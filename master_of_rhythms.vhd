library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity master_of_rhythms is --主模块
	port(
		clk_100M: in std_logic; --100MHz时钟输入
		keyboard_data: in std_logic; --键盘数据输入
		keyboard_clk: in std_logic; --键盘时钟输入
		rx: in std_logic; --串口数据输入
		hs: out std_logic; --VGA行同步信号输出
		vs: out std_logic; --VGA场同步信号输出
		red: out std_logic_vector(2 downto 0); --VGA红色分量输出
		green: out std_logic_vector(2 downto 0); --VGA绿色分量输出
		blue: out std_logic_vector(2 downto 0) --VGA蓝色分量输出
	);
end master_of_rhythms;

architecture bhv of master_of_rhythms is
	component clk_divider is --分频器
		generic (
			div_num: integer := 10 --一周期对应时钟数
		);
		port(
			clk_in: in std_logic; --输入时钟
			clk_out: out std_logic --输出时钟
		);
	end component;
	component keyboard is --键盘模块
		port(
			main_state: in main_state_type; --主模块状态输入
			keyboard_data: in std_logic; --键盘数据输入
			keyboard_clk: in std_logic; --键盘时钟输入
			filter_clk_5M: in std_logic; --滤波5MHz时钟输入
			key_state_p1: out std_logic_vector(3 downto 0); --玩家1按键状态输出
			key_state_p2: out std_logic_vector(3 downto 0) --玩家2按键状态输出
		);
	end component;
	component vga is --VGA模块
		port(
			main_state: in main_state_type; --主模块状态输入
			clk_25M: in std_logic; --25MHz时钟输入
			current_time: in integer; --当前时刻（单位0.01秒）输入
			total_score_p1: in integer; --玩家1总分输入
			total_score_p2: in integer; --玩家2总分输入
			score_p1: in integer; --玩家1得分输入
			score_p2: in integer; --玩家2得分输入
			result_p1: in integer; --玩家1操作结果输入
			result_p2: in integer; --玩家2操作结果输入
			key_state_p1: in std_logic_vector(3 downto 0); --玩家1按键状态输入
			key_state_p2: in std_logic_vector(3 downto 0); --玩家2按键状态输入
			q_background: in std_logic_vector(8 downto 0); --读取背景ROM输入
			q_score: in std_logic_vector(9 downto 0); --读取得分ROM输入
			q_result: in std_logic_vector(9 downto 0); --读取结果ROM输入
			q_map: in std_logic_vector(2 downto 0); --读取曲谱ROM输入
			hs: out std_logic; --VGA行同步信号输出
			vs: out std_logic; --VGA场同步信号输出
			red: out std_logic_vector(2 downto 0); --VGA红色分量输出
			green: out std_logic_vector(2 downto 0); --VGA绿色分量输出
			blue: out std_logic_vector(2 downto 0); --VGA蓝色分量输出
			address_background: out std_logic_vector(15 downto 0); --读取背景ROM地址输出
			address_score: out std_logic_vector(13 downto 0); --读取得分ROM地址输出
			address_result: out std_logic_vector(13 downto 0); --读取结果ROM地址输出
			address_map: out std_logic_vector(14 downto 0); --读取曲谱ROM地址输出
			next_key_time: out array_int_4 --下一待按键时刻（单位0.01秒）输出
		);
	end component;
	component rom_map is --曲谱ROM
		port(
			address: in std_logic_vector(14 downto 0); --地址
			clock: in std_logic; --时钟
			q: out std_logic_vector(2 downto 0) --数据
		);
	end component;
	component rom_background is --背景ROM
		port(
			address: in std_logic_vector(15 downto 0); --地址
			clock: in std_logic; --时钟
			q: out std_logic_vector(8 downto 0) --数据
		);
	end component;
	component rom_score is --得分ROM
		port(
			address: in std_logic_vector(13 downto 0); --地址
			clock: in std_logic; --时钟
			q: out std_logic_vector(9 downto 0) --数据
		);
	end component;
	component rom_result is --结果ROM
		port(
			address: in std_logic_vector(13 downto 0); --地址
			clock: in std_logic; --时钟
			q: out std_logic_vector(9 downto 0) --数据
		);
	end component;
	component serial is --串口模块
		generic(
			bit_num: integer := 8 --每次接受数据的位数
		);
		port(
			bclk: in std_logic; --波特率16倍时钟，近似9600*16Hz
			rxd: in std_logic; --串口接受数据信号
			rx_ready: out std_logic; --成功接受新数据
			rx_data: out std_logic_vector(7 downto 0) --输出接受数据
		);
	end component;
	component judge is --判定模块
		generic (
			miss_delay : integer := 6;
			accept_delay : integer := 4;
			great_delay : integer := 2;
			perfect_delay : integer := 1
		);
		port (
			main_state : in main_state_type; --主模块状态输入
			fclk : in std_logic; --扫描时钟
			next_key_time: in array_int_4; --下一待按键时刻（单位0.01秒）
			key_state: in std_logic_vector(3 downto 0); --按键状态
			current_time : in integer; --当前时刻（单位0.01秒）
			total_score: out integer; --总分输出
			score: out integer; --得分输出
			result: out integer --操作结果输出
		);
	end component;
	signal main_state: main_state_type := READY; --主模块状态
	signal current_time: integer := 0; --当前时刻（单位0.01秒）
	signal next_key_time: array_int_4; --下一待按键时刻（单位0.01秒）
	signal count_time: integer := 0; --计时
	signal total_score_p1: integer; --玩家1总分
	signal total_score_p2: integer; --玩家2总分
	signal score_p1: integer; --玩家1得分
	signal score_p2: integer; --玩家2得分
	signal result_p1: integer; --玩家1状态
	signal result_p2: integer; --玩家2状态
	signal key_state_p1: std_logic_vector(3 downto 0); --玩家1按键状态
	signal key_state_p2: std_logic_vector(3 downto 0); --玩家2按键状态
	signal clk_5M: std_logic; --5MHz时钟
	signal clk_25M: std_logic; --25MHz时钟
	signal clk_s: std_logic; --串口时钟
	signal q_background: std_logic_vector(8 downto 0); --读取背景ROM
	signal q_score: std_logic_vector(9 downto 0); --读取得分ROM
	signal q_result: std_logic_vector(9 downto 0); --读取结果ROM
	signal q_map: std_logic_vector(2 downto 0); --读取曲谱ROM
	signal address_background: std_logic_vector(15 downto 0); --读取背景ROM地址
	signal address_score: std_logic_vector(13 downto 0); --读取得分ROM地址
	signal address_result: std_logic_vector(13 downto 0); --读取结果ROM地址
	signal address_map: std_logic_vector(14 downto 0); --读取曲谱ROM地址
	signal rx_ready: std_logic; --串口成功接受新数据
	signal rx_data: std_logic_vector(7 downto 0); --串口接受数据
