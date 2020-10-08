`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------------------------
reg clk;
reg clk25;
always #0.5 clk = ~clk;
always #1.5 clk25 = ~clk25;

initial begin clk = 0; clk25 = 0; #2000 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
// ---------------------------------------------------------------------

reg [22:0] adr = 23'h12345;
reg [31:0] dr = 0;
reg        dready = 0;

// ------------------
reg arshft = 1;
reg arclk  = 0;
reg ardin  = 0;
reg drshft = 0;
reg drclk  = 0;
reg drout  = 1;
// ------------------

reg [4:0] arcnt = 0;
reg [5:0] drcnt = 0;
reg [4:0] phase = 0;

// 100 mhz
always @(posedge clk) begin

    phase <= phase + 1;

    case (phase)

        // WAIT
        0: begin drshft <= 0; drclk <= 0; end

        // Установка адреса
        1: arclk <= 0;                  // Такт=0 | 12.5 Мгц
        2: ardin <= adr[22];            // Вдвиг MSB адреса
        3: adr   <= {adr[21:0], 1'b0};  // Сдвиг вправо
        4: arcnt <= arcnt + 1;          // Считаем биты адреса
        5: arclk <= 1;                  // Такт=1 | 12.5 Мгц
        8: if (arcnt != 23) phase <= 1; else arclk <= 0; // Вдвиг последнего бита адреса

        // Считывание данных
        9: drclk <= 1;                  // Такт=1 Первый такт защелкнет DATA в сдвигово регистре
        10: drcnt <= drcnt + 1;         // Увеличиваем счетчик битов
        11: dr <= {dr[30:0], drout};    // Задвигаем новый бит в LSB
        13: drclk <= 0;                 // Такт=0, 12.5 Мгц
        14: drshft <= 1;                // Установка режима сдвига
        16: if (drcnt != 33) phase <= 9; // Повторяет 1+32 раза

        // OK
        17: begin dready <= 1; phase <= 17; end

    endcase

end

endmodule
