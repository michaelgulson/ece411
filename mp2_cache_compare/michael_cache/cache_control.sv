module cache_control (   
    input logic clk,
    input logic reset,
    input logic mem_read,
    input logic mem_write,
    input logic pmem_resp,
    input logic hit0,
    input logic hit1,
    input logic valid0_out,
    input logic valid1_out,
    input logic dirty0_out,
    input logic dirty1_out,
    input logic LRU_out,
    input logic LRU_dirty,

    output logic data_array0_read,
    output logic data_array1_read,
    output logic tag0_read,
    output logic tag0_load,
    output logic tag1_read,
    output logic tag1_load,
    output logic valid0_read,
    output logic valid0_load,
    output logic valid0_in,
    output logic valid1_read,
    output logic valid1_load,
    output logic valid1_in,
    output logic dirty0_read,
    output logic dirty0_load,
    output logic dirty0_in,
    output logic dirty1_read,
    output logic dirty1_load,
    output logic dirty1_in,
    output logic LRU_read,
    output logic LRU_load,
    output logic LRU_in,

    output logic pmem_wdata_mux_sel,
    output logic [1:0] mem_offset_mux_sel0,
    output logic [1:0] mem_offset_mux_sel1,
    output logic mem_rdata_mux_sel,
    output logic [1:0] pmem_address_mux_sel,
    output logic data_in_mux_sel,

    output logic mem_resp,
    output logic pmem_read,
    output logic pmem_write

);

//logic [1:0] update_cache_miss_cnt;

enum int unsigned {
    /* List of states */
    hold, operating0, operating1, cache_hit, wait1, wait2, cache_miss_available, update_cache_miss0, update_cache_miss1, cache_miss_writeback, pmemread_miss_writeback 
} state, next_states;


function void set_defaults();
    data_array0_read = 1'b1;
    data_array1_read = 1'b1;
    tag0_load = 1'b0;
    tag0_read = 1'b1;
    tag1_load = 1'b0;
    tag1_read = 1'b1;
    valid0_read = 1'b1;
    valid0_load = 1'b0;
    valid0_in = 1'b0;
    valid1_read = 1'b1;
    valid1_load = 1'b0;
    valid1_in = 1'b0;
    dirty0_read = 1'b1;
    dirty0_load = 1'b0;
    dirty1_read = 1'b1;
    dirty1_load = 1'b1;
    dirty0_in = 1'b0;
    dirty1_in = 1'b0;
    LRU_in = 1'b0;
    LRU_load = 1'b0;
    LRU_read = 1'b1;

    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;

    pmem_wdata_mux_sel = 1'b0;
    mem_offset_mux_sel0 = 2'b10;
    mem_offset_mux_sel1 = 2'b10;

    mem_rdata_mux_sel = 1'b0;
    pmem_address_mux_sel = 2'b00;
    data_in_mux_sel = 1'b0;

endfunction

