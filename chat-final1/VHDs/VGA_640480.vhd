library	ieee;
use		ieee.std_logic_1164.all;
use		ieee.std_logic_unsigned.all;
use		ieee.std_logic_arith.all;
use     ieee.numeric_std.all;
------------------------------------------
use work.GlobalDefines.all;

entity vga640480 is
	 port(
			address		:		    out	STD_LOGIC_VECTOR(13 DOWNTO 0);
			reset       :         in  STD_LOGIC;
			clk25       :		  	 out STD_LOGIC; 
			clk_0       :         in  STD_LOGIC; --100M????
			hs,vs       :         out STD_LOGIC; --?????????
			r, g, b     :         out std_logic_vector(2 downto 0);
			rgb         :         in  std_logic_vector(0 downto 0);
			--input_clk   :         in  std_logic;
			--pic       :         inout  std_logic_vector(2 downto 0);  --choose flag size(000=>16*32 001=>128*128)
			vga_output  :         in  StandardWindow;
			disp_code   :         out std_logic_vector(7 downto 0);
			disp_flag   :         out std_logic;
			cap_flag    :         in  std_logic
			--rgb_bg    :         in  std_logic_vector(8 downto 0);
			--bg_line   :         out std_logic_vector(4 downto 0)
	  );
end vga640480;

architecture behavior of vga640480 is
	--constant 			
	constant input_width   : integer := 480;
	constant output_width  : integer := 416;        --BUBBLE LENGTH
	constant input_start_x : integer := 80; 			--determined by the pic
	constant input_start_y : integer := 384;			--
	constant input_height  : integer := 160;
	constant output_height : integer := 364;			--
	
	constant char_width    : integer := 16;
	constant char_height   : integer := 32;			--adjuctable
	constant bubble_edge   : integer := 10;			--BUBBLE SIDE
	TYPE o_int_type is array (natural range<>) of integer;
	signal o_height_temp   : integer;
	signal o_end_y         : o_int_type(10 downto 0);
	signal o_start_x       : o_int_type(10 downto 0);
	signal o_end_x         : o_int_type(10 downto 0);
	signal o_start_y       : o_int_type(10 downto 0);      --FOUR CORNERS (INNER)
	signal o_count         : o_int_type(10 downto 0);
	
	signal update_screen   : std_logic;
	
	signal   disp_area	  : integer := 0;--------------------------------------------
	signal   char_count    : integer := 0;
	signal   disp_count    : o_int_type(10 downto 0);
	--signal   bg_line_int   : integer := 0;
	constant rgb_bg        : std_logic_vector(8 downto 0) := "000000000";		---
	
	signal hs1,vs1    : std_logic;				
	signal vector_x : integer;		--X??
	signal vector_y : integer;		--Y??
	signal clk50	:	 std_logic;
	signal clk : std_logic;
	signal address_tmp : integer;
	
	------------------------------------------------------------------------
	component pll100_25 is
	port(
		inclk0		: IN STD_LOGIC  := '0';
		c0		      : OUT STD_LOGIC 
	);
	end component;
	
	-------------------------------------------------------------------------
begin

	process	(vector_x, vector_y)
	begin
		if(vector_x=0 and vector_y=0) then
			update_screen<= '1';
		else
			update_screen <= '0';
		end if;
	end process;
	
	--o_count
	process(vga_output, update_screen)
	begin
		if(rising_edge(update_screen)) then
			for j in 1 to 10 loop
				for i in 0 to 40 loop									----length limit 40
					o_count(j) <= i;
					exit when vga_output(j).txt(i) = CHAR_NULL;
				end loop;
				o_start_y(j) <= output_height - j*(char_height*2+2*bubble_edge) + bubble_edge;			---two lines
				o_end_y(j) <= output_height - (j-1)*(char_height*2+2*bubble_edge) - bubble_edge;
				
				--o_start_x(j) <= input_start_x;
				--o_end_x(j) <= input_start_x + input_width;
			end loop;
		end if;
	end process;
	
	process(vga_output, o_count(1), o_count(2), o_count(3), o_count(4))
	begin
		for j in 1 to 4 loop
				if(vga_output(j).isMine = '1') then
					if((o_count(j)*char_width)>=output_width) then 
						o_start_x(j) <= input_start_x + input_width - output_width;
					else
						o_start_x(j) <= input_start_x + input_width - (o_count(j)*char_width);
					end if;
					o_end_x(j) <= input_start_x + input_width;
				else
					--
					if((o_count(j)*char_width)>=output_width) then
						o_end_x(j) <= input_start_x + output_width;
					else
						o_end_x(j) <= input_start_x + (o_count(j)*char_width);
					end if;
					o_start_x(j) <= input_start_x;
				end if;
		end loop;
	end process;
