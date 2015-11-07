-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.GlobalDefines.all;
use ieee.std_logic_unsigned.all;
-------------------------------------------------------------------------------------
entity chat is
	port (
		Clock100M_FPGAE			:	in std_logic;	--100MHz
		reset		:	in std_logic;
		
		PS2clk		:	inout std_logic;
		PS2Data		:	in std_logic;
		
		--hs			:	out std_logic;
		--vs			:	out std_logic;
		--rgb			:	buffer RGBColor;
		
		--VGA_B       :   out std_logic_vector(2 downto 0);
		--VGA_G       :   out std_logic_vector(2 downto 0);
		--VGA_R       :   out std_logic_vector(2 downto 0);
---------------------------
	-- data_in, clk_in : std_logic;
	 -- clk_0: in std_logic;
	hs,vs: out STD_LOGIC;
	seg0, seg1 : out std_logic_vector(6 downto 0); 
	seg2, seg3 : out std_logic_vector(6 downto 0);
	seg4, seg5 : out std_logic_vector(6 downto 0);
	seg6, seg07 : out std_logic_vector(6 downto 0);
	r,g,b: out STD_LOGIC_vector(2 downto 0);
------------------------------------
	eeo, eek, eer, erd, ewr : out std_logic;
	debug_input_clk : out std_logic;
	debug_data_in   : out std_logic;
------------------------------------
------------------------------------
		--Serial
		TXD_FPGAE   : out std_logic;
		RXD_FPGAE	: in  std_logic;
		--FPGAC_FPGAE_CPUCLK : in std_logic;
		ClockK_FPGAE: in std_logic --11.0592M
-------------------------------------------------
--		FPGAC_FPGAE_RamAdd    : buffer std_logic_vector(20 downto 0);
--		FPGAC_Ram_Data        : inout std_logic_vector(31 downto 0);
--		FPGAE_FPGAC_RamRW     : buffer std_logic_vector(1 downto 0);
--		FPGAC_FPGAE_Judgement : in std_logic;
--		FPGAC_FPGAE_Reset     : in std_logic;
--		FPGAC_FPGAE_RegCLK : in std_logic;
--		FPGAE_FPGAC_REG1   : out std_logic;
--		FPGAC_FPGAE_RegReset : in std_logic;
----------------------------------------------
--	    FPGAE_Led            : buffer std_logic_vector(2 downto 0);
-----------------------------------------------
--	    Key_FPGAE        : in std_logic_vector(3 downto 0)
-----------------------------------------------
----		prompt		:	out std_logic_vector (3 downto 0)
	);
end entity;
-------------------------------------------------------------------------------------
architecture structural of chat is
	signal prompt :   std_logic_vector(3 downto 0) := "0000";
-------------------------------------------------------------------------------------
	signal clk			:	std_logic;
	signal clk2			:	std_logic;
	signal clk4			:	std_logic;
	signal txtColor		:	ColorLayer;
	signal bgColor		:	ColorLayer;
	signal ttColor		:	ColorLayer;
	signal erColor		:	ColorLayer;
	signal errorShow	:	std_logic;
	signal xPos			:	Coordinate;
	signal yPos			:	Coordinate;
	--signal text			:	StandardWindow;   --CK MODIFIED: UNUSED, AND TEXT IS A RESERVED WORD
	signal keyClk		:	std_logic;
	signal keyIn		:	MyCharacter;


	type	reg_type		is	array (0 to 7) of std_logic_vector(31 downto 0);
	signal	register_file	:	reg_type;
	signal  State		:	std_logic_vector(7 downto 0) := X"00";		--??
	signal  State_RW		:	std_logic_vector(1 downto 0) := "00";
	signal  DataBuffer  :   std_logic_vector(31 downto 0);
	signal  AddrBuffer  :   std_logic_vector(18 downto 0) :=  (others => '0');
	signal  KEY_FPAGE		:	std_logic := '0';
	
	signal err	: std_logic;
	
------------------------------------------------------------------------------------
	signal clk10	: std_logic := '0';
	signal clk1		: std_logic := '0';
	
	signal cntclk10	: integer range 0 to 4;
	signal cntclk1	: integer range 0 to 4;
	
	constant four	: integer	:=  4;
	signal disp_flag : std_logic;
-------------------------------------------------------------------------------------
--	component DivideClock is
--		port (
--			clk		:	in std_logic;
--			reset	:	in std_logic;
--			outClk	:	buffer std_logic
--		);
--	end component;

-------------------------------------------------------------------------------------
component Controller is
	port (
		
		reset		:	in std_logic;  -- reset
	
		clk			:	in std_logic; -- 串口时钟
		clk100		:	in std_logic; -- 100M
		
		PS2Data		:  in std_logic;	
		PS2clk		:	in std_logic;	
		
		RXD_FPGAE	:  in std_logic;	-- 199
		TXD_FPGAE	:  buffer std_logic;	-- 197

		d_out		:	out std_logic;
		output		: 	buffer StandardWindow;
		
		toSeeBitOfRecTest : out std_logic_vector(7 downto 0);
		cap_flag : out std_logic
	);
