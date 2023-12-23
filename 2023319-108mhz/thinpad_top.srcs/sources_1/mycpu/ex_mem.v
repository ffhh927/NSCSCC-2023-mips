// 作者：张露晗
// 功能: EX/MEM阶段的寄存器
// 版本: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex_mem(

	input	wire										clk,
	input wire										rst,
	
	input wire[5:0]							 stall,	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_wreg,
	input wire[`RegBus]					 ex_wdata, 	
	//访存
	input wire[`AluOpBus]        ex_aluop,
	input wire[`RegBus]          ex_mem_addr,
	input wire[`RegBus]          ex_reg2,
	
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]					 mem_wdata,
	//访存
	 output reg[`AluOpBus]        mem_aluop,
	 output reg[`RegBus]          mem_mem_addr,
	 output reg[`RegBus]          mem_reg2
	
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;	
		  mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;	
		end else begin
			if(stall[3] == `Stop && stall[4] == `NoStop) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		   mem_wdata <= `ZeroWord;		
		   mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;		  				    
		end else if(stall[3] == `NoStop) begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;	
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;	
		end else begin
			mem_wd <= mem_wd;
			mem_wreg <= mem_wreg;
			mem_wdata <= mem_wdata;	
			mem_aluop <= mem_aluop;
			mem_mem_addr <= mem_mem_addr;
			mem_reg2 <= mem_reg2;							
		end  		
		end    //if
	end      //always
			

endmodule