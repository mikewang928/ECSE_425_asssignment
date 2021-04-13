proc AddWaves {} {
	add wave -position end sim:/fetch_tb/clk
    add wave -position end sim:/fetch_tb/fetch_out
	add wave -position end sim:/fetch_tb/dut/pc
	add wave -position end sim:/fetch_tb/dut/next_pc
	add wave -position end sim:/fetch_tb/pc_out
	add wave -position end sim:/fetch_tb/pc_in
	add wave -position end sim:/fetch_tb/pc_src
	add wave -position end sim:/fetch_tb/pc_stall
	add wave -position end sim:/fetch_tb/reset
	add wave -position end sim:/fetch_tb/dut/i_mem/address
	add wave -position end sim:/fetch_tb/dut/i_mem/readdata
}

vlib work

vcom fetch.vhd
vcom fetch_tb.vhd

vsim -t ps work.fetch_tb

AddWaves

run 30ns