----------------------------------------------------------------------------
	--clk25 <= clk;
	address <= conv_std_logic_vector(address_tmp,14);	--m: integer to logic_vector;
 -----------------------------------------------------------------------
--  process(clk_0)	--?100M???????
--    begin
--        if clk_0'event and clk_0='1' then 
--             clk50 <= not clk50;
--        end if;
-- 	end process;
-- 	
--  process(clk50)	--?50M???????
--    begin
--        if clk50'event and clk50='1' then 
--             clk <= not clk;
--        end if;
-- 	end process;
	pll_clk : pll100_25 port map(
		inclk0 => clk_0,
		c0 => clk
	);
	pll_clk2 : pll100_25 port map(
		inclk0 => clk_0,
		c0 => clk25
	);
 -----------------------------------------------------------------------
	 process(clk,reset)	--????????????
	 begin
	  	if reset='0' then
	   		vector_x <= 0;
	  	elsif clk'event and clk='1' then
	   		if vector_x=799 then
	    		vector_x <= 0;
	   		else
	    		vector_x <= vector_x + 1;
	   		end if;
	  	end if;
	 end process;

  -----------------------------------------------------------------------
	 process(clk,reset)	--???????????
	 begin
	  	if reset='0' then
	   		vector_y <= 0;
	  	elsif clk'event and clk='1' then
	   		if vector_x=799 then
	    		if vector_y=524 then
	     			vector_y <= 0;
	    		else
	     			vector_y <= vector_y + 1;
	    		end if;
	   		end if;
	  	end if;
	 end process;
 
  -----------------------------------------------------------------------
	 process(clk,reset) --????????????96???16?
	 begin
		  if reset='0' then
		   hs1 <= '1';
		  elsif clk'event and clk='1' then
		   	if vector_x>=656 and vector_x<752 then
		    	hs1 <= '0';
		   	else
		    	hs1 <= '1';
		   	end if;
		  end if;
	 end process;
 
 -----------------------------------------------------------------------
	 process(clk,reset) --????????????2???10?
	 begin
	  	if reset='0' then
	   		vs1 <= '1';
	  	elsif clk'event and clk='1' then
	   		if vector_y>=490 and vector_y<492 then
	    		vs1 <= '0';
	   		else
	    		vs1 <= '1';
	   		end if;
	  	end if;
	 end process;
 -----------------------------------------------------------------------
	 process(clk,reset) --???????
	 begin
	  	if reset='0' then
	   		hs <= '0';
	  	elsif clk'event and clk='1' then
	   		hs <=  hs1;
	  	end if;
	 end process;

 -----------------------------------------------------------------------
	 process(clk,reset) --???????
	 begin
	  	if reset='0' then
	   		vs <= '0';
	  	elsif clk'event and clk='1' then
	   		vs <=  vs1;
	  	end if;
	 end process;
	 
------------------------------------------------------------------------
	process(vga_output, vector_x, vector_y)
	begin
		for i in 0 to 40 loop									----length limit 40
			--
			char_count <= i;
			exit when vga_output(0).txt(i) = CHAR_NULL;
		end loop;
	end process;
 -----------------------------------------------------------------------
