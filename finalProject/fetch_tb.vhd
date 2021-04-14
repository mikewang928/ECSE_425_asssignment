LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY fetch_tb IS
END fetch_tb;

ARCHITECTURE behaviour OF fetch_tb IS

--Declare the component that you are testing:
    COMPONENT fetch IS
		port(
			clk : in std_logic;
			fetch_out : out std_logic_vector(31 downto 0);
			pc_out : out integer;
			pc_in : in integer;
			pc_src : in std_logic;  -- source of next_pc, pc+1 (0) or external pc (1)
			pc_stall : in std_logic;  -- whether pc needs to be stalled (1) or not (0)
			reset : in std_logic
		);
    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
	signal fetch_out : std_logic_vector(31 downto 0) := (others=>'0');
	signal pc_out : integer := 0;
	signal pc_in : integer := 0;
	signal pc_src : std_logic := '0';
	signal pc_stall : std_logic := '0';
	signal reset : std_logic := '0';

BEGIN

    --dut => Device Under Test
    dut: fetch 
		PORT MAP(
			clk,
			fetch_out,
			pc_out,
			pc_in,
			pc_src,
			pc_stall,
			reset
		);

    clk_process : process
    BEGIN
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process;

    test_process : process
    BEGIN

        wait for 5*clk_period;
		pc_stall <= '1';
		
		wait;

    END PROCESS;
END;