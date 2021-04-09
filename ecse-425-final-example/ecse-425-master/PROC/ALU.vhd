library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity ALU is 
port ( 
clock: in std_logic;
RS,RT: in std_logic_vector(31 downto 0);
FC: in std_logic_vector(3 downto 0);
RES: out std_logic_vector(31 downto 0) ;
ZERO: out std_logic
) ;

constant empty: std_logic_vector(31 downto 0) := (others => '0');
end entity ALU;

architecture arch of ALU is 
Signal c: std_logic_vector (31 downto 0);
Signal hi,lo : std_logic_vector(31 downto 0);
Signal ZT: std_logic;


begin 


Bob : process(RS,RT,FC) 
Variable long : std_logic_vector(63 downto 0);
begin  



ZT<='0';
c <= empty;

case FC is

when "0000" => --add
c <= std_logic_vector(signed(RS) + signed(RT));

when "0001" => --and
c <= RS AND RT;

when "0010" => --div
lo<= std_logic_vector( signed(RS)/signed(RT));
hi<= std_logic_vector( signed(RS) rem signed(RT));

when "0011" => --equals
if (RS=RT) then
ZT <= '1';
else
ZT <= '0';
end if;


when "0100" => --lui
c <= std_logic_vector(SHIFT_LEFT(signed(RS), 16)) ;

when "0101" => --mfhi
c <= hi;

when "0110" => --mflo
c <= lo;

when "0111" => --mult
long := std_logic_vector(signed(RS) * signed(RT));
hi <= long(63 downto 32);
lo <= long(31 downto 0);

when "1000" => --nor
c <= RS nor RT;

when "1001" => --or
c <= RS or RT;

when "1010" => --sll
c <= To_StdLogicVector(to_bitvector(RS) sll to_integer(signed(RT)));

when "1011" => --slt
if (signed(RS) < signed(RT)) then
c <= std_logic_vector(1 + signed(empty));
else
c <= empty;
end if;

when "1100" => --sra
c <= To_StdLogicVector(to_bitvector(RS) sra to_integer(signed(RT)));

when "1101" => --srl
c <= To_StdLogicVector(to_bitvector(RS) srl to_integer(signed(RT)));

when "1110" => --sub
c <= std_logic_vector( signed(RS) - signed(RT));

when "1111" => --xor
c <= RS xor RT;

when others =>
ZT<='0';
c <= empty;

end case;



end process; -- Bob

ZERO <= ZT;
RES <= c;



end architecture ; -- arch