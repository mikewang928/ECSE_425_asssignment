library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
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
end cache;

architecture arch of cache is
-- declare signals here

-- Address Portions: 
-- 4 words per block (128 / 32)  -> 2 bits for offset
-- 32 blocks in the memory (4096 / 128) -> 5 bits for block_ind
-- 32 bit addresses -> 32 - 5 - 2 = 25 bits for tag (however we are only using the lower 15 bits in the 32 bits address)

-- Defining all the possible states for a write-back cache:
-- r_miss_mem_w:in the case of read miss
-- w_miss_mem_w: write s_writedata to main memory and than back to the cache
type state_type is (idle, wrt, rd, r_miss_mem_w, r_miss_mem_r, mem_wait, w_miss_mem_w);
signal state : state_type;
signal next_state : state_type;


-- We define bit 154 to be valid bit, bit 153 to be dirty bit, bits 152 to 128 to be tag bits
-- sincewe have 32 sets, and each sets contains 25bits tag, 1 bit dirty, 1 bit valid, 128 bit data
type cache_type is array (0 to 31) of std_logic_vector (154 downto 0);
signal cache_blocks: cache_type;




begin

-- make circuits here
-- Set up the clock for transition between states
process (clock, reset)
begin
	if reset = '1' then
		-- Reset
		state <= idle;
	elsif (clock'event and clock = '1') then
		-- Normal flow
		state <= next_state;
	end if;

end process;

process(s_read, s_write, m_waitrequest, state)

	variable counter : INTEGER := 0; -- Word counter within the block

	-- Cache should simply use the lower 15 bits of the address and ignore the rest since
	-- the main memory here has only 2^15 bytes (32768 bytes).
	variable MemoryAddress: std_logic_vector (14 downto 0);

	-- Defining the offset and block_ind
	variable word_offset: INTEGER := 0;
	variable block_ind: INTEGER;
	variable valid_bit : std_logic;
	variable dirty_bit : std_logic; 
begin

	-- 2 bits for offset (0, 1 entry of the logic vector)
	-- s_addr 32 bit logic vector
	-- 00->0; 01->1; 10 -> 2; 11-> 3; if we want to find the forth word in the block 
	word_offset := to_integer(unsigned(s_addr(1 downto 0))) + 1;
	-- 5 bits for block_ind
	block_ind := to_integer(unsigned(s_addr(6 downto 2)));


	
	----------------  Defining a Moore machine for the Cache Operations --------------------
	case state is
		
		-- The idle state of the state machine, check what kind of operation is requested (read or write)
		when idle =>
			s_waitrequest <= '1';
			-- Check if there is a write operation
			if s_write = '1' then 
				next_state <= wrt;
			-- Check if there is a read operation
			elsif s_read = '1' then
				next_state <= rd;
			-- If no operation is specificed, stay in the idle state
			else
				next_state <= idle;
			end if;
	
		when rd=>
			-- valid 1, invalid 0
			valid_bit := cache_blocks(block_ind)(154);
			-- dirty 1, clean 0
			dirty_bit := cache_blocks(block_ind)(153);
			
			-- hit 
			-- valid and tag match
			if valid_bit = '1' and cache_blocks(block_ind)(152 downto 128) = s_addr (31 downto 7) then
				-- MSB a b c d LSB
				-- if word_offset = 3. we want to find b 
				-- 3*32 -1 
				-- 2*32 -1
				s_readdata <= cache_blocks(block_ind)(127 downto 0)((word_offset*32) - 1 downto 32*(word_offset - 1));
				s_waitrequest <= '0';
				next_state <= idle;
			
			-- read MISS (tag don't match or valid_bit = '0')
			-- valid, dirty
			elsif valid_bit ='1' and dirty_bit = '1' and cache_blocks(block_ind)(152 downto 128) /= s_addr (31 downto 7)then
				-- still need t write the data from main memory to cache
				next_state <= r_miss_mem_w;
			-- valid, clean
			elsif valid_bit = '1' and dirty_bit = '0'and cache_blocks(block_ind)(152 downto 128) /= s_addr (31 downto 7) then 
				-- still need t write the data from main memory to cache
				next_state <= r_miss_mem_r; 
			
			-- invalid, not matter tag match or unmatch, dirty or clean, 
			-- you need to go to the main memeory and read the correct value
			elsif valid_bit = '0' then 
			-- still need t write the data from main memory to cache
				next_state <= r_miss_mem_r;
				
				
			-- Reading is not done, keep reading
			else 
				next_state <= rd;
			end if;
			
			
			
	when wrt => 
			-- valid 1, invalid 0
			valid_bit := cache_blocks(block_ind)(154);
			-- dirty 1, clean 0
			dirty_bit := cache_blocks(block_ind)(153);
			
			
			-- Hit (valid, tag match)
			-- no matter clean or dirty you change the content
			if valid_bit = '1' and cache_blocks(block_ind)(152 downto 128) = s_addr (31 downto 7) then
				cache_blocks(block_ind)(127 downto 0)((word_offset*32) - 1 downto 32*(word_offset - 1)) <= s_writedata;
				dirty_bit := '1';
				s_waitrequest <= '0';
				next_state <= idle; 
			
			
			-- miss 
			-- no matter dirty or clean as long as you miss or not valid, you need to perform a memwrite
			else
			-- still need to write the data from main memory to cache
				next_state <= w_miss_mem_w; 
			end if; 
			
	-- data in the old block update in the main mem 
	-- extract data from main mem in the corret tag update in the cache
	when r_miss_mem_w =>
			if counter < 4 and m_waitrequest = '1' then
				MemoryAddress := cache_blocks(block_ind)(135 downto 128) & s_addr (6 downto 0);
				m_addr <= to_integer(unsigned (MemoryAddress)) + counter;
				m_write <= '1';
				m_read <= '0';
				-- Write
				m_writedata <= cache_blocks(block_ind)(127 downto 0)((counter * 8) + 7 + 32*(word_offset - 1) downto (counter*8) + 32*(word_offset - 1));
				-- Increment the word counter
				counter := counter + 1;
				next_state <= r_miss_mem_w;
				
			-- old dat updated in the memory
			-- now we need to extract data with correct tag int he main mem to the cache
			-- reset counter 
			elsif counter = 4 then 
				counter := 0;
				next_state <= r_miss_mem_r; 
			
			-- if m_waitrequest = '0', we nee dto wait 
			else 
				m_write <= '0';
				next_state <= r_miss_mem_w; 
			end if;

	-- data in the old block update in the main mem 
	-- cpu data update to the cache	
	when w_miss_mem_w => 
			-- valid 1, invalid 0
			valid_bit := cache_blocks(block_ind)(154);
			-- dirty 1, clean 0
			dirty_bit := cache_blocks(block_ind)(153);
			
			-- updating main mem with old date in the cache which is about to be replaced
			if counter < 4 and m_waitrequest = '1' then
				MemoryAddress := cache_blocks(block_ind)(135 downto 128) & s_addr (6 downto 0);
				m_addr <= to_integer(unsigned (MemoryAddress)) + counter;
				m_write <= '1';
				m_read <= '0';
				-- Write
				m_writedata <= cache_blocks(block_ind)(127 downto 0)((counter * 8) + 7 + 32*(word_offset - 1) downto (counter*8) + 32*(word_offset - 1));
				-- Increment the word counter
				counter := counter + 1;
				next_state <= r_miss_mem_w;
				

				
			-- write cpu data to the cache block 
			elsif counter = 4 then
				counter := 0; 
				cache_blocks(block_ind)(127 downto 0)(32*(word_offset)-1 downto 32*(word_offset - 1)) <= s_writedata;
				cache_blocks(block_ind)(152 downto 128) <= s_addr(31 downto 7);
				cache_blocks(block_ind)(154) <= '1';
				cache_blocks(block_ind)(153) <= '1';
				s_waitrequest <= '0';
				m_write <= '0';
				
				next_state <= idle; 
			end if;
				
	-- provide reading address
	when r_miss_mem_r => 
			if m_waitrequest = '1' then
				-- because we already have a miss in cache thus s_addr (14 downto 0) is the main memory address
				MemoryAddress := s_addr(14 downto 2)&"00"; --unsigned(s_addr(14 downto 4) & "0000")
				m_addr <= to_integer(unsigned (MemoryAddress)) + counter;
				m_read <= '1';
				m_write <= '0'; 
				next_state <= mem_wait;
			else 
				next_state <= r_miss_mem_r; 
				
			end if; 
	
	-- extract data from main mem in the correct tag update in the cache
	when mem_wait => 
			-- valid 1, invalid 0
			valid_bit := cache_blocks(block_ind)(154);
			-- dirty 1, clean 0
			dirty_bit := cache_blocks(block_ind)(153);
			if counter < 3 and m_waitrequest = '0' then
				-- Read the data
				-- m_readdata is a byte 
				-- wrte back to cache 
				cache_blocks(block_ind)(127 downto 0)((counter * 8) + 7 + 32*(word_offset - 1) downto (counter*8) + 32*(word_offset - 1)) <= m_readdata;
				counter := counter + 1;
				m_read <= '0';
				next_state <= r_miss_mem_r;
				-- 0 1 2 3
				
			-- after the 3rd counter we don't need to update the s_addr
			elsif counter = 3 and m_waitrequest = '0' then 
				cache_blocks(block_ind)(127 downto 0)((counter * 8) + 7 + 32*(word_offset - 1) downto (counter*8) + 32*(word_offset - 1)) <= m_readdata;
				counter := counter + 1;
				m_read <= '0';
				next_state <= mem_wait; 
			
			elsif counter = 4 then 
				s_readdata <= cache_blocks(block_ind)(127 downto 0)((32*word_offset - 1) downto 32*(word_offset - 1));
				-- update cache tag
				cache_blocks(block_ind)(152 downto 128) <= s_addr (31 downto 7);
					
				-- update valid and dirty bits s
				cache_blocks(block_ind)(154) <= '1';
				cache_blocks(block_ind)(153) <= '0';
				
				m_read <= '0';
				m_write <= '0'; 
				s_waitrequest <= '0';
				
				counter := 0; 
				next_state <= idle; 
			else 
				next_state <= mem_wait; 	
			end if; 
		end case; 
end process; 

end arch;