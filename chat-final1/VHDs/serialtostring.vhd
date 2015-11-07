-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;
-------------------------------------------------------------------------------------

entity SerialToString is 
	port (
		reset	:	in std_logic;
		clk		:	in std_logic;
		
   	
		s_toRec	: out MyString_40d;
		s_toSend : in MyString_40d;

		wr		:	in std_logic;	-- controller to serialtostring to send! es
		rd		:	out std_logic;  -- 下边沿表示要变了！！  -- serialtostring to controller to send


		dataTshower	:	 BUFFER std_logic_vector(7 downto 0);	
		dataRshower	:	 BUFFER std_logic_vector(7 downto 0);
		
		
		----
		RxD :  in std_logic;				--  receive 
		TxD :  BUFFER std_logic;				--  tra 
		
		toSeeRdo	: out std_logic;
		bitOfRecTest : out std_logic_vector(7 downto 0)

	);
end entity;

architecture bhv of SerialToString is
signal		TXDO	:	 STD_LOGIC:='0';
signal		RXDO :  STD_LOGIC:='0';
signal		rdo	:   STD_LOGIC:='1';	--serial to serialtostring to receive!
signal		wro		: 	 std_logic:='0';	-- serialToString to serial to send!

signal 		test		:  std_logic_vector(3 downto 0);

signal		dataT	:	 std_logic_vector(7 downto 0);	
signal		dataR	:	 std_logic_vector(7 downto 0);

component serial is port
(
	Reset	:	in std_logic;
	dataT    :   in std_logic_vector(7 downto 0);		--  要输出去的!!
	dataR	  :	  out std_logic_vector(7 downto 0);		--  要输读进来的的!!
	

	clk :  in std_logic;				--- 11.0592M
	
	RxD :  in std_logic;				--  receive
	RXDO : BUFFER STD_LOGIC;
	TxD :  BUFFER std_logic;				--  tra
	TXDO	:	BUFFER STD_LOGIC;
	
	
	wr	:	in std_logic;	-- enable
	
	rdo : out std_logic
);
end component;
type STATE_TYPE is (s_init, s_idle, s_sb0, s_s0, s_s1, s_s2);
signal state : STATE_TYPE := s_init;
signal rtate : STATE_TYPE := s_init;

signal cnt_r : integer := 0;
signal cnt_s : integer := 0;
signal cnt_s2 : integer := 0;

signal dataBufferIn : std_logic_vector(7 downto 0);

signal toRecBuffer : MyString_40d;

constant COUNTER_MAX : integer := 47;

signal counter : integer range 0 to COUNTER_MAX := 0;

signal clock : std_logic := '0';

constant inteval : integer := 10;
signal counterInterval : integer range 0 to inteval := 0;

signal wrobuffer : std_logic := '0';

signal mytest		: 	std_logic_vector(3 downto 0) := "0000";

	
signal 		flag		:   std_logic := '0';

signal my_s_toSend : MyString_40d;
signal bitOfRec : std_logic_vector(7 downto 0) := "00000000";

signal getStart  : std_logic := '0';

