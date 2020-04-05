module arbiter_control
(
    input logic clk, 
    input logic rst, 
    input logic mem_read_i, 
    input logic mem_read_d,
    input logic mem_resp, 

    output logic mem_read, 
    output logic mem_write,
    output logic mem_resp_i, 
    output logic mem_resp_d, 
    output logic mux_sel
);

enum int unsigned{
    IDLE, 
    I_CACHE, 
    D_CACHE
} state, next_state;

function void set_defaults();
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_resp_i = 1'b0;
    mem_resp_d = 1'b0;
    mux_sel = 1'b0;
endfunction

always_comb
begin: state_actions
    set_defaults();

    unique case (state)
        IDLE:;

        I_CACHE:
        begin
            mem_resp_i = mem_resp;
            mem_read = mem_read_i;
        end
        D_CACHE:
        begin
            mem_resp_d = mem_resp;
            mem_read = mem_read_d;
            mem_write = mem_write_d;
            mux_sel = 1'b1;
        end
        default: ;
    endcase
end

always_comb
begin : next_state_logic
    unique case (state)
        IDLE: 
        begin
            if(mem_read_i)
            begin
                next_state = I_CACHE;
            end
            else if(mem_read_d || mem_write_d)
            begin
                next_state = D_CACHE;
            end
            else
            begin
                next_state = IDLE;
            end
        end
        I_CACHE:
        begin
            if(mem_resp)
            begin
                next_state = IDLE;
            end
            else
            begin
                next_state = I_CACHE; //wait for resp
            end
             
        end
        D_CACHE:
        begin
            if(mem_resp && !(mem_read_d) && !(mem_write_d))
            begin
                next_state = IDLE;
            end
            else
            begin
                next_state = D_CACHE; //wait for resp
            end
        end
        default:;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if(rst)
    begin
        state <= IDLE;
    end
	else
    begin
        state <= next_state;
    end
    
end

endmodule : arbiter_control
