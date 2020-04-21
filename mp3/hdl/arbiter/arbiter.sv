module arbiter #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask
)(
    input logic clk,
    input logic rst,
    input logic mem_read_i, 
    input logic mem_read_d,
    input logic mem_write_d,
    input logic pmem_resp, 
    input logic [s_line-1:0] pmem_rdata,
    input logic [31:0] mem_addr_i,
    input logic [31:0] mem_addr_d,

    output logic pmem_read,
    output logic pmem_write,
    output logic mem_resp_i,
    output logic mem_resp_d,
    output logic [s_line-1:0] inst_rdata,
    output logic [s_line-1:0] data_rdata,
    output logic [31:0] pmem_addr
);
    
logic mux_sel;

arbiter_datapath #(.s_line(s_line)) arbiter_datapath(
    .*
);
arbiter_control arbiter_control(
    .*
);

endmodule : arbiter
    