module uart(

    input            clock25,   // Тактовая частота 25 mhz
    input            rx,        // Входящие данные
    output reg       ready,     // Строб готовности
    output reg [7:0] rbyte      // Принятые данные
);

// Частота 460800 бод, 25 000 000 / 460 800 = 54
parameter size = 54;

reg [7:0] cnt = 0;
reg [3:0] num = 0;
reg       rdy = 0;
reg       latch = 0;

initial ready = 0;
initial rbyte = 0;

always @(posedge clock25) begin

    ready <= 0;

    if (rdy) begin

        cnt <= cnt + 1;
        
        // Прием сигнала на середине 
        if (cnt == size/2) begin
        
            if (num == 10) // 11 бит = start(1) + data(8) + parity(1) + stop(1)
            begin rdy <= 0; ready <= 1; end // Прием данных окончен
            else if (num < 9) rbyte <= {rx, rbyte[7:1]}; // Сдвиг LSB
            
            num <= num + 1;
            
        end
        else if (cnt == size-1) cnt <= 0;

    end
    // Ожидание старт-бита
    else if ({latch, rx} == 2'b10) begin rdy <= 1; {cnt, num, rbyte} <= 0; end
    
    // Для того, чтобы определить старт-бит
    latch <= rx;

end 

endmodule