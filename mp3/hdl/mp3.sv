//insert top level for mp3 here
import rv32i_types::*;

module mp3 #(
    parameter pmem_mask = 64,
    parameter l2_offset = 5,
    parameter l2_index = 3,
    parameter l2_mask = 2**l2_offset,
    parameter l2_line = 8*l2_mask,
    parameter l1_offset = 5,
    parameter l1_index = 3,
    parameter l1_mask = 2**l1_offset,
    parameter l1_line = 8*l1_mask
)
(
    input clk,
    input rst,
    input pmem_resp,
    input [pmem_mask-1:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [pmem_mask-1:0] pmem_wdata
);

logic [l2_line-1:0] pmem_rdata256;
logic [l2_line-1:0] pmem_wdata256;
logic [l2_line-1:0] l2_pmem_wdata;
logic pmem_readin;
logic pmem_writein;
logic pmem_wdatain;
rv32i_word pmem_addressin;
logic pmem_resp_in;
logic cacheline_adaptor_resp;
logic [l2_line-1:0] inst_rdata_arb;
logic mem_resp_i;
logic [l2_line-1:0] wdata_i;
logic mem_read_i;
logic mem_write_i;
rv32i_word mem_addr_i;
logic [l2_line-1:0] data_rdata_arb;
logic [l2_line-1:0] wdata_d;
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
logic [l2_mask-1:0] l2_rdata;
logic l2_resp;
rv32i_word  l2_addr;


logic [l1_line-1:0] inst_rdata256;
logic [l1_line-1:0] inst_wdata256;
logic [l1_mask-1:0] inst_mbe256;
logic [l1_line-1:0] data_rdata256;
logic [l1_line-1:0] data_wdata256;
logic [l1_mask-1:0] data_mbe256;

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

bus_adapter bus_adapter_inst
(
    .address(inst_addr),
    .mem_wdata256(inst_wdata256),
    .mem_rdata256(inst_rdata256),
    .mem_wdata(32'b0),
    .mem_rdata(inst_rdata),
    .mem_byte_enable(4'b0),
    .mem_byte_enable256(inst_mbe256)
);

cache #(.s_offset(l1_offset),.s_index(l1_index)) i_cache(
    .clk(clk), 
    .rst(rst), 
    .mem_address(inst_addr),
    .pmem_rdata(inst_rdata_arb),
    .mem_read(inst_read),
    .mem_write(1'b0),
    .pmem_resp(mem_resp_i),
    .mem_wdata256(inst_wdata256), //data to the memory
    .mem_byte_enable256(inst_mbe256), //masking, which byte in mem written(@mem write)
    .pmem_wdata(wdata_i),
    .mem_rdata256(inst_rdata256), 
    .pmem_read(mem_read_i), 
    .pmem_write(mem_write_i),
    .mem_resp(inst_resp),
    .pmem_address(mem_addr_i)
);

bus_adapter bus_adapter_data
(
    .address(data_addr),
    .mem_wdata256(data_wdata256),
    .mem_rdata256(data_rdata256),
    .mem_wdata(data_wdata),
    .mem_rdata(data_rdata),
    .mem_byte_enable(data_mbe),
    .mem_byte_enable256(data_mbe256)
);

cache #(.s_offset(l1_offset),.s_index(l1_index)) d_cache(    
    .clk(clk), 
    .rst(rst), 
    .mem_address(data_addr),
    .pmem_rdata(data_rdata_arb),
    .mem_read(data_read),
    .mem_write(data_write),
    .pmem_resp(mem_resp_d),
    .mem_wdata256(data_wdata256), //data to the memory
    .mem_byte_enable256(data_mbe256), //masking, which byte in mem written(@mem write)
    .pmem_wdata(pmem_wdata256),
    .mem_rdata256(data_rdata256), 
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

cache #(.s_offset(l2_offset),
        .s_index(l2_index)) 
l2_cache(
    .clk(clk), 
    .rst(rst), 
    .mem_address(l2_addr), //arbiter
    .pmem_rdata(pmem_rdata256), //*
    .mem_read(l2_read), //arbiter
    .mem_write(l2_write), //arbiter
    .pmem_resp(cacheline_adaptor_resp),//*
    .mem_wdata256(pmem_wdata256), //*connects directly to D-cache
    .mem_byte_enable256(32'b000), 
    
    .pmem_wdata(l2_pmem_wdata), //*
    .mem_rdata256(l2_rdata), //arbiter
    .pmem_read(pmem_readin), //*
    .pmem_write(pmem_writein), //write_o
    .mem_resp(l2_resp), //arbiter
    .pmem_address(pmem_addressin) //*
);

cacheline_adaptor cacheline_adaptor(
   .clk(clk),
   .reset_n(!rst), //cacheline_adaptor active low

    // Port to LLC (Lowest Level Cache)
    .line_i(l2_pmem_wdata),
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
