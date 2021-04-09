-- Testbench for  gate
library IEEE;
use IEEE.std_logic_1164.all;
 
entity testbench is
-- empty
end testbench; 

architecture tb of testbench is

-- DUT component
component EX is
port(
RSD  : in  STD_LOGIC_VECTOR (31 downto 0);
RTD   : in  STD_LOGIC_VECTOR (31 downto 0);
IMM   : in  STD_LOGIC_VECTOR (31 downto 0);


RDD   : out  STD_LOGIC_VECTOR (31 downto 0);
RDAI    : in STD_LOGIC_VECTOR (4 downto 0);
RDAO    : out STD_LOGIC_VECTOR (4 downto 0);

FCode: in std_logic_vector(3 downto 0);


PCEI: in std_logic_vector( 31 downto 0);
PCEO: out std_logic_vector(31 downto 0);

clock   : in  STD_LOGIC;

D1Sel1  : in  STD_LOGIC;
D1Sel0   : in  STD_LOGIC;

D2Sel0   : in  STD_LOGIC;
D2Sel1 : in  STD_LOGIC;

BE: in std_logic_vector(1 downto 0);
BT: out std_logic;

MAWI: in std_logic;
MARI: in std_logic;

MAWO: out std_logic;
MARO: out std_logic;

RA: out std_logic;


ZERO: out std_logic

);
end component;

signal aRSD  : STD_LOGIC_VECTOR (31 downto 0);
signal aRTD   : STD_LOGIC_VECTOR (31 downto 0);
signal aIMM   : STD_LOGIC_VECTOR (31 downto 0);


signal aRDD   :  STD_LOGIC_VECTOR (31 downto 0);
signal aRDAI    :  STD_LOGIC_VECTOR (4 downto 0);
signal aRDAO    :  STD_LOGIC_VECTOR (4 downto 0);

signal aFCode:  std_logic_vector(3 downto 0);


signal aPCEI:  std_logic_vector( 31 downto 0);
signal aPCEO:  std_logic_vector(31 downto 0);

signal aclock   :  STD_LOGIC;
signal sclock   :  STD_LOGIC;

signal aD1Sel1  : STD_LOGIC;
signal aD1Sel0   :   STD_LOGIC;

signal aD2Sel0   :  STD_LOGIC;
signal aD2Sel1 :  STD_LOGIC;

signal aBE:  std_logic_vector(1 downto 0);
signal aBT: std_logic;


signal aMAWI: std_logic;
signal aMARI: std_logic;

signal aMAWO:  std_logic;
signal aMARO: std_logic;

signal aRA: std_logic;


signal aZERO:  std_logic;


CONSTANT clk_period : time := 1 ns;

begin

  -- Connect DUT
  DUT: EX port map(aRSD, aRTD, aIMM, aRDD, aRDAI, aRDAO, aFCode, aPCEI, aPCEO, aclock, aD1Sel1, aD1Sel0, aD2Sel0, aD2Sel1, aBE, aBT, aMAWI,aMARI,aMAWO,aMARO, aZERO);


  clk_process : PROCESS
BEGIN
  aclock <= '1';
  sclock <= '1';
  WAIT FOR clk_period/2;
  aclock <= '0';
  sclock <= '0';
  WAIT FOR clk_period/2;
END PROCESS;

  process
  begin
    
    aRSD <= (others => '0');
    aRTD <= (others => '0');
    aIMM <= (others => '0');

    aRDAI <= (others => '0');
    aFCode <= (others => '0');

    aPCEI <= (others => '0');

    

    aD2Sel1 <= '0';
    aD2Sel0 <= '0';

    aD1Sel1 <= '0';
    aD1Sel0 <= '0';

    aBE <= (others => '0');
    aMARI<='0';
    aMARO<='0';



   
    wait for 2.5 ns;
   
      -- SIMPLE ADD OPERATION DEFAULT MUX SELECTOR 
   aRSD <= "00000000000000000000000000000000";
    aRTD <= "00000000000000000000000000000000";
    aIMM <= "00000000000000000000000010001010";

    
    aRDAI <= "00010";
    

    aFCode <= ("0000");

   
    aPCEI <= (others => '0');


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '0';

    
    aBE <= (others => '0');

   
   
    wait for 1 ns;


         -- SIMPLE ADD OPERATION IMM D2 MUX SELECTOR 
   aRSD <= "00000000000000000000000000111000";
    aRTD <= "00000000000000100000001000111000";
    aIMM <= "00000000000000101001001000111001";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= (others => '0');


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '0';

    
    aBE <= (others => '0');

   
   
    wait for 1 ns;

         -- SIMPLE ADD OPERATION IMM D2 and PCEI D1 MUX SELECTOR 
   aRSD <= "00000000000000000000000000111000";
    aRTD <= "00000000000000100000001000111000";
    aIMM <= "00000000000000101001001000111000";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= "00000000000000110101001100111010";


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '1';

    
    aBE <= (others => '0');

   
   
    wait for 1 ns;


             -- BNE (Taken)
    aRSD <= "00000000000000000000000000111000";
    aRTD <= "00000000000000000000010000111000";
    aIMM <= "00000000000000101001001000111000";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= "00000000000000110101001100111010";


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '1';

    
    aBE <= "10";

   
   
    wait for 1 ns;

             --BNE ( Not Taken)
    aRSD <= "00000000000000100000001000111000";
    aRTD <= "00000000000000100000001000111000";
    aIMM <= "00000000000000101001001000111000";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= "00000000000000110101001100111010";


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '0';

    
    aBE <= "10";

   
   
    wait for 1 ns;

             -- BE (Taken)
    aRSD <= "00000000000000000000000000111000";
    aRTD <= "00000000000000000000000000111000";
    aIMM <= "00000000000000101001001000111000";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= "00000000000000110101001100111010";


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '1';

    
    aBE <= "01";

   
   
    wait for 1 ns;

             -- BE ( Not Taken)
    aRSD <= "00000000000000000000000000111000";
    aRTD <= "00000000000000100000001000111000";
    aIMM <= "00000000000000101001001000111000";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= "00000000000000110101001100111010";


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '1';

    
    aBE <= "01";

   
   
    wait for 1 ns;

                 -- JUMP
    aRSD <= "00000000000000000000000000111000";
    aRTD <= "00000000000000100000001000111000";
    aIMM <= "00000000000000101001001000111000";

    
    aRDAI <= (others => '0');
    

    aFCode <= ("0000");

   
    aPCEI <= "00000000000000110101001100111010";


    aD2Sel1 <= '0';
    aD2Sel0 <= '1';

    aD1Sel1 <= '0';
    aD1Sel0 <= '1';

    
    aBE <= "11";

   
   
    wait for 1 ns;

    aRSD <= (others => '0');
    aRTD <= (others => '0');
    aIMM <= (others => '0');

    aRDAI <= (others => '0');
    aFCode <= (others => '0');

    aPCEI <= (others => '0');



    aD2Sel1 <= '0';
    aD2Sel0 <= '0';

    aD1Sel1 <= '0';
    aD1Sel0 <= '0';

    aBE <= (others => '0');

    

    

      -- Clear inputs
   
    

    wait;
  end process;
end tb;
