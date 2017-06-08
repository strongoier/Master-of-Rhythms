library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity judge is --判定模块
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
end judge;

architecture judge_0 of judge is
signal cur_index : std_logic_vector(1 downto 0) := "00"; -- 当前判断轨道
signal cur_score : integer := 0; -- 当前分数
signal cur_total_score : integer := 0; -- 当前总分
signal cur_result : integer := 0; -- 当前结果
signal cur_judge_state : std_logic_vector(3 downto 0) := "0000"; -- 当前判定状态
signal cur_key_state : std_logic_vector(3 downto 0) := "0000"; -- 当前按键状态
signal cur_key_time : array_int_4; -- 当前按键时间
begin
	------------------------------------------------------
	-- 输出当前分数
	score <= cur_score;
	-- 输出当前总分
	total_score <= cur_total_score;
	-- 输出当前结果
	result <= cur_result;
	------------------------------------------------------
	-- 扫描、更新
	process (main_state, fclk)
	begin
		if (main_state = READY) then -- 当前游戏状态为READY时重置各变量
			cur_index <= "00"; -- 重置轨道
			cur_score <= 0; -- 重置分数
			cur_total_score <= 0; -- 重置总分
			cur_result <= 0; -- 重置判定结果
			cur_judge_state <= "0000"; -- 重置判断状态
			cur_key_state <= "0000"; -- 重置按键状态
			cur_key_time(0) <= -100; -- 重置按键时间
			cur_key_time(1) <= -100;
			cur_key_time(2) <= -100;
			cur_key_time(3) <= -100;
		elsif (main_state = RUN and rising_edge(fclk)) then -- 当前游戏状态为RUN时在100M时钟上升沿处扫描
			case cur_index is --分别扫描四个轨道
				when "00" =>
					cur_index <= "01"; -- 切换下一轨道
					if (cur_key_state(0) = key_state(0)) then -- 如果键盘状态没有变化
						cur_score <= cur_score; --分数、总分、结果、按键状态不变
						cur_result <= cur_result;
						cur_key_state(0) <= cur_key_state(0);
						if (cur_key_time(0) = next_key_time(0)) then -- 如果没有下一个按键到来
						cur_judge_state(0) <= cur_judge_state(0); -- 判断状态与当前按键时间不变 
							cur_key_time(0) <= cur_key_time(0);
						else -- 如果下一个按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(0) <= '0'; -- 重置判定状态、更新当前按键时间
							cur_key_time(0) <= next_key_time(0);
						end if;
					elsif (key_state(0) = '1') then -- 如果按键在此刻按下
						cur_key_state(0) <= key_state(0); -- 更新当前按键状态
						if (cur_judge_state(0) = '0') then -- 如果还未判定当前键位
							if (cur_key_time(0) = next_key_time(0)) then -- 如果当前没有新按键到来
								cur_key_time(0) <= cur_key_time(0); -- 保持当前按键时间
								if ((current_time < next_key_time(0) and next_key_time(0) - current_time < perfect_delay) 
								or (current_time >= next_key_time(0) and current_time - next_key_time(0) < perfect_delay)) then
									-- 如果小于perfect_delay*10毫秒，判断为prefect
									cur_score <= cur_score + 5; -- 更新分数、总分、判断结果、判定状态
									cur_result <= 5;
									cur_judge_state(0) <= '1';
								else
									if ((current_time < next_key_time(0) and next_key_time(0) - current_time < great_delay) 
									or (current_time >= next_key_time(0) and current_time - next_key_time(0) < great_delay)) then
										-- 如果小于great_delay*10毫秒，判断为great
										cur_score <= cur_score + 3; -- 更新分数、总分、判断结果、判定状态
										cur_result <= 3;
										cur_judge_state(0) <= '1';
									else
										if ((current_time < next_key_time(0) and next_key_time(0) - current_time < accept_delay) 
										or (current_time >= next_key_time(0) and current_time - next_key_time(0) < accept_delay)) then
											-- 如果小于accept_delay*10毫秒，判断为accept
											cur_score <= cur_score + 1; -- 更新分数、总分、判断结果、判定状态
											cur_result <= 1;
											cur_judge_state(0) <= '1';
										else
											if ((current_time < next_key_time(0) and next_key_time(0) - current_time < miss_delay) 
											or (current_time >= next_key_time(0) and current_time - next_key_time(0) < miss_delay)) then
												-- 如果小于miss_delay*10毫秒，判断为miss
												cur_score <= cur_score; -- 更新分数、总分、判断结果、判定状态
												cur_result <= 0;
												cur_judge_state(0) <= '0';
											else
												-- 如果时间大于miss_delay*10毫秒，视为无效按键
												cur_score <= cur_score;
												cur_result <= cur_result;
												cur_judge_state(0) <= cur_judge_state(0);
											end if;
										end if;
									end if;
								end if;
							else -- 如果有新按键到来
								cur_total_score <= cur_total_score + 5;
								cur_score <= cur_score;
								cur_result <= cur_result;
								cur_judge_state(0) <= '0';
								cur_key_time(0) <= next_key_time(0);
							end if;
						else -- 如果已经判定当前键位
							cur_score <= cur_score;
							cur_result <= cur_result;
							if (cur_key_time(0) = next_key_time(0)) then -- 如果下一个按键没有到来
								cur_judge_state(0) <= '1'; -- 保持判定状态、按键时间
								cur_key_time(0) <= cur_key_time(0);
							else -- 如果下一个按键到来
								cur_total_score <= cur_total_score + 5;
								cur_judge_state(0) <= '0'; -- 更新判定状态、按键时间
								cur_key_time(0) <= next_key_time(0);
							end if;
						end if;
					else -- 如果按键此时抬起
						cur_key_state(0) <= key_state(0);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(0) = next_key_time(0)) then -- 如果当前没有新按键到来
							cur_judge_state(0) <= cur_judge_state(0); -- 保持判定状态、按键时间
							cur_key_time(0) <= cur_key_time(0);
						else -- 如果当前新按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(0) <= '0'; -- 更新判定状态、按键时间
							cur_key_time(0) <= next_key_time(0);
						end if;
					end if;
				when "01" =>
					cur_index <= "10";
					if (cur_key_state(1) = key_state(1)) then -- 如果键盘状态没有变化
						cur_score <= cur_score; --分数、总分、结果、按键状态不变
						cur_result <= cur_result;
						cur_key_state(1) <= cur_key_state(1);
						if (cur_key_time(1) = next_key_time(1)) then -- 如果没有下一个按键到来
						cur_judge_state(1) <= cur_judge_state(1); -- 判断状态与当前按键时间不变 
							cur_key_time(1) <= cur_key_time(1);
						else -- 如果下一个按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(1) <= '0'; -- 重置判定状态、更新当前按键时间
							cur_key_time(1) <= next_key_time(1);
						end if;
					elsif (key_state(1) = '1') then -- 如果按键在此刻按下
						cur_key_state(1) <= key_state(1); -- 更新当前按键状态
						if (cur_judge_state(1) = '0') then -- 如果还未判定当前键位
							if (cur_key_time(1) = next_key_time(1)) then -- 如果当前没有新按键到来
								cur_key_time(1) <= cur_key_time(1); -- 保持当前按键时间
								if ((current_time < next_key_time(1) and next_key_time(1) - current_time < perfect_delay) 
								or (current_time >= next_key_time(1) and current_time - next_key_time(1) < perfect_delay)) then
									-- 如果小于perfect_delay*10毫秒，判断为prefect
									cur_score <= cur_score + 5; -- 更新分数、总分、判断结果、判定状态
									cur_result <= 5;
									cur_judge_state(1) <= '1';
								else
									if ((current_time < next_key_time(1) and next_key_time(1) - current_time < great_delay) 
									or (current_time >= next_key_time(1) and current_time - next_key_time(1) < great_delay)) then
										-- 如果小于great_delay*10毫秒，判断为great
										cur_score <= cur_score + 3; -- 更新分数、总分、判断结果、判定状态
										cur_result <= 3;
										cur_judge_state(1) <= '1';
									else
										if ((current_time < next_key_time(1) and next_key_time(1) - current_time < accept_delay) 
										or (current_time >= next_key_time(1) and current_time - next_key_time(1) < accept_delay)) then
											-- 如果小于accept_delay*10毫秒，判断为accept
											cur_score <= cur_score + 1; -- 更新分数、总分、判断结果、判定状态
											cur_result <= 1;
											cur_judge_state(1) <= '1';
										else
											if ((current_time < next_key_time(1) and next_key_time(1) - current_time < miss_delay) 
											or (current_time >= next_key_time(1) and current_time - next_key_time(1) < miss_delay)) then
												-- 如果小于miss_delay*10毫秒，判断为miss
												cur_score <= cur_score; -- 更新分数、总分、判断结果、判定状态
												cur_result <= 0;
												cur_judge_state(1) <= '0';
											else
												-- 如果时间大于miss_delay*10毫秒，视为无效按键
												cur_score <= cur_score;
												cur_result <= cur_result;
												cur_judge_state(1) <= cur_judge_state(1);
											end if;
										end if;
									end if;
								end if;
							else -- 如果有新按键到来
								cur_total_score <= cur_total_score + 5;
								cur_score <= cur_score;
								cur_result <= cur_result;
								cur_judge_state(1) <= '0';
								cur_key_time(1) <= next_key_time(1);
							end if;
						else -- 如果已经判定当前键位
							cur_score <= cur_score;
							cur_result <= cur_result;
							if (cur_key_time(1) = next_key_time(1)) then -- 如果下一个按键没有到来
								cur_judge_state(1) <= '1'; -- 保持判定状态、按键时间
								cur_key_time(1) <= cur_key_time(1);
							else -- 如果下一个按键到来
								cur_total_score <= cur_total_score + 5;
								cur_judge_state(1) <= '0'; -- 更新判定状态、按键时间
								cur_key_time(1) <= next_key_time(1);
							end if;
						end if;
					else -- 如果按键此时抬起
						cur_key_state(1) <= key_state(1);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(1) = next_key_time(1)) then -- 如果当前没有新按键到来
							cur_judge_state(1) <= cur_judge_state(1); -- 保持判定状态、按键时间
							cur_key_time(1) <= cur_key_time(1);
						else -- 如果当前新按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(1) <= '0'; -- 更新判定状态、按键时间
							cur_key_time(1) <= next_key_time(1);
						end if;
					end if;
				when "10" =>
					cur_index <= "11";
					if (cur_key_state(2) = key_state(2)) then -- 如果键盘状态没有变化
						cur_score <= cur_score; --分数、总分、结果、按键状态不变
						cur_result <= cur_result;
						cur_key_state(2) <= cur_key_state(2);
						if (cur_key_time(2) = next_key_time(2)) then -- 如果没有下一个按键到来
						cur_judge_state(2) <= cur_judge_state(2); -- 判断状态与当前按键时间不变 
							cur_key_time(2) <= cur_key_time(2);
						else -- 如果下一个按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(2) <= '0'; -- 重置判定状态、更新当前按键时间
							cur_key_time(2) <= next_key_time(2);
						end if;
					elsif (key_state(2) = '1') then -- 如果按键在此刻按下
						cur_key_state(2) <= key_state(2); -- 更新当前按键状态
						if (cur_judge_state(2) = '0') then -- 如果还未判定当前键位
							if (cur_key_time(2) = next_key_time(2)) then -- 如果当前没有新按键到来
								cur_key_time(2) <= cur_key_time(2); -- 保持当前按键时间
								if ((current_time < next_key_time(2) and next_key_time(2) - current_time < perfect_delay) 
								or (current_time >= next_key_time(2) and current_time - next_key_time(2) < perfect_delay)) then
									-- 如果小于perfect_delay*10毫秒，判断为prefect
									cur_score <= cur_score + 5; -- 更新分数、总分、判断结果、判定状态
									cur_result <= 5;
									cur_judge_state(2) <= '1';
								else
									if ((current_time < next_key_time(2) and next_key_time(2) - current_time < great_delay) 
									or (current_time >= next_key_time(2) and current_time - next_key_time(2) < great_delay)) then
										-- 如果小于great_delay*10毫秒，判断为great
										cur_score <= cur_score + 3; -- 更新分数、总分、判断结果、判定状态
										cur_result <= 3;
										cur_judge_state(2) <= '1';
									else
										if ((current_time < next_key_time(2) and next_key_time(2) - current_time < accept_delay) 
										or (current_time >= next_key_time(2) and current_time - next_key_time(2) < accept_delay)) then
											-- 如果小于accept_delay*10毫秒，判断为accept
											cur_score <= cur_score + 1; -- 更新分数、总分、判断结果、判定状态
											cur_result <= 1;
											cur_judge_state(2) <= '1';
										else
											if ((current_time < next_key_time(2) and next_key_time(2) - current_time < miss_delay) 
											or (current_time >= next_key_time(2) and current_time - next_key_time(2) < miss_delay)) then
												-- 如果小于miss_delay*10毫秒，判断为miss
												cur_score <= cur_score; -- 更新分数、总分、判断结果、判定状态
												cur_result <= 0;
												cur_judge_state(2) <= '0';
											else
												-- 如果时间大于miss_delay*10毫秒，视为无效按键
												cur_score <= cur_score;
												cur_result <= cur_result;
												cur_judge_state(2) <= cur_judge_state(2);
											end if;
										end if;
									end if;
								end if;
							else -- 如果有新按键到来
								cur_total_score <= cur_total_score + 5;
								cur_score <= cur_score;
								cur_result <= cur_result;
								cur_judge_state(2) <= '0';
								cur_key_time(2) <= next_key_time(2);
							end if;
						else -- 如果已经判定当前键位
							cur_score <= cur_score;
							cur_result <= cur_result;
							if (cur_key_time(2) = next_key_time(2)) then -- 如果下一个按键没有到来
								cur_judge_state(2) <= '1'; -- 保持判定状态、按键时间
								cur_key_time(2) <= cur_key_time(2);
							else -- 如果下一个按键到来
								cur_total_score <= cur_total_score + 5;
								cur_judge_state(2) <= '0'; -- 更新判定状态、按键时间
								cur_key_time(2) <= next_key_time(2);
							end if;
						end if;
					else -- 如果按键此时抬起
						cur_key_state(2) <= key_state(2);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(2) = next_key_time(2)) then -- 如果当前没有新按键到来
							cur_judge_state(2) <= cur_judge_state(2); -- 保持判定状态、按键时间
							cur_key_time(2) <= cur_key_time(2);
						else -- 如果新按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(2) <= '0'; -- 更新判定状态、按键时间
							cur_key_time(2) <= next_key_time(2);
						end if;
					end if;
				when "11" =>
					cur_index <= "00";
					if (cur_key_state(3) = key_state(3)) then -- 如果键盘状态没有变化
						cur_score <= cur_score; --分数、总分、结果、按键状态不变
						cur_result <= cur_result;
						cur_key_state(3) <= cur_key_state(3);
						if (cur_key_time(3) = next_key_time(3)) then -- 如果没有下一个按键到来
						cur_judge_state(3) <= cur_judge_state(3); -- 判断状态与当前按键时间不变 
							cur_key_time(3) <= cur_key_time(3);
						else -- 如果下一个按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(3) <= '0'; -- 重置判定状态、更新当前按键时间
							cur_key_time(3) <= next_key_time(3);
						end if;
					elsif (key_state(3) = '1') then -- 如果按键在此刻按下
						cur_key_state(3) <= key_state(3); -- 更新当前按键状态
						if (cur_judge_state(3) = '0') then -- 如果还未判定当前键位
							if (cur_key_time(3) = next_key_time(3)) then -- 如果当前没有新按键到来
								cur_key_time(3) <= cur_key_time(3); -- 保持当前按键时间
								if ((current_time < next_key_time(3) and next_key_time(3) - current_time < perfect_delay) 
								or (current_time >= next_key_time(3) and current_time - next_key_time(3) < perfect_delay)) then
									-- 如果小于perfect_delay*10毫秒，判断为prefect
									cur_score <= cur_score + 5; -- 更新分数、总分、判断结果、判定状态
									cur_result <= 5;
									cur_judge_state(3) <= '1';
								else
									if ((current_time < next_key_time(3) and next_key_time(3) - current_time < great_delay) 
									or (current_time >= next_key_time(3) and current_time - next_key_time(3) < great_delay)) then
										-- 如果小于great_delay*10毫秒，判断为great
										cur_score <= cur_score + 3; -- 更新分数、总分、判断结果、判定状态
										cur_result <= 3;
										cur_judge_state(3) <= '1';
									else
										if ((current_time < next_key_time(3) and next_key_time(3) - current_time < accept_delay) 
										or (current_time >= next_key_time(3) and current_time - next_key_time(3) < accept_delay)) then
											-- 如果小于accept_delay*10毫秒，判断为accept
											cur_score <= cur_score + 1; -- 更新分数、总分、判断结果、判定状态
											cur_result <= 1;
											cur_judge_state(3) <= '1';
										else
											if ((current_time < next_key_time(3) and next_key_time(3) - current_time < miss_delay) 
											or (current_time >= next_key_time(3) and current_time - next_key_time(3) < miss_delay)) then
												-- 如果小于miss_delay*10毫秒，判断为miss
												cur_score <= cur_score; -- 更新分数、总分、判断结果、判定状态
												cur_result <= 0;
												cur_judge_state(3) <= '0';
											else
												-- 如果时间大于miss_delay*10毫秒，视为无效按键
												cur_score <= cur_score;
												cur_result <= cur_result;
												cur_judge_state(3) <= cur_judge_state(3);
											end if;
										end if;
									end if;
								end if;
							else -- 如果有新按键到来
								cur_total_score <= cur_total_score + 5;
								cur_score <= cur_score;
								cur_result <= cur_result;
								cur_judge_state(3) <= '0';
								cur_key_time(3) <= next_key_time(3);
							end if;
						else -- 如果已经判定当前键位
							cur_score <= cur_score;
							cur_result <= cur_result;
							if (cur_key_time(3) = next_key_time(3)) then -- 如果下一个按键没有到来
								cur_judge_state(3) <= '1'; -- 保持判定状态、按键时间
								cur_key_time(3) <= cur_key_time(3);
							else -- 如果下一个按键到来
								cur_total_score <= cur_total_score + 5;
								cur_judge_state(3) <= '0'; -- 更新判定状态、按键时间
								cur_key_time(3) <= next_key_time(3);
							end if;
						end if;
					else -- 如果按键此时抬起
						cur_key_state(3) <= key_state(3);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(3) = next_key_time(3)) then -- 如果当前没有新按键到来
							cur_judge_state(3) <= cur_judge_state(3); -- 保持判定状态、按键时间
							cur_key_time(3) <= cur_key_time(3);
						else -- 如果新按键到来
							cur_total_score <= cur_total_score + 5;
							cur_judge_state(3) <= '0'; -- 更新判定状态、按键时间
							cur_key_time(3) <= next_key_time(3);
						end if;
					end if;
				when others =>
					cur_index <= "00";
			end case;
		end if;
	end process;
end judge_0;