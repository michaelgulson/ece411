import rv32i_types::*;


module fowarding_unit
(
    input rv32i_control_word control_word_EX,
    input rv32i_control_word control_word_MEM,
    input rv32i_control_word control_word_WB,


    output alumux::alumux1_sel_t forwardA,
    output alumux::alumux2_sel_t forwardB
);

logic [4:0] dest_MEM;
logic [4:0] dest_WB;
logic load_regfile_MEM;
logic load_regfile_WB;
logic [4:0] rs1_EX;
logic [4:0] rs2_EX;
logic [6:0] opcode_EX;

assign dest_MEM = control_word_MEM.dest;
assign dest_WB = control_word_WB.dest;
assign load_regfile_MEM = control_word_MEM.load_regfile;
assign load_regfile_WB = control_word_WB.load_regfile;
assign rs1_EX = control_word_EX.instr[19:15];
assign rs2_EX = control_word_EX.instr[24:20];
assign opcode_EX = control_word_EX.instr[6:0];

always_comb begin
    if(!((opcode_EX == op_lui) || (opcode_EX == op_auipc) || (opcode_EX == op_jal))) begin
        if(load_regfile_MEM && dest_MEM!=0 && dest_MEM == rs1_EX)begin
            forwardA = alumux::alu_out_MEM1;
        end
        else if(load_regfile_WB && dest_WB!=0 && dest_WB == rs1_EX)begin
            forwardA = alumux::regfile_WB1;
        end
        else begin
            forwardA = control_word_EX.alu_muxsel1;
        end
    end
    else begin
        forwardA = control_word_EX.alu_muxsel1;
    end

    if((opcode_EX == op_reg)||(opcode_EX == op_store)||(opcode_EX == op_br)) begin
        if(load_regfile_MEM && dest_MEM!=0 && dest_MEM == rs2_EX)begin
            forwardB = alumux::alu_out_MEM2;
        end
        else if(load_regfile_WB && dest_WB!=0 && dest_WB == rs2_EX)begin
            forwardB = alumux::regfile_WB2;
        end
        else begin
            forwardB = control_word_EX.alu_muxsel2;
        end
    end
    else begin
        forwardB = control_word_EX.alu_muxsel2;
    end
end
endmodule