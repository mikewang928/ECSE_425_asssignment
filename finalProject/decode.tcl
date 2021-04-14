proc AddWaves {} {
	add wave -position end sim:/decode_tb/clk
	add wave -position end sim:/decode_tb/instruction
	add wave -position end sim:/decode_tb/wb_data
	add wave -position end sim:/decode_tb/wb_reg
	add wave -position end sim:/decode_tb/wb
	add wave -position end sim:/decode_tb/pc_in	
	add wave -position end sim:/decode_tb/pc_target
	add wave -position end sim:/decode_tb/read_data_1
	add wave -position end sim:/decode_tb/read_data_2	
	add wave -position end sim:/decode_tb/rt_out
	add wave -position end sim:/decode_tb/rd_out
	add wave -position end sim:/decode_tb/rs_out	
	add wave -position end sim:/decode_tb/alu_op
	add wave -position end sim:/decode_tb/reg_dst
	add wave -position end sim:/decode_tb/branch
	add wave -position end sim:/decode_tb/mem_write
	add wave -position end sim:/decode_tb/mem_read
	add wave -position end sim:/decode_tb/reg_write
	add wave -position end sim:/decode_tb/mem_to_reg
}

vlib work

vcom decode.vhd
vcom decode_tb.vhd

vsim -t ps work.decode_tb

AddWaves

run 5ns
