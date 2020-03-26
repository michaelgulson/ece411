import rv32i_types::*;
import control_word_types::*;

module datapath
{
    input clk,
    input rst,

    input rv32i_word i_mem_rdata,
    output rv32i_word i_mem_wdata, // signal used by RVFI Monitor
    output rv32i_word i_mem_address,
    output i_mem_read,
    output i_mem_write, 

    input rv32i_word d_mem_rdata,
    output rv32i_word d_mem_wdata, // signal used by RVFI Monitor
    output rv32i_word d_mem_address,
    output d_mem_read,
    output d_mem_write,

    output [3:0] mem_byte_en

};

rv32i_word pc_plus4;
logic true;

assign true = 1'b1;
/********************************Control Unit********************************/



/****************************************************************************/




/********************************Registers***********************************/
//Other registers
//pcreg

//5 stage registers
//IF/ID
register pc_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_plus4),
    .out(pc_IF_ID_out)
);

register ir_IF_ID(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(i_mem_rdata),
    .out(ir_IF_ID_out)
); 

//ID/EX

register #(CONTROL_WORD_SIZE) control_word_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(control_unit_out),
    .out(control_word_EX)
); 

register pc_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_plus4),
    .out(pc_ID_EX_out)
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

register #(IMM_SIZE) imm_ID_EX(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(imm),
    .out(imm_EX)
);

//EX/MEM
register #(CONTROL_WORD_SIZE) control_word_EX_MEM(
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
    .in(pc_EX),
    .out(pc_MEM)
);

register read_data2_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(read_data2_EX),
    .out(read_data2_MEM)
);

register imm_EX_MEM(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(imm_EX),
    .out(imm_MEM)
);

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
    .out(control_word_EX)
); 

register br_en_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(br_en_MEM),
    .out(br_en_WB)
); 

register pc_offset_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(pc_MEM),
    .out(pc_WB)
);

register data_out_MEM_WB(
   .clk(clk),
    .rst(rst),
    .load(true),
    .in(data_out),
    .out(data_out_WB)
);

register alu_out_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(alu_out),
    .out(aluout_WB)
);

register imm_MEM_WB(
    .clk(clk),
    .rst(rst),
    .load(true),
    .in(imm_MEM),
    .out(imm_WB)
);


/****************************************************************************/



/*******************************ALU and CMP in one module********************/
alu ALU(
    .aluop(aluop), //controls the operation of the ALU
    .a(alu_mux1_out), //this is the output of the mux for input 1 of ALU
    .b(alu_mux2_out), //this is the output of the mux for input 2 of ALU
    .f(alu_out) //output of the ALU
    .z(br_en) //br_en output 
);
/*****************************************************************************/


/*********************************Muxes***************************************/



/*****************************************************************************/