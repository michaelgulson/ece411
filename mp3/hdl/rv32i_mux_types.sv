package pcmux;
typedef enum bit [1:0] {
    pc_plus4  = 3'b000
    ,alu_out  = 3'b001
    ,alu_mod2 = 3'b010
    ,btb_out = 3'b011
    ,pc_mem_plus4 = 3'b100;
} pcmux_sel_t;
endpackage

package datamux;
typedef enum bit {
    pc_out = 1'b0
    ,alu_out = 1'b1
} addrmux_sel_t;
endpackage

package cmpmux;
typedef enum bit {
    rs2_out = 1'b0
    ,i_imm = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum bit [1:0]{
    rs1_out = 2'b00
    ,pc_out = 2'b01
    ,alu_out_MEM1 = 2'b10
    ,regfile_WB1 = 2'b11
} alumux1_sel_t;

typedef enum bit [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_out = 3'b101
    ,alu_out_MEM2 = 3'b110
    ,regfile_WB2 = 3'b111
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum bit [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage