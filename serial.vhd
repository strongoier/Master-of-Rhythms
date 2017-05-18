library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity serial is
	generic (
		bit_num : integer := 8 -- 每次接受数据的位数
	);
	port (
		bclk : in std_logic; -- 波特率16倍时钟，近似9600*16Hz
		reset : in std_logic; -- 重置信号
		-- 发送数据
		xmit_cmd_p : in std_logic; -- 发送控制信号（应尽量小于一个完整数据包发送时间）
		tx_data : in std_logic_vector(7 downto 0); -- 输入发送数据
		txd : out std_logic; -- 串口发送数据信号
		tx_ready : out std_logic; -- 成功发送新数据
		-- 接受数据
		rxd : in std_logic; -- 串口接受数据信号
		rx_ready : out std_logic; -- 成功接受新数据
		rx_data : out std_logic_vector(7 downto 0) -- 输出接受数据
	);
end serial;

architecture serial_0 of serial is
-- 发送数据
type tx_states is (t_idle, t_start, t_wait, t_shift, t_stop); -- 发送数据状态类型
signal tx_state : tx_states := t_idle; -- 发送数据状态变量
signal tx_clk_cnt : std_logic_vector(4 downto 0) := "00000"; -- 发送数据用时钟计数器
signal tx_bit_cnt : integer := 0; -- 记录当前发送数据位数
signal tmp_txd : std_logic; -- 内部数据缓冲区
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
	-- 发送数据
	txd <= tmp_txd; -- 输出发送数据
	process (bclk, reset, xmit_cmd_p, tx_data)
	begin
		if (reset = '0') then
			-- 重置相关信息
			tx_state <= t_idle;
			tx_ready <= '0';
			tmp_txd <= '1';
		elsif (rising_edge(bclk)) then
			-- 16倍波特率时钟上升沿
			case tx_state is
				when t_idle =>
					-- 状态1，等待数据帧发送命令
					if (xmit_cmd_p = '1') then
						-- 进入状态2
						tx_state <= t_start;
						tx_ready <= '0';
					else
						-- 保持状态1
						tx_state <= t_idle;
					end if;
				when t_start =>
					--状态2，发送信号至起始位
					if (tx_clk_cnt = "01111") then
						-- 已经计数15次，进入状态4
						tx_state <= t_shift;
						tx_clk_cnt <= "00000";
					else
						-- 保持状态2，继续计数，发送起始位
						tx_clk_cnt <= tx_clk_cnt + 1;
						tmp_txd <= '0';    
						tx_state <= t_start;
					end if;
				when t_wait =>
					--状态3，等待状态
					if (tx_clk_cnt >= "01110") then
						-- 已计数14次
						if (tx_bit_cnt = bit_num) then
							-- 所有bit均发送完毕，重置比特计数器
							tx_state <= t_stop;
							tx_bit_cnt <= 0;
							--tx_clk_cnt <= "00000";
						else
							-- 还有未发送bit，进入状态4
							tx_state <= t_shift;
						end if;
						-- 重置时钟计数器
						tx_clk_cnt <= "00000";
					else
						-- 保持状态3，继续计数
						tx_clk_cnt <= tx_clk_cnt + 1;
						tx_state <= t_wait;
					end if;
				when t_shift =>
					--状态4，将待发数据进行并串转换，发送当前bit，进入状态3
					tmp_txd <= tx_data(tx_bit_cnt);
					tx_bit_cnt <= tx_bit_cnt + 1;
					tx_state <= t_wait;
				when t_stop =>
					--状态 5，停止位发送状态
					if (tx_clk_cnt >= "01111") then
						if (xmit_cmd_p = '0') then
							-- 准备下一次发送
							tx_state <= t_idle;
							tx_clk_cnt <= "00000";
						else
							-- 如果xmit_cmd_p没有即时撤出，确保不会重复发送
							tx_clk_cnt <= tx_clk_cnt;
							tx_state <= t_stop;
						end if;
						-- 发送完成
						tx_ready <= '1';
					else
						-- 保持状态5，发送高电平一个波特率周期
						tx_clk_cnt <= tx_clk_cnt + 1;
						tmp_txd <= '1';
						tx_state <= t_stop;
					end if;
			   when others =>
					-- 进入状态1
					tx_state <= t_idle;
			end case;
		end if;
	end process;
	------------------------------------------------------------
	-- 接受数据
	process (bclk, reset, rxd_sync)
	begin
		if (reset = '0') then
			-- 重置相关信息
			rx_state <= r_start;
			rx_clk_cnt <= "0000";
		elsif (rising_edge(bclk)) then
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
						