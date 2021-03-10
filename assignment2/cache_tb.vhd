library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

arcTag_Matchecture behavior of cache_tb is

component cache is
	generic(
		 ram_size : INTEGER := 32768
	);
	port(
		 clock : in std_logic;
		 reset : in std_logic;

		 -- Avalon interface --
		 s_addr : in std_logic_vector (31 downto 0);
		 s_read : in std_logic;
		 s_readdata : out std_logic_vector (31 downto 0);
		 s_write : in std_logic;
		 s_writedata : in std_logic_vector (31 downto 0);
		 s_waitrequest : out std_logic; 

		 m_addr : out integer range 0 to ram_size-1;
		 m_read : out std_logic;
		 m_readdata : in std_logic_vector (7 downto 0);
		 m_write : out std_logic;
		 m_writedata : out std_logic_vector (7 downto 0);
		 m_waitrequest : in std_logic
	);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin

-- put your tests here
	-- Table of Contents for Test Cases:
	--------------------------------------------
	--    1.  Read  -  Clean,  Tag_Match,   		Valid
	--    2.  Read  -  Clean,  Tag_Match,   		Invalid 
	--    3.  Read  -  Clean,  Tag_Not_Match,  	Valid 
	--    4.  Read  -  Clean,  Tag_Not_Match,  	Invalid 
	--    5.  Read  -  Dirty,  Tag_Match,   		Valid
	--    6.  Read  -  Dirty,  Tag_Match,   		Invalid (Impossible Case)
	--    7.  Read  -  Dirty,  Tag_Not_Match,  	Valid
	--    8.  Read  -  Dirty,  Tag_Not_Match,  	Invalid (Impossible Case)
	--    9.  Write -  Clean,  Tag_Match,   		Valid
	--    10. Write -  Clean,  Tag_Match,   		Invalid 
	--    11. Write -  Clean,  Tag_Not_Match,  	Valid
	--    12. Write -  Clean,  Tag_Not_Match,  	Invalid 
	--    13. Write -  Dirty,  Tag_Match,   		Valid
	--    14. Write -  Dirty,  Tag_Match,   		Invalid (Impossible Case)
	--    15. Write -  Dirty,  Tag_Not_Match,  	Valid
	--    16. Write -  Dirty,  Tag_Not_Match,  	Invalid (Impossible Case)
	--------------------------------------------
	
	
	
	

	-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
	-- s_addr: 31-15 useless, 14-9 tag, 8-4 block index,3-2 word offset,1-0 byte offset		
	-- 1.  Read  -  Clean,  Tag_Match,   Valid
	-- offset = 0000; block_index = 111110; tag = 0000000000000000000011
	-- REPORT "1.  Read  -  Clean,  Tag_Match,   Valid";
	s_addr <= "00000000000000000000111111100000";
	-- report "s_addr: "&integer'image(to_integer(unsigned(s_addr)));
	-- first make it valid
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000A000A";
	wait for 10*clk_period;
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait for 10*clk_period;
	assert s_readdata = x"000A000A" report "################ Test 1 Not Passed! #####################" severity error;
	s_read <= '0';                                                       
	s_write <= '0'; 
--	wait for clk_period;
--	-- reset <= '1';
--	wait for clk_period;
	REPORT "_______________________";
	--reset <= '1';
	--reset <='0';
	WAIT FOR 10*clk_period;
	
	
	
