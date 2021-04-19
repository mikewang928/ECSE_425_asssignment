library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity Memory is
	generic(
			ram_size:		integer := 8192 -- There're 8192 lines in the data memory
--			mem_delay:		time := 1 ns;
--			clock_period:	time := 1 ns			
			);
	port(
		clk: in std_logic;
		mem_write_in : in std_logic;  								-- whether write to memory is needed (1) or not (0)
		mem_data_write : in std_logic_vector(31 downto 0); 	-- data write into the memory
		mem_read_in : in std_logic;  									-- whether read from memory is needed (1) or not (0)
		alu_in : in std_logic_vector (31 downto 0); 			--address that we want to read/write
		
		-- control signals propogated to the next stage
		reg_write_in : in std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_in : in std_logic; 								-- selecting whether writeback data is read
		

		reg_write_out : out std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_out : out std_logic; 								-- selecting whether writeback data is read
		
		read_data : out std_logic_vector(31 downto 0);
		alu_out : out std_logic_vector (31 downto 0)
	);
end entity;

architecture arch of Memory is
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL memory_block: MEM;
begin
	reg_write_out <= reg_write_in;
	mem_to_reg_out <= mem_to_reg_in;
	alu_out <= alu_in;

	process(clk)
	variable address: integer range 0 to ram_size-1;
	file data_memory: text;
	variable row: line;
	begin
	if (now < 1ps) then
		for i in 0 to ram_size-1 loop
			memory_block(i) <= std_logic_vector(to_unsigned(i,32));
		end loop;
	end if;
	
	if(rising_edge(clk)) then
		address := to_integer(unsigned(alu_in));
		if (mem_write_in = '1') then
			memory_block(address/4) <= mem_data_write;
			file_open(data_memory, "memory.txt", WRITE_MODE);
			for i in 0 to ram_size-1 loop
				write(row, memory_block(i));
				writeline(data_memory, row);
			end loop;
			file_close(data_memory);
			read_data <= memory_block(address/4);
		elsif (mem_read_in = '1') then
			read_data <= memory_block(address/4);
		elsif (mem_write_in = '0' and mem_read_in = '0') then
			read_data <= "00000011111111111111111111111111";
		end if;
		
	end if;
	end process;
end arch;	
		
		
		
		