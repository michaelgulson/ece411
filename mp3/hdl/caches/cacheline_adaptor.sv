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

logic [63:0] buffer_mem [3:0];
//logic [255:0] buffer_mem;
logic [255:0] write_buffer;
logic [1:0] read_cnt;
logic [1:0] write_cnt;
logic read_state;
logic write_state;
logic delayWrite;


always_ff @ (posedge clk, posedge reset_n) begin
    if (reset_n==1'b1) begin
        read_o <= 1'b0;
        write_o <= 1'b0;
        read_cnt <= 2'b00;
        write_cnt <= 2'b00;
        //delayRead <= 2'b00;
        read_state <= 1'b0;
        write_state <= 1'b0;
        delayWrite <= 1'b0;
    end
    else if (read_state)begin
        case({read_i, write_i, resp_i})
            3'b000: begin       
                                /*if(cnt<4) begin
                                    line_o[63:0] <= buffer_mem[0];
                                    line_o[127:64] <= buffer_mem[1];
                                    line_o[191:128] <= buffer_mem[2];
                                    line_o[255:192] <= buffer_mem[3];
                                    //$display(buffer_mem[1]);
                                    //line_o <= buffer_mem;
                                    //$display(buffer_mem[0]);
                                    resp_o <= 1'b1; 
                                    //$display(buffer_mem[0]);
                                end*/
                                //if(cnt==3) begin
                                //$display(cnt);
                                if(read_cnt==3) begin
                                    /*if(delayRead == 3) begin
                                        read_o <= 1'b1;
                                    end*/ 
                                    //else begin
                                    //else begin
                                        read_o <= 1'b0;
                                        resp_o <= 1'b1;
                                        line_o[63:0] <= buffer_mem[0];
                                        line_o[127:64] <= buffer_mem[1];
                                        line_o[191:128] <= buffer_mem[2];
                                        line_o[255:192] <= buffer_mem[3];
                                    //read_state <= 1'b0;
                                    //    delayRead <= delayRead +1;
                                        read_state <= 1'b0;
                                        //read_cnt <= 2'b00;
                                    //end
                                    //read_o <= 1'b0;
                                    //$display(buffer_mem[2]);
                                    //$display(delayRead);
                                end
                                else
                                    read_o <= 1'b1;

                                //end
                    end
            3'b001: begin 
                            if(read_cnt<2) begin
                                buffer_mem[read_cnt] <= burst_i;   
                                read_cnt <= read_cnt +1;
                                read_o <= 1'b1;
                            end
                            else if(read_cnt==2)begin
                                buffer_mem[read_cnt] <= burst_i;   
                                read_cnt <= read_cnt +1;
                                read_o <= 1'b0;
                            end
                            else if(read_cnt ==3) begin
                                    buffer_mem[read_cnt] <= burst_i;
                                    read_o <= 1'b0;
                                
                            end
                            else begin
                                //do nothing
                                read_o <= 1'b1;
                            end
                            //$display(line_o[64*cnt +: 64]);
                    end
            /*3'b010: begin
                                write_o <= 1'b1;
                                address_o <= address_i;
                                write_state <= 1'b1;
                                write_cnt <= 2'b00;    
                    end   */        
            3'b100: begin  
                                read_cnt <= 2'b00;
                                read_o <= 1'b1;
                                //address_o <= address_i;
                                //read_state <= 1'b1;
                                resp_o <= 1'b0;
                    end
            3'b101: begin
                            read_cnt <= 2'b00;
                            read_o <= 1'b1;
                            //address_o <= address_i;
                    end
            default:  begin     end
        endcase
    end

    else if(write_state) begin
        case({read_i, write_i, resp_i})        
        3'b000: begin
                    //if(write_cnt==3)begin
                        resp_o <= 1'b1;
                        write_state <= 1'b0;
                        
                    //end
                end
        3'b001: begin
            //if(delayWrite) begin
            //    $display("reaches ln128");
                if(write_cnt<3) begin
                    burst_o <= write_buffer[64*write_cnt +: 64];   
                    write_cnt <= write_cnt +1;
                end
                else begin
                    if(write_cnt==3)begin
                        burst_o <= write_buffer[64*write_cnt +: 64];  
                        //$display("Write Buffer \t%x", write_buffer);
                    end
                end
            //end
            //else begin
            //    delayWrite <= 1'b1;
            //    $display("reaches ln141");
            //end                   

            end
        3'b010: begin
                    address_o <= address_i;
                    write_buffer <= line_i;
                    resp_o <= 1'b0;
                    write_cnt <= 2'b00;
                    write_o <= 1'b1;
                    delayWrite <= 1'b0;
                    burst_o <= write_buffer[63:0];
                    write_cnt <= 2'b01;
                end
        3'b011: begin
                    burst_o <= write_buffer[64*write_cnt +: 64];
                    write_cnt <= 2'b10;
                end        
        default: begin
                 end
        endcase
    end

    else begin
        case({read_i, write_i})
            2'b00: begin
                    read_cnt <= 2'b00;
                    read_o <= 1'b0;
                    write_o <= 1'b0;
                    resp_o <= 1'b0;
                   end
            
            2'b01: begin
                    write_state <= 1'b1;
                    end
            2'b10: begin
                    read_state <= 1'b1;
                    read_cnt <= 2'b00;
                    read_o <= 1'b1;
                    address_o <= address_i;
                   end
            default: begin
                        read_o <= 1'b0;
                        write_o <= 1'b0;
                    end
        endcase
    end

end
endmodule : cacheline_adaptor