--	process(vector_x, vector_y)
--	begin
--		for i in 1 to 10 loop
--			disp_count(i) <= (vector_y - o_start_y(i)) / char_height * (output_width/char_width) + (vector_x-o_start_x(i))/char_width;
--		end loop;
--	end process;
	
	process(reset , clk, vector_x, vector_y, rgb) -- XY LAYOUT
	begin  
		if reset= '0' then 
			address_tmp <= 0;
		elsif clk'event and clk='1' then
			for i in 1 to 2 loop
				if i = 1 then
					r <= "000";
					g <= "000";
					b <= "000";
				else
--------1---------
					if (vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width >= 0 and
						(vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width < o_count(1) 
						and vector_y >= o_start_y(1) and vector_x >= o_start_x(1) and vector_x <= o_end_x(1) and vector_y < o_end_y(1) then
						
						if vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width) = CHINESE_HEAD and
								(vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width+1<o_count(1) AND
								vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width+1)/=CHINESE_HEAD	then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(1)) MOD char_width + (vector_y-o_start_y(1)) MOD char_height * char_width*2;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width+1);
									if(rgb = "1") then
										if(vga_output(1).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width > 0)	and
						 vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width-1)=CHINESE_HEAD and
						vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width)/=CHINESE_HEAD	then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(1)) MOD char_width + (vector_y-o_start_y(1)) MOD char_height * char_width*2 + 16;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width);
									if(rgb = "1") then
										if(vga_output(1).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))/=CHINESE_HEAD) then
								disp_flag <= '0';
						
								address_tmp <= (vector_x-o_start_x(1)) MOD char_width + (vector_y-o_start_y(1)) MOD char_height * char_width;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(1).txt((vector_y - o_start_y(1)) / char_height * (output_width/char_width) + (vector_x-o_start_x(1))/char_width);
									if(rgb = "1") then
										if(vga_output(1).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						end if;
					end if;
--------2---------
					if (vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width >= 0 and
						(vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width < o_count(2) 
						and vector_y >= o_start_y(2) and vector_x >= o_start_x(2) and vector_x <= o_end_x(2) and vector_y < o_end_y(2) then
						
						if vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width) = CHINESE_HEAD and 
								(vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width+1<o_count(2) and 
								vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width+1)/=CHINESE_HEAD	then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(2)) MOD char_width + (vector_y-o_start_y(2)) MOD char_height * char_width*2;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width+1);
									if(rgb = "1") then
										if(vga_output(2).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width > 0)	and
						 vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width-1)=CHINESE_HEAD and
						vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width)/=CHINESE_HEAD	then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(2)) MOD char_width + (vector_y-o_start_y(2)) MOD char_height * char_width*2 + 16;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width);
									if(rgb = "1") then
										if(vga_output(2).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))/=CHINESE_HEAD) then
								disp_flag <= '0';
						
								address_tmp <= (vector_x-o_start_x(2)) MOD char_width + (vector_y-o_start_y(2)) MOD char_height * char_width;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(2).txt((vector_y - o_start_y(2)) / char_height * (output_width/char_width) + (vector_x-o_start_x(2))/char_width);
									if(rgb = "1") then
										if(vga_output(2).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						end if;
					end if;
-------3--------				
					if (vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width >= 0 and
						(vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width < o_count(3) 
						and vector_y >= o_start_y(3) and vector_x >= o_start_x(3) and vector_x <= o_end_x(3) and vector_y < o_end_y(3) then
						
						if vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width) = CHINESE_HEAD and
								(vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width+1<o_count(3) and
								vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width+1)/=CHINESE_HEAD	then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(3)) MOD char_width + (vector_y-o_start_y(3)) MOD char_height * char_width*2;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width+1);
									if(rgb = "1") then
										if(vga_output(3).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width > 0)	and
						 vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width-1)=CHINESE_HEAD AND
						 vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width)/=CHINESE_HEAD then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(3)) MOD char_width + (vector_y-o_start_y(3)) MOD char_height * char_width*2 + 16;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width);
									if(rgb = "1") then
										if(vga_output(3).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))/=CHINESE_HEAD) then
								disp_flag <= '0';
						
								address_tmp <= (vector_x-o_start_x(3)) MOD char_width + (vector_y-o_start_y(3)) MOD char_height * char_width;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(3).txt((vector_y - o_start_y(3)) / char_height * (output_width/char_width) + (vector_x-o_start_x(3))/char_width);
									if(rgb = "1") then
										if(vga_output(3).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						end if;
					end if;
			---4---
					if (vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width >= 0 and
						(vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width < o_count(4) 
						and vector_y >= o_start_y(4) and vector_x >= o_start_x(4) and vector_x <= o_end_x(4) and vector_y < o_end_y(4) then
						 
						if vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width) = CHINESE_HEAD and
								(vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width +1 < o_count(4) AND 
								vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width+1)/=CHINESE_HEAD	then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(4)) MOD char_width + (vector_y-o_start_y(4)) MOD char_height * char_width*2;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width+1);
									if(rgb = "1") then
										if(vga_output(4).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width > 0)	and
							vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width-1)=CHINESE_HEAD and
							vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width)/=CHINESE_HEAD then
								disp_flag <= '1';
						
								address_tmp <= (vector_x-o_start_x(4)) MOD char_width + (vector_y-o_start_y(4)) MOD char_height * char_width*2 + 16;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width);
									if(rgb = "1") then
										if(vga_output(4).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						elsif(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))/=CHINESE_HEAD) then
								disp_flag <= '0';
						
								address_tmp <= (vector_x-o_start_x(4)) MOD char_width + (vector_y-o_start_y(4)) MOD char_height * char_width;
								
								--disp_count <= ((vector_x - o_start_x(1)) / 16 + (vector_y - o_start_y(1)) / 32 * (output_width/16))MOD o_count(1);
								disp_code  <= vga_output(4).txt((vector_y - o_start_y(4)) / char_height * (output_width/char_width) + (vector_x-o_start_x(4))/char_width);
									if(rgb = "1") then
										if(vga_output(4).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
										else
											r <= "111";
											g <= "111";
											b <= "000";
										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
						end if;
					end if;
		---input-----
					if (vector_y - input_start_y)  * (input_width) + char_height *(vector_x-1-input_start_x) >= 0 and
						(vector_y - input_start_y) / char_height * (input_width/char_width) + (vector_x-1-input_start_x)/char_width < char_count 
						and vector_y >= input_start_y --and not((vector_y-input_start_y) MOD char_height = 1)
						and vector_x >= input_start_x 
						--and vector_y < input_start_y + input_width 
						and vector_x <= input_start_x + input_width then
						--integer div????????????!!!!!!!!!!!!!------------------------------------?//////////////////////////
							
							if(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))=CHINESE_HEAD) and
							(vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16)+1 < char_count  and
							(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16)+1)/=CHINESE_HEAD) then
								disp_flag <= '1';
								address_tmp <= (vector_x-input_start_x) MOD 16 + (vector_y-input_start_y) MOD 32 * 32;
								
								--disp_count <= (vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16);
								disp_code  <= vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16)+1);
									if(rgb = "1") then
										--if(vga_output(0).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
--										else
--											r <= "111";
--											g <= "111";
--											b <= "000";
--										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
							elsif(((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))>0) and
							(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16)-1)=CHINESE_HEAD) and 
							(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))/=CHINESE_HEAD)then
								disp_flag <= '1';
								address_tmp <= (vector_x-input_start_x) MOD 16 + (vector_y-input_start_y) MOD 32 * 32 + 16;
								
								--disp_count <= (vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16);
								disp_code  <= vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16));
									if(rgb = "1") then
										--if(vga_output(0).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
--										else
--											r <= "111";
--											g <= "111";
--											b <= "000";
--										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
							elsif(vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16))/=CHINESE_HEAD) then
								address_tmp <= (vector_x-input_start_x) MOD 16 + (vector_y-input_start_y) MOD 32 * 16;
								disp_flag <= '0';
								--disp_count <= (vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16);
								disp_code  <= vga_output(0).txt((vector_x - input_start_x) / 16 + (vector_y - input_start_y) / 32 * (input_width/16));
									if(rgb = "1") then
										--if(vga_output(0).isMine = '1') then
											r <= "111";
											g <= "000";
											b <= "111";
