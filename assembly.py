
dictio = {'imm':"01", 'cop':"00", "add":"10000", "sub":"10001", "neg":"10010", "and":"10011", "not":"10100", "xor":"0101", "finish":"10111111",
        "ifeq_r":"11000", "ifgr_r":"11010", "ifneq_r":"11100", "ifngr_r":"11110",
        "ifeq_c":"11001", "ifgr_c":"11011", "ifneq_c":"11101", "ifngr_c":"11111",
        "reg0":"000", "reg1":"001", "reg2":"010", "reg3":"011", "reg4":"100", "reg5":"101", "ram":"110", "glob":"111"}

with open('assembly.txt','r') as file:
    with open('code.txt','w') as code:
        write=""
        for line in file:
            try:
                line=line[:line.index("/")]
            except:
                pass
            line=line.strip()
            line=line.rstrip("\n")
            words = line.split()
            if not words:
                continue
            for word in words:
                if not ((word.isdigit()) or (word in dictio)):
                    print("ERROR")
                    print(word,line)
                    break
                if word in dictio:
                    write= write + dictio[word]
                else:
                    write = write + bin(int(word))[2:].zfill(6)
            code.write(write+'\n')
            write=""