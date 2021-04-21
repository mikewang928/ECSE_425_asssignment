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

component instructionFetchStage IS
	port(
		clk : in std_logic;
		muxInput0 : in std_logic_vector(31 downto 0);
		selectInputs : in std_logic;
		four : in INTEGER;
		structuralStall : IN STD_LOGIC;
		pcStall : IN STD_LOGIC;

		selectOutput : out std_logic_vector(31 downto 0);
		instructionMemoryOutput : out std_logic_vector(31 downto 0)
		);
		
	end component;
		
component controller is
	port(clk : in std_logic;
		 opcode : in std_logic_vector(5 downto 0);
		 funct : in std_logic_vector(5 downto 0);
		 branch: in std_logic;
		 oldBranch: in std_logic;
		 ALU1src : out STD_LOGIC;
		 ALU2src : out STD_LOGIC;
		 MemRead : out STD_LOGIC;
		 MemWrite : out STD_LOGIC;
		 RegWrite : out STD_LOGIC;
		 MemToReg : out STD_LOGIC;
		 RType : out std_logic;
		 JType : out std_logic;
		 Shift : out std_logic;
		 structuralStall : out std_logic;
		 ALUOp : out STD_LOGIC_VECTOR(4 downto 0)
		 );
end component;

component register_file is

PORT(
		
		clock: IN STD_LOGIC;
		rs: IN STD_LOGIC_VECTOR (4 downto 0);
		rt: IN STD_LOGIC_VECTOR (4 downto 0);
		write_enable: IN STD_LOGIC; 
		rd: IN STD_LOGIC_VECTOR (4 downto 0);
		rd_data: IN STD_LOGIC_VECTOR (31 downto 0); 
		writeToText : IN STD_LOGIC := '0';

		ra_data: OUT STD_LOGIC_VECTOR (31 downto 0);
		rb_data: OUT STD_LOGIC_VECTOR (31 downto 0) 
	);

end component;


component signextender is 
	PORT (
        immediate_in: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        immediate_out: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
    );
end component;
	
component mux is
port(
	 input0 : in std_logic_vector(31 downto 0);
	 input1 : in std_logic_vector(31 downto 0);
	 selectInput : in std_logic;
	 selectOutput : out std_logic_vector(31 downto 0)
	 );
	 	
	
end component;

component alu is
 Port ( input_a : in STD_LOGIC_VECTOR (31 downto 0);
 input_b : in STD_LOGIC_VECTOR (31 downto 0);
 SEL : in STD_LOGIC_VECTOR (4 downto 0);
 out_alu : out STD_LOGIC_VECTOR(31 downto 0));
end component;

component zero is
port (input_a : in std_logic_vector (31 downto 0);
	input_b : in std_logic_vector (31 downto 0);
	optype : in std_logic_vector (4 downto 0);
	result: out std_logic
  );
end component;

