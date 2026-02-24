// Code your design here
`timescale 1ns/1ps

// ================= PC =================
module PC(
input clk,
input reset,
input [31:0] PC_next,
output reg [31:0] PC_out
);

always @(posedge clk)
begin
 if(reset)
   PC_out <= 0;
 else
   PC_out <= PC_next;
end

endmodule


// ================= PC + 4 =================

module PC_Adder(
input [31:0] PC_in,
output [31:0] PC_next
);

assign PC_next = PC_in + 4;

endmodule


// ================= Instruction Memory =================

module InstructionMemory(
input [31:0] address,
output [31:0] instruction
);

reg [31:0] memory[0:15];

integer i;

initial begin

memory[0] = 32'h00221820; // ADD R3,R1,R2
memory[1] = 32'h00222022; // SUB R4,R1,R2
memory[2] = 32'h00222824; // AND R5,R1,R2
memory[3] = 32'h00223025; // OR  R6,R1,R2

for(i=4;i<16;i=i+1)
memory[i]=32'h00221820;

end

assign instruction = memory[address[31:2]];

endmodule


// ================= IF/ID =================

module IF_ID(

input clk,
input reset,
input [31:0] instruction_in,
input [31:0] pc_in,

output reg [31:0] instruction_out,
output reg [31:0] pc_out
);

always @(posedge clk)
begin

if(reset)
begin
 instruction_out <= 0;
 pc_out <= 0;
end

else
begin
 instruction_out <= instruction_in;
 pc_out <= pc_in;
end

end

endmodule


// ================= Register File =================

module RegisterFile(

input clk,
input RegWrite,

input [4:0] ReadReg1,
input [4:0] ReadReg2,
input [4:0] WriteReg,

input [31:0] WriteData,

output [31:0] ReadData1,
output [31:0] ReadData2
);

reg [31:0] registers[0:31];

integer i;

initial begin
for(i=0;i<32;i=i+1)
registers[i]=i;
end

assign ReadData1 = registers[ReadReg1];
assign ReadData2 = registers[ReadReg2];

always @(posedge clk)
if(RegWrite)
registers[WriteReg] <= WriteData;

endmodule


// ================= ID/EX =================

module ID_EX(

input clk,
input reset,

input [31:0] ReadData1_in,
input [31:0] ReadData2_in,
input [4:0] rd_in,
input [5:0] funct_in,

output reg [31:0] ReadData1_out,
output reg [31:0] ReadData2_out,
output reg [4:0] rd_out,
output reg [5:0] funct_out

);

always @(posedge clk)
begin

if(reset)
begin

ReadData1_out<=0;
ReadData2_out<=0;
rd_out<=0;
funct_out<=0;

end

else
begin

ReadData1_out<=ReadData1_in;
ReadData2_out<=ReadData2_in;
rd_out<=rd_in;
funct_out<=funct_in;

end

end

endmodule


// ================= ALU =================

module ALU(

input [31:0] A,
input [31:0] B,
input [5:0] funct,

output reg [31:0] Result

);

always @(*)
begin

case(funct)

6'b100000: Result = A+B;
6'b100010: Result = A-B;
6'b100100: Result = A&B;
6'b100101: Result = A|B;

default: Result=0;

endcase

end

endmodule



// ================= EX/MEM =================

module EX_MEM(

input clk,
input reset,

input [31:0] ALUResult_in,
input [4:0] rd_in,

output reg [31:0] ALUResult_out,
output reg [4:0] rd_out
);

always @(posedge clk)
begin

if(reset)
begin

ALUResult_out<=0;
rd_out<=0;

end

else
begin

ALUResult_out<=ALUResult_in;
rd_out<=rd_in;

end

end

endmodule



// ================= Data Memory =================

module DataMemory(

input clk,
input MemWrite,
input MemRead,

input [31:0] address,
input [31:0] WriteData,

output [31:0] ReadData
);

reg [31:0] memory[0:31];

integer i;

initial begin

for(i=0;i<32;i=i+1)
memory[i]=i*10;

end

assign ReadData =
MemRead ? memory[address[31:2]] : 0;

always @(posedge clk)

if(MemWrite)

memory[address[31:2]]<=WriteData;

endmodule



// ================= MEM/WB =================

module MEM_WB(

input clk,
input reset,

input [31:0] Result_in,
input [4:0] rd_in,

output reg [31:0] Result_out,
output reg [4:0] rd_out
);

always @(posedge clk)
begin

if(reset)
begin

Result_out<=0;
rd_out<=0;

end

else
begin

Result_out<=Result_in;
rd_out<=rd_in;

end

end

endmodule




// ================= TOP MODULE =================

module Pipeline_CPU(

input clk,
input reset

);

wire [31:0] PC;
wire [31:0] PC_next;

wire [31:0] instruction;
wire [31:0] IF_ID_instruction;


// PC

PC pc(
.clk(clk),
.reset(reset),
.PC_next(PC_next),
.PC_out(PC)
);


// PC adder

PC_Adder adder(
.PC_in(PC),
.PC_next(PC_next)
);


// Instruction Memory

InstructionMemory imem(
.address(PC),
.instruction(instruction)
);


// IF_ID

IF_ID ifid(

.clk(clk),
.reset(reset),

.instruction_in(instruction),
.pc_in(PC),

.instruction_out(IF_ID_instruction)

);


// Instruction decode

wire [4:0] rs,rt,rd;
wire [5:0] funct;

assign rs = IF_ID_instruction[25:21];
assign rt = IF_ID_instruction[20:16];
assign rd = IF_ID_instruction[15:11];
assign funct = IF_ID_instruction[5:0];



// Register File

wire [31:0] ReadData1;
wire [31:0] ReadData2;

wire [31:0] MEM_WB_Result;
wire [4:0] MEM_WB_rd;

RegisterFile rf(

.clk(clk),
.RegWrite(1),

.ReadReg1(rs),
.ReadReg2(rt),

.WriteReg(MEM_WB_rd),
.WriteData(MEM_WB_Result),

.ReadData1(ReadData1),
.ReadData2(ReadData2)

);


// ID_EX

wire [31:0] ID_EX_A;
wire [31:0] ID_EX_B;

wire [4:0] ID_EX_rd;
wire [5:0] ID_EX_funct;


ID_EX idex(

.clk(clk),
.reset(reset),

.ReadData1_in(ReadData1),
.ReadData2_in(ReadData2),

.rd_in(rd),
.funct_in(funct),

.ReadData1_out(ID_EX_A),
.ReadData2_out(ID_EX_B),

.rd_out(ID_EX_rd),
.funct_out(ID_EX_funct)

);


// ALU

wire [31:0] ALUResult;

ALU alu(

.A(ID_EX_A),
.B(ID_EX_B),

.funct(ID_EX_funct),

.Result(ALUResult)

);


// EX_MEM

wire [31:0] EX_MEM_Result;
wire [4:0] EX_MEM_rd;


EX_MEM exmem(

.clk(clk),
.reset(reset),

.ALUResult_in(ALUResult),
.rd_in(ID_EX_rd),

.ALUResult_out(EX_MEM_Result),
.rd_out(EX_MEM_rd)

);


// Data Memory

wire [31:0] MemoryData;

DataMemory dmem(

.clk(clk),
.MemWrite(0),
.MemRead(1),

.address(EX_MEM_Result),

.WriteData(0),

.ReadData(MemoryData)

);


// MEM_WB

MEM_WB memwb(

.clk(clk),
.reset(reset),

.Result_in(EX_MEM_Result),
.rd_in(EX_MEM_rd),

.Result_out(MEM_WB_Result),
.rd_out(MEM_WB_rd)

);

endmodule