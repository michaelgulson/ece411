module arbiter #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask
)(
    input logic clk,
    input logic rst,

    //i cache
    input logic [31:0] mem_addr_i,
    input logic mem_read_i, 
    input logic mem_write_i,
    input logic [s_line-1:0] inst_wdata,
    output logic [s_line-1:0] inst_rdata,
    output logic mem_resp_i,

    //d cache
    input logic [31:0] mem_addr_d,
    input logic mem_read_d,
    input logic mem_write_d,
    input logic [s_line-1:0] data_wdata,
    output logic [s_line-1:0] data_rdata,
    output logic mem_resp_d,

    //l2 cache
    input logic pmem_resp, //to control
    input logic [s_line-1:0] pmem_rdata, //to datapath
    output logic [s_line-1:0] pmem_wdata, //from datapath
    output logic [31:0] pmem_addr, //from datapath
    output logic pmem_read, //from control
    output logic pmem_write //from control
);
    
logic load_i;
logic load_d;
logic [s_line-1:0] buf_i_rdata;
logic [s_line-1:0] buf_d_rdata;
logic buf_read_i;
logic buf_write_i;
logic buf_read_d;
logic buf_write_d;
logic [31:0] buf_addr_i;
logic [31:0] buf_addr_d;
logic buf_resp_i;
logic buf_resp_d;

always_ff @(posedge clk) begin
    if(rst)begin
        buf_read_i <= 1'b0;
        buf_write_i <= 1'b0;
        buf_read_d <= 1'b0;
        buf_write_d <= 1'b0;
        buf_addr_i <= 1'b0;
        buf_addr_d <= 1'b0;
        mem_resp_i <= 1'b0;
        mem_resp_d <= 1'b0;
    end else begin
        buf_read_i <= mem_read_i;
        buf_write_i <= mem_write_i;
        buf_read_d <= mem_read_d;
        buf_write_d <= mem_write_d;
        buf_addr_i <= mem_addr_i;
        buf_addr_d <= mem_addr_d;
        mem_resp_i <= buf_resp_i;
        mem_resp_d <= buf_resp_d;
    end
end

register #(.width(s_line)) reg_i_rdata (
    .*,
    .load(load_i),
    .in(buf_i_rdata),
    .out(inst_rdata)
);

register #(.width(s_line)) reg_d_rdata (
    .*,
    .load(load_d),
    .in(buf_d_rdata),
    .out(data_rdata)
);

arbiter_datapath #(.s_line(s_line)) arbiter_datapath(
    .*,
    .inst_rdata(buf_i_rdata),
    .data_rdata(buf_d_rdata),
    .mem_addr_i(buf_addr_i),
    .mem_addr_d(buf_addr_d)
);

arbiter_control arbiter_control(
    .*,
    .mem_resp_i(buf_resp_i),
    .mem_resp_d(buf_resp_d),
    .mem_read_i(buf_read_i),
    .mem_read_d(buf_read_d),
    .mem_write_i(buf_write_i),
    .mem_write_d(buf_write_d)
);

endmodule : arbiter
    