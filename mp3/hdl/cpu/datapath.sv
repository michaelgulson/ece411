`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
`define CONTROL_WORD_SIZE 66
`define NON_SYNTHESIS //uncomment to use non synthesis for rvfi montior 

import rv32i_types::*;


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
rv32i_word pc_out;
pcmux::pcmux_sel_t pcmux_sel; //based on the MEM stage br_en and control word

//ID stage
logic [2:0] funct3;
logic [6:0] funct7;
rv32i_opcode opcode;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_control_word ctrl_word;
rv32i_word ir_ID;
logic control_word_mux_sel;
logic nop_sel;
// logic btb_hit;
// logic flush_ID;
// logic [31:0] btb_mem_address_r;
// logic [31:0] btb_mem_address_w;
// logic [31:0] btb_wdata;
// logic btb_mem_read;
// logic btb_mem_write;
// logic [31:0] btb_rdata;

//EX stage
rv32i_word alu_out;
rv32i_word read_data1_EX;
rv32i_word read_data2_EX;
rv32i_word pc_EX;
logic br_en;
rv32i_control_word control_word_EX;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word pc_offset;
rv32i_word i_imm_EX;
rv32i_word s_imm_EX;
rv32i_word b_imm_EX;
rv32i_word u_imm_EX;
rv32i_word j_imm_EX;
rv32i_opcode opcode_EX;
readdatamux::readdatamux_sel_t forwardA;
readdatamux::readdatamux_sel_t forwardB;
rv32i_word read_data1_out;
rv32i_word read_data2_out;

//MEM stage
rv32i_word alu_out_MEM;
rv32i_word pc_MEM;
rv32i_word pc_offset_MEM;
rv32i_control_word control_word_MEM;
`ifdef NON_SYNTHESIS
// synthesis translate_off
rv32i_word read_data1_MEM; //only for rv32i monitor
// synthesis translate_on
`endif
rv32i_word read_data2_MEM;
logic br_en_MEM;
logic [3:0] rmask_MEM;
logic [3:0] wmask_MEM;

//WB stage
rv32i_word alu_out_WB;
rv32i_word data_out_WB;
rv32i_word pc_WB;
logic br_en_WB;
rv32i_control_word control_word_WB;
rv32i_word regfilemux_out;
logic [7:0] dm_mask_b;
logic [15:0] dm_mask_h;
rv32i_word dm_mask_w;
rv32i_word pc_offset_WB;
rv32i_word data_addrmux_out;
rv32i_word u_imm_WB;
`ifdef NON_SYNTHESIS
// synthesis translate_off
rv32i_word read_data1_WB; //only for rv32i monitor
rv32i_word read_data2_WB; //only for rv32i monitor
rv32i_word data_addr_WB;  //only for rv32i monitor
rv32i_word data_wdata_WB;  //only for rv32i monitor
rv32i_word pc_wdata;  //only for rv32i monitor
logic [3:0] wmask_WB;
// synthesis translate_on
`endif
logic [3:0] rmask_WB;

//LoadReg signals
logic loadReg;
logic data_ok;
logic data_rw;

//static branch
logic flush; //detects a flush, changes
rv32i_control_word nop;

//nop assignments
assign nop.alu_op = alu_add_beq;
assign nop.mem_read = 1'b0;
assign nop.mem_write = 1'b0;
assign nop.load_regfile = 1'b0;
assign nop.dest = 5'b0;
assign nop.trap = 1'b1;
assign nop.instr = 32'b0;
assign nop.regfile_mux_sel = regfilemux::alu_out;
assign nop.pc_mux_sel = pcmux::pc_plus4;
assign nop.alu_muxsel1 = alumux::rs1_out;
assign nop.alu_muxsel2 = alumux::i_imm;
assign nop.data_addrmux_sel = datamux::pc_out;
assign nop.rs1 = 3'b0;
assign nop.rs2 = 3'b0;

//need this for loadReg.
assign data_rw = data_read || data_write;
assign data_ok = (data_rw) ? ((data_resp) ? 1'b1 : 1'b0) : 1'b1;
assign loadReg = inst_resp && data_ok; //for stalling (makes sure that cahce is updated)

//assigned variables for EX stage 
assign i_imm_EX = {{21{control_word_EX.instr[31]}}, control_word_EX.instr[30:20]};
assign s_imm_EX = {{21{control_word_EX.instr[31]}}, control_word_EX.instr[30:25], control_word_EX.instr[11:7]};
assign b_imm_EX = {{20{control_word_EX.instr[31]}}, control_word_EX.instr[7], control_word_EX.instr[30:25], control_word_EX.instr[11:8], 1'b0};
assign u_imm_EX = {control_word_EX.instr[31:12], 12'h000};
assign j_imm_EX = {{12{control_word_EX.instr[31]}}, control_word_EX.instr[19:12], control_word_EX.instr[20], control_word_EX.instr[30:21], 1'b0};

//assigned variables for WB stage
assign u_imm_WB = {control_word_WB.instr[31:12], 12'h000};

//input/output assignments
assign data_read = control_word_MEM.mem_read;
assign data_write = control_word_MEM.mem_write;
assign inst_read = 1'b1;
assign inst_addr = pc_out;
assign data_addr = data_addrmux_out;
assign data_mbe = wmask_MEM;

//assigned variables for IF stage
assign funct3 = ir_ID[14:12];
assign funct7 = ir_ID[31:25];
assign opcode = rv32i_opcode'(ir_ID[6:0]);
assign opcode_EX = rv32i_opcode'(control_word_EX.instr[6:0]);
assign nop_sel = flush||control_word_mux_sel;

/********************************Control Unit********************************/
control_unit Control_Unit( //incldue instruction
    .instr(ir_ID),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .addr_01(pc_offset_MEM[1:0]),
    .ctrl_word(ctrl_word)
);
/****************************************************************************/

/********************************Regfile*************************************/
regfile regfile(
    .clk(clk),
    .rst(rst),
    .load(control_word_WB.load_regfile),
    .in(regfilemux_out),
    .src_a(ctrl_word.rs1), .src_b(ctrl_word.rs2), .dest(control_word_WB.dest),
    .reg_a(rs1_out), .reg_b(rs2_out)
);
/****************************************************************************/

/********************************Registers***********************************/
//Other registers
//pcreg
pc_register pc(
    .clk(clk),
    .rst(rst),
    .load(loadReg && !control_word_mux_sel),
    .in(pcmux_out),
    .out(pc_out)
);

//5 stage registers
//IF/ID
register pc_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(loadReg && !control_word_mux_sel),
    .in(pc_out),
    .out(pc_ID)
);

register ir_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(loadReg && !control_word_mux_sel),
    //.in(((flush||flush_ID) ? 32'b0 : inst_rdata)),
    .in(((flush) ? 32'b0 : inst_rdata)),
    .out(ir_ID)
);

//register

//ID/EX
register #(`CONTROL_WORD_SIZE) control_word_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in((nop_sel ? nop : ctrl_word)),
    .out(control_word_EX)
); 

