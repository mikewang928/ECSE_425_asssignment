LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY decode IS
	PORT (
		clk : in std_logic;
		instruction : in std_logic_vector(31 downto 0);  -- fetched instruction
		wb_data : in std_logic_vector(31 downto 0);  -- data to write back to register
		pc_in : in integer;  -- incremented pc from fetch stage
		
		pc_out : out integer;  -- pc bypass output
		read_data_1 : out std_logic_vector(31 downto 0);
		read_data_2 : out std_logic_vector(31 downto 0);
		ext32 : out std_logic_vector(31 downto 0);  -- sign or zero extend from 16 bits to 32 bits		
		rt_out : out std_logic_vector(4 downto 0);
		rd_out : out std_logic_vector(4 downto 0);		
		jump_addr : out integer;  -- jump target address
		
		-- EX stage control signals
		alu_op : out integer range 0 to 26;  -- ALU operation
		alu_src : out std_logic;  -- selecting the input to the ALU (register (0) or immediate (1))
		reg_dst : out std_logic;  -- selecting whether rt (0) or rd (1) is the destination register
		
		-- M stage control signals
		branch : out std_logic;  -- whether instruction is branch (1) or not branch (0)
		mem_write : out std_logic;  -- whether write to memory is needed (1) or not (0)
		mem_read : out std_logic;  -- whether read from memory is needed (1) or not (0)
		
		-- WB stage control signals
		reg_write : out std_logic;  -- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg : out std_logic  -- selecting whether writeback data is read from memory (1) or from ALU result (0)
		
	);
END decode;

ARCHITECTURE rtl OF decode IS
	
	-- 32 registers of 32 bits each
	type register_struct is array(31 downto 0) of std_logic_vector(31 downto 0);
	signal register_bank : register_struct := (others=>(others=>'0'));
	

BEGIN

	pc_out <= pc_in;

	process(clk) 
		variable opcode,funct : std_logic_vector(5 downto 0);
		variable rs,rt,rd,shamt : std_logic_vector(4 downto 0);
		variable immediate : std_logic_vector(15 downto 0);
		variable address : std_logic_vector(25 downto 0)
	begin
		if rising_edge(clk) then
			opcode := instruction(31 downto 26);
			funct := instruction(5 downto 0);
			rs := instruction(25 downto 21);
			rt := instruction(20 downto 16);
			rd := instruction(15 downto 11);
			shamt := instruction(10 downto 6);
			immediate := instruction(15 downto 0);
			address := instruction(25 downto 0);
			read_data_1 <= register_bank(to_integer(unsigned(rs)));
			read_data_2 <= register_bank(to_integer(unsigned(rt)));
			rt_out <= rt;
			rd_out <= rd;
			case opcode is
			-- R type instructions
			when "000000" => 
				alu_src <= '0';  -- register as ALU input
				reg_dst <= '1';  -- rd as writeback destination register
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				case funct is
					when "100000" =>  
						alu_op <= 0; -- add
					when "100010" =>  
						alu_op <= 1; -- sub
					when "011000" =>  
						alu_op <= 3; -- mult
					when "011010" =>  
						alu_op <= 4; -- div
					when "101010" =>  
						alu_op <= 5; -- slt
					when "100100" =>  
						alu_op <= 7; -- and
					when "100101" =>  
						alu_op <= 8; -- or
					when "100111" =>  
						alu_op <= 9; -- nor
					when "100110" =>  
						alu_op <= 10; -- xor
					when "010000" =>  
						alu_op <= 14; -- mfhi
					when "010010" =>  
						alu_op <= 15; -- mflo
					when "000000" =>  
						alu_op <= 17; -- sll						
					when "000010" =>  
						alu_op <= 18; -- srl						
					when "000011" =>  
						alu_op <= 19; -- sra						
					when "001000" =>  
						alu_op <= 25; -- jr
						reg_write <= '0';
				end case;
			-- I type instructions
			when "001000" =>
				alu_op <= 2; -- addi
				ext32 <= std_logic_vector(resize(signed(immediate), ext32'length));
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
			when "001010" =>
				alu_op <= 6; -- slti
				ext32 <= std_logic_vector(resize(signed(immediate), ext32'length));
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
			when "001100" =>
				alu_op <= 11; -- andi
				ext32 <= x"0000" & immediate;
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
			when "001101" =>
				alu_op <= 12; -- ori
				ext32 <= x"0000" & immediate;
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
			when "001110" =>
				alu_op <= 13; -- xori
				ext32 <= x"0000" & immediate;
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
			when "001111" =>
				alu_op <= 16; -- lui
				ext32 <= x"0000" & immediate;
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
			when "100011" =>
				alu_op <= 20; -- lw
				ext32 <= std_logic_vector(resize(signed(immediate), ext32'length));
				alu_src <= '1';
				reg_dst <= '0';
				mem_read <= '1';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '1';
			when "101011" =>
				alu_op <= 21; -- sw
				ext32 <= std_logic_vector(resize(signed(immediate), ext32'length));
				alu_src <= '1';
				mem_read <= '0';
				mem_write <= '1';
				reg_write <= '0';
				mem_to_reg <= '0';
			when "000100" =>
				alu_op <= 22; -- beq
				ext32 <= std_logic_vector(resize(signed(immediate), ext32'length));
				alu_src <= '0';
				branch <= '1';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '0';
				mem_to_reg <= '0';
			when "000101" =>
				alu_op <= 23; -- bne
				ext32 <= std_logic_vector(resize(signed(immediate), ext32'length));
				alu_src <= '0';
				branch <= '1';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '0';
				mem_to_reg <= '0';
			-- J type instruction
			when "000010" =>
				alu_op <= 24; -- j
			when "000011" =>
				alu_op <= 26; -- jal
				
			end case;
				
		elsif falling_edge(clk) then
	
		end if;
	end process;


END rtl;




