-- --2.  Read  -  Clean,  Tag_Match,   		Invalid 
	-- offset = 0000; block_index = 000000; tag = 0000000000000000000000
	s_addr <= "00000000000000000000000000000001";
	s_read <= '1';
	s_write <= '0';
	wait for 10*clk_period;
	assert s_readdata = "00000000000000000000000000000001" report "################ Test 2 Not Passed! #####################" severity error;
	s_read <= '0';                                                       
	s_write <= '0'; 	
	REPORT "_______________________";
	--reset <= '1';
	--reset <='0';
	WAIT FOR 10*clk_period;
	
	
	-- 3.  Read  -  Clean,  Tag_Not_Match,  Valid
	-- offset = 0000; block_index = 111100; tag = 0000000000000000000011   
	REPORT "3.  Read  -  Clean,  Tag_Not_Match,  Valid";	
	s_addr <= "00000000000000000000111111000000";	
	-- first make it valid and clean
	s_read <= '1';                                                       
	s_write <= '0';
	s_writedata <= x"000A000B";  	
	wait for 10*clk_period;  
	-- change index to make it Tag_Not_Match but still clean and valid 
	-- offset = 0000; block_index = 111100; tag = 0000000000000000000010   
	s_addr <= "00000000000000000000101111000000";
	s_read <= '1';
	s_write <= '0';
	assert s_readdata = "00000000000000000000101111000000" report "################Test 3 Not Passed!################" severity error;
	s_read <= '0';                                                       
	s_write <= '0';
	wait for 10*clk_period;
	REPORT "_______________________";

	
	-- 4.  Read  -  Clean,  Tag_Not_Match,  Invalid
	-- offset = 0000; block_index = 10000; tag = 0000000000000000000000001   
	REPORT "4.  Read  -  Clean,  Tag_Not_Match,  Invalid";
	s_addr <= "00000000000000000000001100000000";	
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);      
	assert s_readdata = "00000000000000000000001100000000" report "################Test 4 Not Passed!################" severity error;
	s_read <= '0';                                                       
	s_write <= '0';
	wait for clk_period;
	REPORT "_______________________";

	
	-- 5.  Read  -  Dirty,  Tag_Match,   Valid
	-- offset = 0000; block_index = 111110; tag = 0000000000000000000011
	REPORT "5.  Read  -  Dirty,  Tag_Match,   Valid";
	s_addr <= "00000000000000000000111111100000";                        
	-- first make it dirty 
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000A000C";                                          
	wait until rising_edge(s_waitrequest);                               
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	assert s_readdata = x"000A000C" report "################Test 5 Not Passed!################" severity error;
	s_read <= '0';                                                       
	s_write <= '0'; 
	wait for clk_period;
	REPORT "_______________________";

	
	-- 7.  Read  -  Dirty,  Tag_Not_Match,  Valid
	-- offset = 0000; block_index = 111110; tag = 0000000000000000000011
	REPORT "7.  Read  -  Dirty,  Tag_Not_Match,  Valid";
	s_addr <= "00000000000000000000111111100000";  
	-- first make it dirty
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000A000D";                                          
	wait until rising_edge(s_waitrequest);
	-- offset = 0000; block_index = 111110; tag = 0000000000000000000010
	s_addr <= "00000000000000000000101111100000";                                                     
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);                               
	assert s_readdata = "00000000000000000000101111100000" report "################Test 7 Not Passed!################" severity error;
	s_read <= '0';                                                       
	s_write <= '0'; 
	wait for clk_period;
	REPORT "_______________________";
	
	
	
	-- 9.  Write -  Clean,  Tag_Match,   Valid
	REPORT "9.  Write -  Clean,  Tag_Match,   Valid";	
	-- offset = 0100; block_index = 000001; tag = 0000000000000000000001
	s_addr <= "00000000000000000000010000010100";
	-- first make it valid
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000A000E";    	
	wait until rising_edge(s_waitrequest);
	-- write on clean
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"000B000A";
	wait until rising_edge(s_waitrequest);  
	s_read <= '1';                                                       
	s_write <= '0';
	wait until rising_edge(s_waitrequest); 
	assert s_readdata = x"000B000A" report "################Test 9 Not Passed!################" severity error;	
	s_write <= '0';
	s_read <= '0';
	REPORT "_______________________";

	
	-- 10. Write -  Clean,  Tag_Match,  Invalid 
	REPORT "10. Write -  Clean,  Tag_Match,  Invalid";
	-- offset = 0100; block_index = 000101; tag = 0000000000000000000001
	s_addr <= "00000000000000000000010001010100";
	-- report "s_addr: "&integer'image(to_integer(unsigned(s_addr)));
	-- first make it valid
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000A000A";
	wait for 10*clk_period;
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait for 10*clk_period;
	assert s_readdata = x"000A000A" report "################ Test 10 Not Passed! #####################" severity error;
	s_read <= '0';                                                       
	s_write <= '0'; 
