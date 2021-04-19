library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WriteBack is
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
end WriteBack;

architecture arch of WriteBack is

begin	
	
	mem_to_reg_out <= mem_to_reg_in;

	process(clk)
	begin

	if(now < 1 ps) then
		write_data <= "00000000000000000000000000000000";	
		reg_to_write_out <= "00000";
	end if;	

	if(rising_edge(clk))then
		if (mem_to_reg_in = '1') then
			reg_to_write_out <= reg_to_write_in;
			if(reg_write_in = '1')then
				write_data <= read_data;
			else
				write_data <= alu_in;
			end if;
		elsif(mem_to_reg_in = '0') then	
			write_data <= "00000000000000000000000000000000";	
			reg_to_write_out <= "00000";	
		end if;
	end if;
	end process;
end arch;