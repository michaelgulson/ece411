module bus_adapter #(
    parameter small_cache = 32,
    parameter big_cache = 256,
    parameter segments = big_cache/small_cache
)
(
    output [big_cache-1:0] mem_wdata256,
    input [big_cache-1:0] mem_rdata256,
    input [small_cache-1:0] mem_wdata,
    output [small_cache-1:0] mem_rdata,
    input [3:0] mem_byte_enable,
    output logic [small_cache-1:0] mem_byte_enable256,
    input [31:0] address
);

assign mem_wdata256 = {segments*{mem_wdata}};
assign mem_rdata = mem_rdata256[(small_cache*address[4:2]) +: small_cache];
assign mem_byte_enable256 = {28'h0, mem_byte_enable} << (address[4:2]*4);

endmodule : bus_adapter