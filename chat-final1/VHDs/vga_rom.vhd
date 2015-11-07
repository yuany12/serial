library ieee;
use ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
-------------------------------------
use work.GlobalDefines.all;

entity vga_rom is
port(
	data_in, clk_in : std_logic;
	clk_0,reset: in std_logic;
	hs,vs: out STD_LOGIC;
	seg0, seg1 : out std_logic_vector(6 downto 0); 
	r,g,b: out STD_LOGIC_vector(2 downto 0)
);
end vga_rom;

architecture vga_rom of vga_rom is
-------------------------------------------------------------------
signal scancode   :  std_logic_vector(7 downto 0);
signal rst        :  std_logic;
signal input_clk  :  std_logic;									--
signal pic_choose :  std_logic_vector(2 downto 0);    -- 0: 16*32  1: 128*128
signal bg_line    :  std_logic_vector(4 downto 0);
--type state is (k_start, k_wait, k_shift);
--signal curr_state, next_state : state := k_start;
-------------------------------------------------------------------
component vga640480 is
	 port(
			address		:		  out	STD_LOGIC_VECTOR(13 DOWNTO 0);
			reset       :         in  STD_LOGIC;
			clk25       :		  out std_logic; 
			clk_0       :         in  STD_LOGIC; --100M????
			hs,vs       :         out STD_LOGIC; --?????????
			r, g, b		:		  out std_logic_vector(2 downto 0);
			rgb         :         in  std_logic_vector(2 downto 0);
			input_clk   :         in  std_logic;
			--pic         :         in  std_logic_vector(2 downto 0);
			vga_output  :         in  StandardWindow;
			disp_code   :         out std_logic_vector(7 downto 0)
			--rgb_bg      :         in  std_logic_vector(8 downto 0);
			--bg_line     :         out std_logic_vector(4 downto 0)
	  );
end component;
-------------------------------------------------------------------
--component digital_rom IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(8 downto 0)
--	);
--END component;

--component bg_0 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_1 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_2 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_3 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_4 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_5 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_6 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_7 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_8 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_9 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_10 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_11 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_12 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_13 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_14 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_15 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_16 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_17 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_18 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
--component bg_19 IS
--	PORT
--	(
--		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
--		clock		: IN STD_LOGIC ;
--		q      		: out STD_LOGIC_vector(2 downto 0)
--	);
--END component;
-------------------------------------------------------------------
component alpha_a IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

component alpha_b IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

component alpha_c IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

component alpha_d IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

component alpha_e IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

component alpha_f IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

component alpha_g IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(2 downto 0)
	);
END component;

-------------------------------------------------------------------
component Keyboard is
port (
	datain, clkin : in std_logic ; -- PS2 clk and data
	fclk, rst     : in std_logic ;  -- filter clock
--	fok : out std_logic ;  -- data output enable signal
	scancode      : out std_logic_vector(7 downto 0) -- scan code signal output
	) ;
end component ;
-------------------------------------------------------------------
component seg7 is
port(
code    : in std_logic_vector(3 downto 0);
seg_out : out std_logic_vector(6 downto 0)
);
end component;
-------------------------------------------------------------------
component bug is
	port
	(
		input		   : in std_logic;
		output      : out std_logic_vector(2 downto 0)
	);
end component;
-------------------------------------------------------------------
signal address_tmp: std_logic_vector(13 downto 0);
signal clk25: std_logic;
signal rgb, rgb_a, rgb_b, rgb_0: std_logic_vector(2 downto 0);
signal rgb_c, rgb_d, rgb_e, rgb_f, rgb_g : std_logic_vector(2 downto 0);
--signal rgb_bg : std_logic_vector(8 downto 0);
--signal rgb_1, rgb_2, rgb_3, rgb_4, rgb_5, rgb_6, rgb_7, rgb_8, rgb_9, rgb_10, rgb_11, rgb_12, rgb_13, rgb_14, rgb_15, rgb_16, rgb_17, rgb_18, rgb_19 : std_logic_vector(2 downto 0);
signal r1 , g1, b1 : std_logic;
-------------------------------------------------------------------

