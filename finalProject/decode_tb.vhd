LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY decode_tb IS
END decode_tb;

ARCHITECTURE behaviour OF decode_tb IS

--Declare the component that you are testing:
    COMPONENT decode IS
		PORT (
			clk : in std_logic;
			instruction : in std_logic_vector(31 downto 0);  -- fetched instruction
			wb_data : in std_logic_vector(31 downto 0);  -- data to write back to register
			wb_reg : in std_logic_vector(4 downto 0);  -- the register to write back to
			wb : in std_logic;  -- whether a write back is required (1) or not (0)
			pc_in : in integer;  -- incremented pc (pc+1) from fetch stage
			
			pc_target : out integer;  -- target pc for branch or jump
			read_data_1 : out std_logic_vector(31 downto 0);
			read_data_2 : out std_logic_vector(31 downto 0);
			rt_out : out std_logic_vector(4 downto 0);
			rs_out : out std_logic_vector(4 downto 0);
			rd_out : out std_logic_vector(4 downto 0);
			branch : out std_logic;  -- branch or jump (1) or not (0)
			
			-- EX stage control signals
			alu_op : out integer range 0 to 26;  -- ALU operation
			reg_dst : out std_logic;  -- selecting whether rt (0) or rd (1) is the destination register
			
			-- M stage control signals
			mem_write : out std_logic;  -- whether write to memory is needed (1) or not (0)
			mem_read : out std_logic;  -- whether read from memory is needed (1) or not (0)
			
			-- WB stage control signals
			reg_write : out std_logic;  -- signal indicating whether a write to register is needed (1) or not (0)
			mem_to_reg : out std_logic  -- selecting whether writeback data is read from memory (1) or from ALU result (0)

		);
    END COMPONENT;

    --all the input signals with initial values
    signal clk : std_logic := '0';
    constant clk_period : time := 1 ns;
	signal instruction : std_logic_vector(31 downto 0);  -- fetched instruction
	signal wb_data : std_logic_vector(31 downto 0);  -- data to write back to register
	signal wb_reg : std_logic_vector(4 downto 0);  -- the register to write back to
	signal wb : std_logic;  -- whether a write back is required (1) or not (0)
	signal pc_in : integer;  -- incremented pc from fetch stage
			
	signal pc_target : integer;  -- pc bypass output
	signal read_data_1 : std_logic_vector(31 downto 0);
	signal read_data_2 : std_logic_vector(31 downto 0);
	signal rt_out : std_logic_vector(4 downto 0);
	signal rd_out : std_logic_vector(4 downto 0);		
	signal rs_out : std_logic_vector(4 downto 0);	
	signal branch : std_logic;  -- branch or jump (1) or not (0)
			
			-- EX stage control signals
	signal alu_op : integer range 0 to 26;  -- ALU operation
	signal reg_dst : std_logic;  -- selecting whether rt (0) or rd (1) is the destination register
			
			-- M stage control signals
	signal mem_write : std_logic;  -- whether write to memory is needed (1) or not (0)
	signal mem_read : std_logic;  -- whether read from memory is needed (1) or not (0)
			
			-- WB stage control signals
	signal reg_write : std_logic;  -- signal indicating whether a write to register is needed (1) or not (0)
	signal mem_to_reg : std_logic;  -- selecting whether writeback data is read from memory (1) or from ALU result (0)
			


BEGIN

    --dut => Device Under Test
    dut: decode 
		PORT MAP(
			clk,
			instruction,
			wb_data,
			wb_reg,
			wb,
			pc_in,	
			pc_target,
			read_data_1,
			read_data_2,	
			rt_out,
			rs_out,
			rd_out,
			branch,			
			alu_op,
			reg_dst,
			mem_write,
			mem_read,
			reg_write,
			mem_to_reg
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
		instruction <= x"00000000";
		wb <= '0';
		wait;
    END PROCESS;
END;