register pc_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(pc_ID),
    .out(pc_EX)
);

register read_data1_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(rs1_out),
    .out(read_data1_EX)
);

register read_data2_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(rs2_out),
    .out(read_data2_EX)
);

//EX/MEM
register #(`CONTROL_WORD_SIZE) control_word_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in((flush ? nop : control_word_EX)),
    .out(control_word_MEM)
); 

register pc_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(pc_EX),
    .out(pc_MEM)
);

register #(1) br_en_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(br_en),
    .out(br_en_MEM)
);

register pc_offset_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(pc_offset),
    .out(pc_offset_MEM)
);

`ifdef NON_SYNTHESIS
// synthesis translate_off
register read_data1_EX_MEM(     //only for rv32i monitor
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(read_data1_out),
    .out(read_data1_MEM)
);
// synthesis translate_on
`endif

register read_data2_EX_MEM(  
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(read_data2_out),
    .out(read_data2_MEM)
);

register ALUout_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(alu_out),
    .out(alu_out_MEM)
);

//MEM/WB
register #(`CONTROL_WORD_SIZE) control_word_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(control_word_MEM),
    .out(control_word_WB)
); 

register #(1) br_en_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(br_en_MEM),
    .out(br_en_WB)
); 

register pc_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(pc_MEM),
    .out(pc_WB)
);

