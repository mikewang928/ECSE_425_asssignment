LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY memory_tb IS
END memory_tb;

ARCHITECTURE Behaviour of memory_tb IS

signal clk: std_logic := '0';
constant clk_period: time := 1 ns;
signal mem_write_in : std_logic;  								-- whether write to memory is needed (1) or not (0)
signal mem_data_write : std_logic_vector(31 downto 0); 	-- data write into the memory
signal mem_read_in : std_logic;  									-- whether read from memory is needed (1) or not (0)
signal alu_in : std_logic_vector (31 downto 0); 			--address that we want to read/write
		
		-- control signals propogated to the next stage
signal reg_write_in : std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
signal mem_to_reg_in : std_logic; 								-- selecting whether writeback data is read
		

signal reg_write_out : std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
signal mem_to_reg_out : std_logic; 								-- selecting whether writeback data is read
		
signal read_data : std_logic_vector(31 downto 0);
signal alu_out : std_logic_vector (31 downto 0);



COMPONENT Memory
	generic(
			ram_size:		integer := 8192 -- There're 8192 lines in the data memory
--			clock_period:	time := 1 ns			
--			mem_delay:		time := 1 ns;
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
END COMPONENT;


    BEGIN

    	label1: Memory port 
		MAP(
    		clk => clk,
		mem_write_in => mem_write_in,
		mem_data_write => mem_data_write,								-- whether read from memory is needed (1) or not (0)
		mem_read_in => mem_read_in,
		alu_in => alu_in,--address that we want to read/write
		
		-- control signals propogated to the next stage
		reg_write_in => reg_write_in,								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_in => mem_to_reg_in,								-- selecting whether writeback data is read
		

		reg_write_out => reg_write_out,							-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_out => mem_to_reg_out,							-- selecting whether writeback data is read
		
		read_data => read_data,
		alu_out => alu_out
    		);
			
			
      clk_process : process
    	BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    	END PROCESS;

    	test_process : process
    	begin
		mem_write_in <= '0';
		mem_read_in <= '0';
		alu_in <= "00000000000000000000000000000000";
		mem_data_write <= "11100010101010101010101010101010";
		wait for clk_period;
		mem_write_in <= '0';
		mem_read_in <= '1';
		alu_in <= "00000000000000000000000000000100";
		mem_data_write <= "11100010101010101010101010101010";		
		wait for clk_period;
		mem_write_in <= '1';
		mem_read_in <= '0';
		alu_in <= "00000000000000000000000000001000";
		mem_data_write <= "11100010101010101010101010101010";
		wait for clk_period;
    	END PROCESS;

    END Behaviour;