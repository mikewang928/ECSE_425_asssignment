proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/decode/clk
    add wave -position end  sim:/decode/instruction_in
    add wave -position end  -radix unsigned sim:/decode/dest_register_address
    add wave -position end  -radix unsigned sim:/decode/r1
    add wave -position end  -radix unsigned sim:/decode/r2
    
    add wave -group "ALU Control" -radix alu sim:/decode/alu_op\
        -radix binary sim:/decode/use_imm\
        -radix decimal sim:/decode/reg1_out\
        -radix decimal sim:/decode/reg2_out\
        -radix decimal sim:/decode/immediate_out

    add wave -position end  sim:/decode/load
    add wave -position end  sim:/decode/store

    add wave -position end -radix unsigned sim:/decode/pc_in
    add wave -position end -radix unsigned sim:/decode/pc_out

    add wave -group "Branch Compa"  -radix signed sim:/decode/reg_comparator/value1\
                                    -radix signed sim:/decode/reg_comparator/value2\
                                    -radix unsigned sim:/decode/branch_dest\
                                    -radix br_ctl sim:/decode/branch_ctl\
                                    -radix binary sim:/decode/branch_taken
}

;#Generates a clock of period 1 ns on the clk input pin of the memory arbiter.
proc GenerateCPUClock {} { 
    force -deposit /decode/clk 0 0 ns, 1 0.5 ns -repeat 1 ns
}

proc RadixDefine {} {
    radix define alu {
        4'b0000 "ADD",
        4'b0001 "AND",
        4'b0010 "DIV",
        4'b0011 "EQUALS",
        4'b0100 "LUI",
        4'b0101 "MFHI",
        4'b0110 "MFLO",
        4'b0111 "MULT",
        4'b1000 "NOR",
        4'b1001 "OR",
        4'b1010 "SLL",
        4'b1011 "SLT",
        4'b1100 "SRA",
        4'b1101 "SRL",
        4'b1110 "SUB",
        4'b1111 "XOR"
    }

    radix define br_ctl {
        2'b00 "NO",
        2'b01 "EQ",
        2'b10 "NE",
        2'b11 "J"
    }
}

proc assert condition {
    if {![uplevel 1 expr $condition]} {
        return -code error "assertion failed: $condition"
    }
 }

proc Init {} {
    vlib work

    #Compile

    vcom ALU.vhd
    vcom memory_arbiter_lib.vhd
    vcom shifter.vhd
    vcom Register.vhd
    vcom comparator.vhd
    vcom PC.vhd
    vcom decode.vhd

    ; # Start Simulation

    vsim decode
    RadixDefine
    AddWaves
    GenerateCPUClock

    force -deposit /decode/n_reset 0 0 ns, 1 1 ns 
    run 1 ns

}

Init 

force -deposit /decode/pc_in "00000000010010101000000001011000" 0

echo "jump: add \$9 \$10 \$11"
force -deposit /decode/instruction_in "00000001010010110100100000100000"
run 1 ns

echo "addi \$2, \$4, 138"
force -deposit /decode/instruction_in "00100000100000100000000010001010"
run 1 ns

echo "lw \$25, 17(\$7)"
force -deposit /decode/instruction_in "10001100111110010000000000010001"
run 1 ns

echo "beq \$3, \$18, jump"
force -deposit /decode/instruction_in "00010010010000111111111111111101"
run 1 ns
assert {[exa /decode/branch_taken] == 1}
assert {[exa /decode/r1] == 0}
assert {[exa /decode/r2] == 0}


echo "sw \$8, 38(\$4)"
force -deposit /decode/instruction_in "10101100100010000000000000100110"
run 1 ns

echo "lui \$30, 0x1382"
force -deposit /decode/instruction_in "00111100000111100001001110000010"
run 1 ns

echo "and \$1, \$2, \$3"
force -deposit /decode/instruction_in "00000000010000110000100000100100"
run 1 ns

echo "jr \$8"
force -deposit /decode/instruction_in "00000001000000000000000000001000"
run 1 ns
assert {[exa /decode/branch_taken] == 1}

echo "nor \$4, \$7, \$9"
force -deposit /decode/instruction_in "00000000111010010010000000100111"
run 1 ns

echo "or \$14, \$15, \$16"
force -deposit /decode/instruction_in "00000001111100000111000000100101"
run 1 ns

echo "sll \$8, \$4, \$1"
force -deposit /decode/instruction_in "00000000000001000100000001000000"
run 1 ns

echo "banana: slt \$1, \$2, \$3"
force -deposit /decode/instruction_in "00000000010000110000100000101010"
run 1 ns

echo "srl \$8, \$5, \$1"
force -deposit /decode/instruction_in "00000000000001010100000001000010"
run 1 ns

echo "sub \$14, \$8, \$3"
force -deposit /decode/instruction_in "00000001000000110111000000100010"
run 1 ns

echo "div \$0, \$4"
force -deposit /decode/instruction_in "00000000000001000000000000011010"
run 1 ns

echo "mflo \$27"
force -deposit /decode/instruction_in "00000000000000001101100000010010"
run 1 ns

echo "mfhi \$30"
force -deposit /decode/instruction_in "00000000000000001111000000010000"
run 1 ns

echo "mult \$9, \$17"
force -deposit /decode/instruction_in "00000001001100010000000000010100"
run 1 ns

echo "xor \$7, \$16, \$9"
force -deposit /decode/instruction_in "00000010000010010011100000100110"
run 1 ns

echo "sra \$19, \$6, \$23"
force -deposit /decode/instruction_in "00000000000001101001110111000011"
run 1 ns

echo "addi \$6, \$4, 0x75"
force -deposit /decode/instruction_in "00100000100001100000000001110101"
run 1 ns

echo "andi \$1, \$2, banana"
force -deposit /decode/instruction_in "00110000010000011111111111110110"
run 1 ns

echo "bne \$8, \$3, banana"
force -deposit /decode/instruction_in "00010100011010001111111111110101"
run 1 ns
assert {[exa /decode/branch_taken] == 0}
assert {[exa /decode/r1] == 0}
assert {[exa /decode/r2] == 0}

echo "lb \$19, (\$4) "
force -deposit /decode/instruction_in "10000000100100110000000000000000"
run 1 ns


