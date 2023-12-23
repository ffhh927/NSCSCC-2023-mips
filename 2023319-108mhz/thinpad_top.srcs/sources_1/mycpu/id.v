// 作者 ：张露晗
// 功能: 译码阶段
// 版本: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module id(

	input wire										rst,
	//从if阶段接受的信息
	input wire[`InstAddrBus]			pc_i,
	input wire[`InstBus]          inst_i,
	
	//处理Load相关
	 input wire[`AluOpBus]					ex_aluop_i,
	
    //regfile返回的信息
	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,

    //数据前递
    //执行阶段数据前递
	input wire							ex_wreg_i,
	input wire[`RegBus]					ex_wdata_i,
	input wire[`RegAddrBus]            ex_wd_i,
	
	//访存阶段数据前递
	input wire								mem_wreg_i,
	input wire[`RegBus]						mem_wdata_i,
	input wire[`RegAddrBus]                  mem_wd_i,
	
    //延迟槽
    input wire                    is_in_delayslot_i,

	//送到regfile的信息
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//送到执行阶段的信息
	output reg[`AluOpBus]         aluop_o,//8位运算子类型
	output reg[`AluSelBus]        alusel_o,//3位运算类型
	output reg[`RegBus]           reg1_o,//源操作数1的值
	output reg[`RegBus]           reg2_o,//源操作数2的值
	output reg[`RegAddrBus]       wd_o,//写回的地址
	output reg                    wreg_o,//是否要写回
	
	//延迟槽
	output reg                    next_inst_in_delayslot_o,
	
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,       
	output reg[`RegBus]           link_addr_o,
	output reg                    is_in_delayslot_o,
	//ls
	output wire[`RegBus]          inst_o,
	
	output   wire        stallreq         // 流水线暂停请求
);

  wire[5:0] op = inst_i[31:26];//op
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];//func
  wire[4:0] op4 = inst_i[20:16];
  reg[`RegBus]	imm;
  reg instvalid;
  
  //延迟槽
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_sll2_signedext;  
  
  assign pc_plus_8 = pc_i + 8;
  assign pc_plus_4 = pc_i +4;
  assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  //扩展
  
    //ls
    assign inst_o = inst_i;
 
    //处理load相关
    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;
  //流水线暂停
    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
     assign pre_inst_is_load = 	(ex_aluop_i == `EXE_LW_OP)||(ex_aluop_i == `EXE_LB_OP)  ? 1'b1 : 1'b0;
      
    
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;		
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;	
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];		
			imm <= `ZeroWord;			
			link_addr_o <= `ZeroWord;
             branch_target_address_o <= `ZeroWord;
             branch_flag_o <= `NotBranch;			
			next_inst_in_delayslot_o <= `NotInDelaySlot; 
		  case (op)
		  `EXE_SPECIAL_INST:		begin
		    	case (op2)
		    		5'b00000:			begin
		    			case (op3)
		    			`EXE_ADDU: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDU_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
						`EXE_SUB: begin
									wreg_o <= `WriteEnable;		aluop_o <= `EXE_SUB_OP;
		  						alusel_o <= `EXE_RES_ARITHMETIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end
						`EXE_OR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  						alusel_o <= `EXE_RES_LOGIC; 	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;	
								end  
		    			`EXE_AND:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
		  						alusel_o <= `EXE_RES_LOGIC;	  reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  	
		    			`EXE_XOR:	begin
		    					wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
		  						alusel_o <= `EXE_RES_LOGIC;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  						instvalid <= `InstValid;	
								end  	
						`EXE_SRAV: begin
								wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRA_OP;
		  						alusel_o <= `EXE_RES_SHIFT;		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  						instvalid <= `InstValid;			
		  						end	
		  				`EXE_JR: begin
								wreg_o <= `WriteDisable;		aluop_o <= `EXE_JR_OP;
		  						alusel_o <= `EXE_RES_JUMP_BRANCH;   reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  						link_addr_o <= `ZeroWord;	  						
			            	    branch_target_address_o <= reg1_o;
			                 	branch_flag_o <= `Branch;			           
			                    next_inst_in_delayslot_o <= `InDelaySlot;
			                    instvalid <= `InstValid;	
								end
								default:	begin
						    end
						  endcase
						  end
						default: begin
						end
					endcase	
				end
		  	`EXE_ORI:			begin                        //ORI指令
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
		  	end 	
		  	`EXE_LUI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  		alusel_o <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {inst_i[15:0], 16'h0};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	
			`EXE_ANDI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
		  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 	
		  	`EXE_XORI:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
		  		alusel_o <= `EXE_RES_LOGIC;	reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 	
			`EXE_ADDIU:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_ADDIU_OP;
		  		alusel_o <= `EXE_RES_ARITHMETIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
			`EXE_J:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_J_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		link_addr_o <= `ZeroWord;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
			`EXE_JAL:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_JAL_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b0;
		  		wd_o <= 5'b11111;	
		  		link_addr_o <= pc_plus_8 ;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    instvalid <= `InstValid;	
				end
			`EXE_BEQ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BEQ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o == reg2_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end else begin
			          branch_target_address_o <= `ZeroWord;
			          branch_flag_o <= `NotBranch;	
			          next_inst_in_delayslot_o <= `NotInDelaySlot; 
			     end
				end
			`EXE_BGTZ:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGTZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;	
		  		if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end else begin
			          branch_target_address_o <= `ZeroWord;
			          branch_flag_o <= `NotBranch;	
			          next_inst_in_delayslot_o <= `NotInDelaySlot; 
			     end
				end
			`EXE_REGIMM_INST:		begin
					case (op4)
						`EXE_BGEZ:	begin
							wreg_o <= `WriteDisable;		aluop_o <= `EXE_BGEZ_OP;
		  				alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
		  				instvalid <= `InstValid;	
		  				if(reg1_o[31] == 1'b0) begin
			    			branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    			branch_flag_o <= `Branch;
			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
			   			end else begin
                              branch_target_address_o <= `ZeroWord;
                              branch_flag_o <= `NotBranch;	
                              next_inst_in_delayslot_o <= `NotInDelaySlot; 
                         end
						end
						default:	begin
						end
					endcase
				end			
			`EXE_SPECIAL2_INST:		begin
					case ( op3 )
						`EXE_MUL:		begin
							wreg_o <= `WriteEnable;		aluop_o <= `EXE_MUL_OP;
		  				alusel_o <= `EXE_RES_MUL; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;	
		  				instvalid <= `InstValid;	  			
						end
						default:	begin
						end
					endcase      //EXE_SPECIAL_INST2 case
				end			
			`EXE_BNE:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
		  		alusel_o <= `EXE_RES_JUMP_BRANCH; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1;
		  		instvalid <= `InstValid;	
		  		if(reg1_o != reg2_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end else begin
			          branch_target_address_o <= `ZeroWord;
			          branch_flag_o <= `NotBranch;	
			          next_inst_in_delayslot_o <= `NotInDelaySlot; 
			     end
			end	
			`EXE_LW:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LW_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
			end
            `EXE_SW:			begin
            wreg_o <= `WriteDisable;		aluop_o <= `EXE_SW_OP;
            reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
            alusel_o <= `EXE_RES_LOAD_STORE; 
            end		
            `EXE_LB:			begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_LB_OP;
		  		alusel_o <= `EXE_RES_LOAD_STORE; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;	  	
					wd_o <= inst_i[20:16]; instvalid <= `InstValid;	
				end
			`EXE_SB:			begin
		  		wreg_o <= `WriteDisable;		aluop_o <= `EXE_SB_OP;
		  		reg1_read_o <= 1'b1;	reg2_read_o <= 1'b1; instvalid <= `InstValid;	
		  		alusel_o <= `EXE_RES_LOAD_STORE; 
				end			 
		    default:			begin
		    end
		  endcase		  //case op		
		  
		  if (inst_i[31:21] == 11'b00000000000) begin
		  	if (op3 == `EXE_SLL) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRL ) begin
		  		wreg_o <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
		  		alusel_o <= `EXE_RES_SHIFT; reg1_read_o <= 1'b0;	reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else begin
				end
			end		  
		
		end       //if
	end         //always
	

	always @ (*) begin
	stallreq_for_reg1_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o //load相关
								&& reg1_read_o == 1'b1 ) begin
		  stallreq_for_reg1_loadrelate <= `Stop;	
        end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) //ex阶段前递
                            && (ex_wd_i == reg1_addr_o)) begin
        reg1_o <= ex_wdata_i; 
      end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) //mem阶段前递
                            && (mem_wd_i == reg1_addr_o)) begin
        reg1_o <= mem_wdata_i; 	
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	always @ (*) begin
	stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
								&& reg2_read_o == 1'b1 ) begin
		  stallreq_for_reg2_loadrelate <= `Stop;	
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) //ex阶段前递
								&& (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) //mem阶段前递
								&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;		
	  end else if(reg2_read_o == 1'b1) begin
	  	reg2_o <= reg2_data_i;
	  end else if(reg2_read_o == 1'b0) begin
	  	reg2_o <= imm;
	  end else begin
	    reg2_o <= `ZeroWord;
	  end
	end
	//分支
	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
		  is_in_delayslot_o <= is_in_delayslot_i;		
	  end
	end

	

endmodule