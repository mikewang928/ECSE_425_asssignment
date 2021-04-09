-- ECSE 425 - Assignment 2
-- Ali Tapan - 260556540

library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipeline is
port (clk : in std_logic;
      a, b, c, d, e : in integer;
      op1, op2, op3, op4, op5, final_output : out integer
  );
end pipeline;


architecture behavioral of pipeline is

-- The operation ((a + b) * 42) - (c * d * (a-e)) will be completed in 2 clock cycles with pipelining.
-- To store the asynchronous parts we have the following:
signal register_1, register_2, register_3, register_4, register_5: integer;
-- To store the synchronous parts (at every clock cycle) we have the following:
signal s_register_1, s_register_2, s_register_3, s_register_4, s_register_5: integer;

begin
process (clk)
begin
    -- At every clock cycle update the registers
    if (clk'event and clk = '1') then
        s_register_1 <= register_1;
        s_register_2 <= register_2;
        s_register_3 <= register_3;
        s_register_4 <= register_4;
        s_register_5 <= register_5;
    end if;
end process;

-- Perform asynchronous operations for pipelining
register_1 <= a + b;
register_2 <= s_register_1 * 42;
register_3 <= c * d;
register_4 <= a - e;
register_5 <= s_register_4 * s_register_3;
final_output <= s_register_2 - s_register_5;

-- Update the outputs for the next clock cycle
op1 <= s_register_1;
op2 <= s_register_2;
op3 <= s_register_3;
op4 <= s_register_4;
op5 <= s_register_5;

end behavioral;