always_comb
begin : state_actions
    if(reset)begin
        set_defaults();
    end

    set_defaults();

    unique case(state) 
        hold: set_defaults();
                /*begin
                valid0_load = 1'b1;
                valid1_load = 1'b1;
                LRU_load = 1'b1;
                dirty0_load = 1'b1;
                dirty1_load = 1'b1;
                end */

        operating0: set_defaults();
        operating1: set_defaults();

        cache_hit: begin
                        if(mem_read)begin
                            if(hit0)begin
                                mem_rdata_mux_sel = 1'b0; 
                                LRU_in = 1'b1;
                                LRU_load = 1'b1;
                                mem_resp = 1'b1;
                            end
                            else begin //hit1
                                mem_rdata_mux_sel = 1'b1; 
                                LRU_in = 1'b0;
                                LRU_load = 1'b1;
                                mem_resp = 1'b1;
                            end
                        end
                        else  begin//mem_write
                            if(hit0) begin
                                mem_offset_mux_sel0 = 2'b00;
                            end
                            else begin
                                mem_offset_mux_sel1 = 2'b00;
                            end                         
                        end
                    end
        cache_miss_available:   begin
                                    if(mem_read)begin
                                        if(LRU_out)begin
                                            tag1_load = 1'b1;
                                            pmem_read = 1'b1;
                                        end
                                        else begin
                                            tag0_load = 1'b1;
                                            pmem_read = 1'b1;
                                        end
                                    end
                                    else begin //mem_write
                                        if(LRU_out)begin
                                            tag1_load = 1'b1;
                                            pmem_write = 1'b1;
                                        end
                                        else begin
                                            tag0_load = 1'b1;
                                            pmem_write = 1'b1;
                                        end
                                    end                                    
                                end
        update_cache_miss0:  begin  //extra state needed because it takes a clock cycle to for dataArray to load
                                if(mem_read)begin
                                    //if((valid0_out&&valid1_out)&&(LRU_dirty)) begin //writeback
                                            if(LRU_out)begin
                                                //data_array1_load = 1'b1;
                                                mem_offset_mux_sel1 = 2'b01;
                                                //data_in_mux_sel = 1'b0;
                                                //LRU_in = 1'b0;
                                                //LRU_load = 1'b1;
                                                //update_cache_miss_cnt = 2'b01;

                                            end
                                            else begin
                                                //data_array0_load = 1'b1;
                                                mem_offset_mux_sel0 = 2'b01;                                        
                                                //data_in_mux_sel = 1'b0;
                                                //LRU_in = 1'b1;
                                                //LRU_load = 1'b1;  
                                                //update_cache_miss_cnt = 2'b01;
                                            end
                                        //end
                                    //end
                                    /*else begin //available
                                            if(!valid0_out)begin
                                                //data_in_mux_sel = 1'b0;
                                                mem_offset_mux_sel0 = 2'b01;
                                                //data_array0_load = 1'b1;
                                                //update_cache_miss_cnt = 2'b01;
                                            end
                                            else if(!valid1_out) begin
                                                mem_offset_mux_sel1 = 2'b01;
                                            end
                                            else if(LRU_out) begin
                                                mem_offset_mux_sel1 = 2'b01;
                                            end
                                            else begin
                                                mem_offset_mux_sel0 = 2'b01;
                                            end
                                        //end
                                    end
                                end
                                else begin//mem_write 
                                    if((valid0_out&&valid1_out)&&(LRU_dirty)) begin //writeback
                                            if(LRU_out)begin
                                                //data_array1_load = 1'b1;
                                                mem_offset_mux_sel1 = 2'b01;
                                            end
                                            else begin
                                                //data_array0_load = 1'b1;
                                                mem_offset_mux_sel0 = 2'b01;                                        
                                                //data_in_mux_sel = 1'b0;
                                                //LRU_in = 1'b1;
                                                //LRU_load = 1'b1;  
                                                //update_cache_miss_cnt = 2'b01;
                                            end
                                        //end
                                    end
                                    else begin //available
                                            if(!valid0_out)begin
                                                //data_in_mux_sel = 1'b0;
                                                mem_offset_mux_sel0 = 2'b01;
                                                //data_array0_load = 1'b1;
                                                //update_cache_miss_cnt = 2'b01;
                                            end
                                            else if(!valid1_out) begin
                                                mem_offset_mux_sel1 = 2'b01;
                                            end
                                            else if(LRU_out) begin
                                                mem_offset_mux_sel1 = 2'b01;
                                            end
                                            else begin
                                                mem_offset_mux_sel0 = 2'b01;
                                            end
                                        
                                    end*/
                                        
                                    
                                end
                            end
        update_cache_miss1:  begin
                                if(mem_read)begin
                                    /*if((valid0_out&&valid1_out)&&(LRU_dirty)) begin
                                    //writeback
                                    if(LRU_out)begin
                                                //data_array1_load = 1'b1;
                                                //mem_offset_mux_sel1 = 2'b01;
                                                //data_in_mux_sel = 1'b0;
                                                mem_resp = 1'b1;
                                                valid1_in = 1'b1;
                                                valid1_load = 1'b1;
                                                LRU_in = 1'b0;
                                                LRU_load = 1'b1;
                                                //update_cache_miss_cnt = 2'b10;
                                            end
                                            else begin
                                                //data_array0_load = 1'b1;
                                                //mem_offset_mux_sel1 = 2'b01;                                        
                                                //data_in_mux_sel = 1'b0;
                                                mem_resp = 1'b1;
                                                valid0_in = 1'b1;
                                                valid0_load = 1'b1;   
                                                LRU_in = 1'b1;
                                                LRU_load = 1'b1;  
                                                //update_cache_miss_cnt = 2'b10;
                                            end
                                    end
                                    else begin*/
                                        //if(update_cache_miss_cnt==1) begin
                                            if(LRU_out)begin
                                                //data_array1_load = 1'b1;
                                                //mem_offset_mux_sel1 = 2'b01;
                                                //data_in_mux_sel = 1'b0;
                                                mem_resp = 1'b1;
                                                valid1_in = 1'b1;
                                                valid1_load = 1'b1;
                                                LRU_in = 1'b0;
                                                LRU_load = 1'b1;
                                                mem_rdata_mux_sel = 1'b1;
                                                //update_cache_miss_cnt = 2'b10;
                                            end
                                            else begin
                                                //data_array0_load = 1'b1;
                                                //mem_offset_mux_sel1 = 2'b01;                                        
                                                //data_in_mux_sel = 1'b0;
                                                mem_resp = 1'b1;
                                                valid0_in = 1'b1;
                                                valid0_load = 1'b1;   
                                                LRU_in = 1'b1;
                                                LRU_load = 1'b1;  
                                                mem_rdata_mux_sel = 1'b0;
                                                //update_cache_miss_cnt = 2'b10;
                                            end
                                        //end
                                        /*
                                            if(!LRU_out)begin
                                                //data_in_mux_sel = 1'b0;
                                                //mem_offset_mux_sel0 = 2'b01;
                                                //data_array0_load = 1'b1;
                                                LRU_in = 1'b0;
                                                LRU_load = 1'b1;
                                                mem_resp = 1'b1;
                                                valid0_in = 1'b1;
                                                valid0_load = 1'b1;
                                                mem_rdata_mux_sel = 1'b0;
                                                //update_cache_miss_cnt = 2'b10;
                                            end
                                            else begin
                                                //data_in_mux_sel = 1'b0;
                                                //mem_offset_mux_sel1 = 2'b01;
                                                //data_array1_load = 1'b1;
                                                LRU_in = 1'b1;
                                                LRU_load = 1'b1;
                                                mem_resp = 1'b1;
                                                valid1_in = 1'b1;
                                                valid1_load = 1'b1;
                                                mem_rdata_mux_sel = 1'b1;
                                                //update_cache_miss_cnt = 2'b10;
                                            end
                                        */
                                        //end
                                    //end
                                end
                                else begin
                                    if(LRU_out) begin
                                        mem_resp = 1'b1;
                                        valid1_in = 1'b1;
                                        valid1_load = 1'b1;
                                        LRU_in = 1'b0;
                                        LRU_load = 1'b1;
                                        mem_offset_mux_sel1 = 2'b00;
                                    end
                                    else begin
                                        mem_resp = 1'b1;
                                        valid0_in = 1'b1;
                                        valid0_load = 1'b1;   
                                        LRU_in = 1'b1;
                                        LRU_load = 1'b1;  
                                        mem_offset_mux_sel0 = 2'b00;
                                    end
                                end
                            end

        cache_miss_writeback:  begin
                                    if(mem_read) begin
                                        if(LRU_out)begin
                                            pmem_address_mux_sel = 1'b1;
                                            pmem_wdata_mux_sel = 1'b1;
                                            pmem_write = 1'b1;
                                        end
                                        else begin
                                            pmem_address_mux_sel =1'b0;
                                            pmem_wdata_mux_sel = 1'b0;
                                            pmem_write = 1'b1;
                                        end
                                    end
                                    else 
                                        set_defaults();
                                end
        pmemread_miss_writeback:    begin
                                        if(mem_read)begin
                                            if(LRU_out)begin
                                                tag1_load = 1'b1;
                                                pmem_address_mux_sel = 1'b1;
                                                pmem_read =1'b1;
                                            end
                                            else begin
                                                tag0_load = 1'b1;
                                                pmem_address_mux_sel = 1'b0;
                                                pmem_read = 1'b1;
                                            end
                                        end
                                        else
                                            set_defaults();
                                           
                                    end
        wait1:      begin
                        set_defaults();

                    end

        wait2:      set_defaults();
            
        default:    set_defaults();     
    endcase
