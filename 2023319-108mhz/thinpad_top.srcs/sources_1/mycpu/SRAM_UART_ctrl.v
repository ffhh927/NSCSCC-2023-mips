// 作者： 张露晗
// 功能: sram控制器和串口控制器
// 版本: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

`define SerialState 32'hBFD003FC    //串口状态地址
`define SerialData  32'hBFD003F8    //串口数据地址

module SRAM_UART_ctrl (
    input wire clk,
    input wire rst,

    //if阶段输入的信息和获得的指令
    (* DONT_TOUCH = "1" *) input    wire[31:0]  rom_addr_i,        //读取指令的地址
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_i,          //指令存储器使能信号
     output   reg [31:0]  inst_o,            //获取到的指令

    //mem阶段传递的信息和取得的数据
    output   reg[31:0]   ram_data_o,        //读取的数据
    input    wire[31:0]  mem_addr_i,        //读（写）地址
    input    wire[31:0]  mem_data_i,        //写入的数据
    input    wire        mem_we_n,          //写使能，低有效
    input    wire[3:0]   mem_sel_n,         //字节选择信号
    input    wire        mem_ce_i,          //片选信号

    //BaseRAM信号
    inout    wire[31:0]  base_ram_data,     //BaseRAM数据
    output   reg [19:0]  base_ram_addr,     //BaseRAM地址
    output   reg [3:0]   base_ram_be_n,     //BaseRAM字节使能，低有效。
    output   reg         base_ram_ce_n,     //BaseRAM片选，低有效
    output   reg         base_ram_oe_n,     //BaseRAM读使能，低有效
    output   reg         base_ram_we_n,     //BaseRAM写使能，低有效

    //ExtRAM信号
    inout    wire[31:0]  ext_ram_data,      //ExtRAM数据
    output   reg [19:0]  ext_ram_addr,      //ExtRAM地址
    output   reg [3:0]   ext_ram_be_n,      //ExtRAM字节使能，低有效。
    output   reg         ext_ram_ce_n,      //ExtRAM片选，低有效
    output   reg         ext_ram_oe_n,      //ExtRAM读使能，低有效
    output   reg         ext_ram_we_n,      //ExtRAM写使能，低有效
    
    output   reg         stop_inst, 

    //直连串口信号
    output   wire        txd,                //直连串口发送端
    input    wire        rxd                //直连串口接收端

);

wire [7:0]  RxD_data;           //接收到的数据
reg [7:0]  TxD_data;           //待发送的数据
wire        RxD_data_ready;     //接收器收到数据完成之后，置为1
wire        TxD_busy;           //发送器状态是否忙碌，1为忙碌，0为不忙碌
reg        TxD_start;          //发送器是否可以发送数据，1代表可以发送
reg        RxD_clear;          //为1时将清除接收标志（ready信号）


