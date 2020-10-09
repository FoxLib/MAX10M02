module nes6502(

    input  wire         clock,
    output wire [15:0]  address,
    input  wire [ 7:0]  din,
    output reg  [ 7:0]  out,
    output reg          rd,
    output reg          we
);

// Состояния процессора
parameter
    OPC =  0,
    NDX =  1, // 1, 2, 3
    NDY =  4,
    ZP  =  7,
    ZPX =  8,
    ZPY =  9,
    ABS =  10,
    ABX =  12,
    ABY =  14,

    IMM =  1,
    REL =  1,
    ACC =  1,
    IMP =  1,
    LAT =  1,
    RUN =  1,

    JMP_ABS = 8'h4C;

// Выбор источника памяти
assign address = bus ? cursor : pc;

// Регистры процессора
// ---------------------------------------------------------------------
reg [ 7:0] A; reg [ 7:0] X; reg [ 7:0] Y;
reg [ 7:0] P; reg [ 7:0] S; reg [15:0] pc = 16'h0000;

// Текущее состояние
// ---------------------------------------------------------------------
reg        bus = 0;         // Шина (0 PC, 1 CURSOR)
reg        wb = 0;          // Write Back, писать в регистры
reg [ 4:0] q = 0;           // Текущий адрес микрокода
reg [15:0] cursor;          // Указатель адреса
reg [ 7:0] opcode;          // Сохраненный опкод
reg [ 7:0] tr;              // Временный регистр
reg [ 3:0] alu;             // Номер АЛУ
reg        cout;            // Для вычисления latency в адресации
reg        read_en;         // Разрешение чтения операнда
reg        branch_en;       // =1 Выполнится Branch для REL-секции

// Вычисления
// ---------------------------------------------------------------------
wire [8:0]  xadd   = X + din;
wire [8:0]  yadd   = Y + din;
wire [7:0]  dinc   = din + cout;    // Складывание carry + din
wire [15:0] branch = pc + 1 + {{8{din[7]}}, din[7:0]}; // Вычисление перехода
wire [7:0]  zpnext = cursor + 1;    // Адрес в пределах ZeroPage

