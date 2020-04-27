//cache_datapath
//branch target datapath


module btb_datapath #(
    parameter s_offset = 2,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_index - 2, //tag is size
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,
    input logic [31:0] mem_address_r,
    input logic [31:0] mem_address_w,
    input logic set_valid,
    input logic set_lru,
    input logic load_tag,
    input logic load_data, 
    input logic [s_line-1:0] mem_wdata,
    output logic hit,
    output logic [s_line-1:0] mem_rdata
);  

logic [s_tag-1:0] set_tag_r;
logic [s_index-1:0] set_idx_r;
logic [s_tag-1:0] set_tag_w;
logic [s_index-1:0] set_idx_w;
logic cache_hit;
logic lru_in;
logic lru_out;
logic h0;
logic h1;
logic [s_tag-1:0]t0;
logic [s_tag-1:0]t1;
logic v0;
logic v1;
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

assign set_tag_r = mem_address_r[31:32-s_tag];
assign set_idx_r = mem_address_r[32-s_tag-1:s_offset];
assign set_tag_w = mem_address_w[31:32-s_tag];
assign set_idx_w = mem_address_w[32-s_tag-1:s_offset];

assign h0 = ( (set_tag_r == t0) && v0 ); //hit for way 0
assign h1 = ( (set_tag_r == t1) && v1 ); //hit for way 1
assign hit = (h0 || h1);

assign lru_in = (hit) ? ((h0) ? 1'b1: 1'b0) : lru_out;

assign tl_0 = (load_tag && !lru_out);
assign tl_1 = (load_tag && lru_out);


assign vl_0 = (set_valid && !lru_out);
assign vl_1  = (set_valid && lru_out);

assign mem_rdata = ((h0)? data_array_out0: data_array_out1);



always_comb begin

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

data_array #( .s_offset(s_offset), .s_index(s_index)) line_array_1
(
    .read(data_read),
    .write_en(line_1),
    .rindex(set_idx_r),
    .windex(set_idx_w),
    .datain(mem_wdata),
    .dataout(data_array_out1),
    .*
);

data_array #( .s_offset(s_offset), .s_index(s_index)) line_array_0
(
    .read(data_read),
    .write_en(line_0),
    .rindex(set_idx_r),
    .windex(set_idx_w),
    .datain(mem_wdata),
    .dataout(data_array_out0),
    .*
);

array #(.width(s_tag),.s_index(s_index)) tag_array_0(
    .read(data_read),
    .load(tl_0),
    .rindex(set_idx_r),
    .windex(set_idx_w),
    .datain(set_tag_r),
    .dataout(t0),
    .*
);

array #(.width(s_tag),.s_index(s_index)) tag_array_1(
    .read(data_read),
    .load(tl_1),
    .rindex(set_idx_r),
    .windex(set_idx_w),
    .datain(set_tag_r),
    .dataout(t1),
    .*
);

array valid_array_0 (
    .read(data_read),
    .load(vl_0),
    .rindex(set_idx_r),
    .windex(set_idx_w),
    .datain(1'b1),
    .dataout(v0),
    .*
);

array valid_array_1 (
    .read(data_read),
    .load(vl_1),
    .rindex(set_idx_r),
    .windex(set_idx_w),
    .datain(1'b1),
    .dataout(v1),
    .*
);

array LRU(
            .clk(clk),
            .read(!set_lru),
            .load(set_lru),
            .rindex(set_idx_r),
            .windex(set_idx_w),
            .datain(lru_in),
            .dataout(lru_out),
            .*
);


endmodule : btb_datapath