--	wait for clk_period;
--	-- reset <= '1';
--	wait for clk_period;
	REPORT "_______________________";
	--reset <= '1';
	--reset <='0';
	WAIT FOR 10*clk_period;
	
	-- 11. Write -  Clean,  Tag_Not_Match,  Valid
	REPORT "11. Write -  Clean,  Tag_Not_Match,  Valid";
	-- offset = 0100; block_index = 010001; tag = 0000000000000000000001
	s_addr <= "00000000000000000000010100010100";	
	-- first make it valid
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000B000B";
	wait until rising_edge(s_waitrequest); 
	-- write on clean and Tag_Not_Match
	-- offset = 0100; block_index = 010001; tag = 0000000000000000000011
	s_addr <= "00000000000000000000110100010100";
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"000B000C";
	wait until rising_edge(s_waitrequest);
	s_read <= '1';                                                       
	s_write <= '0';
	wait until rising_edge(s_waitrequest); 
	assert s_readdata = x"000B000C" report "################Test 11 Not Passed!################" severity error;	
	s_write <= '0';
	s_read <= '0';
	REPORT "_______________________";

	
	
	
	
	-- 12. Write -  Clean,  Tag_Not_Match,  Invalid
	-- write on clean, Tag_Not_Match and invalid
	REPORT "12. Write -  Clean,  Tag_Not_Match,  Invalid";
	-- offset = 0100; block_index = 011001; tag = 0000000000000000000011
	s_addr <= "00000000000000000000110110010100";
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"0000000B";
	wait until rising_edge(s_waitrequest);
	s_read <= '1';                                                       
	s_write <= '0';
	wait until rising_edge(s_waitrequest); 
	assert s_readdata = x"0000000B" report "################Test 12 Not Passed!################" severity error;	
	s_write <= '0';
	s_read <= '0';
	REPORT "_______________________";
	
	
	
	
	-- 13. Write -  Dirty,  Tag_Match,   Valid
	-- write on dirty, Tag_Match and valid
	REPORT "13. Write -  Dirty,  Tag_Match,   Valid";
	-- offset = 0100; block_index = 011001; tag = 0000000000000000000011
	s_addr <= "00000000000000000000110110010100";
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"0000000C";
	wait until rising_edge(s_waitrequest);
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"0000000D";
	wait until rising_edge(s_waitrequest);
	s_read <= '1';                                                       
	s_write <= '0';
	wait until rising_edge(s_waitrequest); 
	assert s_readdata = x"0000000D" report "################Test 13 Not Passed!################" severity error;	
	s_write <= '0';
	s_read <= '0';
	REPORT "_______________________";

	
	
	-- 15. Write -  Dirty,  Tag_Not_Match,  Valid
	REPORT "15. Write -  Dirty,  Tag_Not_Match,  Valid";
	-- offset = 0100; block_index = 011001; tag = 0000000000000000000011
	s_addr <= "00000000000000000000110110010100";
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"0000000E";
	wait until rising_edge(s_waitrequest);
	-- offset = 0100; block_index = 011001; tag = 0000000000000000000111
	s_addr <= "00000000000000000001110110010100";
	s_write <= '1';
	s_read <= '0';
	s_writedata <= x"000000AE";
	wait until rising_edge(s_waitrequest);
	s_read <= '1';                                                       
	s_write <= '0';
	wait until rising_edge(s_waitrequest); 
	assert s_readdata = x"000000AE" report "################Test 15 Not Passed!################" severity error;	
	s_write <= '0';
	s_read <= '0';
	REPORT "_______________________";
end process;
	
end;