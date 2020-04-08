module cacheline_adaptor
(
    input clk,
    input rst,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input logic read_i,
    input logic write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] pmem_rdata,
    output logic [63:0] pmem_wdata,
    output logic [31:0] pmem_address,
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp
);

/* making cacheline adaptor, 32 or 64 bytes of data in
 * address space. Pins limit it so, have to send over
 * several cycles.
 * 
 * Does two things:
 *   1. On loads, buffers data from memory until the
 *      burst is complete, then repsonds to lowest
 *      level cacche (LLC) with the complete cache 
 *      line.
 *   2. On stores, buffers a cacheline from the LLC,
 *      segments the data into appropriate sized blocks
 *      for burst transmission,and transmits the blocks
 *      into memory.
 */

logic mode; //direction of imforation travel
logic[2:0] counter;
logic ready;
assign pmem_address = address_i;

always_ff @(posedge clk, posedge rst) begin
    //if reset
    if(rst) begin
        counter <= 3'b000;
        pmem_read <= 1'b0;
        pmem_write <= 1'b0;
        resp_o <= 1'b0;
        mode <= 1'b0;
        ready <= 1'b0;
    end
    else begin
        case({read_i,write_i,pmem_resp})
            3'b000, 3'b001: begin
                if(mode == 1'b0)begin //completed reads
                    if(counter == 3'b100)begin
                        resp_o <= 1'b0;
                        counter <= 3'b101; //5
                        ready <= 1'b0;
                    end else begin
                        ready <= 1'b0;
                        pmem_read <= 1'b0;
                        resp_o <= 1'b0;
                    end
                end
                else begin
                    if(counter == 3'b010) begin //completed bursts
                        counter <= 3'b011; //avoid coming here agin twice
                        resp_o <= 1'b1;
                    end
                    pmem_write <= 1'b0;
                end
            end

            3'b101: begin 
                ready <= 1'b0;
                if(mode == 1'b0) begin //reciving batches
                    case(counter)
                        3'b000: begin //recive first batch
                            counter <= 3'b001; //1
                            line_o[63:0] <= pmem_rdata;
                        end
                        3'b001: begin //second batch
                            counter <= 3'b010; //2
                            line_o[127:64] <= pmem_rdata;
                        end
                        3'b010: begin //third batch
                            counter <= 3'b011; //3
                            line_o[191:128] <= pmem_rdata;
                        end
                        3'b011: begin //forth batch
                            counter <= 3'b100; //4
                            line_o[255:192] <= pmem_rdata;
                            pmem_read <= 1'b0;
                            ready <= 1'b1;
                        end
                        default: ; //done loading batches
                    endcase
                end
                else begin
                    case(counter)
                        3'b000: begin //first burst     
                            counter <= 3'b001; //1
                            pmem_wdata <= line_i[191:128];
                        end
                        3'b001: begin //second burst
                            counter <= 3'b010; //2
                            pmem_wdata <= line_i[255:192]; //last burst here
                        end
                        default: ; //nothing here
                    endcase
                end
            end
            3'b100: begin  //receiving from testbench to memory
                if(ready == 1'b0) begin
                    // pmem_address <= address_i; //send address
                    resp_o <= 1'b0; //response not valid
                    pmem_read <= 1'b1; //turn read on
                    pmem_write <= 1'b0; //turn write off
                    counter <= 3'b000;
                    mode <= 1'b0;
                end else begin
                    resp_o <= 1'b1;
                    pmem_read <= 1'b0;
                end
            end
            3'b010: begin //receiving from memory to testbench
                // pmem_address <= address_i; //send address
                resp_o <= 1'b0; //response not valid
                pmem_read <= 1'b0; //turn read off
                pmem_write <= 1'b1; //turn write on
                counter <= 3'b000;
                mode <= 1'b1;
                pmem_wdata <= line_i[63:0];
            end
            3'b011: begin //write and resp is logic 1
                pmem_wdata <= line_i[127:64];
            end
            default: ;
        endcase
    end
end

endmodule : cacheline_adaptor