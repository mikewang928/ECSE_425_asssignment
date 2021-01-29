LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;

ENTITY fsm_tb IS
END fsm_tb;

ARCHITECTURE behaviour OF fsm_tb IS

COMPONENT comments_fsm IS
PORT (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
END COMPONENT;

--The input signals with their initial values
SIGNAL clk, s_reset, s_output: STD_LOGIC := '0';
SIGNAL s_input: std_logic_vector(7 downto 0) := (others => '0');

CONSTANT clk_period : time := 1 ns;
CONSTANT SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
CONSTANT STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
CONSTANT NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";
CONSTANT T: std_logic_vector(7 downto 0) := "01010100";
CONSTANT H: std_logic_vector(7 downto 0) := "01001000";
CONSTANT I: std_logic_vector(7 downto 0) := "01001001";
CONSTANT S: std_logic_vector(7 downto 0) := "01010011";
CONSTANT SPACE: std_logic_vector(7 downto 0) := "00100000";
CONSTANT A: std_logic_vector(7 downto 0) := "01000001";
CONSTANT C: std_logic_vector(7 downto 0) := "01000011";
CONSTANT O: std_logic_vector(7 downto 0) := "01001111";
CONSTANT M: std_logic_vector(7 downto 0) := "01001101";
CONSTANT E: std_logic_vector(7 downto 0) := "01000101";
CONSTANT N: std_logic_vector(7 downto 0) := "01001110";
CONSTANT D: std_logic_vector(7 downto 0) := "01000100";

BEGIN
dut: comments_fsm
PORT MAP(clk, s_reset, s_input, s_output);

 --clock process
clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
 
--TODO: Thoroughly test your FSM
stim_process: PROCESS
BEGIN    
	REPORT "Example case, reading a meaningless character";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;
	REPORT "_______________________";

	s_reset <='1';
	WAIT FOR 1*clk_period;
	s_reset <='0';
	WAIT FOR 1*clk_period;
	


	REPORT "Case 1, reading: '//comment \n end'";
	s_input <= C;
	WAIT FOR 1 * clk_period;
	
   s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 1: the output should be '0' SLASH_CHARACTER1" SEVERITY ERROR;
   s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 1: the output should be '0' SLASH_CHARACTER2" SEVERITY ERROR;
	
	s_input <= C;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' C" SEVERITY ERROR;
	s_input <= O;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' O" SEVERITY ERROR;
	s_input <= M;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' M" SEVERITY ERROR;
	s_input <= M;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' M" SEVERITY ERROR;
	s_input <= E;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' E" SEVERITY ERROR;
	s_input <= N;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' N" SEVERITY ERROR;
	s_input <= T;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' T" SEVERITY ERROR;

	s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 1: the output should be '1' NEW_LINE_CHARACTER" SEVERITY ERROR;

	s_input <= E;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 1: the output should be '0' E" SEVERITY ERROR;
	s_input <= N;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 1: the output should be '0' N" SEVERITY ERROR;
	s_input <= D;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 1: the output should be '0' D" SEVERITY ERROR;
	REPORT "_______________________";

	s_reset <='1';
	WAIT FOR 1*clk_period;
	s_reset <='0';
	WAIT FOR 1*clk_period;


	
	

	REPORT "Case 2, reading: '/*comment \n end */ \n'";
   s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 2: the output should be '0' SLASH_CHARACTER1" SEVERITY ERROR;
   s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 2: the output should be '0' STAR_CHARACTER1" SEVERITY ERROR;
	
	s_input <= C;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' C" SEVERITY ERROR;
	s_input <= O;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' O" SEVERITY ERROR;
	s_input <= M;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' M" SEVERITY ERROR;
	s_input <= M;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' M" SEVERITY ERROR;
	s_input <= E;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' E" SEVERITY ERROR;
	s_input <= N;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' N" SEVERITY ERROR;
	s_input <= T;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' T" SEVERITY ERROR;

	s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' NEW_LINE_CHARACTER1" SEVERITY ERROR;

	s_input <= E;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' E" SEVERITY ERROR;
	s_input <= N;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' N" SEVERITY ERROR;
	s_input <= D;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' D" SEVERITY ERROR;
	
	s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' STAR_CHARACTER2" SEVERITY ERROR;
	s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "Case 2: the output should be '1' SLASH_CHARACTER2" SEVERITY ERROR;
	
	s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "Case 2: the output should be '0' NEW_LINE_CHARACTER2" SEVERITY ERROR;
	
	REPORT "_______________________";
	
	
	
	WAIT;
END PROCESS stim_process;
END;
