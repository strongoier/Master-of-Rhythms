library ieee;
use ieee.std_logic_1164.all;

entity digital_7 is --点亮数字人生
	port(
		key: in std_logic_vector(3 downto 0); --数据输入
		display: out std_logic_vector(6 downto 0) --不带译码器的数码管输出
	);
end digital_7;

architecture bhv of digital_7 is
begin
	process(key) --不带译码器的数码管需要进行译码处理
	begin
		case key is --以下是0~f编码规则
			when "0000" => display <= "1111110"; --0
			when "0001" => display <= "1100000"; --1
			when "0010" => display <= "1011101"; --2
			when "0011" => display <= "1111001"; --3
			when "0100" => display <= "1100011"; --4
			when "0101" => display <= "0111011"; --5
			when "0110" => display <= "0111111"; --6
			when "0111" => display <= "1101000"; --7
			when "1000" => display <= "1111111"; --8
			when "1001" => display <= "1111011"; --9
			when "1010" => display <= "1101111"; --a
			when "1011" => display <= "0110111"; --b
			when "1100" => display <= "0011110"; --c
			when "1101" => display <= "1110101"; --d
			when "1110" => display <= "0011111"; --e
			when "1111" => display <= "0001111"; --f
			when others => display <= "0000000"; --其他情况全灭
		end case;
	end process;
end bhv;