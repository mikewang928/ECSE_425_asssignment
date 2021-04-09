library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memory_arbiter_lib.all;

entity PROCtestbench is
-- empty
end PROCtestbench; 

architecture tb of PROCtestbench is

component PROC is
port (

clock: in std_logic;
inst : in std_logic_vector (31 downto 0);
we : in std_logic;
writeadd : in std_logic_vector(reg_adrsize-1 downto 0);
writedat : in std_logic_vector(31 downto 0);
resetn : in std_logic;



RDDO   : out  STD_LOGIC_VECTOR (31 downto 0);
RDAO	: out STD_LOGIC_VECTOR (reg_adrsize-1 downto 0);
PCEO: out std_logic_vector(31 downto 0);
BT: out std_logic;

MAWEO: out std_logic;
MAREO: out std_logic;

RAEO: out std_logic;
ZEROEO: out std_logic
);
end component;

signal clock: std_logic;
signal inst : std_logic_vector (31 downto 0);
signal we : std_logic;
signal writeadd : std_logic_vector(reg_adrsize-1 downto 0);
signal writedat :  std_logic_vector(31 downto 0);
signal resetn :  std_logic;



signal RDDO   :   STD_LOGIC_VECTOR (31 downto 0);
signal RDAO	:  STD_LOGIC_VECTOR (reg_adrsize-1 downto 0);
signal PCEO: std_logic_vector(31 downto 0);
signal BT:  std_logic;

signal MAWEO:  std_logic;
signal MAREO:  std_logic;

signal RAEO:  std_logic;
signal ZEROEO:  std_logic;

CONSTANT clk_period : time := 1 ns;

begin 

Processor: PROC port map (clock,inst,we,writeadd,writedat,resetn,RDDO,RDAO,PCEO,BT,MAWEO,MAREO,RAEO,ZEROEO);

  clk_process : PROCESS
BEGIN
  clock <= '1';
  WAIT FOR clk_period/2;
  clock <= '0';
  WAIT FOR clk_period/2;
END PROCESS;

process
begin

inst<=  (others => '0');
we<=  '0';
writeadd<=  (others => '0');
writedat<=  (others => '0');
resetn<=  '0';

wait for 1.5 ns;

inst<=  "00100000100001100000000001110101";
we<=  '0';
writeadd<=  (others => '0');
writedat<=  (others => '0');
resetn<=  '0';

wait for 1 ns;

inst<=  (others => '0');
we<=  '0';
writeadd<=  (others => '0');
writedat<=  (others => '0');
resetn<=  '0';

wait for 1 ns;




end process;
end tb;