library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

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
	--    1.  Read  -  Clean,  Hit,   Valid
	--    2.  Read  -  Clean,  Hit,   Invalid (Impossible Case)
	--    3.  Read  -  Clean,  Miss,  Valid 
	--    4.  Read  -  Clean,  Miss,  Invalid
	--    5.  Read  -  Dirty,  Hit,   Valid
	--    6.  Read  -  Dirty,  Hit,   Invalid (Impossible Case)
	--    7.  Read  -  Dirty,  Miss,  Valid
	--    8.  Read  -  Dirty,  Miss,  Invalid (Impossible Case)
	--    9.  Write -  Clean,  Hit,   Valid
	--    10. Write -  Clean,  Hit,   Invalid (Impossible Case)
	--    11. Write -  Clean,  Miss,  Valid
	--    12. Write -  Clean,  Miss,  Invalid
	--    13. Write -  Dirty,  Hit,   Valid
	--    14. Write -  Dirty,  Hit,   Invalid (Impossible Case)
	--    15. Write -  Dirty,  Miss,  Valid
	--    16. Write -  Dirty,  Miss,  Invalid (Impossible Case)
	--------------------------------------------
	
	-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
	-- s_addr: 31-7 tag (12-7 is useful tag),6-2 block index,1-0 word offset (s_addr only consider word allocation in cache)
	-- m_addr: 31-15 useless, 14-9 tag,8-4 block index,3-2 word offset,1-0 byte offset
	
	-- 1.  Read  -  Clean,  Hit,   Valid
	-- s_addr: 31-7 tag (12-7 is useful tag),6-2 block index,1-0 word offset (s_addr only consider word allocation in cache)
	-- offset = 11; block_index = 11111; tag = 1111111111111111111111111
	REPORT "1.  Read  -  Clean,  Hit,   Valid";
	s_addr <= "11111111111111111111111111110000";                        
	-- first make it valid
	s_write <= '1'; 
	s_read <= '0';
	s_writedata <= x"000B000A";
	wait for clk_period;
	-- assert m_writedata = x"" report "m_writedata wrong" 
	s_read <= '1';                                                       
	s_write <= '0';                                                      
	wait until rising_edge(s_waitrequest);     
	wait until falling_edge(s_waitrequest);
	assert s_readdata = "00000000000000000000111111110000" report "Test 1 Not Passed!" severity error;
	s_read <= '0';                                                       
	s_write <= '0'; 
	wait for clk_period;
	-- reset <= '1';
	wait for clk_period;
	REPORT "_______________________";
	-- reset <='0';
	WAIT FOR 1*clk_period;
	