register pc_offset_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(pc_offset_MEM),
    .out(pc_offset_WB)
);

register data_out_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(data_rdata),
    .out(data_out_WB)
);

register alu_out_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(alu_out_MEM),
    .out(alu_out_WB)
);

`ifdef NON_SYNTHESIS
// synthesis translate_off
register read_data1_MEM_WB(     //only for rv32i monitor
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(read_data1_MEM),
    .out(read_data1_WB)
);

register read_data2_MEM_WB(     //only for rv32i monitor
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(read_data2_MEM),
    .out(read_data2_WB)
);

register data_addr_MEM_WB(      //only for rv32i monitor  
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(data_addrmux_out),
    .out(data_addr_WB)
);

register data_wdata_MEM_WB(   //only for rv32i monitor 
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(data_wdata),
    .out(data_wdata_WB)
);


register #(4) rmask_MEM_WB(   //only for rv32i monitor 
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(rmask_MEM),
    .out(rmask_WB)
);


register #(4) wmask_MEM_WB(   //only for rv32i monitor 
    .clk(clk),
    .rst(rst),
    .load(loadReg),
    .in(wmask_MEM),
    .out(wmask_WB)
);
// synthesis translate_on
`endif

/****************************************************************************/

/*******************************ALU and CMP in one module********************/
alu ALU(
    .aluop(control_word_EX.alu_op), //controls the operation of the ALU
    .a(alumux1_out), //this is the output of the mux for input 1 of ALU
    .b(alumux2_out), //this is the output of the mux for input 2 of ALU
    .f(alu_out), //output of the ALU
    .z(br_en) //br_en output 
);
/*****************************************************************************/

/*******************************Other modules*********************************/
//masking for the WB stage for regfile mux
load_masking data_mem_masking(
    .rmask(rmask_WB),
    .mdrreg_out(data_out_WB),
    .mdr_mask_h(dm_mask_h),
    .mdr_mask_b(dm_mask_b),
    .mdr_mask_w(dm_mask_w)
);

//masking for store
sshifter storeshifter(
    .wmask(wmask_MEM),
    .rs2_out(read_data2_MEM),
    .mem_data_out_in(data_wdata)
);
/***************************forwarding unit and hazard detection*******************/
fowarding_unit forwarding_unit(
    .control_word_EX(control_word_EX),
    .control_word_MEM(control_word_MEM),
    .control_word_WB(control_word_WB),
    .forwardA(forwardA),
    .forwardB(forwardB)
);

hazard_detect_unit hazard_detect(
    .control_word_ID((flush ? nop : ctrl_word)),
    .control_word_EX(control_word_EX),
    .control_word_mux_sel(control_word_mux_sel)
);


// branch_predictor #(3) branch_predict(
//     .clk(clk),
//     .rst(rst),
//     .pc_ID(pc_ID),
//     .pc_offset_MEM(pc_offset_MEM),
//     .opcode_ID(opcode),
//     .control_word_MEM(control_word_MEM),
//     .br_en_MEM(br_en_MEM),
//     .btb_hit(btb_hit),
//     .pcmux_sel(pcmux_sel),
//     .flush(flush),
//     .flush_ID(flush_ID),
//     .btb_mem_address_r(btb_mem_address_r),
//     .btb_mem_address_w(btb_mem_address_w),
//     .btb_wdata(btb_wdata),
//     .btb_mem_read(btb_mem_read),
//     .btb_mem_write(btb_mem_write),
//     .pc_MEM(pc_MEM)
// );

// btb branch_target_buffer(
//     .clk(clk), 
//     .rst(rst), 

//     //to/from smaller cache
//     .mem_address_r(btb_mem_address_r),
//     .mem_address_w(btb_mem_address_w),
//     .mem_read(btb_mem_read),
//     .mem_write(btb_mem_write),
//     .mem_rdata(btb_rdata), 
//     .mem_wdata(btb_wdata),
//     .hit(btb_hit)
// );

rsmask rsmask(
    .addr_01(alu_out_MEM[1:0]),
    .funct3(control_word_MEM.instr[14:12]),
    .opcode(control_word_MEM.instr[6:0]),
    .rmask(rmask_MEM),
    .wmask(wmask_MEM)
);
/****************************************************************************/



