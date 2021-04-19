LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY WriteBack_tb IS
END entity;

ARCHITECTURE Behaviour of WriteBack_tb IS

signal clk : std_logic := '0';
constant clk_period : time := 1 ns;
signal reg_write_in : std_logic;
signal mem_to_reg_in : std_logic; 
signal read_data : std_logic_vector(31 downto 0); 	 				
signal alu_in : std_logic_vector (31 downto 0); 			
signal reg_to_write_in : std_logic_vector(4 downto 0);
		
signal mem_to_reg_out : std_logic;  							
signal write_data : std_logic_vector(31 downto 0);
signal reg_to_write_out : std_logic_vector (4 downto 0);


COMPONENT WriteBack
	port(	
		signal clk : in std_logic;
		signal reg_write_in : in std_logic;
		signal mem_to_reg_in : in std_logic; 
		signal read_data : in std_logic_vector(31 downto 0); 	 				
		signal alu_in : in std_logic_vector (31 downto 0); 			
		signal reg_to_write_in : in std_logic_vector(4 downto 0);
		
		signal mem_to_reg_out : out std_logic;  						
		signal write_data : out std_logic_vector(31 downto 0);
		signal reg_to_write_out : out std_logic_vector (4 downto 0)
		);	
END COMPONENT;


    BEGIN

    	label1 : WriteBack port 
		MAP(
    		clk => clk,
		reg_write_in => reg_write_in,
		mem_to_reg_in => mem_to_reg_in,
		read_data => read_data,
		alu_in => alu_in,
		reg_to_write_in => reg_to_write_in,
		mem_to_reg_out => mem_to_reg_out,
		write_data => write_data,
		reg_to_write_out => reg_to_write_out
    		);
			
			
      clk_process : process
    	BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    	END PROCESS;

    	test_process : process
    	begin
		reg_write_in <= '0';
		mem_to_reg_in <= '1';
		alu_in <= "00000000000000000000000000000010";
		read_data <= "11100010101010101010101010101010";
		wait for clk_period;
		reg_write_in <= '1';
		mem_to_reg_in <= '1';
		alu_in <= "00000000000000000000000000000100";
		read_data <= "11100010101010101010101010101010";		
		wait for clk_period;
		reg_write_in <= '0';
		mem_to_reg_in <= '0';
		alu_in <= "00000000000000000000000000001000";
		read_data <= "11100010101010101010101010101010";
		wait for clk_period;
		reg_write_in <= '1';
		mem_to_reg_in <= '0';
		alu_in <= "00000000000000000000000000001000";
		read_data <= "11100010101010101010101010101010";
		wait for clk_period;
    	END PROCESS;

    END Behaviour;