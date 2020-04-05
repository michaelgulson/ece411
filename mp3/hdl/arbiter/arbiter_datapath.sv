module arbiter_datapath(
    input logic mux_sel;
    input logic [31:0] mem_addr_i;
    input logic [31:0] mem_addr_d;
    input logic [255:0] wdata_i;
    input logic [255:0] wdata_d;
    input logic [255:0] rdata;
    output logic [31:0] mem_addr;
    output logic [255:0] inst_rdata;
    output logic [255:0] data_rdata;
    output logic [255:0] wdata;
);

always_comb
begin
    case(mux_sel)
        1'd0:
        begin
            mem_addr = mem_addr_i;
            inst_rdata = rdata;
            wdata = wdata_i;
        end
        1'd1:
        begin
            mem_addr = mem_addr_d;
            data_rdata = rdata;
            wdata = wdata_d;
        end
        default: 
            mem_addr = mem_addr_i; 
		endcase
end
endmodule: arbiter_datapath

