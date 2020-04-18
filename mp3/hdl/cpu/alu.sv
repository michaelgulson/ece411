import rv32i_types::*;

module alu
(
    input alu_ops aluop,
    input [31:0] a, b,
    output logic [31:0] f,
    output logic z
);

always_comb begin
    unique case (aluop)
        alu_add_beq: begin 
            f = a + b;
            z = (a == b);
        end
        alu_sll_bne: begin 
            f = a << b[4:0];
            z = !(a == b);
        end
        alu_sra: begin
            f = $signed(a) >>> b[4:0];
            z = 0;
        end
        alu_sub: begin
            f = a - b;
            z = 0;
        end
        alu_xor_blt: begin
            f = a ^ b;
            z = $signed(a) < $signed(b);
        end
        alu_srl_bge: begin
            f = a >> b[4:0];
            z = $signed(a) >= $signed(b);
        end
        alu_or_bltu: begin
            f = a | b;
            z = a < b;
        end
        alu_and_bgeu: begin
            f = a & b;
            z = a >= b;
        end
    endcase
end

endmodule : alu
