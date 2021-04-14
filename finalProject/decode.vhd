LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

-- branch/jump resolved in this stage
-- target pc computed in this stage
-- immediate value placed on read_data_2

ENTITY decode IS
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
END decode;

ARCHITECTURE rtl OF decode IS
	
	-- 32 registers of 32 bits each
	type register_struct is array(31 downto 0) of std_logic_vector(31 downto 0);
	signal register_bank : register_struct := (others=>(others=>'0'));
	
BEGIN

	process(clk) 
		variable opcode,funct : std_logic_vector(5 downto 0);
		variable rs,rt,rd,shamt : std_logic_vector(4 downto 0);
		variable immediate : std_logic_vector(15 downto 0);
		variable address : std_logic_vector(25 downto 0);
		variable comparator : std_logic;  -- compares the two register outputs, equal (1) or not (0)
		variable jump_addr : std_logic_vector(31 downto 0);  -- intermediate result for jump address computation
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
			rs_out <= rs;
			if register_bank(to_integer(unsigned(rs))) = register_bank(to_integer(unsigned(rt))) then
				comparator := '1';
			else
				comparator := '0';
			end if;
			case opcode is
			-- R type instructions
			when "000000" => 
				reg_dst <= '1';  -- rd as writeback destination register
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '0';
				case funct is
					when "100000" =>  
						alu_op <= 0; -- add
					when "100010" =>  
						alu_op <= 1; -- sub
					when "011000" =>  
						alu_op <= 3; -- mult
						reg_write <= '0';  -- writes to HI and LO
					when "011010" =>  
						alu_op <= 4; -- div
						reg_write <= '0';  -- writes to HI and LO
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
						branch <= '1';
						pc_target <= to_integer(unsigned(register_bank(to_integer(unsigned(rs))))) / 4;  -- PC = R[rs] and pc is word-addressed and integer
					when others =>
						
				end case;
			-- I type instructions
			when "001000" =>
				alu_op <= 2; -- addi
				read_data_2 <= std_logic_vector(resize(signed(immediate), 32));
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';				
				branch <= '0';
			when "001010" =>
				alu_op <= 6; -- slti
				read_data_2 <= std_logic_vector(resize(signed(immediate), 32));
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '0';
			when "001100" =>
				alu_op <= 11; -- andi
				read_data_2 <= x"0000" & immediate;
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '0';
			when "001101" =>
				alu_op <= 12; -- ori
				read_data_2 <= x"0000" & immediate;
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '0';
			when "001110" =>
				alu_op <= 13; -- xori
				read_data_2 <= x"0000" & immediate;
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '0';
			when "001111" =>
				alu_op <= 16; -- lui
				read_data_2 <= x"0000" & immediate;
				reg_dst <= '0';
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '0';
			when "100011" =>
				alu_op <= 20; -- lw
				read_data_2 <= std_logic_vector(resize(signed(immediate), 32));
				reg_dst <= '0';
				mem_read <= '1';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '1';
				branch <= '0';
			when "101011" =>
				alu_op <= 21; -- sw
				read_data_2 <= std_logic_vector(resize(signed(immediate), 32));
				mem_read <= '0';
				mem_write <= '1';
				reg_write <= '0';
				mem_to_reg <= '0';
				branch <= '0';
			when "000100" =>
				alu_op <= 22; -- beq
				read_data_2 <= std_logic_vector(resize(signed(immediate), 32));
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '0';
				mem_to_reg <= '0';
				branch <= comparator;
				pc_target <= pc_in + to_integer(signed(immediate));  -- no need to left shift by 2 and sign extend since pc is word-addressed and integer format
			when "000101" =>
				alu_op <= 23; -- bne
				read_data_2 <= std_logic_vector(resize(signed(immediate), 32));
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '0';
				mem_to_reg <= '0';
				branch <= not comparator;
				pc_target <= pc_in + to_integer(signed(immediate));  -- no need to left shift by 2 and sign extend since pc is word-addressed and integer format
			-- J type instruction
			when "000010" =>
				alu_op <= 24; -- j
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '0';
				mem_to_reg <= '0';
				branch <= '1';
				jump_addr := std_logic_vector(to_unsigned(pc_in*4, 32));
				pc_target <= to_integer(unsigned(std_logic_vector'(jump_addr(31 downto 28) & address & "00"))) / 4;  -- refer to MIPS reference, pc is integer and word-addressed
			when "000011" =>
				alu_op <= 26; -- jal
				mem_read <= '0';
				mem_write <= '0';
				reg_write <= '1';
				mem_to_reg <= '0';
				branch <= '1';
				reg_dst <= '1';  -- store 31 in rd_out
				rd_out <= "11111";
				read_data_1 <= std_logic_vector(to_unsigned(pc_in, 32));  -- R[31] = (pc+1)+1 (word-addressed)
				read_data_2 <= x"00000001";
				jump_addr := std_logic_vector(to_unsigned(pc_in*4, 32));
				pc_target <= to_integer(unsigned(std_logic_vector'(jump_addr(31 downto 28) & address & "00"))) / 4;  -- refer to MIPS reference, pc is integer and word-addressed
			when others =>
				
			end case;
				
		elsif falling_edge(clk) then  -- write back to register
			if(wb = '1') then
				if(wb_reg = "00000") then  -- R0 is always 0
					register_bank(to_integer(unsigned(wb_reg))) <= x"00000000";
				else
					register_bank(to_integer(unsigned(wb_reg))) <= wb_data;
				end if;
			end if;
		end if;
	end process;


END rtl;




























