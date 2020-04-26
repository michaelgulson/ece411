import rv32i_types::*;

module branch_predictor #(
    parameter n// size of BHT and PHT

)(
    input logic clk,
    input logic rst,
    input rv32i_word pc_ID,
    input rv32i_word pc_offset_MEM,
    input rv32i_control_word control_word_MEM,
    input rv32i_opcode opcode_ID,
    //input logic prev_branch_taken,
    input logic btb_hit,
    input logic br_en_MEM,
    //input logic btb_resp,

    //output predict_address BTB
    //output logic branch_taken,
    output btb_mem_address_r,
    output btb_mem_address_w,
    output rv32i_word btb_wdata,
    output logic btb_mem_read,
    output logic btb_mem_write,
    output logic flush,
    output logic flush_ID,
    output pcmux::pcmux_sel_t pcmux_sel
);

logic [n-1:0] branch_hist_reg;
logic [n-1:0] branch_hist_reg_next;
logic [1:0] pht_out;
pcmux::pcmux_sel_t pcmux_sel_old;
logic flush_old;
logic is_curr_branch;
logic is_prev_branch;
logic pred_branch_taken_reg_out;
logic prev_branch_taken;
logic confirmation;
logic pred_branch_taken;
logic prev_pred_branch_taken;

assign is_curr_branch = opcode_ID == op_br || opcode_ID == op_jal || opcode_ID == op_jalr;
assign is_prev_branch = control_word_MEM.instr[6:0] == 7'h6f || control_word_MEM.instr[6:0] == 7'h67 || control_word_MEM.instr[6:0] == 7'h63;

assign pred_branch_taken = pht_out[1];
assign branch_hist_reg_next = (branch_hist_reg << 1) | prev_branch_taken;
assign prev_branch_taken = ((control_word_MEM.pc_mux_sel == pcmux::alu_out)&&(br_en_MEM))||(control_word_MEM.instr[6:0] == 7'h6f || control_word_MEM.instr[6:0] == 7'h67);
assign confirmation = pc_ID == pc_offset_MEM;
assign btb_wdata = pc_offset_MEM;
assign btb_mem_address_w = pc_MEM;
assign btb_mem_address_r = pc_ID;

register #(n) bhr_reg(
    .load(is_prev_branch),
    .in(branch_hist_reg_next),
    .out(branch_hist_reg),
    .*
);

register #(1) pred_branch_taken_reg(
    .load(is_curr_branch),
    .in(pred_branch_taken && btb_hit),
    .out(prev_pred_branch_taken),
    .*
);

/*
register #(32) btb_target_address(
    .load(is_curr_branch && btb_hit && btb_resp),
    .in(btb_rdata),
    .out(btb_target_address),
    .*
)*/


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

function void set_defaults();
    pcmux_sel = pcmux_sel_old;
    flush_ID = 1'b0;
    flush = 1'b0;
    btb_mem_read = 1'b0;
    btb_mem_write = 1'b0;
endfunction

always_comb begin 
    set_defaults();

    if(is_prev_branch && prev_pred_branch_taken && prev_branch_taken && confirmation) begin //we predicted taken and previous branch taken
        if(is_curr_branch && pred_branch_taken && btb_hit) begin
            pcmux_sel = pcmux::btb_out;
            flush_ID = 1'b1;
            flush = 1'b0;
            btb_mem_read = 1'b1;
            btb_mem_write = 1'b1;
        end
        else begin
            pcmux_sel = pcmux::pc_plus4;
            flush = 1'b0;
            flush_ID = 1'b0;
            btb_mem_write = 1'b1;
        end
    end
    else if(is_prev_branch && prev_pred_branch_taken && (!(confirmation && prev_branch_taken))) begin //we predicted taken and previous branch not taken
        if(prev_branch_taken)begin
            btb_mem_write = 1'b1;
        end        
        pcmux_sel = pcmux::pc_mem_plus4;
        flush = 1'b1;
        flush_ID = 1'b0;
    end
    else if(is_prev_branch && prev_branch_taken)begin //we predicted branch not taken and branch taken
        pcmux_sel = pcmux_sel_old;
        flush = flush_old;
        flush_ID = 1'b0;
        btb_mem_write = 1'b1;
    end
    else if(is_prev_branch && !prev_branch_takne)begin //we predicted branch not taken and branch not taken
        if(is_curr_branch && pred_branch_taken && btb_hit) begin
            pcmux_sel = pcmux::btb_out;
            flush_ID = 1'b1;
            flush = 1'b0;
            btb_mem_read = 1'b1;
        end
        else begin
            pcmux_sel = pcmux_sel_old;
            flush = flush_old;
            flush_ID = 1'b0;
        end
    end

    else if(pred_branch_taken && btb_hit && is_curr_branch) begin //pred branch taken
        pcmux_sel = pcmux::btb_out;
        flush = 1'b0;
        flush_ID = 1'b1;
        btb_mem_read = 1'b1;
    end
    else begin //else
        pcmux_sel = pcmux_sel_old;
        flush = flush_old;
        flush_ID = 1'b0;
    end

end

endmodule
