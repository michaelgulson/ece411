module control_unit
(
    input rv32i_opcode opcode,
    input logic[2:0] fucnt3,
    input logic[6:0] funct7,
    output rv32i_control_word 

);
