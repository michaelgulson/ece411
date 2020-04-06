//insert top level for mp3 here
import rv32i_types::*;

module mp3
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata,

    output logic inst_read,
    output rv32i_word inst_addr,
    output logic inst_resp,
    output rv32i_word inst_rdata,
    output logic data_read,
    output logic data_write,
    output rv32i_word data_wdata,
    output logic [3:0] data_mbe,
    output logic data_resp,
    output rv32i_word data_addr,
    output rv32i_word data_rdata
);

logic [255:0] pmem_rdata256;
logic [255:0] pmem_wdata256;
logic pmem_readin;
logic pmem_writein;
logic pmem_wdatain;
rv32i_word pmem_addressin;
logic pmem_resp_in;
logic cacheline_adaptor_resp;
logic mem_resp;
rv32i_word mem_rdata;
logic mem_read;
logic mem_write;
rv32i_word mem_address;
rv32i_word mem_wdata;
logic [31:0] mem_byte_enable256;
logic [255:0] inst_rdata_arb;
logic mem_resp_i;
logic [255:0] wdata_i;
logic mem_read_i;
logic mem_write_i;
rv32i_word mem_addr_i;
logic [255:0] data_rdata_arb;
logic [255:0] wdata_d;
logic mem_read_d;
logic mem_write_d;
rv32i_word mem_addr_d;
logic mem_resp_d;

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
    .pmem_rdata(inst_rdata_arb),
    .mem_read(inst_read),
    .mem_write(1'b0),
    .pmem_resp(mem_resp_i),
    .mem_wdata(32'd0), //data to the memory
    .mem_byte_enable(4'b000), //masking, which byte in mem written(@mem write)
    .pmem_wdata(wdata_i),
    .mem_rdata(inst_rdata), 
    .pmem_read(mem_read_i), 
    .pmem_write(mem_write_i),
    .mem_resp(inst_resp),
    .pmem_address(mem_addr_i)
);

cache d_cache(    
    .clk(clk), 
    .rst(rst), 
    .mem_address(data_addr),
    .pmem_rdata(data_rdata_arb),
    .mem_read(data_read),
    .mem_write(data_write),
    .pmem_resp(mem_resp_d),
    .mem_wdata(data_wdata), //data to the memory
    .mem_byte_enable(data_mbe), //masking, which byte in mem written(@mem write)
    .pmem_wdata(pmem_wdata256),
    .mem_rdata(data_rdata), 
    .pmem_read(mem_read_d), 
    .pmem_write(mem_write_d),
    .mem_resp(data_resp),
    .pmem_address(mem_addr_d)
);


arbiter arbiter(   
    .clk(clk),
    .rst(rst),
    .mem_read_i(mem_read_i), 
    .mem_read_d(mem_read_d),
    .mem_write_d(mem_write_d),
    .pmem_resp(cacheline_adaptor_resp), 
    .pmem_rdata(pmem_rdata256),
    .mem_addr_i(mem_addr_i),
    .mem_addr_d(mem_addr_d),

    .pmem_read(pmem_readin),
    .pmem_write(pmem_writein),
    .mem_resp_i(mem_resp_i),
    .mem_resp_d(mem_resp_d),
    .inst_rdata(inst_rdata_arb),
    .data_rdata(data_rdata_arb),
    .pmem_addr(pmem_addressin)
);

cacheline_adaptor cacheline_adaptor(
  .clk(clk),
   .reset_n(rst),

    // Port to LLC (Lowest Level Cache)
    .line_i(pmem_wdata256),
   .line_o(pmem_rdata256),
    .address_i(pmem_addressin),
    .read_i(pmem_readin),
    .write_i(pmem_writein),
    .resp_o(cacheline_adaptor_resp),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);
endmodule: mp3
