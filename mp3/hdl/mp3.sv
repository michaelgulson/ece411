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
    output [63:0] pmem_wdata
);

logic [255:0] pmem_rdata256;
logic [255:0] pmem_wdata256;
logic pmem_readin;
logic pmem_writein;
logic pmem_wdatain;
rv32i_word pmem_addressin;
logic pmem_resp_in;
logic cacheline_adaptor_resp;
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
logic inst_read;
rv32i_word inst_addr;
logic inst_resp;
rv32i_word inst_rdata;
logic data_read;
logic data_write;
rv32i_word data_wdata;
logic [3:0] data_mbe;
logic data_resp;
rv32i_word data_addr;
rv32i_word data_rdata;

logic l2_read;
logic l2_write;
logic [255:0] l2_rdata;
logic l2_resp;
rv32i_word  l2_addr;




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


cache #(.write_width(256),
        .s_index(2),
        .l2(1)) 
l2_cache(
    .clk(clk), 
    .rst(rst), 
    .mem_address(l2_addr), //arbiter
    .pmem_rdata(pmem_rdata256), //*
    .mem_read(l2_read), //arbiter
    .mem_write(l2_write), //arbiter
    .pmem_resp(cacheline_adaptor_resp),//*
    .mem_wdata(pmem_wdata256), //*connects directly to D-cache
    .mem_byte_enable(4'b000), 
    
    .pmem_wdata(), //*
    .mem_rdata(l2_rdata), //arbiter
    .pmem_read(pmem_readin), //*
    .pmem_write(pmem_writein), //write_o
    .mem_resp(l2_resp), //arbiter
    .pmem_address(pmem_addressin) //*
);


arbiter arbiter(   
    .clk(clk),
    .rst(rst),
    .mem_read_i(mem_read_i), 
    .mem_read_d(mem_read_d),
    .mem_write_d(mem_write_d),
    .pmem_resp(l2_resp), 
    .pmem_rdata(l2_rdata),
    .mem_addr_i(mem_addr_i),
    .mem_addr_d(mem_addr_d),

    .pmem_read(l2_read),
    .pmem_write(l2_write),
    .mem_resp_i(mem_resp_i),
    .mem_resp_d(mem_resp_d),
    .inst_rdata(inst_rdata_arb),
    .data_rdata(data_rdata_arb),
    .pmem_addr(l2_addr)
);

cacheline_adaptor cacheline_adaptor(
   .clk(clk),
   .reset_n(!rst), //cacheline_adaptor active low

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
