PC.vhd: 
	1, if reset = 0, setting all pc to 0
	2, if at rising_edge of the clock and enable = 1, push pc_in into pc_out