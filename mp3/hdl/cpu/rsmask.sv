import rv32i_types::*;

module rsmask(
    input logic [1:0] addr_01,
    input logic [2:0] funct3,
    input logic [6:0] opcode,
    output logic [3:0] rmask,
    output logic [3:0] wmask
);

store_funct3_t store_funct3;
load_funct3_t load_funct3;

assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

always_comb begin 
    wmask = 4'b0;
    rmask = 4'b0;

    case (opcode)

        op_load: begin
                case (load_funct3)
                    lw: rmask = 4'b1111;
                    lh, lhu: 
                    begin
                        if(addr_01)
                             rmask = 4'b1100;
                        else
                             rmask = 4'b0011; 
                    end				
                    lb, lbu: 
                    begin
                        case (addr_01)
                            2'b00:
                                 rmask = 4'b0001;
                            2'b01:
                                 rmask = 4'b0010;
                            2'b10:
                                 rmask = 4'b0100;
                            2'b11:
                                 rmask = 4'b1000;
                            default:
                                 rmask = 4'b0001;
                        endcase				
                    end
                    default: ;
                endcase
            end

		 op_store: begin
            case (store_funct3)
                sw:  wmask = 4'b1111;
                sh: 
				begin
					if(addr_01)
						 wmask = 4'b1100; 
					else
						 wmask = 4'b0011 ;
				end	
                sb:
				begin
					case (addr_01)
						2'b00:
							 wmask = 4'b0001;
						2'b01:
							 wmask = 4'b0010;
						2'b10:
							 wmask = 4'b0100;
						2'b11:
							 wmask = 4'b1000;
						default:
							 wmask = 4'b0001;
					endcase				
				end 

                default: begin
                            wmask = 4'b0;
                            rmask = 4'b0;
                        end
            endcase
        end

        default: begin
                rmask = 4'b0;
                wmask = 4'b0;
                end

    endcase
end    

endmodule