end component;
	-- by ck
	component vga640480 is
	 port(
			address		:		  out	STD_LOGIC_VECTOR(13 DOWNTO 0);
			reset       :         in  STD_LOGIC;
			clk25       :		  out std_logic; 
			clk_0       :         in  STD_LOGIC; --100M????
			hs,vs       :         out STD_LOGIC; --?????????
			r, g, b		:		  out std_logic_vector(2 downto 0);
			rgb         :         in  std_logic_vector(0 downto 0);
			--input_clk   :         in  std_logic;
			--pic         :         in  std_logic_vector(2 downto 0);
			vga_output  :         in  StandardWindow;
			disp_code   :         out std_logic_vector(7 downto 0);
			disp_flag   :         out std_logic;
			cap_flag    :         in  std_logic

			--rgb_bg      :         in  std_logic_vector(8 downto 0);
			--bg_line     :         out std_logic_vector(4 downto 0)
	  );
end component;
-------------------------------------------------------------------
component seg7 is
port(
code    : in std_logic_vector(3 downto 0);
seg_out : out std_logic_vector(6 downto 0)
);
end component;

component alpha_a IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_b IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_c IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_d IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_e IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_f IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
		);
end component;

component alpha_g IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
		);
end component;

component alpha_h IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_i IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_j IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_k IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_l IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_m IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
		);
end component;

component alpha_n IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
		);
end component;

component alpha_o IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_p IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_q IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_r IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_s IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_t IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
		);
end component;

component alpha_u IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
		);
end component;

component alpha_v IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_w IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_x IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_y IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_z IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_A_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_B_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_C_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_D_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_E_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_F_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_G_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_H_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_I_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_J_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_K_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_L_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_M_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_N_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_O_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_P_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_Q_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_R_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_S_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_T_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_U_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_V_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_W_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_X_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_Y_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_Z_caps IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component num_0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_6 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_7 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_8 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component num_9 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component alpha_sur IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component alpha_que IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component alpha_dot IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component alpha_com IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component ch_a0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_a1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_a2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_a3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_a4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_a5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b6 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b7 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b8 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_b9 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_ba IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_bb IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_bc IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_c0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_c1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_c2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_c3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_c4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_c5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;
component ch_d6 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;

component ch_e0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;	
component ch_f0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
END component;	
component ch_f1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_f2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_f3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_f4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_f5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_g6 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_h0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_h1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_h2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_h3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);
	END component;
component ch_h4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_h5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_h6 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_h7 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_j0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_j1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_j2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_k0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_k1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_k2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_k3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_l0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_l1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_l2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_l3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_m0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_m1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_m2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_n0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_n1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_n2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_n3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_o0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_p0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_p1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_q0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_q1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_q2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_q3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_q4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_q5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_r0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_r1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_r2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_s0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_s1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_s2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_s3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_s4 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_s5 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_t0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_t1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_t2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_t3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_w0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_w1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_w2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_x0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_x1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_x2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_y0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_y1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_y2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_y3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_z0 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_z1 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_z2 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;
component ch_z3 IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		   : IN STD_LOGIC ;
		q      		: out STD_LOGIC_vector(0 downto 0)
	);END component;


-------------------------------------------------------------------------

signal address_tmp: std_logic_vector(13 downto 0);
signal clk25: std_logic;
signal rgb : std_logic_vector(0 downto 0);
signal rgb_a, rgb_b, rgb_c, rgb_d, rgb_e, rgb_f, rgb_g : std_logic_vector(0 downto 0);
signal rgb_h, rgb_i, rgb_j, rgb_k, rgb_l, rgb_m, rgb_n : std_logic_vector(0 downto 0);
signal rgb_o, rgb_p, rgb_q, rgb_r, rgb_s, rgb_t : std_logic_vector(0 downto 0);
signal rgb_u, rgb_v, rgb_w, rgb_x, rgb_y, rgb_z : std_logic_vector(0 downto 0);
signal rgb_A_caps, rgb_B_caps, rgb_C_caps, rgb_D_caps, rgb_E_caps, rgb_F_caps, rgb_G_caps : std_logic_vector(0 downto 0);
signal rgb_H_caps, rgb_I_caps, rgb_J_caps, rgb_K_caps, rgb_L_caps, rgb_M_caps, rgb_N_caps : std_logic_vector(0 downto 0);
signal rgb_O_caps, rgb_P_caps, rgb_Q_caps, rgb_R_caps, rgb_S_caps, rgb_T_caps : std_logic_vector(0 downto 0);
signal rgb_U_caps, rgb_V_caps, rgb_W_caps, rgb_X_caps, rgb_Y_caps, rgb_Z_caps : std_logic_vector(0 downto 0);
signal rgb_0, rgb_1, rgb_2, rgb_3, rgb_4, rgb_5, rgb_6, rgb_7, rgb_8, rgb_9 : std_logic_vector(0 downto 0);
signal rgb_sur, rgb_que, rgb_dot, rgb_com : std_logic_vector(0 downto 0);

------------------------------------------------------------------------------------
signal rgb_a0, rgb_a1, rgb_a2, rgb_a3, rgb_a4, rgb_a5 : std_logic_vector(0 downto 0);
signal rgb_b0, rgb_b1, rgb_b2, rgb_b3, rgb_b4, rgb_b5, rgb_b6, rgb_b7, rgb_b8, rgb_b9, rgb_ba, rgb_bb, rgb_bc : std_logic_vector(0 downto 0);
signal rgb_c0, rgb_c1, rgb_c2, rgb_c3, rgb_c4, rgb_c5 : std_logic_vector(0 downto 0);
signal rgb_d0, rgb_d1, rgb_d2, rgb_d3, rgb_d4, rgb_d5, rgb_d6 : std_logic_vector(0 downto 0);