//内存映射
wire is_SerialState = (mem_addr_i ==  `SerialState); 
wire is_SerialData  = (mem_addr_i == `SerialData);
wire is_base_ram    = (mem_addr_i >= 32'h80000000) 
                    && (mem_addr_i < 32'h80400000);
wire is_ext_ram     = (mem_addr_i >= 32'h80400000)
                    && (mem_addr_i < 32'h80800000);
                    
wire [1:0]state;

reg [31:0] serial_o;        //串口输出数据
wire[31:0] base_ram_o;      //baseram输出数据
wire[31:0] ext_ram_o;       //extram输出数据


//串口实例化模块，波特率9600
async_receiver #(.ClkFrequency(108000000),.Baud(9600))   //接收模块
                ext_uart_r(
                   .clk(clk),                           //外部时钟信号
                   .RxD(rxd),                           //外部串行信号输入
                   .RxD_data_ready(RxD_data_ready),     //数据接收到标志
                   .RxD_clear(RxD_clear),               //清除接收标志
                   .RxD_data(RxD_data)                  //接收到的一字节数据
                );

async_transmitter #(.ClkFrequency(108000000),.Baud(9600)) //发送模块
                    ext_uart_t(
                      .clk(clk),                        //外部时钟信号
                      .TxD(txd),                        //串行信号输出
                      .TxD_busy(TxD_busy),              //发送器忙状态指示
                      .TxD_start(TxD_start),            //开始发送信号
                      .TxD_data(TxD_data)               //待发送的数据
                    );
//处理收发
wire rst_n = ~rst;
always @(*) begin

        TxD_start = 1'b0;
        serial_o = 32'h0000_0000;
        TxD_data = 8'h00;
        
        if(is_SerialState) begin                                     //更新串口状态
            serial_o = {{30{1'b0}}, {RxD_data_ready, !TxD_busy}};
            TxD_start = 1'b0;
            TxD_data = 8'h00;
        end
        else if(is_SerialData) begin                  
            if(mem_we_n) begin                             //读数据    
                serial_o = {24'h000000, RxD_data};
                TxD_start = 1'b0;
                TxD_data = 8'h00;
            end
            else if(!TxD_busy)begin                          //发数据
                TxD_data = mem_data_i[7:0];
                TxD_start = 1'b1;
                serial_o = 32'h0000_0000;
            end else begin
                TxD_start = 1'b0;
                serial_o = 32'h0000_0000;
                TxD_data = 8'h00;
             end
        end
        else begin
            TxD_start = 1'b0;
            serial_o = 32'h0000_0000;
            TxD_data = 8'h00;
        end
end
//处理发送
always @(*) begin
        RxD_clear = 1'b1;
        if(RxD_data_ready&&is_SerialData&&mem_we_n) begin
            RxD_clear = 1'b1;
        end
        else begin
            RxD_clear = 1'b0;
        end
end

//处理BaseRam（指令存储器）
assign base_ram_data = is_base_ram ? ((mem_we_n == 1'b0) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign base_ram_o = base_ram_data;      //读取到的BaseRam数据

//当mem阶段需要向BaseRam的地址写入或读取数据时，发生结构冒险
always @(*) begin
    base_ram_addr = 20'h00000;
    base_ram_be_n = 4'b1111;
    base_ram_ce_n = 1'b1;
    base_ram_oe_n = 1'b1;
    base_ram_we_n = 1'b1;
    inst_o = `ZeroWord;
    stop_inst = 1'b0;//basesram不被占用
    if(is_base_ram) begin           //涉及到BaseRam的相关数据操作，需要暂停流水线
        base_ram_addr = mem_addr_i[21:2];   //有对齐要求，低两位舍去
        base_ram_be_n = mem_sel_n;
        base_ram_ce_n = 1'b0;
        base_ram_oe_n = !mem_we_n;
        base_ram_we_n = mem_we_n;
        inst_o = `ZeroWord;
        stop_inst = 1'b1;
    end else begin                  //不涉及到BaseRam的相关数据操作，继续取指令
        base_ram_addr = rom_addr_i[21:2];   //有对齐要求，低两位舍去
        base_ram_be_n = 4'b0000;
        base_ram_ce_n = 1'b0;
        base_ram_oe_n = 1'b0;
        base_ram_we_n = 1'b1;
       
        if(is_SerialData)begin  //串口和取指令不能同时
        stop_inst = 1'b1;
        inst_o = `ZeroWord;
        end else begin
        stop_inst = 1'b0;
        inst_o = base_ram_o;
        end
    end
end


//处理ExtRam（数据存储器）
assign ext_ram_data = is_ext_ram ? ((mem_we_n == 1'b0) ? mem_data_i : 32'hzzzzzzzz) : 32'hzzzzzzzz;
assign ext_ram_o = ext_ram_data;

always @(*) begin
    ext_ram_addr = 20'h00000;
    ext_ram_be_n = 4'b1111;
    ext_ram_ce_n = 1'b1;
    ext_ram_oe_n = 1'b1;
    ext_ram_we_n = 1'b1;
    if(is_ext_ram) begin           //涉及到extRam的相关数据操作
        ext_ram_addr = mem_addr_i[21:2];    //有对齐要求，低两位舍去
        ext_ram_be_n = mem_sel_n;
        ext_ram_ce_n = 1'b0;
        ext_ram_oe_n = !mem_we_n;
        ext_ram_we_n = mem_we_n;
    end else begin
        ext_ram_addr = 20'h00000;
        ext_ram_be_n = 4'b1111;
        ext_ram_ce_n = 1'b1;
        ext_ram_oe_n = 1'b1;
        ext_ram_we_n = 1'b1;
    end
end


//确认输出的数据

always @(*) begin
    ram_data_o = `ZeroWord;
     if(is_SerialState || is_SerialData ) begin
         ram_data_o = serial_o;         
     end else
     if (is_base_ram) begin
        ram_data_o = base_ram_o;       
    end else if (is_ext_ram) begin
        ram_data_o = ext_ram_o;     
    end else begin
        ram_data_o = `ZeroWord;     
    end
end


endmodule //ram