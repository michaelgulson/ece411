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

/****************************** Halting **************************************/
// int timeout = 100000000;   // Feel Free to adjust the timeout value
int halting = 0;
int count = 0;
logic prehalt;
int delay = 5;

// Stop simulation on timeout (stall detection), halt
always @(posedge itf.clk) begin
    if (prehalt) begin
        halting <= 1;
    end
    if (halting == 1) begin
        count <= count + 1;
    end
    if (count == delay) begin
        rvfi.halt <= 1;
        $finish;
    end
    // if (timeout == 0) begin
    //     $display("TOP: Timed out");
    //     $finish;
    // end
    // timeout <= timeout - 1;
end
/*****************************************************************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP3
assign prehalt = (dut.pipeline_datapath.control_word_MEM.instr[6:0] == 7'h63) & 
                    (dut.pipeline_datapath.pc_MEM == dut.pipeline_datapath.pc_offset_MEM);   // Set high when you detect an infinite loop
initial rvfi.order = 0;
initial rvfi.halt = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

assign rvfi.commit = (dut.pipeline_datapath.control_word_WB.instr != 32'b0) && dut.pipeline_datapath.loadReg;
assign rvfi.inst = dut.pipeline_datapath.control_word_WB.instr;
assign rvfi.trap = dut.pipeline_datapath.control_word_WB.trap;
assign rvfi.rs1_addr = dut.pipeline_datapath.control_word_WB.rs1;
assign rvfi.rs2_addr = dut.pipeline_datapath.control_word_WB.rs2;
assign rvfi.rs1_rdata = dut.pipeline_datapath.read_data1_WB;
assign rvfi.rs2_rdata = dut.pipeline_datapath.read_data2_WB;
assign rvfi.load_regfile = dut.pipeline_datapath.control_word_WB.load_regfile;
assign rvfi.rd_addr = dut.pipeline_datapath.control_word_WB.dest;
assign rvfi.rd_wdata = dut.pipeline_datapath.regfilemux_out;
assign rvfi.pc_rdata = dut.pipeline_datapath.pc_WB;
assign rvfi.pc_wdata = dut.pipeline_datapath.pc_wdata;
assign rvfi.mem_addr = dut.pipeline_datapath.data_addr_WB;
assign rvfi.mem_rmask = dut.pipeline_datapath.control_word_WB.rmask;
assign rvfi.mem_wmask = dut.pipeline_datapath.control_word_WB.wmask;
assign rvfi.mem_rdata = dut.pipeline_datapath.data_out_WB;
assign rvfi.mem_wdata = dut.pipeline_datapath.data_wdata_WB;

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