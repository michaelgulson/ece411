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

enum int unsigned
{
    IDLE,
    READ_1,
    READ_2,
    READ_3,
    READ_4,
    READ,
    WRITE_1,
    WRITE_2,
    WRITE_3,
    WRITE_4
} state, next_state;

function void default_set();
    address_o = address_i;
    read_o = read_i;
    write_o = write_i;
endfunction

always_comb 
begin : state_actions
    unique case (state)
        IDLE:
        begin
        resp_o = 1'b0 ;
        burst_o = 64'b0;
        end
        
        READ_1:
        begin
            resp_o = 1'b0 ;
            burst_o = 64'b0;
        end

        READ_2:
        begin 
            resp_o = 1'b0 ;
            burst_o = 64'b0;
        end

        READ_3:
        begin
            resp_o = 1'b0 ;
            burst_o = 64'b0;
            
        end

        READ_4:
        begin
            resp_o = 1'b0 ;
            burst_o = 64'b0;
        end

        READ:
        begin
            resp_o = 1;
            burst_o = 64'b0;
        end
        WRITE_1:
        begin
            resp_o = 0;
            burst_o = line_i[63:0];  
        end

        WRITE_2:
        begin
            resp_o = 0;
            burst_o = line_i[127:64];
         
        end

        WRITE_3:
        begin
              resp_o = 0;
            burst_o = line_i[191:128];
        end

        WRITE_4:
        begin
            burst_o = line_i[255:192];
            resp_o = 1;
        end

        default:
        begin
            burst_o = 64'b0;
            resp_o = 0;
        end
    endcase
end 

always_comb
begin: next_state_logic
default_set();
    unique case(state)
    IDLE:
    begin
        read_o = 0;
        write_o = 0;
        if(read_i)
        begin
            address_o = address_i;
            next_state = READ_1;
            read_o = 1;
            write_o = 0;
        end
        else if(write_i)
        begin 
            address_o = address_i;
            write_o = 1;
            read_o = 0;
            next_state = WRITE_1;
        end
        else 
            next_state = IDLE;
    end

    READ_1:
    begin
        read_o = 1;
        write_o = 0;
        address_o = address_i;
        if(resp_i)
        begin
            next_state = READ_2;        
        end
        else    
        begin
            next_state = READ_1;
        end
    end

    READ_2:
    begin
        read_o = 1;
        write_o = 0;
        address_o = address_i;
        next_state = READ_3;
    end

    READ_3:
    begin
        read_o = 1;
        write_o = 0;
        address_o = address_i;
        next_state = READ_4;
    end

    READ_4:
    begin
        read_o = 1;
        write_o = 0;
        address_o = address_i;
        next_state = READ;
    end

    READ:
    begin
        read_o = 0;
        write_o = 0;
        address_o = address_i;
        next_state = IDLE;
    end

    WRITE_1:
    begin
        read_o = 0;
        write_o = 1;
        address_o = address_i;
        if(resp_i)
        begin
            next_state = WRITE_2;
        end
        else
        begin   
            next_state = WRITE_1;
        end
    end
    WRITE_2:
    begin
        read_o = 0;
        write_o = 1;
        address_o = address_i;
        if(resp_i)
        begin
            next_state = WRITE_3;
        end
        else
        begin   
            next_state = WRITE_2;
        end
    end

    WRITE_3:
    begin
        read_o = 0;
        write_o = 1;
        address_o = address_i;
        if(resp_i)
        begin
            next_state = WRITE_4;
        end
        else
        begin   
            next_state = WRITE_3;
        end
    end

    WRITE_4:
    begin 
        read_o = 0;
        write_o = 1;
        address_o = address_i;
        if(resp_i)
        begin
            write_o = 0;
            next_state = IDLE;
        end
        else
        begin   
            next_state = WRITE_4;
        end
    end

    default:
    begin
        read_o = 0;
        write_o = 0;
        address_o = address_i;
        next_state = IDLE;
    end
    endcase
end

always_ff@(posedge clk)
begin: next_state_assignment
    if(!reset_n) //changed from active low (!reset_n) to high
        state <= IDLE;
    else
        state <= next_state;
end

always_ff@(posedge clk)
begin: cacheline_read
    unique case(state)
    READ_1:
    begin
        line_o[63:0] <= burst_i;
    end
    READ_2:
    begin
        line_o[127:64] <= burst_i;
    end
    READ_3:
    begin
        line_o[191:128] <= burst_i;
    end
    READ_4:
    begin
        line_o[255:192] <= burst_i;
    end
    default:
    begin
        ;
    end
    endcase
end


endmodule : cacheline_adaptor