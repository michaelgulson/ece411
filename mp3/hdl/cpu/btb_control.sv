module cache_control #(
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
    input logic mem_read,
    input logic mem_write,
    input logic hit,
    output logic set_valid,
    output logic load_tag,
    output logic load_data,    
);

/*
enum int unsigned{
    STORE,
    HIT
}state, next_state;
*/

function void set_defaults();
    set_valid = 1'b0;
    load_tag = 1'b0;
    load_data = 1'b0;
    set_lru = 1'b0;
endfunction

always_comb
begin: state_actions
       set_defaults();
        unique case({mem_write, mem_read})
            2'b00: ; 
            2'b01: set_lru = 1'b1;
            2'b10: begin
                        set_valid = 1'b1;
                        load_tag = 1'b1;
                        load_data = 1'b1;
                        set_lru = 1'b1;
                    end
            2'b11:  begin
                        set_valid = 1'b1;
                        load_tag = 1'b1;
                        load_data = 1'b1;
                        set_lru = 1'b1;
                    end
            default:;
        endcase
    end
end
/*
always_comb
begin: next_state_logic
    unique case(state)
        LOAD: //getting data from physical memory
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
        STORE: //sending data to physical memory
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
        HIT: //detecting a hit
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
*/
endmodule