--	-- 3.  Read  -  Clean,  Miss,  Valid
--	-- offset = 00; block_index = 00000; tag = 0000000000000000000000000   
--	REPORT "3.  Read  -  Clean,  Miss,  Valid";	
--	s_addr <= "00000000000000000000000000000000";	
--	-- first make it valid
--	s_read <= '1';                                                       
--	s_write <= '0';  	
--	wait until rising_edge(s_waitrequest);   
--	-- offset = 00; block_index = 00000; tag = 0000000000000000000000000  
--	s_addr <= "00000000000000000000000010000000";
--	s_read <= '1';
--	s_write <= '0';
--	assert s_readdata = "00000000000000000000000010000000" report "Test 3 Not Passed!" severity error;
--	s_read <= '0';                                                       
--	s_write <= '0';
--	wait for clk_period;
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	-- 4.  Read  -  Clean,  Miss,  Invalid
--	-- offset = 00; block_index = 00000; tag = 0000000000000000000000000   
--	REPORT "4.  Read  -  Clean,  Miss,  Invalid";
--	s_addr <= "00000000000000000000000100000000";	
--	s_read <= '1';                                                       
--	s_write <= '0';                                                      
--	wait until rising_edge(s_waitrequest);      
--	assert s_readdata = "00000000000000000000000100000000" report "Test 4 Not Passed!" severity error;
--	s_read <= '0';                                                       
--	s_write <= '0';
--	wait for clk_period;
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	-- 5.  Read  -  Dirty,  Hit,   Valid
--	-- offset = 11; block_index = 11111; tag = 1111111111111111111111111
--	REPORT "5.  Read  -  Dirty,  Hit,   Valid";
--	s_addr <= "11111111111111111111111111111111";                        
--	-- first make it dirty 
--	s_write <= '1'; 
--	s_read <= '0';
--	s_writedata <= x"000B000A";                                          
--	wait until rising_edge(s_waitrequest);                               
--	s_read <= '1';                                                       
--	s_write <= '0';                                                      
--	wait until rising_edge(s_waitrequest);                               
--	assert s_readdata = x"000B000A" report "Test 5 Not Passed!" severity error;
--	s_read <= '0';                                                       
--	s_write <= '0'; 
--	wait for clk_period;
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	
--	
--	-- 7.  Read  -  Dirty,  Miss,  Valid
--	-- offset = 11; block_index = 11111; tag = 1111111111111111111111110
--	REPORT "7.  Read  -  Dirty,  Miss,  Valid";
--	s_addr <= "11111111111111111111111111111111"; 
--	-- first make it dirty
--	s_write <= '1'; 
--	s_read <= '0';
--	s_writedata <= x"000B000A";                                          
--	wait until rising_edge(s_waitrequest);
--	s_addr <= "11111111111111111111111101111111";                                                     
--	s_read <= '1';                                                       
--	s_write <= '0';                                                      
--	wait until rising_edge(s_waitrequest);                               
--	assert s_readdata = "00000000000000000000111101111111" report "Test 7 Not Passed!" severity error;
--	s_read <= '0';                                                       
--	s_write <= '0'; 
--	wait for clk_period;
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	
--	
--	-- 9.  Write -  Clean,  Hit,   Valid
--	REPORT "9.  Write -  Clean,  Hit,   Valid";	
--	s_addr <= "00000000000000000000000000000100";
--	-- first make it valid
--	s_read <= '1';                                                       
--	s_write <= '0';     	
--	wait until rising_edge(s_waitrequest);
--	-- write on clean
--	s_write <= '1';
--	s_read <= '0';
--	s_writedata <= x"0000000B";
--	wait until rising_edge(s_waitrequest);  
--	s_read <= '1';                                                       
--	s_write <= '0';
--	wait until rising_edge(s_waitrequest); 
--	assert s_readdata = x"0000000B" report "Test 9 Not Passed!" severity error;	
--	s_write <= '0';
--	s_read <= '0';
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	
--	
--	
--	-- 11. Write -  Clean,  Miss,  Valid
--	REPORT "11. Write -  Clean,  Miss,  Valid";
--	s_addr <= "00000000000000000000000000001000";	
--	-- first make it valid
--	s_read <= '1';                                                       
--	s_write <= '0';     	
--	wait until rising_edge(s_waitrequest); 
--	-- write on clean and miss
--	s_addr <= "00000000000000000000000010001000";
--	s_write <= '1';
--	s_read <= '0';
--	s_writedata <= x"0000000B";
--	wait until rising_edge(s_waitrequest);
--	s_read <= '1';                                                       
--	s_write <= '0';
--	wait until rising_edge(s_waitrequest); 
--	assert s_readdata = x"0000000B" report "Test 11 Not Passed!" severity error;	
--	s_write <= '0';
--	s_read <= '0';
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	
--	
--	
--	-- 12. Write -  Clean,  Miss,  Invalid
--	-- write on clean, miss and invalid
--	REPORT "12. Write -  Clean,  Miss,  Invalid";
--	s_addr <= "00000000000000000000000000001100";
--	s_write <= '1';
--	s_read <= '0';
--	s_writedata <= x"0000000B";
--	wait until rising_edge(s_waitrequest);
--	s_read <= '1';                                                       
--	s_write <= '0';
--	wait until rising_edge(s_waitrequest); 
--	assert s_readdata = x"0000000B" report "Test 12 Not Passed!" severity error;	
--	s_write <= '0';
--	s_read <= '0';
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	
--	
--	
--	-- 13. Write -  Dirty,  Hit,   Valid
--	-- write on dirty, hit and valid
--	REPORT "13. Write -  Dirty,  Hit,   Valid";
--	s_addr <= "00000000000000000000000000001100";
--	s_write <= '1';
--	s_read <= '0';
--	s_writedata <= x"0000000C";
--	wait until rising_edge(s_waitrequest);
--	s_read <= '1';                                                       
--	s_write <= '0';
--	wait until rising_edge(s_waitrequest); 
--	assert s_readdata = x"0000000C" report "Test 13 Not Passed!" severity error;	
--	s_write <= '0';
--	s_read <= '0';
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
--	
--	
--	-- 15. Write -  Dirty,  Miss,  Valid
--	REPORT "15. Write -  Dirty,  Miss,  Valid";
--	s_addr <= "00000000000000000000000010001100";
--	s_write <= '1';
--	s_read <= '0';
--	s_writedata <= x"0000000D";
--	wait until rising_edge(s_waitrequest);
--	s_read <= '1';                                                       
--	s_write <= '0';
--	wait until rising_edge(s_waitrequest); 
--	assert s_readdata = x"0000000D" report "Test 15 Not Passed!" severity error;	
--	s_write <= '0';
--	s_read <= '0';
--	REPORT "_______________________";
--	reset <='1';
--	WAIT FOR 1*clk_period;
--	reset <='0';
--	WAIT FOR 1*clk_period;
end process;
	
end;