begin
	div5M: clk_divider generic map(20) port map(clk_100M, clk_5M);
	div25M: clk_divider generic map(4) port map(clk_100M, clk_25M);
	div_s: clk_divider generic map(651) port map(clk_100M, clk_s);
	kb: keyboard port map(main_state, keyboard_data, keyboard_clk, clk_5M, key_state_p1, key_state_p2);
	v: vga port map(main_state, clk_25M, current_time, total_score_p1, total_score_p2, score_p1, score_p2, result_p1, result_p2, key_state_p1, key_state_p2, q_background, q_score, q_result, q_map, hs, vs, red, green, blue, address_background, address_score, address_result, address_map, next_key_time);
	rm: rom_map port map(address_map, clk_100M, q_map);
	rb: rom_background port map(address_background, clk_100M, q_background);
	rs: rom_score port map(address_score, clk_100M, q_score);
	rr: rom_result port map(address_result, clk_100M, q_result);
	s: serial port map(clk_s, rx, rx_ready, rx_data);
	j2: judge generic map(16, 12, 8, 4) port map(main_state, clk_100M, next_key_time, key_state_p2, current_time, total_score_p2, score_p2, result_p2);
	j1: judge generic map(16, 12, 8, 4) port map(main_state, clk_100M, next_key_time, key_state_p1, current_time, total_score_p1, score_p1, result_p1);

	process(clk_100M) --控制进程
	begin
		if rising_edge(clk_100M) then
			if rx_ready = '1' and rx_data = 114 then
				main_state <= READY;
				count_time <= 0;
				current_time <= 0;
			elsif rx_ready = '1' and rx_data = 115 and main_state = READY then
				main_state <= RUN;
			elsif main_state = RUN then
				if count_time = 999999 then
					count_time <= 0;
					current_time <= current_time + 1;
					if current_time = 21599 then
						main_state <= STOP;
					end if;
				else
					count_time <= count_time + 1;
				end if;
			end if;
		end if;
	end process;
end bhv;