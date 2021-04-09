library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memory_arbiter_lib.all;

entity PROCv2 is
port(
clock : in std_logic;
reset: in std_logic

	);
end entity;

architecture foo of PROCv2 is

component MEM is
port(
clk   : in  std_logic;  -- Clock signal
n_reset : in std_logic; -- Active low reset signal
data_in : in std_logic_vector (31 downto 0); --  Connects with ex_mem_data_out
address_in : in std_logic_vector(31 downto 0); --  Connects with ex_ALU_result_out - Truncated down to 5 lower bits
mem_access_write : in std_logic;  -- Connects with ex_storeen_out
mem_access_load: in std_logic;
byte : in std_logic; -- when '1' you are interacting with the memory in word otherwise in byte
register_access_in : in std_logic; -- Connects with ex_reg_en_out
register_access_add_in : in std_logic_vector(reg_adrsize-1 downto 0); -- Connects with ex_dest_regadd_out (passthrough)

register_access_out : out std_logic; -- Connects with register access in of WB stage (passthrough)
register_access_add_out : out std_logic_vector(reg_adrsize-1 downto 0); -- ex_dest_regadd_out (passthrough)
forwarded_data_in: in std_logic_vector(31 downto 0);
data_out : out std_logic_vector(31 downto 0) :=(others =>'Z');
data_in_selected: in std_logic
	);
end component;

component decode is
port(
clk : in std_logic;
pc_in : in std_logic_vector(31 downto 0) ;
pc_out : out std_logic_vector(31 downto 0) ;
instruction_in : in std_logic_vector (31 downto 0);
write_enable : in std_logic;
write_register_address : in std_logic_vector(reg_adrsize-1 downto 0);
write_register_data : in std_logic_vector(31 downto 0);
alu_op : out std_logic_vector (3 downto 0); -- ALU function code
reg1_out : out std_logic_vector(31 downto 0) ; -- ALU first element
reg2_out : out std_logic_vector(31 downto 0) ; -- ALU second element
reg1_addr : out std_logic_vector(reg_adrsize-1 downto 0) ;
reg2_addr : out std_logic_vector(reg_adrsize-1 downto 0) ;
immediate_out : out std_logic_vector (31 downto 0); -- sign extended immediate value
dest_register_address : out std_logic_vector (reg_adrsize-1 downto 0); -- destination register address for write back stage
load : out std_logic; -- indicates if the mem stage should use the result of alu as address for load
store : out std_logic; -- indicates if the mem stage should use the result of alu as address for store operation
use_imm : out std_logic; -- indicate if alu should use value immediate for input 2
branch_taken : out std_logic; -- selector for IF stage pc source mux
byte : out std_logic;
write_back_enable : out std_logic;
n_reset : in std_logic
	);
end component;

component EX is
port(
RSD  : in  STD_LOGIC_VECTOR (31 downto 0);
RTD   : in  STD_LOGIC_VECTOR (31 downto 0);
IMM   : in  STD_LOGIC_VECTOR (31 downto 0);
RDD   : out  STD_LOGIC_VECTOR (31 downto 0);
RDAI	: in STD_LOGIC_VECTOR (4 downto 0);
RDAO	: out STD_LOGIC_VECTOR (4 downto 0);
FCode: in std_logic_vector(3 downto 0);
mem_forward_data: in std_logic_vector (31 downto 0);
WB_forward_data: in std_logic_vector (31 downto 0);
clock   : in  STD_LOGIC;
n_reset: in std_logic;
use_imm: in std_logic;
D1Sel1  : in  STD_LOGIC;
D1Sel0   : in  STD_LOGIC;
D2Sel0   : in  STD_LOGIC;
D2Sel1 : in  STD_LOGIC;
MAWI: in std_logic;
MARI: in std_logic;
MAWO: out std_logic;
MARO: out std_logic;
mem_data_out:out STD_LOGIC_VECTOR (31 downto 0);
ex_stall: in std_logic;
byte_in:in std_logic;
WB_enable_in: in std_logic;
byte_out:out std_logic;
alu_result_in:in STD_LOGIC_VECTOR (31 downto 0);
WB_enable_out: out std_logic

	);
end component;

