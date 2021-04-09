library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux41 is
    Port ( SEL0 : in  STD_LOGIC;
    		SEL1 : in  STD_LOGIC;
           A   : in  STD_LOGIC_VECTOR (31 downto 0);
           B   : in  STD_LOGIC_VECTOR (31 downto 0);
           C   : in  STD_LOGIC_VECTOR (31 downto 0);
           D   : in  STD_LOGIC_VECTOR (31 downto 0);
           X   : out STD_LOGIC_VECTOR (31 downto 0));
end mux41;

architecture arch of mux41 is
  signal ctl : std_logic_vector(1 downto 0) ;
begin
  ctl <= SEL1 & SEL0;
  with ctl select X <= 
    A when "00",
    B when "01",
    C when "10",
    D when "11",
    (others => '0') when others;

end architecture ; -- arch