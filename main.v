module decoder_module ( //Decoder module, decode intructions and pass to regs/ALU(partially has its own decoder)
    input wire [7:0] opcode,
    input wire clk,

    output reg reg_read,
    output reg reg_write,
    output reg reg_reset, // not used
    output reg [7:0] data_out,
    output reg [2:0] addr_in,
    output reg [2:0] addr_out,

    output reg ALU_select,
    output reg [3:0] ALU_code,


    output reg ram_read,
    output reg ram_write,

    output reg global_read,
    output reg global_write
); 


always @(opcode) begin
    reg_write=0;
    reg_read=0;
    reg_reset=0;
    ALU_code=0;
    ALU_select=0;
    ram_write=0;
    ram_read=0;
    global_write=0;
    global_read=0;
    data_out=8'bz;
    addr_in=3'bz;
    addr_out=3'bz;
    
    case(opcode[7:6])

        2'b00:begin          // 0-5 regs, 6 ram, 7 global 00 - move , xxx - to, yyy - from => 00xxxyyy
            addr_in=opcode[5:3];
            addr_out=opcode[2:0];
        end

        2'b01:begin         // immidiate value to reg0
            data_out={2'b00,opcode[5:0]};
            addr_in=3'b000;
        end

        2'b10:begin         // select ALU and pass opcode there, open reg for write (10 arithmetics)
            if (opcode[7:0]==8'b10111111) begin  /// taken reserved code for finish
                $finish;
            end else begin
            ALU_code=opcode[6:3];
            ALU_select=1;
            addr_in=opcode[2:0];
            end
        end 

        2'b11:begin         // select ALU and pass opcode there, select reg for reading memory pointer (11 logic)
            ALU_code = opcode [6:3];
            ALU_select=1;
            addr_out=opcode[2:0];
        end 
    endcase

    case(addr_in)
        3'b111: global_write=1'b1;
        3'b110: ram_write=1'b1;
        3'b?: reg_write=1'b0;
        default: reg_write=1'b1;
    endcase
    case(addr_out)
        3'b111: global_read=1'b1;
        3'b110: ram_read=1'b1;
        3'b?: reg_read=1'b0;
        default: reg_read=1'b1;
    endcase
   //$display("ALU_select:%d",ALU_select); 
end
endmodule






module reg_module (  //Register module, 6 8bit registers 0-5, data_out0 and data_out1 always active and connected to ALU
    input wire clk,
    input wire write,
    input wire read,
    input wire reset,

    input wire [2:0] addr_in,
    input wire [2:0] addr_out,
    input wire [7:0] data_in,

    output wire [7:0] data_out0,
    output wire [7:0] data_out1,
    output wire [7:0] data_out2
    );

reg [7:0] register [5:0];
integer i;
task clear;
    begin
        for (i=0; i<6; i=i+1) register[i] = 0;
    end
endtask

initial clear();

assign    data_out0 = register[0];
assign    data_out1 = register[1];
assign data_out2 = read ? register[addr_out]: 8'bz;

always @(posedge clk) begin

    if (reset) clear();

    if (write) begin
        register[addr_in]<=data_in;
    end

    //$display("reg0:%d, reg1:%d, reg2:%d, reg3:%d, reg4:%d, reg5:%d", register[0],register[1],register[2],register[3],register[4],register[5]);
    
end

endmodule





module alu_module (
    input wire select,
    input wire [3:0] opcode,

    input wire [7:0] data_in0,
    input wire [7:0] data_in1,
    input wire [7:0] data_in2,
    
    output reg code_count_change,
    output reg ram_count_change,
    output wire [7:0] data_out
);

reg [7:0] result;

assign data_out = select ? result: 8'bz;

always@(select) begin

    result=8'bz;
    code_count_change=0;
    ram_count_change=0;

    case(opcode)
        //Arithmetics
        4'b0000: result = data_in0 + data_in1; //ADD
        4'b0001: result = data_in0 - data_in1; //SUB
        4'b0010: result = -data_in0;           //NEG
        4'b0011: result = data_in0 & data_in1; //AND
        4'b0100: result = ~data_in0;           //NOT
        4'b0101: result = data_in0 ^ data_in1; //XOR
        4'b0110: result=8'h00;                 //RESERVED (taken here for reg_reset)
        4'b0111: result=8'h00;                 //RESERVED (taken here for simulation finish)

        //Logic
        4'b1000: begin  //IFEQ_R
            ram_count_change = (data_in0 == data_in1);            
        end

        4'b1010: begin //IFGR_R
            ram_count_change = (data_in0 > data_in1);               
        end

        4'b1100: begin //IFNEQ_R
            ram_count_change = !(data_in0 == data_in1);               
        end

        4'b1110: begin //IFNGR_R
            ram_count_change = !(data_in0 > data_in1);
        end

        4'b1001: begin //IFEQ_C
            code_count_change= (data_in0 == data_in1);              
        end

        4'b1011: begin //IFGR_C
            code_count_change= (data_in0 > data_in1);                     
        end

        4'b1101: begin //IFNEQ_C
            code_count_change= !(data_in0 == data_in1);                      
        end

        4'b1111: begin //IFNGR_C
            code_count_change= !(data_in0 > data_in1);                       
        end
    endcase
    //$display("select:%d, opcode:%d, code_count_change=%d", select,opcode,code_count_change);
end
endmodule



module ram_module (
    input wire clk,
    input wire write,
    input wire read,
    input wire overwrite,

    input wire [7:0] data_in,
    input wire [7:0] addr_in,

    output wire [7:0] data_out
);

reg [7:0] ram [255:0];

integer i;
initial begin
    for (i=0; i<256; i=i+1) ram[i] = 0;
end

reg [7:0] addr = 0;

assign data_out = read ? ram[addr] : 8'bz;

always @(posedge clk) begin
    if (write)begin
        ram[addr]<=data_in;
        addr<=addr+1;
    end

    if (overwrite) addr<=addr_in;

    if (read) addr<=addr+1;

    //$display("addr:%d, ram[0]:%d, ram[1]:%d", addr, ram[0],ram[1]);

end

endmodule





module global_IO_module(
    input wire clk,
    input wire read,
    input wire write,
    input wire [7:0] data_in,

    output wire [7:0] data_out
);

reg [7:0] global_input [1023:0];

reg [9:0] addr_in =0;
reg [9:0] addr_out =0;


initial begin
    $readmemb("global_input.txt", global_input, 0, 1023);
end

assign data_out = read ? global_input[addr_in] : 8'bz;

always @(posedge clk) begin
    if(read) begin
        addr_in<=addr_in+1;
    end
    if(write) begin
        $display("Index %d: Data = %d",addr_out,data_in);
        addr_out=addr_out+1;
    end 
end

endmodule


module code_mem_module (
    input wire overwrite,
    input wire clk,

    input wire [7:0] addr_in,

    output reg [7:0] opcode
);

reg [7:0] code [255:0];
reg [7:0] addr = 0;

initial begin
    addr = 8'b0;
    $readmemb("code.txt", code, 0, 255);
end


always @(posedge clk) begin
    if (overwrite) addr<=addr_in;
    else addr<=addr+1;
    //$display("time:%d, addr:%d, opcode:%b, overwrite:%d, addr_in:%d",$time, addr,code[addr],overwrite,addr_in);
    if (addr>256) begin
        $display("too bad");
        $finish;
    end    
    //if ($time > 1000) $finish;
end

always @(negedge clk) begin
    opcode=code[addr];
end
endmodule





module main;

reg clk=1'b0;

wire [7:0] opcode, data_bus; 

wire [7:0] reg0_val, reg1_val;
wire [3:0] ALU_code;
wire ALU_select;
wire ram_count_change, code_count_change;

wire [2:0] reg_addr_in, reg_addr_out;
wire reg_write, reg_read, reg_reset;
wire ram_read, ram_write;
wire global_read, global_write;

decoder_module decoder ( opcode, clk, reg_read, reg_write, reg_reset, data_bus, reg_addr_in, reg_addr_out, ALU_select, ALU_code, ram_read, ram_write, global_read, global_write);

alu_module ALU(ALU_select, ALU_code, reg0_val, reg1_val, data_bus, code_count_change, ram_count_change, data_bus);

ram_module ram(clk, ram_write, ram_read, ram_count_change, data_bus, data_bus, data_bus);

global_IO_module global_IO(clk, global_read, global_write, data_bus, data_bus);

code_mem_module code_mem(code_count_change, clk, data_bus, opcode);

reg_module registrs (clk, reg_write, reg_read, reg_reset, reg_addr_in, reg_addr_out, data_bus, reg0_val, reg1_val, data_bus);

always #5 clk=~clk;

endmodule //main

