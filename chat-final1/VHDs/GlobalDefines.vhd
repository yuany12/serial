-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
-------------------------------------------------------------------------------------
package GlobalDefines is
-------------------------------------------------------------------------------------
	
	subtype	MyCharacter		is	std_logic_vector(7 downto 0);
	type	MyString		is	array (Natural range <>) of MyCharacter;
	subtype	MyString_40d		is	MyString(40 downto 0);
	subtype	LengthInt		is	Integer range 0 to 40;
	-- 字符类型定义
	--subtype  ChineseChar		is std_logic_vector(15 downto 0);
	
	-- 字符表, 现在暂时支持8位
	constant CHAR_NULL		:	MyCharacter	:=	"00000000"; --------------
	constant CHAR_ENTER		:	MyCharacter	:=  "11111111";
	constant CHAR_BACKSPACE	:	MyCharacter	:=  "11111110";
---------------------------------------------------------------------
	constant CHAR_SPACE     :  MyCharacter	:=	"10000000";----------------
	constant CHAR_a			:	MyCharacter	:=	"00000001";		--small 1~26 big 27~52
	constant CHAR_b			:	MyCharacter	:=	"00000010";
	constant CHAR_c			:	MyCharacter	:=	"00000011";
	constant CHAR_d			:	MyCharacter	:=	"00000100";
	constant CHAR_e			:	MyCharacter	:=	"00000101";
	constant CHAR_f			:	MyCharacter	:=	"00000110";
	constant CHAR_g			:	MyCharacter	:=	"00000111";
	constant CHAR_h			:	MyCharacter	:=	"00001000";
	constant CHAR_i			:	MyCharacter	:=	"00001001";
	constant CHAR_j			:	MyCharacter	:=	"00001010";
	constant CHAR_k			:	MyCharacter	:=	"00001011";
	constant CHAR_l			:	MyCharacter	:=	"00001100";
	constant CHAR_m			:	MyCharacter	:=	"00001101";
	constant CHAR_n			:	MyCharacter	:=	"00001110";
	constant CHAR_o			:	MyCharacter	:=	"00001111";
	constant CHAR_p			:	MyCharacter	:=	"00010000";
	constant CHAR_q			:	MyCharacter	:=	"00010001";
	constant CHAR_r			:	MyCharacter	:=	"00010010";
	constant CHAR_s			:	MyCharacter	:=	"00010011";
	constant CHAR_t			:	MyCharacter	:=	"00010100";
	constant CHAR_u			:	MyCharacter	:=	"00010101";
	constant CHAR_v			:	MyCharacter	:=	"00010110";
	constant CHAR_w			:	MyCharacter	:=	"00010111";
	constant CHAR_x			:	MyCharacter	:=	"00011000";
	constant CHAR_y			:	MyCharacter	:=	"00011001";
	constant CHAR_z			:	MyCharacter	:=	"00011010";
	--caps
	constant CHAR_A_caps		:	MyCharacter	:=	"00011011";
	constant CHAR_B_caps		:	MyCharacter	:=	"00011100";
	constant CHAR_C_caps		:	MyCharacter	:=	"00011101";
	constant CHAR_D_caps		:	MyCharacter	:=	"00011110";
	constant CHAR_E_caps		:	MyCharacter	:=	"00011111";
	constant CHAR_F_caps		:	MyCharacter	:=	"00100000";		--32
	constant CHAR_G_caps		:	MyCharacter	:=	"00100001";
	constant CHAR_H_caps		:	MyCharacter	:=	"00100010";
	constant CHAR_I_caps		:	MyCharacter	:=	"00100011";
	constant CHAR_J_caps		:	MyCharacter	:=	"00100100";
	constant CHAR_K_caps		:	MyCharacter	:=	"00100101";
	constant CHAR_L_caps		:	MyCharacter	:=	"00100110";
	constant CHAR_M_caps		:	MyCharacter	:=	"00100111";
	constant CHAR_N_caps		:	MyCharacter	:=	"00101000";
	constant CHAR_O_caps		:	MyCharacter	:=	"00101001";
	constant CHAR_P_caps		:	MyCharacter	:=	"00101010";
	constant CHAR_Q_caps		:	MyCharacter	:=	"00101011";
	constant CHAR_R_caps		:	MyCharacter	:=	"00101100";
	constant CHAR_S_caps		:	MyCharacter	:=	"00101101";
	constant CHAR_T_caps		:	MyCharacter	:=	"00101110";
	constant CHAR_U_caps		:	MyCharacter	:=	"00101111";
	constant CHAR_V_caps		:	MyCharacter	:=	"00110000";
	constant CHAR_W_caps		:	MyCharacter	:=	"00110001";
	constant CHAR_X_caps		:	MyCharacter	:=	"00110010";
	constant CHAR_Y_caps		:	MyCharacter	:=	"00110011";
	constant CHAR_Z_caps		:	MyCharacter	:=	"00110100";  --26~52 BIG ALPHA CHARS
	------53~62 num 0~9
	constant CHAR_0		   :	MyCharacter	:=	"00110101";		
	constant CHAR_1		   :	MyCharacter	:=	"00110110";
	constant CHAR_2		   :	MyCharacter	:=	"00110111";		--
	constant CHAR_3		   :	MyCharacter	:=	"00111000";
	constant CHAR_4		   :	MyCharacter	:=	"00111001";
	constant CHAR_5		   :	MyCharacter	:=	"00111010";
	constant CHAR_6		   :	MyCharacter	:=	"00111011";
	constant CHAR_7		   :	MyCharacter	:=	"00111100";
	constant CHAR_8		   :	MyCharacter	:=	"00111101";
	constant CHAR_9		   :	MyCharacter	:=	"00111110";		--62
	-------punctuation
	constant CHAR_com		   :	MyCharacter	:=	"00111111";
	constant CHAR_dot		   :	MyCharacter	:=	"01000000";
	constant CHAR_que		   :	MyCharacter	:=	"01000001";
	constant CHAR_sur		   :	MyCharacter	:=	"01000010";		--66
	
	--------chineseChar
	constant CHINESE_HEAD   :  MyCharacter	:=	"10101010";		-------------------------
	constant CHAR_a0		   :	MyCharacter	:=	"00000001";
	constant CHAR_a1		   :	MyCharacter	:=	"00000010";
	constant CHAR_a2		   :	MyCharacter	:=	"00000011";
	constant CHAR_a3		   :	MyCharacter	:=	"00000100";
	constant CHAR_a4		   :	MyCharacter	:=	"00000101";
	constant CHAR_a5		   :	MyCharacter	:=	"00000110";
	constant CHAR_b0		   :	MyCharacter	:=	"00000111";
	constant CHAR_b1		   :	MyCharacter	:=	"00001000";
	constant CHAR_b2		   :	MyCharacter	:=	"00001001";
	constant CHAR_b3		   :	MyCharacter	:=	"00001010";
	constant CHAR_b4		   :	MyCharacter	:=	"00001011";
	constant CHAR_b5		   :	MyCharacter	:=	"00001100";
	constant CHAR_b6		   :	MyCharacter	:=	"00001101";
	constant CHAR_b7		   :	MyCharacter	:=	"00001110";
	constant CHAR_b8		   :	MyCharacter	:=	"00001111";
	constant CHAR_b9		   :	MyCharacter	:=	"00010000";
	constant CHAR_ba		   :	MyCharacter	:=	"00010001";
	constant CHAR_bb		   :	MyCharacter	:=	"00010010";
	constant CHAR_bc		   :	MyCharacter	:=	"00010011";
	constant CHAR_c0		   :	MyCharacter	:=	"00010100";
	constant CHAR_c1		   :	MyCharacter	:=	"00010101";
	constant CHAR_c2		   :	MyCharacter	:=	"00010110";
	constant CHAR_c3		   :	MyCharacter	:=	"00010111";
	constant CHAR_c4		   :	MyCharacter	:=	"00011000";
	constant CHAR_c5		   :	MyCharacter	:=	"00011001";
	constant CHAR_d0		   :	MyCharacter	:=	"00011010";
	constant CHAR_d1		   :	MyCharacter	:=	"00011011";
	constant CHAR_d2		   :	MyCharacter	:=	"00011100";
	constant CHAR_d3		   :	MyCharacter	:=	"00011101";
	constant CHAR_d4		   :	MyCharacter	:=	"00011110";
	constant CHAR_d5		   :	MyCharacter	:=	"00011111";
	constant CHAR_d6		   :	MyCharacter	:=	"00100000";		--32
	
	constant CHAR_e0		   :	MyCharacter	:=	"00100001";
	constant CHAR_f0		   :	MyCharacter	:=	x"22";
	constant CHAR_f1		   :	MyCharacter	:=	x"23";
	constant CHAR_f2		   :	MyCharacter	:=	x"24";
	constant CHAR_f3		   :	MyCharacter	:=	x"25";
	constant CHAR_f4		   :	MyCharacter	:=	x"26";
	constant CHAR_f5		   :	MyCharacter	:=	x"27";
	constant CHAR_g0		   :	MyCharacter	:=	x"28";
	constant CHAR_g1		   :	MyCharacter	:=	x"29";
	constant CHAR_g2		   :	MyCharacter	:=	x"2a";
	constant CHAR_g3		   :	MyCharacter	:=	x"2b";
	constant CHAR_g4		   :	MyCharacter	:=	x"2c";
	constant CHAR_g5		   :	MyCharacter	:=	x"2d";
	constant CHAR_g6		   :	MyCharacter	:=	x"2e";
	constant CHAR_h0		   :	MyCharacter	:=	x"2f";
	constant CHAR_h1		   :	MyCharacter	:=	x"30";
	constant CHAR_h2		   :	MyCharacter	:=	x"31";
	constant CHAR_h3		   :	MyCharacter	:=	x"32";
	constant CHAR_h4		   :	MyCharacter	:=	x"33";
	constant CHAR_h5		   :	MyCharacter	:=	x"34";
	constant CHAR_h6		   :	MyCharacter	:=	x"35";
	constant CHAR_h7		   :	MyCharacter	:=	x"36";
	--constant CHAR_h8		   :	MyCharacter	:=	x"37";	----num_2
	constant CHAR_j0		   :	MyCharacter	:=	x"38";
	constant CHAR_j1		   :	MyCharacter	:=	x"39";
	constant CHAR_j2		   :	MyCharacter	:=	x"3a";
	constant CHAR_k0		   :	MyCharacter	:=	x"3b";
	constant CHAR_k1		   :	MyCharacter	:=	x"3c";
	constant CHAR_k2		   :	MyCharacter	:=	x"3d";
	constant CHAR_k3		   :	MyCharacter	:=	x"3e";
	--constant CHAR_k4		   :	MyCharacter	:=	x"3f";	-----com
	constant CHAR_l0		   :	MyCharacter	:=	x"40";
	constant CHAR_l1		   :	MyCharacter	:=	x"41";
	constant CHAR_l2		   :	MyCharacter	:=	x"42";
	constant CHAR_l3		   :	MyCharacter	:=	x"43";
	constant CHAR_m0		   :	MyCharacter	:=	x"44";
	constant CHAR_m1		   :	MyCharacter	:=	x"45";
	constant CHAR_m2		   :	MyCharacter	:=	x"46";
	constant CHAR_n0		   :	MyCharacter	:=	x"47";
	constant CHAR_n1		   :	MyCharacter	:=	x"48";
	constant CHAR_n2		   :	MyCharacter	:=	x"49";
	constant CHAR_n3		   :	MyCharacter	:=	x"4a";
	constant CHAR_o0		   :	MyCharacter	:=	x"4b";
	constant CHAR_p0		   :	MyCharacter	:=	x"4c";
	constant CHAR_p1		   :	MyCharacter	:=	x"4d";
	constant CHAR_q0		   :	MyCharacter	:=	x"4e";
	constant CHAR_q1		   :	MyCharacter	:=	x"4f";
	constant CHAR_q2		   :	MyCharacter	:=	x"50";
	constant CHAR_q3		   :	MyCharacter	:=	x"51";
	constant CHAR_q4		   :	MyCharacter	:=	x"52";
	constant CHAR_q5		   :	MyCharacter	:=	x"53";
	constant CHAR_r0		   :	MyCharacter	:=	x"54";
	constant CHAR_r1		   :	MyCharacter	:=	x"55";
	constant CHAR_r2		   :	MyCharacter	:=	x"56";
	constant CHAR_s0		   :	MyCharacter	:=	x"57";
	constant CHAR_s1		   :	MyCharacter	:=	x"58";
	constant CHAR_s2		   :	MyCharacter	:=	x"59";
	constant CHAR_s3		   :	MyCharacter	:=	x"5a";
	constant CHAR_s4		   :	MyCharacter	:=	x"5b";
	constant CHAR_s5		   :	MyCharacter	:=	x"5c";
	constant CHAR_t0		   :	MyCharacter	:=	x"5d";
	constant CHAR_t1		   :	MyCharacter	:=	x"5e";
	constant CHAR_t2		   :	MyCharacter	:=	x"5f";
	constant CHAR_t3		   :	MyCharacter	:=	x"60";
	constant CHAR_w0		   :	MyCharacter	:=	x"61";
	constant CHAR_w1		   :	MyCharacter	:=	x"62";
	constant CHAR_w2		   :	MyCharacter	:=	x"63";
	constant CHAR_x0		   :	MyCharacter	:=	x"64";
	constant CHAR_x1		   :	MyCharacter	:=	x"65";
	constant CHAR_x2		   :	MyCharacter	:=	x"66";
	constant CHAR_y0		   :	MyCharacter	:=	x"67";
	constant CHAR_y1		   :	MyCharacter	:=	x"68";
	constant CHAR_y2		   :	MyCharacter	:=	x"69";
	constant CHAR_y3		   :	MyCharacter	:=	x"6a";
	constant CHAR_z0		   :	MyCharacter	:=	x"6b";
	constant CHAR_z1		   :	MyCharacter	:=	x"6c";
	constant CHAR_z2		   :	MyCharacter	:=	x"6d";
	constant CHAR_z3		   :	MyCharacter	:=	x"6e";----------110

	
	
	type	ColorElement	is	(Red, Green, Blue);
	subtype	Coordinate		is	std_logic_vector(9 downto 0);
	subtype TxtCoordinateX	is	std_logic_vector(5 downto 0);
	subtype TxtCoordinateY	is	std_logic_vector(3 downto 0);
	type	RGBColor		is	array (ColorElement range Red to Blue) of std_logic;
	
	type	ColorLayer	is record
		color		:	RGBColor;
		transparent	:	std_logic;
	end record;
	
	type	ColorLayers		is	array (Natural range<>) of ColorLayer;
	
	
	type	TextWithColor	is record
		txt	:	MyString_40d; 			
		--color	:	RGBColor;
		isMine	:	std_logic;
	end record;
	
	
	type	StandardWindow	is	array(0 to 10) of TextWithColor;

	
	constant COLOR_BLACK	:	RGBColor	:=	"000";
	constant COLOR_BLUE		:	RGBColor	:=	"001";
	constant COLOR_GREEN	:	RGBColor	:=	"010";
	constant COLOR_CYAN		:	RGBColor	:=	"011";
	constant COLOR_RED		:	RGBColor	:=	"100";
	constant COLOR_PURPLE	:	RGBColor	:=	"101";
	constant COLOR_YELLOW	:	RGBColor	:=	"110";
	constant COLOR_WHITE	:	RGBColor	:=	"111";

	
	function equal(x : MyCharacter; y : MyCharacter) return boolean;

-------------------------------------------------------------------------------------
end package;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
package body GlobalDefines is
-------------------------------------------------------------------------------------
	function equal(x : MyCharacter; y : MyCharacter) return boolean is
	begin
		return x(0) = y(0) and x(1) = y(1) and x(2) = y(2) and x(3) = y(3) and 
			x(4) = y(4) and x(5) = y(5) and x(6) = y(6) and x(7) = y(7);
	end function;
-------------------------------------------------------------------------------------
end GlobalDefines;
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------