signal rgb_e0 : std_logic_vector(0 downto 0);
signal rgb_f0 : std_logic_vector(0 downto 0);
signal rgb_f1 : std_logic_vector(0 downto 0);
signal rgb_f2 : std_logic_vector(0 downto 0);
signal rgb_f3 : std_logic_vector(0 downto 0);
signal rgb_f4 : std_logic_vector(0 downto 0);
signal rgb_f5 : std_logic_vector(0 downto 0);
signal rgb_g0 : std_logic_vector(0 downto 0);
signal rgb_g1 : std_logic_vector(0 downto 0);
signal rgb_g2 : std_logic_vector(0 downto 0);
signal rgb_g3 : std_logic_vector(0 downto 0);
signal rgb_g4 : std_logic_vector(0 downto 0);
signal rgb_g5 : std_logic_vector(0 downto 0);
signal rgb_g6 : std_logic_vector(0 downto 0);
signal rgb_h0 : std_logic_vector(0 downto 0);
signal rgb_h1 : std_logic_vector(0 downto 0);
signal rgb_h2 : std_logic_vector(0 downto 0);
signal rgb_h3 : std_logic_vector(0 downto 0);
signal rgb_h4 : std_logic_vector(0 downto 0);
signal rgb_h5 : std_logic_vector(0 downto 0);
signal rgb_h6 : std_logic_vector(0 downto 0);
signal rgb_h7 : std_logic_vector(0 downto 0);
--signal rgb_h8 : std_logic_vector(0 downto 0);
signal rgb_j0 : std_logic_vector(0 downto 0);
signal rgb_j1 : std_logic_vector(0 downto 0);
signal rgb_j2 : std_logic_vector(0 downto 0);
signal rgb_k0 : std_logic_vector(0 downto 0);
signal rgb_k1 : std_logic_vector(0 downto 0);
signal rgb_k2 : std_logic_vector(0 downto 0);
signal rgb_k3 : std_logic_vector(0 downto 0);
--signal rgb_k4 : std_logic_vector(0 downto 0);
signal rgb_l0 : std_logic_vector(0 downto 0);
signal rgb_l1 : std_logic_vector(0 downto 0);
signal rgb_l2 : std_logic_vector(0 downto 0);
signal rgb_l3 : std_logic_vector(0 downto 0);
signal rgb_m0 : std_logic_vector(0 downto 0);
signal rgb_m1 : std_logic_vector(0 downto 0);
signal rgb_m2 : std_logic_vector(0 downto 0);
signal rgb_n0 : std_logic_vector(0 downto 0);
signal rgb_n1 : std_logic_vector(0 downto 0);
signal rgb_n2 : std_logic_vector(0 downto 0);
signal rgb_n3 : std_logic_vector(0 downto 0);
signal rgb_o0 : std_logic_vector(0 downto 0);
signal rgb_p0 : std_logic_vector(0 downto 0);
signal rgb_p1 : std_logic_vector(0 downto 0);
signal rgb_q0 : std_logic_vector(0 downto 0);
signal rgb_q1 : std_logic_vector(0 downto 0);
signal rgb_q2 : std_logic_vector(0 downto 0);
signal rgb_q3 : std_logic_vector(0 downto 0);
signal rgb_q4 : std_logic_vector(0 downto 0);
signal rgb_q5 : std_logic_vector(0 downto 0);
signal rgb_r0 : std_logic_vector(0 downto 0);
signal rgb_r1 : std_logic_vector(0 downto 0);
signal rgb_r2 : std_logic_vector(0 downto 0);
signal rgb_s0 : std_logic_vector(0 downto 0);
signal rgb_s1 : std_logic_vector(0 downto 0);
signal rgb_s2 : std_logic_vector(0 downto 0);
signal rgb_s3 : std_logic_vector(0 downto 0);
signal rgb_s4 : std_logic_vector(0 downto 0);
signal rgb_s5 : std_logic_vector(0 downto 0);
signal rgb_t0 : std_logic_vector(0 downto 0);
signal rgb_t1 : std_logic_vector(0 downto 0);
signal rgb_t2 : std_logic_vector(0 downto 0);
signal rgb_t3 : std_logic_vector(0 downto 0);
signal rgb_w0 : std_logic_vector(0 downto 0);
signal rgb_w1 : std_logic_vector(0 downto 0);
signal rgb_w2 : std_logic_vector(0 downto 0);
signal rgb_x0 : std_logic_vector(0 downto 0);
signal rgb_x1 : std_logic_vector(0 downto 0);
signal rgb_x2 : std_logic_vector(0 downto 0);
signal rgb_y0 : std_logic_vector(0 downto 0);
signal rgb_y1 : std_logic_vector(0 downto 0);
signal rgb_y2 : std_logic_vector(0 downto 0);
signal rgb_y3 : std_logic_vector(0 downto 0);
signal rgb_z0 : std_logic_vector(0 downto 0);
signal rgb_z1 : std_logic_vector(0 downto 0);
signal rgb_z2 : std_logic_vector(0 downto 0);
signal rgb_z3 : std_logic_vector(0 downto 0);


--signal rgb_bg : std_logic_vector(8 downto 0);
--signal rgb_1, rgb_2, rgb_3, rgb_4, rgb_5, rgb_6, rgb_7, rgb_8, rgb_9, rgb_10, rgb_11, rgb_12, rgb_13, rgb_14, rgb_15, rgb_16, rgb_17, rgb_18, rgb_19 : std_logic_vector(2 downto 0);
signal r1 , g1, b1 : std_logic;
signal cap_flag : std_logic;

