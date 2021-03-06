import rv32i_types::*;
//import control_word_types::*;
`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

module control_unit
(
    input rv32i_word instr,
    input rv32i_opcode opcode,
    input logic[2:0] funct3,
    input logic[6:0] funct7,
    input logic [1:0] addr_01,
    output rv32i_control_word ctrl_word
);

alu_ops branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = alu_ops'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

logic pre_load_regfile;

always_comb begin : trap_check
    ctrl_word.trap = 0;

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
                lw: ;
                lh, lhu: ;		
                lb, lbu: ;
                default: ctrl_word.trap = 1;
            endcase
        end

		 op_store: begin
            case (store_funct3)
                sw: ;
                sh: ;
                sb: ;
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
    pre_load_regfile = 1'b0;
    ctrl_word.pc_mux_sel = pcmux::pc_plus4;
    ctrl_word.alu_muxsel1 = alumux::rs1_out;
    ctrl_word.alu_muxsel2 = alumux::rs2_out;
    ctrl_word.dest = instr[11:7];
    ctrl_word.data_addrmux_sel = datamux::pc_out;
    ctrl_word.instr = instr;
    ctrl_word.rs1 = instr[19:15]; //source for rs1
    ctrl_word.rs2 = instr[24:20]; //source for rs2
    case (opcode)
        op_lui: begin
            pre_load_regfile  = 1'b1;
            ctrl_word.regfile_mux_sel = regfilemux::u_imm; 
            ctrl_word.rs1 = 3'b0; //not using rs1
            ctrl_word.rs2 = 3'b0; //not using rs2
        end
        op_auipc: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.regfile_mux_sel = regfilemux::alu_out;
            pre_load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::pc_out;
            ctrl_word.alu_muxsel2 = alumux::u_imm;
            ctrl_word.pc_mux_sel = pcmux::pc_plus4;
            ctrl_word.rs1 = 3'b0; //not using rs1
            ctrl_word.rs2 = 3'b0; //not using rs2
        end
        op_jal: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.regfile_mux_sel = regfilemux::pc_plus4;
            pre_load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::pc_out;
            ctrl_word.alu_muxsel2 = alumux::j_imm;
            ctrl_word.pc_mux_sel = pcmux::alu_out;
            ctrl_word.rs1 = 3'b0; //not using rs1
            ctrl_word.rs2 = 3'b0; //not using rs2
        end
        op_jalr: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.regfile_mux_sel = regfilemux::pc_plus4;
            pre_load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::i_imm;
            ctrl_word.pc_mux_sel = pcmux::alu_mod2;
            ctrl_word.rs2 = 3'b0; //not using rs2
        end
        op_br: begin
            ctrl_word.dest = 3'b0; //don't use dest register
            ctrl_word.alu_op = branch_funct3;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::rs2_out;
            ctrl_word.pc_mux_sel = pcmux::alu_out;
        end
        op_load: begin
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.mem_read = 1'b1;
            pre_load_regfile = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::i_imm;
            ctrl_word.pc_mux_sel = pcmux::pc_plus4;  
            ctrl_word.data_addrmux_sel = datamux::alu_out;
            ctrl_word.rs2 = 3'b0; //not using rs2
            case(load_funct3)
                lw: ctrl_word.regfile_mux_sel = regfilemux::lw;
                lh: ctrl_word.regfile_mux_sel = regfilemux::lh;
                lhu: ctrl_word.regfile_mux_sel = regfilemux::lhu;
                lb:ctrl_word.regfile_mux_sel = regfilemux::lb;
                lbu:ctrl_word.regfile_mux_sel = regfilemux::lbu;
                default:;    //#########
            endcase
        end
        op_store: begin
            ctrl_word.dest = 3'b0; //don't use dest register
            ctrl_word.alu_op = alu_add_beq;
            ctrl_word.mem_write = 1'b1;
            ctrl_word.alu_muxsel1 = alumux::rs1_out;
            ctrl_word.alu_muxsel2 = alumux::s_imm;   
            ctrl_word.pc_mux_sel = pcmux::pc_plus4;   
            ctrl_word.data_addrmux_sel = datamux::alu_out;
        end
        op_imm: begin
            pre_load_regfile = 1'b1;
            ctrl_word.pc_mux_sel = pcmux::pc_plus4;
            ctrl_word.rs2 = 3'b0; //not using rs2
            case(arith_funct3)
                slt: ctrl_word.regfile_mux_sel = regfilemux::br_en;
                sltu: ctrl_word.regfile_mux_sel = regfilemux::br_en;
                sr:
                begin
                    ctrl_word.regfile_mux_sel = regfilemux::alu_out;
                    ctrl_word.alu_muxsel1 = alumux::rs1_out;
                    ctrl_word.alu_muxsel2 = alumux::i_imm;
                    pre_load_regfile = 1'b1;

                    if (funct7 == 7'b0000000) //SRLI
                    begin
                        ctrl_word.alu_op = alu_ops'(funct3);
                    end
                    if (funct7 == 7'b0100000) //SRAI
                    begin
                        ctrl_word.alu_op = alu_sra;
                    end
                end
                default: begin
                    ctrl_word.regfile_mux_sel = regfilemux::alu_out;
                    ctrl_word.alu_op = alu_ops'(funct3);
                    ctrl_word.alu_muxsel1 = alumux::rs1_out;
                    ctrl_word.alu_muxsel2 = alumux::i_imm;
                end
            endcase
        end
        op_reg: begin
            ctrl_word.regfile_mux_sel = regfilemux::alu_out;
            pre_load_regfile = 1'b1;
            ctrl_word.pc_mux_sel = pcmux::pc_plus4;
            case(arith_funct3)
                add:
                begin
                    if(funct7 == 7'b0000000)
                    begin
                        ctrl_word.alu_op = alu_add_beq;
                        ctrl_word.alu_muxsel1 = alumux::rs1_out;
                        ctrl_word.alu_muxsel2 = alumux::rs2_out;
                    end
                    if(funct7 == 7'b0100000)
                    begin
                        ctrl_word.alu_op = alu_sub;
                        ctrl_word.alu_muxsel1 = alumux::rs1_out;
                        ctrl_word.alu_muxsel2 = alumux::rs2_out;
                    end
                end
                sll:
                begin
                    ctrl_word.alu_op = alu_sll_bne;
                    ctrl_word.alu_muxsel1 = alumux::rs1_out;
                    ctrl_word.alu_muxsel2 = alumux::rs2_out;
                end
                slt:
                begin
                    ctrl_word.regfile_mux_sel = regfilemux::br_en;
                end
                sltu:
                begin
                    ctrl_word.regfile_mux_sel = regfilemux::br_en;
                end
                axor:
                begin
                    ctrl_word.alu_op = alu_xor_blt;
                    ctrl_word.alu_muxsel1 = alumux::rs1_out;
                    ctrl_word.alu_muxsel2 = alumux::rs2_out;
                end
                sr:
                begin
                    if(funct7 == 7'b0000000)
                    begin
                        ctrl_word.alu_op = alu_srl_bge;
                        ctrl_word.alu_muxsel1 = alumux::rs1_out;
                        ctrl_word.alu_muxsel2 = alumux::rs2_out;
                    end
                    if(funct7 == 7'b0100000)
                    begin
                        ctrl_word.alu_op = alu_sra;
                        ctrl_word.alu_muxsel1 = alumux::rs1_out;
                        ctrl_word.alu_muxsel2 = alumux::rs2_out;
                    end
                end
                aor:
                begin
                    ctrl_word.alu_op = alu_or_bltu;
                    ctrl_word.alu_muxsel1 = alumux::rs1_out;
                    ctrl_word.alu_muxsel2 = alumux::rs2_out;
                end
                aand:
                begin
                    ctrl_word.alu_op = alu_and_bgeu;
                    ctrl_word.alu_muxsel1 = alumux::rs1_out;
                    ctrl_word.alu_muxsel2 = alumux::rs2_out;
                end
                default: `BAD_MUX_SEL;
            endcase
     end
     default: ;
     endcase
 end

//if dest reg = 0, then load_regfile is 0
 assign ctrl_word.load_regfile = (instr[11:7] == 0) ? 1'b0 : pre_load_regfile;

 endmodule: control_unit


