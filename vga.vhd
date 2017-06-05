library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use work.types.all;

entity vga is --VGA模块
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
end vga;

architecture bhv of vga is
	--颜色设定
	constant BLANK_RED: std_logic_vector(2 downto 0) := "000"; --空白颜色
	constant BLANK_GREEN: std_logic_vector(2 downto 0) := "000";
	constant BLANK_BLUE: std_logic_vector(2 downto 0) := "000";
	constant LINE_RED: std_logic_vector(2 downto 0) := "100"; --分割线颜色
	constant LINE_GREEN: std_logic_vector(2 downto 0) := "100";
	constant LINE_BLUE: std_logic_vector(2 downto 0) := "100";
	constant CHANNEL_14_RED: std_logic_vector(2 downto 0) := "111"; --第一四道键与下方块颜色
	constant CHANNEL_14_GREEN: std_logic_vector(2 downto 0) := "110";
	constant CHANNEL_14_BLUE: std_logic_vector(2 downto 0) := "110";
	constant CHANNEL_23_RED: std_logic_vector(2 downto 0) := "111"; --第二三道键与下方块颜色
	constant CHANNEL_23_GREEN: std_logic_vector(2 downto 0) := "100";
	constant CHANNEL_23_BLUE: std_logic_vector(2 downto 0) := "101";
	constant GOAL_RED: std_logic_vector(2 downto 0) := "100"; --目标键颜色
	constant GOAL_GREEN: std_logic_vector(2 downto 0) := "100";
	constant GOAL_BLUE: std_logic_vector(2 downto 0) := "110";
	constant PRESS_RED: std_logic_vector(2 downto 0) := "111"; --按下道目标键与下方块颜色
	constant PRESS_GREEN: std_logic_vector(2 downto 0) := "111";
	constant PRESS_BLUE: std_logic_vector(2 downto 0) := "111";
	constant SCORE_RED: std_logic_vector(2 downto 0) := "111"; --得分颜色
	constant SCORE_GREEN: std_logic_vector(2 downto 0) := "111";
	constant SCORE_BLUE: std_logic_vector(2 downto 0) := "111";
	constant GET_5_RED: std_logic_vector(2 downto 0) := "111"; --结果5颜色
	constant GET_5_GREEN: std_logic_vector(2 downto 0) := "101";
	constant GET_5_BLUE: std_logic_vector(2 downto 0) := "000";
	constant GET_3_RED: std_logic_vector(2 downto 0) := "010"; --结果3颜色
	constant GET_3_GREEN: std_logic_vector(2 downto 0) := "101";
	constant GET_3_BLUE: std_logic_vector(2 downto 0) := "010";
	constant GET_1_RED: std_logic_vector(2 downto 0) := "001"; --结果1颜色
	constant GET_1_GREEN: std_logic_vector(2 downto 0) := "011";
	constant GET_1_BLUE: std_logic_vector(2 downto 0) := "111";
	constant GET_0_RED: std_logic_vector(2 downto 0) := "011"; --结果0颜色
	constant GET_0_GREEN: std_logic_vector(2 downto 0) := "011";
	constant GET_0_BLUE: std_logic_vector(2 downto 0) := "011";
	--大小设定
	constant BLANK_WIDTH: integer := 65; --两侧空白宽度
	constant LINE_WIDTH: integer := 2; --分割线宽度
	constant CHANNEL_WIDTH: integer := 20; --道宽度
	constant DIGIT_WIDTH: integer := 20; --数字宽度
	constant DIGIT_HEIGHT: integer := 30; --数字高度
	constant KEY_HEIGHT: integer := 4; --键高度
	constant CHECK_HEIGHT: integer := KEY_HEIGHT * 12; --暗判高度
	--位置设定（横）
	constant BLANK_LEFT: integer := 0; --左侧空白起始位置
	constant LINE_1: integer := BLANK_WIDTH; --第一条分割线起始位置
	constant CHANNEL_1: integer := LINE_1 + LINE_WIDTH; --第一道起始位置
	constant LINE_2: integer := CHANNEL_1 + CHANNEL_WIDTH; --第二条分割线起始位置
	constant CHANNEL_2: integer := LINE_2 + LINE_WIDTH; --第二道起始位置
	constant LINE_3: integer := CHANNEL_2 + CHANNEL_WIDTH; --第三条分割线起始位置
	constant CHANNEL_3: integer := LINE_3 + LINE_WIDTH; --第三道起始位置
	constant LINE_4: integer := CHANNEL_3 + CHANNEL_WIDTH; --第四条分割线起始位置
	constant CHANNEL_4: integer := LINE_4 + LINE_WIDTH; --第四道起始位置
	constant LINE_5: integer := CHANNEL_4 + CHANNEL_WIDTH; --第五条分割线起始位置
	constant CHANNEL_5: integer := LINE_5 + LINE_WIDTH; --第五道（空白）起始位置
	constant DIGIT_1: integer := CHANNEL_5 + CHANNEL_WIDTH; --千位起始位置
	constant DIGIT_2: integer := DIGIT_1 + DIGIT_WIDTH; --百位起始位置
	constant DIGIT_3: integer := DIGIT_2 + DIGIT_WIDTH; --十位起始位置
	constant DIGIT_4: integer := DIGIT_3 + DIGIT_WIDTH; --个位起始位置
	constant BLANK_RIGHT: integer := DIGIT_4 + DIGIT_WIDTH; --右侧空白起始位置
	constant MID: integer := 320; --中间位置
	--位置设定（纵）
	constant GOAL: integer := 380; --目标键位置
	constant UNDERBLOCK: integer := GOAL + KEY_HEIGHT; --下方块位置
	constant SCORE: integer := 100; --得分位置
	--中间信号
	signal x: integer := 0; --下一时刻的x
	signal y: integer := 0; --下一时刻的y
	signal nx: integer := 1; --下下时刻的x
	signal ny: integer := 0; --下下时刻的y
	signal s_current_time: integer; --当前屏当前时刻（单位0.01秒）
	signal s_score_p1: integer; --当前屏玩家1得分
	signal s_score_p2: integer; --当前屏玩家2得分
	signal s_result_p1: integer; --当前屏玩家1操作结果
	signal s_result_p2: integer; --当前屏玩家2操作结果
	signal s_key_state_p1: std_logic_vector(3 downto 0); --当前屏玩家1按键状态
	signal s_key_state_p2: std_logic_vector(3 downto 0); --当前屏玩家2按键状态
