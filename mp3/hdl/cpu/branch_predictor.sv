import rv32i_types::*;

module branch_predictor #(
    parameter n  // size of BHT and PHT

)(
    input logic clk,
    input logic rst,
    input logic is_curr_branch,
    input logic is_prev_branch,
    input rv32i_word instruction,
    input logic prev_branch_taken,
    input logic btb_hit,

    //output predict_address BTB
    output logic branch_taken,
    output logic [1:0] pcmux_sel
);

logic [n-1:0] branch_hist_reg;
logic [n-1:0] branch_hist_reg_next;
logic [1:0] pht_out;

assign branch_taken = pht_out / 2;
assign branch_hist_reg_next = (branch_hist_reg << 1) | prev_branch_taken;


register #(n) bhr_reg(
    .load(is_prev_branch),
    .in(branch_hist_reg_next),
    .out(branch_hist_reg),
    .*
);


predict_hist_tbl #(n) pht(
    .is_prev_branch(is_prev_branch),
    .prev_branch_taken(prev_branch_taken),
    .bhr(branch_hist_reg),
    .pht_out(pht_out),
    .*
);

endmodule