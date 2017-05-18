package types is --各模块所需的类型定义
	type array_int_4 is array(3 downto 0) of integer; --长度为4的int数组
	type main_state_type is (READY, RUN, STOP); --主模块状态类型
end types;