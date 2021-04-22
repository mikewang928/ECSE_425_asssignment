library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- @TODO: branch hazard
entity fetch is
	port(
		clk : in std_logic;
		fetch_out : out std_logic_vector(31 downto 0);					-- feched out data
		pc_out : out integer;													-- @TODO: not impemented? 
		pc_in : in integer;														-- external pc 
		pc_src : in std_logic;  												-- source of next_pc, pc+1 (0) or external pc (1)
		pc_stall : in std_logic;  												-- whether pc needs to be stalled (1) or not (0)
		reset : in std_logic
	);
end fetch;

architecture arch of fetch is

component instruction_memory is
	generic(
		ram_size : INTEGER := 8192;
		mem_delay : time := 1 ns;
		clock_period : time := 1 ns
	);
	port(
		clk: IN STD_LOGIC; 
		memread : IN STD_LOGIC; 
		address: IN INTEGER RANGE 0 TO ram_size-1; 
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0); --instrcution is prganized word-wise
		waitrequest: OUT STD_LOGIC 
	);
end component;

signal adder_out : integer := 0; 										-- normal next instruction counter (pc + 1)
signal pc : integer := 0; 													-- program counter 
signal next_pc : integer := 0; 											-- the next instrcution counter (can be either normal or external(branch))
signal s_memread : std_logic := '1'; 									 
signal s_waitrequest : std_logic := '1';
signal s_readdata : std_logic_vector(31 downto 0);					-- data extracted from mem 

begin

	-- control pc counter (reset and normal)
	pc_control : process(clk, pc_stall, reset) begin
		-- reset pc to 0
		if reset = '1' then
			pc <= 0;
		else
		-- increament pc every clock cycle (when pc_stall = '1' no increament)
			if rising_edge(clk) and pc_stall = '0' then
				pc <= next_pc;
			else
				pc <= pc;
			end if;
			
		end if;
	end process;
	
	
	-- control instruction output, not synchronous to ensure no delay in fetch_out 
	fetch_out_control : process(s_readdata, pc_stall, reset) begin
		if reset = '1' then
			fetch_out <= "00000000000000000000000000100000"; -- add r0,r0,r0 instruction
		else
			fetch_out <= s_readdata;
		end if;
	end process;
	
	
	
	i_mem : instruction_memory
	-- linking ports from instruction memory and fetch
	port map(
		clk => clk,
		memread => s_memread,
		address => pc,
		readdata => s_readdata,
		waitrequest => s_waitrequest
	);

	adder_out <= pc + 1;  -- increment PC by 4 bytes (1 word as the instruction memory is word-addressed)
	next_pc <= adder_out when (pc_src = '0') else pc_in;  -- mux


end arch;