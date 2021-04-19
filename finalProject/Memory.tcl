vlib work

;# Compile components if any
vcom Memory.vhd
vcom Memory_tb.vhd


;# Start simulation
vsim Memory_tb

;# Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/Memory_tb/clk
    add wave -position end sim:/Memory_tb/mem_write_in
    add wave -position end sim:/Memory_tb/mem_read_in
    add wave -position end sim:/Memory_tb/alu_in
    add wave -position end sim:/Memory_tb/read_data
    add wave -position end sim:/Memory_tb/alu_out

}

;# Add the waves
AddWaves
;# Run for 500 ns
run 500ns
