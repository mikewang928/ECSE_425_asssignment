library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity execution is
	port(
		-- clk
		clk : in std_logic;
		-- oparends 
		decode_data_1: in std_logic_vector(31 downto 0);						-- read_data_1 from decode stage  
		decode_data_2: in std_logic_vector(31 downto 0);						-- read_data_2 from decode stage 
		rt_in: in std_logic_vector(4 downto 0);									-- rt from the decode stage 
		rs_in: in std_logic_vector(4 downto 0);									-- rs from the decode stage
		
		-- inputs form the Forward unit: 
					-----------------------------------------------------
					-- 	    mux control 			|        source		--
					-----------------------------------------------------
					--			    00               |         ID/EX		--
					-----------------------------------------------------
					--				 10					|			 EX/MEM     --
					-----------------------------------------------------
					--				 01					|         MEM/WB     --
					-----------------------------------------------------
		forwarding_write_back_data: in std_logic_vector(31 downto 0);		-- forwarding data from the write back stage
		forwarding_mem_data: in std_logic_vector(31 downto 0);				-- forwarding data from the mem stage
		forwarding_signal_1: in std_logic_vector(1 downto 0); 				-- alu input mux  				
		forwarding_signal_2: in std_logic_vector(1 downto 0);					-- alu input mux 
		
		
		
		-- EX stage control signals
		alu_op_ex : in integer range 0 to 26;  					-- ALU operation control bits
		reg_dst_ex : in std_logic;  									-- selecting whether rt (0) or rd (1) is the destination register
		
		-- M stage control signals in
		mem_write : in std_logic;  								-- whether write to memory is needed (1) or not (0)
		mem_read : in std_logic;  									-- whether read from memory is needed (1) or not (0)
		
		-- WB stage control signals in
		reg_write : in std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg : in std_logic  								-- selecting whether writeback data is read
		 
		 
		-- alu out put
		alu_out : out std_logic_vector (31 downto 0);
		
		-- M stage control signals out
		mem_write_out : out std_logic;  								-- whether write to memory is needed (1) or not (0)
		mem_read_out : out std_logic;  								-- whether read from memory is needed (1) or not (0)
		
		-- WB stage control signals out
		reg_write_out : out std_logic;  								-- signal indicating whether a write to register is needed (1) or not (0)
		mem_to_reg_out : out std_logic  								-- selecting whether writeback data is read
		
	);
end execution;


architecture arch of execution is
	-- 2 registers of 32 bits HI[1], LO[0]
	type special_register_struct is array(1 downto 0) of std_logic_vector(31 downto 0);
	signal special_register_bank : register_struct := (others=>(others=>'0'));

begin

		process(clk)
			variable mux_output_1, mux_output_2, div_main, div_remainder, ZERO: std_logic_vector(31 downto 0);  
			variable mux_register_out: std_logic; 
			variable mux_mult_out, mux_mult_div_out： std_logic_vector(63 downto 0)
			
		
			if rising_edge(clk) then
			-- mux logic
			-- Forward unit outputs: 
					-----------------------------------------------------
					-- 	    mux control 			|        source		--
					-----------------------------------------------------
					--			    00               |         ID/EX		--
					-----------------------------------------------------
					--				 10					|			 EX/MEM     --
					-----------------------------------------------------
					--				 01					|         MEM/WB     --
					-----------------------------------------------------
				
				-- mux 1: decode_data_1 or forwarding_write_back_data or forwarding_mem_data
				if (forwarding_signal_1 = '00') then
					mux_output_1 <=  decode_data_1; 
				elsif (forwarding_signal_1 = '01') then 
					mux_output_1 <= forwarding_write_back_data;
				elsif (forwarding_signal_1 = '10') then 
					mux_output_1 <= forwarding_mem_data;
				end if 
				
				-- mux 2: decode_data_2 or forwarding_write_back_data or forwarding_mem_data
				if (forwarding_signal_2 = '00') then
					mux_output_2 <=  decode_data_1; 
				elsif (forwarding_signal_2 = '01') then 
					mux_output_2 <= forwarding_write_back_data;
				elsif (forwarding_signal_2 = '10') then 
					mux_output_2 <= forwarding_mem_data;
				end if 
				
				
				-- mux 3: rt(0) or rd(1)
				if (reg_dst_ex = '0') then 
					mux_register_out <= rt_in
				else
					mux_register_out <= rd_in
				end if 
		
				-- alu logic 
				-- operend: mux_output_1 and mux_output_2
				case alu_op_ex is 
				when 0 => -- add
					alu_out <= mux_output_1 + mux_output_2; 
					
				when 1 => -- sub
					alu_out <= mux_output_1 - mux_output_2;
					
				when 2 => -- addi 
					alu_out <= mux_output_1 + mux_output_2; 
				
				when 3 => -- mult 
					mux_mult_out <= signed(mux_output_1) * signed(mux_output_2);
					special_register_bank(0) <= mux_mult_out(31 downto 0); --LO
					special_register_bank(1) <= mux_mult_out(63 downto 32) --HI
				
				when 4 => -- div
					div_main <= signed(mux_output_1) / signed(mux_output_2); -- 32 bits
					mux_mult_div_out： <= signed(div_main)*signed(mux_output_2); 
					div_remainder <= mux_output_1 - mux_mult_div_out： --64 bits 
					special_register_bank(0) <= div_main;
					special_register_bank(1) <= div_remainder(31 downto 0);
					
				when 5 => -- slt (op1<op2:1; op1>op2:0)
					if (mux_output_1 > mux_output_2) then
						alu_out <= x"00000000"
					else 
						alu_out <= x"00000001"
					end if
					
				when 6 => -- slt (op1<op2:1; op1>op2:0)
					if (mux_output_1 > mux_output_2) then
						alu_out <= x"00000000"
					else 
						alu_out <= x"00000001"
					end if
					
				when 7 => -- and 
					alu_out <= mux_output_1 and mux_output_2; 
				when 8 => -- or
					alu_out <= mux_output_1 or mux_output_2; 
				when 9 => -- nor 
					alu_out <= mux_output_1 nor mux_output_2; 
				when 10 => -- xor 
					alu_out <= mux_output_1 xor mux_output_2; 
				when 11 => -- andi
					alu_out <= mux_output_1 and mux_output_2;
				when 12 => -- ori
					alu_out <= mux_output_1 or mux_output_2;
				when 13 => -- xori 
					alu_out <= mux_output_1 xor mux_output_2;
				
				
				when 14 => -- mfhi (move form high)
					alu_out <= special_register_bank(1);
				when 15 => -- mflo (move from lo)
					alu_out <= special_register_bank(0);
					
				when 16 => -- lui (load upper 16 bits of the immediate value)
					alu_out <= mux_output_2(15 downto 0) & x"0000";
					
				when 17 => -- sll (shift left logical)
					alu_out <= shift_left(signed(mux_output_1), to_integer(signed(mux_output_2)));
					
				-- 1001 -> 0001/ 1111
				when 18 => -- srl	(shift right logical)
					ZERO <= x"00000000"; 
					alu_out <= ZERO + mux_output_1(31 downto to_integer(signed(mux_output_2)))); 
				
				when 19 => -- sra (shift right arthemic)
					alu_out <= shift_right(signed(mux_output_1), to_integer(signed(mux_output_2)));
					
				when 20 => -- lw
				when 21 => -- sw
				
				when 22 => -- beq
				when 23 => -- bne
				
				when 24 => -- j
				when 25 => -- jr
				when 26 => -- jal
		



end arch;