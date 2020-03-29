`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
`define CONTROL_WORD_SIZE 31

import rv32i_types::*;
//import control_word_types::*;

module datapath(
    input logic clk,
    input logic rst,

    input rv32i_word inst_rdata,
    output rv32i_word inst_addr,
    output logic inst_read,
    input logic inst_resp, 

    input rv32i_word data_rdata,
    input logic data_resp,
    output rv32i_word data_wdata, // signal used by RVFI Monitor
    output rv32i_word data_addr,
    output logic [3:0] data_mbe,
    output logic data_read,
    output logic data_write
);

//IF stage
rv32i_word pcmux_out;
rv32i_word pc_ID;
logic load_pc;
rv32i_word pc_out;
pcmux::pcmux_sel_t pcmux_sel; //based on the MEM stage br_en and control word

//ID stage
rv32i_word regfile_out_srca;
rv32i_word regfile_out_srcb;
logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;
logic [2:0] funct3;
logic [6:0] funct7;
rv32i_opcode opcode;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_control_word ctrl_word;

//EX stage
rv32i_word alu_out;
rv32i_word read_data1_EX;
rv32i_word read_data2_EX;
rv32i_word pc_EX;
logic br_en;
rv32i_control_word control_word_EX;
rv32i_word imm_EX;
rv32i_word alu_mux1_out; //ALU
rv32i_word alu_mux2_out; //ALU
alu_ops aluop; //ALU
logic [1:0] alumux1_sel;
rv32i_word alumux1_out;
logic [2:0] alumux2_sel;
rv32i_word alumux2_out;
rv32i_word pc_offset;
rv32i_word i_imm_EX;
rv32i_word s_imm_EX;
rv32i_word b_imm_EX;
rv32i_word u_imm_EX;
rv32i_word j_imm_EX;

//MEM stage
rv32i_word imm_MEM;
rv32i_word alu_out_MEM;
rv32i_word data_out;
rv32i_word pc_MEM;
rv32i_word pc_offset_MEM;
rv32i_control_word control_word_MEM;
rv32i_word aluout_MEM;
rv32i_word read_data2_MEM;
logic br_en_MEM;

//WB stage
rv32i_word imm_WB;
rv32i_word aluout_WB;
rv32i_word data_out_WB;
rv32i_word pc_WB;
logic br_en_WB;
rv32i_control_word control_word_WB;
rv32i_word regfilemux_out;
rv32i_word dm_mask_b;
rv32i_word dm_mask_h;
rv32i_word dm_mask_w;
rv32i_word pc_offset_WB;
rv32i_word u_imm_WB;


//need this for true values. Gives you a warning if you define it. 
logic true;
assign true = 1'b1;

//assigned variables for EX stage  //##############change to instruction from control word
assign pc_offset = pc_offset_MEM + imm_EX;
assign i_imm_EX = {{21{imm_EX[31]}}, imm_EX[30:20]};
assign s_imm_EX = {{21{imm_EX[31]}}, imm_EX[30:25], imm_EX[11:7]};
assign b_imm_EX = {{20{imm_EX[31]}}, imm_EX[7], imm_EX[30:25], imm_EX[11:8], 1'b0};
assign u_imm_EX = {imm_EX[31:12], 12'h000};
assign j_imm_EX = {{12{imm_EX[31]}}, imm_EX[19:12], imm_EX[20], imm_EX[30:21], 1'b0};

//assigned variables for WB stage
assign u_imm_WB = {imm_WB[31:12], 12'h000};

/********************************Control Unit********************************/
control_unit Control_Unit( //incldue instruction
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .addr_01(pc_offset_MEM[1:0]), // <-----FIX THIS
    .ctrl_word(ctrl_word)
);
/****************************************************************************/

/********************************Regfile*************************************/
regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(control_word_WB.load_regfile),
    .in(regfilemux_out),
    .src_a(rs1), .src_b(rs2), .dest(control_word_WB.dest),
    .reg_a(rs1_out), .reg_b(rs2_out)
);
/****************************************************************************/

/********************************Registers***********************************/
//Other registers
//pcreg
pc_register pc(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

//5 stage registers
//IF/ID
register pc_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_out),
    .out(pc_ID)
);

ir ir_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(inst_rdata),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    // .i_imm(i_imm),
    // .s_imm(s_imm),
    // .b_imm(b_imm),
    // .u_imm(u_imm),
    // .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

//ID/EX
register #(`CONTROL_WORD_SIZE) control_word_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(ctrl_word),
    .out(control_word_EX)
); 

register pc_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_ID),
    .out(pc_EX)
);

register read_data1_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(regfile_out_srca),
    .out(read_data1_EX)
);

register read_data2_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(regfile_out_srcb),
    .out(read_data2_EX)
);

