proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/PROC/clock
    add wave -position end  sim:/PROC/inst
    add wave -position end  sim:/PROC/we
    add wave -position end  sim:/PROC/writeadd
    add wave -position end  sim:/PROC/writedat
    add wave -position end  sim:/PROC/resetn
    add wave -position end  sim:/PROC/RDDO
    add wave -position end  sim:/PROC/RDAO
    add wave -position end  sim:/PROC/PCEO
    add wave -position end  sim:/PROC/BT
    add wave -position end  sim:/PROC/MAWEO
    add wave -position end  sim:/PROC/MAREO
    add wave -position end  sim:/PROC/RAEO
    add wave -position end  sim:/PROC/ZEROEO

    add wave -position end  sim:/PROC/clk
    add wave -position end  sim:/PROC/instBuffer
    add wave -position end  sim:/PROC/WEBuffer
    add wave -position end  sim:/PROC/WRABuffer
    add wave -position end  sim:/PROC/WRDBuffer
    add wave -position end  sim:/PROC/RSTBuffer

    add wave -position end  sim:/PROC/alu_opO
    add wave -position end  sim:/PROC/reg1_outO
    add wave -position end  sim:/PROC/reg2_outO
    add wave -position end  sim:/PROC/immediate_outO
    add wave -position end  sim:/PROC/dest_register_addressO 
    add wave -position end  sim:/PROC/use_immO

    add wave -position end  sim:/PROC/RSDBuffer
    add wave -position end  sim:/PROC/RTDBuffer  
    add wave -position end  sim:/PROC/IMMBuffer
    add wave -position end  sim:/PROC/RDAIBuffer
    add wave -position end  sim:/PROC/FCodeBuffer
    add wave -position end  sim:/PROC/D1Sel0Buffer
    add wave -position end  sim:/PROC/D2Sel0Buffer 


    
    
    
}
;
proc GenerateCPUClock {} { 
    force -deposit /PROC/clock 0 0 ns, 1 0.5 ns -repeat 1 ns
}


proc Init {} {
    vlib work

    #Compile

vcom memory_arbiter_lib.vhd
vcom shifter.vhd
vcom Register.vhd
vcom PC.vhd
vcom decode.vhd
vcom ALU.vhd
vcom mux41.vhd
vcom EX.vhd
vcom PROC.vhd

    ; # Start Simulation

    vsim PROC
    
    AddWaves
    GenerateCPUClock

    force -deposit /PROC/resetn 0 0 ns, 1 1 ns 
    run 1 ns


}

Init

echo "NULL COMMAND"
force -deposit /PROC/inst "00000000000000000000000000000000"
force -deposit /PROC/we '0'
force -deposit /PROC/writeadd "00000"
force -deposit /PROC/writedat "00000000000000000000000000000000"
run 1.5 ns

echo "or \$14, \$15, \$16"
force -deposit /PROC/inst "00000001111100000111000000100101"
run 1 ns

echo "addi \$2, \$4, 138"
force -deposit /PROC/inst "00100000100000100000000010001010"
run 1 ns

echo "NULL COMMAND"
force -deposit /PROC/inst "00000000000000000000000000000000"
run 10 ns