signal myrd : std_logic := '0';
begin
  rd <= myrd;
  bitOfRecTest <= bitOfRec;
  dataTshower <= dataT;
  dataRshower <= dataR;
  toSeeRdo <= rdo;
  
  u : serial port  map(
  		Reset	=>	reset,
		dataT => dataT,		--  要输出去的!!
		dataR => dataR,		--  要输读进来的的!!
	

	clk  => clk ,				--- 11.0592M
	
	RxD =>RXD,				--  receive
	RXDO =>RXDO,
	TxD =>TXD,				--  tra
	TXDO	=>TXDO,
	
	
	wr	=> wro,	-- enable
	rdo => rdo
  );
  
	test <= mytest;
	process(wrobuffer)
	begin
		if wrobuffer'event and wrobuffer = '1' then
			wro <= not wro;
		end if;
	end process;
	
	process (rdo, reset)
	begin
		if reset = '0' then
			s_toRec <= ( others => CHAR_NULL );
			cnt_r <= 0;
			bitOfRec <= x"00";
		elsif falling_edge(rdo) then
			if getStart = '0' then
				myrd <= '0';
				getStart <= '1';
			else
				if cnt_r < 39 then
					cnt_r <= cnt_r + 1;
					bitOfRec <= bitOfRec + 1;
					myrd <= '1';
					s_toRec(cnt_r) <= dataR;
				else 
					cnt_r <= 0;
					myrd <= '0';
					bitOfRec <= x"00";
				end if;
			end if;
		end if;
	end process;
			
	
	my_s_toSend(0) <= x"55";
	my_s_toSend(1) <= x"77";
	my_s_toSend(2) <= x"EE";
	my_s_toSend(3) <= x"00";
	
	process (clock, reset)
	begin
		if reset = '0' or wr = '1' then
			state <= s_s0;
			counterInterval <= 0;
			cnt_s <= 0;

		elsif clock'event and clock = '1' then
			--mytest <= mytest xor "1111";
			case state is 
				when s_init =>
					state <= s_idle;
				when s_idle =>
					state <= s_idle;
				when s_sb0=>
					if wr = '1' then
						state <= s_sb0;
					else 
						state <= s_s0;
					end if;
					counterInterval <= 0;
				when s_s0 =>
					if counterInterval = inteval then
						dataT <= s_toSend(cnt_s2);
						state <= s_s1;
					elsif counterInterval = 4 then
						wrobuffer <= '1';
						--test <= "1001";
						counterInterval <= counterInterval+1;
						state <= s_s0;
					else 
						counterInterval <= counterInterval+1;
						state <= s_s0;
					end if;
				when s_s1 =>
					wrobuffer <= '0';
					--test <= "1010";
					if  cnt_s +1 <= 40*2-1  then
--						if flag = '0' then
							cnt_s <= cnt_s + 1;
--						else cnt_s <= cnt_s;
--						end if;
						flag <= not flag;
						state <= s_s2;
					else
						-- wro <= '1';
						state <= s_idle;
					end if;
					
					--
											
					--
				when s_s2 =>
					state <= s_s0;
					counterInterval <= 0;
			end case;
		end if;
	end process;
		
		cnt_s2 <= (cnt_s+1) / 2;
		
		process(clk, reset) begin
		if reset = '0' then
			counter <= 0;
			clock <= '1';
		elsif clk'event and clk = '1' then
			if counter = COUNTER_MAX then  ---11.0592M
				counter <= 0;
				CLOCK <= not CLOCK;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;

	process (state,wr)
	begin

		case state is
			when s_idle=>
				-- mytest <= "0000";
			when s_sb0=>
				-- mytest <= "0001";
			when s_s0=>
				mytest <= "0010";
			when s_s1=>
				mytest <= "0011";
			when s_s2=>
				mytest <= "0100";
--			when s_r0=>
--				mytest <= "1000";
--			when s_r1=>
--				mytest <= "1001";
--			when s_r2=>
--				mytest <= "1010";
			when s_init=>
				mytest <= "1111";
		end case;
	end process;
	

	end architecture;
	


	
--------------------------------------serial-	
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity serial is port (
---------------------------------------
	
	Reset	:	in std_logic;
	dataT    :   in std_logic_vector(7 downto 0);		--  要输出去的!!
	dataR	  :	  out std_logic_vector(7 downto 0);		--  要输读进来的的!!
	

	clk :  in std_logic;				--- 11.0592M
	
	RxD :  in std_logic;				--  receive
	RXDO : BUFFER STD_LOGIC;
	TxD :  BUFFER std_logic;				--  tra
	TXDO	:	BUFFER STD_LOGIC;
	
	
	wr	:	in std_logic;	-- enable
	rdo : out std_logic
);
end entity;

architecture Behavior of serial is
type STATE_TYPE   is (s_init0,s_init1,s_init2,s_init3,s_start,s_d0,s_d1,s_d2,s_d3,s_d4,s_d5,s_d6,s_d7,s_end,s_end1,s_idle);
signal state_s      :   STATE_TYPE := s_init0;---发送状态机
signal state_r      :   STATE_TYPE := s_init0;---接受状态机
signal Clock        : std_logic := '1';--
signal ClockRXD     : std_logic := '1';--
-------------------------------- 接收
signal RxDBuffer    : std_logic_vector(7 downto 0) := X"00";
signal RxDBufferIn  : std_logic_vector(7 downto 0) := X"00";
-------------------------------- 发送
signal TxRDY      	: std_logic := '1';
signal TxRDYBit     : std_logic := '1';

