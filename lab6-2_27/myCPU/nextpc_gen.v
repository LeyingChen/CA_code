module nextpc_gen(
    input  wire        clk,
    input  wire        resetn,
    input  wire        resetn_reg,

    input  wire [31:0] fe_pc,

    input  wire        de_br_taken,     //1: branch taken, go to the branch target
    input  wire        de_br_is_br,     //1: target is PC+offset
    input  wire        de_br_is_j,      //1: target is PC||offset
    input  wire        de_br_is_jr,     //1: target is GR value
    input  wire [15:0] de_br_offset,    //offset for type "br"
    input  wire [25:0] de_br_index,     //instr_index for type "j"
    input  wire [31:0] de_br_target,    //target for type "jr"

    //output wire [31:0] inst_sram_addr,
    input  wire        inst_addr_ok,//I, 1
    input  wire        inst_data_ok,//I, 1
    output /*reg */        inst_req,
    output wire [31:0] inst_addr,

    output wire [31:0] nextpc,

    input  wire        de_block,

    input  wire        de_is_eret,
    input  wire [31:0] de_eret_target,
    input  wire        de_is_syscall,

    output wire        de_pc_err,
    input  wire        exc_handler,

    input  wire        inst_block,
    input  wire        data_block,
    input  wire        axi_block
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
 
    assign nextpc = (~resetn) ? 32'hbfc00000:
                    (~resetn_reg) ? 32'hbfc00000:
                    (de_block||inst_block||data_block||axi_block)? fe_pc:
                    (exc_handler)? 32'hbfc00380:
                                C1 | C2 | C3 | C4 | C5 ;                                  
 
    reg inst_keep;

 //   assign inst_req  = 1'b1;
    always @(posedge clk) begin
        inst_keep <= (!resetn) ? 1'b1 :
                     (!resetn_reg) ? 1'b1 :
                     (nextpc != fe_pc)  ? 1'b1 :
                     inst_data_ok ? 1'b0 : inst_keep;
    end 

    assign inst_req = (nextpc != fe_pc) || inst_keep;

    assign inst_addr = (inst_req&&inst_addr_ok) ? nextpc:32'hxxxxxxxx;
    assign de_pc_err = (nextpc[1:0] != 2'b00);

    //assign inst_sram_addr = (~resetn) ? 32'b0 : nextpc;

endmodule //nextpc_gen