component fetch is
port(
	clk : in std_logic;
    pc_out : out std_logic_vector (31 downto 0);
    pc_in : in std_logic_vector (31 downto 0);
    pc_sel : in std_logic;
    pc_enable : in std_logic;
    instruction_out : out std_logic_vector (MEM_DATA_WIDTH-1 downto 0);
    n_reset : in std_logic
	);
end component;

--Control Signals
signal clk: std_logic;
signal ex_reset: std_logic;
signal id_reset: std_logic;
signal if_reset: std_logic;
signal mem_reset: std_logic;


--IF in buffers
signal if_pc_in_buffer: std_logic_vector(31 downto 0);
signal if_pc_sel_in_buffer: std_logic;
signal if_pc_enable_in_buffer: std_logic;

--IF out signals
signal if_pc_out: std_logic_vector(31 downto 0);
signal if_inst_out: std_logic_vector(31 downto 0);

--ID in buffers
signal id_inst_in_buffer:std_logic_vector (31 downto 0);
signal id_wenable_in_buffer: std_logic;
signal id_reg_add_in_buffer: std_logic_vector (reg_adrsize-1 downto 0);
signal id_reg_data_in_buffer: std_logic_vector(31 downto 0);
signal id_pc_in_buffer: std_logic_vector(31 downto 0);

--ID out signals
signal id_pc_out: std_logic_vector(31 downto 0);
signal id_alu_op_out: std_logic_vector(3 downto 0);
signal id_r1_out: std_logic_vector(31 downto 0);
signal id_r2_out: std_logic_vector(31 downto 0);
signal id_imm_out: std_logic_vector(31 downto 0);
signal id_dest_regadd_out: std_logic_vector (reg_adrsize-1 downto 0);
signal id_loaden_out: std_logic;
signal id_storeen_out:std_logic;
signal id_useimm_out:std_logic;
signal id_branch_out : std_logic;
signal id_byte_out : std_logic;
signal id_WB_enable_out : std_logic;
signal id_reg1_addr_out : std_logic_vector(reg_adrsize-1 downto 0) ;
signal id_reg2_addr_out : std_logic_vector(reg_adrsize-1 downto 0) ;

--EX in buffers
signal ex_r1_in_buffer:std_logic_vector (31 downto 0);
signal ex_r2_in_buffer:std_logic_vector (31 downto 0);
signal ex_imm_in_buffer:std_logic_vector (31 downto 0);
signal ex_dest_regadd_in_buffer:std_logic_vector (reg_adrsize-1 downto 0);
signal ex_alu_op_in_buffer: std_logic_vector(3 downto 0);
signal ex_ALUData1_selector0_in_buffer: std_logic;
signal ex_ALUData1_selector1_in_buffer: std_logic;
signal ex_ALUData2_selector0_in_buffer: std_logic;
signal ex_ALUData2_selector1_in_buffer: std_logic;
signal ex_loaden_in_buffer: std_logic;
signal ex_storeen_in_buffer:std_logic;
signal ex_stall_in_buffer:std_logic;
signal ex_stall_in_buffer0:std_logic;
signal ex_byte_in_buffer:std_logic;
signal ex_WB_enable_in_buffer:std_logic;
signal ex_alu_result_in:std_logic_vector (31 downto 0);
signal ex_use_IMM_in: std_logic;


--EX out signals
signal ex_ALU_result_out:std_logic_vector (31 downto 0);--used by mem
signal ex_dest_regadd_out:std_logic_vector (reg_adrsize-1 downto 0); --passthrough
signal ex_loaden_out: std_logic;--used
signal ex_storeen_out:std_logic;--used
signal ex_mem_data_out:std_logic_vector (31 downto 0);--used
signal ex_byte_out : std_logic;
signal ex_WB_enable_out : std_logic;

--MEM in buffers
signal mem_data_in_buffer:std_logic_vector (31 downto 0);
signal mem_address_in_buffer:std_logic_vector (31 downto 0);
signal mem_access_write_in_buffer: std_logic;
signal mem_access_load_in_buffer: std_logic;
signal mem_byte_in_buffer : std_logic;
signal mem_WB_enable_in_buffer : std_logic;
signal mem_WB_address_in_buffer:std_logic_vector (reg_adrsize-1 downto 0);
signal mem_forwarded_data_in: std_logic_vector (31 downto 0);
signal mem_data_in_selected: std_logic;


