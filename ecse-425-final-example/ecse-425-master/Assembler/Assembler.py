#!/usr/bin/env python
__author__ = 'David Lavoie-Boutin'

import re
import json

## Add a space at periodic intervals 
#
# @param string The string to add space to
# @param length The distance between each spaces
#
# @return The original strings with the added spaces
def encrypt(string, length):
    return ' '.join(string[i:i+length] for i in xrange(0,len(string),length))

## Build a two's complement string representation of a signed number.
#
# @param value The number to represent in two's complement.
# @param bits The number of bits the representation should have. This includes 
# the sign bit.
def twos_complement(value, bits):
    if value < 0:
        value += (1 << bits)
    formatstring = '{:0%ib}' % bits
    return formatstring.format(value)

## This translates an assembly program to binary code according to the MIPS isa 
# 
class Assembler(object):
    full_line_comment = re.compile(ur'^\s*#.*')
    inline_comment_regex = re.compile(ur'#.+$')
    label_regex = re.compile(ur'^.*?(?=:)')
    argument_regex = re.compile(ur'(-*[\w|$]+)')
    between_parentheses = re.compile(ur'(?<=\().+(?=\))')
    before_parentheses = re.compile(ur'(?<=\s).+(?=\()')

    ## Constructor creates file handles to the input and output files for the process.
    #
    # @param input_file The assembly program to be converted
    # @param mips_isa_file The instruction type definitions file. This must be a 
    # JSON formated file where each key should have at least a `type` sub-key.
    #
    def __init__(self, input_file, mips_isa_file):
        self.file_in = open(input_file, 'r')
        self.file_temp = open(input_file + ".json", 'w')
        self.file_out = open(input_file + ".bin", 'w')
        self.mips_isa_file = open(mips_isa_file, 'r')
        self.mips_isa = json.load(self.mips_isa_file)

        self.line_number = 0
        self.labels = {}

        self.queue = []

    ## Read all file and convert each instruction to machine code
    #
    # Parses each line to extract instructions and their arguments. Builds a 
    # queue with all instructions and arguments. Once reached file end, parses
    # each group in the queue to build a proper byte instruction.
    def run(self):
        self.process_file()
        json.dump({"instructions":self.queue, "labels":self.labels}, self.file_temp, indent=4, separators=(',', ': '))
        for ins in self.queue:
            self.build_machine_code(ins)

    ## Parse an argument and return the number to put in the instruction line 
    #
    # This function also compares the 
    #
    # @param index The index of the argument to parse in the group 
    # @param inst_list The group of arguments from the queue
    #
    # @ return The number to be formated for the instruction line
    def parse_argument(self, index, inst_list):
        try:
            current = inst_list[index]
        except IndexError:
            return 0

        try:
            target_line = self.labels[inst_list[index]]
            return target_line - inst_list[0]
        except KeyError:
            pass

        if '$' in current:
            return int(inst_list[index].strip("$"))
        elif "0x" in current:
            return int(inst_list[index], 16)
        else:
            return int(inst_list[index])

    ## Compile the current instructions' machine code representation
    #
    # Parse the type of instruction and chose proper instruction format.
    # Extract proper binary value from each argument based on instruction type
    # and assemble whole 32 bits of instruction. Finally append byte code to 
    # binary file.
    #
    # @param instruction a list containing the line number and all tokens 
    # extracted from the assembly code.
    #
    def build_machine_code(self, instruction):
        try:
            prop = self.mips_isa[instruction[1]]
        except KeyError:
            print("Invalid instruction identifier")
            print(instruction)
            exit(1)
            return
        except IndexError:
            return

        if prop["type"] == "r":
            rd = "{:05b}".format(0)
            rs = "{:05b}".format(0)
            rt = "{:05b}".format(0)
            sa = "{:05b}".format(0)

            if instruction[1] in ["sll", "srl", "sra"]:
                """
                    format : sll $rd, $rt, $sa
                """

                rt = "{:05b}".format(self.parse_argument(3,instruction))
                rd = "{:05b}".format(self.parse_argument(2,instruction))
                sa = "{:05b}".format(self.parse_argument(4,instruction))

            elif instruction[1] in ["div", "divu", "mult", "multu"]:
                """
                    format : div $rs, $rt
                """
                rs = "{:05b}".format(self.parse_argument(2,instruction))
                rt = "{:05b}".format(self.parse_argument(3,instruction))

            elif instruction[1] in ["mfhi", "mflo"]:
                """
                    format : mflo $rd
                """
                rd = "{:05b}".format(self.parse_argument(2,instruction))

            elif instruction[1] in ["jr"]:
                """
                    format : rj $rs
                """
                rs = "{:05b}".format(self.parse_argument(2,instruction))

            else:
                """
                    format : sll $rd, $rs, $rt
                """
                rs = "{:05b}".format(self.parse_argument(3,instruction))
                rt = "{:05b}".format(self.parse_argument(4,instruction))
                rd = "{:05b}".format(self.parse_argument(2,instruction))

            line = prop["opcode"] + rs + rt + rd + sa + prop["funct"]

        elif prop["type"] == "i":
            rt = "{:05b}".format(self.parse_argument(2,instruction))
            if instruction[1] in ["ll", "lw", "sh", "sc", "sb", "lb", "lhu", "sw"]:
                rs = "{:05b}".format(self.parse_argument(len(instruction) - 1,instruction))
                if len(instruction) == 4:
                    immediate = twos_complement(0, 16)
                else:
                    immediate = twos_complement(self.parse_argument(3,instruction), 16)
            elif instruction[1] in ["lui"]:
                rs = "{:05b}".format(0)
                immediate = twos_complement(self.parse_argument(3,instruction), 16)

            else:
                rs = "{:05b}".format(self.parse_argument(3,instruction))
                immediate = twos_complement(self.parse_argument(4,instruction), 16)

            line = prop["opcode"] + rs + rt + immediate

        elif prop["type"] == "j":
            address = twos_complement(self.parse_argument(2,instruction), 26)

            line = prop["opcode"] + address

        else:
            line = "{:032b}".format(0)

        print encrypt(line, 4), '\t', instruction
        self.file_out.write(line + '\n')

    ## Iterate over all lines in the input file and process non-empty, 
    # non-comments line only.
    #
    # Removes the comments from each line and only processes the non-empty lines
    #
    def process_file(self):
        for line in self.file_in:
            line = line.strip('\n')
            # find full comments lines
            comment = re.search(self.full_line_comment, line)
            if comment:
                line = line.replace(comment.group(), "")

            if line.strip(" "):
                self.process_line(line)

    ## Extract label identifier and tokenize the instruction with name and arguments
    #
    # Build a queue of tokenized instructions with the line number of each.
    # Also creates a map of labels and their target line.
    # Prior to entering this function, full comments line should have been removed
    # Only instruction lines should be processed
    #
    # @param line The line from the file. 
    #
    def process_line(self, line):
        comments = re.search(self.inline_comment_regex, line)
        if comments:
            line = line.replace(comments.group(), "")

        label = re.search(self.label_regex, line)
        if label:
            line = line.replace(label.group(), "")

            if not self.labels.has_key(label.group()):
                self.labels[label.group()] = self.line_number
            else:
                raise KeyError("Label already exists in program")

        arguments = re.findall(self.argument_regex, line)
        self.queue.append([self.line_number] + arguments)
        self.line_number += 1

    ## Destructor releases the files handles
    def __del__(self):
        self.file_in.close()
        self.file_temp.close()
        self.mips_isa_file.close()
        print "Program terminated cleanly"

if __name__ == '__main__':

    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-i", "--isa", dest="isa_file",
                      help="mips isa description file, should be the provided 'mips-isa.json' file", default=None)
    parser.add_option("-a", "--assembly", dest="assembly_file",
                      help="The mips program to assemble", default=None)
    (options, args) = parser.parse_args()

    if options.isa_file is not None:
        isa_file = options.isa_file
    else:
        isa_file = None
        print 'ERROR: MIPS ISA file not found!'
        exit(1)

    if options.assembly_file is not None:
        assembly_file = options.assembly_file
    else:
        assembly_file = None
        print 'ERROR: Assembly program file not found!'
        exit(1)

    assembler = Assembler(assembly_file, isa_file)
    assembler.run()
