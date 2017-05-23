library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity master_of_rhythms is --主模块
	port(
		clk_100M: in std_logic; --100MHz时钟输入
		start: in std_logic; --开始游戏输入
		reset: in std_logic; --重置输入
		keyboard_data: in std_logic; --键盘数据输入
		keyboard_clk: in std_logic; --键盘时钟输入
		hs: out std_logic; --VGA行同步信号输出
		vs: out std_logic; --VGA场同步信号输出
		red: out std_logic_vector(2 downto 0); --VGA红色分量输出
		green: out std_logic_vector(2 downto 0); --VGA绿色分量输出
		blue: out std_logic_vector(2 downto 0); --VGA蓝色分量输出
		display_7: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_6: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_5: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_4: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_3: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_2: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_1: out std_logic_vector(6 downto 0); --调试用数码管输出
		display_0: out std_logic_vector(6 downto 0) --调试用数码管输出
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
			score_p1: in integer; --玩家1得分输入
			score_p2: in integer; --玩家2得分输入
			result_p1: in integer; --玩家1操作结果输入
			result_p2: in integer; --玩家2操作结果输入
			key_state_p1: in std_logic_vector(3 downto 0); --玩家1按键状态输入
			key_state_p2: in std_logic_vector(3 downto 0); --玩家2按键状态输入
			q_pic: in std_logic_vector(0 downto 0); --读取图片ROM输入
			q_map: in std_logic_vector(2 downto 0); --读取曲谱ROM输入
			hs: out std_logic; --VGA行同步信号输出
			vs: out std_logic; --VGA场同步信号输出
			red: out std_logic_vector(2 downto 0); --VGA红色分量输出
			green: out std_logic_vector(2 downto 0); --VGA绿色分量输出
			blue: out std_logic_vector(2 downto 0); --VGA蓝色分量输出
			address_pic: out std_logic_vector(13 downto 0); --读取图片ROM地址输出
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
	component rom_num is --数字ROM
		port(
			address: in std_logic_vector(13 downto 0); --地址
			clock: in std_logic; --时钟
			q: out std_logic_vector(0 downto 0) --数据
		);
	end component;
	component digital_7 is --点亮数字人生
		port(
			key: in std_logic_vector(3 downto 0); --数据输入
			display: out std_logic_vector(6 downto 0) --不带译码器的数码管输出
		);
	end component;
	component judge is --判定模块
		generic (
			accept_delay: integer := 5;
			great_dalay: integer := 3;
			profect_dalay: integer := 1
		);
		port (
			reset: in std_logic; --重置信号
			next_key_time: in array_int_4; --下一待按键时刻（单位0.01秒）
			key_state: in std_logic_vector(3 downto 0); --按键状态
			current_time: in integer; --当前时刻（单位0.01秒）
			score: out integer; --得分输出
			result: out integer --操作结果输出
		);
	end component;
	signal main_state: main_state_type := READY; --主模块状态
	signal current_time: integer := 0; --当前时刻（单位0.01秒）
	signal next_key_time: array_int_4; --下一待按键时刻（单位0.01秒）
	signal count_time: integer := 0; --计时
	signal score_p1: integer; --玩家1得分
	signal score_p2: integer; --玩家2得分
	signal result_p1: integer; --玩家1状态
	signal result_p2: integer; --玩家2状态
	signal key_state_p1: std_logic_vector(3 downto 0); --玩家1按键状态
	signal key_state_p2: std_logic_vector(3 downto 0); --玩家2按键状态
	signal clk_5M: std_logic; --5MHz时钟
	signal clk_25M: std_logic; --25MHz时钟
	signal q_pic: std_logic_vector(0 downto 0); --读取图片ROM
	signal q_map: std_logic_vector(2 downto 0); --读取曲谱ROM
	signal address_pic: std_logic_vector(13 downto 0); --读取图片ROM地址
	signal address_map: std_logic_vector(14 downto 0); --读取曲谱ROM地址
begin
	d7: digital_7 port map("0000" + reset, display_7);
	d6: digital_7 port map("0000" + start, display_6);
	d4: digital_7 port map("0000" + current_time / 10000, display_4);
	d3: digital_7 port map("0000" + current_time / 1000 mod 10, display_3);
	d2: digital_7 port map("0000" + current_time / 100 mod 10, display_2);
	d1: digital_7 port map("0000" + current_time / 10 mod 10, display_1);
	d0: digital_7 port map("0000" + current_time mod 10, display_0);
	--d7: digital_7 port map("0000" + key_state_p2(3), display_7);
	--d6: digital_7 port map("0000" + key_state_p2(2), display_6);
	--d5: digital_7 port map("0000" + key_state_p2(1), display_5);
	--d4: digital_7 port map("0000" + key_state_p2(0), display_4);
	--d3: digital_7 port map("0000" + key_state_p1(3), display_3);
	--d2: digital_7 port map("0000" + key_state_p1(2), display_2);
	--d1: digital_7 port map("0000" + key_state_p1(1), display_1);
	--d0: digital_7 port map("0000" + key_state_p1(0), display_0);
	div5M: clk_divider generic map(20) port map(clk_100M, clk_5M);
	div25M: clk_divider generic map(4) port map(clk_100M, clk_25M);
	kb: keyboard port map(main_state, keyboard_data, keyboard_clk, clk_5M, key_state_p1, key_state_p2);
	v: vga port map(main_state, clk_25M, current_time, score_p1, score_p2, result_p1, result_p2, key_state_p1, key_state_p2, q_pic, q_map, hs, vs, red, green, blue, address_pic, address_map, next_key_time);
	rm: rom_map port map(address_map, clk_100M, q_map);
	rn: rom_num port map(address_pic, clk_100M, q_pic);
	j2: judge port map(reset, next_key_time, key_state_p2, current_time, score_p2, result_p2);

	process(clk_100M) --控制进程
	begin
		if reset = '0' then
			main_state <= READY;
			count_time <= 0;
			current_time <= 0;
		elsif rising_edge(clk_100M) then
			if main_state = READY and start = '0' then
				main_state <= RUN;
			elsif main_state = RUN then
				if count_time = 999999 then
					count_time <= 0;
					current_time <= current_time + 1;
					if current_time = 17999 then
						main_state <= STOP;
					end if;
				else
					count_time <= count_time + 1;
				end if;
			end if;
		end if;
	end process;
end bhv;