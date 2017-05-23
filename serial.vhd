library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity serial is -- 串口模块
	generic (
		bit_num : integer := 8 -- 每次接受数据的位数
	);
	port (
		bclk : in std_logic; -- 波特率16倍时钟，近似9600*16Hz
		rxd : in std_logic; -- 串口接受数据信号
		rx_ready : out std_logic; -- 成功接受新数据
		rx_data : out std_logic_vector(7 downto 0) -- 输出接受数据
	);
end serial;

architecture serial_0 of serial is
-- 接受数据
type rx_states is (r_start, r_center, r_wait, r_sample, r_stop); -- 接受数据状态类型
signal rx_state : rx_states := r_start; -- 接受数据状态变量
signal rxd_sync : std_logic; -- 经过简单稳定的接受数据信号
signal rx_clk_cnt : std_logic_vector(3 downto 0) := "0000"; -- 接受数据用时钟计数器
signal rx_bit_cnt : integer := 0; -- 记录当前接受数据位数
signal rx_tmp_data : std_logic_vector(7 downto 0); -- 内部数据缓冲区
begin
	------------------------------------------------------------
	-- 稳定输入信号
	process (rxd)
	begin
		if (rxd = '0') then
			rxd_sync <= '0';
		else
			rxd_sync <= '1';
		end if;
	end process;
	------------------------------------------------------------
	-- 接受数据
	process (bclk, rxd_sync)
	begin
		if (rising_edge(bclk)) then
		-- 16倍波特率时钟上升沿
			case rx_state is
				when r_start =>
					-- 状态1，准备低电平开始信号
					if (rxd_sync = '0') then
						-- 进入状态2
						rx_state <= r_center;
						rx_ready <= '0';
						rx_bit_cnt <= 0;
					else
						-- 保持状态1
						rx_state <= r_start;
						rx_ready <= '0';
					end if;
				when r_center =>
					-- 状态2，确保低电平为开始信号（有一定长度）
					if (rxd_sync = '0') then
						if (rx_clk_cnt = "0100") then
							-- 确定为开始信号，进入状态3
							rx_state <= r_wait;
							rx_clk_cnt <= "0000";
						else
							-- 继续计数，保持状态2
							rx_clk_cnt <= rx_clk_cnt + 1;
							rx_state <= r_center;
						end if;
					else
						-- 低电平为毛刺，转到状态1
						rx_state <= r_start;
					end if;
				when r_wait =>
					-- 状态3，计数到数据位中点
					if (rx_clk_cnt >= "1110") then
						-- 读取/结束
						if (rx_bit_cnt = bit_num) then
							-- 进入状态5，结束
							rx_state <= r_stop;
						else
							-- 进入状态4，读取
							rx_state <= r_sample;
						end if;
						rx_clk_cnt <= "0000";
					else
						-- 保持状态3，继续计数
						rx_clk_cnt <= rx_clk_cnt + 1;
						rx_state <= r_wait;
					end if;
				when r_sample =>
					-- 状态4，读取当前数据位，转到状态3
					rx_tmp_data(rx_bit_cnt) <= rxd_sync;
					rx_bit_cnt <= rx_bit_cnt + 1;
					rx_state <= r_wait;
				when r_stop =>
					-- 状态5，结束
					rx_ready <= '1';
					rx_data <= rx_tmp_data;
					rx_state <= r_start;
				when others =>
					-- 转入状态1
					rx_state <= r_start;
			end case;
		end if;
	end process;
end serial_0;
						