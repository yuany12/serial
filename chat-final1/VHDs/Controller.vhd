-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.GlobalDefines.all;
-------------------------------------------------------------------------------------
entity Controller is
	port (
		
		reset		:	in std_logic;  -- reset
	
		clk			:	in std_logic; -- 串口时钟
		clk100		:	in std_logic; -- 100M
		
		PS2Data		:  in std_logic;	
		PS2clk		:	in std_logic;	
		
		RXD_FPGAE	:  in std_logic;	-- 199
		TXD_FPGAE	:  buffer std_logic;	-- 197

		-------
		
		
		--keyClk		:	in std_logic;
		--keyIn		:	in MyCharacter;
		
		
--		errorShow	:	out	std_logic;
--		
		d_out		:	out std_logic;
		output		: 	buffer StandardWindow;
--		
		toSeeBitOfRecTest : out std_logic_vector(7 downto 0);
		
		----
		cap_flag : out std_logic
		
	);
end entity;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
architecture structural of Controller is


	signal	errorShow	:		std_logic;
		
--	signal	d_out		:	 std_logic;
--	signal	output		: 	 StandardWindow;
	signal	seg0,seg1,seg2,seg3,seg4,seg5,seg6,seg07 :  std_logic_vector(6 downto 0);
		
		
	signal	test		: 	 std_logic_vector(3 downto 0);
		
		
	component SerialToString
    port (
		reset	:	in std_logic;
		clk		:	in std_logic;
		
   	
		s_toRec	: out MyString_40d;
		s_toSend : in MyString_40d;

		wr		:	in std_logic;	-- controller to serialtostring to send! es
		rd	:	out std_logic;  -- 下边沿表示要变了！！  -- serialtostring to controller to send

		dataTshower	:	buffer std_logic_vector(7 downto 0);	
		dataRshower	:	 buffer std_logic_vector(7 downto 0);

		
--		test		: 	buffer std_logic_vector(3 downto 0);
		
		
		----
		RxD :  in std_logic;				--  receive ！
		TxD :  BUFFER std_logic;				--  tra ！
		
		toSeeRdo : out std_logic;
		bitOfRecTest : out std_logic_vector(7 downto 0)
	);
	end component;

	
	
	component Keyboard is
	port (
	keyClk        : out std_logic;
	datain, clkin : in std_logic ; -- PS2 clk and data
	fclk, rst     : in std_logic ;  -- filter clock
--	fok : out std_logic ;  -- data output enable signal
	scancode      : out std_logic_vector(7 downto 0) -- scan code signal output
	) ;
	end component;
	
	component seg7 is
	port(
	code    : in std_logic_vector(3 downto 0);
	seg_out : out std_logic_vector(6 downto 0)
	);
	end component;

	type STATE_TYPE is (s_init, s_idle, s_rb0, s_r0, s_r1, s_r2, s_sb0, s_s0, s_s1, s_s2);
	
	constant nulString : MyString_40d := (others => CHAR_NULL);
		
	signal state : STATE_TYPE := s_init; 
	signal outputUp 	: MyString_40d := nulString;
	signal outputDown	: MyString_40d := nulString;
	signal outputS	: MyString_40d := nulString;
	
	signal outputBuffer	: StandardWindow; -- ��ô��ʼ��??
	
	signal str : MyString_40d := (others => CHAR_NULL);
	signal len : LengthInt := 0;
	signal nextlen: LengthInt := 0;

	
	signal sendCnt : integer := 0;
	signal counterClock: integer := 0;

	constant COUNTER_MAX : integer := 47;
	signal	clock	:	std_logic := '0';
	signal	counterclk:	integer range 0 to COUNTER_MAX := 0;
	
	signal er : std_logic := '0';
	signal ew : std_logic := '0';
	-- signal eew : std_logic := '0';
	
	signal ds : std_logic := '0';
	
	signal t1	: std_logic := '0';
	signal t2	: std_logic := '0';
	
	signal data_in, clk_in : std_logic;
	signal keyClkck     :  std_logic;
	signal scancode   :  std_logic_vector(7 downto 0);
	signal char_code : std_logic_vector(7 downto 0);			--
	signal key : MyCharacter;
	
	signal ek : std_logic;
	signal input_clk : std_logic := '1';
	
