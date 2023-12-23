// 作者：张露晗
// 功能: 访存阶段
// 版本: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem(

	input wire										rst,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire[`RegBus]					  wdata_i,
	//访存
	 input wire[`AluOpBus]        aluop_i,
	input wire[`RegBus]          mem_addr_i,
	input wire[`RegBus]          reg2_i,
	
	input wire[`RegBus]          mem_data_i,
	
	//送到回写阶段的信息
	output reg[`RegAddrBus]      wd_o,
	output reg                   wreg_o,
	output reg[`RegBus]					 wdata_o,
	//访存
	output reg[`RegBus]          mem_addr_o,
	output wire									 mem_we_o,//低位有效
	output reg[3:0]              mem_sel_o,//低位有效
	output reg[`RegBus]          mem_data_o,
	output reg                   mem_ce_o	
	
);
    wire[`RegBus] zero32;
	reg                   mem_we;

	assign mem_we_o = ~mem_we ;
	assign zero32 = `ZeroWord;
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  wdata_o <= `ZeroWord;
		   mem_addr_o <= `ZeroWord;
		  mem_we <= `WriteDisable;
		  mem_sel_o <= 4'b1111;
		  mem_data_o <= `ZeroWord;
		  mem_ce_o <= `ChipDisable;	
		end else begin
		  wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			mem_we <= `WriteDisable;
			mem_addr_o <= `ZeroWord;
			mem_sel_o <= 4'b1111;
			mem_ce_o <= `ChipDisable;
			case (aluop_i)
			`EXE_LW_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b0000;
					mem_ce_o <= `ChipEnable;		
				end
            `EXE_SW_OP:		begin
                mem_addr_o <= mem_addr_i;
                mem_we <= `WriteEnable;
                mem_data_o <= reg2_i;
                mem_sel_o <= 4'b0000;	
                mem_ce_o <= `ChipEnable;		
            end
            `EXE_LB_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11:	begin
							wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
							mem_sel_o <= 4'b0111;
						end
						2'b10:	begin
							wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
							mem_sel_o <= 4'b1011;
						end
						2'b01:	begin
							wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
							mem_sel_o <= 4'b1101;
						end
						2'b00:	begin
							wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
							mem_sel_o <= 4'b1110;
						end
						default:	begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
			`EXE_SB_OP:		begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b11:	begin
							mem_sel_o <= 4'b0111;
						end
						2'b10:	begin
							mem_sel_o <= 4'b1011;
						end
						2'b01:	begin
							mem_sel_o <= 4'b1101;
						end
						2'b00:	begin
							mem_sel_o <= 4'b1110;	
						end
						default:	begin
							mem_sel_o <= 4'b1111;
						end
					endcase				
				end
           default:begin    end
			endcase		
		end    //if
	end      //always
			

endmodule