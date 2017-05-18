library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity vga is --VGA模块
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
end vga;