//insert top level for mp3 here
// import rv32i_types::*;

module mp3
(
    input logic clk,
    input logic rst,

    /* I Cache Ports */
    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    /* D Cache Ports */
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input logic data_resp,
    input logic [31:0] data_rdata
);


datapath pipeline_datapath(
    .clk(clk),
    .rst(rst),

    /* I Cache Ports */
    .inst_read(inst_read),
    .inst_addr(inst_addr),
    .inst_resp(inst_resp),
    .inst_rdata(inst_rdata),

    /* D Cache Ports */
    .data_read(data_read),
    .data_write(data_write),
    .data_mbe(data_mbe),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_resp(data_resp),
    .data_rdata(data_rdata)
);

cache i_cache(
    .clk(clk), 
    .rst(rst), 
    .mem_address(inst_addr),
    .pmem_rdata,
    .mem_read(inst_read),
    .mem_write(1'b0),
    .pmem_resp(mem_resp_i),
    .mem_wdata(32'bxxxx), //data to the memory
    .mem_byte_enable(xxxx), //masking, which byte in mem written(@mem write)
    .pmem_wdata(),
    .mem_rdata(data_), 
    .pmem_read, 
    .pmem_write,
    .mem_resp,
    .pmem_address
);

cache d_cache(.*);

arbiter arbiter(.*);

cacheline_adapter cacheline_adapter(.*);
endmodule: mp3
