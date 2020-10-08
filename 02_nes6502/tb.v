`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------------------------
reg clk;
reg clk25;
always #0.5 clk   = ~clk;
always #1.5 clk25 = ~clk25;

initial begin clk = 0; clk25 = 0; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// ---------------------------------------------------------------------

wire [15:0] address;
reg  [ 7:0] data_in;
wire [ 7:0] data_out;
wire        read;
wire        write;

nes6502 NesTicle(

    .clock  (clk),
    .address(address),
    .data   (data_in),
    .out    (data_out),
    .rd     (read),
    .we     (write)
);

endmodule
