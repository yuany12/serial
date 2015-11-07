library	ieee;
use		ieee.std_logic_1164.all;
use		ieee.std_logic_unsigned.all;
use		ieee.std_logic_arith.all;
use     ieee.numeric_std.all;
entity bug is
	port
	(
		input		: in std_logic;
		output      : out std_logic_vector(2 downto 0)
	);
end bug;

architecture behavior of bug is
begin
	output <= (others => input);
end behavior;