--										else
--											r <= "111";
--											g <= "111";
--											b <= "000";
--										end if;
									else
										r <= "000";
										g <= "000";
										b <= "000";
									end if;
							end if;
					end if;
------------others------------
					if ((vector_y = input_start_y - bubble_edge or vector_y = input_start_y + char_height*2 + bubble_edge) and 
						vector_x >= input_start_x and vector_x < input_start_x + input_width ) or
						((vector_x = input_start_x - bubble_edge or vector_x = input_start_x + input_width + bubble_edge) and 
						vector_y >= input_start_y and vector_y < input_start_y + char_height*2 )
						then
						--color orange
						r <= "111";
						g <= "011";
						b <= "001";
					end if;
------------------------					
					if ((vector_y = o_start_y(4) - bubble_edge or vector_y = o_start_y(1) + char_height*2 + bubble_edge) and 
						vector_x >= input_start_x and vector_x < input_start_x + input_width ) or
						((vector_x = input_start_x - bubble_edge or vector_x = input_start_x + input_width + bubble_edge) and 
						vector_y >= o_start_y(4) and vector_y < o_start_y(1) + char_height*2 )
						then
						--color orange
						r <= "111";
						g <= "011";
						b <= "001";
					end if;
					--line
--					elsif (vector_y-input_start_y) MOD char_height = 1 and vector_y>input_start_y and vector_y<=input_start_y + char_height*2 +1
--						and vector_x >= input_start_x and vector_x < input_start_x + input_width then
--						--color gray
--						r <= "011";
--						g <= "011";
--						b <= "011";
					