--	signal rec,send : MyString_40d;
	
	signal sts_wr,sts_rd : std_logic;
	
	signal dataR, dataT : std_logic_vector(7 downto 0);
	
	signal d_send		:	 std_logic;
	signal outSend	:	MyString_40d;
		
	signal d_rec		:	std_logic;
	signal inputRec	:	MyString_40d;
	signal keyclk 		:  std_logic;
	signal keyIn 		:  MyCharacter :=char_code;
	
	constant s2_counter_max : integer := 5;
	signal s2_counter : integer range 0 to s2_counter_max;
	---------ck--------
type key_state is (start, f_state);
signal curr_key_state : key_state := start;
type cap_state is (cap_off, cap_on);
signal curr_cap_state : cap_state := cap_off;
type shift_state is (shift_off, shift_on);
signal curr_shift_state : shift_state := shift_off;

type r_shift_state is (r_shift_off, r_shift_on);
signal curr_r_shift_state : r_shift_state := r_shift_off;
--type lan_state is (English, Chinese);
--signal curr_lan_state : lan_state := English;
--
--type ch_input_state is (start, s_a, s_b, s_c, s_d, s_e, s_f, s_g, s_h, s_i, s_j, s_k
--								, s_l, s_m, s_n, s_o, s_p, s_q, s_r, s_s, s_t, s_u, s_v, s_w
--								, s_x, s_y, s_z);
--signal curr_ch_in_state : ch_input_state := start;

constant inclk_wait : integer := 100000;		--loop times


signal sendtest : MyString_40d;
signal toSeeRdotest : std_logic;
--signal toSeeBitOfRecTest : std_logic_vector(7 downto 0);
begin
	
	keyIn <= char_code;
	keyclk <= not input_clk;					-------------ck
	
	process (d_send)
	begin
		if d_send'event and d_send = '0' then
			seg0(0) <= not seg0(0);
		end if;
	end process;
	
	process (d_rec)
	begin
		if d_rec'event and d_rec = '0' then
			seg0(1) <= not seg0(1);
		end if;
	end process;
	
	process(toSeeRdotest)
	begin
		if toSeeRdotest'event and toSeeRdotest = '0' then
			seg0(6) <= not seg0(6);
		end if;
	end process;
	
	sendtest <= outputS;
--u22: seg7 port map(scancode(7 downto 4),seg0);
u21: seg7 port map(test,seg1);
u_seg7_3 : seg7 port map(output(1).txt(0)(3 downto 0), seg2);
u_seg7_4 : seg7 port map(output(1).txt(1)(3 downto 0), seg3);
u_seg7_5 : seg7 port map(output(1).txt(2)(3 downto 0), seg4);
u_seg7_6 : seg7 port map(output(1).txt(3)(3 downto 0), seg5);
u_seg7_7 : seg7 port map(output(1).txt(4)(3 downto 0), seg6);
u_seg7_8 : seg7 port map(output(1).txt(4)(3 downto 0), seg07);
	
	u_serialToString : SerialToString port map(

		reset	=> reset,
		clk	=> clk,
		
   	
		s_toRec	=> inputRec,
		s_toSend => outSend,

		wr		=> d_send,	-- controller to serialtostring to send! es
		rd  	=> d_rec,  -- 下边沿表示要变了！！  -- serialtostring to controller to send
		
		----
		dataTshower => dataT,
		dataRshower => dataR,
		RxD => RXD_FPGAE,				--  receive ！
		TxD => TXD_FPGAE,				--  tra ！
		toSeeRdo => toSeeRdotest,
		bitOfRecTest => toSeeBitOfRecTest
	);
	
	
	u2: Keyboard port map(
						datain => PS2Data,
						clkin => PS2clk,
						fclk => clk100, --!! 100M 
						rst=> not reset,
						scancode => scancode,
						keyClk => keyClkck
					);

	seg0(3) <= er or ew;
	d_out <= er or ew;
	outSend <= outputS;
	d_send <= ds;
	-- test1 <= t1;
	-- test2 <= t2;
	
	outputBuffer(0).isMine <= '1';

	process (keyClk,reset,ew)
	begin
		if reset = '0' then
			  outputUp 	<= nulString;
		      outputDown  <= nulString;
		      --outputS	<= nulString;

				
			  len <= 0;
			-- do sth to restart
		elsif keyClk'event and keyClk = '0' then
				-- eew <= '1';

				if keyIn = CHAR_ENTER then
					-- show up;
					outputUp <= outputDown;
					-- show down clear
					outputDown <= nulString;
					-- send to the other;
					--outputS <= outputDown;
					len <= 0;
					--ees <= '1';
				elsif keyIn = CHAR_BACKSPACE then
					-- backspace
					if len >= 1 then
						outputDown(len-1) <= CHAR_NULL;
						len <= len-1;
					end if;
					outputUp <= nulString;
					--outputS <= nulString;
				else
					if len < 40 then
						-- show down
						outputDown(len) <= keyIn;
						
						len <= len + 1;
					end if;
					outputUp <= nulString;
					--outputS <= nulString;
				end if;
		end if;
