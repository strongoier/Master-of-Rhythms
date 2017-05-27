library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity add4bitdec is
	port (
		ain, bin : in std_logic_vector(3 downto 0);
		cin : in std_logic;
		fout : out std_logic_vector(3 downto 0);
		cout : out std_logic
	);
end add4bitdec;

architecture add4bitdec_0 of add4bitdec is
signal tmp1, tmp2 : std_logic_vector(4 downto 0);
begin
	tmp1 <= "00000" + ain + bin + cin;
	fout <= tmp2(3 downto 0);
	cout <= tmp2(4);
	process (tmp1)
	begin
		if (tmp1 > "1001") then
			tmp2 <= tmp1 + "00110";
		else
			tmp2 <= tmp1;
		end if;
	end process;
end architecture add4bitdec_0;

entity add16bitdec is
	port (
		ain, bin : in std_logic_vector(15 downto 0);
		cin : in std_logic;
		fout : out std_logic_vector(15 downto 0);
		cout : out std_logic
	);
end add16bitdec;

architecture add16bitdec_0 of add16bitdec of
component add4bitdec is
	port (
		ain, bin : in std_logic_vector(3 downto 0);
		cin : in std_logic;
		fout : out std_logic_vector(3 downto 0);
		cout : out std_logic
	);
end component;
signal c1, c2, c3 : std_logic;
begin
	add4bitdec_0 : add4bitdec port map(ain(3 downto 0), bin(3 downto 0), cin, fout(3 downto 0), c1);
	add4bitdec_1 : add4bitdec port map(ain(7 downto 4), bin(7 downto 4), c1, fout(7 downto 4), c2);
	add4bitdec_2 : add4bitdec port map(ain(11 downto 8), bin(11 downto 8), c2, fout(11 downto 8), c3);
	add4bitdec_4 : add4bitdec port map(ain(15 downto 12), bin(15 downto 12), c3, fout(15 downto 12), cout);
end add16bitdec_0;

entity add16bit is
	port (
		result : in std_logic_vector(3 downto 0);
		clk : in std_logic;
		score : out std_logic_vector(15 downto 0)
	);
end add16bit;

architecture add16bit_0 of add16bit is
component add16bitdec is
	port (
		ain, bin : in std_logic_vector(15 downto 0);
		cin : in std_logic;
		fout : out std_logic_vector(15 downto 0);
		cout : out std_logic
	);
end component;
signal addnum : std_logic_vector(15 downto 0);
signal cur_score : std_logic_vector(15 downto 0) := "0000000000000000";
signal cout : std_logic;
signal pre_score : std_logic_vector(15 downto 0) := "0000000000000000";
begin
	add16bitdec_0 : add16bitdec port map(pre_score, addnum, '0', cur_score, cout);
	score <= cur_score;
	addnum <= "000000000000" & result;
	process (clk)
	begin
		if (falling_edge(clk)) then
			pre_score <= cur_score;
		end if;
	end process;
end add16bit_0;
