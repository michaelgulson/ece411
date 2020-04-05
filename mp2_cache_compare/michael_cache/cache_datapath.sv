`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;


module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
input logic clk,
input logic reset,
input logic data_array0_read,
input logic data_array1_read,
input logic [s_tag-1:0] mem_tag,
input logic [s_index-1:0] mem_set,
input logic [s_offset-1:0] mem_offset,
input logic [255:0] mem_wdata256,
input logic [31:0] mem_byte_enable256,
input logic [255:0] pmem_rdata,

input logic tag0_read,
input logic tag0_load,
input logic tag1_read,
input logic tag1_load,
input logic valid0_read,
input logic valid0_load,
input logic valid0_in,
input logic valid1_read,
input logic valid1_load,
input logic valid1_in,
input logic dirty0_read,
input logic dirty0_load,
input logic dirty0_in,
input logic dirty1_read,
input logic dirty1_load,
input logic dirty1_in,
input logic LRU_read,
input logic LRU_load,
input logic LRU_in,
input logic pmem_wdata_mux_sel,
input logic [1:0] pmem_address_mux_sel,
input logic [1:0] mem_offset_mux_sel0,
input logic [1:0] mem_offset_mux_sel1,
input logic mem_rdata_mux_sel,
input logic data_in_mux_sel,

output logic [255:0] mem_rdata256,
output logic [255:0] pmem_wdata,
output logic hit0,
output logic hit1,
output logic valid0_out,
output logic valid1_out,
output logic dirty0_out,
output logic dirty1_out,
output logic LRU_out,
output rv32i_word pmem_address,
output logic LRU_dirty

);

logic [255:0] data_in_mux_out0;
logic [255:0] data_in_mux_out1;
logic [31:0] mem_offset_mux_out0;
logic [31:0] mem_offset_mux_out1;
logic [255:0] data_array0_out;
logic [255:0] data_array1_out;
logic [s_tag-1:0] tag0_dataout;
logic [s_tag-1:0] tag1_dataout;
logic cmp0_out;
logic cmp1_out;

assign hit0 = valid0_out && cmp0_out;
assign hit1 = valid1_out && cmp1_out;


data_array dataArray0(
    .clk(clk),
    .rst(reset),
    .read(data_array0_read),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(data_in_mux_out0),
    .write_en(mem_offset_mux_out0),
    .dataout(data_array0_out)
);

data_array dataArray1(
    .clk(clk),
    .rst(reset),
    .read(data_array1_read),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(data_in_mux_out1),
    .write_en(mem_offset_mux_out1),
    .dataout(data_array1_out)
);

array #(.width(s_tag)) tagArray0(
    .clk(clk),
    .rst(reset),
    .read(tag0_read),
    .load(tag0_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(mem_tag),
    .dataout(tag0_dataout)

);

array #(.width(s_tag)) tagArray1(
    .clk(clk),
    .rst(reset),
    .read(tag1_read),
    .load(tag1_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(mem_tag),
    .dataout(tag1_dataout)
);

array validArray0(
    .clk(clk),
    .rst(reset),
    .read(valid0_read),
    .load(valid0_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(valid0_in),
    .dataout(valid0_out)
);
array validArray1(    
    .clk(clk),
    .rst(reset),
    .read(valid1_read),
    .load(valid1_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(valid1_in),
    .dataout(valid1_out)
);
array dirtyArray0(
    .clk(clk),
    .rst(reset),
    .read(dirty0_read),
    .load(dirty0_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(dirty0_in),
    .dataout(dirty0_out)
);
array dirtyArray1(
    .clk(clk),
    .rst(reset),
    .read(dirty1_read),
    .load(dirty1_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(dirty1_in),
    .dataout(dirty1_out)
);
array LRUArray(    
    .clk(clk),
    .rst(reset),
    .read(LRU_read),
    .load(LRU_load),
    .rindex(mem_set),
    .windex(mem_set),
    .datain(LRU_in),
    .dataout(LRU_out)
);
cache_cmp cache_cmp0(
    .a(tag0_dataout),
    .b(mem_tag),
    .out(cmp0_out)
);
cache_cmp cache_cmp1(
    .a(tag1_dataout),
    .b(mem_tag),
    .out(cmp1_out)
);


//Pmem_data_mux //either data_array0_out or data_array1_out
//data_Array_in_mux
//mem_offset_mux_out  //either 32'd1 or mem_byte_enable256
//wdata_out_array_mux

always_comb begin //: CACHE MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // rv32i_word alumux1_out;

    unique case (pmem_wdata_mux_sel)
        1'b0: pmem_wdata = data_array0_out;
        1'b1:  pmem_wdata = data_array1_out;
        // etc.
        default: pmem_wdata = data_array0_out;
    endcase

    unique case (mem_offset_mux_sel0)
        2'b00: mem_offset_mux_out0 = mem_byte_enable256;
        2'b01: mem_offset_mux_out0 = 32'b11111111111111111111111111111111;
        2'b10: mem_offset_mux_out0 = 32'h00000000;
        default: mem_offset_mux_out0 = 32'h00000000;
    endcase

    unique case (mem_offset_mux_sel1)
        2'b00: mem_offset_mux_out1 = mem_byte_enable256;
        2'b01: mem_offset_mux_out1 = 32'b11111111111111111111111111111111;
        2'b10: mem_offset_mux_out1 = 32'h00000000;
        default: mem_offset_mux_out1 = 32'h00000000;
    endcase

    unique case (mem_rdata_mux_sel)
        1'b0: mem_rdata256 = data_array0_out;
        1'b1: mem_rdata256 = data_array1_out;

        default: mem_rdata256 = data_array0_out;
    endcase
    unique case (pmem_address_mux_sel)

        2'b00: pmem_address = {mem_tag, mem_set, 5'h0};
        2'b01: pmem_address = {tag0_dataout, mem_set, 5'h0};
        2'b10: pmem_address = {tag1_dataout, mem_set, 5'h0};
        default: pmem_address = {mem_tag, mem_set, 5'h0};
    endcase
    unique case (LRU_out)
        1'b0: begin
                if(dirty0_out)
                    LRU_dirty = 1'b1;
                else
                    LRU_dirty = 1'b0;
            end
        1'b1: begin
                if(dirty1_out)
                    LRU_dirty = 1'b1;
                else
                    LRU_dirty = 1'b0;
                end
            default: LRU_dirty = 1'b0;
    endcase
    unique case (mem_offset_mux_sel0)
        2'b00:  data_in_mux_out0 = mem_wdata256;
        2'b01:  data_in_mux_out0 = pmem_rdata;
        2'b10:  data_in_mux_out0 = pmem_rdata;
            default: data_in_mux_out0 = pmem_rdata;
    endcase
    unique case (mem_offset_mux_sel1)
        2'b00:  data_in_mux_out1 = mem_wdata256;
        2'b01:  data_in_mux_out1 = pmem_rdata;
        2'b10:  data_in_mux_out1 = pmem_rdata;
            default: data_in_mux_out1 = pmem_rdata;
    endcase

    
end

endmodule : cache_datapath
