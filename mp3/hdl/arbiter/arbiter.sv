module arbiter(
    input logic clk,
    input logic rst,
    input logic mem_read_i, 
    input logic mem_write_i,   
    input logic mem_read_d,
    input logic mem_write_d,
    input logic pmem_resp, 
    input logic [255:0] wdata_i,
    input logic [255:0] wdata_d,
    input logic [31:0] mem_addr_i,
    input logic [31:0] mem_addr_d,

    output logic pmem_read,
    output logic pmem_write,
    output logic mem_resp_i,
    output logic mem_resp_d,
    output logic [255:0] pmem_wdata,
    output logic [255:0] inst_rdata,
    output logic [255:0] data_rdata,
    output logic [31:0] pmem_addr
);
logic mux_sel;

arbiter_datapath arbiter_datapath(
    .*
);
arbiter_control arbiter_control(
    .*
);

endmodule : arbiter
    