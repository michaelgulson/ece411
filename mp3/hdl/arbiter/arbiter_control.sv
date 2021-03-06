//import rv32i_types::*;

module arbiter_control
(
    input logic clk, 
    input logic rst, 
    input logic mem_read_i, 
    input logic mem_read_d,
    input logic mem_write_d,
    input logic mem_write_i,
    input logic pmem_resp,
    output logic pmem_read, 
    output logic pmem_write,
    output logic mem_resp_i, 
    output logic mem_resp_d, 
    output logic load_i,
    output logic load_d
);

enum int unsigned{
    IDLE, 
    I_CACHE, 
    D_CACHE
} state, next_state;

function void set_defaults();
    pmem_read = 1'b0;
    pmem_write = 1'b0;
    mem_resp_i = 1'b0;
    mem_resp_d = 1'b0;
    load_i = 1'b0;
    load_d = 1'b0;
endfunction

always_comb
begin: state_actions
    set_defaults();

    unique case (state)
        IDLE:;
        I_CACHE:
        begin
            load_i = 1'b1;
            mem_resp_i = pmem_resp;
            pmem_read = mem_read_i;
            pmem_write = mem_write_i;
        end
        D_CACHE:
        begin
            load_d = 1'b1;
            mem_resp_d = pmem_resp;
            pmem_read = mem_read_d;
            pmem_write = mem_write_d;
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
            if(pmem_resp&&(!(mem_read_d||mem_write_d)))
            begin
                next_state = IDLE;
            end
            else if(pmem_resp && (mem_read_d||mem_write_d))
            begin
                next_state = D_CACHE; //wait for resp
            end
            else
            begin
                next_state = I_CACHE;
            end
        end
        D_CACHE:
        begin
            if(pmem_resp && (!mem_read_i))
            begin
                next_state = IDLE;
            end
            else if(pmem_resp && (mem_read_i))
            begin 
                next_state = I_CACHE;
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
