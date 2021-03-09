library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

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

-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
-- s_addr: 31-15 useless, 14-9 tag, 8-4 block index,3-2 word offset,1-0 byte offset
architecture arch of cache is

type state_type is (idle, wrt, rd, r_miss_mem_w, r_miss_mem_r, mem_wait, w_miss_mem_w, mem_w_cache_w);
signal state : state_type;
signal next_state : state_type;

type cache_type is array (0 to 31) of std_logic_vector (154 downto 0);
signal cache_blocks: cache_type:= (others=>(others=>'0'));

-- shadow 
signal m_addr_i : integer range 0 to ram_size-1;
signal MemoryAddress: std_logic_vector (14 downto 0);


begin
-- shadow
m_addr <= m_addr_i;

	-- make circuits here
	-- Set up the clock for transition between states
	process (clock, reset)
	begin
		if reset = '1' then
			-- Reset
			state <= idle;
			cache_blocks <= (others=>(others=>'0'));
			s_waitrequest <= '1';
			-- init cache 
		elsif (clock'event and clock = '1') then
			-- Normal flow
			state <= next_state;
		end if;
	end process;

	
	
	process(s_read, s_write, m_waitrequest, state)
		variable counter : INTEGER := 0; -- Word counter within the block
		variable word_offset: INTEGER := 0;
		variable block_ind: INTEGER;
		variable valid_bit : std_logic;
		variable dirty_bit : std_logic; 
	begin
	   --report "process 2 begining";
		word_offset := to_integer(unsigned(s_addr(3 downto 2))) + 1;
		block_ind := to_integer(unsigned(s_addr(8 downto 4)));
		

--	s_addr <= "00000000000000000000111111100000";
--	s_write <= '1'; 
--	s_read <= '0';
--	s_writedata <= x"000B000A";
--	wait for clk_period;
--		
		
		----------------  Defining a Moore machine for the Cache Operations --------------------
		case state is
			
			-- The idle state of the state machine, check what kind of operation is requested (read or write)
			when idle =>
			report "in idle!";
				s_waitrequest <= '1';
				report "s_write :"&std_logic'image(s_write);
				report "s_read :"&std_logic'image(s_read);
				if s_write = '1' and s_read = '0' then 
					next_state <= wrt;
				elsif s_read = '1' and s_write = '0'then
					next_state <= rd;
				else
					next_state <= idle;
				end if;
		 
		
--			-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
--			-- s_addr: 31-15 useless, 14-9 tag, 8-4 block index,3-2 word offset,1-0 byte offset				
		when wrt => 
				report "------------ in wrt state! -----------------";
				-- valid 1, invalid 0
				valid_bit := cache_blocks(block_ind)(154);
				-- dirty 1, clean 0
				dirty_bit := cache_blocks(block_ind)(153);
				report "valid_bit: "&std_logic'image(valid_bit);
				report "dirty_bit: "&std_logic'image(dirty_bit);
				
				-- Hit (valid, tag match), thus wrting on cache
				if valid_bit = '1' and cache_blocks(block_ind)(133 downto 128) = s_addr (14 downto 9) then
					cache_blocks(block_ind)(127 downto 0)((word_offset*32) - 1 downto 32*(word_offset - 1)) <= s_writedata;
					dirty_bit := '1';
					s_waitrequest <= '0';
					next_state <= idle; 
			
				-- miss invalid or miss valid clean
				elsif valid_bit = '0' or valid_bit = 'U' or cache_blocks(block_ind)(133 downto 128) /= s_addr (14 downto 9) or (valid_bit='1' and dirty_bit ='0') then
					next_state <= mem_w_cache_w;
					
				-- miss valid dirty
				elsif valid_bit = '1' and cache_blocks(block_ind)(133 downto 128) /= s_addr (14 downto 9) and dirty_bit = '1'then 
					next_state <= w_miss_mem_w;
				-- wrting did not finished
				else
					next_state <= wrt; 
				end if; 
			
--			-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
--			-- s_addr: 31-15 useless, 14-9 tag, 8-4 block index,3-2 word offset,1-0 byte offset			
		when mem_w_cache_w=> 	
			--report "---------in mem_w_cache_w state!-----------";
			--report "m_waitrequest: "&std_logic'image(m_waitrequest);
			-- invalid miss or clean,valid,miss
			-- write s_writedata into the main mem byte by byte 
			
			if counter < 4 and m_waitrequest = '1' then
				report "---------in mem_w_cache_w state cache writing state!-----------";
				report "counter: "&integer'image(counter);
				m_write <= '1';
				m_read <= '0';
				MemoryAddress <= s_addr(14 downto 2)&"00";
				m_addr_i <= to_integer(unsigned(MemoryAddress)) + counter;
				report "s_addr: "&integer'image(to_integer(unsigned(s_addr)));
				report "MemoryAddress: "&integer'image(to_integer(unsigned(MemoryAddress)));
				report "m_addr_i: "&integer'image(m_addr_i);
				
				m_writedata <= s_writedata(((counter+1)*8-1) downto (counter*8));
				--report "m_writedata: "&integer'image(to_integer(unsigned(m_writedata)));
				counter := counter + 1;
				
				-- next_state <= mem_w_cache_w;
			
			-- write cpu data to the cache block 
			elsif counter = 4 then
				report "*********counter ended!*********";
				counter := 0; 
				report "s_write: "&std_logic'image(s_write);
				cache_blocks(block_ind)(127 downto 0)(32*(word_offset)-1 downto 32*(word_offset - 1)) <= s_writedata;
				-- set tag
				cache_blocks(block_ind)(150 downto 128) <= s_addr(31 downto 9);
				-- set valid
				cache_blocks(block_ind)(154) <= '1';
				-- set dirty
				cache_blocks(block_ind)(153) <= '0';
				report "valid_bit_after mem_w_cache_w: "&std_logic'image(cache_blocks(block_ind)(154));
				report "dirty_bit_after mem_w_cache_w: "&std_logic'image(cache_blocks(block_ind)(153));
				s_waitrequest <= '0';
				m_write <= '0';
				m_read <= '0';
				next_state <= idle; 
			else 
				m_write <= '0';
				next_state <= mem_w_cache_w; 
			end if;
			
			
		-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
		-- s_addr: 31-15 useless, 14-9 tag,8-4 block index,3-2 word offset,1-0 byte offset
		when w_miss_mem_w => 
				report "--------------w_miss_mem_w state start-------------------------------";
				-- valid 1, invalid 0
				valid_bit := cache_blocks(block_ind)(154);
				-- dirty 1, clean 0
				dirty_bit := cache_blocks(block_ind)(153);
				
				report "m_waitrequest :"& std_logic'image(m_waitrequest);
				-- updating main mem with old data in the cache which is about to be replaced
				if counter < 4 and m_waitrequest = '1' then
					m_write <= '1';
					m_read <= '0';
					MemoryAddress <= cache_blocks(block_ind)(127 downto 0)(150 downto 128) & s_addr (8 downto 2) & "00";
					report "s_addr (8 downto 2): " & integer'image(to_integer(unsigned(s_addr (8 downto 2))));
					report "MemoryAddress : " & integer'image(to_integer(unsigned(MemoryAddress)));
					m_addr_i <= to_integer(unsigned (MemoryAddress)) + counter;
					report "m_addr_i : " & integer'image(m_addr_i);
					-- Write
					m_writedata <= cache_blocks(block_ind)((((word_offset -1)*32) +((counter+1)*8)-1) downto((word_offset - 1)*32 + counter*8));
					-- Increment the word counter
					report "counter ="&integer'image(counter);
					counter := counter + 1;
					next_state <= w_miss_mem_w;
				
					
				-- write cpu data to the cache block 
				elsif counter = 4 then
					report "***************counter ended!*******************";
					m_write <= '0';
					m_read <= '0';
					counter := 0; 
					cache_blocks(block_ind)(127 downto 0)(32*(word_offset)-1 downto 32*(word_offset - 1)) <= s_writedata;
					-- set tag
					cache_blocks(block_ind)(150 downto 128) <= s_addr(31 downto 9);
					-- set valid
					cache_blocks(block_ind)(154) <= '1';
					-- set clean
					cache_blocks(block_ind)(153) <= '0';
					s_waitrequest <= '0';
					next_state <= idle; 
				else 
					m_write <= '0';
					next_state <= w_miss_mem_w; 
				end if;
		
		
		-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
		-- s_addr: 31-15 useless, 14-9 tag, 8-4 block index,3-2 word offset,1-0 byte offset
		when rd=>
			report "--------------rd state start!-------------------------------";
			valid_bit := cache_blocks(block_ind)(154);
			dirty_bit := cache_blocks(block_ind)(153);
			report "valid_bit: "&std_logic'image(valid_bit);
			report "dirty_bit: "&std_logic'image(dirty_bit);
			-- hit 
			-- valid and tag match
			if valid_bit = '1' and cache_blocks(block_ind)(150 downto 128) = s_addr (31 downto 9) then
				report "hit!";
				s_readdata <= cache_blocks(block_ind)(127 downto 0)((word_offset*32) - 1 downto 32*(word_offset - 1));
				s_waitrequest <= '0';
				next_state <= idle;
			
			-- read MISS (tag don't match or valid_bit = '0')
			-- valid, dirty
			elsif valid_bit ='1' and dirty_bit = '1' and cache_blocks(block_ind)(150 downto 128) /= s_addr (31 downto 9)then
				report "valid, dirty! miss!";
				next_state <= r_miss_mem_w;
			
			-- valid, clean
			elsif valid_bit = '1' and dirty_bit = '0'and cache_blocks(block_ind)(150 downto 128) /= s_addr (31 downto 9) then 
				report "valid, clean! miss!";
				next_state <= r_miss_mem_r; 
			
			-- invalid, not matter tag match or unmatch, dirty or clean, 
			-- you need to go to the main memeory and read the correct value
			elsif valid_bit = '0' then 
				report "invalid! miss!";
				next_state <= r_miss_mem_r;
			else 
				report "read waiting!";
				next_state <= rd;
			end if;
			
			
			
		-- cache_blocks: 154 valid, 153 dirty, 152-134 useless, 133-128 tag, 127-0 data field in the block
		-- s_addr: 31-15 useless, 14-9 tag, 8-4 block index,3-2 word offset,1-0 byte offset
		when r_miss_mem_w =>
				report "in r_miss_mem_w state!";
				-- here we are writing the entire word (32 bit, 4 bytes) in the block in the cache into the main memory
				if counter < 4 and m_waitrequest = '1' then
					MemoryAddress <= cache_blocks(block_ind)(133 downto 128) & s_addr (8 downto 2)&"00"; 
					report "MemoryAddress is:" & integer'image(to_integer(unsigned(MemoryAddress)));
					m_addr_i <= to_integer(unsigned (MemoryAddress)) + counter;
					report "m_addr is: " & INTEGER'image(m_addr_i);
					m_write <= '1';
					m_read <= '0';
					
					-- Write
					m_writedata <= cache_blocks(block_ind)((((word_offset -1)*32) +((counter+1)*8)-1) downto ((word_offset - 1)*32 + counter*8));
					-- Increment the word counter
					counter := counter + 1;
					next_state <= r_miss_mem_w;
					
				-- old data updated in the memory
				elsif counter = 4 then 
					m_write <= '0';
					m_read <= '0';
					counter := 0;
					next_state <= r_miss_mem_r; 
				-- if m_waitrequest = '0', we need to wait 
				else  
					m_write <= '0';
					next_state <= r_miss_mem_w; 
				end if;
				
				
				
				
		-- provide reading address
		when r_miss_mem_r => 
				report "in r_miss_mem_r state!";
				if m_waitrequest = '1' then
					-- because we already have a miss in cache thus s_addr (12 downto 0)+byte_offset is the main memory address
					MemoryAddress <= s_addr(12 downto 0)&"00"; 
					m_addr_i <= to_integer(unsigned (MemoryAddress)) + counter;
					m_read <= '1';
					m_write <= '0'; 
					next_state <= mem_wait;
				else 
					next_state <= r_miss_mem_r; 
					
				end if; 
		
		
		
		-- extract data from main mem in the correct tag update in the cache
		when mem_wait => 
				report "in mem_wait state!";
				-- valid 1, invalid 0
				valid_bit := cache_blocks(block_ind)(154);
				-- dirty 1, clean 0
				dirty_bit := cache_blocks(block_ind)(153);
				if counter < 3 and m_waitrequest = '0' then
					-- Read the data
					-- m_readdata is a byte 
					cache_blocks(block_ind)((((word_offset -1)*32) +((counter+1)*8)-1) downto ((word_offset - 1)*32 + counter*8)) <= m_readdata;
					counter := counter + 1;
					m_read <= '0';
					next_state <= r_miss_mem_r;
					
				-- after the 3rd counter we don't need to update the s_addr
				elsif counter = 3 and m_waitrequest = '0' then 
					cache_blocks(block_ind)((((word_offset -1)*32) +((counter+1)*8)-1) downto ((word_offset - 1)*32 + counter*8)) <= m_readdata;
					counter := counter + 1;
					m_read <= '0';
					next_state <= mem_wait; 
				
				elsif counter = 4 then
					s_readdata <= cache_blocks(block_ind)((32*word_offset - 1) downto 32*(word_offset - 1));
					-- update cache tag
					cache_blocks(block_ind)(150 downto 128) <= s_addr (31 downto 9);
					-- update valid and dirty bits s
					cache_blocks(block_ind)(154) <= '1';
					cache_blocks(block_ind)(153) <= '1';
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