end

always_comb
begin : next_state_logic
    if(reset)begin
        next_states = hold;
    end
    else begin
        unique case (state)
            hold: next_states = operating0;
            operating0: begin
                        if(mem_read||mem_write)
                            next_states = operating1;
                        else    
                            next_states = operating0;
                        end

            operating1: begin
                        if(mem_read)begin
                            if(hit0||hit1)
                                next_states = cache_hit;                            
                            else if((valid0_out&&valid1_out)&&(LRU_dirty))
                                next_states = cache_miss_writeback;
                            else
                                next_states = cache_miss_available;  
                        end
                        else if(mem_write)begin
                            if(hit0||hit1)
                                next_states = cache_hit;                            
                            else if((valid0_out&&valid1_out)&&(LRU_dirty))
                                next_states = cache_miss_writeback;
                            else
                                next_states = cache_miss_available; 
                        end
                        else
                            next_states = operating0;
                        end
            cache_hit: begin
                            next_states = operating0;
                        end
            
            /*cache_miss_available: begin
                                        if(pmem_resp)
                                            next_states = update_cache_miss;
                                        else
                                            next_states = cache_miss_available;
                                    end  */
            cache_miss_available: next_states = wait1;                        

            /*
            cache_miss_writeback: begin
                                        if(pmem_resp)
                                            next_states = pmemread_miss_writeback;
                                        else
                                            next_states = cache_miss_writeback;
                                    end*/
            cache_miss_writeback:  next_states = wait1;                        
            
            /*
            pmemread_miss_writeback: begin
                                        if(pmem_resp)
                                            next_states = update_cache_miss;
                                        else
                                            next_states = pmemread_miss_writeback;
                                    end*/
            pmemread_miss_writeback: next_states = wait2;

            wait1:   begin
                        if(pmem_resp)begin
                            if((valid0_out&&valid1_out)&&(LRU_dirty))
                                next_states = pmemread_miss_writeback;
                            else
                                next_states = update_cache_miss0;
                        end
                        else
                            next_states = wait1;
                    end
            wait2:  begin
                        if(pmem_resp)
                            next_states = update_cache_miss0;
                        else
                            next_states = wait2;
                    end

            update_cache_miss0: begin

                                    next_states = update_cache_miss1;
                                end
            update_cache_miss1:     next_states = operating0;

            default: next_states = operating0;

        endcase
    end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_states;
end



endmodule : cache_control