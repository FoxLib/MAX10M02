module nes6502(

    input  wire         clock,
    output wire [15:0]  address,
    input  wire [ 7:0]  data,
    output wire [ 7:0]  out,
    output wire         rd,
    output wire         we
);

// Выбор источника памяти
assign address = bus ? cursor : pc;

// Регистры процессора
reg [ 7:0] A; reg [ 7:0] X; reg [ 7:0] Y;
reg [ 7:0] P; reg [ 7:0] S; reg [15:0] pc = 16'h0000;

// Текущее состояние
reg        bus = 0;
reg [15:0] cursor;

endmodule
