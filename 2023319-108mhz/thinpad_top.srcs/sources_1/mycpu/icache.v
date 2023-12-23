// 作者： 张露晗
// 功能: 指令缓存icache
// 版本: 1.0
//////////////////////////////////////////////////////////////////////
`define ZeroWord 32'h00000000

module icache(
    //时钟
    input wire clk,
    input wire rst,
//与cpu连接
        //if阶段输入的信息和获得的指令
    (* DONT_TOUCH = "1" *) input    wire[31:0]  rom_addr_i,        //读取指令的地址
    (* DONT_TOUCH = "1" *) input    wire        rom_ce_i,          //指令存储器使能信号
     output   reg [31:0]  inst_o,            //获取到的指令

    output   reg         stall,
//与sram控制器连接
     input wire  inst_stop,
     input   wire [31:0]  inst_i          //获取到的指令

);


//icache需要实现的功能包括：
//读取
//命中时取指
//未命中时发出流水线暂停信号，从sram中取值


//cache大小32*32，即1K=128B
//采用直接映射，每块只一个字，块内寻址2位,cache地址5位
//basesram大小4MB，地址22位
//tag 22-5-2=15位
//valid 1位
parameter Cache_Num = 32;
parameter Tag = 15;
parameter Cache_Index = 5;
parameter Block_Offset = 2;
 reg[31:0] cache_mem[0:Cache_Num-1];//cache memory
 reg[Tag-1:0] cache_tag[0:Cache_Num-1];//cache tag
 reg[Cache_Num-1:0]        cache_valid;//cache valid

//状态机
parameter IDLE=0;//初态
parameter READ_SRAM=1;

reg[1:0] state,next_state;

always@(posedge clk or posedge rst)begin
    if(rst)begin
        state<=IDLE;
      //  state<= READ_SRAM;
    end else begin
        state<=next_state;
    end
end


//read
//hit(单独指读命中，写命中没有意义)
wire [Tag-1:0] ram_tag_i = rom_addr_i[21:7];//ram tag
wire [Cache_Index-1:0] ram_cache_i = rom_addr_i[6:2];//ram cache block addr

wire hit = (state==IDLE)?cache_valid[ram_cache_i]&&(cache_tag[ram_cache_i]==ram_tag_i):1'b0;//tag相同，valid=1命中（写无效）
//wire hit =1'b0;
reg finish_read;
integer i;
//获取指令
always@(*)begin
    if(rst)begin
        finish_read = 1'b0;
        inst_o = `ZeroWord;       //读取的指令
    end else begin
        case(state)
        IDLE:begin
            finish_read = 1'b0;       
            if(hit&&~inst_stop)begin
                inst_o = cache_mem[ram_cache_i];
            end else begin
                inst_o = `ZeroWord;
            end
        end
        READ_SRAM: begin       
                inst_o = inst_i;       //读取的指令  
                finish_read = 1'b1;   
        end
        default:begin 
            finish_read = 1'b0;
            inst_o = 32'hzzzzzzzz;
        end
        endcase
    end
end
//存入cache memory
wire rst_n = ~rst;
always@(posedge clk or posedge rst_n)begin
    if(!rst_n)begin
        for(i=0 ; i < 32 ; i=i+1)begin
                cache_mem[i] <= 32'b0;
                cache_tag[i] <= 15'b0;
            end  
        cache_valid <=32'h00000000;
    end else begin
        case(state)
        READ_SRAM: begin       
                cache_mem[ram_cache_i] <= inst_i;
                cache_valid[ram_cache_i] <= 1'b1;
                cache_tag[ram_cache_i] <= ram_tag_i;//cache tag  
        end
        default:begin 
                 cache_mem[ram_cache_i] <= cache_mem[ram_cache_i];
                cache_valid[ram_cache_i] <= cache_valid[ram_cache_i];
                cache_tag[ram_cache_i] <= cache_tag[ram_cache_i];//cache tag  
        end
        endcase
    end
end
//状态控制
always@(*)begin
    if(rst)begin
        stall = 1'b0;     
        next_state = READ_SRAM;
    end else begin
        case(state)
            IDLE:begin
                if(rom_ce_i&&~hit&&~inst_stop)begin//读，未命中
                    next_state=READ_SRAM;
                    stall = 1'b1;
                end else begin
                    next_state=IDLE;
                    stall = 1'b0;
                end
            end
            READ_SRAM:begin
                if(finish_read)begin
                    next_state=IDLE;
                    stall = 1'b0;
                    end
                else begin
                    next_state=READ_SRAM;
                    stall = 1'b1;  
                    stall = 1'b0;
                end 
             end
            default:begin 
                     next_state = IDLE;
                     stall = 1'b0;
            end
        endcase
    end
end
endmodule