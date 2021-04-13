proc AddWaves {} {
	add wave -position end sim:/fetch_tb/clk
    add wave -position end sim:/fetch_tb/fetch_out
	add wave -position end sim:/fetch_tb/dut/pc
	add wave -position end sim:/fetch_tb/dut/next_pc
	add wave -position end sim:/fetch_tb/dut/adder_out
	add wave -position end sim:/fetch_tb/dut/s_waitrequest
	add wave -position end sim:/fetch_tb/dut/pc_stall
}

vlib work

vcom fetch.vhd
vcom fetch_tb.vhd

vsim -t ps work.fetch_tb

AddWaves

run 30ns