signal char_code : std_logic_vector(7 downto 0);			--
signal disp_code : std_logic_vector(7 downto 0);
signal vga_update_clk : std_logic;
signal vga_output : StandardWindow;
-------------------------------------------------------------------yy
component Controller is
	port (
		reset		:	in std_logic;
	
		clk			:	in std_logic;		--ck??
		
		keyClk		:	in std_logic;
		keyIn		:	in MyCharacter;
		
		--errorShow	:	out	std_logic;		ck??
		
		d_out		:	out std_logic;
		output		: 	buffer StandardWindow
	);
end component;

begin
---------------------------------------------------------------
--u_y0: Controller port map(
--	reset => reset,
--	clk   => clk_0,		--100M?
--	keyClk => input_clk,
--	keyIn  => char_code,
--	
--	d_out => vga_update_clk,
--	output => vga_output
--);
---------------------------------------------------------------bug: multiple clock (Controller.vhd(70) 'eew')

--practice:
	vga_output(0).txt(0) <= CHAR_a;
	vga_output(0).txt(1) <= CHAR_b;
	vga_output(0).txt(2) <= CHAR_b;
	vga_output(0).txt(3) <= CHAR_g;
	vga_output(0).txt(4) <= CHAR_f;
	vga_output(0).txt(5) <= CHAR_c;
	vga_output(0).txt(6) <= CHAR_NULL;
	vga_output(1).txt(0) <= CHAR_c;
	vga_output(1).txt(1) <= CHAR_d;
	vga_output(1).txt(2) <= CHAR_NULL;
	vga_output(2).txt(0) <= CHAR_e;
	vga_output(2).txt(1) <= CHAR_f;
	vga_output(2).txt(2) <= CHAR_NULL;
	vga_output(3).txt(0) <= CHAR_a;
	vga_output(3).txt(1) <= CHAR_b;
	vga_output(3).txt(2) <= CHAR_NULL;
	vga_output(4).txt(0) <= CHAR_g;
	vga_output(4).txt(1) <= CHAR_a;
	vga_output(4).txt(2) <= CHAR_NULL;

----------------------------------------------------------------
--r1 <= rgb(2);
--g1 <= rgb(1);
--b1 <= rgb(0);
	rst <= not reset;	--keyboard need

u1: vga640480 port map(
						address  =>  address_tmp, 
						reset    =>  reset, 
						clk25    =>  clk25, 
						clk_0    =>  clk_0, 
						hs       =>  hs, 
						vs       =>  vs,
						r=>r,   g=>g,   b=>b,
						rgb      =>  rgb,
						input_clk => input_clk,
						--pic      =>  pic_choose,
						vga_output => vga_output,
						disp_code => disp_code
						--rgb_bg   =>  rgb_bg,
						--bg_line  =>  bg_line
					);
u2: Keyboard port map(
						datain=>data_in,
						clkin=>clk_in,
						fclk=>clk_0,
						rst=>rst,
						scancode=>scancode
					);
					
u21: seg7 port map(scancode(3 downto 0),seg0);
u22: seg7 port map(scancode(7 downto 4),seg1);
--------------------------------------------------------------------
--alpha
u2_1: alpha_a port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a
					);

u2_2: alpha_b port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b
					);
u2_3: alpha_c port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c
					);

u2_4: alpha_d port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d
					);
u2_5: alpha_e port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_e
					);

u2_6: alpha_f port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f
					);
u2_7: alpha_g port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g
					);


--------------------------------------------------------------------	
--qw--background 128*128
--u2_0: digital_rom port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_bg
--					);
					
--u2_0_0: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_0
--					);
--u2_0_1: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_1
--					);
--u2_0_2: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_2
--					);
--u2_0_3: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_3
--					);
--u2_0_4: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_4
--					);
--u2_0_5: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_5
--					);
--u2_0_6: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_6
--					);
--u2_0_7: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_7
--					);
--u2_0_8: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_8
--					);
--u2_0_9: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_9
--					);
--u2_0_10: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_10
--					);
--u2_0_11: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_11
--					);
--u2_0_12: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_12
--					);
--u2_0_13: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_13
--					);
--u2_0_14: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_14
--					);
--u2_0_15: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_15
--					);
--u2_0_16: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_16
--					);
--u2_0_17: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_17
--					);
--u2_0_18: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_18
--					);
--u2_0_19: bg_0 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_19
--					);					

