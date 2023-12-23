// 作者：张露晗
// 功能: 通用寄存器，共32个
// 版本: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module regfile(

	input	wire										clk,
	input wire										rst,
	
	//写端口
	input wire										we,//写使能
	input wire[`RegAddrBus]				waddr,
	input wire[`RegBus]						wdata,
	
	//读端口1
	input wire										re1,//rs1读使能
	input wire[`RegAddrBus]			  raddr1,
	output reg[`RegBus]           rdata1,
	
	//读端口2
	input wire										re2,//rs2读使能
	input wire[`RegAddrBus]			  raddr2,
	output reg[`RegBus]           rdata2
	
);

	reg[`RegBus]  regs[0:`RegNum-1];
	

    //写回
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] <= wdata;
			end else if(waddr == `RegNumLog2'h0) begin
			     regs[waddr] <= `ZeroWord;
		    end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata1 <= `ZeroWord;
	  end else if(raddr1 == `RegNumLog2'h0) begin//rs1=x0
	  		rdata1 <= `ZeroWord;
	  end else if((raddr1 == waddr) && (we == `WriteEnable) //先写后读
	  	            && (re1 == `ReadEnable)) begin
	  	  rdata1 <= wdata;
	  end else if(re1 == `ReadEnable) begin
	      rdata1 <= regs[raddr1];
	  end else begin
	      rdata1 <= `ZeroWord;
	  end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata2 <= `ZeroWord;
	  end else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  end else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  rdata2 <= wdata;
	  end else if(re2 == `ReadEnable) begin
	      rdata2 <= regs[raddr2];
	  end else begin
	      rdata2 <= `ZeroWord;
	  end
	end

endmodule