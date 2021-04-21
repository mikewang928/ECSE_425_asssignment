library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cpuPipeline is
port 
(
clk : in std_logic;
reset : in std_logic;
four : INTEGER;
writeToRegisterFile : in std_logic := '0';
writeToMemoryFile : in std_logic := '0'

);

end cpuPipeline;

architecture cpuPipeline_arch of cpuPipeline is
	component instruction_memory IS
		PORT (
		clk: IN STD_LOGIC;
		memread : IN STD_LOGIC;
		address: IN INTEGER RANGE 0 TO ram_size-1;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
	end component; 
	
	component fetch IS
		port(
		clk : in std_logic;
		fetch_out : out std_logic_vector(31 downto 0);					-- feched out data
		pc_out : out integer;													-- @TODO: not impemented? 
		pc_in : in integer;														-- external pc 
		pc_src : in std_logic;  												-- source of next_pc, pc+1 (0) or external pc (1)
		pc_stall : in std_logic;  												-- whether pc needs to be stalled (1) or not (0)
		reset : in std_logic
	);
	end component; 
		
	
	
	component decode IS
		PORT (
		clk : in std_logic;
		instruction : in std_logic_vector(31 downto 0);  	-- fetched instruction
		wb_data : in std_logic_vector(31 downto 0);  	 	-- data to write back to register
		wb_reg : in std_logic_vector(4 downto 0);  			-- the register to write back to
		wb : in std_logic;  											-- whether a write back is required (1) or not (0)
		pc_in : in integer;  										-- incremented pc (pc+1) from fetch stage
		
		pc_target : out integer;  									-- target pc for branch or jump
		read_data_1 : out std_logic_vector(31 downto 0);
		read_data_2 : out std_logic_vector(31 downto 0);
		rt_data : out std_logic_vector(31 downto 0);			-- when sw this signal contains the value stored in rt
		rt_out : out std_logic_vector(4 downto 0);			-- source register 
		rs_out : out std_logic_vector(4 downto 0);			-- source register
		rd_out : out std_logic_vector(4 downto 0);			-- destination register
		branch : out std_logic;  									-- branch or jump (1) or not (0)
		
		-- EX stage control signals
		alu_op : out integer range 0 to 26;  					-- ALU operation
		reg_dst : out std_logic;  									-- selecting whether rt (0) or rd (1) is the destination register
		
		-- M stage control signals
		mem_write : out std_logic;  								-- whether write to memory is needed (1) or not (0)
		mem_read : out std_logic;  								-- whether read from memory is needed (1) or not (0)
		
		-- WB stage control signals
		reg_write : out std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg : out std_logic  								-- selecting whether writeback data is read from memory (1) or from ALU result (0)
		
	);
	end component;
	

	component Forwarding IS
		port
        ( reg_rs_ex : in std_logic_vector(4 downto 0)
        ; reg_rt_ex : in std_logic_vector(4 downto 0)
        ; reg_rd_mem  : in std_logic_vector(4 downto 0)
        ; reg_rd_wb   : in std_logic_vector(4 downto 0)
        ; reg_wen_mem       : in  std_logic
        ; reg_wen_wb        : in  std_logic

		  
		  ; data_1_forward_mem : out std_logic_vector(1 downto 0)
		  ; data_2_forward_mem : out std_logic_vector(1 downto 0)
		  ; data_1_forward_wb : out std_logic_vector(1 downto 0)
		  ; data_2_forward_wb : out std_logic_vector(1 downto 0)
        );
	end component; 
		
	
	
	component Memory IS
		port(
		clk: in std_logic;
		mem_write_in : in std_logic;  								-- whether write to memory is needed (1) or not (0)
		mem_data_write : in std_logic_vector(31 downto 0); 	-- data write into the memory
		mem_read_in : in std_logic;  									-- whether read from memory is needed (1) or not (0)
		alu_in : in std_logic_vector (31 downto 0); 				-- address that we want to read/write
		
		-- control signals propogated to the next stage
		reg_write_in : in std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_in : in std_logic; 								-- selecting whether writeback data is read
		

		reg_write_out : out std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_out : out std_logic; 								-- selecting whether writeback data is read
		
		read_data : out std_logic_vector(31 downto 0);
		alu_out : out std_logic_vector (31 downto 0)
	);
	end component; 
	
	
	component WriteBack IS
		port(
		clk:				in std_logic;
		reg_write_in:			in std_logic;
		mem_to_reg_in:			in std_logic;
		read_data:		in std_logic_vector(31 downto 0);
		alu_in:		in std_logic_vector(31 downto 0);
		reg_to_write_in: in std_logic_vector(4 downto 0); -- which register to write to
		
		mem_to_reg_out:	out std_logic;
		write_data:			out std_logic_vector(31 downto 0);
		reg_to_write_out: out std_logic_vector(4 downto 0) -- pass to the decode stage
	);
	end component; 
	
	
	component hazard_detection IS
		 port ( mem_read_ex : in  std_logic
         ; reg_rt_ex   : in std_logic_vector(4 downto 0)
         ; reg_rs_id   : in std_logic_vector(4 downto 0)
         ; reg_rt_id   : in std_logic_vector(4 downto 0)
         ; insert_stall_mux: out  std_logic
			; if_id_write : out std_logic 
        );
	end component; 
	
	
	-- signals for hazard_detection
	signal reg_rt_ex_hazard_s  : in std_logic_vector(4 downto 0);
	signal reg_rs_id_hazard_s   : in std_logic_vector(4 downto 0);
	signal reg_rt_id_hazard_s   : in std_logic_vector(4 downto 0);
	signal insert_stall_mux_hazard_s : out  std_logic;
	signal if_id_write_hazard_s : out std_logic ;
	
	
	
	-- signals for writeback 
	signal reg_write_in_wb_s:			in std_logic;
	signal mem_to_reg_in_wb_s:			in std_logic;
	signal read_data_wb_s:		in std_logic_vector(31 downto 0);
	signal alu_in_wb_s:		in std_logic_vector(31 downto 0);
	signal reg_to_write_in_wb_s: in std_logic_vector(4 downto 0); -- which register to write to

	signal mem_to_reg_out_wb_s:	out std_logic;
	signal write_data_wb_s:			out std_logic_vector(31 downto 0);
	signal reg_to_write_out_wb_s: out std_logic_vector(4 downto 0) -- pass to the decode stage
	
	
	-- signals for Memory
	signal mem_write_in_MEM_s : in std_logic;  								-- whether write to memory is needed (1) or not (0)
	signal mem_data_write_MEM_s  : in std_logic_vector(31 downto 0); 	-- data write into the memory
	signal mem_read_in_MEM_s  : in std_logic;  									-- whether read from memory is needed (1) or not (0)
	signal alu_in_MEM_s  : in std_logic_vector (31 downto 0); 				-- address that we want to read/write
	signal reg_write_in_MEM_s  : in std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
	signal mem_to_reg_in_MEM_s  : in std_logic; 								-- selecting whether writeback data is read
	signal reg_write_out_MEM_s  : out std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
	signal mem_to_reg_out_MEM_s  : out std_logic; 								-- selecting whether writeback data is read
	signal read_data_MEM_s  : out std_logic_vector(31 downto 0);
	signal alu_out_MEM_s  : out std_logic_vector (31 downto 0);


	-- signals for Forwarding
	signal reg_rs_ex_forwarding_s : in std_logic_vector(4 downto 0)
	signal reg_rt_ex_forwarding_s  : in std_logic_vector(4 downto 0)
	signal reg_rd_mem_forwarding_s   : in std_logic_vector(4 downto 0)
	signal reg_rd_wb_forwarding_s    : in std_logic_vector(4 downto 0)
	signal reg_wen_mem_forwarding_s  : in  std_logic
	signal reg_wen_wb_forwarding_s   : in  std_logic
	signal data_1_forward_mem_forwarding_s  : out std_logic_vector(1 downto 0)
	signal data_2_forward_mem_forwarding_s  : out std_logic_vector(1 downto 0)
	signal data_1_forward_wb_forwarding_s  : out std_logic_vector(1 downto 0)
	signal data_2_forward_wb_forwarding_s  : out std_logic_vector(1 downto 0)
	
	
	
	-- signals for decode
	signal instruction_decode_s : in std_logic_vector(31 downto 0);  	-- fetched instruction
	signal wb_data_decode_s : in std_logic_vector(31 downto 0);  	 	-- data to write back to register
	signal wb_reg_decode_s : in std_logic_vector(4 downto 0);  			-- the register to write back to
	signal wb_decode_s : in std_logic;  											-- whether a write back is required (1) or not (0)
	signal pc_in_decode_s : in integer;  										-- incremented pc (pc+1) from fetch stage
	signal pc_target_decode_s : out integer;  									-- target pc for branch or jump
	signal read_data_1_decode_s : out std_logic_vector(31 downto 0);
	signal read_data_2_decode_s : out std_logic_vector(31 downto 0);
	signal rt_data_decode_s : out std_logic_vector(31 downto 0);			-- when sw this signal contains the value stored in rt
	signal rt_out_decode_s : out std_logic_vector(4 downto 0);			-- source register 
	signal rs_out_decode_s : out std_logic_vector(4 downto 0);			-- source register
	signal rd_out_decode_s : out std_logic_vector(4 downto 0);			-- destination register
	signal branch_decode_s : out std_logic;  									-- branch or jump (1) or not (0)
	signal alu_op_decode_s : out integer range 0 to 26;  					-- ALU operation
	signal reg_dst_decode_s : out std_logic;  									-- selecting whether rt (0) or rd (1) is the destination register
	signal mem_write_decode_s : out std_logic;  								-- whether write to memory is needed (1) or not (0)
	signal mem_read_decode_s : out std_logic;  								-- whether read from memory is needed (1) or not (0)
	signal reg_write_decode_s : out std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
	signal mem_to_reg_decode_s : out std_logic  								-- selecting whether writeback data is read from memory (1) or from ALU result (0)
	
	
	-- signals for fetch
	signal fetch_out_detch_s : out std_logic_vector(31 downto 0);					-- feched out data
	signal pc_out_detch_s  : out integer;													-- @TODO: not impemented? 
	signal pc_in_detch_s  : in integer;														-- external pc 
	signal pc_src_detch_s  : in std_logic;  												-- source of next_pc, pc+1 (0) or external pc (1)
	signal pc_stall_detch_s  : in std_logic;  												-- whether pc needs to be stalled (1) or not (0)
	signal reset_detch_s  : in std_logic
	
	-- signals for instruction memory
	signal memread_IM_S : IN STD_LOGIC;
	signal address_IM_S : IN INTEGER RANGE 0 TO ram_size-1;
	signal readdata_IM_S : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
	signal waitrequest_IM_S : OUT STD_LOGIC
 

begin


IM: instruction_memory
port map( 
	memread => memread_IM_S,
	address => address_IM_S,
	readdata => readdata_IM_S,
	waitrequest => waitrequest_IM_S
);


Fth: fetch
port map(
	fetch_out => fetch_out_detch_s,
	pc_out => pc_out_detch_s,
	pc_in => pc_in_detch_s,
	pc_src => pc_src_detch_s,
	pc_stall => pc_stall_detch_s,
	reset => reset_detch_s
);



Dcd: decode
port map(
	clk  => 
	instruction => instruction_decode_s,
	wb_data => wb_data_decode_s,
	wb_reg => wb_reg_decode_s,
	wb => wb_decode_s,
	pc_in => pc_in_decode_s,
	pc_target => pc_target_decode_s,
	read_data_1 => read_data_1_decode_s,
	read_data_2 => read_data_2_decode_s,
	rt_data => rt_data_decode_s,
	rt_out => rt_out_decode_s,
	rs_out => rs_out_decode_s,
	rd_out => rd_out_decode_s,
	branch => branch_decode_s,
	alu_op => alu_op_decode_s,
	reg_dst => reg_dst_decode_s,
	mem_write => mem_write_decode_s,
	mem_read => mem_read_decode_s,
	reg_write => reg_write_decode_s,
	mem_to_reg => mem_to_reg_decode_s
);



Fwd： Forwarding
port map(
	reg_rs_ex => reg_rs_ex_forwarding_s,
	reg_rt_ex => reg_rt_ex_forwarding_s,
	reg_rd_mem => reg_rd_mem_forwarding_s,
	reg_rd_wb => reg_rd_wb_forwarding_s,
	reg_wen_mem => reg_wen_mem_forwarding_s,
	reg_wen_wb => reg_wen_wb_forwarding_s,
	data_1_forward_mem => data_1_forward_mem_forwarding_s,
	data_2_forward_mem => data_2_forward_mem_forwarding_s,
	data_1_forward_wb => data_1_forward_wb_forwarding_s,
	data_2_forward_wb => data_2_forward_wb_forwarding_s

);
	
	
MEM； Memory
port map(
	clk => clk,
	mem_write_in => mem_write_in_MEM_s,
	mem_data_write => mem_data_write_MEM_s,
	mem_read_in => mem_read_in_MEM_s,
	alu_in => alu_in_MEM_s,
	reg_write_in => reg_write_in_MEM_s,
	mem_to_reg_in => mem_to_reg_in_MEM_s,
	reg_write_out => reg_write_out_MEM_s,
	mem_to_reg_out => mem_to_reg_out_MEM_s,
	read_data => read_data_MEM_s,
	alu_out => alu_out_MEM_s
);




WB: WriteBack
port map(
	clk => clk,
	reg_write_in => reg_write_in_wb_s,
	mem_to_reg_in => mem_to_reg_in_wb_s,
	read_data => read_data_wb_s,
	alu_in => alu_in_wb_s,
	reg_to_write_in => reg_to_write_in_wb_s,
	mem_to_reg_out => mem_to_reg_out_wb_s,
	write_data => write_data_wb_s,
	reg_to_write_out => reg_to_write_out_wb_s
);





HD: hazard_detection
port map(
	reg_rt_ex => reg_rt_ex_hazard_s,
	reg_rs_id => reg_rs_id_hazard_s,
	reg_rt_id => reg_rt_id_hazard_s,
	insert_stall_mux => insert_stall_mux_hazard_s,
	if_id_write => if_id_write_hazard_s
);




process(EXMEMStructuralStall)
begin
if EXMEMStructuralStall = '1' then 
	pcStall <= '1';
else 
	pcStall <= '0';
end if;

end process;

process (clk)
begin

if (clk'event and clk = '1') then
--PIPELINED VALUE 
--IFID 
IFIDaddress <= address;
IFIDinstruction <= instruction;

-- IDEX
IDEXaddress <= IFIDaddress;
IDEXrb <= rb;

--FOR IMMEDIATE VALUES
if RType = '1' then
	IDEXrd <= rd;
-- FOR JAL
elsif ALUOP = "11010" then
	IDEXrd <= "11111";
else
	IDEXrd <= rt;
end if;

--FOR SHIFT INSTRUCTIONS
if Shift = '1' then
	IDEXra <= rb;
else
	IDEXra <= ra;
end if;

--FOR JUMP INSTRUCTIONS
if JType = '1' then
	IDEXimmediate <= "000000" & IFIDinstruction(25 downto 0);
else
	IDEXimmediate <= immediate_out;
end if;

IDEXALU1srcO <= ALU1srcO;
IDEXALU2srcO <= ALU2srcO;
IDEXMemReadO <= MemReadO;
IDEXMeMWriteO <= MemWriteO;
IDEXRegWriteO <= RegWriteO;
IDEXMemToRegO <= MemToRegO;
IDEXAluOp <= ALUOp;

	
--EXMEM 
EXMEMBranch <= zeroOutput; 
EXMEMrd <= IDEXrd;
EXMEMMemReadO <= IDEXMemReadO;
EXMEMMeMWriteO <= IDEXMeMWriteO;
EXMEMRegWriteO <= IDEXRegWriteO;
EXMEMMemToRegO <= IDEXMemToRegO;
EXMEMaluOutput <= aluOutput;
EXMEMStructuralStall <= IDEXStructuralStall;
structuralStall <= EXMEMStructuralStall;
--FOR JAL
if IDEXAluOp = "11010" then
	EXMEMregisterOutput <= IDEXaddress;
	ctrl_jal <= '1';
else
	EXMEMregisterOutput <= IDEXrb;
	ctrl_jal <= '0';
end if;
	
	
end if ;
end process;

-- controller values
opcodeInput <= IFIDinstruction(31 downto 26);
functInput <= IFIDinstruction(5 downto 0);
-- register values
rs <= IFIDinstruction(25 downto 21);
rt <= IFIDinstruction(20 downto 16);
rd <= IFIDinstruction(15 downto 11);
shamnt <= IFIDinstruction(10 downto 6);
-- EXTENDED
immediate <= IFIDinstruction(15 downto 0);
-- MIGHT NEED TO PUT WRITE ENABLE HERE LATER 
-- AND JUMP ADDRESS HERE 

end cpuPipeline_arch;