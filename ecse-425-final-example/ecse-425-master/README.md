# MIPS 5 Stage Pipeline

Author: 

 - Wei-Di Chang
 - David Lavoie-Boutin
 - Muhammad Ali Lashari
 - Sitara Sheriff

VHDL description of a 5-stage mips pipeline implementing early branch resolution, forwarding and hazard detection. This processor was implemented as a project deliverable for ECSE 425, Computer Organisation and Architecture.

*For testing instruction, jump to the testing [section](https://github.com/dlavoieb/ecse-425#testing)*

## Assembler

The assembler translates a program written in MIPS assembly to its binary format, ready to be executed by our processor. 

### Requirements

The assembler requires Python version 2.7 which can be downloaded [from here](https://www.python.org/downloads/release/python-2711/)

### Usage

The assembler is executed from the command line, so open a terminal window and navigate to the location of the executable `Assembler.py`. Make sure you have downloaded the file `mips-isa.json` which contains the list of supported mips operations and their structure.

So simply call the executable with the proper arguments

```
$ Assembler.py -i mips-ias.json -a fib.asm
```

*The `-i` flag specifies the path to the isa description. The `-a` flag specifies the path to the assembly program to assemble.*

The output of the assembler is a file, which will be at the same location as the input assembly file. Its name will be the same as the assembly with the `.bin` suffix added. You will need to rename that file to `Init.dat` and place it in the same folder as the MainMemory.vhd file.

## Processor

![mips pipeline group 10 - mips processor v1](https://cloud.githubusercontent.com/assets/5551220/14159058/cd0525b0-f6a1-11e5-8e37-bbeb88e81a52.png)

The processor description is separated in stages, starting with fetch.vhd, decode.vhd, EX.vhd and MEM.vhd. All the stages are integrated with the control unit for forwarding and hazard detection in the main component: PROC.vhd.

In this implementation, the pipeline buffers (yellow blocks in the diagram) latch their values on the falling edge. This insures that on the next rising edge, the values are available for the stages to compute with. This is our simplification of the setup time requirement.

### Instruction Fetch

In this stage, we increment a program counter and load the instructions from the instruction memory. The instruction fetched and next program counter are output of this stage.

The content of the `Init.dat` file are loaded in this memory block by the test scripts, **so make sure** the content of that file is the program you want to execute.

### Instruction Decode

The instruction decode stage parses the instruction received from the fetch stage and sets the proper control signals for the execute stage. 

It also implements early branch resolution, so branch and jump statements (and their target program counter) get computed in this stage. If the branch is taken, the rest of the pipeline is staled and the pc is updated.

The output of this stage include (but not limited to):

- Register data content
- Sign or zero extended immediate value
- Immediate selection control signal
- Memory load or store control signal

### Execute

This stage wraps the ALU operations along with some multiplexer functions to allow for forwarding. 

| ALU Operation | Function Code |
|:-------------:|:-------------:|
| ADD			| 0000			|
| AND			| 0001			|
| DIV			| 0010			|
| EQUALS		| 0011			|
| LUI			| 0100			|
| MFHI			| 0101			|
| MFLO			| 0110			|
| MULT			| 0111			|
| NOR			| 1000			|
| OR 			| 1001			|
| SLL			| 1010			|
| SLT			| 1011			|
| SRA			| 1100			|
| SRL			| 1101			|
| SUB			| 1110			|
| XOR			| 1111			|


### Memory

This is where the interface with data memory happens. Data content and address are computer in the execute stage and fed to the memory.

### Write Back stage

Simply feed the proper signals from EX and MEM back to the register file in the decode stage.

## Testing

 1. Assemble the program to a binary file.
 2. Rename that compiled file to `Init.dat`
 3. Move that file in the project folder with the processor
 4. Source the test script `processor.tcl`
 5. Initialise the simulation with the command `Init`
 6. Run the simulation with the command `runsim`


The script will load the instruction content in `Init.dat` inside the instruction memory, it will compile all the components and start the simulation. 

**You might need to change the run duration to make sure you run the processor long enough.**

The input and output of each stage are grouped together, with the clock in the control signal group.

## Current Problems

The main branch fully implements forwarding and hazard detection. For 1-bit and 2-bit prediction implementation, refer to the other branches. The predictions affect the program counter correctly, however, the stalling logic does not respond well to those changes. Therefore, it is not fully merged back with master.
