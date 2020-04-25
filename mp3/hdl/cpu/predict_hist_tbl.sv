module predict_hist_tbl #(parameter n)
(
    input is_prev_branch,
    input prev_branch_taken,
    input [n-1:0] bhr,
    output [1:0] pht_out;
);


logic [2**n-1:0] pht [1:0];
logic [1:0] pht_out;
logic [1:0] cnt_input;

always_comb begin
    if(prev_branch_taken) begin
        if(pht[bhr] == 2'b11) begin
            cnt_input = 2'b11;
        end
        else begin
            cnt_input = pht[bhr] +1;
        end
    end
    else begin
        if(pht[bhr]==2'b00)begin
            cnt_input = 2'b00;
        end
        else begin
            cnt_input = pht[bhr] -1;
        end
    end
end


always_ff @(posedge clk) begin
    if(rst) begin
        for (int i =0;i<n ;i++ ) begin
            pht[i] <= 2'b00; 
        end
        cnt_input = 2'b00;
    end
    else begin 
        if(is_prev_branch) begin
            pht[bhr] <= cnt_input;
        end
    end
    pht_out <= pht[bhr];
end