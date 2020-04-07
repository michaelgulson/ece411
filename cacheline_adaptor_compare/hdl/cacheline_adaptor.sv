module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
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

always_ff @(posedge clk, negedge reset_n) begin
    static logic mode;
    static logic[2:0] counter; 
    //if reset
    if(~reset_n) begin
        read_o <= 1'b0;
        write_o <= 1'b0;
        resp_o <= 1'b0;
        mode = 1'b0;
    end
    else begin
        case({read_i,write_i,resp_i})
            3'b000: begin
                if(mode == 1'b0)begin //completed reads
                    if(counter == 4)begin
                        resp_o <= 1'b1;
                        counter <= 5;
                    end
                    read_o <= 1'b0;
                end
                else begin
                    // $display("counter: %d",counter);
                    if(counter == 2) begin //completed bursts
                        counter <= 3; //avoid coming here agin twice
                        resp_o <= 1'b1;
                    end
                    write_o <= 1'b0;
                end
            end

            3'b001: begin 
                if(mode == 1'b0) begin //reciving batches
                    case(counter)
                        3'b000: begin //recive first batch
                            counter <= 1;
                            line_o[63:0] <= burst_i;
                        end
                        3'b001: begin //second batch
                            counter <= 2;
                            line_o[127:64] <= burst_i;
                        end
                        3'b010: begin //third batch
                            counter <= 3;
                            line_o[191:128] <= burst_i;
                        end
                        3'b011: begin //forth batch
                            counter <= 4;
                            line_o[255:192] <= burst_i;
                        end
                        default: ; //done loading batches
                    endcase
                end
                else begin
                    case(counter)
                        3'b000: begin //first burst     
                            counter <= 1;
                            burst_o <= line_i[191:128];
                            // $display("sending %x",line_i[191:128]);
                        end
                        3'b001: begin //second burst
                            counter <= 2;
                            burst_o <= line_i[255:192]; //last burst here
                            // $display("sending %x",line_i[255:192]);
                        end
                        default: ; //nothing here
                    endcase
                end
            end
            3'b100: begin  //receiving from testbench to memory
                address_o <= address_i; //send address
                resp_o <= 1'b0; //response not valid
                read_o <= 1'b1; //turn read on
                write_o <= 1'b0; //turn write off
                counter <= 0;
                mode <= 1'b0;
            end
            3'b010: begin //receiving from memory to testbench
                address_o <= address_i; //send address
                resp_o <= 1'b0; //response not valid
                read_o <= 1'b0; //turn read off
                write_o <= 1'b1; //turn write on
                counter <= 0;
                mode <= 1'b1;
                burst_o <= line_i[63:0];
                // $display("sending %x",line_i[63:0]);
            end
            3'b011: begin //write and resp is logic 1
                burst_o <= line_i[127:64];
                // $display("sending %x",line_i[127:64]);
            end
        endcase
    end
end

endmodule : cacheline_adaptor