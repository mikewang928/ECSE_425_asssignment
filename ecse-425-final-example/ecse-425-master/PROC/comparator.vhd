library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memory_arbiter_lib.all;

entity comparator is
  port (
	value1 : in std_logic_vector(MEM_DATA_WIDTH-1 downto 0) ;
	value2 : in std_logic_vector(MEM_DATA_WIDTH-1 downto 0) ;	
	ctl	   : in std_logic_vector(1 downto 0) ;
	taken  : out std_logic
  ) ;
end entity ; -- comparator

architecture arch of comparator is
begin
  
comp : process( value1, value2, ctl )
begin
	if ctl = "11" then
		taken <= '1';
	elsif ctl = "01" then
		-- beq
		if value1 = value2 then
			taken <= '1';
		else 
			taken <= '0';
		end if ;
	elsif ctl = "10" then
		if value1 = value2 then
			taken <= '0';
		else 
			taken <= '1';
		end if ;
	else
		taken <= '0';
	end if ;
end process ; -- comp




end architecture ; -- arch