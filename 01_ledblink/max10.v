module max10(

    output wire [13:0]   IO,
    output wire [ 3:0]   LED,
    input  wire          KEY0,
    input  wire          KEY1,
    input  wire          SERIAL_RX,
    input  wire          SERIAL_TX,
    input  wire          CLK100MHZ
);

assign LED = ledena ? ~4'b1101 : 4'b1111 /* off */;


// 100.000.000 div 2^(17+1) = 381 Hz
reg ledena;
reg [16:0] cnt;
reg [16:0] duty = 1024;

always @(posedge CLK100MHZ) begin

	// 50%
	ledena <= cnt < duty;
	cnt    <= cnt + 1;
	 
	if (cnt == 0) begin
		if (~KEY0) duty <= duty + 1;
		if (~KEY1) duty <= duty - 1;
	end
	
end

pll PLL(
    .inclk0 (CLK100MHZ),
    .c25    (clock25),
);

endmodule
