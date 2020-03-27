
import rv32i_types::*;

module load_masking(
    input logic [3:0] rmask,
    input rv32i_word mdrreg_out,
    output logic [15:0] mdr_mask_h,
    output logic [7:0] mdr_mask_b,
    output rv32i_word mdr_mask_w
);

always_comb
begin
    mdr_mask_h = 16'd0;
    mdr_mask_b = 8'd0;
    mdr_mask_w = 32'd0;
    case(rmask)
        4'b1111: mdr_mask_w = mdrreg_out;
        4'b0011: mdr_mask_h = mdrreg_out[15:0];
        4'b1100: mdr_mask_h = mdrreg_out[31:16];
        4'b0001: mdr_mask_b = mdrreg_out[7:0];
        4'b0010: mdr_mask_b = mdrreg_out[15:8];
        4'b0100: mdr_mask_b = mdrreg_out[23:16];
        4'b1000: mdr_mask_b = mdrreg_out[31:24];
        default: begin
                mdr_mask_h = 16'd0;
                mdr_mask_b = 8'd0;
                mdr_mask_w = 32'd0;
                end
    endcase
end
endmodule