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
			current_time_ms: integer; --当前时刻（毫秒）输入
			score: in integer; --得分输入
			result: in integer; --操作结果输入
			key_state: in std_logic_vector(3 downto 0); --按键状态输入
			q_pic: in std_logic_vector(2 downto 0); --读取图片ROM输入
			q_map: in std_logic_vector(2 downto 0); --读取曲谱ROM输入
			hs: out std_logic; --VGA行同步信号输出
			vs: out std_logic; --VGA场同步信号输出
			red: out std_logic_vector(2 downto 0); --VGA红色分量输出
			green: out std_logic_vector(2 downto 0); --VGA绿色分量输出
			blue: out std_logic_vector(2 downto 0); --VGA蓝色分量输出
			address_pic: out std_logic_vector(13 downto 0); --读取图片ROM地址输出
			address_map: out std_logic_vector(13 downto 0); --读取曲谱ROM地址输出
			next_key_time_ms: out array_int_4 --下一待按键时刻（毫秒）输出
		);
	end component;
	component digital_7 is --点亮数字人生
		port(
			key: in std_logic_vector(3 downto 0); --数据输入
			display: out std_logic_vector(6 downto 0) --不带译码器的数码管输出
		);
	end component;
	signal main_state: main_state_type; --主模块状态
	signal current_time_ms: integer; --当前时刻（毫秒）
	signal next_key_time_ms: array_int_4; --下一待按键时刻（毫秒）
	signal score_p1: integer; --玩家1得分
	signal score_p2: integer; --玩家2得分
	signal key_state_p1: std_logic_vector(3 downto 0); --玩家1按键状态
	signal key_state_p2: std_logic_vector(3 downto 0); --玩家2按键状态
	signal clk_5M: std_logic; --5MHz时钟
	signal clk_25M: std_logic; --25MHz时钟
begin
	d7: digital_7 port map("0000" + key_state_p2(3), display_7);
	d6: digital_7 port map("0000" + key_state_p2(2), display_6);
	d5: digital_7 port map("0000" + key_state_p2(1), display_5);
	d4: digital_7 port map("0000" + key_state_p2(0), display_4);
	d3: digital_7 port map("0000" + key_state_p1(3), display_3);
	d2: digital_7 port map("0000" + key_state_p1(2), display_2);
	d1: digital_7 port map("0000" + key_state_p1(1), display_1);
	d0: digital_7 port map("0000" + key_state_p1(0), display_0);
	div5M: clk_divider generic map(20) port map(clk_100M, clk_5M);
	div25M: clk_divider generic map(4) port map(clk_100M, clk_25M);
	kb: keyboard port map(main_state, keyboard_data, keyboard_clk, clk_5M, key_state_p1, key_state_p2);
end bhv;