// register imm_ID_EX(
//     .clk(clk),
//     .rst(rst),
//     .load(true),
//     .in(i_imm),
//     .out(imm_EX)
// );

//EX/MEM
register #(`CONTROL_WORD_SIZE) control_word_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(control_word_EX),
    .out(control_word_MEM)
); 

register pc_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_EX),
    .out(pc_MEM)
);

register #(1) br_en_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(br_en),
    .out(br_en_MEM)
);

register pc_offset_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_offset),
    .out(pc_offset_MEM)
);

register read_data2_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(read_data2_EX),
    .out(read_data2_MEM)
);

// register imm_EX_MEM(
//     .clk(clk),
//     .rst(rst),
//     .load(true),
//     .in(imm_EX),
//     .out(imm_MEM)
// );

register ALUout_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(alu_out),
    .out(aluout_MEM)
);

//MEM/WB
register control_word_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(control_word_MEM),
    .out(control_word_WB)
); 

register br_en_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(br_en_MEM),
    .out(br_en_WB)
); 

register pc_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_MEM),
    .out(pc_WB)
);

register pc_offset_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_offset_MEM),
    .out(pc_offset_WB)
);

register data_out_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(data_rdata),
    .out(data_out_WB)
);

register alu_out_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(alu_out_MEM),
    .out(aluout_WB)
);

// register imm_MEM_WB(
//     .clk(clk),
//     .rst(rst),
//     .load(true),
//     .in(imm_MEM),
//     .out(imm_WB)
// );
/****************************************************************************/

/*******************************ALU and CMP in one module********************/
alu ALU(
    .aluop(aluop), //controls the operation of the ALU
    .a(alu_mux1_out), //this is the output of the mux for input 1 of ALU
    .b(alu_mux2_out), //this is the output of the mux for input 2 of ALU
    .f(alu_out), //output of the ALU
    .z(br_en) //br_en output 
);
/*****************************************************************************/

/*******************************Other modules*********************************/
load_masking data_mem_masking(
    .rmask(control_word_WB.rmask),
    .mdrreg_out(data_out_WB),
    .mdr_mask_h(dm_mask_h),
    .mdr_mask_b(dm_mask_b),
    .mdr_mask_w(dm_mask_w)
);
/*****************************************************************************/

/*********************************Muxes***************************************/
//fix this, variables are not correct to their stages.
always_comb begin : MUXES
    //IF stage
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out:  pcmux_out = aluout_MEM;
        pcmux::alu_mod2:  pcmux_out = {aluout_MEM[31:1],1'b0};
        default: pcmux_out = pc_out;
    endcase

    //EX stage
    unique case (control_word_EX.alu_muxsel1)
        alumux::rs1_out:  alumux1_out = read_data1_EX;
        alumux::pc_out:   alumux1_out = pc_EX;
        default: alumux1_out = read_data1_EX;
    endcase

    unique case (control_word_EX.alu_muxsel2)
        alumux::i_imm: alumux2_out = i_imm_EX;  
        alumux::u_imm: alumux2_out = u_imm_EX;
        alumux::b_imm: alumux2_out = b_imm_EX;
        alumux::s_imm: alumux2_out = s_imm_EX;
        alumux::j_imm: alumux2_out = j_imm_EX;
        alumux::rs2_out: alumux2_out = read_data2_EX;
        default: alumux2_out = i_imm_EX;
    endcase

    //WB stage
    unique case (control_word_WB.regfile_mux_sel)
        regfilemux::alu_out:    regfilemux_out = aluout_WB;
        regfilemux::br_en:      regfilemux_out = {31'b0, br_en_WB};
        regfilemux::u_imm:      regfilemux_out = u_imm_WB;
        regfilemux::lw:         regfilemux_out = data_out_WB;
        regfilemux::pc_plus4:  regfilemux_out = pc_WB +4;
        regfilemux::lb:     begin
                            if(dm_mask_b[7]==1'b1)
                            regfilemux_out = {24'b111111111111111111111111, dm_mask_b[7:0]};    
                            else
                            regfilemux_out = {24'b000000000000000000000000, dm_mask_b[7:0]};    
                            end
        regfilemux::lbu:    regfilemux_out = {24'b000000000000000000000000, dm_mask_b[7:0]};//fix later
        regfilemux::lh:     begin
                            if(dm_mask_h[15]==1'b1)
                                regfilemux_out = {16'b1111111111111111, dm_mask_h[15:0]};
                            else
                                regfilemux_out = {16'b0000000000000000, dm_mask_h[15:0]};
                            end
        regfilemux::lhu:    regfilemux_out = {16'b0000000000000000, dm_mask_h[15:0]};
        default: regfilemux_out = aluout_WB;
    endcase

end
/*****************************************************************************/

endmodule: datapath
