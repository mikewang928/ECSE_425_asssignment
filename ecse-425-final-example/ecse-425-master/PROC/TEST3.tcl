proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window

add wave -group "Hazard Detection" sim:/PROCv3/enable_stall

add wave -group "Control Signals" sim:/PROCv3/clk\
sim:/PROCv3/ex_reset\
sim:/PROCv3/id_reset\
sim:/PROCv3/if_reset\
sim:/PROCv3/mem_reset

add wave -group "IF in buffers" sim:/PROCv3/if_pc_in_buffer\
sim:/PROCv3/if_pc_sel_in_buffer\
sim:/PROCv3/if_pc_enable_in_buffer

add wave -group "IF out signals" sim:/PROCv3/if_pc_out\
sim:/PROCv3/if_inst_out

add wave -group "ID in buffers" sim:/PROCv3/id_inst_in_buffer\
sim:/PROCv3/id_wenable_in_buffer\
sim:/PROCv3/id_reg_add_in_buffer\
sim:/PROCv3/id_reg_data_in_buffer\
sim:/PROCv3/id_pc_in_buffer

add wave -group "ID out signals" sim:/PROCv3/id_pc_out\
sim:/PROCv3/id_alu_op_out\
sim:/PROCv3/id_r1_out\
sim:/PROCv3/id_r2_out\
sim:/PROCv3/id_imm_out\
sim:/PROCv3/id_dest_regadd_out\
sim:/PROCv3/id_loaden_out\
sim:/PROCv3/id_storeen_out\
sim:/PROCv3/id_useimm_out\
sim:/PROCv3/id_branch_out\
sim:/PROCv3/id_byte_out\
sim:/PROCv3/id_WB_enable_out

add wave -group "EX in buffers" sim:/PROCv3/ex_r1_in_buffer\
sim:/PROCv3/ex_r2_in_buffer\
sim:/PROCv3/ex_imm_in_buffer\
sim:/PROCv3/ex_dest_regadd_in_buffer\
sim:/PROCv3/ex_alu_op_in_buffer\
sim:/PROCv3/ex_ALUData1_selector0_in_buffer\
sim:/PROCv3/ex_ALUData1_selector1_in_buffer\
sim:/PROCv3/ex_ALUData2_selector0_in_buffer\
sim:/PROCv3/ex_ALUData2_selector1_in_buffer\
sim:/PROCv3/ex_loaden_in_buffer\
sim:/PROCv3/ex_storeen_in_buffer\
sim:/PROCv3/ex_stall_in_buffer\
sim:/PROCv3/ex_stall_in_buffer0\
sim:/PROCv3/ex_byte_in_buffer\
sim:/PROCv3/ex_WB_enable_in_buffer


add wave -group "EX out signals" sim:/PROCv3/ex_ALU_result_out\
sim:/PROCv3/ex_dest_regadd_out\
sim:/PROCv3/ex_loaden_out\
sim:/PROCv3/ex_storeen_out\
sim:/PROCv3/ex_mem_data_out\
sim:/PROCv3/ex_byte_out\
sim:/PROCv3/ex_WB_enable_out

add wave -group "MEM in buffers" sim:/PROCv3/mem_data_in_buffer\
sim:/PROCv3/mem_address_in_buffer\
sim:/PROCv3/mem_access_write_in_buffer\
sim:/PROCv3/mem_byte_in_buffer\
sim:/PROCv3/mem_WB_enable_in_buffer\
sim:/PROCv3/mem_WB_address_in_buffer


add wave -group "MEM out signals" sim:/PROCv3/mem_WB_enable_out\
sim:/PROCv3/mem_WB_address_out\
sim:/PROCv3/mem_WB_data_out

add wave -group "WB in buffers" sim:/PROCv3/wb_WB_enable_in_buffer\
sim:/PROCv3/wb_WB_address_in_buffer\
sim:/PROCv3/wb_WB_data_in_buffer

    
    
}
;

proc runsim {} {
      vsim PROCv3 -t ps
    
    AddWaves
;#run 1 ns
  force -deposit /PROCv3/if_pc_enable_in_buffer 0 0 ns
  force -deposit /PROCv3/MEMstage/mem_access_write 0 0
  force -deposit /PROCv3/MEMstage/data_in "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" 0
  force -deposit /PROCv3/MEMstage/data_out "00000000000000000000000000000000" 0
  force -deposit /PROCv3/MEMstage/address_in "00000000000000000000000000000000" 0
  force -deposit /PROCv3/MEMstage/byte 0 0

    GenerateCPUClock

    force -deposit /PROCv3/reset 0 0  
    

  loadInstructions
  run 1 ns
  force -deposit /PROCv3/if_pc_in_buffer "00000000000000000000000000110000" 0
  force -deposit /PROCv3/if_pc_enable_in_buffer 1 0 ns
  force -deposit /PROCv3/reset 1 1
    run 10 ns

}

proc loadInstructions {} {
  force -deposit PROCv3/IFstage/instruction_memory/initialize 0 0 ns, 1 1 ns, 0 2 ns
  ;#run 1 ns ;#Force signals to update right away
}

proc GenerateCPUClock {} { 
    force -deposit /PROCv3/clock 0 0 ns, 1 0.5 ns -repeat 1 ns
}


proc Init {} {
    vlib work

    #Compile
vcom Memory_in_Byte.vhd
vcom memory_arbiter_lib.vhd
vcom Main_Memory.vhd
vcom Data_Mem.vhd
vcom MEM.vhd
vcom PC.vhd
vcom fetch.vhd
vcom shifter.vhd
vcom comparator.vhd
vcom Register.vhd
vcom decode.vhd
vcom ALU.vhd
vcom mux41.vhd
vcom EX.vhd
vcom PROCv3.vhd

    ; # Start Simulation


}




