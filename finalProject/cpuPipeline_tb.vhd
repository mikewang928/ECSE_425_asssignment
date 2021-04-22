library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric.all;

entity cpuPipeline_tb is
end entity;

architecture arch of cpu_Pipeline_tb is
	component cpuPipeline is
	port 
	(
	clk : in std_logic;
	reset : in std_logic;
	four : INTEGER;
	writeToRegisterFile : in std_logic := '0';
	writeToMemoryFile : in std_logic := '0'
	);

	end component;

	signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
    signal reset : std_logic := '0';
    signal four : integer := 0;
    signal writeToRegisterFile : std_logic := '0';
    signal writeToMemoryFile : std_logic := '0';

begin
	l1: cpuPipeline port MAP(
    		clk => clk,
            reset => reset,
            four => four,
            writeToRegisterFile => writeToRegisterFile,
            writeToMemoryFile => writeToMemoryFile
    		);

    		clk_process : process
	    	begin
	        clk <= '0';
	        wait for clk_period/2;
	        clk <= '1';
	        wait for clk_period/2;
	    	end process;
end



