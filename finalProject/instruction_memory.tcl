proc AddWaves {} {
	add wave -position end sim:/instruction_memory_tb/clk
    add wave -position end sim:/instruction_memory_tb/address
    add wave -position end sim:/instruction_memory_tb/memread
    add wave -position end sim:/instruction_memory_tb/readdata
	add wave -position end sim:/instruction_memory_tb/waitrequest
}

vlib work

vcom instruction_memory.vhd
vcom instruction_memory_tb.vhd

vsim -t ps work.instruction_memory_tb

AddWaves

run 30ns