signal RxRDY      	: std_logic := '0';
signal RxRDYBit     : std_logic := '0';

signal TxDBuffer  : std_logic_vector(7 downto 0) := X"00";
signal TxDBufferOut  : std_logic_vector(7 downto 0) := X"00";

signal RxDStart   : std_logic := '0';
signal RxDEnd     : std_logic := '1';
signal RxDIdle    : std_logic := '1';
signal RxD_0    : std_logic := '1';
signal RxDBefore    : std_logic := '1';
signal serialState : std_logic_vector(7 downto 0) := X"00";---状态寄存器

--constant COUNTER_MAX : integer := 47;
constant COUNTER_MAX : integer := 47;
---
---
---
--signal counter  : integer range 0 to 575;---分频器  9600
signal counter  : integer range 0 to COUNTER_MAX;---分频器 115200
signal counterRXD  : integer range 0 to COUNTER_MAX;---分频器 115200
--signal counter  : integer range 0 to 143;---分频器   38400

--signal dataT    :   std_logic_vector(7 downto 0) := "11110001";

SIGNAL TXDXO : std_logic := '1';
SIGNAL RXDXO : std_logic := '0';
begin
-------------------------------------------------------------------------------------

	
	
	PROcess(RXD)
	begin 
		if rxd'event and rxd = '0' then 
			rxdo <= not rxdo;
		end if;
	end process;
	
	PROcess(txd)
	BEGin
		IF TXD'EVEnt AND TXD = '0' THEn
			TXDO <= NOT TXDO;
		END IF;
	END PROcess;
	
	TxRDYBit <= '1' when state_s = s_idle and TxRDY = '1' else '0';
    RxRDYBit <= '1' when state_r = s_idle and RxRDY = '1' else '0';
	
	process(reset,wr,RxDBuffer,TxDBuffer,state_r,state_s,TxRDY,TxRDYBit)
	begin
		
		if reset = '0' then
			TxRDY <= '1'; --允许CPU写入数据
		elsif state_s = s_end then
			TxRDY <= '1';---发送完毕，允许再写入数据
	    elsif wr'event and wr = '0'  and state_s = s_idle then
			TxRDY <= '0';
		end if;
		
--		if reset = '0'  then
--			RxRDY <= '0';  --CPU不能读取数据??
--	    elsif state_r = s_end then
--			RxRDY <= '1'; 
--		elsif rd'event and rd = '0' and wr = '1' then
--			RxRDY <= '0'; --读走数据
--		end if;		
		
--		
--		if rd'event and rd = '0' then 
--				dataR <= RxDBuffer;
--		end if;
		
		if wr'event and wr = '0' then
	    		TxDBuffer <= dataT; 
		end if;
		
	end process; 
	--data在里面
	
-------------------------------------------------------------------	
---发送器	
	
	process(reset,Clock,TxRDY) 
	begin
			if reset = '0' then
			 	state_s <= s_init0;
				TxD <= '1';	
			elsif Clock'event and Clock = '1' then
				case state_s is
					when s_init0 => 
						state_s <= s_idle;
						TxD <= '1';
					when s_idle =>
						 if TxRDY = '0' then ---如果写入了数据，则开始发送
						 	 state_s <= s_start;
						 else
						 	 state_s <= s_idle;
						 end if;
						 TxD <= '1';
					when s_start => 
						state_s <= s_d0;
						TxD <= '0';
					when s_d0 => 
						state_s <= s_d1;
						TxD <= TxDBuffer(0);
					when s_d1 => 
						state_s <= s_d2;
						 TxD <= TxDBuffer(1);
					when s_d2 => 
						 state_s <= s_d3;
						 TxD <= TxDBuffer(2);
					when s_d3 => 
						state_s <= s_d4;
						 TxD <= TxDBuffer(3);
					when s_d4 => 
						state_s <= s_d5;
						TxD <= TxDBuffer(4);	
					when s_d5 => 
						state_s <= s_d6;
						TxD <= TxDBuffer(5);
					when s_d6 =>
						 state_s <= s_d7;
						TxD <= TxDBuffer(6);
					when s_d7 => 
						TxD <= TxDBuffer(7);
						state_s <= s_end;
					when s_end => 
						 TxD <= '1';
						state_s <= s_idle;
					when others => 
						TxD <= '1';
						state_s <= s_idle;
				end case;				
			end if;
	 
    end process;
	
	 
