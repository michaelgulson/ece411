module arbiter_datapath #(
    parameter s_line = 256
)
(
    input logic load_i,
    input logic load_d,

    //i cache
    input logic [31:0] mem_addr_i,
    input logic [s_line-1:0] inst_wdata,
    output logic [s_line-1:0] inst_rdata,

    //d cache
    input logic [31:0] mem_addr_d,
    input logic [s_line-1:0] data_wdata,
    output logic [s_line-1:0] data_rdata,

    //l2 cache
    input  logic [s_line-1:0] pmem_rdata,
    output logic [s_line-1:0] pmem_wdata,
    output logic [31:0] pmem_addr
);

always_comb
begin
    inst_rdata = {s_line{1'b0}};
    data_rdata = {s_line{1'b0}};
    pmem_wdata = {s_line{1'b0}};
    pmem_addr = {32{1'b0}};
    unique case({load_i,load_d})
        2'b10: //i cache
        begin
            pmem_addr = mem_addr_i;
            pmem_wdata = inst_wdata;
            inst_rdata = pmem_rdata;
        end
        2'b01: //d cache
        begin
            pmem_addr = mem_addr_d;
            pmem_wdata = data_wdata;
            data_rdata = pmem_rdata;
        end
        default: 
        begin
            inst_rdata = {s_line{1'b0}};
            data_rdata = {s_line{1'b0}};
            pmem_wdata = {s_line{1'b0}};
            pmem_addr = {32{1'b0}};
        end
    endcase
end

endmodule: arbiter_datapath