signal data_in, clk_in : std_logic;
-------------------------------------------------------------------

signal char_code : std_logic_vector(7 downto 0);			--
signal disp_code : std_logic_vector(7 downto 0);
signal vga_update_clk : std_logic;
signal vga_output : StandardWindow;
signal key : MyCharacter;
signal ek : std_logic;
signal input_clk : std_logic := '1';
signal window : StandardWindow;
signal clk_0 : std_logic;
signal er,ew,es,eo : std_logic;
signal rec, send : MyString_40d;
signal dataR, dataT : std_logic_vector (7 downto 0);
signal rd,wr : std_logic;
signal rst : std_logic;
signal scancode   :  std_logic_vector(7 downto 0);
signal pic_choose :  std_logic_vector(2 downto 0);    -- 0: 16*32  1: 128*128
signal bg_line    :  std_logic_vector(4 downto 0);
signal keyClkck     :  std_logic;

signal yy_test      :   std_logic_vector(3 downto 0);
--signal 
---------ck--------
signal ck_debug_count1 : std_logic_vector(3 downto 0);

signal toseestatetest: std_logic_vector(7 downto 0);
-------------------------------------------------------------------------------------
begin
---------------------------------------------------------------------------


	key <= char_code;
	ek <= not input_clk;					-------------ck
	
	process(reset, eo)
	begin
		if(reset = '0') then
			--
			for i in 0 to 10 loop
				vga_output(i).txt <= (others => char_null);
			end loop;
		elsif(falling_edge(eo)) then
			vga_output <= window;
		end if;
	end process;
	
	clk_0 <= Clock100M_FPGAE;
	clk <= Clock100M_FPGAE;
	
	clk_in <= PS2clk;
	data_in <= PS2Data;
	
	eeo <= eo;
	eek <= ek;
	eer <= er;
	erd <= rd;
	ewr <= wr;
	debug_input_clk <= input_clk;
	debug_data_in <= eo;
----


    
	 u_controller : Controller port map
	 (
		
		reset		=> reset,  -- reset
	
		clk			=> ClockK_FPGAE, -- 串口时钟
		clk100		=> Clock100M_FPGAE, -- 100M
		
		PS2Data		=> PS2Data,	
		PS2clk		=> PS2clk,	
		
		RXD_FPGAE	=> RXD_FPGAE,	-- 199
		TXD_FPGAE	=> TXD_FPGAE,	-- 197

		d_out		=> eo,
		output		=> window,
		toSeeBitOfRecTest => toseestatetest,
		cap_flag=>cap_flag
	);
	
    
--	vga_output(0).txt(0) <= CHAR_a;
--	vga_output(0).txt(1) <= CHAR_b;
--	vga_output(0).txt(2) <= CHAR_b;
--	vga_output(0).txt(3) <= CHAR_f;
--	vga_output(0).txt(4) <= CHAR_f;
--	vga_output(0).txt(5) <= CHAR_c;
--	vga_output(0).txt(6) <= CHAR_d;
--	vga_output(0).txt(7) <= CHAR_c;
--	vga_output(0).txt(8) <= CHAR_c;
--	vga_output(0).txt(9) <= CHAR_c;
--	vga_output(0).txt(10) <= CHAR_c;
--	vga_output(0).txt(11) <= CHAR_c;
--	vga_output(0).txt(12) <= CHAR_a;
--	vga_output(0).txt(13) <= CHAR_a;
--	vga_output(0).txt(14) <= CHAR_a;
--	vga_output(0).txt(15) <= CHAR_a;
--	vga_output(0).txt(16) <= CHAR_a;
--	vga_output(0).txt(17) <= CHAR_a;
--	vga_output(0).txt(18) <= CHAR_a;
--	vga_output(0).txt(19) <= CHAR_a;
--	vga_output(0).txt(20) <= CHAR_a;
--	vga_output(0).txt(21) <= CHAR_a;
--	vga_output(0).txt(22) <= CHAR_a;
--	vga_output(0).txt(23) <= CHAR_a;
--	vga_output(0).txt(24) <= CHAR_NULL;
--	vga_output(1).txt(0) <= CHAR_c;
--	vga_output(1).txt(1) <= CHAR_d;
--	vga_output(1).txt(2) <= CHAR_NULL;
--	vga_output(2).txt(0) <= CHAR_e;
--	vga_output(2).txt(1) <= CHAR_f;
--	vga_output(2).txt(2) <= CHAR_NULL;
--	vga_output(3).txt(0) <= CHAR_a;
--	vga_output(3).txt(1) <= CHAR_b;
--	vga_output(3).txt(2) <= CHAR_NULL;
--	vga_output(4).txt(0) <= CHAR_g;
--	vga_output(4).txt(1) <= CHAR_a;
--	vga_output(4).txt(2) <= CHAR_NULL;

----------------------------------------------------------------
--r1 <= rgb(2);
--g1 <= rgb(1);
--b1 <= rgb(0);
	rst <= not reset;	-- need

u1: vga640480 port map(
						address  =>  address_tmp, 
						reset    =>  reset, 
						clk25    =>  clk25, 
						clk_0    =>  clk_0, 
						hs       =>  hs, 
						vs       =>  vs,
						r=>r,   g=>g,   b=>b,
						rgb      =>  rgb,
						--input_clk => input_clk,
						--pic      =>  pic_choose,
						vga_output => vga_output,
						disp_code => disp_code,
						disp_flag => disp_flag,
						cap_flag=>cap_flag
						--rgb_bg   =>  rgb_bg,
						--bg_line  =>  bg_line
					);