--					elsif (vector_y-o_start_y(1)) MOD char_height = 0 and vector_y>o_start_y(1) and vector_y<=o_end_y(1) 
--						and vector_x >= o_start_x(1) and vector_x < o_end_x(1) then
--						--color ?
--						r <= "000";
--						g <= "111";
--						b <= "111";
--					elsif (vector_y-o_start_y(2)) MOD char_height = 0 and vector_y>o_start_y(2) and vector_y<=o_end_y(2) 
--						and vector_x >= o_start_x(2) and vector_x < o_end_x(2) then
--						--color ?
--						r <= "000";
--						g <= "111";
--						b <= "111";
--					elsif (vector_y-o_start_y(3)) MOD char_height = 0 and vector_y>o_start_y(3) and vector_y<=o_end_y(3) 
--						and vector_x >= o_start_x(3) and vector_x < o_end_x(3) then
--						--color ?
--						r <= "000";
--						g <= "111";
--						b <= "111";
--					elsif (vector_y-o_start_y(4)) MOD char_height = 0 and vector_y>o_start_y(4) and vector_y<=o_end_y(4) 
--						and vector_x >= o_start_x(4) and vector_x < o_end_x(4) then
--						--color ?
--						r <= "000";
--						g <= "111";
--						b <= "111";
					
					--background
--					if vector_x >= 0 and vector_x < 640 and vector_y >= 0 and vector_y < 480 then
--							
--							--address_tmp <= vector_x MOD 128 + vector_y MOD 128 * 128;
--								
--							--macth output (low);
--							r(0) <= rgb_bg(6);
--							r(1) <= rgb_bg(7);
--							r(2) <= rgb_bg(8);
--							g(0) <= rgb_bg(3);
--							g(1) <= rgb_bg(4);
--							g(2) <= rgb_bg(5);
--							b(0) <= rgb_bg(0);
--							b(1) <= rgb_bg(1);
--							b(2) <= rgb_bg(2);
--					end if;
					if(cap_flag='1' and (vector_x-40)+(vector_y-404)<10 and (vector_x-40)+(vector_y-404)>-10
						and (vector_x-40)-(vector_y-404)<10 and (vector_x-40)-(vector_y-404)>-10) then
						r <= "111";
						g <= "111";
						b <= "111";
					end if;
				end if;
			end loop;
		end if;		 
	end process;	

							
	-----------------------------------------------------------------------
	

end behavior;

