`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------------------------
reg clk;
reg clk25;
always #0.5 clk = ~clk;
always #1.5 clk25 = ~clk25;

initial begin clk = 1; clk25 = 0; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// ---------------------------------------------------------------------
endmodule