-----------------------------------------------------------
	process(reset,clockRXD,RxD,RxRDY,state_r) 
	begin		 
			if reset = '0' then
			 	state_r <= s_init0;
			elsif state_r = s_idle and rxd = '0' then
				state_r <= s_start;
			elsif rising_edge(clockRXD) then
				case state_r is
					when s_init0 => 
						state_r <= s_idle;
					when s_idle => 
						if rxd = '0' then
							state_r <= s_start;
						else
							state_r <= s_idle;
						end if;
					when s_start =>
						 state_r <= s_d0;
					when s_d0   =>
						 state_r <= s_d1;
					when s_d1   =>
						 state_r <= s_d2;
					when s_d2   =>
						 state_r <= s_d3;
					when s_d3   =>
						 state_r <= s_d4;
					when s_d4   =>
						 state_r <= s_d5;
					when s_d5   =>
						 state_r <= s_d6;
					when s_d6   =>
						 state_r <= s_d7;
					when s_d7   =>
						 state_r <= s_end;	
					when s_end => 
						state_r <= s_idle;
					when others => 
						state_r <= s_idle;
				end case;				
			end if;		
		
    end process;
	
	process(reset,clockRXD,RxD,RxRDY) 
	begin		  	
			if reset = '0' then 
				rdo <= '1';
			elsif falling_edge(clockRXD) then
				case state_r is
				when s_d0 => 
					rdo <= '1';
					RxDBufferIn(0) <= RxD;
				when s_d1 => RxDBufferIn(1) <= RxD;
				when s_d2 => RxDBufferIn(2) <= RxD;
				when s_d3 => RxDBufferIn(3) <= RxD;
				when s_d4 => RxDBufferIn(4) <= RxD;
				when s_d5 => RxDBufferIn(5) <= RxD;
				when s_d6 => RxDBufferIn(6) <= RxD;
				when s_d7 => 
					dataR(7) <= RxD;
					dataR(6) <= RxDBufferIn(6);
					dataR(5) <= RxDBufferIn(5);
					dataR(4) <= RxDBufferIn(4);
					dataR(3) <= RxDBufferIn(3);
					dataR(2) <= RxDBufferIn(2);
					dataR(1) <= RxDBufferIn(1);
					dataR(0) <= RxDBufferIn(0);
				when s_end => RxDEnd <= RxD; --停止位
					RxDBuffer	<= RxDBufferIn;
					rdo <= '0';			
				when s_idle => 
					RxDIdle <= RxD;
				when others => RxDIdle <= RxD;
				end case;				
			end if;		
		
    end process;
	
	
	
	
	
------------------------------------------------------
--分频器
	process(clk, reset) begin
		if reset = '0' then
			counter <= 0;
			CLOCK <= '1';
		elsif clk'event and clk = '1' then
			if counter = COUNTER_MAX then  ---11.0592M
				counter <= 0;
				CLOCK <= not CLOCK;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;
-------------------------------------------------------------------------------------		
--分频器
	process(clk, reset,state_r,RXD) 
	begin
		if reset = '0' or (state_r = s_idle and RXD = '1' ) then
			counterRXD <= 0;
			ClockRXD <= '1';
		elsif clk'event and clk = '1' then
			if counterRXD = COUNTER_MAX then  ---11.0592M
				counterRXD <= 0;
				ClockRXD <= not ClockRXD;
			else
				counterRXD <= counterRXD + 1;
			end if;
		end if;
	end process;
-------------------------------------------------------------------------------------		
end architecture;
