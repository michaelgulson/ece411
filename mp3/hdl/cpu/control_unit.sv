import rv32i_types::*;
import control_word_types::*;

module control_unit
(
    input rv32i_opcode opcode,
    input logic[2:0] funct3,
    input logic[6:0] funct7,
    input logic [1:0] addr_01,
    output control_word ctrl_word
);


//branch_funct3_t branch_funct3;
alu_ops branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = alu_ops'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

always_comb begin : trap_check
    ctrl_word.trap = 0;
    ctrl_word.rmask = '0;
    ctrl_word.wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
				case(branch_funct3)
                alu_add_beq, alu_sll_bne, alu_xor_blt, alu_srl_bge, alu_or_bltu, alu_and_bgeu:;
                default: ctrl_word.trap = 1;			 
            endcase
        end
		op_load: begin
            case (load_funct3)
                lw: ctrl_word.rmask = 4'b1111;
                lh, lhu: 
				begin
					if(addr_01)
						ctrl_word.rmask = 4'b1100;
					else
						ctrl_word.rmask = 4'b0011; 
				end				
                lb, lbu: 
				begin
					case (addr_01)
						2'b00:
							ctrl_word.rmask = 4'b0001;
						2'b01:
							ctrl_word.rmask = 4'b0010;
						2'b10:
							ctrl_word.rmask = 4'b0100;
						2'b11:
							ctrl_word.rmask = 4'b1000;
						default:
							ctrl_word.rmask = 4'b0001;
					endcase				
				end
                default: ctrl_word.trap = 1;
            endcase
        end

		 op_store: begin
            case (store_funct3)
                sw: ctrl_word.wmask = 4'b1111;
                sh: 
				begin
					if(addr_01)
						ctrl_word.wmask = 4'b1100; 
					else
						ctrl_word.wmask = 4'b0011 ;
				end	
                sb:
				begin
					case (addr_01)
						2'b00:
							ctrl_word.wmask = 4'b0001;
						2'b01:
							ctrl_word.wmask = 4'b0010;
						2'b10:
							ctrl_word.wmask = 4'b0100;
						2'b11:
							ctrl_word.wmask = 4'b1000;
						default:
							ctrl_word.wmask = 4'b0001;
					endcase				
				end 
                default: ctrl_word.trap = 1;
            endcase
        end
        default: ctrl_word.trap = 1;
    endcase
end

always_comb begin
    //default assignments
    ctrl_word.alu_op = alu_ops'(funct3);
    ctrl_word.mem_read = 1'b0;
    ctrl_word.mem_write = 1'b0;
    ctrl_word.regfile_mux_sel = regfilemux::alu_out; 
    ctrl_word.load_regfile = 1'b0;
    ctrl_word.pc_mux_sel = 2'b00; //<-- fix this
    ctrl_word.alu_muxsel1 = alumux::rs1_out;
    ctrl_word.alu_muxsel2 = alumux::rs2_out;
    ctrl_word.dest = 1'b0; //<-- fix this

    case (opcode)
        op_lui: begin
            ctrl_word.load_regfile  = 1'b1;
            ctrl_word.regfile_mux_sel = regfilemux::u_imm; 
        end
        op_auipc: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.regfile_mux_sel = regfilemux::alu_out;
            ctrl_word.load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::pc_out;
            ctrl_word.alu_muxsel2 = alumux::u_imm;
        end
        op_jal: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.regfile_mux_sel = regfilemux::pc_plus4;
            ctrl_word.load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::pc_out;
            ctrl_word.alu_muxsel2 = alumux::j_imm;
        end
        op_jalr: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.regfile_mux_sel = regfilemux::pc_plus4;
            ctrl_word.load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::i_imm;
        end
        op_br: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.alu_muxsel1 = alumux::pc_out;
            ctrl_word.alu_muxsel2 = alumux::b_imm;
        end
        op_load: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.mem_read = 1'b1;
            ctrl_word.load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::i_imm;
            case(load_funct3)
                lw: ctrl_word.regfile_mux_sel = regfilemux::lb;
                lh: ctrl_word.regfile_mux_sel = regfilemux::lh;
                lhu: ctrl_word.regfile_mux_sel = regfilemux::lhu;
                lb:ctrl_word.regfile_mux_sel = regfilemux::lb;
                lbu:ctrl_word.regfile_mux_sel = regfilemux::lbu;
                default:;    //#########
            endcase
        end
        op_store: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.mem_write = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::s_imm;   
        end
        op_imm: begin
            ctrl_word.load_regfile = 1'b1;
            case(arith_funct3)
                slt: ctrl_word.regfile_mux_sel = regfilemux::br_en;
                //########Not done yet here 
                default: begin
                    ctrl_word.regfile_mux_sel = 1'b1;
                    ctrl_word.alu_op = alu_ops'(funct3);
                end
            endcase
        end
        op_reg: begin
        
        end
        default: ;
    endcase
end
endmodule: control_unit