// Принадлежит ли инструкция к Inc или Dec?
wire incdec  = ({opcode[7:6], opcode[2:0]} == 5'b11_1_10) ||
               ({opcode[7],   opcode[2:0]} == 4'b0__1_10);

// Для некоторых методов адресации нужна дополнительная задержка
wire [4:0] lat = (cout | (opcode[7:5] == 3'b100) | incdec) ? LAT : RUN;

// Основная тактовая частота
// ---------------------------------------------------------------------
always @(posedge clock) begin

    case (q)

        // Считывание опкода
        OPC: begin

            opcode      <= din;    // Считывание опкода
            read_en     <= 1;      // Разрешено чтение опкода из памяти
            branch_en   <= 0;      // По умолчанию не выполнять Branch
            we <= 0;               // Запрещена запись в память
            wb <= 0;

            // Декодирование опкода
            casex (din)

                8'bxxx_000_x1: q <= NDX;
                8'bxxx_010_x1,
                8'b1xx_000_x0: q <= IMM;
                8'bxxx_100_x1: q <= NDY;
                8'bxxx_110_x1: q <= ABY;
                8'bxxx_001_xx: q <= ZP;
                8'bxxx_011_xx,
                8'b001_000_00: q <= ABS;
                8'b10x_101_1x: q <= ZPY;
                8'bxxx_101_xx: q <= ZPX;
                8'b10x_111_1x: q <= ABY;
                8'bxxx_111_xx: q <= ABX;
                8'bxxx_100_00: q <= REL;
                8'b0xx_010_10: q <= ACC;
                default:       q <= IMP;

            endcase

            // Подготовка инструкции, чтобы соблюдать cycle accuracy
            casex (din)

                8'b100_xx_100: /* STY */ begin read_en <= 1'b0; out <= Y; end
                8'b100_xx_110: /* STX */ begin read_en <= 1'b0; out <= X; end
                8'b100_xxx_01: /* STA */ begin read_en <= 1'b0; out <= A; end
                8'bxxx_xxx_01: /* ALU */ begin alu     <= din[7:5]; end

            endcase

            // Условие выполнения Branch
            case (opcode[7:6])

                /* S */ 2'b00: branch_en <= (P[7] == opcode[5]);
                /* V */ 2'b01: branch_en <= (P[6] == opcode[5]);
                /* C */ 2'b10: branch_en <= (P[0] == opcode[5]);
                /* Z */ 2'b11: branch_en <= (P[1] == opcode[5]);

            endcase

            pc <= pc + 1;

        end

        // Indirect, X Косвенно-индексная по X
        // -------------------------------------------------------------
        NDX:   begin q <= NDX+1; cursor <= xadd[7:0];  bus <= 1;       end
        NDX+1: begin q <= NDX+2; cursor <= zpnext;     tr  <= din;     end
        NDX+2: begin q <= LAT;   cursor <= {din, tr};  rd  <= read_en; end

        // Indirect, Y  Косвенно-индексная по Y
        // -------------------------------------------------------------
        NDY:   begin q <= NDY+1; cursor <= din; bus <= 1;              end
        NDY+1: begin q <= NDY+2; cursor <= zpnext; {cout, tr} <= yadd; end
        NDY+2: begin q <= lat;   cursor <= {dinc, tr}; rd <= read_en;  end

        // ZP,ZPX,ZPY Операнд получается из ZeroPage
        // -------------------------------------------------------------
        ZP:  begin q <= RUN; cursor <= din;       bus <= 1; rd <= read_en; end
        ZPX: begin q <= LAT; cursor <= xadd[7:0]; bus <= 1; rd <= read_en; end
        ZPY: begin q <= LAT; cursor <= yadd[7:0]; bus <= 1; rd <= read_en; end

        // Absolute
        // -------------------------------------------------------------
        ABS:   begin q <= ABS+1; tr <= din; pc <= pc + 1; end
        ABS+1: begin

            if (opcode == JMP_ABS)
                 begin q <= OPC; pc <= {din, tr}; end
            else begin q <= RUN; cursor <= {din, tr}; bus <= 1; rd <= read_en; end

        end

        // Absolute,X
        // -------------------------------------------------------------
        ABX:   begin q <= ABX+1; {cout, tr} <= xadd; pc <= pc + 1; end
        ABX+1: begin q <= lat; cursor <= {dinc, tr}; bus <= 1; rd <= read_en; end

        // Absolute,Y
        // -------------------------------------------------------------
        ABY:   begin q <= ABY+1; {cout, tr} <= yadd; pc <= pc + 1; end
        ABY+1: begin q <= lat; cursor <= {dinc, tr}; bus <= 1; rd <= read_en; end

        // REL Относительный условный переход
        // -------------------------------------------------------------
        REL: begin

            if (branch_en)
                 begin pc <= branch; q <= branch[15:8] == pc[15:8] ? REL+2 : REL+1; end
            else begin pc <= pc + 1; q <= OPC; end

        end

        REL+1: begin q <= REL+2; end // +2T если есть превышение границ
        REL+2: begin q <= OPC; end   // +1T если переход

        // Задержка для совместимости с циклами
        // -------------------------------------------------------------
        LAT: q <= RUN;

        // Исполнение инструкции
        // -------------------------------------------------------------
        RUN: begin end


    endcase

end

// ---------------------------------------------------------------------
// Обратная запись в регистры
// ---------------------------------------------------------------------

always @(negedge clock) begin

    // Писать результат АЛУ
    if (wb) case (op1)

        2'b00: A <= R[7:0];
        2'b01: X <= R[7:0];
        2'b10: Y <= R[7:0];

    endcase

    // Флаги
//    if (SEI) /* BRK I=1, B=1 */ P <= {P[7:6], 2'b11, P[3], 1'b1, P[1:0]};
//    else if (WR && RA == 2'b11) P <= DIN; /* PLP, RTI */
//    else if (FW) /* Другие */   P <= AF;

    // Записать в регистр S результат
//    if (SW) S <= AR;


end

// ---------------------------------------------------------------------
// Арифметико-логическое устройство
// ---------------------------------------------------------------------

// Запрос
reg [1:0] op1; // Назначение (A,X,Y)
reg [2:0] op2; // Источник (0 Din, 1 X, 2 Y, 3 S, 4-7 A)

// Ответ
reg [8:0] R; // Результат
reg [7:0] F; // Флаги

// Внутреннее представление
reg [7:0] dst;
reg [7:0] src;

// Подключение к шине
always @* begin

    // Операнд A
    casex (op1)

        2'b00: dst = A;
        2'b01: dst = X;
        2'b10: dst = Y;
        // 2'b11  Неиспользуемый

    endcase

    // Операнд AB
    casex (op2)

        3'b000: src = din;
        3'b001: src = X;
        3'b010: src = Y;
        3'b011: src = S;
        3'b1xx: src = A;

    endcase

end

// Статусы ALU
wire zero  = R[7:0] == 0;
wire sign  = R[7];
wire oadc  = (dst[7] ^ src[7] ^ 1'b1) & (dst[7] ^ R[7]); // Переполнение ADC
wire osbc  = (dst[7] ^ src[7]       ) & (dst[7] ^ R[7]); // Переполнение SBC
wire cin   = P[0];
wire carry = R[8];

always @* begin

    // Расчет результата
    case (alu)

        /* ORA */ 4'b0000: R = dst | src;
        /* AND */ 4'b0001: R = dst & src;
        /* EOR */ 4'b0010: R = dst ^ src;
        /* ADC */ 4'b0011: R = dst + src + cin;
        /* STA */ 4'b0100: R = dst;
        /* LDA */ 4'b0101: R = src;
        /* CMP */ 4'b0110: R = dst - src;
        /* SBC */ 4'b0111: R = dst - src - !cin;
        /* ASL */ 4'b1000: R = {src[6:0], 1'b0};
        /* ROL */ 4'b1001: R = {src[6:0], P[0]};
        /* LSR */ 4'b1010: R = {1'b0, src[7:1]};
        /* ROR */ 4'b1011: R = {P[0], src[7:1]};
        /* BIT */ 4'b1101: R = dst & src;
        /* DEC */ 4'b1110: R = src - 1;
        /* INC */ 4'b1111: R = src + 1;

    endcase

    // Расчет флагов
    casex (alu)

        // Арифметика
        4'b000x, /* ORA, AND */
        4'b0010, /* EOR */
        4'b010x, /* STA, LDA */
        4'b111x: /* DEC, INC */
                 F = {sign,       P[6:2], zero,   P[0]};
        4'b0011: F = {sign, oadc, P[5:2], zero,  carry}; // ADC
        4'b0110: F = {sign,       P[6:2], zero, ~carry}; // CMP
        4'b0111: F = {sign, osbc, P[5:2], zero, ~carry}; // SBC

        // Сдвиговые
        4'b100x: F = {sign, P[6:2], zero, src[7]}; // ASL, ROL
        4'b101x: F = {sign, P[6:2], zero, src[0]}; // LSR, ROR

        // Флаговые
        4'b1100: casex (opcode[7:5])

            /* CLC */ 3'b00x: F = {P[7:1], opcode[5]};
            /* CLI */ 3'b01x: F = {P[7:3], opcode[5], P[1:0]};
            /* CLV */ 3'b101: F = {P[7],   1'b0,      P[5:0]};
            /* CLD */ 3'b11x: F = {P[7:4], opcode[5], P[2:0]};

        endcase

        // BIT
        4'b1101: F = {src[7:6], P[5:2], zero, P[0]};

    endcase

end

endmodule
