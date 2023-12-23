// 作者： 张露晗
// 功能: 指令指针寄存器PC
// 版本: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module pc_reg(

	input	wire										clk,
	input wire										rst,
	input wire [5:0]                            stall,//暂停信号
	

	
	input wire                    branch_flag_i,//是否发生转移
	input wire[`RegBus]           branch_target_address_i,//转移到的地址
	
	output reg[`InstAddrBus]			pc,//取出指令的地址
	output reg                    ce  //指令寄存使能信号
	
);
// 指令地址控制

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else begin
            if(stall[0]==`NoStop) begin
                if(branch_flag_i == `Branch) begin
                    pc <= branch_target_address_i;
                end else begin
                    pc <= pc + 4'h4;
                end 
            end else begin
                 pc <= pc;
            end 
		end 
	end
// 开启指令	
	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

endmodule