import rv32i_types::*;


module fowarding_unit
(
    input rv32i_control_word control_word_EX,
    input rv32i_control_word control_word_MEM,
    input rv32i_control_word control_word_WB,


    output [1:0] forwardA,
    output [3:0] forwardB
);

logic [4:0] dest_MEM;
logic [4:0] dest_WB;
logic load_regfile_MEM;
logic load_regfile_WB;
logic [4:0] rs1_EX;
logic [4:0] rs2_EX;
alumux::alumux1_sel_t alu_muxsel1_EX;
alumux::alumux2_sel_t alu_muxsel2_EX;

assign dest_MEM = control_word_MEM.dest;
assign dest_WB = control_word_WB.dest;
assign load_regfile_MEM = control_word_MEM.load_regfile;
assign load_regfile_WB = control_word_WB.load_regfile;
assign rs1_EX = control_word_EX.instr[19:15];
assign rs2_EX = control_word_EX.instr[24:20];
assign alumuxsel1_EX = control_word_EX.alu_muxsel1;
assign alumuxsel2_EX = control_word_EX.alu_muxsel2;


always_comb begin
    if(load_regfile_MEM && dest_MEM!=0 && dest_MEM == rs1_EX)begin
        forwardA = 2'b10;
    end
    else if(load_regfile_WB && dest_WB!=0 && dest_WB == rs1_EX)begin
        forwardA = 2'b11;
    end
    else begin
        forwardA = {1'b0,alumuxsel1_EX};
    end

    if(load_regfile_MEM && dest_MEM!=0 && dest_MEM == rs2_EX)begin
        forwardB = 4'b1000;
    end
    else if(load_regfile_WB && dest_WB!=0 && dest_WB == rs2_EX)begin
        forwardB = 4'b1001;
    end
    else begin
        forwardB = {1'b0,alumuxsel2_EX};
    end
    end
endmodule