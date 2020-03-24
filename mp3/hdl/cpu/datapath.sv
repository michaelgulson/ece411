module datapath
{
    input clk,
    input rst,

    input rv32i_word i_mem_rdata,
    output rv32i_word i_mem_wdata, // signal used by RVFI Monitor
    output rv32i_word i_mem_address,
    output i_mem_read,
    output i_mem_write, 

    input rv32i_word d_mem_rdata,
    output rv32i_word d_mem_wdata, // signal used by RVFI Monitor
    output rv32i_word d_mem_address,
    output d_mem_read,
    output d_mem_write,

}