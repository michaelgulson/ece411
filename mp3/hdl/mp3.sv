//insert top level for mp3 here
import rv32i_types::*;

module mp3
(
    input logic clk,
    input logic rst,

    /* I Cache Ports */
    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input [31:0] inst_rdata;

    /* D Cache Ports */
    output logic data_read;
    output logic data_write;
    output logic [3:0] data_mbe;
    output logic [31:0] data_addr;
    output logic [31:0] data_wdata;
    input logic data_resp;
    input logic [31:0] data_rdata;
);


datapath pipeline_datapath(.*);