--state_m : process(reset, clk_0)
--	begin
--	if(reset = '0') then
--		curr_state <= k_start;
--	elsif(clk_0'event and clk_0 = '1') then
--		curr_state <= next_state;
--	end if;
--	end process;
--------------------------------------------------------------------
--keyboard controller
--	process(bg_line, rgb_0, rgb_1, rgb_2, rgb_3, rgb_4, rgb_5, rgb_6, rgb_7, rgb_8, rgb_9, rgb_10, rgb_11, rgb_12, rgb_13, rgb_14, rgb_15, rgb_16, rgb_17, rgb_18, rgb_19 )
--	begin
--		case bg_line is
--			when "00000"  =>  rgb_bg <= rgb_0;
--			when "00001"  =>  rgb_bg <= rgb_1;
--			when "00010"  =>  rgb_bg <= rgb_2;
--			when "00011"  =>  rgb_bg <= rgb_3;
--			when "00100"  =>  rgb_bg <= rgb_4;
--			when "00101"  =>  rgb_bg <= rgb_5;
--			when "00110"  =>  rgb_bg <= rgb_6;
--			when "00111"  =>  rgb_bg <= rgb_7;
--			when "01000"  =>  rgb_bg <= rgb_8;
--			when "01001"  =>  rgb_bg <= rgb_9;
--			when "01010"  =>  rgb_bg <= rgb_10;
--			when "01011"  =>  rgb_bg <= rgb_11;
--			when "01100"  =>  rgb_bg <= rgb_12;
--			when "01101"  =>  rgb_bg <= rgb_13;
--			when "01110"  =>  rgb_bg <= rgb_14;
--			when "01111"  =>  rgb_bg <= rgb_15;
--			when "10000"  =>  rgb_bg <= rgb_16;
--			when "10001"  =>  rgb_bg <= rgb_17;
--			when "10010"  =>  rgb_bg <= rgb_18;
--			when "10011"  =>  rgb_bg <= rgb_19;
--			when others   =>  
--		end case;
--	--rgb_bg <= rgb_0;
--	end process;
--	rgb_bg <= rgb_0;
	--------------------------------------------------------------------
	process(scancode)
	begin			
		case scancode is
			when "00011100" => 
				
				input_clk <= '1';
				--if(pic_choose <= "000") then 
					--rgb<=rgb_a;
				--else
					--rgb<=rgb_0;
				--end if;
				char_code <= "00000001";
			when "00110010" =>
				
				input_clk <= '1';
				--if(pic_choose <= "000") then 
					--rgb<=rgb_b;
				--else
					--rgb<=rgb_0;
				--end if;
				char_code <= "00000010";
			when "00100001" =>
				input_clk <= '1';
				--rgb <= rgb_c;
				char_code <= "00000011";
			when "00100011" =>
				input_clk <= '1';
				--rgb <= rgb_d;
				char_code <= "00000100";
			when "00100100" =>
				input_clk <= '1';
				--rgb <= rgb_e;
				char_code <= "00000101";
			when "00101011" =>
				input_clk <= '1';
				--rgb <= rgb_f;
				char_code <= "00000110";
			when "00110100" =>
				input_clk <= '1';
				--rgb <= rgb_g;
				char_code <= "00000111";
			when "11110000" =>
				input_clk <= '0';
			when others=>
				input_clk <= '1';
				--rgb <= "000";			--space
				char_code <= "10000000";
				--rgb<=rgb_0;
				--pic_choose <= "001";
		end case;
	end process;
---------------------------------------------------------------------
	process (rgb_a, rgb_b, rgb_c, rgb_d, rgb_e, rgb_f, rgb_g, rgb_0, disp_code)
	begin
		case disp_code is
			when "00000001" =>
				rgb <= rgb_a;
			when "00000010" =>
				rgb <= rgb_b;
			when "00000011" =>
				rgb <= rgb_c;
			when "00000100" =>
				rgb <= rgb_d;
			when "00000101" =>
				rgb <= rgb_e;
			when "00000110" =>
				rgb <= rgb_f;
			when "00000111" =>
				rgb <= rgb_g;
			when others    =>
				rgb <= "000";
		end case;
	end process;
---------------------------------------------------------------------
--u3: bug port map(
--					input => r1,
--					output => r
--				);
--u4: bug port map(
--					input => g1,
--					output => g
--				);
--u5: bug port map(
--					input => b1,
--					output => b
--				);
end vga_rom;