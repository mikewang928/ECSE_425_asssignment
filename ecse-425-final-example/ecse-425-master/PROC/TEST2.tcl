proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window

add wave -group "Control Signals" sim:/PROCv2/clk\
sim:/PROCv2/ex_reset\
sim:/PROCv2/id_reset\
sim:/PROCv2/if_reset\
sim:/PROCv2/mem_reset

add wave -group "Hazard Detection" sim:/PROCv2/enable_stall

add wave -group "IF in buffers" -radix unsigned sim:/PROCv2/if_pc_in_buffer\
-radix binary sim:/PROCv2/if_pc_sel_in_buffer\
-radix binary sim:/PROCv2/if_pc_enable_in_buffer

add wave -group "IF out signals" -radix unsigned sim:/PROCv2/if_pc_out\
-radix binary sim:/PROCv2/if_inst_out

add wave -group "ID in buffers" -radix binary sim:/PROCv2/id_inst_in_buffer\
sim:/PROCv2/id_wenable_in_buffer\
-radix unsigned sim:/PROCv2/id_reg_add_in_buffer\
-radix binary sim:/PROCv2/id_reg_data_in_buffer\
-radix unsigned sim:/PROCv2/id_pc_in_buffer

add wave -group "ID out signals" -radix unsigned sim:/PROCv2/id_pc_out\
-radix alu sim:/PROCv2/id_alu_op_out\
-radix decimal sim:/PROCv2/id_r1_out\
-radix decimal sim:/PROCv2/id_r2_out\
-radix decimal sim:/PROCv2/id_imm_out\
-radix unsigned sim:/PROCv2/id_dest_regadd_out\
-radix binary sim:/PROCv2/id_loaden_out\
sim:/PROCv2/id_storeen_out\
sim:/PROCv2/id_useimm_out\
sim:/PROCv2/id_branch_out\
sim:/PROCv2/id_byte_out\
sim:/PROCv2/id_WB_enable_out\
-radix unsigned sim:/PROCv2/id_reg1_addr_out\
-radix unsigned sim:/PROCv2/id_reg2_addr_out

add wave -group "EX in buffers" -radix decimal sim:/PROCv2/ex_r1_in_buffer\
-radix decimal sim:/PROCv2/ex_r2_in_buffer\
-radix decimal sim:/PROCv2/ex_imm_in_buffer\
-radix unsigned sim:/PROCv2/ex_dest_regadd_in_buffer\
-radix alu sim:/PROCv2/ex_alu_op_in_buffer\
-radix binary sim:/PROCv2/ex_ALUData1_selector0_in_buffer\
sim:/PROCv2/ex_ALUData1_selector1_in_buffer\
sim:/PROCv2/ex_ALUData2_selector0_in_buffer\
sim:/PROCv2/ex_ALUData2_selector1_in_buffer\
sim:/PROCv2/ex_loaden_in_buffer\
sim:/PROCv2/ex_storeen_in_buffer\
sim:/PROCv2/ex_stall_in_buffer\
sim:/PROCv2/ex_stall_in_buffer0\
sim:/PROCv2/ex_byte_in_buffer\
sim:/PROCv2/ex_WB_enable_in_buffer\
-radix decimal sim:/PROCv2/ex_alu_result_in\
-radix decimal sim:/PROCv2/EXstage/X1\
-radix decimal sim:/PROCv2/EXstage/X2

add wave -group "EX out signals" -radix decimal sim:/PROCv2/ex_ALU_result_out\
-radix unsigned sim:/PROCv2/ex_dest_regadd_out\
-radix binary sim:/PROCv2/ex_loaden_out\
sim:/PROCv2/ex_storeen_out\
sim:/PROCv2/ex_mem_data_out\
sim:/PROCv2/ex_byte_out\
sim:/PROCv2/ex_WB_enable_out

add wave -group "MEM in buffers" -radix decimal sim:/PROCv2/mem_data_in_buffer\
-radix unsigned sim:/PROCv2/mem_address_in_buffer\
-radix binary sim:/PROCv2/mem_access_write_in_buffer\
sim:/PROCv2/mem_byte_in_buffer\
sim:/PROCv2/mem_WB_enable_in_buffer\
-radix unsigned sim:/PROCv2/mem_WB_address_in_buffer\
-radix decimal sim:/PROCv2/MEMstage/data_selected\
-radix unsigned sim://PROCv2/MEMstage/data_memory/port_adr


add wave -group "MEM out signals" -radix binary sim:/PROCv2/mem_WB_enable_out\
-radix unsigned sim:/PROCv2/mem_WB_address_out\
-radix decimal sim:/PROCv2/mem_WB_data_out

add wave -group "WB in buffers" -radix binary sim:/PROCv2/wb_WB_enable_in_buffer\
-radix unsigned sim:/PROCv2/wb_WB_address_in_buffer\
-radix decimal sim:/PROCv2/wb_WB_data_in_buffer
}
;

proc runsim {} {
      vsim PROCv2 -t ps

    AddWaves
;#run 1 ns
  force -deposit /PROCv2/if_pc_enable_in_buffer 0 0 ns
  force -deposit /PROCv2/MEMstage/mem_access_write 0 0
  force -deposit /PROCv2/MEMstage/data_in "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" 0
  force -deposit /PROCv2/MEMstage/data_out "00000000000000000000000000000000" 0
  force -deposit /PROCv2/MEMstage/address_in "00000000000000000000000000000000" 0
  force -deposit /PROCv2/MEMstage/byte 0 0

    GenerateCPUClock

    force -deposit /PROCv2/reset 0 0


  loadInstructions
  run 1 ns
  force -deposit /PROCv2/if_pc_in_buffer "00000000000000000000000000110000" 0
  force -deposit /PROCv2/if_pc_enable_in_buffer 1 0 ns
  force -deposit /PROCv2/reset 1 1
    run 18 ns

}

proc loadInstructions {} {
  force -deposit PROCv2/IFstage/instruction_memory/initialize 0 0 ns, 1 1 ns, 0 2 ns
  ;#run 1 ns ;#Force signals to update right away
}

proc GenerateCPUClock {} {
    force -deposit /PROCv2/clock 0 0 ns, 1 0.5 ns -repeat 1 ns
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


proc Init {} {
    vlib work

    #Compile
vcom Memory_in_Byte.vhd
vcom memory_arbiter_lib.vhd
vcom Main_Memory.vhd
vcom memory_constants.vhd
vcom Data_Mem.vhd
vcom PC.vhd
vcom MEM.vhd
vcom fetch.vhd
vcom shifter.vhd
vcom comparator.vhd
vcom Register.vhd
vcom decode.vhd
vcom ALU.vhd
vcom mux41.vhd
vcom EX.vhd
vcom PROCv2.vhd

RadixDefine
}
