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
    input logic mem_write
    input logic mem_read,
    output logic [s_line-1:0] mem_rdata, 
    input logic [s_line-1:0] mem_wdata,
    output logic hit,

);

   //internal logic declaration
    logic miss;
    logic set_valid;
    logic load_tag;
    logic load_data;

btb_control #(
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


btb_datapath #(
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
    // mem_rdata256,
    // pmem_wdata,
    // pmem_address
);

endmodule : cache