u22: seg7 port map(window(1).txt(0)(7 downto 4),seg0);			
u21: seg7 port map(window(1).txt(0)(3 downto 0),seg1);
u_seg7_3 : seg7 port map(window(1).txt(1)(7 downto 4), seg2);
u_seg7_4 : seg7 port map(window(1).txt(1)(3 downto 0), seg3);
u_seg7_5 : seg7 port map(window(1).txt(2)(7 downto 4), seg4);
u_seg7_6 : seg7 port map(window(1).txt(2)(3 downto 0), seg5);
u_seg7_7 : seg7 port map(toseestatetest(7 downto 4), seg6);
u_seg7_8 : seg7 port map(toseestatetest(3 downto 0), seg07);

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
u2_8: alpha_h port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h
					);

u2_9: alpha_i port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_i
					);
u2_10: alpha_j port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_j
					);

u2_11: alpha_k port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_k
					);
u2_12: alpha_l port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_l
					);

u2_13: alpha_m port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_m
					);
u2_14: alpha_n port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_n
					);
u2_15: alpha_o port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_o
					);

u2_16: alpha_p port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_p
					);
u2_17: alpha_q port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q
					);

u2_18: alpha_r port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_r
					);
u2_19: alpha_s port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s
					);

u2_20: alpha_t port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_t
					);
u2_21: alpha_u port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_u
					);
u2_22: alpha_v port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_v
					);

u2_23: alpha_w port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_w
					);
u2_24: alpha_x port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_x
					);

u2_25: alpha_y port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_y
					);
u2_26: alpha_z port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_z
					);
					
u2_27: alpha_A_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_A_caps
					);
u2_28: alpha_b_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b_caps
					);
u2_29: alpha_c_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c_caps
					);
u2_30: alpha_d_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d_caps
					);
u2_31: alpha_e_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_e_caps
					);
u2_32: alpha_f_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f_caps
					);
u2_33: alpha_g_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g_caps
					);
u2_34: alpha_h_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h_caps
					);
u2_35: alpha_i_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_i_caps
					);
u2_36: alpha_j_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_j_caps
					);
u2_37: alpha_k_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_k_caps
					);
u2_38: alpha_l_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_l_caps
					);
u2_39: alpha_m_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_m_caps
					);
u2_40: alpha_n_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_n_caps
					);
u2_41: alpha_o_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_o_caps
					);
u2_42: alpha_p_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_p_caps
					);
u2_43: alpha_q_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q_caps
					);
u2_44: alpha_r_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_r_caps
					);
u2_45: alpha_s_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s_caps
					);
u2_46: alpha_t_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_t_caps
					);
u2_47: alpha_u_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_u_caps
					);
u2_48: alpha_v_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_v_caps
					);
u2_49: alpha_w_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_w_caps
					);
u2_50: alpha_x_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_x_caps
					);
u2_51: alpha_y_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_y_caps
					);
u2_52: alpha_z_caps port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_z_caps
					);					

u2_53: num_0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_0
					);	
u2_54: num_1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_1
					);
u2_55: num_2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_2
					);
u2_56: num_3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_3
					);
u2_57: num_4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_4
					);
u2_58: num_5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_5
					);
u2_59: num_6 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_6
					);
u2_60: num_7 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_7
					);
u2_61: num_8 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_8
					);
u2_62: num_9 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_9
					);
					
u2_63: alpha_sur port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_sur
					);					
u2_64: alpha_que port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_que
					);
u2_65: alpha_dot port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_dot
					);
u2_66: alpha_com port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_com
					);					
					
u_ch_1: ch_a0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a0
					);
u_ch_2: ch_a1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a1
					);
u_ch_3: ch_a2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a2
					);
u_ch_4: ch_a3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a3
					);
u_ch_5: ch_a4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a4
					);
u_ch_6: ch_a5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_a5
					);
u_ch_7: ch_b0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b0
					);
u_ch_8: ch_b1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b1
					);
u_ch_9: ch_b2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b2
					);
u_ch_10: ch_b3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b3
					);
u_ch_11: ch_b4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b4
					);
u_ch_12: ch_b5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b5
					);
u_ch_13: ch_b6 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b6
					);
u_ch_14: ch_b7 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b7
					);
u_ch_15: ch_b8 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b8
					);
u_ch_16: ch_b9 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_b9
					);
u_ch_17: ch_ba port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_ba
					);
u_ch_18: ch_bb port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_bb
					);
u_ch_19: ch_bc port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_bc
					);
u_ch_20: ch_c0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c0
					);
u_ch_21: ch_c1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c1
					);
u_ch_22: ch_c2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c2
					);
u_ch_23: ch_c3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c3
					);
u_ch_24: ch_c4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c4
					);
u_ch_25: ch_c5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_c5
					);
u_ch_26: ch_d0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d0
					);
u_ch_27: ch_d1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d1
					);
u_ch_28: ch_d2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d2
					);
u_ch_29: ch_d3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d3
					);
u_ch_30: ch_d4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d4
					);
u_ch_31: ch_d5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d5
					);
u_ch_32: ch_d6 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_d6
					);
					
u_ch_33: ch_e0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_e0
					);
u_ch_34: ch_f0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f0
					);
u_ch_35: ch_f1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f1
					);
u_ch_36: ch_f2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f2
					);