begin
	process(clk_25M)
	begin
		if rising_edge(clk_25M) then
			--计算下一时刻的坐标
			if nx = 799 then
				nx <= 0;
				if ny = 524 then
					ny <= 0;
				else
					ny <= ny + 1;
				end if;
			else
				nx <= nx + 1;
			end if;
			x <= nx;
			y <= ny;
			--计算行场同步信号输出
			if x >= 656 and x < 752 then
				hs <= '0';
			else
				hs <= '1';
			end if;
			if y >= 490 and y < 492 then
				vs <= '0';
			else
				vs <= '1';
			end if;
			--读取当前屏输入
			if x = 0 and y = 0 then
				s_current_time <= current_time;
				s_score_p1 <= score_p1;
				s_score_p2 <= score_p2;
				s_result_p1 <= result_p1;
				s_result_p2 <= result_p2;
				s_key_state_p1 <= key_state_p1;
				s_key_state_p2 <= key_state_p2;
			end if;
			--读取ROM
			if nx >= CHANNEL_1 and nx < LINE_2 then --第一道
				if ny >= 0 and ny < UNDERBLOCK then
					address_map <= "000000000000000" + conv_std_logic_vector(s_current_time + (UNDERBLOCK - ny - 1) / KEY_HEIGHT, 15);
				elsif ny >= UNDERBLOCK and ny < UNDERBLOCK + CHECK_HEIGHT then
					if s_current_time >= (ny - UNDERBLOCK) / KEY_HEIGHT then
						address_map <= "000000000000000" + conv_std_logic_vector(s_current_time - (ny - UNDERBLOCK) / KEY_HEIGHT, 15);
					else
						address_map <= "111111111111111";
					end if;
				end if;
			end if;
			if nx >= DIGIT_1 and nx < DIGIT_2 then --千位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p2 / 1000, 4) & conv_std_logic_vector(nx - DIGIT_1, 5) & conv_std_logic_vector(ny - SCORE, 5);
				elsif ny >= GOAL and ny < GOAL + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_result_p2, 4) & conv_std_logic_vector(nx - DIGIT_1, 5) & conv_std_logic_vector(ny - GOAL, 5);
				end if;
			end if;
			if nx >= DIGIT_2 and nx < DIGIT_3 then --百位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p2 / 100 mod 10, 4) & conv_std_logic_vector(nx - DIGIT_2, 5) & conv_std_logic_vector(ny - SCORE, 5);
				end if;
			end if;
			if nx >= DIGIT_3 and nx < DIGIT_4 then --十位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p2 / 10 mod 10, 4) & conv_std_logic_vector(nx - DIGIT_3, 5) & conv_std_logic_vector(ny - SCORE, 5);
				end if;
			end if;
			if nx >= DIGIT_4 and nx < BLANK_RIGHT then --个位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p2 mod 10, 4) & conv_std_logic_vector(nx - DIGIT_4, 5) & conv_std_logic_vector(ny - SCORE, 5);
				end if;
			end if;
			if nx >= MID + DIGIT_1 and nx < MID + DIGIT_2 then --千位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p1 / 1000, 4) & conv_std_logic_vector(nx - MID - DIGIT_1, 5) & conv_std_logic_vector(ny - SCORE, 5);
				elsif ny >= GOAL and ny < GOAL + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_result_p1, 4) & conv_std_logic_vector(nx - MID - DIGIT_1, 5) & conv_std_logic_vector(ny - GOAL, 5);
				end if;
			end if;
			if nx >= MID + DIGIT_2 and nx < MID + DIGIT_3 then --百位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p1 / 100 mod 10, 4) & conv_std_logic_vector(nx - MID - DIGIT_2, 5) & conv_std_logic_vector(ny - SCORE, 5);
				end if;
			end if;
			if nx >= MID + DIGIT_3 and nx < MID + DIGIT_4 then --十位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p1 / 10 mod 10, 4) & conv_std_logic_vector(nx - MID - DIGIT_3, 5) & conv_std_logic_vector(ny - SCORE, 5);
				end if;
			end if;
			if nx >= MID + DIGIT_4 and nx < MID + BLANK_RIGHT then --个位
				if ny >= SCORE and ny < SCORE + DIGIT_HEIGHT then
					address_pic <= conv_std_logic_vector(s_score_p1 mod 10, 4) & conv_std_logic_vector(nx - MID - DIGIT_4, 5) & conv_std_logic_vector(ny - SCORE, 5);
				end if;
			end if;
			--计算next_key_time
			if main_state = RUN then
				if x >= CHANNEL_1 and x < LINE_2 then
					if y >= 0 and y < UNDERBLOCK then
						case q_map is
							when "001" =>
								next_key_time(3) <= s_current_time + ((UNDERBLOCK - y - 1) / KEY_HEIGHT);
							when "010" =>
								next_key_time(2) <= s_current_time + ((UNDERBLOCK - y - 1) / KEY_HEIGHT);
							when "011" =>
								next_key_time(1) <= s_current_time + ((UNDERBLOCK - y - 1) / KEY_HEIGHT);
							when "100" =>
								next_key_time(0) <= s_current_time + ((UNDERBLOCK - y - 1) / KEY_HEIGHT);
							when others =>
						end case;
					elsif y >= UNDERBLOCK and y < UNDERBLOCK + CHECK_HEIGHT then
						case q_map is
							when "001" =>
								next_key_time(3) <= s_current_time - ((y - UNDERBLOCK) / KEY_HEIGHT);
							when "010" =>
								next_key_time(2) <= s_current_time - ((y - UNDERBLOCK) / KEY_HEIGHT);
							when "011" =>
								next_key_time(1) <= s_current_time - ((y - UNDERBLOCK) / KEY_HEIGHT);
							when "100" =>
								next_key_time(0) <= s_current_time - ((y - UNDERBLOCK) / KEY_HEIGHT);
							when others =>
						end case;
					end if;
				end if;
			else
				next_key_time(3) <= -5;
				next_key_time(2) <= -5;
				next_key_time(1) <= -5;
				next_key_time(0) <= -5;
			end if;
			--计算当前屏输出
			if x >= 0 and x < 640 and y >= 0 and y < 480 then
				if x >= BLANK_LEFT and x < LINE_1 then --左侧空白
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				elsif x >= LINE_1 and x < CHANNEL_1 then --第一条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= CHANNEL_1 and x < LINE_2 then --第一道
					if y >= 0 and y < GOAL then
						if q_map = "001" then
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p2(3) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p2(3) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						end if;
					end if;
				elsif x >= LINE_2 and x < CHANNEL_2 then --第二条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= CHANNEL_2 and x < LINE_3 then --第二道
					if y >= 0 and y < GOAL then
						if q_map = "010" then
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p2(2) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p2(2) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						end if;
					end if;
				elsif x >= LINE_3 and x < CHANNEL_3 then --第三条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= CHANNEL_3 and x < LINE_4 then --第三道
					if y >= 0 and y < GOAL then
						if q_map = "011" then
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p2(1) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p2(1) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						end if;
					end if;
				elsif x >= LINE_4 and x < CHANNEL_4 then --第四条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= CHANNEL_4 and x < LINE_5 then --第四道
					if y >= 0 and y < GOAL then
						if q_map = "100" then
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p2(0) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p2(0) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						end if;
					end if;
				elsif x >= LINE_5 and x < CHANNEL_5 then --第五条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= CHANNEL_5 and x < DIGIT_1 then --第五道（空白）
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				elsif x >= DIGIT_1 and x < DIGIT_2 then --千位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < GOAL + DIGIT_HEIGHT then
						if q_pic = "1" then
							if s_result_p2 = 5 then
								red <= GET_5_RED;
								green <= GET_5_GREEN;
								blue <= GET_5_BLUE;
							elsif s_result_p2 = 3 then
								red <= GET_3_RED;
								green <= GET_3_GREEN;
								blue <= GET_3_BLUE;
							elsif s_result_p2 = 1 then
								red <= GET_1_RED;
								green <= GET_1_GREEN;
								blue <= GET_1_BLUE;
							else
								red <= GET_0_RED;
								green <= GET_0_GREEN;
								blue <= GET_0_BLUE;
							end if;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= DIGIT_2 and x < DIGIT_3 then --百位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= DIGIT_3 and x < DIGIT_4 then --十位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= DIGIT_4 and x < BLANK_RIGHT then --个位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= BLANK_RIGHT and x < 320 then --右侧空白
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				elsif x >= MID + BLANK_LEFT and x < MID + LINE_1 then --左侧空白
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				elsif x >= MID + LINE_1 and x < MID + CHANNEL_1 then --第一条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= MID + CHANNEL_1 and x < MID + LINE_2 then --第一道
					if y >= 0 and y < GOAL then
						if q_map = "001" then
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p1(3) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p1(3) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						end if;
					end if;
				elsif x >= MID + LINE_2 and x < MID + CHANNEL_2 then --第二条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= MID + CHANNEL_2 and x < MID + LINE_3 then --第二道
					if y >= 0 and y < GOAL then
						if q_map = "010" then
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p1(2) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p1(2) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						end if;
					end if;
				elsif x >= MID + LINE_3 and x < MID + CHANNEL_3 then --第三条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= MID + CHANNEL_3 and x < MID + LINE_4 then --第三道
					if y >= 0 and y < GOAL then
						if q_map = "011" then
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p1(1) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p1(1) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_23_RED;
							green <= CHANNEL_23_GREEN;
							blue <= CHANNEL_23_BLUE;
						end if;
					end if;
				elsif x >= MID + LINE_4 and x < MID + CHANNEL_4 then --第四条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= MID + CHANNEL_4 and x < MID + LINE_5 then --第四道
					if y >= 0 and y < GOAL then
						if q_map = "100" then
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < UNDERBLOCK then
						if s_key_state_p1(0) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= GOAL_RED;
							green <= GOAL_GREEN;
							blue <= GOAL_BLUE;
						end if;
					else
						if s_key_state_p1(0) = '1' then
							red <= PRESS_RED;
							green <= PRESS_GREEN;
							blue <= PRESS_BLUE;
						else
							red <= CHANNEL_14_RED;
							green <= CHANNEL_14_GREEN;
							blue <= CHANNEL_14_BLUE;
						end if;
					end if;
				elsif x >= MID + LINE_5 and x < MID + CHANNEL_5 then --第五条分割线
					red <= LINE_RED;
					green <= LINE_GREEN;
					blue <= LINE_BLUE;
				elsif x >= MID + CHANNEL_5 and x < MID + DIGIT_1 then --第五道（空白）
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				elsif x >= MID + DIGIT_1 and x < MID + DIGIT_2 then --千位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					elsif y >= GOAL and y < GOAL + DIGIT_HEIGHT then
						if q_pic = "1" then
							if s_result_p1 = 5 then
								red <= GET_5_RED;
								green <= GET_5_GREEN;
								blue <= GET_5_BLUE;
							elsif s_result_p1 = 3 then
								red <= GET_3_RED;
								green <= GET_3_GREEN;
								blue <= GET_3_BLUE;
							elsif s_result_p1 = 1 then
								red <= GET_1_RED;
								green <= GET_1_GREEN;
								blue <= GET_1_BLUE;
							else
								red <= GET_0_RED;
								green <= GET_0_GREEN;
								blue <= GET_0_BLUE;
							end if;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= MID + DIGIT_2 and x < MID + DIGIT_3 then --百位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= MID + DIGIT_3 and x < MID + DIGIT_4 then --十位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= MID + DIGIT_4 and x < MID + BLANK_RIGHT then --个位
					if y >= SCORE and y < SCORE + DIGIT_HEIGHT then
						if q_pic = "1" then
							red <= SCORE_RED;
							green <= SCORE_GREEN;
							blue <= SCORE_BLUE;
						else
							red <= BLANK_RED;
							green <= BLANK_GREEN;
							blue <= BLANK_BLUE;
						end if;
					else
						red <= BLANK_RED;
						green <= BLANK_GREEN;
						blue <= BLANK_BLUE;
					end if;
				elsif x >= MID + BLANK_RIGHT and x < 640 then --右侧空白
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				else
					red <= BLANK_RED;
					green <= BLANK_GREEN;
					blue <= BLANK_BLUE;
				end if;
			else
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '0');
			end if;
		end if;
	end process;
end bhv;