--MEM out signals
signal mem_WB_enable_out: std_logic;
signal mem_WB_address_out:std_logic_vector (reg_adrsize-1 downto 0);
signal mem_WB_data_out: std_logic_vector (31 downto 0);


--WB in buffers
signal wb_WB_enable_in_buffer: std_logic;
signal wb_WB_address_in_buffer:std_logic_vector (reg_adrsize-1 downto 0);
signal wb_WB_data_in_buffer: std_logic_vector (31 downto 0);

--Forwarding signals
signal mem_forward_data: std_logic_vector (31 downto 0);
signal WB_forward_data: std_logic_vector (31 downto 0);

--Hazard Detection
signal fwd_from_ex_enable: std_logic;
signal fwd_from_mem_enable: std_logic;
signal enable_stall: std_logic;
signal ex_enable_stall: std_logic;
signal if_pc_enable_in_buffer_temp: std_logic;
signal enable_stall_temp: std_logic;
signal enable_stall_temp1: std_logic;
signal enable_stall_temp2: std_logic;
signal z:std_logic;
begin

--instantiate stages
IDstage: decode port map(clk, id_pc_in_buffer, id_pc_out,id_inst_in_buffer, id_wenable_in_buffer,id_reg_add_in_buffer,id_reg_data_in_buffer,id_alu_op_out,id_r1_out,id_r2_out, id_reg1_addr_out,id_reg2_addr_out,id_imm_out, id_dest_regadd_out, id_loaden_out,id_storeen_out, id_useimm_out,id_branch_out, id_byte_out,id_WB_enable_out, id_reset);
EXstage: EX port map (ex_r1_in_buffer,ex_r2_in_buffer,ex_imm_in_buffer,ex_ALU_result_out,ex_dest_regadd_in_buffer,ex_dest_regadd_out,ex_alu_op_in_buffer,mem_forward_data,WB_forward_data ,clk,ex_reset, ex_use_IMM_in, ex_ALUData1_selector1_in_buffer,ex_ALUData1_selector0_in_buffer, ex_ALUData2_selector0_in_buffer,ex_ALUData2_selector1_in_buffer,ex_storeen_in_buffer,ex_loaden_in_buffer,ex_storeen_out,ex_loaden_out, ex_mem_data_out,ex_stall_in_buffer,ex_byte_in_buffer,ex_WB_enable_in_buffer,ex_byte_out,ex_alu_result_in,ex_WB_enable_out);
IFstage: fetch port map(clk,if_pc_out,if_pc_in_buffer, if_pc_sel_in_buffer,if_pc_enable_in_buffer,if_inst_out,if_reset);
MEMstage: MEM port map(clk,mem_reset,mem_data_in_buffer,mem_address_in_buffer,mem_access_write_in_buffer ,mem_access_load_in_buffer,mem_byte_in_buffer,mem_WB_enable_in_buffer,mem_WB_address_in_buffer,mem_WB_enable_out,mem_WB_address_out,mem_forwarded_data_in,mem_WB_data_out,mem_data_in_selected);


clk<=clock;
id_reset<=reset;
ex_reset<=reset AND NOT(ex_enable_stall);
if_reset<=reset;
mem_reset<=reset;

--unclocked branching signals
if_pc_in_buffer<=id_pc_out;
if_pc_sel_in_buffer<=id_branch_out;

--unclocked WB to ID signals
id_wenable_in_buffer<=wb_WB_enable_in_buffer;
id_reg_add_in_buffer<=wb_WB_address_in_buffer;
id_reg_data_in_buffer<=wb_WB_data_in_buffer;
if_pc_enable_in_buffer<= not enable_stall;

--unclocked forwarding signals

ex_alu_result_in<=mem_address_in_buffer;
mem_forward_data<=wb_WB_data_in_buffer;

--enable_stall<='0';
--if_pc_enable_in_buffer <='1';

--Control Unit
mem_forwarded_data_in <= wb_WB_data_in_buffer;

