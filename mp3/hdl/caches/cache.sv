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

    //to/from smaller cache
    input logic [31:0] mem_address,
    input logic mem_read,
    input logic mem_write,
	input logic [s_mask-1:0] mem_byte_enable256, //masking, which byte in mem written(@mem write)
    output logic [s_line-1:0] mem_rdata256, 
    input logic [s_line-1:0] mem_wdata256,
    output logic mem_resp,

    //to/from bigger cache
    output logic [31:0]pmem_address,
    output logic pmem_read, 
    output logic pmem_write,
    input logic [s_line-1:0] pmem_rdata,
    output logic [s_line-1:0] pmem_wdata,
    input logic pmem_resp
);

   //internal logic declaration
    logic hit;
    logic miss;
    logic dirty;
    // logic valid;
    logic set_dirty;
    logic reset_dirty;
    logic set_valid;
    logic load_tag;
    logic set_lru;
    logic load_data;

cache_control #(
    .s_offset(s_offset),
    .s_index(s_index),
    .s_tag(s_tag),
    .s_mask(s_mask),
    .s_line(s_line),
    .num_sets(num_sets)
) cache_control
(
    .*
    //mem_read,
    //mem_write,
    //hit,
    //miss,
    //dirty, 
    //valid, <>
    //set_dirty,
    //reset_dirty,
    //set_valid,
    //load_tag,
    //set_lru,
    //load_data,
    //mem_resp,
    //pmem_read,
    //pmem_write  
);


cache_datapath #(
    .s_offset(s_offset),
    .s_index(s_index),
    .s_tag(s_tag),
    .s_mask(s_mask),
    .s_line(s_line),
    .num_sets(num_sets)
) cache_datapath
(
    .*
    // mem_address,
    // set_dirty,
    // reset_dirty,
    // set_valid,
    // load_tag,
    // set_lru,
    // load_data, 
    // pmem_write,
    // mem_byte_enable256,
    // pmem_rdata,
    // mem_wdata256,
    // hit,
    // miss,
    // dirty,
    // valid, <>
    // mem_rdata256,
    // pmem_wdata,
    // pmem_address
);

endmodule : cache