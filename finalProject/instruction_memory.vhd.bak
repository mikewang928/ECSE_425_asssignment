LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

ENTITY instruction_memory IS
	GENERIC(
		ram_size : INTEGER := 8192;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clk: IN STD_LOGIC;
		memread : IN STD_LOGIC;
		address: IN INTEGER RANGE 0 TO ram_size-1;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
END instruction_memory;

ARCHITECTURE rtl OF instruction_memory IS
	TYPE MEM IS ARRAY(ram_size-1 downto 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ram_block: MEM := (others => (others => '0'));
	SIGNAL read_address_reg: INTEGER RANGE 0 to ram_size-1;
	SIGNAL read_waitreq_reg: STD_LOGIC := '1';
BEGIN
	
	mem_process: PROCESS (clk)
		file program_file : text;
		variable instr_row : line;
		variable instr : std_logic_vector(31 downto 0);
		variable counter : integer range 0 to ram_size-1 := 0;
	BEGIN
		-- initialize instruction memory with instructions from program.txt
		
		IF(now < 1 ps)THEN
			-- read from program.txt line by line and save to memory
			file_open(program_file, "program.txt", read_mode);
			while not endfile(program_file) loop
				readline(program_file, instr_row);
				read(instr_row, instr);
				ram_block(counter) <= instr;
				counter := counter + 1;
			end loop;
			file_close(program_file);
		end if;
		
		IF (clk'event AND clk = '1') THEN
			read_address_reg <= address;
		END IF;
		
	END PROCESS;
	readdata <= ram_block(read_address_reg);

	waitreq_r_proc: PROCESS (memread)
	BEGIN
		IF(memread'event AND memread = '1')THEN
			read_waitreq_reg <= '0' after mem_delay, '1' after mem_delay + clock_period;
		END IF;
	END PROCESS;
	waitrequest <= read_waitreq_reg;

END rtl;
