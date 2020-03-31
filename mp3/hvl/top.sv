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

assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = (dut.pipeline_datapath.control_word_MEM.instr[6:0] == 7'h63) & 
                    (dut.pipeline_datapath.pc_MEM == dut.pipeline_datapath.pc_offset_MEM);   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (rvfi.halt)
        $finish;
    // if (timeout == 0) begin
    //     $display("TOP: Timed out");
    //     $finish;
    // end
    // timeout <= timeout - 1;
end
/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
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
    .inst_read(itf.inst_read),
    .inst_addr(itf.inst_addr),
    .inst_resp(itf.inst_resp),
    .inst_rdata(itf.inst_rdata),

    .data_read(itf.data_read),
    .data_write(itf.data_write),
    .data_mbe(itf.data_mbe),
    .data_addr(itf.data_addr),
    .data_wdata(itf.data_wdata),
    .data_resp(itf.data_resp),
    .data_rdata(itf.data_rdata)
);
/***************************** End Instantiation *****************************/

endmodule