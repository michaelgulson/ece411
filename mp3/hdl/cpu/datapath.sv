import rv32i_types::*;


module datapath
{
    input clk,
    input rst,

    input rv32i_word i_mem_rdata,
    output rv32i_word i_mem_wdata, // signal used by RVFI Monitor
    output rv32i_word i_mem_address,
    output i_mem_read,
    output i_mem_write, 

    input rv32i_word d_mem_rdata,
    output rv32i_word d_mem_wdata, // signal used by RVFI Monitor
    output rv32i_word d_mem_address,
    output d_mem_read,
    output d_mem_write,

};


/********************************Control Unit********************************/



/****************************************************************************/




/********************************Registers***********************************/
//Other registers
//pcreg

//5 stage registers
//IF/ID
register pc_IF_ID(

//I'll do this later

);

register ir_IF_ID(

//I'll do this later

); 

//ID/EX

register control_word_ID_EX(

//I'll do this later

); 

register pc_IF_ID(

//I'll do this later

);

register read_data1_ID_EX(

//I'll do this later

);

register read_data2_ID_EX(
    
//I'll do this later

);

register imm_ID_EX(
    
//I'll do this later

);

//EX/MEM
register control_word_EX_MEM(

//I'll do this later

); 

register pc_EX_MEM(

//I'll do this later

);

register br_en_EX_MEM(

//I'll do this later

);

register pc_offset_EX_MEM(

//I'll do this later

);

register read_data2_EX_MEM(

//I'll do this later

);

register imm_EX_MEM(

//I'll do this later

);

register ALUout_EX_MEM(

//I'll do this later

);

//MEM/WB
register control_word_MEM_WB(

//I'll do this later

); 

register br_en_MEM_WB(

//I'll do this later

); 

register pc_offset_MEM_WB(

//I'll do this later

);

register data_out_MEM_WB(

//I'll do this later

);

register alu_out_MEM_WB(

//I'll do this later

);

register imm_MEM_WB(

//I'll do this later

);


/****************************************************************************/



/*******************************ALU and CMP(if needed)************************/




/*****************************************************************************/


/*********************************Muxes***************************************/



/*****************************************************************************/