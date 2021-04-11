library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity adder2 is
port(
	 in1 : in std_logic_vector(31 downto 0);
	 in2 : in std_logic_vector(31 downto 0);
	 output : out std_logic_vector(31 downto 0)
	 );
end adder2;

architecture rtl of adder2 is

begin

	output <= std_logic_vector(unsigned(in1) + unsigned(in2));
	
end rtl;