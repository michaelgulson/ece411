import rv32i_types::*;


module sshifter(
    input logic [3:0]  wmask,
    input rv32i_word rs2_out,
    output rv32i_word mem_data_out_in
);


always_comb
begin
    case(wmask)
        4'b1111: mem_data_out_in = rs2_out;   
        4'b0011: mem_data_out_in = rs2_out;
        4'b0001: mem_data_out_in = rs2_out;
        4'b0010: mem_data_out_in = rs2_out << 8;
        4'b0100: mem_data_out_in = rs2_out << 16;
        4'b1000: mem_data_out_in = rs2_out << 24;
        4'b1100: mem_data_out_in = rs2_out << 16;
        default: mem_data_out_in = rs2_out;
    endcase
end

endmodule