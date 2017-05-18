library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity clk_divider is --分频器
	generic (
		div_num : integer := 10 -- 一周期对应时钟数
	);	
	port(
		clk_in: in std_logic; --输入时钟
		clk_out: out std_logic --输出时钟
	);
end clk_divider;

architecture clk_divider_0 of clk_divider is
signal result : std_logic := '0'; -- 内部分频时钟
signal cnt : integer := 0; -- 分频用计数器
constant low_num : integer := div_num / 2; -- 低电平对应时钟数
constant high_num : integer := (div_num + 1) / 2; -- 高电平对应时钟数
begin
	----------------------------------------------------
	-- 输出时钟
	clk_out <= result;
	----------------------------------------------------
	-- 分频过程
	process (clk_in)
	begin
		if (rising_edge(clk_in)) then
			if ((result = '0' and cnt < low_num - 1) or (result = '1' and cnt < high_num - 1)) then
				cnt <= cnt + 1;
			else
				cnt <= 0;
				result <= not result;
			end if;
		end if;
	end process;
end clk_divider_0;