proc: process (clock)
begin
if falling_edge(clock) then
		ex_enable_stall<=enable_stall;



		--IF/ID Buffer Latching
		if (if_inst_out /= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ") then
		id_inst_in_buffer <=if_inst_out;
		end if;
		id_pc_in_buffer<=if_pc_out;


		--ID/EX Buffer Latching
		ex_r1_in_buffer <=id_r1_out;
		ex_r2_in_buffer <=id_r2_out;
		ex_imm_in_buffer <=id_imm_out;
		ex_dest_regadd_in_buffer <= id_dest_regadd_out;
		ex_alu_op_in_buffer <=id_alu_op_out;

		ex_loaden_in_buffer <=id_loaden_out;
		ex_storeen_in_buffer <=id_storeen_out;

		ex_stall_in_buffer0<=id_branch_out;
		ex_stall_in_buffer<=ex_stall_in_buffer0;

		ex_byte_in_buffer<=id_byte_out;
		ex_WB_enable_in_buffer<=id_WB_enable_out;
		ex_use_IMM_in<=id_useimm_out;


		--EX/MEM Buffer Latching
		mem_address_in_buffer<=ex_ALU_result_out;
		mem_WB_address_in_buffer<=ex_dest_regadd_out;
		mem_access_write_in_buffer<=ex_storeen_out;
		mem_data_in_buffer<=ex_mem_data_out;
		mem_byte_in_buffer<=ex_byte_out;
		mem_WB_enable_in_buffer<=ex_WB_enable_out;
		mem_access_load_in_buffer<=ex_loaden_out;

		--MEM/WB(ID) buffer latching
		wb_WB_data_in_buffer<=mem_WB_data_out;
		wb_WB_enable_in_buffer<=mem_WB_enable_out;
		wb_WB_address_in_buffer<=mem_WB_address_out;

		--ALU Operand 1 Forwarding
		 if ((id_reg1_addr_out /= "00000") and (id_reg1_addr_out = ex_dest_regadd_out) and ex_WB_enable_out='1') then
		 ex_ALUData1_selector0_in_buffer <= '1';
		 ex_ALUData1_selector1_in_buffer <= '0';
		elsif ((id_reg1_addr_out /= "00000") and (id_reg1_addr_out = mem_WB_address_out) and mem_WB_enable_out='1') then
		 ex_ALUData1_selector0_in_buffer <= '0';
		 ex_ALUData1_selector1_in_buffer <= '1';
		else 
		ex_ALUData1_selector0_in_buffer <= '0';
		ex_ALUData1_selector1_in_buffer <= '0';
		end if;

		--ALU Operand 2 Forwarding
		if ((id_reg2_addr_out /= "00000") and (id_reg2_addr_out = ex_dest_regadd_out) and ex_WB_enable_out='1') then
		 ex_ALUData2_selector0_in_buffer <= '1';
		 ex_ALUData2_selector1_in_buffer <= '0';
		elsif ((id_reg2_addr_out /= "00000") and (id_reg2_addr_out = mem_WB_address_out) and mem_WB_enable_out='1') then
		 ex_ALUData2_selector0_in_buffer <= '0';
		 ex_ALUData2_selector1_in_buffer <= '1';
		else 
		ex_ALUData2_selector0_in_buffer <= '0';
		ex_ALUData2_selector1_in_buffer <= '0';
		end if;

		--MEM Forwarding (sw after lw)
		mem_data_in_selected <='0';
		if ((ex_dest_regadd_out /="00000") and (ex_dest_regadd_out=mem_WB_address_out) and (ex_storeen_out='1')) then
		mem_data_in_selected <='1';
		end if;

end if;
end process;

--Stalling 
if_pc_enable_in_buffer <= not enable_stall;
enable_stall<= '1' when ((((( ((id_reg2_addr_out = ex_dest_regadd_in_buffer) and (id_reg2_addr_out /= "00000")) or ((id_reg1_addr_out = ex_dest_regadd_in_buffer) and (id_reg1_addr_out /= "00000") ) ) and ex_loaden_out ='1') and id_storeen_out='0') OR  (id_storeen_out ='1' and ((id_reg1_addr_out = ex_dest_regadd_in_buffer) and (id_reg1_addr_out /= "00000")) and ex_reset='1') ) and ex_dest_regadd_in_buffer /="00000" and ex_loaden_out ='1')  else 
'0';

--and not id_storeen_out) OR  id_storeen_out and ()


end foo;
