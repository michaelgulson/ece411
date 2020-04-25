import rv32i_types::*;

module branch_predictor #(
    parameter n  // size of BHT and PHT

)(
    input logic clk,
    input logic rst,

    input rv32i_control_word control_word_MEM,
    input rv32i_opcode opcode_ID,
    input logic prev_branch_taken,
    input logic btb_hit,
    input logic btb_resp,

    //output predict_address BTB
    //output logic branch_taken,
    output pcmux_sel_t [1:0] pcmux_sel
);

logic [n-1:0] branch_hist_reg;
logic [n-1:0] branch_hist_reg_next;
logic [1:0] pht_out;
pcmux_sel_t pcmux_sel_old;
logic flush_old;
logic is_curr_branch;
logic is_prev_branch;
logic pred_branch_taken_reg_out;

assign is_curr_branch = opcode_ID == op_br || opcode_ID == op_jal || opcode_ID == op_jalr;
assign is_prev_branch = control_word_MEM.instr[6:0] == 7'h6f || control_word_MEM.instr[6:0] == 7'h67 || control_word_MEM.instr[6:0] == 7'h63;

assign pred_branch_taken = pht_out / 2;
assign branch_hist_reg_next = (branch_hist_reg << 1) | prev_branch_taken;



register #(n) bhr_reg(
    .load(is_prev_branch),
    .in(branch_hist_reg_next),
    .out(branch_hist_reg),
    .*
);

register #(1) pred_branch_taken_reg(
    .load(is_curr_branch),
    .in(pred_branch_taken && btb_hit && btb_resp),
    .out(pred_branch_taken_reg_out),
    .*
);


predict_hist_tbl #(n) pht(
    .is_prev_branch(is_prev_branch),
    .prev_branch_taken(prev_branch_taken),
    .bhr(branch_hist_reg),
    .pht_out(pht_out),
    .*
);


//pcmuxsel and flush logic from datapath before branch prediction
always_comb begin
    if((control_word_MEM.pc_mux_sel == pcmux::alu_out) && (br_en_MEM || control_word_MEM.instr[6:0] == 7'h6f)) begin
        pcmux_sel_old = pcmux::alu_out;
        flush_old = 1'b1;
    end
    else if((control_word_MEM.pc_mux_sel == pcmux::alu_mod2) && (br_en_MEM || control_word_MEM.instr[6:0] == 7'h67)) begin
        pcmux_sel_old = pcmux::alu_mod2;
        flush_old = 1'b1;
    end
    else begin
        pcmux_sel_old = pcmux::pc_plus4;
        flush_old = 1'b0;
    end       
end

always_comb begin  //what happens if we're predicting a branch at the same time we're resolving a previous branch???  resolving should have priority right?
    if(is_prev_branch && pred_branch_taken_reg_out && prev_branch_taken) begin
        pcmux_sel = pcmux::pc_plus4;
        flush = 1'b0;
    end
    else if
    
    
    if(pred_branch_taken && btb_hit && btb_resp && is_curr_branch) //pred branch taken, what if curr_branch




end

endmodule
