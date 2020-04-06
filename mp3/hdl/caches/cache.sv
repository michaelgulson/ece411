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
    input logic [31:0] mem_address,
    input logic [255:0] pmem_rdata,
    input logic mem_read,
    input logic mem_write,
    input logic pmem_resp,
    input logic [31:0] mem_wdata, //data to the memory
    input logic [3:0] mem_byte_enable, //masking, which byte in mem written(@mem write)
    output logic [255:0] pmem_wdata,
    output logic [31:0] mem_rdata, 
    output logic pmem_read, 
    output logic pmem_write,
    output logic mem_resp,
    output logic [31:0]pmem_address
);

   //internal logic declaration
    logic [255:0] mem_rdata256;
    logic [255:0] mem_wdata256;

    logic [31:0] mem_byte_enable256;
    logic hit;
    logic miss;
    logic dirty;
    logic set_dirty;
    logic reset_dirty;
    logic set_valid;
    logic load_tag;
    logic set_lru;
    logic data_read;
    logic load_data;

<<<<<<< HEAD
//TODO: check the control
l2_control control
=======
cache_control cache_control
>>>>>>> nikki
(
    .*
);

cache_datapath cache_datapath
(
    .*
);

bus_adapter bus_adapter
(
    .address(mem_address),
    .*
);

endmodule : cache