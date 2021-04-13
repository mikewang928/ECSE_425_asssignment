library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch is

port(
	clk : in std_logic;
	fetch_out : out std_logic_vector(31 downto 0);
	pc_out : out integer := 0;
	pc_in : in integer := 0;
	pc_select : in std_logic := '0';
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
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

signal adder_out : integer := 0;
signal pc : integer := 0;
signal next_pc : integer := 0;
signal s_memread : std_logic := '1';
signal s_waitrequest : std_logic := '1';
signal pc_stall : std_logic := '0';
signal s_readdata : std_logic_vector(31 downto 0);


begin

	pc_counter : process(clk,reset) begin
		if(reset = '1') then
			pc <= 0;
		elsif(rising_edge(clk)) and (pc_stall = '0') then
			fetch_out <= s_readdata;
			pc <= next_pc;
		elsif(rising_edge(clk)) and (pc_stall = '1') then
			fetch_out <= "00000000000000000000000000100000"; -- add r0,r0,r0 instruction
		end if;
	end process;

	i_mem : instruction_memory
	port map(
		clk => clk,
		memread => s_memread,
		address => pc,
		readdata => s_readdata,
		waitrequest => s_waitrequest
	);

	adder_out <= pc + 1;  -- increment PC by 4 bytes (1 word as the instruction memory is word-addressed)
	next_pc <= adder_out when (pc_select = '0') else pc_in;  -- mux


end arch;