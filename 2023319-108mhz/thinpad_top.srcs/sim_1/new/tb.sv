`timescale 1ns / 1ps
module tb;

wire clk_50M, clk_11M0592;

reg clock_btn = 0;         //BTN5鎵嬪姩鏃堕挓鎸夐挳寮?鍏筹紝甯︽秷鎶栫數璺紝鎸変笅鏃朵负1
reg reset_btn = 0;         //BTN6鎵嬪姩澶嶄綅鎸夐挳寮?鍏筹紝甯︽秷鎶栫數璺紝鎸変笅鏃朵负1

reg[3:0]  touch_btn;  //BTN1~BTN4锛屾寜閽紑鍏筹紝鎸変笅鏃朵负1
reg[31:0] dip_sw;     //32浣嶆嫧鐮佸紑鍏筹紝鎷ㄥ埌鈥淥N鈥濇椂涓?1

wire[15:0] leds;       //16浣峀ED锛岃緭鍑烘椂1鐐逛寒
wire[7:0]  dpy0;       //鏁扮爜绠′綆浣嶄俊鍙凤紝鍖呮嫭灏忔暟鐐癸紝杈撳嚭1鐐逛寒
wire[7:0]  dpy1;       //鏁扮爜绠￠珮浣嶄俊鍙凤紝鍖呮嫭灏忔暟鐐癸紝杈撳嚭1鐐逛寒

wire txd;  //鐩磋繛涓插彛鍙戦?佺
wire rxd;  //鐩磋繛涓插彛鎺ユ敹绔?

wire[31:0] base_ram_data; //BaseRAM鏁版嵁锛屼綆8浣嶄笌CPLD涓插彛鎺у埗鍣ㄥ叡浜?
wire[19:0] base_ram_addr; //BaseRAM鍦板潃
wire[3:0] base_ram_be_n;  //BaseRAM瀛楄妭浣胯兘锛屼綆鏈夋晥銆傚鏋滀笉浣跨敤瀛楄妭浣胯兘锛岃淇濇寔涓?0
wire base_ram_ce_n;       //BaseRAM鐗囬?夛紝浣庢湁鏁?
wire base_ram_oe_n;       //BaseRAM璇讳娇鑳斤紝浣庢湁鏁?
wire base_ram_we_n;       //BaseRAM鍐欎娇鑳斤紝浣庢湁鏁?

wire[31:0] ext_ram_data; //ExtRAM鏁版嵁
wire[19:0] ext_ram_addr; //ExtRAM鍦板潃
wire[3:0] ext_ram_be_n;  //ExtRAM瀛楄妭浣胯兘锛屼綆鏈夋晥銆傚鏋滀笉浣跨敤瀛楄妭浣胯兘锛岃淇濇寔涓?0
wire ext_ram_ce_n;       //ExtRAM鐗囬?夛紝浣庢湁鏁?
wire ext_ram_oe_n;       //ExtRAM璇讳娇鑳斤紝浣庢湁鏁?
wire ext_ram_we_n;       //ExtRAM鍐欎娇鑳斤紝浣庢湁鏁?

wire [22:0]flash_a;      //Flash鍦板潃锛宎0浠呭湪8bit妯″紡鏈夋晥锛?16bit妯″紡鏃犳剰涔?
wire [15:0]flash_d;      //Flash鏁版嵁
wire flash_rp_n;         //Flash澶嶄綅淇″彿锛屼綆鏈夋晥
wire flash_vpen;         //Flash鍐欎繚鎶や俊鍙凤紝浣庣數骞虫椂涓嶈兘鎿﹂櫎銆佺儳鍐?
wire flash_ce_n;         //Flash鐗囬?変俊鍙凤紝浣庢湁鏁?
wire flash_oe_n;         //Flash璇讳娇鑳戒俊鍙凤紝浣庢湁鏁?
wire flash_we_n;         //Flash鍐欎娇鑳戒俊鍙凤紝浣庢湁鏁?
wire flash_byte_n;       //Flash 8bit妯″紡閫夋嫨锛屼綆鏈夋晥銆傚湪浣跨敤flash鐨?16浣嶆ā寮忔椂璇疯涓?1

//Windows闇?瑕佹敞鎰忚矾寰勫垎闅旂鐨勮浆涔夛紝渚嬪"D:\\foo\\bar.bin"
//parameter BASE_RAM_INIT_FILE = "E:\\nscscc2021\\nscscc2023_mips_v1.0\\fpga_template_mips_utf8_v1.0\\text\\text.srcs\\sim_1\\tmp\\lab2\\lab2.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
//parameter BASE_RAM_INIT_FILE = "E:\\nscscc2021\\nscscc2023_mips_v1.0\\fpga_template_mips_utf8_v1.0\\text\\text.srcs\\sim_1\\tmp\\lab3\\kernel.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
//parameter BASE_RAM_INIT_FILE = "E:\\nscscc2021\\nscscc2023_mips_v1.0\\fpga_template_mips_utf8_v1.0\\text\\text.srcs\\sim_1\\tmp\\lab1\\lab1.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
parameter BASE_RAM_INIT_FILE = "E:\\cpu\\new.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
//parameter EXT_RAM_INIT_FILE = "E:\\nscscc2021\\nscscc2023_mips_v1.0\\fpga_template_mips_utf8_v1.0\\text\\text.srcs\\sim_1\\tmp\\lab1\\exm.bin";    //ExtRAM初始化文件，请修改为实际的绝对路径
//parameter BASE_RAM_INIT_FILE = "C:\\Users\\HP\\Desktop\\fpga_template_mips_utf8_v1.0\\thinpad_top.srcs\\sim_1\\tmp\\MIPS_MATRIX.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
//parameter BASE_RAM_INIT_FILE = "C:\\Users\\HP\\Desktop\\fpga_template_mips_utf8_v1.0\\thinpad_top.srcs\\sim_1\\tmp\\MIPS_CRYPTONIGHT.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
//parameter BASE_RAM_INIT_FILE = "E:\\nscscc2021\\nscscc2023_mips_v1.0\\fpga_template_mips_utf8_v1.0\\text\\text.srcs\\sim_1\\tmp\\lab3\\kernel.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径

parameter FLASH_INIT_FILE = "/tmp/kernel.elf";    //Flash初始化文件，请修改为实际的绝对路径
parameter EXT_RAM_INIT_FILE = "C:\\Users\\HP\\Desktop\\fpga_template_mips_utf8_v1.0\\thinpad_top.srcs\\sim_1\\tmp\\ext-0-300000.bin";    //ExtRAM初始化文件，请修改为实际的绝对路径

//assign rxd = 1'b1; //idle state
reg _rxd;
assign rxd = _rxd; //idle state
initial begin 
    _rxd = 1'b1;
    //鍦ㄨ繖閲屽彲浠ヨ嚜瀹氫箟娴嬭瘯杈撳叆搴忓垪锛屼緥濡傦細
    dip_sw = 32'h2;
    touch_btn = 0;
    reset_btn = 1;
    #100;
    reset_btn = 0;
    for (integer i = 0; i < 20; i = i+1) begin
        #100; //绛夊緟100ns
        clock_btn = 1; //鎸変笅鎵嬪伐鏃堕挓鎸夐挳
        #100; //绛夊緟100ns
        clock_btn = 0; //鏉惧紑鎵嬪伐鏃堕挓鎸夐挳
    end
    #20000
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b0;//1
    #104080
    _rxd = 1'b0;//2
    #104080
    _rxd = 1'b1;//3
    #104080
    _rxd = 1'b0;//4
    #104080
    _rxd = 1'b1;//5
    #104080
    _rxd = 1'b0;//6
    #104080
    _rxd = 1'b1;//7
    #104080
    _rxd = 1'b0;//8
    #104080
    _rxd = 1'b1;
    #20000
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b0;//1
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;//8
    #104080
    _rxd = 1'b1;
    #20000
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b0;//1
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;//8
    #104080
    _rxd = 1'b1;
    #20000
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b0;//1
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;
    #104080
    _rxd = 1'b1;
    #104080
    _rxd = 1'b0;//8
    #104080
    _rxd = 1'b1;
end
//initial begin 
//    //鍦ㄨ繖閲屽彲浠ヨ嚜瀹氫箟娴嬭瘯杈撳叆搴忓垪锛屼緥濡傦細
//    dip_sw = 32'h2;
//    touch_btn = 0;
//    reset_btn = 1;
//    #100;
//    reset_btn = 0;
//    for (integer i = 0; i < 20; i = i+1) begin
//        #100; //绛夊緟100ns
//        clock_btn = 1; //鎸変笅鎵嬪伐鏃堕挓鎸夐挳
//        #100; //绛夊緟100ns
//        clock_btn = 0; //鏉惧紑鎵嬪伐鏃堕挓鎸夐挳
//    end
//end

// 寰呮祴璇曠敤鎴疯璁?
thinpad_top dut(
    .clk_50M(clk_50M),
    .clk_11M0592(clk_11M0592),
    .clock_btn(clock_btn),
    .reset_btn(reset_btn),
    .touch_btn(touch_btn),
    .dip_sw(dip_sw),
    .leds(leds),
    .dpy1(dpy1),
    .dpy0(dpy0),
    .txd(txd),
    .rxd(rxd),
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    .base_ram_be_n(base_ram_be_n),
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n),
    .ext_ram_be_n(ext_ram_be_n),
    .flash_d(flash_d),
    .flash_a(flash_a),
    .flash_rp_n(flash_rp_n),
    .flash_vpen(flash_vpen),
    .flash_oe_n(flash_oe_n),
    .flash_ce_n(flash_ce_n),
    .flash_byte_n(flash_byte_n),
    .flash_we_n(flash_we_n)
);
// 鏃堕挓婧?
clock osc(
    .clk_11M0592(clk_11M0592),
    .clk_50M    (clk_50M)
);

// BaseRAM 浠跨湡妯″瀷
sram_model base1(/*autoinst*/
            .DataIO(base_ram_data[15:0]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[0]),
            .UB_n(base_ram_be_n[1]));
sram_model base2(/*autoinst*/
            .DataIO(base_ram_data[31:16]),
            .Address(base_ram_addr[19:0]),
            .OE_n(base_ram_oe_n),
            .CE_n(base_ram_ce_n),
            .WE_n(base_ram_we_n),
            .LB_n(base_ram_be_n[2]),
            .UB_n(base_ram_be_n[3]));
// ExtRAM 浠跨湡妯″瀷
sram_model ext1(/*autoinst*/
            .DataIO(ext_ram_data[15:0]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[0]),
            .UB_n(ext_ram_be_n[1]));
sram_model ext2(/*autoinst*/
            .DataIO(ext_ram_data[31:16]),
            .Address(ext_ram_addr[19:0]),
            .OE_n(ext_ram_oe_n),
            .CE_n(ext_ram_ce_n),
            .WE_n(ext_ram_we_n),
            .LB_n(ext_ram_be_n[2]),
            .UB_n(ext_ram_be_n[3]));
// Flash 浠跨湡妯″瀷
x28fxxxp30 #(.FILENAME_MEM(FLASH_INIT_FILE)) flash(
    .A(flash_a[1+:22]), 
    .DQ(flash_d), 
    .W_N(flash_we_n),    // Write Enable 
    .G_N(flash_oe_n),    // Output Enable
    .E_N(flash_ce_n),    // Chip Enable
    .L_N(1'b0),    // Latch Enable
    .K(1'b0),      // Clock
    .WP_N(flash_vpen),   // Write Protect
    .RP_N(flash_rp_n),   // Reset/Power-Down
    .VDD('d3300), 
    .VDDQ('d3300), 
    .VPP('d1800), 
    .Info(1'b1));

initial begin 
    wait(flash_byte_n == 1'b0);
    $display("8-bit Flash interface is not supported in simulation!");
    $display("Please tie flash_byte_n to high");
    $stop;
end

// 浠庢枃浠跺姞杞? BaseRAM
initial begin 
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open BaseRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("BaseRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        base1.mem_array0[i] = tmp_array[i][24+:8];
        base1.mem_array1[i] = tmp_array[i][16+:8];
        base2.mem_array0[i] = tmp_array[i][8+:8];
        base2.mem_array1[i] = tmp_array[i][0+:8];
    end
end

// 浠庢枃浠跺姞杞? ExtRAM
initial begin 
    reg [31:0] tmp_array[0:1048575];
    integer n_File_ID, n_Init_Size;
    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
    if(!n_File_ID)begin 
        n_Init_Size = 0;
        $display("Failed to open ExtRAM init file");
    end else begin
        n_Init_Size = $fread(tmp_array, n_File_ID);
        n_Init_Size /= 4;
        $fclose(n_File_ID);
    end
    $display("ExtRAM Init Size(words): %d",n_Init_Size);
    for (integer i = 0; i < n_Init_Size; i++) begin
        ext1.mem_array0[i] = tmp_array[i][24+:8];
        ext1.mem_array1[i] = tmp_array[i][16+:8];
        ext2.mem_array0[i] = tmp_array[i][8+:8];
        ext2.mem_array1[i] = tmp_array[i][0+:8];
    end
end
endmodule