--MEMORY OBJ FOR MEM STAGE
COMPONENT memory IS
	GENERIC(
		ram_size : INTEGER := 8192;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC := '0';
		memread: IN STD_LOGIC := '0';
		writeToText : IN STD_LOGIC := '0';
		
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
END COMPONENT;

--MEM STAGE
component mem is  
port (clk: in std_logic;
	-- Control lines
	ctrl_write : in std_logic;
	ctrl_read: in std_logic;
	ctrl_memtoreg_in: in std_logic;
	ctrl_memtoreg_out: out std_logic;
	ctrl_regwrite_in: in std_logic;
	ctrl_regwrite_out: out std_logic;
	ctrl_jal: in std_logic;

	--Ports of stage
	alu_in : in std_logic_vector (31 downto 0);
	alu_out : out std_logic_vector (31 downto 0);
	mem_data_in: in std_logic_vector (31 downto 0);
	mem_data_out: out std_logic_vector (31 downto 0);
	write_addr_in: in std_logic_vector (4 downto 0);
	write_addr_out: out std_logic_vector (4 downto 0);
	
	--Memory signals
	writedata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
	address: OUT INTEGER RANGE 0 TO 32768 -1;
	memwrite: OUT STD_LOGIC := '0';
	memread: OUT STD_LOGIC := '0';
	readdata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
	waitrequest: IN STD_LOGIC
	
  );
end component;
 
component wb is
port (ctrl_memtoreg_in: in std_logic;
	ctrl_regwrite_in: in std_logic;
	ctrl_regwrite_out: out std_logic;
	
	alu_in : in std_logic_vector (31 downto 0);
	mem_in: in std_logic_vector (31 downto 0);
	mux_out : out std_logic_vector (31 downto 0);
	write_addr_in: in std_logic_vector (4 downto 0);
	write_addr_out: out std_logic_vector (4 downto 0)
);
 end component;

 
 -- STALL SIGNALS 
signal IDEXStructuralStall : std_logic;
signal EXMEMStructuralStall : std_logic;
signal structuralStall : std_logic;
signal pcStall : std_logic;
-- TEST SIGNALS 
signal muxInput : STD_LOGIC_VECTOR(31 downto 0) := "00000000000000000000000000000000";
signal selectInput : std_logic := '1';
signal fourInt : INTEGER := 4;

-- PIPELINE IFID
--address goes to both IFID and IDEX
signal address : std_logic_vector(31 downto 0);
signal instruction : std_logic_vector(31 downto 0);
signal IFIDaddress : std_logic_vector(31 downto 0);
signal IFIDinstruction : std_logic_vector(31 downto 0);

--PIPELINE IDEX

signal IDEXaddress : std_logic_vector(31 downto 0);
signal IDEXra : std_logic_vector(31 downto 0);
signal IDEXrb : std_logic_vector(31 downto 0);
signal IDEXimmediate : std_logic_vector(31 downto 0);
signal IDEXrd : std_logic_vector (4 downto 0);
signal IDEXALU1srcO, IDEXALU2srcO, IDEXMemReadO, IDEXMeMWriteO, IDEXRegWriteO, IDEXMemToRegO: std_logic;
signal IDEXAluOp : std_logic_vector (4 downto 0);


-- SIGNALS FOR CONTROLLER
signal opcodeInput,functInput : std_logic_vector(5 downto 0);
signal ALU1srcO,ALU2srcO,MemReadO,MemWriteO,RegWriteO,MemToRegO,RType,Jtype,Shift: std_logic;
signal ALUOp : std_logic_vector(4 downto 0);

-- SIGNALS FOR REGISTERS
signal rs,rt,rd,WBrd : std_logic_vector (4 downto 0);
signal rd_data: std_logic_vector(31 downto 0);
signal write_enable : std_logic;
signal ra,rb : std_logic_vector(31 downto 0);
signal shamnt : std_logic_vector(4 downto 0);

signal immediate : std_logic_vector(15 downto 0); 
signal immediate_out : std_logic_vector(31 downto 0);

-- SIGNALS FOR EXECUTE STAGE  
signal muxOutput1 : std_logic_vector(31 downto 0);
signal muxOutput2 : std_logic_vector(31 downto 0);
signal aluOutput : std_logic_vector(31 downto 0);
signal zeroOutput : std_logic;

-- SIGNALS FOR EXMEM
signal EXMEMBranch : std_logic; -- need the zero variable 
signal ctrl_jal : std_logic;
signal EXMEMaluOutput : std_logic_vector(31 downto 0);
signal EXMEMregisterOutput : std_logic_vector(31 downto 0);
signal EXMEMrd : std_logic_vector(4 downto 0);
signal EXMEMMemReadO, EXMEMMeMWriteO, EXMEMRegWriteO, EXMEMMemToRegO: std_logic;

-- MEM SIGNALS 
signal MEMWBmemOutput : std_logic_vector(31 downto 0);
signal MEMWBaluOutput : std_logic_vector(31 downto 0);
signal MEMWBrd : std_logic_vector(4 downto 0);
signal memtoReg : std_logic;
signal regWrite : std_logic;

signal	MEMwritedata : std_logic_vector(31 downto 0);
signal	MEMaddress : INTEGER;
signal	MEMmemwrite : STD_LOGIC;
signal	MEMmemread  : STD_LOGIC;
signal	MEMreaddata : std_logic_vector(31 downto 0);
signal	MEMwaitrequest : STD_LOGIC;

begin

IFS : instructionFetchStage
port map(
	clk => clk,
	muxInput0 => EXMEMaluOutput,
	selectInputs => EXMEMBranch,
	four => fourInt,
	structuralStall => structuralStall,
	pcStall => pcStall,
	selectOutput => address,
	instructionMemoryOutput => instruction
);
-- DECODE STAGE 
CT : controller 
port map(
	clk => clk,
	opcode => opcodeInput, 
	funct => functInput,
	branch => zeroOutput,
	oldBranch => EXMEMBranch,
	ALU1src => ALU1srcO,
	ALU2src => ALU2srcO,
	MemRead => MemReadO,
	MemWrite => MemWriteO,
	RegWrite => RegWriteO,
	MemToReg => MemToRegO,
	structuralStall => IDEXStructuralStall,
	ALUOp => ALUOp,
	Shift => Shift,
	RType => RType,
	JType => JType
	
);

RegisterFile : register_file
port map (
	clock => clk,
	rs => rs,
	rt => rt,
	write_enable => write_enable,
	rd => WBrd,
	rd_data => rd_data,
	writeToText => writeToRegisterFile,
	ra_data => ra,
	rb_data => rb
);

se : signextender
port map(
immediate_in => immediate,
immediate_out => immediate_out
);

-- EXECUTE STAGE 
exMux1 : mux 
port map (
input0 => IDEXra,
input1 => IDEXaddress,
selectInput => IDEXALU1srcO,
selectOutput => muxOutput1
);

exMux2 : mux 
port map (
input0 => IDEXimmediate,
input1 => IDEXrb,
selectInput => IDEXALU2srcO,
selectOutput => muxOutput2
);

operator : alu 
port map( 
input_a => muxOutput1,
input_b => muxOutput2,
SEL => IDEXAluOp,
out_alu => aluOutput
);

zr : zero 
port map (
input_a => IDEXra,
input_b => IDEXrb, 
optype => IDEXAluOp,  
result => zeroOutput
);

memStage : mem
port map (
	clk =>clk,
	-- Control lines
	ctrl_write => EXMEMMemWriteO,
	ctrl_read => EXMEMMemReadO,
	ctrl_memtoreg_in => EXMEMMemToRegO,
	ctrl_memtoreg_out => memtoReg,
	ctrl_regwrite_in => EXMEMRegWriteO,
	ctrl_regwrite_out => regWrite,
	ctrl_jal => ctrl_jal,

	--Ports of stage
	alu_in => EXMEMaluOutput,
	alu_out=>  MEMWBaluOutput,
	mem_data_in => EXMEMregisterOutput,
	mem_data_out => MEMWBmemOutput, 
	write_addr_in => EXMEMrd,
	write_addr_out => MEMWBrd,
	
	--Memory signals
	writedata => MEMwritedata,
	address => MEMaddress,
	memwrite => MEMmemwrite,
	memread  => MEMmemread,
	readdata => MEMreaddata,
	waitrequest => MEMwaitrequest
);

memMemory: memory
port map (
	clock => clk,
	writedata => MEMwritedata,
	address => MEMaddress,
	memwrite => MEMmemwrite,
	memread  => MEMmemread,
	writeToText => writeToMemoryFile,
	readdata => MEMreaddata,
	waitrequest => MEMwaitrequest
);

wbStage: wb
port map (ctrl_memtoreg_in => memtoReg,
	ctrl_regwrite_in => regWrite,
	ctrl_regwrite_out => write_enable,
	
	alu_in  => MEMWBaluOutput,
	mem_in => MEMWBmemOutput,
	mux_out  => rd_data,
	write_addr_in => MEMWBrd,
	write_addr_out => WBrd
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