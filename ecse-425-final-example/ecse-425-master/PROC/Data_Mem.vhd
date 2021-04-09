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

use work.memory_constants.all;

entity Data_Memory is
  port (
    clk : in std_logic;
    n_rst : in std_logic; -- Active low reset signal
    write_enable : in std_logic;  -- Write control signal
    write_in : in std_logic_vector(31 downto 0);  -- Input data port
    write_adr: in std_logic_vector(31 downto 0);-- address write
    port_adr : in std_logic_vector(31 downto 0); -- Port read address
    byte : in std_logic; -- when '1' you are interacting with the memory in word otherwise in byte
    port_out : out std_logic_vector(31 downto 0)  -- Read port
    );
  end entity ;

  architecture behavior of Data_Memory is
    signal output_temp : std_logic_vector(31 downto 0);

    subtype byte_t is std_logic_vector(7 DOWNTO 0); -- Byte typedef
    type mem_t is ARRAY(0 TO dm_depth*4-1) OF byte_t; -- Data memory array
    SIGNAL mem_signal : mem_t; -- Initialize register
    begin
      mem_process : process(clk, n_rst)
      begin
      if n_rst = '0' then
        for i in 0 to dm_depth*4-1 loop
          mem_signal(i) <= (OTHERS => '0'); --  Reset all content
        end loop;
      elsif rising_edge(clk) then
        if write_enable = '1' then
          if byte = '0' then
            mem_signal(to_integer(unsigned(write_adr))) <= write_in(7 downto 0);  -- Write in data
          else
            mem_signal(4*to_integer(unsigned(write_adr))) <= write_in(7 downto 0);  -- Write in data
            mem_signal(4*to_integer(unsigned(write_adr)) + 1) <= write_in(15 downto 8);  -- Write in data
            mem_signal(4*to_integer(unsigned(write_adr)) + 2) <= write_in(23 downto 16);  -- Write in data
            mem_signal(4*to_integer(unsigned(write_adr)) + 3) <= write_in(31 downto 24);  -- Write in data
        end if;
      end if;
    end if;
    end process;

    --Sign extension
    output_temp <= std_logic_vector(resize(signed(mem_signal(to_integer(unsigned(port_adr)))), output_temp'length)) when byte = '0';

    port_out(7 downto 0) <= output_temp(7 downto 0) when byte = '0'
    else mem_signal(4*to_integer(unsigned(port_adr))) when byte = '1';

    port_out(15 downto 8) <= output_temp(15 downto 8) when byte = '0'
    else mem_signal(4*to_integer(unsigned(port_adr)) + 1) when byte = '1';

    port_out(23 downto 16) <= output_temp(23 downto 16) when byte = '0'
    else mem_signal(4*to_integer(unsigned(port_adr)) + 2) when byte = '1';

    port_out(31 downto 24) <= output_temp(31 downto 24) when byte = '0'
    else mem_signal(4*to_integer(unsigned(port_adr)) + 3) when byte = '1';

  end architecture ;
