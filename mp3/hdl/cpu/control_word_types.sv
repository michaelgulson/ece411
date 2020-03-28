package control_word_types;


typedef struct packed {
    alu_ops alu_op;
    logic mem_read;
    logic mem_write;
    logic regfile_mux_sel;
    logic [3:0] load_regfile;
    logic pc_mux_sel;
    logic alu_muxsel1;
    logic [2:0] alu_muxsel2;
    logic [4:0] dest;
    logic [3:0] rmask;
    logic [3:0] wmask;
	 logic trap;
} control_word;

endpackage : control_word_types