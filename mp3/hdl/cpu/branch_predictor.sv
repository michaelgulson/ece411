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
    input logic btb_resp,

    //output predict_address BTB
    output logic branch_taken,
    output pcmux_sel_t [1:0] pcmux_sel
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

always_comb begin
    if(btb_resp && btb_hit && branch_taken && is_curr_branch)begin
        pcmux_sel = pcmux::btb_out;    
        //flush = 1'b1???
    end
    else if((control_word_MEM.pc_mux_sel == pcmux::alu_out) & (br_en_MEM || control_word_MEM.instr[6:0] == 7'h6f)) begin
        pcmux_sel = pcmux::alu_out;
        flush = 1'b1;
    end
    else if((control_word_MEM.pc_mux_sel == pcmux::alu_mod2) & (br_en_MEM || control_word_MEM.instr[6:0] == 7'h67)) begin
        pcmux_sel = pcmux::alu_mod2;
        flush = 1'b1;
    end
    else begin
        pcmux_sel = pcmux::pc_plus4;
        flush = 1'b0;
    end       
end


endmodule