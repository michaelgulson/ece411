
module cache_cmp(
    input [23:0] a,
    input [23:0] b,
    output logic out
);


always_comb
begin
            if(a == b)begin
               out = 1'b1;
            end
            else begin
                out = 1'b0;
            end

end
endmodule