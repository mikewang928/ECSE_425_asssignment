library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.memory_arbiter_lib.all;

entity decode is
    port (
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
        write_back_enable : out std_logic; -- write-back stage is expected to write to regs
        n_reset : in std_logic
    ) ;
end entity ; -- decode

architecture arch of decode is

signal r1 : std_logic_vector(reg_adrsize-1 downto 0);
signal r2 : std_logic_vector(reg_adrsize-1 downto 0);
signal zero16b : std_logic_vector(15 downto 0) := (others => '0');
signal immediate_out_internal : std_logic_vector (31 downto 0); -- sign extended immediate value

signal reg1_out_internal : std_logic_vector(31 downto 0) ; -- ALU first element
signal reg2_out_internal : std_logic_vector(31 downto 0) ; -- ALU second element
signal branch_taken_internal : std_logic;
signal branch_ctl : std_logic_vector(1 downto 0) ; -- control flow signal for taking branches and jumps
signal offset : std_logic_vector(31 downto 0) ;
signal branch_dest : std_logic_vector(31 downto 0) ;
signal offset_select : std_logic;

begin

    register_file : ENTITY work.Registers
    PORT MAP (
        clk => clk, -- : in std_logic;
        n_rst => n_reset, -- : in std_logic; -- Active low reset signal
        write_enable => write_enable, -- : in std_logic;  -- Write control signal
        write_in => write_register_data, -- : in std_logic_vector(31 downto 0);  -- Input data port
        write_adr => write_register_address, --: in std_ulogic_vector(reg_adrsize-1 downto 0);-- address write

        port1_adr => r1, -- : in std_logic_vector(reg_adrsize-1 downto 0); -- Port 1 read address
        port2_adr => r2, -- : in std_logic_vector(reg_adrsize-1 downto 0); -- Port 2 read address
        port1_out => reg1_out_internal, -- : out std_logic_vector(31 downto 0);  -- Read port 1
        port2_out => reg2_out_internal -- : out std_logic_vector(31 downto 0);  -- Read port 2

    );

    reg_comparator : ENTITY work.comparator
    PORT MAP (
        value1 => reg1_out_internal,
        value2 => reg2_out_internal,
        taken => branch_taken_internal,
        ctl => branch_ctl
    );

    decode_stage : process( clk )

    variable opcode : std_logic_vector(5 downto 0);
    variable rs : std_logic_vector(reg_adrsize-1 downto 0);
    variable rt : std_logic_vector(reg_adrsize-1 downto 0);
    variable rd : std_logic_vector(reg_adrsize-1 downto 0);
    variable shamt : std_logic_vector(4 downto 0);
    variable funct : std_logic_vector(5 downto 0);
    begin
        branch_ctl <= "00";
        immediate_out_internal <= std_logic_vector(resize(signed(instruction_in(15 downto 0)), immediate_out_internal'length));
        opcode := instruction_in(31 downto 26);
        rs := instruction_in(25 downto 21);
        rt := instruction_in(20 downto 16);
        rd := instruction_in(15 downto 11);
        shamt := instruction_in(10 downto 6);
        funct := instruction_in(5 downto 0);
        offset_select <= '0';

        load <= '0';
        store <='0';
        write_back_enable <= '1';

        r1 <= rs;
        r2 <= rt;

        byte <= '1';

        --alu operators signals

        if opcode = "000000" then
            -- r-type instruction
            dest_register_address <= rd;
            use_imm <= '0';

            case( funct ) is

                when "100000" =>
                    -- add
                    alu_op <= "0000";

                when "100100" =>
                    -- and
                    alu_op <= "0001";

                when "011010" =>
                    -- div
                    alu_op <= "0010";
                    write_back_enable <= '0';

                when "100111" =>
                    -- nor
                    alu_op <= "1000";

                when "100101" =>
                    -- or
                    alu_op <= "1001";

                when "101010" =>
                    -- slt
                    alu_op <= "1011";

                when "100010" =>
                    -- sub
                    alu_op <= "1110";

                when "001110" =>
                    -- xor
                    alu_op <= "1111";

                when "010100" =>
                    -- mult
                    alu_op <= "0111";
                    write_back_enable <= '0';

                when "010000" =>
                    -- mfhi
                    alu_op <= "0101";

                when "010010" =>
                    -- mflo
                    alu_op <= "0110";

                when "000000" =>
                    -- sll
                    -- NOTE: shift amount will be in immediate field. ALU mux for input 2 must be set properly
                    alu_op <= "1010";
                    immediate_out_internal <= std_logic_vector(resize(signed(shamt), immediate_out_internal'length));
                    use_imm <= '1';
                    r1 <= rt;

                when "000010" =>
                    -- srl
                    -- NOTE: shift amount will be in immediate field. ALU mux for input 2 must be set properly
                    alu_op <= "1101";
                    immediate_out_internal <= std_logic_vector(resize(signed(shamt), immediate_out_internal'length));
                    use_imm <= '1';
                    r1 <= rt;

                when "000011" =>
                    -- sra
                    -- NOTE: shift amount will be in immediate field. ALU mux for input 2 must be set properly
                    alu_op <= "1100";
                    immediate_out_internal <= std_logic_vector(resize(signed(shamt), immediate_out_internal'length));
                    use_imm <= '1';
                    r1 <= rt;

                when "001000" =>
                    -- jr
                    -- NOTE : the output of r2 is used as the PC offset
                    -- ALU is issued nop (add r0 + 0) with immediate value
                    alu_op <= "0000";
                    r1 <= (others => '0');
                    r2 <= rs;
                    branch_ctl <= "11";
                    offset_select <='1';
                    use_imm <= '1';
                    immediate_out_internal <= (others => '0');
                    write_back_enable <= '0';

                when others =>
                    alu_op <= "0000";
                    r1 <= "00000";
                    r2 <= "00000";
                    write_back_enable <= '0';
            end case ;

        elsif opcode = "000010" then
            -- j
            -- alu is issued nop (add r0 + r0)
            immediate_out_internal <=  To_StdLogicVector(to_bitvector(std_logic_vector(resize(signed(instruction_in(15 downto 0)), immediate_out_internal'length))) sll 2);
            r1 <= (others => '0');
            r2 <= (others => '0');
            branch_ctl <= "11";
            write_back_enable <= '0';

        elsif opcode = "000011" then
            -- jal
            immediate_out_internal <=  To_StdLogicVector(to_bitvector(std_logic_vector(resize(signed(instruction_in(15 downto 0)), immediate_out_internal'length))) sll 2);
            r1 <= (others => '0');
            r2 <= (others => '0');
            branch_ctl <= "11";
            write_back_enable <= '0';
            -- TODO: indicate the need to store current PC

        else
            dest_register_address <= rt;
            use_imm <= '1';
            case( opcode ) is

                when "001000" =>
                    -- addi
                    alu_op <= "0000";
                when "001100" =>
                    -- andi
                    alu_op <= "0001";
                    immediate_out_internal <= zero16b & instruction_in(15 downto 0); -- zero extended instead of sign extended

                when "001101" =>
                    -- ori
                    alu_op <= "1001";
                    immediate_out_internal <= zero16b & instruction_in(15 downto 0); -- zero extended instead of sign extended

                when "001110" =>
                    -- xori
                    alu_op <= "1111";
                    immediate_out_internal <= zero16b & instruction_in(15 downto 0); -- zero extended instead of sign extended

                when "100000" =>
                    -- lb
                    alu_op <= "0000";
                    load <= '1';
                    byte <= '0';

                when "100101" =>
                    -- lhu
                    alu_op <= "0000";
                    load <= '1';

                when "110000" =>
                    -- ll
                    alu_op <= "0000";
                    load <= '1';

                when "100011" =>
                    -- lw
                    alu_op <= "0000";
                    load <= '1';

                when "001111" =>
                    -- lui
                    alu_op <= "0100";
                    load <= '1';

                when "101000" =>
                    -- sb
                    alu_op <= "0000";
                    store <= '1';
                    byte <= '0';
                    write_back_enable <= '0';

                when "101011" =>
                    -- sw
                    alu_op <= "0000";
                    store <= '1';
                    write_back_enable <= '0';

                when "001010" =>
                    -- stli
                    alu_op <= "1011";

                when "000100" =>
                    -- beq
                    alu_op <= "0000";
                    branch_ctl <= "01";
                    use_imm <= '0';
                    immediate_out_internal <=  To_StdLogicVector(to_bitvector(std_logic_vector(resize(signed(instruction_in(15 downto 0)), immediate_out_internal'length))) sll 2);
                    -- r1 <= (others => '0');
                    -- r2 <= (others => '0');
                    write_back_enable <= '0';

                when "000101" =>
                    -- bne
                    alu_op <= "0000";
                    use_imm <= '0';
                    branch_ctl <= "10";
                    immediate_out_internal <=  To_StdLogicVector(to_bitvector(std_logic_vector(resize(signed(instruction_in(15 downto 0)), immediate_out_internal'length))) sll 2);
                    -- r1 <= (others => '0');
                    -- r2 <= (others => '0');
                    write_back_enable <= '0';

                when others =>
                    null;

            end case ;
        end if ;
    end process ; -- decode_stage

    immediate_out <= immediate_out_internal;
    reg1_out <= reg1_out_internal;
    reg2_out <= reg2_out_internal;

    reg1_addr <= r1;
    reg2_addr <= r2;

    dest : process( immediate_out_internal, offset_select, reg2_out_internal )
    begin
        if offset_select = '0' then
            offset <= immediate_out_internal;
        else
            offset <= reg2_out_internal;
        end if;
    end process ; -- dest

    compute_branch_target : process( offset )
    begin
        branch_dest <= std_logic_vector(signed(offset) + signed(pc_in)-4);
    end process ; -- compute_branch_target

    branch_taken <= branch_taken_internal;

    with branch_taken_internal select pc_out <=
        branch_dest when '1',
        pc_in when others;


end architecture ; -- arch
