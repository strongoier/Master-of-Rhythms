library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity judge is --判定模块
	generic (
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
		score: out integer; --得分输出
		result: out integer --操作结果输出
	);
end judge;

architecture judge_0 of judge is
signal cur_index : std_logic_vector(1 downto 0) := "00"; -- 当前判断轨道
signal cur_score : integer := 0; -- 当前分数
signal cur_result : integer := 0; -- 当前结果
signal cur_judge_state : std_logic_vector(3 downto 0) := "0000"; -- 当前判定状态
signal cur_key_state : std_logic_vector(3 downto 0) := "0000"; -- 当前按键状态
signal cur_key_time : array_int_4; -- 当前按键时间
begin
	------------------------------------------------------
	-- 输出当前分数
	score <= cur_score;
	result <= cur_result;
	------------------------------------------------------
	-- 扫描、更新
	process (main_state, fclk)
	begin
		if (main_state = READY) then
			cur_index <= "00";
			cur_score <= 0;
			cur_result <= 0;
			cur_judge_state <= "0000";
			cur_key_state <= "0000";
			cur_key_time(0) <= -5;
			cur_key_time(1) <= -5;
			cur_key_time(2) <= -5;
			cur_key_time(3) <= -5;
		elsif (main_state = RUN and rising_edge(fclk)) then
			case cur_index is
				when "00" =>
					cur_index <= "01";
					if (cur_key_state(0) = key_state(0)) then
						cur_score <= cur_score;
						cur_result <= cur_result;
						cur_key_state(0) <= cur_key_state(0);
						if (cur_key_time(0) = next_key_time(0)) then
							cur_judge_state(0) <= cur_judge_state(0);
							cur_key_time(0) <= cur_key_time(0);
						else
							cur_judge_state(0) <= '0';
							cur_key_time(0) <= next_key_time(0);
						end if;
					elsif (key_state(0) = '1') then
						cur_key_state(0) <= key_state(0);
						if (cur_judge_state(0) = '0') then
							if (cur_key_time(0) = next_key_time(0)) then
								cur_key_time(0) <= cur_key_time(0);
								if ((current_time < next_key_time(0) and next_key_time(0) - current_time < perfect_delay) 
								or (current_time >= next_key_time(0) and current_time - next_key_time(0) < perfect_delay)) then
									cur_score <= cur_score + 5;
									cur_result <= 5;
									cur_judge_state(0) <= '1';
								else
									if ((current_time < next_key_time(0) and next_key_time(0) - current_time < great_delay) 
									or (current_time >= next_key_time(0) and current_time - next_key_time(0) < great_delay)) then
										cur_score <= cur_score + 3;
										cur_result <= 3;
										cur_judge_state(0) <= '1';
									else
										if ((current_time < next_key_time(0) and next_key_time(0) - current_time < accept_delay) 
										or (current_time >= next_key_time(0) and current_time - next_key_time(0) < accept_delay)) then
											cur_score <= cur_score + 1;
											cur_result <= 1;
											cur_judge_state(0) <= '1';
										else
											cur_score <= cur_score;
											cur_result <= 0;
											cur_judge_state(0) <= '0';
										end if;
									end if;
								end if;
							else
								cur_score <= cur_score;
								cur_result <= 0;
								cur_judge_state(0) <= '0';
								cur_key_time(0) <= next_key_time(0);
							end if;
						else
							cur_score <= cur_score;
							if (cur_key_time(0) = next_key_time(0)) then
								cur_judge_state(0) <= '1';
								cur_key_time(0) <= cur_key_time(0);
								cur_result <= cur_result;
							else
								cur_result <= 0;
								cur_judge_state(0) <= '0';
								cur_key_time(0) <= next_key_time(0);
							end if;
						end if;
					else
						cur_key_state(0) <= key_state(0);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(0) = next_key_time(0)) then
							cur_judge_state(0) <= cur_judge_state(0);
							cur_key_time(0) <= cur_key_time(0);
						else
							cur_judge_state(0) <= '0';
							cur_key_time(0) <= next_key_time(0);
						end if;
					end if;
				when "01" =>
					cur_index <= "10";
					if (cur_key_state(1) = key_state(1)) then
						cur_score <= cur_score;
						cur_result <= cur_result;
						cur_key_state(1) <= cur_key_state(1);
						if (cur_key_time(1) = next_key_time(1)) then
							cur_judge_state(1) <= cur_judge_state(1);
							cur_key_time(1) <= cur_key_time(1);
						else
							cur_judge_state(1) <= '0';
							cur_key_time(1) <= next_key_time(1);
						end if;
					elsif (key_state(1) = '1') then
						cur_key_state(1) <= key_state(1);
						if (cur_judge_state(1) = '0') then
							if (cur_key_time(1) = next_key_time(1)) then
								cur_key_time(1) <= cur_key_time(1);
								if ((current_time < next_key_time(1) and next_key_time(1) - current_time < perfect_delay) 
								or (current_time >= next_key_time(1) and current_time - next_key_time(1) < perfect_delay)) then
									cur_score <= cur_score + 5;
									cur_result <= 5;
									cur_judge_state(1) <= '1';
								else
									if ((current_time < next_key_time(1) and next_key_time(1) - current_time < great_delay) 
									or (current_time >= next_key_time(1) and current_time - next_key_time(1) < great_delay)) then
										cur_score <= cur_score + 3;
										cur_result <= 3;
										cur_judge_state(1) <= '1';
									else
										if ((current_time < next_key_time(1) and next_key_time(1) - current_time < accept_delay) 
										or (current_time >= next_key_time(1) and current_time - next_key_time(1) < accept_delay)) then
											cur_score <= cur_score + 1;
											cur_result <= 1;
											cur_judge_state(1) <= '1';
										else
											cur_score <= cur_score;
											cur_result <= 0;
											cur_judge_state(1) <= '0';
										end if;
									end if;
								end if;
							else
								cur_score <= cur_score;
								cur_result <= 0;
								cur_judge_state(1) <= '0';
								cur_key_time(1) <= next_key_time(1);
							end if;
						else
							cur_score <= cur_score;
							if (cur_key_time(1) = next_key_time(1)) then
								cur_judge_state(1) <= '1';
								cur_key_time(1) <= cur_key_time(1);
								cur_result <= cur_result;
							else
								cur_result <= 0;
								cur_judge_state(1) <= '0';
								cur_key_time(1) <= next_key_time(1);
							end if;
						end if;
					else
						cur_key_state(1) <= key_state(1);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(1) = next_key_time(1)) then
							cur_judge_state(1) <= cur_judge_state(1);
							cur_key_time(1) <= cur_key_time(1);
						else
							cur_judge_state(1) <= '0';
							cur_key_time(1) <= next_key_time(1);
						end if;
					end if;
				when "10" =>
					cur_index <= "11";
					if (cur_key_state(2) = key_state(2)) then
						cur_score <= cur_score;
						cur_result <= cur_result;
						cur_key_state(2) <= cur_key_state(2);
						if (cur_key_time(2) = next_key_time(2)) then
							cur_judge_state(2) <= cur_judge_state(2);
							cur_key_time(2) <= cur_key_time(2);
						else
							cur_judge_state(2) <= '0';
							cur_key_time(2) <= next_key_time(2);
						end if;
					elsif (key_state(2) = '1') then
						cur_key_state(2) <= key_state(2);
						if (cur_judge_state(2) = '0') then
							if (cur_key_time(2) = next_key_time(2)) then
								cur_key_time(2) <= cur_key_time(2);
								if ((current_time < next_key_time(2) and next_key_time(2) - current_time < perfect_delay) 
								or (current_time >= next_key_time(2) and current_time - next_key_time(2) < perfect_delay)) then
									cur_score <= cur_score + 5;
									cur_result <= 5;
									cur_judge_state(2) <= '1';
								else
									if ((current_time < next_key_time(2) and next_key_time(2) - current_time < great_delay) 
									or (current_time >= next_key_time(2) and current_time - next_key_time(2) < great_delay)) then
										cur_score <= cur_score + 3;
										cur_result <= 3;
										cur_judge_state(2) <= '1';
									else
										if ((current_time < next_key_time(2) and next_key_time(2) - current_time < accept_delay) 
										or (current_time >= next_key_time(2) and current_time - next_key_time(2) < accept_delay)) then
											cur_score <= cur_score + 1;
											cur_result <= 1;
											cur_judge_state(2) <= '1';
										else
											cur_score <= cur_score;
											cur_result <= 0;
											cur_judge_state(2) <= '0';
										end if;
									end if;
								end if;
							else
								cur_score <= cur_score;
								cur_result <= 0;
								cur_judge_state(2) <= '0';
								cur_key_time(2) <= next_key_time(2);
							end if;
						else
							cur_score <= cur_score;
							if (cur_key_time(2) = next_key_time(2)) then
								cur_judge_state(2) <= '1';
								cur_key_time(2) <= cur_key_time(2);
								cur_result <= cur_result;
							else
								cur_result <= 0;
								cur_judge_state(2) <= '0';
								cur_key_time(2) <= next_key_time(2);
							end if;
						end if;
					else
						cur_key_state(2) <= key_state(2);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(2) = next_key_time(2)) then
							cur_judge_state(2) <= cur_judge_state(2);
							cur_key_time(2) <= cur_key_time(2);
						else
							cur_judge_state(2) <= '0';
							cur_key_time(2) <= next_key_time(2);
						end if;
					end if;
				when "11" =>
					cur_index <= "00";
					if (cur_key_state(3) = key_state(3)) then
						cur_score <= cur_score;
						cur_result <= cur_result;
						cur_key_state(3) <= cur_key_state(3);
						if (cur_key_time(3) = next_key_time(3)) then
							cur_judge_state(3) <= cur_judge_state(3);
							cur_key_time(3) <= cur_key_time(3);
						else
							cur_judge_state(3) <= '0';
							cur_key_time(3) <= next_key_time(3);
						end if;
					elsif (key_state(3) = '1') then
						cur_key_state(3) <= key_state(3);
						if (cur_judge_state(3) = '0') then
							if (cur_key_time(3) = next_key_time(3)) then
								cur_key_time(3) <= cur_key_time(3);
								if ((current_time < next_key_time(3) and next_key_time(3) - current_time < perfect_delay) 
								or (current_time >= next_key_time(3) and current_time - next_key_time(3) < perfect_delay)) then
									cur_score <= cur_score + 5;
									cur_result <= 5;
									cur_judge_state(3) <= '1';
								else
									if ((current_time < next_key_time(3) and next_key_time(3) - current_time < great_delay) 
									or (current_time >= next_key_time(3) and current_time - next_key_time(3) < great_delay)) then
										cur_score <= cur_score + 3;
										cur_result <= 3;
										cur_judge_state(3) <= '1';
									else
										if ((current_time < next_key_time(3) and next_key_time(3) - current_time < accept_delay) 
										or (current_time >= next_key_time(3) and current_time - next_key_time(3) < accept_delay)) then
											cur_score <= cur_score + 1;
											cur_result <= 1;
											cur_judge_state(3) <= '1';
										else
											cur_score <= cur_score;
											cur_result <= 0;
											cur_judge_state(3) <= '0';
										end if;
									end if;
								end if;
							else
								cur_score <= cur_score;
								cur_result <= 0;
								cur_judge_state(3) <= '0';
								cur_key_time(3) <= next_key_time(3);
							end if;
						else
							cur_score <= cur_score;
							if (cur_key_time(3) = next_key_time(3)) then
								cur_judge_state(3) <= '1';
								cur_key_time(3) <= cur_key_time(3);
								cur_result <= cur_result;
							else
								cur_result <= 0;
								cur_judge_state(3) <= '0';
								cur_key_time(3) <= next_key_time(3);
							end if;
						end if;
					else
						cur_key_state(3) <= key_state(3);
						cur_score <= cur_score;
						cur_result <= cur_result;
						if (cur_key_time(3) = next_key_time(3)) then
							cur_judge_state(3) <= cur_judge_state(3);
							cur_key_time(3) <= cur_key_time(3);
						else
							cur_judge_state(3) <= '0';
							cur_key_time(3) <= next_key_time(3);
						end if;
					end if;
				when others =>
					cur_index <= "00";
			end case;
		end if;
	end process;
end judge_0;