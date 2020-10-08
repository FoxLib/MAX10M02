module max10(

    output wire [13:0]   IO,
    output wire [ 3:0]   LED,
    input  wire          KEY0,
    input  wire          KEY1,
    input  wire          SERIAL_RX,
    input  wire          SERIAL_TX,
    input  wire          CLK100MHZ
);

assign LED = mm[3:0];

reg [511:0] mm = 512'hEA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_EA_C1_;

always @(posedge CLK100MHZ)
    mm <= mm[511:4];


endmodule
