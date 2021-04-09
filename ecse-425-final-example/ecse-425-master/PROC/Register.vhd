library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

--  This entity defines a register block with storage capacity of 32*reg_depth bits
--  Data is thus organized as a 2D array :
--  | reg address | value (32 bit wide) |
--  |     0       |       word_0        |
--  |     4       |       word_1        |
--  |     .       |         .           |
--  |     .       |         .           |
--  |     .       |         .           |
--  | reg_adrsize |  word_(regdepth-1)  |
--  =====================================
--  TODO: Define reg_adrsize
--        Define reg_depth
--        Figure out addressing and fixed word width or not


use work.memory_arbiter_lib.all;

entity Registers is
  port (
  clk : in std_logic;
  n_rst : in std_logic; -- Active low reset signal
  write_enable : in std_logic;  -- Write control signal
  write_in : in std_logic_vector(31 downto 0);  -- Input data port
  write_adr: in std_logic_vector(reg_adrsize-1 downto 0);-- address write
  port1_adr : in std_logic_vector(reg_adrsize-1 downto 0); -- Port 1 read address
  port2_adr : in std_logic_vector(reg_adrsize-1 downto 0); -- Port 2 read address
  port1_out : out std_logic_vector(31 downto 0);  -- Read port 1
  port2_out : out std_logic_vector(31 downto 0)  -- Read port 2
    ) ;
  end entity ;

  architecture behavior of Registers is
    subtype word_t is std_logic_vector(31 DOWNTO 0); -- Register word TYPE  TODO: Consider removing since fixed width
    type register_t is ARRAY(0 TO reg_depth-1) OF word_t; -- Register array TYPE
    SIGNAL register_signal : register_t; -- Initialize register
    begin
      register_process : process(clk, n_rst)
      begin
      if n_rst = '0' then
        for i in 0 to reg_depth-1 loop
          register_signal(i) <= (OTHERS => '0'); --  Reset all content
        end loop;
      elsif rising_edge(clk) then
        if write_enable = '1' then
          if to_integer(unsigned(write_adr)) /= 0 then  -- Write protection for register 0
            register_signal(to_integer(unsigned(write_adr))) <= write_in;  -- Write in data
          end if;
        end if;
      end if;
    end process ;
    port1_out <= register_signal(to_integer(unsigned(port1_adr)));
    port2_out <= register_signal(to_integer(unsigned(port2_adr)));
  end architecture ;
