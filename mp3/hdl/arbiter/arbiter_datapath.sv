module arbiter_datapath #(
    parameter s_line = 256
)
(
    input logic mux_sel,
    input logic [31:0] mem_addr_i,
    input logic [31:0] mem_addr_d,
    input logic [s_line-1:0] pmem_rdata,
    output logic [31:0] pmem_addr,
    output logic [s_line-1:0] inst_rdata,
    output logic [s_line-1:0] data_rdata
);


always_comb
begin
    unique case(mux_sel)
        1'd0:
        begin
            pmem_addr = mem_addr_i;
            inst_rdata = pmem_rdata;
            data_rdata = {s_line*{1'b0}};
        end
        1'd1:
        begin
            pmem_addr = mem_addr_d;
			inst_rdata = {s_line*{1'b0}}; // or pmem_rdata?
            data_rdata = pmem_rdata;
            inst_rdata = {s_line*{1'b0}};
        end
        default: 
		  begin
            pmem_addr = mem_addr_i; 
				inst_rdata = pmem_rdata; // or 256'b0?
				data_rdata = pmem_rdata; // or 0?
		  end
    endcase
end
endmodule: arbiter_datapath

