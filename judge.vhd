library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity judge is
	generic (
		accept_delay_ms : integer := 50;
		great_dalay_ms : integer := 30;
		profect_dalay_ms : integer := 10
	);
	port (
		reset : in std_logic; -- 重置信号
		next_key_time_ms: in array_int_4; --下一待按键时刻（毫秒）
		key_state: in std_logic_vector(3 downto 0); --按键状态
		current_time_ms : in integer; --当前时刻（毫秒）
		score: out integer; --得分输出
		result: out integer --操作结果输出
	);
end judge;

architecture judge_0 of judge is
signal cur_score : integer := 0; -- 当前分数
signal judge_state : std_logic_vector(3 downto 0) := "0000"; -- 当前判定状态
signal cur_key_time_ms : array_int_4; -- 当前键时刻（毫秒）
begin
	------------------------------------------------------
	-- 输出当前分数
	score <= cur_score;
	------------------------------------------------------
	-- 新的键到来时刷新状态
	process (next_key_time_ms)
	begin
		if (next_key_time_ms(0) /= cur_key_time_ms(0)) then
			judge_state(0) <= '0'
			cur_key_time_ms(0) <= next_key_time_ms(0)
		end if;
		if (next_key_time_ms(1) /= cur_key_time_ms(1)) then
			judge_state(1) <= '1'
			cur_key_time_ms(1) <= next_key_time_ms(1)
		end if;
		if (next_key_time_ms(2) /= cur_key_time_ms(2)) then
			judge_state(2) <= '2'
			cur_key_time_ms(2) <= next_key_time_ms(2)
		end if;
		if (next_key_time_ms(3) /= cur_key_time_ms(3)) then
			judge_state(3) <= '3'
			cur_key_time_ms(3) <= next_key_time_ms(3)
		end if;
	------------------------------------------------------
	-- 判定
	process (reset, key_state)
	begin
		if (reset = '0') then
			cur_score <= 0;
			judge_state <= "0000";
			cur_key_time_ms(0) <= -1;
			cur_key_time_ms(1) <= -1;
			cur_key_time_ms(2) <= -1;
			cur_key_time_ms(3) <= -1;
		else
			if (rising_edge(key_state(0))) then
				if (key_state(0) = '0') then
					if ((current_time_ms < next_key_time_ms(0) and next_key_time_ms(0) - current_time_ms < profect_dalay_ms) 
					or (current_time_ms > next_key_time_ms(0) and current_time_ms - next_key_time_ms(0) < profect_dalay_ms)) then
						cur_score <= cur_score + 5;
						result <= 5;
						key_state(0) <= '1';
					else
						if ((current_time_ms < next_key_time_ms(0) and next_key_time_ms(0) - current_time_ms < great_dalay_ms) 
						or (current_time_ms > next_key_time_ms(0) and current_time_ms - next_key_time_ms(0) < great_dalay_ms)) then
							cur_score <= cur_score + 3;
							result <= 3;
							key_state(0) <= '1';
						else
							if ((current_time_ms < next_key_time_ms(0) and next_key_time_ms(0) - current_time_ms < accept_delay_ms) 
							or (current_time_ms > next_key_time_ms(0) and current_time_ms - next_key_time_ms(0) < accept_delay_ms)) then
								cur_score <= cur_score + 1;
								result <= 1;
								key_state(0) <= '1';
							else
								cur_score <= cur_score;
								result <= 0;
								key_state(0) <= '0';
						end if;
					end if;
				else
					cur_score <= cur_score;
					result <= 0;
				end if;
			end if;
			if (rising_edge(key_state(1))) then
				if ((current_time_ms < next_key_time_ms(1) and next_key_time_ms(1) - current_time_ms < max_delay_ms) 
				or (current_time_ms > next_key_time_ms(1) and current_time_ms - next_key_time_ms(1) < max_delay_ms)) then
					cur_score <= cur_score + 300;
				end if;
			end if;
			if (rising_edge(key_state(2))) then
				if ((current_time_ms < next_key_time_ms(2) and next_key_time_ms(2) - current_time_ms < max_delay_ms) 
				or (current_time_ms > next_key_time_ms(2) and current_time_ms - next_key_time_ms(2) < max_delay_ms)) then
					cur_score <= cur_score + 300;
				end if;
			end if;
			if (rising_edge(key_state(3))) then
				if ((current_time_ms < next_key_time_ms(3) and next_key_time_ms(3) - current_time_ms < max_delay_ms) 
				or (current_time_ms > next_key_time_ms(3) and current_time_ms - next_key_time_ms(3) < max_delay_ms)) then
					cur_score <= cur_score + 300;
				end if;
			end if;
		end if;
	end process;
end judge_0;