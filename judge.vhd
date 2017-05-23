library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.types.all;

entity judge is
	generic (
		max_delay_ms : integer := 50
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
signal cur_key_time_ms : array_int_4;
begin
	------------------------------------------------------
	-- 输出当前分数
	score <= cur_score;
	------------------------------------------------------
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
				if ((current_time_ms < next_key_time_ms(0) and next_key_time_ms(0) - current_time_ms < max_delay_ms) 
				or (current_time_ms > next_key_time_ms(0) and current_time_ms - next_key_time_ms(0) < max_delay_ms)) then
					cur_score <= cur_score + 300;
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