u_ch_37: ch_f3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f3
					);
u_ch_38: ch_f4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f4
					);
u_ch_39: ch_f5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_f5
					);
u_ch_40: ch_g0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g0
					);
u_ch_41: ch_g1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g1
					);
u_ch_42: ch_g2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g2
					);
u_ch_43: ch_g3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g3
					);
u_ch_44: ch_g4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g4
					);
u_ch_45: ch_g5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g5
					);
u_ch_46: ch_g6 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_g6
					);
u_ch_47: ch_h0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h0
					);
u_ch_48: ch_h1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h1
					);
u_ch_49: ch_h2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h2
					);
u_ch_50: ch_h3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h3
					);
u_ch_51: ch_h4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h4
					);
u_ch_52: ch_h5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h5
					);
u_ch_53: ch_h6 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h6
					);
u_ch_54: ch_h7 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_h7
					);
--u_ch_55: ch_h8 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_h8
--					);
u_ch_56: ch_j0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_j0
					);
u_ch_57: ch_j1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_j1
					);
u_ch_58: ch_j2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_j2
					);
u_ch_59: ch_k0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_k0
					);
u_ch_60: ch_k1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_k1
					);
u_ch_61: ch_k2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_k2
					);
u_ch_62: ch_k3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_k3
					);
--u_ch_63: ch_k4 port map(	
--						address=>address_tmp, 
--						clock=>clk25, 
--						q => rgb_k4
--					);
u_ch_64: ch_l0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_l0
					);
u_ch_65: ch_l1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_l1
					);
u_ch_66: ch_l2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_l2
					);
u_ch_67: ch_l3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_l3
					);
u_ch_68: ch_m0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_m0
					);
u_ch_69: ch_m1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_m1
					);
u_ch_70: ch_m2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_m2
					);
u_ch_71: ch_n0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_n0
					);
u_ch_72: ch_n1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_n1
					);
u_ch_73: ch_n2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_n2
					);
u_ch_74: ch_n3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_n3
					);
u_ch_75: ch_o0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_o0
					);
u_ch_76: ch_p0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_p0
					);
u_ch_77: ch_p1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_p1
					);
u_ch_78: ch_q0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q0
					);
u_ch_79: ch_q1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q1
					);
u_ch_80: ch_q2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q2
					);
u_ch_81: ch_q3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q3
					);
u_ch_82: ch_q4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q4
					);
u_ch_83: ch_q5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_q5
					);
u_ch_84: ch_r0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_r0
					);
u_ch_85: ch_r1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_r1
					);
u_ch_86: ch_r2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_r2
					);
u_ch_87: ch_s0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s0
					);
u_ch_88: ch_s1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s1
					);
u_ch_89: ch_s2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s2
					);
u_ch_90: ch_s3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s3
					);
u_ch_91: ch_s4 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s4
					);
u_ch_92: ch_s5 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_s5
					);
u_ch_93: ch_t0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_t0
					);
u_ch_94: ch_t1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_t1
					);
u_ch_95: ch_t2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_t2
					);
u_ch_96: ch_t3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_t3
					);
u_ch_97: ch_w0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_w0
					);
u_ch_98: ch_w1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_w1
					);
u_ch_99: ch_w2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_w2
					);
u_ch_100: ch_x0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_x0
					);
u_ch_101: ch_x1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_x1
					);
u_ch_102: ch_x2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_x2
					);
u_ch_103: ch_y0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_y0
					);
u_ch_104: ch_y1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_y1
					);
u_ch_105: ch_y2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_y2
					);
u_ch_106: ch_y3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_y3
					);
u_ch_107: ch_z0 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_z0
					);
u_ch_108: ch_z1 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_z1
					);
u_ch_109: ch_z2 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_z2
					);
u_ch_110: ch_z3 port map(	
						address=>address_tmp, 
						clock=>clk25, 
						q => rgb_z3
					);
				

