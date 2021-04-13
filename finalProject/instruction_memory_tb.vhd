LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY instruction_memory_tb IS
END instruction_memory_tb;

ARCHITECTURE behaviour OF instruction_memory_tb IS

--Declare the component that you are testing:
    COMPONENT instruction_memory IS
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
    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    signal address: INTEGER RANGE 0 TO 8192-1;
    signal memread: STD_LOGIC := '0';
    signal readdata: STD_LOGIC_VECTOR (31 DOWNTO 0) := (others => '0');
    signal waitrequest: STD_LOGIC;

BEGIN

    --dut => Device Under Test
    dut: instruction_memory 
		PORT MAP(
			clk,
			memread,
			address,
			readdata,
			waitrequest
		);

    clk_process : process
    BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    test_process : process
    BEGIN
		address <= 0;
        memread <= '1';
		wait for 5*clk_period;
        address <= 1;
		wait for 5*clk_period;
        address <= 2;
		wait for 5*clk_period;
        address <= 3;
		wait for 5*clk_period;
        
        
        wait;

    END PROCESS;
END;