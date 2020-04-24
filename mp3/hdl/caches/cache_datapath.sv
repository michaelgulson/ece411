//cache_datapath
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
    input logic rst,
    input rv32i_word mem_address,
    input logic set_dirty,
    input logic reset_dirty,
    input logic set_valid,
    input logic load_tag,
    input logic set_lru,
    input logic load_data, 
    input logic pmem_write,
    input logic [s_mask-1:0] mem_byte_enable256,
    input logic [s_line-1:0] pmem_rdata,
    input logic [s_line-1:0] mem_wdata256,
    output logic hit,
    output logic miss,
    output logic dirty,
    output logic [s_line-1:0] mem_rdata256,
    output logic [s_line-1:0] pmem_wdata,
    output rv32i_word pmem_address
);  

logic [s_tag-1:0] set_tag;
logic [s_index-1:0] set_idx;
logic cache_hit;
logic h0;
logic h1;
logic [s_tag-1:0]t0;
logic [s_tag-1:0]t1;
logic v0;
logic v1;
logic dl_0;
logic dl_1;
logic d0;
logic d1;
logic lru_in;
logic lru_out;
logic tl_0;
logic tl_1;
logic vl_0;
logic vl_1;
logic [s_line-1:0]data_mux_out;
logic [s_mask-1:0]line_0;
logic [s_mask-1:0]line_1;
logic [s_line-1:0]data_array_out0;
logic [s_line-1:0]data_array_out1;
logic data_read;

assign data_read = 1'b1;

assign set_tag = mem_address[31:32-s_tag];
assign set_idx = mem_address[32-s_tag-1:s_offset];

assign h0 = ( (set_tag == t0) && v0 ); //hit for way 0
assign h1 = ( (set_tag == t1) && v1 ); //hit for way 1
assign cache_hit = (h0 || h1);
assign hit = cache_hit;
assign miss = (!cache_hit);

assign dl_0 = ((set_dirty || reset_dirty) && !lru_out);
assign dl_1 = ((set_dirty || reset_dirty) && lru_out);
assign dirty = (lru_out)? d1 : d0;

assign lru_in = (hit) ? ((h0) ? 1'b1: 1'b0) : lru_out;

assign tl_0 = (load_tag && !lru_out);
assign tl_1 = (load_tag && lru_out);

assign vl_0 = (set_valid && !lru_out);
assign vl_1  = (set_valid && lru_out);

assign pmem_wdata = (miss)? ((lru_out)? data_array_out1 : data_array_out0) : ((h0)? data_array_out0: data_array_out1);

assign mem_rdata256 = pmem_wdata;

assign pmem_address = (!pmem_write) ?  mem_address : {(!lru_out) ? t0 : t1, mem_address[7:5], 5'd0};

always_comb
begin 
    unique case (set_dirty)
    1'b0: //not dirty
    begin
        unique case (lru_out)
            1'b0:  //way 0 was lru
            begin 
                unique case (load_data) 
                1'b0: line_0 = {s_mask{1'b0}};
                1'b1: line_0 = {s_mask{1'b1}};
                default: line_0 = {s_mask{1'b0}};
                endcase
                line_1 = {s_mask{1'b0}};
            end 
            1'b1: //way 1 was lru
            begin 
                unique case (load_data)
                1'b0: line_1 = {s_mask{1'b0}};
                1'b1: line_1 = {s_mask{1'b1}};
                default: line_1 = {s_mask{1'b0}};
                endcase
                line_0 = {s_mask{1'b0}};
            end
            default: //this should never happen
            begin
                line_0 = {s_mask{1'b0}};
                line_1 = {s_mask{1'b0}};
            end 
        endcase 
    end 
    1'b1: //dirty
    begin  
        // Line 0
        unique case (h0)
            1'b0: line_0 = {s_mask{1'b0}};
            1'b1: 
            begin
                unique case (load_data)
                1'b0: line_0 = {s_mask{1'b0}};
                1'b1: line_0 = mem_byte_enable256;
                default: line_0 = {s_mask{1'b0}};
                endcase  
            end 
        default: //this should never happen
            begin
                line_0 = {s_mask{1'b0}};
            end 
        endcase 
        // Line 1
        unique case (h1)
        1'b0: line_1 = {s_mask{1'b0}};
        1'b1:
        begin
            unique case (load_data)
            1'b0: line_1 = {s_mask{1'b0}};
            1'b1: line_1 = mem_byte_enable256;
            default: line_1 = {s_mask{1'b0}};
            endcase  
        end 
        default:
        begin 
            line_1 = {s_mask{1'b0}};
        end 
        endcase
    end 
    default:
    begin
        line_0 = {s_mask{1'b0}};
        line_1 = {s_mask{1'b0}};
    end
    endcase 
end

data_array #( .s_offset(s_offset), .s_index(s_index)) line_array_1
(
    .read(data_read),
    .write_en(line_1),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(data_mux_out),
    .dataout(data_array_out1),
    .*
);

data_array #( .s_offset(s_offset), .s_index(s_index)) line_array_0
(
    .read(data_read),
    .write_en(line_0),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(data_mux_out),
    .dataout(data_array_out0),
    .*
);

array #(.width(s_tag),.s_index(s_index)) tag_array_0(
    .read(data_read),
    .load(tl_0),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(set_tag),
    .dataout(t0),
    .*
);

array #(.width(s_tag),.s_index(s_index)) tag_array_1(
    .read(data_read),
    .load(tl_1),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(set_tag),
    .dataout(t1),
    .*
);

array valid_array_0 (
    .read(data_read),
    .load(vl_0),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(1'b1),
    .dataout(v0),
    .*
);

array valid_array_1 (
    .read(data_read),
    .load(vl_1),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(1'b1),
    .dataout(v1),
    .*
);

array dirty_array_0(
    .read(data_read),
    .load(dl_0),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(set_dirty),
    .dataout(d0),
    .*
);

array dirty_array_1(
    .read(data_read),
    .load(dl_1),
    .rindex(set_idx),
    .windex(set_idx),
    .datain(set_dirty),
    .dataout(d1),
    .*
);

array LRU(
            .clk(clk),
            .read(!set_lru),
            .load(set_lru),
            .rindex(set_idx),
            .windex(set_idx),
            .datain(lru_in),
            .dataout(lru_out),
            .*
);

always_comb
begin
    case(set_dirty)
        1'd0:
            data_mux_out = pmem_rdata;
        1'd1:
            data_mux_out = mem_wdata256; 
        default:
            data_mux_out = pmem_rdata;
    endcase
end

endmodule : cache_datapath