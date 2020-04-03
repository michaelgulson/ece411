module l2_control #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,
    input logic pmem_resp,
    input logic mem_read,
    input logic mem_write,
    input logic hit,
    input logic miss,
    input logic dirty, 
    output logic set_dirty,
    output logic reset_dirty,
    output logic set_valid,
    output logic load_tag,
    output logic set_lru,
    output logic data_read,
    output logic load_data,
    output logic mem_resp,
    output logic pmem_read,
    output logic pmem_write      
);

enum int unsigned{
    STORE,
    LOAD,
    HIT
}state, next_state;

function void set_defaults();
    set_dirty = 1'b0;
    reset_dirty = 1'b0;
    set_valid = 1'b0;
    load_tag = 1'b0;
    set_lru = 1'b0;
    data_read = 1'b0;
    load_data = 1'b0;
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
endfunction

always_comb
begin: state_actions
    set_defaults()
    unique case(state)
            LOAD:
			begin
                set_valid = pmem_resp;
				load_tag = pmem_resp;
                data_read = (mem_read || mem_write);
                load_data = pmem_resp;
                pmem_read = !(pmem_resp);
			end
            STORE:
			begin
                data_read = (mem_read || mem_write);
				reset_dirty = pmem_resp;
                pmem_read = pmem_resp;                
                pmem_write= !(pmem_resp);
			end
            HIT:
			begin
                data_read = (mem_read || mem_write);
				mem_resp = (mem_read || mem_write) && hit;
				set_lru = (mem_read || mem_write) && hit;
				set_dirty = mem_write && hit;
				load_data = mem_write && hit;
			end
            default:;
    endcase
end

always_comb
begin: next_state_logic
    unique case(state)
        LOAD:
        begin
            if(pmem_resp)
            begin
                next_state = HIT;
            end
            else
            begin
                next_state = LOAD;
            end
        end
        STORE:
        begin
            if(pmem_resp)
            begin
                next_state = LOAD;
            end
            else
            begin
                next_state = STORE;
            end
        end
        HIT:
        begin
            if(mem_read || mem_write)
            begin
                if((hit && mem_read) || (hit && mem_write)) 
                begin
                    next_state = HIT;
                end             
                else
                begin
                    if(dirty)
                    begin
                        next_state = STORE;
                    end
                    else
                    begin
                        next_state = LOAD;     
                    end
                end
            end
            else
            begin
                next_state = HIT;
            end
        end
        default:
        begin
            next_state = HIT;
        end
    endcase
end

always_ff@(posedge clk)
begin: next_state_assignment
    if(rst) 
    begin
        state <= HIT;
    end
    else
        state <= next_state;
end

endmodule : cache_control