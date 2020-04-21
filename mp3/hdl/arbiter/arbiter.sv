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

logic [s_line-1:0] pmem_rdata_buffer;
logic [31:0] mem_addr_i_buffer;
logic [31:0] mem_addr_d_buffer;
logic mem_read_i_buffer;
logic mem_read_d_buffer;
logic mem_write_d_buffer;
logic pmem_resp_buffer;

register #(s_line) register_pmem_rdata(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(pmem_rdata),
    .out(pmem_rdata_buffer)
);

register  register_mem_addr_i(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(mem_addr_i),
    .out(mem_addr_i_buffer)
);

register  register_mem_addr_d(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(mem_addr_d),
    .out(mem_addr_d_buffer)
);

register #(1) register_mem_read_i(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(mem_read_i),
    .out(mem_read_i_buffer)
);

register #(1) register_mem_read_d(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(mem_read_d),
    .out(mem_read_d_buffer)
);

register #(1) register_mem_write_d(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(mem_write_d),
    .out(mem_write_d_buffer)
);

register #(1) register_pmem_resp(
    .clk(clk),
    .rst(rst),
    .load(1'b1),
    .in(pmem_resp),
    .out(pmem_resp_buffer)
);






arbiter_datapath #(.s_line(s_line)) arbiter_datapath(
    .mux_sel(mux_sel),
    .mem_addr_i(mem_addr_i_buffer),
    .mem_addr_d(mem_addr_d_buffer),
    .pmem_rdata(pmem_rdata_buffer),
    .pmem_addr(pmem_addr),
    .inst_rdata(inst_rdata),
    .data_rdata(data_rdata)
);
arbiter_control arbiter_control(
    .clk(clk), 
    .rst(rst), 
    .mem_read_i(mem_read_i_buffer), 
    .mem_read_d(mem_read_d_buffer),
    .mem_write_d(mem_write_d_buffer),
    .pmem_resp(pmem_resp_buffer),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .mem_resp_i(mem_resp_i), 
    .mem_resp_d(mem_resp_d), 
    .mux_sel(mux_sel)
);

endmodule : arbiter
    