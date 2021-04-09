library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity shifter is
  generic(
  	INPUT_WIDTH : integer := 32
  );
  port (
	input_vector : in std_logic_vector(INPUT_WIDTH-1 downto 0) ;
	output_vector : out std_logic_vector(INPUT_WIDTH-1 downto 0);
	shamt : in integer
  ) ;
end entity ; -- shifter


architecture arch of shifter is
begin
output_vector <= To_StdLogicVector(to_bitvector(input_vector) sll shamt);
end architecture ; -- arch