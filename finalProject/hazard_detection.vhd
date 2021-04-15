library ieee;
use ieee.std_logic_1164.all;
use work.defs.all;


entity hazard_detection is
    port ( mem_read_ex : in  std_logic
         ; reg_rt_ex   : in std_logic_vector(4 downto 0)
         ; reg_rs_id   : in std_logic_vector(4 downto 0)
         ; reg_rt_id   : in std_logic_vector(4 downto 0)
         ; insert_stall_mux: out  std_logic
			; if_id_write : out std_logic 
        );
end hazard_detection;

architecture behavioral of hazard_detection is

begin
	
	-- hazard_detection unit outputs for both insert_stall_mux and if_id_write: 
	-----------------------------------------------------
	-- 	    haz control 			|        Action		--
	-----------------------------------------------------
	--			    0                |        proceed		--
	-----------------------------------------------------
	--				 1					   |			 stall      --
	-----------------------------------------------------

  process (mem_read_ex, reg_rt_ex, reg_rs_id, reg_rt_id) 
  begin 
    insert_stall <= '0';
    
    --Check for hazard
    if mem_read_ex = '1' then
      if reg_rt_ex = reg_rs_id or reg_rt_ex = reg_rt_id then
        --HAZARD. Time to stall
        insert_stall_mux <= '1';
		  if_id_write <= '1';
      end if;
    end if;
  end process;

end behavioral;