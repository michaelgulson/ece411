module mp3_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);
/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP3
// int timeout = 100000000;   // Feel Free to adjust the timeout value
int halting = 0;
int count = 0;
logic prehalt;
int delay = 5;

assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
assign prehalt = (dut.pipeline_datapath.control_word_MEM.instr[6:0] == 7'h63) & 
                    (dut.pipeline_datapath.pc_MEM == dut.pipeline_datapath.pc_offset_MEM);   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (prehalt) begin
        halting <= 1;
        // $display("1");
    end
    if (halting == 1) begin
        count <= count + 1;
        // $display("2");
    end
    if (count == delay) begin
        // $display("3");
        rvfi.halt <= 1;
        $finish;
    end
    // if (timeout == 0) begin
    //     $display("TOP: Timed out");
    //     $finish;
    // end
    // timeout <= timeout - 1;
end

initial begin
    while(prehalt == 0) begin
        //do nothing
    end
    //after prehalt detected
    for(int i = 0; i < 8; ++i) begin
        //check way 0
        if(dut.d_cache.cache_datapath.valid_array_0.data[i] &
           dut.d_cache.cache_datapath.dirty_array_0.data[i]) begin
            tb.mem._mem[dut.d_cache.cache_datapath.tag_array_0.data[i]] = dut.d_cache.cache_datapath.line_array_0.data[i];
        end
        //check way 1
        if(dut.d_cache.cache_datapath.valid_array_1.data[i] &
           dut.d_cache.cache_datapath.dirty_array_1.data[i]) begin
            tb.mem._mem[dut.d_cache.cache_datapath.tag_array_1.data[i]] = dut.d_cache.cache_datapath.line_array_1.data[i];
        end
    end
end
/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
assign itf.inst_read = dut.inst_read;
assign itf.inst_addr = dut.inst_addr;
assign itf.inst_rdata = dut.inst_rdata;
assign itf.inst_resp = dut.inst_resp;
assign itf.data_read = dut.data_read;
assign itf.data_write = dut.data_write;
assign itf.data_addr = dut.data_addr;
assign itf.data_rdata = dut.data_rdata;
assign itf.data_wdata = dut.data_wdata;
assign itf.data_resp = dut.data_resp;
assign itf.data_mbe = dut.data_mbe;
/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/****************************** Generate Clock *******************************/
bit clk;
assign clk = itf.clk;

/*********************** Instantiate your design here ************************/
mp3 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    .pmem_resp(itf.mem_resp),
    .pmem_rdata(itf.mem_rdata),
    .pmem_read(itf.mem_read),
    .pmem_write(itf.mem_write),
    .pmem_address(itf.mem_addr),
    .pmem_wdata(itf.mem_wdata)
);
/***************************** End Instantiation *****************************/

endmodule