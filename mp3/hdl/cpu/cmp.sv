import rv32i_types::*;

module cmp(
    input branch_funct3_t cmpop,
    input rv32i_word rs1_out,
    input rv32i_word cmp_mux_out,
    output logic br_en
);

always_comb
begin 
    unique case (cmpop)
        beq: br_en = rs1_out == cmp_mux_out;
        bne: br_en = !(rs1_out == cmp_mux_out);
        blt: br_en = $signed(rs1_out) < $signed(cmp_mux_out);
        bltu: br_en = rs1_out < cmp_mux_out;
        bge: br_en = $signed(rs1_out) >= $signed(cmp_mux_out);
        bgeu: br_en = rs1_out >= cmp_mux_out;
        default: br_en = 1'b0;
    endcase
end

endmodule : cmp