//pcmux_sel branch detection
always_comb begin : PC_MUX
    if((control_word_MEM.pc_mux_sel == pcmux::alu_out) & (br_en_MEM || control_word_MEM.instr[6:0] == 7'h6f)) begin
        pcmux_sel = pcmux::alu_out;
        flush = 1'b1;
    end
    else if((control_word_MEM.pc_mux_sel == pcmux::alu_mod2) & (br_en_MEM || control_word_MEM.instr[6:0] == 7'h67)) begin
        pcmux_sel = pcmux::alu_mod2;
        flush = 1'b1;
    end
    else begin
        pcmux_sel = pcmux::pc_plus4;
        flush = 1'b0;
    end
end

/*****************************************************************************/

/*********************************Muxes***************************************/
always_comb begin : MUXES
    //IF stage
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out:  pcmux_out = pc_offset_MEM;
        pcmux::alu_mod2:  pcmux_out = {alu_out_MEM[31:1],1'b0};
        //pcmux::btb_out:    pcmux_out = btb_rdata;
        // pcmux::pc_mem_plus4:  pcmux_out = pc_MEM +4;
        default: pcmux_out = pc_out;
    endcase

    //WB stage
    unique case (control_word_WB.regfile_mux_sel)
        regfilemux::alu_out:    regfilemux_out = alu_out_WB;
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
        default: regfilemux_out = alu_out_WB;
    endcase

    unique case (control_word_MEM.data_addrmux_sel)
        datamux::pc_out:    data_addrmux_out = pc_MEM;
        datamux::alu_out:  data_addrmux_out = alu_out_MEM;
        default: data_addrmux_out = pc_MEM;
    endcase

    unique case (opcode_EX)
        op_br:     pc_offset = pc_EX + b_imm_EX; 
        op_jal:    pc_offset = pc_EX + j_imm_EX;
        op_jalr:   pc_offset = pc_EX + j_imm_EX; 
        default:   pc_offset = pc_EX + b_imm_EX;
    endcase

    //EX stage
    unique case(forwardA)
        readdatamux::alu_out_MEM:  read_data1_out = alu_out_MEM;
        readdatamux::regfile_WB:  read_data1_out = regfilemux_out;
        readdatamux::read_data:  read_data1_out = read_data1_EX;

        default: read_data1_out = read_data1_EX;    
    endcase


    unique case(forwardB)
        readdatamux::alu_out_MEM:  read_data2_out = alu_out_MEM;
        readdatamux::regfile_WB:  read_data2_out = regfilemux_out;
        readdatamux::read_data:  read_data2_out = read_data2_EX;

        default: read_data2_out = read_data2_EX;    
    endcase

    unique case (control_word_EX.alu_muxsel1)
        alumux::rs1_out:  alumux1_out = read_data1_out;
        alumux::pc_out:   alumux1_out = pc_EX;
        default: alumux1_out = read_data1_out;
    endcase

    unique case (control_word_EX.alu_muxsel2)
        alumux::i_imm: alumux2_out = i_imm_EX;  
        alumux::u_imm: alumux2_out = u_imm_EX;
        alumux::b_imm: alumux2_out = b_imm_EX;
        alumux::s_imm: alumux2_out = s_imm_EX;
        alumux::j_imm: alumux2_out = j_imm_EX;
        alumux::rs2_out: alumux2_out = read_data2_out;
        default: alumux2_out = i_imm_EX;
    endcase

    `ifdef NON_SYNTHESIS
    // synthesis translate_off
    unique case(rv32i_opcode'(control_word_WB.instr[6:0])) //only for rv32i monitor 
        op_br: begin
                if(br_en_WB==1'b1)
                    pc_wdata = pc_offset_WB;
                else
                    pc_wdata = pc_WB+4;
                end
        op_jal: pc_wdata = pc_offset_WB;
        op_jalr: pc_wdata = {alu_out_WB[31:1],1'b0};
        default: pc_wdata = pc_WB +4;
    endcase

    // synthesis translate_on
    `endif

end
/*****************************************************************************/



endmodule: datapath
