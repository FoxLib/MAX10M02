module max10(

    output wire [13:0]   IO,
    output wire [ 3:0]   LED,
    input  wire          KEY0,
    input  wire          KEY1,
    input  wire          SERIAL_RX,
    input  wire          SERIAL_TX,
    input  wire          CLK100MHZ
);

assign LED = ~rxb[3:0];

wire [7:0] rbyte;
reg  [7:0] rxb;
wire ready;

always @(posedge clock25)
    if (ready)
        rxb <= rbyte;

uart UART(

    .clock25 (clock25),
    .rx      (SERIAL_RX),
    .ready   (ready),
    .rbyte   (rbyte)
);

pll PLL(
    .inclk0 (CLK100MHZ),
    .c25    (clock25),
);

endmodule
