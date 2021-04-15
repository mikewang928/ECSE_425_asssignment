library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.defs.all;

entity forwarding_unit is

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

end forwarding_unit;



architecture Behavioral of forwarding_unit is

--Internal signals, as the values are being read.
signal data_1_forward_mem_i : std_logic_vector(1 downto 0)
signal data_2_forward_mem_i : std_logic_vector(1 downto 0)

begin

--Connect internal signals and output
  
  data_1_forward_mem <= data_1_forward_mem_i;
  data_2_forward_mem <= data_2_forward_mem_i;

    forwarding_logic:
        process ( reg_rs_ex
                , reg_rt_ex
                , reg_rd_mem
                , reg_rd_wb
                , reg_wen_mem
                , reg_wen_wb
					 , data_1_forward_mem_i
					 , data_2_forward_mem_i
                )
        begin
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
				
				data_1_forward_mem_i <= '00';
				data_2_forward_mem_i <= '00';
				
            data_1_forward_wb <= '00';
            data_2_forward_wb <= '00';

            -----------------------------
            --EX hazard detection and MEM hazard detection
				--
				--First check if the destination come from mem matches with EX, 
				--if not mem check if it come from wb
            --
            --Equations are taken from page 308 and 311
            --in "Computer Organization and Design"
				--by Patterson and Hennesy
            -----------------------------
				
            if reg_wen_mem = '1' and reg_rd_mem /= "00000" and reg_rd_mem = reg_rs_ex then 
              data_1_forward_mem_i <= '10'; 
				elsif reg_wen_wb = '1' and reg_rd_wb /= "00000" and reg_rd_wb = reg_rs_ex then
              data_1_forward_wb_en <= '01';
            end if; 
				
            
            if reg_wen_mem = '1' and reg_rd_mem /= "00000" and reg_rd_mem = reg_rt_ex then 
              data_2_forward_mem_i <= '10';
				elsif reg_wen_wb = '1' and reg_rd_wb /= "00000" and reg_rd_wb = reg_rt_ex then
              data_2_forward_wb_en <= '01';
            end if;
            

				
--            if reg_wen_wb = '1'
--            and reg_rd_wb /= "00000"
--            and reg_rd_wb = reg_rs_ex
--            then
--              data_1_forward_wb_en <= '01';
--            end if;
--            
--            if reg_wen_wb = '1'
--            and reg_rd_wb /= "00000"
--            and reg_rd_wb = reg_rt_ex
--            then
--              data_2_forward_wb_en <= '01';
--            end if;

        end process;

end Behavioral;