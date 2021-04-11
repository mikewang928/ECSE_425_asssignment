library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mux2 is
port(
	 in0 : in std_logic_vector(31 downto 0);
	 in1 : in std_logic_vector(31 downto 0);
	 ctrl : in std_logic;
	 output : out std_logic_vector(31 downto 0)
	 );
	 
end mux2;

architecture rtl of mux2 is

begin

	output <= in0 when (ctrl = '0') else in1 ;
	
end rtl;
