module max10(

    output wire [13:0]   IO,
    output wire [ 3:0]   LED,
    input  wire          KEY0,
    input  wire          KEY1,
    input  wire          SERIAL_RX,
    output wire          SERIAL_TX,
    input  wire          CLK100MHZ
);

assign LED = ~rxb[3:0];

wire [7:0] rbyte;
reg  [7:0] rxb = 0;
reg  [7:0] txb = 8'h42;
reg        txs = 0;
wire ready;

always @(posedge clock25)
    
    if (ready) begin
        rxb <= rxb + 1;     
        txb <= rbyte;
        txs <= 1;
    end
    else if (tx_ready) begin
        txs <= 0;
    end        

uart UART
(
    .clock25 (clock25),
    
    // Receive2
    .rx      (SERIAL_RX),
    .rx_ready(ready),
    .rx_byte (rbyte),
    
    // Transmit
    .tx      (SERIAL_TX),
    .tx_byte (txb),
    .tx_send (txs),
    .tx_ready (tx_ready)    
);

pll PLL
(
    .inclk0 (CLK100MHZ),
    .c25    (clock25),
);

endmodule
