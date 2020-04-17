import rv32i_types::*;

module hazard_detect_unit(
    input control_word_EX,
    input control_word_ID,

    output control_word_mux_sel
);

assign rs1_ID = control_word_ID.instr[19:15];
assign rs2_ID = control_word_ID.instr[24:20];

always_comb begin
    if(control_word_EX.mem_read && ((control_word_EX.dest == rs1_ID)|| (control_word_EX.dest == rs2_ID)))
        control_word_mux_sel = 1'b1;
    else
        control_word_mux_sel = 1'b0;
end


endmodule