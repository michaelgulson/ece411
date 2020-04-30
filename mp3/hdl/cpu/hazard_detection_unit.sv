import rv32i_types::*;

module hazard_detect_unit(
    input rv32i_control_word control_word_EX,
    input rv32i_control_word control_word_ID,

    output logic control_word_mux_sel
);

logic [4:0] rs1_ID;
logic [4:0] rs2_ID;

assign rs1_ID = control_word_ID.instr[19:15];
assign rs2_ID = control_word_ID.instr[24:20];

always_comb begin
    if(control_word_EX.mem_read && ((control_word_EX.dest == rs1_ID) || (control_word_EX.dest == rs2_ID)||(control_word_EX.dest == control_word_ID.dest)))
        control_word_mux_sel = 1'b1;
    else if(control_word_EX.instr[6:0] == op_lui && ((control_word_EX.dest == rs1_ID)))
        control_word_mux_sel = 1'b1;
    else
        control_word_mux_sel = 1'b0;
end


endmodule