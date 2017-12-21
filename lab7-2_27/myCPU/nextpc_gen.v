module nextpc_gen(
    input  wire        resetn,

    input  wire [31:0] fe_pc,

    input  wire        de_br_taken,     //1: branch taken, go to the branch target
    input  wire        de_br_is_br,     //1: target is PC+offset
    input  wire        de_br_is_j,      //1: target is PC||offset
    input  wire        de_br_is_jr,     //1: target is GR value
    input  wire [15:0] de_br_offset,    //offset for type "br"
    input  wire [25:0] de_br_index,     //instr_index for type "j"
    input  wire [31:0] de_br_target,    //target for type "jr"

    output wire [31:0] inst_sram_addr,
    output wire [31:0] nextpc,

    input  wire        de_block,

    input  wire        de_is_eret,
    input  wire [31:0] de_eret_target,
    input  wire        de_is_syscall,

    output wire        de_pc_err,
    input  wire        exc_handler
);

    wire nojump;
    wire [31:0] br_target;
    wire [31:0] j_target;
    wire [31:0] C1;
    wire [31:0] C2;
    wire [31:0] C3;
    wire [31:0] C4;
    wire [31:0] C5;
    assign nojump = ~(de_br_taken | de_br_is_j |de_br_is_jr | de_is_eret | exc_handler);  //no need for de_br_is_br?
    assign br_target = fe_pc + {{14{de_br_offset[15]}}, de_br_offset, {2'b00}};
    assign j_target = {{4'hb}, de_br_index, {2'b00}};
    assign C1 = {32{de_br_taken}} & br_target;                 //BNE BEQ
    assign C2 = {32{de_br_is_j }} & j_target;                  //J JAL
    assign C3 = {32{de_br_is_jr}} & de_br_target;              //JR
    assign C4 = {32{nojump     }} & fe_pc + 4;                 //OTHERS
    assign C5 = {32{de_is_eret }} & de_eret_target;            //ERET
 
    assign nextpc = (~resetn) ? 32'b0:
                    (exc_handler)? 32'hbfc00380:
                    (de_block)? fe_pc:
                                C1 | C2 | C3 | C4 | C5 ;                                  
    assign inst_sram_addr = (~resetn) ? 32'b0 : nextpc;

    assign de_pc_err = (nextpc[1:0] != 2'b00);

endmodule //nextpc_gen