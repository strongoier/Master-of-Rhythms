library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity judge is --判定模块
	generic (
		accept_delay : integer := 5;
		great_dalay : integer := 3;
		profect_dalay : integer := 1
	);
	port (
		reset : in std_logic; --重置信号
		next_key_time: in array_int_4; --下一待按键时刻（单位0.01秒）
		key_state: in std_logic_vector(3 downto 0); --按键状态
		current_time : in integer; --当前时刻（单位0.01秒）
		score: out integer; --得分输出
		result: out integer --操作结果输出
	);
end judge;

architecture judge_0 of judge is
signal cur_score : integer := 0; -- 当前分数
signal judge_state : std_logic_vector(3 downto 0) := "0000"; -- 当前判定状态
signal cur_key_time : array_int_4; -- 当前键时刻（毫秒）
begin
	------------------------------------------------------
	-- 输出当前分数
	score <= cur_score;
	------------------------------------------------------
	-- 新的键到来时刷新状态
	process (next_key_time)
	begin
		if (next_key_time(0) /= cur_key_time(0)) then
			judge_state(0) <= '0';
			cur_key_time(0) <= next_key_time(0);
		end if;
		if (next_key_time(1) /= cur_key_time(1)) then
			judge_state(1) <= '0';
			cur_key_time(1) <= next_key_time(1);
		end if;
		if (next_key_time(2) /= cur_key_time(2)) then
			judge_state(2) <= '0';
			cur_key_time(2) <= next_key_time(2);
		end if;
		if (next_key_time(3) /= cur_key_time(3)) then
			judge_state(3) <= '0';
			cur_key_time(3) <= next_key_time(3);
		end if;
	end process;
	------------------------------------------------------
	-- 判定
	process (reset, key_state)
	begin
		if (reset = '0') then
			cur_score <= 0;
			judge_state <= "0000";
			cur_key_time(0) <= -1;
			cur_key_time(1) <= -1;
			cur_key_time(2) <= -1;
			cur_key_time(3) <= -1;
		else
			if (rising_edge(key_state(0))) then
				if (judge_state(0) = '0') then
					if ((current_time < next_key_time(0) and next_key_time(0) - current_time < profect_dalay) 
					or (current_time > next_key_time(0) and current_time - next_key_time(0) < profect_dalay)) then
						cur_score <= cur_score + 5;
						result <= 5;
						judge_state(0) <= '1';
					else
						if ((current_time < next_key_time(0) and next_key_time(0) - current_time < great_dalay) 
						or (current_time > next_key_time(0) and current_time - next_key_time(0) < great_dalay)) then
							cur_score <= cur_score + 3;
							result <= 3;
							judge_state(0) <= '1';
						else
							if ((current_time < next_key_time(0) and next_key_time(0) - current_time < accept_delay) 
							or (current_time > next_key_time(0) and current_time - next_key_time(0) < accept_delay)) then
								cur_score <= cur_score + 1;
								result <= 1;
								judge_state(0) <= '1';
							else
								cur_score <= cur_score;
								result <= 0;
								judge_state(0) <= '0';
							end if;
						end if;
					end if;
				else
					cur_score <= cur_score;
					result <= 0;
					judge_state(0) <= '1';
				end if;
			end if;
			if (rising_edge(key_state(1))) then
				if (judge_state(1) = '0') then
					if ((current_time < next_key_time(1) and next_key_time(1) - current_time < profect_dalay) 
					or (current_time > next_key_time(1) and current_time - next_key_time(1) < profect_dalay)) then
						cur_score <= cur_score + 5;
						result <= 5;
						judge_state(1) <= '1';
					else
						if ((current_time < next_key_time(1) and next_key_time(1) - current_time < great_dalay) 
						or (current_time > next_key_time(1) and current_time - next_key_time(1) < great_dalay)) then
							cur_score <= cur_score + 3;
							result <= 3;
							judge_state(1) <= '1';
						else
							if ((current_time < next_key_time(1) and next_key_time(1) - current_time < accept_delay) 
							or (current_time > next_key_time(1) and current_time - next_key_time(1) < accept_delay)) then
								cur_score <= cur_score + 1;
								result <= 1;
								judge_state(1) <= '1';
							else
								cur_score <= cur_score;
								result <= 0;
								judge_state(1) <= '0';
							end if;
						end if;
					end if;
				else
					cur_score <= cur_score;
					result <= 0;
					judge_state(1) <= '1';
				end if;
			end if;
			if (rising_edge(key_state(2))) then
				if (judge_state(2) = '0') then
					if ((current_time < next_key_time(2) and next_key_time(2) - current_time < profect_dalay) 
					or (current_time > next_key_time(2) and current_time - next_key_time(2) < profect_dalay)) then
						cur_score <= cur_score + 5;
						result <= 5;
						judge_state(2) <= '1';
					else
						if ((current_time < next_key_time(2) and next_key_time(2) - current_time < great_dalay) 
						or (current_time > next_key_time(2) and current_time - next_key_time(2) < great_dalay)) then
							cur_score <= cur_score + 3;
							result <= 3;
							judge_state(2) <= '1';
						else
							if ((current_time < next_key_time(2) and next_key_time(2) - current_time < accept_delay) 
							or (current_time > next_key_time(2) and current_time - next_key_time(2) < accept_delay)) then
								cur_score <= cur_score + 1;
								result <= 1;
								judge_state(2) <= '1';
							else
								cur_score <= cur_score;
								result <= 0;
								judge_state(2) <= '0';
							end if;
						end if;
					end if;
				else
					cur_score <= cur_score;
					result <= 0;
					judge_state(2) <= '1';
				end if;
			end if;
			if (rising_edge(key_state(3))) then
				if (judge_state(3) = '0') then
					if ((current_time < next_key_time(3) and next_key_time(3) - current_time < profect_dalay) 
					or (current_time > next_key_time(3) and current_time - next_key_time(3) < profect_dalay)) then
						cur_score <= cur_score + 5;
						result <= 5;
						judge_state(3) <= '1';
					else
						if ((current_time < next_key_time(3) and next_key_time(3) - current_time < great_dalay) 
						or (current_time > next_key_time(3) and current_time - next_key_time(3) < great_dalay)) then
							cur_score <= cur_score + 3;
							result <= 3;
							judge_state(3) <= '1';
						else
							if ((current_time < next_key_time(3) and next_key_time(3) - current_time < accept_delay) 
							or (current_time > next_key_time(3) and current_time - next_key_time(3) < accept_delay)) then
								cur_score <= cur_score + 1;
								result <= 1;
								judge_state(3) <= '1';
							else
								cur_score <= cur_score;
								result <= 0;
								judge_state(3) <= '0';
							end if;
						end if;
					end if;
				else
					cur_score <= cur_score;
					result <= 0;
					judge_state(3) <= '1';
				end if;
			end if;
		end if;
	end process;
end judge_0;