end process;
	
	-------------------------------------------------------------------------------------		
--��Ƶ��
	process(clk, reset) 
	begin
		if reset = '0' then
			counterClock <= 0;
			Clock <= '1';
		elsif clk'event and clk = '1' then
			if counterClock = COUNTER_MAX then 
				counterClock <= 0;
				Clock <= not Clock;
			else
				counterClock <=counterClock + 1;
			end if;
		end if;
	end process;
	
	process (Clock, reset)
	begin 
		if reset = '0' then 
			state <= s_init;
							output(0).txt <= nulString;
							output(1).txt <= nulString;
							output(2).txt <= nulString;
							output(3).txt <= nulString;
							output(4).txt <= nulString;
							output(5).txt <= nulString;
							output(6).txt <= nulString;
							output(7).txt <= nulString;
							output(8).txt <= nulString;
							output(9).txt <= nulString;
							output(10).txt <= nulString;
							
							outputBuffer(0).txt <= nulString;
							outputBuffer(1).txt <= nulString;
							outputBuffer(2).txt <= nulString;
							outputBuffer(3).txt <= nulString;
							outputBuffer(4).txt <= nulString;
							outputBuffer(5).txt <= nulString;
							outputBuffer(6).txt <= nulString;
							outputBuffer(7).txt <= nulString;
							outputBuffer(8).txt <= nulString;
							outputBuffer(9).txt <= nulString;
							outputBuffer(10).txt <= nulString;
		elsif Clock'event and Clock = '1' then
			case state is
				when s_init =>
					state <= s_idle;
				when s_idle =>
					if keyClk = '1' then
						ew <= '1';
						state <= s_sb0;
					elsif d_rec = '1' then   --?? 0?
						er <= '1';
						state <= s_rb0;
					else 
						state <= s_idle;
					end if;
				when s_rb0  =>
					if d_rec = '0' then 
						state <= s_r0;
					else state <= s_rb0;
					end if;
				when s_r0	=>
					if (not equal(inputRec(0),CHAR_NULL)) then
						outputBuffer(10) <= output(9);
						outputBuffer(9) <= output(8);
						outputBuffer(8) <= output(7);
						outputBuffer(7) <= output(6);
						outputBuffer(6) <= output(5);
						outputBuffer(5) <= output(4);
						outputBuffer(4) <= output(3);
						outputBuffer(3) <= output(2);
						outputBuffer(2) <= output(1);
						outputBuffer(1).txt <= inputRec;
						outputBuffer(1).isMine <= '0';
					end if;
					outputBuffer(0).txt <= outputDown;
					
					state <= s_r1;

				when s_r1	=>
					output <= outputBuffer;
					state <= s_r2;
				when s_r2	=>
					er <= '0';
					state <= s_idle;
				when s_sb0	=>
					-- t1 <= '1';
					-- ds <= '0';
					if keyClk = '0' then
						state <= s_s0;
					else
						state <= s_sb0;
					end if;
				when s_s0	=>
						if (not equal (outputUp(0) , CHAR_NULL)) then
							outputBuffer(10) <= output(9);
							outputBuffer(9) <= output(8);
							outputBuffer(8) <= output(7);
							outputBuffer(7) <= output(6);
							outputBuffer(6) <= output(5);
							outputBuffer(5) <= output(4);
							outputBuffer(4) <= output(3);
							outputBuffer(3) <= output(2);
							outputBuffer(2) <= output(1);
							outputBuffer(1).txt <= outputUp;
							outputBuffer(1).isMine <= '1';
							outputS <= outputUp;
							ds <= '1';
						end if;
						outputBuffer(0).txt <= outputDown;
						
						
						state <= s_s1;
						-- t2 <= '1';
				when s_s1	=>
					output <= outputBuffer;
					state <= s_s2;
					s2_counter <= 0;
				when s_s2	=>
					ew <= '0';
					-- ds <= '0';
					if s2_counter = s2_counter_max then
						state <= s_idle;
						ds <= '0';
					else 
						state <= s_s2;
						s2_counter <= s2_counter + 1;
					end if;
			end case;
		end if;
	end process;
	
	process (state)
	begin
		case state is
			when s_idle=>
				test <= "0000";
			when s_sb0=>
				test <= "0001";
			when s_s0=>
				test <= "0010";
			when s_s1=>
				test <= "0011";
			when s_s2=>
				test <= "0100";
			when s_r0=>
				test <= "1000";
			when s_r1=>
				test <= "1001";
			when s_r2=>
				test <= "1010";
			when s_init=>
				test <= "1111";
			when s_rb0=>
				test <= "1011";
		end case;
	end process;
	
	process(reset, scancode, keyClkck)
	begin
		if(reset = '0') then
			curr_cap_state <= cap_off;
			--curr_ch_in_state <= start;
			curr_key_state <= start;
			--curr_lan_state <= English;
			curr_shift_state <= shift_off;
		elsif(falling_edge(keyClkck)) then
		case scancode is
			when "01011010" =>
				--ENTER
				char_code <= CHAR_ENTER;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01100110" =>
				--BACKSPACE
				char_code <= CHAR_BACKSPACE;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01011000" =>			
				--58 : CAPSLOCK	
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					if(curr_cap_state = cap_on) then 
						curr_cap_state <= cap_off;
					else
						curr_cap_state <= cap_on;
					end if;
				end if;
			when "00010010" =>
				--12: SHIFT
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					curr_shift_state <= shift_off;
				else
					curr_shift_state <= shift_on;
				end if;
			when "01011001" =>
				--59: r_SHIFT
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					curr_r_shift_state <= r_shift_off;
				else
					curr_r_shift_state <= r_shift_on;
				end if;
			when "00010100" =>
				--14: CTRL
				char_code <= CHINESE_HEAD;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			
			when "01000101" =>			--45:0
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_0;
				else
					char_code <= "01" & char_0(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00010110" =>			--16:1
				if(curr_shift_state = shift_on) then
					char_code <= char_sur;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_1;
					else
						char_code <= "01" & char_1(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00011110" =>			--1e:2
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_2;
				else
					char_code <= "01" & char_2(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00100110" =>			--26:3
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_3;
				else
					char_code <= "01" & char_3(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00100101" =>			--25:4
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_4;
				else
					char_code <= "01" & char_4(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00101110" =>			--2e:5
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_5;
				else
					char_code <= "01" & char_5(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00110110" =>			--36:6
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_6;
				else
					char_code <= "01" & char_6(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00111101" =>			--3d:7
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_7;
				else
					char_code <= "01" & char_7(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00111110" =>			--3e:8
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_8;
				else
					char_code <= "01" & char_8(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01000110" =>			--46:9
				if(curr_r_shift_state = r_shift_off) then
					char_code <= char_9;
				else
					char_code <= "01" & char_9(5 downto 0);
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
				
			when "01000001" =>			--41:com
				char_code <= char_com;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01001001" =>			--49:dot
				char_code <= char_dot;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01001010" =>			--4a:que
				char_code <= char_que;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			
			when "00011100" =>
				-----------------------------------a
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_a_caps;
					else
						char_code <= "01" & char_a_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_a;
					else
						char_code <= "01" & char_a(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00110010" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_b_caps;
					else
						char_code <= "01" & char_b_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_b;
					else
						char_code <= "01" & char_b(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00100001" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_c_caps;
					else
						char_code <= "01" & char_c_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_c;
					else
						char_code <= "01" & char_c(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00100011" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_d_caps;
					else
						char_code <= "01" & char_d_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_d;
					else
						char_code <= "01" & char_d(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00100100" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_e_caps;
					else
						char_code <= "01" & char_e_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_e;
					else
						char_code <= "01" & char_e(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00101011" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_f_caps;
					else
						char_code <= "01" & char_f_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_f;
					else
						char_code <= "01" & char_f(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00110100" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_g_caps;
					else
						char_code <= "01" & char_g_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_g;
					else
						char_code <= "01" & char_g(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00110011" => 
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_h_caps;
					else
						char_code <= "01" & char_h_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_h;
					else
						char_code <= "01" & char_h(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01000011" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_i_caps;
					else
						char_code <= "01" & char_i_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_i;
					else
						char_code <= "01" & char_i(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00111011" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_j_caps;
					else
						char_code <= "01" & char_j_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_j;
					else
						char_code <= "01" & char_j(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01000010" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_k_caps;
					else
						char_code <= "01" & char_k_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_k;
					else
						char_code <= "01" & char_k(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01001011" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_l_caps;
					else
						char_code <= "01" & char_l_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_l;
					else
						char_code <= "01" & char_l(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00111010" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_m_caps;
					else
						char_code <= "01" & char_m_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_m;
					else
						char_code <= "01" & char_m(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00110001" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_n_caps;
					else
						char_code <= "01" & char_n_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_n;
					else
						char_code <= "01" & char_n(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01000100" => 
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_o_caps;
					else
						char_code <= "01" & char_o_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_o;
					else
						char_code <= "01" & char_o(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "01001101" =>
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_p_caps;
					else
						char_code <= "01" & char_p_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_p;
					else
						char_code <= "01" & char_p(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00010101" =>	--15
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_q_caps;
					else
						char_code <= "01" & char_q_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_q;
					else
						char_code <= "01" & char_q(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00101101" =>	--2d
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_r_caps;
					else
						char_code <= "01" & char_r_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_r;
					else
						char_code <= "01" & char_r(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00011011" =>	--1b
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_s_caps;
					else
						char_code <= "01" & char_s_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_s;
					else
						char_code <= "01" & char_s(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00101100" =>	--2c
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_t_caps;
					else
						char_code <= "01" & char_t_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_t;
					else
						char_code <= "01" & char_t(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00111100" =>	--3c
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_u_caps;
					else
						char_code <= "01" & char_u_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_u;
					else
						char_code <= "01" & char_u(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00101010" => 	--2a
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_v_caps;
					else
						char_code <= "01" & char_v_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_v;
					else
						char_code <= "01" & char_v(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00011101" =>	--1d
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_w_caps;
					else
						char_code <= "01" & char_w_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_w;
					else
						char_code <= "01" & char_w(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00100010" =>	--22
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_x_caps;
					else
						char_code <= "01" & char_x_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_x;
					else
						char_code <= "01" & char_x(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00110101" =>	--35
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_y_caps;
					else
						char_code <= "01" & char_y_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_y;
					else
						char_code <= "01" & char_y(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "00011010" =>	--1a
				if(curr_cap_state = cap_on) then
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_z_caps;
					else
						char_code <= "01" & char_z_caps(5 downto 0);
					end if;
				else
					if(curr_r_shift_state = r_shift_off) then
						char_code <= char_z;
					else
						char_code <= "01" & char_z(5 downto 0);
					end if;
				end if;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				end if;
			when "11110000" =>
				--F0
				--input_clk <= '1';
				curr_key_state <= f_state;
			
			when "00101001" =>				--29
				char_code <= CHAR_SPACE;
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					input_clk <= '1';
				else
					input_clk <= '0';
				--rgb <= "000";			--space
				
				end if;
				--rgb<=rgb_0;
				--pic_choose <= "001";
			when others=>
				if(curr_key_state = f_state) then
					curr_key_state <= start;
					--input_clk <= '1';	-------------------------------------------------------------modify(2014-6-9 00:54:13)
				end if;
		end case;
		end if;
	end process;
	
	process (curr_cap_state)
	begin
		if(curr_cap_state = cap_on) then
			cap_flag <= '1';
		else
			cap_flag <= '0';
		end if;
	end process;
	
end;