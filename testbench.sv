// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module testbench;

reg clk;
reg reset;

Pipeline_CPU uut(

.clk(clk),
.reset(reset)

);


initial begin
  $dumpfile("dump.vcd"); $dumpvars;

clk=0;
forever #5 clk=~clk;

end


initial begin

reset=1;

#10

reset=0;

#200

$finish;

end

endmodule