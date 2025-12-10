# 8-bit-processor
Basic 8-bit processor with custom ISA built as a hobby.

MAIN POINTS:
1. One instruction per clock cycle, no multi-cycle instructions 
2. fetch on negative edge, execute on positive edge
3. RAM counter increases by 1 every operation with it (read/write RAM)
4. 8 memory destinations: 6 registers, 1 IO, 1 RAM
5. Arithmetics always works on reg0 and reg1, stores in any memory
6. Logic compares reg0 and reg1, jumps to address from any memory destination
7. ALU cannot give carry in operation (add, multiply, etc.)
8. Code from code.txt
9. Global inpur from global_input.txt
10. There is small assembly in python (assembly.py)


Description:

This is a basic processor with 8-bit data bus, intruction bus and address space. While on basis it is created around harward architecture with differentiated memory and code, many aspects were modified to ease coding. In general it is one instrucion per cycle processor, and does not incorporate any pipelining. Due to this design choice has fallen to fetch instruction on negative edge of clock and execute on positive edge to avoid unstable values on control wires, while it should be possible and even better if both fetch and execute would have happened on positive edge of clock it would be longer/harder to code, however i will look in to is as leaving code as it is is not satisfiable. About other interesting design choices, RAM counter increments by itself at any operation of read/write from ram, it was chosen this way as most of programs in mind for this processor were about processing of consecutive data, so it just made sense to include it. As this processor was made with idea of single instruction per cycle and 8-bit instruction bus, amount of data directions is limited to 8 (aa bbb ccc, aa-opcode, bbb- to, ccc-from), due to this, 1 for IO, 1 for RAM, leaves only 6 regs available. Also due to 8-bit instruction bus, ALU operations are quite limited compared to full scale processors in addition to inability to chose on what register operate. ALU in aritmetic operations always works on reg0 and reg1, however it can choose where to store result (any memory destination). ALU in logic operations works on comparing reg0 and reg1, and extracting address to change to from any memory destination. Also, ALU does not give carry for operations. More on how opcodes work in the respective section. Processor gets code from code.txt file, its just easier to code this way for me, for note i use icarus verilog. Global inputs also stored in txt: global_input.txt. In both cases verilog reads line by line, truncating or padding to 8 bits as needed. Output is made when sending data to global output, it displays value in console with respective index. Also i wrote little assembly on python to ease coding, it can be found as assembly.py. If any questions appear you may ask on: nikita.nakonechnyy@nu.edu.kz.

OPCODES:

Naming is the one that used in assembly.py

cop xxx yyy
00 xxx yyy - copy from yyy to xxx.
Values for xxx and yyy:
000 - reg0
001 - reg1
010 - reg2
011 - reg3
100 - reg4
101 - reg5
110 - RAM (ram in assembly)
111 - global IO (glob in assembly)

01 xxxxxx - immidiate values to reg0, as it can be seen it only can be from 0 to 63, for any other add should be used
opcode      wording in assembly
1 xxxxxxx - ALU
10000 xxx - add, reg0 + reg1, save to xxx
10001 xxx - sub, reg0 - reg1, save to xxx
10010 xxx - neg, -reg0, save to xxx (it is just (bit wise not on reg0)+1 ,  aka assuming negative number is defined by leading bit )
10011 xxx - and, reg0 & reg1, save to xxx, bitwise AND
10100 xxx - not, ~reg0 , save to xxx, bitwise NOT
10101 xxx - xor, reg0 ^ reg1, save to xxx, bitwise XOR
10110 xxx - reserved
10111 xxx - finish, stops simulation

11000 xxx - ifeq_r, reg0 == reg1, change RAM address to xxx
11010 xxx - ifgr_r, reg0 > reg1, change RAM address to xxx
11100 xxx - ifneq_r, reg0 != reg1, change RAM address to xxx
11110 xxx - ifngr_r, !(reg0 > reg1), change RAM address to xxx
11001 xxx - ifeq_r, reg0 == reg1, change CODE address to xxx
11011 xxx - ifgr_r, reg0 > reg1, change CODE address to xxx
11101 xxx - ifneq_r, reg0 != reg1, change CODE address to xxx
11111 xxx - ifngr_r, !(reg0 > reg1), change CODE address to xxx

Well it should be all. Again if somehow you have question you can write to: nikita.nakonechnyy@nu.edu.kz.
