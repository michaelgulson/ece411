import rv32i_types::*;

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,
    input rv32i_word mem_address,
    input rv32i_word mem_wdata,
    input logic [255:0] pmem_rdata,
    input logic pmem_resp,
    input logic mem_read,
    input logic mem_write,
    input logic [3:0] mem_byte_enable,
    output logic mem_resp,
    output rv32i_word mem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output logic [255:0] pmem_wdata
);
logic [s_index-1:0] mem_set;
logic [s_tag-1:0] mem_tag;
logic [s_offset-1:0] mem_offset;
logic hit0;
logic hit1;
logic valid0_out;
logic valid1_out;
logic dirty0_out;
logic dirty1_out;
logic LRU_out;
logic LRU_dirty;
logic data_array0_read;
logic data_array1_read;
logic tag0_read;
logic tag0_load;
logic tag1_read;
logic tag1_load;
logic valid0_read;
logic valid0_load;
logic valid0_in;
logic valid1_read;
logic valid1_load;
logic valid1_in;
logic dirty0_read;
logic dirty0_load;
logic dirty0_in;
logic dirty1_read;
logic dirty1_load;
logic dirty1_in;
logic LRU_read;
logic LRU_load;
logic LRU_in;
logic pmem_wdata_mux_sel;
logic [1:0] mem_offset_mux_sel0;
logic [1:0] mem_offset_mux_sel1;
logic mem_rdata_mux_sel;
logic [1:0] pmem_address_mux_sel;
logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic data_in_mux_sel;
logic [31:0] mem_byte_enable256;


assign mem_offset = mem_address[4:0];
assign mem_set = mem_address[7:5];
assign mem_tag = mem_address[31:8];



cache_control control
(
    .clk(clk),
    .reset(rst),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .pmem_resp(pmem_resp),
    .hit0(hit0),
    .hit1(hit1),
    .valid0_out(valid0_out),
    .valid1_out(valid1_out),
    .dirty0_out(dirty0_out),
    .dirty1_out(dirty1_out),
    .LRU_out(LRU_out),
    .LRU_dirty(LRU_dirty),

    .data_array0_read(data_array0_read),
    .data_array1_read(data_array1_read),
    .tag0_read(tag0_read),
    .tag0_load(tag0_load),
    .tag1_read(tag1_read),
    .tag1_load(tag1_load),
    .valid0_read(valid0_read),
    .valid0_load(valid0_load),
    .valid0_in(valid0_in),
    .valid1_read(valid1_read),
    .valid1_load(valid1_load),
    .valid1_in(valid1_in),
    .dirty0_read(dirty0_read),
    .dirty0_load(dirty0_load),
    .dirty0_in(dirty0_in),
    .dirty1_read(dirty1_read),
    .dirty1_load(dirty1_load),
    .dirty1_in(dirty1_in),
    .LRU_read(LRU_read),
    .LRU_load(LRU_load),
    .LRU_in(LRU_in),

    .pmem_wdata_mux_sel(pmem_wdata_mux_sel),
    .mem_offset_mux_sel0(mem_offset_mux_sel0),
    .mem_offset_mux_sel1(mem_offset_mux_sel1),

    .mem_rdata_mux_sel(mem_rdata_mux_sel),
    .pmem_address_mux_sel(pmem_address_mux_sel),
    .data_in_mux_sel(data_in_mux_sel),

    .mem_resp(mem_resp),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write)
);

cache_datapath datapath
(
    .clk(clk),
    .reset(rst),
    .data_array0_read(data_array0_read),
    .data_array1_read(data_array1_read),
    .mem_tag(mem_tag),
    .mem_set(mem_set),
    .mem_offset(mem_offset),
    .mem_wdata256(mem_wdata256),
    .mem_byte_enable256(mem_byte_enable256),
    .pmem_rdata(pmem_rdata),
    .tag0_read(tag0_read),
    .tag0_load(tag0_load),
    .tag1_read(tag1_read),
    .tag1_load(tag1_load),
    .valid0_read(valid0_read),
    .valid0_load(valid0_load),
    .valid0_in(valid0_in),
    .valid1_read(valid1_read),
    .valid1_load(valid1_load),
    .valid1_in(valid1_in),
    .dirty0_read(dirty0_read),
    .dirty0_load(dirty0_load),
    .dirty0_in(dirty0_in),
    .dirty1_read(dirty1_read),
    .dirty1_load(dirty1_load),
    .dirty1_in(dirty1_in),
    .LRU_read(LRU_read),
    .LRU_load(LRU_load),
    .LRU_in(LRU_in),
    .pmem_wdata_mux_sel(pmem_wdata_mux_sel),
    .pmem_address_mux_sel(pmem_address_mux_sel),
    .mem_offset_mux_sel0(mem_offset_mux_sel0),
    .mem_offset_mux_sel1(mem_offset_mux_sel1),
    .mem_rdata_mux_sel(mem_rdata_mux_sel),
    .data_in_mux_sel(data_in_mux_sel),


    .mem_rdata256(mem_rdata256),
    .pmem_wdata(pmem_wdata),
    .hit0(hit0),
    .hit1(hit1),
    .valid0_out(valid0_out),
    .valid1_out(valid1_out),
    .dirty0_out(dirty0_out),
    .dirty1_out(dirty1_out),
    .LRU_out(LRU_out),
    .pmem_address(pmem_address),
    .LRU_dirty(LRU_dirty)
);

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(mem_rdata256),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);


endmodule : cache
