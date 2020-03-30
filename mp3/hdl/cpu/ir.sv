import rv32i_types::*;

module ir
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    output [2:0] funct3,
    output [6:0] funct7,
    output rv32i_opcode opcode,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd
);

logic [31:0] data;

assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];

//why "=" instead of "<="
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load == 1)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

endmodule : ir
