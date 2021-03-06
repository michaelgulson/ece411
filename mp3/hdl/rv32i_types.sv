package rv32i_types;
// Mux types are in their own packages to prevent identiier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import datamux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;
import readdatamux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add_beq = 3'b000,
    alu_sll_bne = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor_blt = 3'b100,
    alu_srl_bge = 3'b101,
    alu_or_bltu  = 3'b110,
    alu_and_bgeu = 3'b111
} alu_ops;

typedef struct packed {
    alu_ops alu_op;
    logic mem_read;
    logic mem_write;
    logic load_regfile;
    logic [4:0] dest;
    logic trap; //for branching
    rv32i_word instr;
    logic [4:0] rs1; //source registers from regfile
    logic [4:0] rs2; //source registers from regfile

    //muxes
    regfilemux::regfilemux_sel_t    regfile_mux_sel;
    pcmux::pcmux_sel_t              pc_mux_sel;
    alumux::alumux1_sel_t           alu_muxsel1;
    alumux::alumux2_sel_t           alu_muxsel2;
    datamux::addrmux_sel_t          data_addrmux_sel;
} rv32i_control_word;


endpackage : rv32i_types