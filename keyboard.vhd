library ieee;
use ieee.std_logic_1164.all;
use work.types.all;

entity keyboard is --键盘模块
	port(
		main_state: in main_state_type; --主模块状态输入
		keyboard_data: in std_logic; --键盘数据输入
		keyboard_clk: in std_logic; --键盘时钟输入
		filter_clk_5M: in std_logic; --滤波5MHz时钟输入
		key_state_p1: out std_logic_vector(3 downto 0); --玩家1按键状态输出
		key_state_p2: out std_logic_vector(3 downto 0) --玩家2按键状态输出
	);
end keyboard;

architecture bhv of keyboard is
	type state_type is (DELAY, START, D0, D1, D2, D3, D4, D5, D6, D7, PARITY, STOP, FINISH); --状态类型
	signal state: state_type; --当前状态
	signal code: std_logic_vector(7 downto 0); --扫描码
	signal last_code: std_logic_vector(7 downto 0); --上一成功读取的扫描码
	signal data: std_logic; --滤波后的数据
	signal clk1: std_logic; --滤波中间时钟1
	signal clk2: std_logic; --滤波中间时钟2
	signal clk: std_logic; --滤波后的时钟
	signal odd: std_logic; --奇校验
	signal ok: std_logic; --成功读取一个扫描码标识
begin
	clk1 <= keyboard_clk when rising_edge(filter_clk_5M);
	clk2 <= clk1 when rising_edge(filter_clk_5M);
	clk <= (not clk1) and clk2;
	data <= keyboard_data when rising_edge(filter_clk_5M);
	odd <= code(0) xor code(1) xor code(2) xor code(3) xor code(4) xor code(5) xor code(6) xor code(7);

	process(filter_clk_5M) --扫描码读取进程
	begin
		if rising_edge(filter_clk_5M) then
			ok <= '0';
			case state is 
				when DELAY =>
					state <= START;
				when START =>
					if clk = '1' then
						if data = '0' then
							state <= D0;
						else
							state <= DELAY;
						end if;
					end if;
				when D0 =>
					if clk = '1' then
						code(0) <= data;
						state <= D1;
					end if;
				when D1 =>
					if clk = '1' then
						code(1) <= data;
						state <= D2;
					end if;
				when D2 =>
					if clk = '1' then
						code(2) <= data;
						state <= D3;
					end if;
				when D3 =>
					if clk = '1' then
						code(3) <= data;
						state <= D4;
					end if;
				when D4 =>
					if clk = '1' then
						code(4) <= data;
						state <= D5;
					end if;
				when D5 =>
					if clk = '1' then
						code(5) <= data;
						state <= D6;
					end if;
				when D6 =>
					if clk = '1' then
						code(6) <= data;
						state <= D7;
					end if;
				when D7 =>
					if clk = '1' then
						code(7) <= data;
						state <= PARITY;
					end if ;
				when PARITY =>
					if clk = '1' then
						if (data xor odd) = '1' then
							state <= STOP;
						else
							state <= DELAY;
						end if;
					end if;
				when STOP =>
					if clk = '1' then
						if data = '1' then
							state <= FINISH;
						else
							state <= DELAY;
						end if;
					end if;
				when FINISH =>
					state <= DELAY;
					ok <= '1';
				when others =>
					state <= DELAY;
			end case;
		end if;
	end process;

	process(main_state, ok) --按键状态维护进程
	begin
		if main_state = RUN then --主模块RUN状态时根据读取的扫描码维护按键状态
			if rising_edge(ok) then
				if last_code = x"F0" then --断码
					case code is
						when x"6B" =>
							key_state_p1(3) <= '0';
						when x"73" =>
							key_state_p1(2) <= '0';
						when x"74" =>
							key_state_p1(1) <= '0';
						when x"79" =>
							key_state_p1(0) <= '0';
						when x"1C" =>
							key_state_p2(3) <= '0';
						when x"1B" =>
							key_state_p2(2) <= '0';
						when x"23" =>
							key_state_p2(1) <= '0';
						when x"2B" =>
							key_state_p2(0) <= '0';
						when others =>
					end case;
				else --通码
					case code is
						when x"6B" =>
							key_state_p1(3) <= '1';
						when x"73" =>
							key_state_p1(2) <= '1';
						when x"74" =>
							key_state_p1(1) <= '1';
						when x"79" =>
							key_state_p1(0) <= '1';
						when x"1C" =>
							key_state_p2(3) <= '1';
						when x"1B" =>
							key_state_p2(2) <= '1';
						when x"23" =>
							key_state_p2(1) <= '1';
						when x"2B" =>
							key_state_p2(0) <= '1';
						when others =>
					end case;
				end if;
				last_code <= code;
			end if;
		else --主模块其余状态时按键状态保持为未按下
			key_state_p1 <= (others => '0');
			key_state_p2 <= (others => '0');
		end if;
	end process;
end bhv;