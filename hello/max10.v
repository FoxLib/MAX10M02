module max10(

    output wire [13:0]   IO,
    output wire [ 3:0]   LED,
    input  wire          KEY0,
    input  wire          KEY1,
    input  wire          SERIAL_RX,
    input  wire          SERIAL_TX,
    input  wire          CLK100MHZ
);

wire drclk;
wire arshft;
wire arclk;
wire drdout;

// Тактовая частота 12.5 Мгц
// Cтаршим битом вперед задвигается arclk, arshft=1, ardin=адрес
// DRSHIFT=определяет сдвигать ли данные (1) или переместить из флеш в сдвиговый регистр (0)

// 3072 слов по 32 бита = 12 килобайт
altera_onchip_flash_block # (

        .DEVICE_FAMILY          ("MAX 10"),
        .PART_NAME              ("10M02DCV36C8G"),
        .IS_DUAL_BOOT           ("False"),
        .IS_ERAM_SKIP           ("True"),
        .IS_COMPRESSED_IMAGE    ("False"),
        .INIT_FILENAME          ("demo.mif"),
        .MIN_VALID_ADDR         (0),
        .MAX_VALID_ADDR         (3071),
        .MIN_UFM_VALID_ADDR     (0),
        .MAX_UFM_VALID_ADDR     (3071),
        .ADDR_RANGE1_END_ADDR   (3071),
        .ADDR_RANGE1_OFFSET     (512),
        .ADDR_RANGE2_OFFSET     (0),
        // simulation only start
        .DEVICE_ID              ("02"),
        .INIT_FILENAME_SIM      ("")
        // simulation only end

    ) altera_onchip_flash_block_ (

        .xe_ye      (1'b1),
        .se         (1'b1),
        .arclk      (arclk),        // arclk = 12.5/32 mhz
        .arshft     (arshft),       // 1=задвиг 0=инкремент
        .ardin      ({{22{1'b1}}, 1'b0}), // Задвигается постоянно адрес 0
        .drclk      (drclk),        // Тактовая частота 12,5 mhz для данных
        .drshft     (drshft),       // 1=сдвиг 0=скопировать из flash в сдвиговый регистр
        .drdin      (1'b0),
        .nprogram   (1'b1),
        .nerase     (1'b1),
        .nosc_ena   (1'b0),
        .par_en     (1'b1),
        .drdout     (drdout),       // Выходные данные для чтения Data Read Out
        .busy       (),
        .se_pass    (),
        .sp_pass    (),
        .osc        ()
    );


endmodule
