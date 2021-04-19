vlib work

;# Compile components if any
vcom WriteBack.vhd
vcom WriteBack_tb.vhd


;# Start simulation
vsim WriteBack_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/WriteBack_tb/clk
    add wave -position end sim:/WriteBack_tb/reg_write_in
    add wave -position end sim:/WriteBack_tb/mem_to_reg_in
    add wave -position end sim:/WriteBack_tb/alu_in
    add wave -position end sim:/WriteBack_tb/read_data
    add wave -position end sim:/WriteBack_tb/reg_to_write_in
    add wave -position end sim:/WriteBack_tb/mem_to_reg_out
    add wave -position end sim:/WriteBack_tb/write_data
    add wave -position end sim:/WriteBack_tb/reg_to_write_out

}

;# Add the waves
AddWaves
;# Run for 500 ns
run 500ns
