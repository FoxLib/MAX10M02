module max10(

    output wire [13:0]   IO,
    output wire [ 3:0]   LED,
    input  wire          KEY0,
    input  wire          KEY1,
    input  wire          SERIAL_RX,
    input  wire          SERIAL_TX,
    input  wire          CLK100MHZ
);

assign LED = clock50;

pll PLL(
    .inclk0 (CLK100MHZ),
    .c50    (clock50),
);

endmodule