--------------------------------------------------------------
-- 锟斤拷锟斤拷要锟斤拷!!!
	process (--rgb_a, rgb_b, rgb_c, rgb_d, rgb_e, rgb_f, rgb_g, 
			--rgb_h, rgb_i, rgb_j, rgb_k, rgb_l, rgb_m, rgb_n,
			--rgb_o, rgb_p, rgb_q, rgb_r, rgb_s, rgb_t,
			--rgb_u, rgb_v, rgb_w, rgb_x, rgb_y, rgb_z,
			--rgb_a_caps, rgb_b_caps, rgb_c_caps, rgb_d_caps, rgb_e_caps, rgb_f_caps, rgb_g_caps, 
			--rgb_h_caps, rgb_i_caps, rgb_j_caps, rgb_k_caps, rgb_l_caps, rgb_m_caps, rgb_n_caps,
			--rgb_o_caps, rgb_p_caps, rgb_q_caps, rgb_r_caps, rgb_s_caps, rgb_t_caps,
			--rgb_u_caps, rgb_v_caps, rgb_w_caps, rgb_x_caps, rgb_y_caps, rgb_z_caps,
			--rgb_0, rgb_1, rgb_2, rgb_3, rgb_4, rgb_5, rgb_6, rgb_7, rgb_8, rgb_9,
			--rgb_sur, rgb_que, rgb_dot, rgb_com, 
			disp_code, disp_flag)
	begin
	 if(disp_flag = '0') then
		case disp_code is
			when CHAR_a =>
				rgb <= rgb_a;
			when CHAR_b =>
				rgb <= rgb_b;
			when CHAR_c =>
				rgb <= rgb_c;
			when CHAR_d =>
				rgb <= rgb_d;
			when CHAR_e =>
				rgb <= rgb_e;
			when CHAR_f =>
				rgb <= rgb_f;
			when CHAR_g =>
				rgb <= rgb_g;
			when CHAR_h =>
				rgb <= rgb_h;
			when CHAR_i =>
				rgb <= rgb_i;
			when CHAR_j =>
				rgb <= rgb_j;
			when CHAR_k =>
				rgb <= rgb_k;
			when CHAR_l =>
				rgb <= rgb_l;
			when CHAR_m =>
				rgb <= rgb_m;
			when CHAR_n =>
				rgb <= rgb_n;
			when CHAR_o =>
				rgb <= rgb_o;
			when CHAR_p =>
				rgb <= rgb_p;
			when CHAR_q =>
				rgb <= rgb_q;
			when CHAR_r =>
				rgb <= rgb_r;
			when CHAR_s =>
				rgb <= rgb_s;
			when CHAR_t =>
				rgb <= rgb_t;
			when CHAR_u =>
				rgb <= rgb_u;
			when CHAR_v =>
				rgb <= rgb_v;
			when CHAR_w =>
				rgb <= rgb_w;
			when CHAR_x =>
				rgb <= rgb_x;
			when CHAR_y =>
				rgb <= rgb_y;
			when CHAR_z =>
				rgb <= rgb_z;
				
			when CHAR_a_caps =>
				rgb <= rgb_a_caps;
			when CHAR_b_caps =>
				rgb <= rgb_b_caps;
			when CHAR_c_caps =>
				rgb <= rgb_c_caps;
			when CHAR_d_caps =>
				rgb <= rgb_d_caps;
			when CHAR_e_caps =>
				rgb <= rgb_e_caps;
			when CHAR_f_caps =>
				rgb <= rgb_f_caps;
			when CHAR_g_caps =>
				rgb <= rgb_g_caps;
			when CHAR_h_caps =>
				rgb <= rgb_h_caps;
			when CHAR_i_caps =>
				rgb <= rgb_i_caps;
			when CHAR_j_caps =>
				rgb <= rgb_j_caps;
			when CHAR_k_caps =>
				rgb <= rgb_k_caps;
			when CHAR_l_caps =>
				rgb <= rgb_l_caps;
			when CHAR_m_caps =>
				rgb <= rgb_m_caps;
			when CHAR_n_caps =>
				rgb <= rgb_n_caps;
			when CHAR_o_caps =>
				rgb <= rgb_o_caps;
			when CHAR_p_caps =>
				rgb <= rgb_p_caps;
			when CHAR_q_caps =>
				rgb <= rgb_q_caps;
			when CHAR_r_caps =>
				rgb <= rgb_r_caps;
			when CHAR_s_caps =>
				rgb <= rgb_s_caps;
			when CHAR_t_caps =>
				rgb <= rgb_t_caps;
			when CHAR_u_caps =>
				rgb <= rgb_u_caps;
			when CHAR_v_caps =>
				rgb <= rgb_v_caps;
			when CHAR_w_caps =>
				rgb <= rgb_w_caps;
			when CHAR_x_caps =>
				rgb <= rgb_x_caps;
			when CHAR_y_caps =>
				rgb <= rgb_y_caps;
			when CHAR_z_caps =>
				rgb <= rgb_z_caps;
			
			when CHAR_0 =>
				rgb <= rgb_0;
			when CHAR_1 =>
				rgb <= rgb_1;
			when CHAR_2 =>
				rgb <= rgb_2;
			when CHAR_3 =>
				rgb <= rgb_3;
			when CHAR_4 =>
				rgb <= rgb_4;
			when CHAR_5 =>
				rgb <= rgb_5;
			when CHAR_6 =>
				rgb <= rgb_6;
			when CHAR_7 =>
				rgb <= rgb_7;
			when CHAR_8 =>
				rgb <= rgb_8;
			when CHAR_9 =>
				rgb <= rgb_9;
				
			when CHAR_sur =>
				rgb <= rgb_sur;
			when CHAR_que =>
				rgb <= rgb_que;
			when CHAR_dot =>
				rgb <= rgb_dot;
			when CHAR_com =>
				rgb <= rgb_com;
			
			when char_space =>
				rgb <= "0";
			when others =>
				--can't recognize
		end case;
	 else
	   case disp_code is
			when char_a0 =>  rgb <= rgb_a0;
			when char_a1 =>  rgb <= rgb_a1;
			when char_a2 =>  rgb <= rgb_a2;
			when char_a3 =>  rgb <= rgb_a3;
			when char_a4 =>  rgb <= rgb_a4;
			when char_a5 =>  rgb <= rgb_a5;
			when char_b0 =>  rgb <= rgb_b0;
			when char_b1 =>  rgb <= rgb_b1;
			when char_b2 =>  rgb <= rgb_b2;
			when char_b3 =>  rgb <= rgb_b3;
			when char_b4 =>  rgb <= rgb_b4;
			when char_b5 =>  rgb <= rgb_b5;
			when char_b6 =>  rgb <= rgb_b6;
			when char_b7 =>  rgb <= rgb_b7;
			when char_b8 =>  rgb <= rgb_b8;
			when char_b9 =>  rgb <= rgb_b9;
			when char_ba =>  rgb <= rgb_ba;
			when char_bb =>  rgb <= rgb_bb;
			when char_bc =>  rgb <= rgb_bc;
			when char_c0 =>  rgb <= rgb_c0;
			when char_c1 =>  rgb <= rgb_c1;
			when char_c2 =>  rgb <= rgb_c2;
			when char_c3 =>  rgb <= rgb_c3;
			when char_c4 =>  rgb <= rgb_c4;
			when char_c5 =>  rgb <= rgb_c5;
			when char_d0 =>  rgb <= rgb_d0;
			when char_d1 =>  rgb <= rgb_d1;
			when char_d2 =>  rgb <= rgb_d2;
			when char_d3 =>  rgb <= rgb_d3;
			when char_d4 =>  rgb <= rgb_d4;
			when char_d5 =>  rgb <= rgb_d5;
			when char_d6 =>  rgb <= rgb_d6;
			
			when char_e0 =>  rgb <= rgb_e0;
			when char_f0 =>  rgb <= rgb_f0;
			when char_f1 =>  rgb <= rgb_f1;
			when char_f2 =>  rgb <= rgb_f2;
			when char_f3 =>  rgb <= rgb_f3;
			when char_f4 =>  rgb <= rgb_f4;
			when char_f5 =>  rgb <= rgb_f5;
			when char_g0 =>  rgb <= rgb_g0;
			when char_g1 =>  rgb <= rgb_g1;
			when char_g2 =>  rgb <= rgb_g2;
			when char_g3 =>  rgb <= rgb_g3;
			when char_g4 =>  rgb <= rgb_g4;
			when char_g5 =>  rgb <= rgb_g5;
			when char_g6 =>  rgb <= rgb_g6;
			when char_h0 =>  rgb <= rgb_h0;
			when char_h1 =>  rgb <= rgb_h1;
			when char_h2 =>  rgb <= rgb_h2;
			when char_h3 =>  rgb <= rgb_h3;
			when char_h4 =>  rgb <= rgb_h4;
			when char_h5 =>  rgb <= rgb_h5;
			when char_h6 =>  rgb <= rgb_h6;
			when char_h7 =>  rgb <= rgb_h7;
			--when char_h8 =>  rgb <= rgb_h8;
			when char_j0 =>  rgb <= rgb_j0;
			when char_j1 =>  rgb <= rgb_j1;
			when char_j2 =>  rgb <= rgb_j2;
			when char_k0 =>  rgb <= rgb_k0;
			when char_k1 =>  rgb <= rgb_k1;
			when char_k2 =>  rgb <= rgb_k2;
			when char_k3 =>  rgb <= rgb_k3;
			--when char_k4 =>  rgb <= rgb_k4;
			when char_l0 =>  rgb <= rgb_l0;
			when char_l1 =>  rgb <= rgb_l1;
			when char_l2 =>  rgb <= rgb_l2;
			when char_l3 =>  rgb <= rgb_l3;
			when char_m0 =>  rgb <= rgb_m0;
			when char_m1 =>  rgb <= rgb_m1;
			when char_m2 =>  rgb <= rgb_m2;
			when char_n0 =>  rgb <= rgb_n0;
			when char_n1 =>  rgb <= rgb_n1;
			when char_n2 =>  rgb <= rgb_n2;
			when char_n3 =>  rgb <= rgb_n3;
			when char_o0 =>  rgb <= rgb_o0;
			when char_p0 =>  rgb <= rgb_p0;
			when char_p1 =>  rgb <= rgb_p1;
			when char_q0 =>  rgb <= rgb_q0;
			when char_q1 =>  rgb <= rgb_q1;
			when char_q2 =>  rgb <= rgb_q2;
			when char_q3 =>  rgb <= rgb_q3;
			when char_q4 =>  rgb <= rgb_q4;
			when char_q5 =>  rgb <= rgb_q5;
			when char_r0 =>  rgb <= rgb_r0;
			when char_r1 =>  rgb <= rgb_r1;
			when char_r2 =>  rgb <= rgb_r2;
			when char_s0 =>  rgb <= rgb_s0;
			when char_s1 =>  rgb <= rgb_s1;
			when char_s2 =>  rgb <= rgb_s2;
			when char_s3 =>  rgb <= rgb_s3;
			when char_s4 =>  rgb <= rgb_s4;
			when char_s5 =>  rgb <= rgb_s5;
			when char_t0 =>  rgb <= rgb_t0;
			when char_t1 =>  rgb <= rgb_t1;
			when char_t2 =>  rgb <= rgb_t2;
			when char_t3 =>  rgb <= rgb_t3;
			when char_w0 =>  rgb <= rgb_w0;
			when char_w1 =>  rgb <= rgb_w1;
			when char_w2 =>  rgb <= rgb_w2;
			when char_x0 =>  rgb <= rgb_x0;
			when char_x1 =>  rgb <= rgb_x1;
			when char_x2 =>  rgb <= rgb_x2;
			when char_y0 =>  rgb <= rgb_y0;
			when char_y1 =>  rgb <= rgb_y1;
			when char_y2 =>  rgb <= rgb_y2;
			when char_y3 =>  rgb <= rgb_y3;
			when char_z0 =>  rgb <= rgb_z0;
			when char_z1 =>  rgb <= rgb_z1;
			when char_z2 =>  rgb <= rgb_z2;
			when char_z3 =>  rgb <= rgb_z3;

			
			when others  =>  rgb <= "0";---------------can't recognize
		end case;
	 end if;
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
    
    end architecture;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------