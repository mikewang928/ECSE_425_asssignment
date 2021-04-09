
;# This function is responsible for adding to the Waves window
;# the signals that are relevant to the fetch stage. This
;# allows the developers to inspect the behavior of the fetch stage
;# component as it is being simulated.
proc AddWaves {} {

	;#Add the following signals to the Waves window
	add wave -position end  -radix binary sim:/fetch/clk
  add wave -position end  -radix binary sim:/fetch/n_reset
	add wave -position end  -radix binary sim:/fetch/pc_enable

  ;#These signals will be contained in a group named "Port 1"
	add wave -group "Fetch"  -radix unsigned sim:/fetch/pc_out\
                            -radix unsigned sim:/fetch/pc_in\
                            -radix binary sim:/fetch/pc_sel\
                            -radix binary sim:/fetch/instruction_out

  ;#These signals will be contained in a group named "Main Memory"
  add wave -group "Main Memory" -radix binary sim:/fetch/instruction_memory/initialize\
                -radix unsigned sim:/fetch/im_address\
                sim:/fetch/im_re\
                sim:/fetch/im_rd_ready

 
  ;#Set some formating options to make the Waves window more legible
	configure wave -namecolwidth 250
	WaveRestoreZoom {0 ns} {8 ns}
}

;#Generates a clock of period 1 ns on the clk input pin of the fetch stage.
proc GenerateCPUClock {} {
	force -deposit /fetch/clk 0 0 ns, 1 0.5 ns -repeat 1 ns
}

proc assert condition {
  if {![uplevel 1 expr $condition]} {
    return -code error "assertion failed: $condition"
  }
}

proc loadInstructions {} {
  force -deposit /fetch/instruction_memory/initialize 0 0 ns, 1 1 ns, 0 2 ns
  run 2 ns ;#Force signals to update right away
}

;#This function compiles the fetch stage and its components.
;#It initializes a fetch stage simulation session, and
;#sets up the Waves window to contain useful input/output signals
;#for debugging.
proc InitFetch {} {
  ;#Create the work library, which is the default library used by ModelSim
  vlib work

  ;#Compile the fetch stage and its subcomponents
  vcom Memory_in_Byte.vhd
  vcom memory_arbiter_lib.vhd
  vcom Main_Memory.vhd
  vcom PC.vhd
  vcom fetch.vhd

  ;#Start a simulation session with the fetch component
  vsim -t ps fetch

  ;#Add the fetch stage's input and ouput signals to the waves window
  ;#to allow inspecting the module's behavior
	AddWaves

  force -deposit /fetch/n_reset 0 0 ns, 1 1 ns
  force -deposit /fetch/pc_enable 0 0 ns
  force -deposit /fetch/pc_sel 0 0

  ;#Generate a CPU clock
	GenerateCPUClock

  run 1 ns
  loadInstructions
  run 1 ns

  force -deposit /fetch/pc_enable 1 0
  run 5 ns
   # DO STUFF
}

InitFetch

force -deposit /fetch/pc_in "00000000000000000000000000110000" 0
force -deposit /fetch/pc_sel 1 0 ns, 0 1 ns

# assert {[exa /fetch/pc_out] == "00000000000000000000000000010100" }
run 1 ns
# assert {[exa /fetch/pc_out] == "00000000000000000000000000100000"}
run 3 ns 
