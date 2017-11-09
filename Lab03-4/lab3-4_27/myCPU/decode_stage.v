
module decode_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] fe_inst,

    output wire [ 4:0] de_rf_raddr1,
    input  wire [31:0] de_rf_rdata1,
    output wire [ 4:0] de_rf_raddr2,
    input  wire [31:0] de_rf_rdata2,

    output wire        de_br_taken,     //1: branch taken, go to the branch target
    output wire        de_br_is_br,     //1: target is PC+offset
    output wire        de_br_is_j,      //1: target is PC||offset 
    output wire        de_br_is_jr,     //1: target is GR value
    output wire [15:0] de_br_offset,    //offset for type "br"
    output wire [25:0] de_br_index,     //instr_index for type "j" !!or"jal"
    output wire [31:0] de_br_target,    //target for type "jr"

    output wire [ 2:0] de_out_op,       //control signals used in EXE, MEM, WB stages
    output wire [ 4:0] de_dest,         //reg num of dest operand, zero if no dest
    output wire [31:0] de_vsrc1,        //value of source operand 1
    output wire [31:0] de_vsrc2,        //value of source operand 2
    output wire [31:0] de_st_value,     //value stored to memory

    input  wire [31:0] fe_pc,
    output wire [31:0] de_pc,
    output wire [31:0] de_inst,         //instr code @decode stage

    output wire de_block,

    input  wire [ 3:0] wb_rf_wen,
    input  wire [ 4:0] wb_rf_waddr,
    input  wire [31:0] wb_rf_wdata,

    input  wire [ 4:0] mem_dest,        //reg num of dest operand
    input  wire [31:0] mem_value,       //mem_stage final result
    input  wire [31:0] mem_inst,

    input  wire [ 4:0] exe_dest,
    input  wire [31:0] exe_value,
    input  wire [31:0] exe_inst,

    output wire        de_saveal,

    input  wire [31:0] HI_rdata,
    input  wire [31:0] LO_rdata,
    input  wire [31:0] HI_wdata,
    input  wire [31:0] LO_wdata,
    input  wire        HI_wen,
    input  wire        LO_wen,
    //output wire        mul_signed,
    output wire        div_signed,
    output wire [31:0] div_x,
    output wire [31:0] div_y,
    output wire        div,
    input  wire        complete,

    input  wire [31:0] mul_div_result,
    output wire        de_mul,
    input  wire        exe_mul,
    input  wire        mem_mul
);

    //registers for input signal
    reg [31:0] fe_inst_reg;
    reg [31:0] fe_pc_reg;

    wire is_rtype;
    wire is_store;
    wire de_br_is_bneq;
    wire is_load;/////////////////////////////////if there is not 6'b100111
    wire exe_is_load;
    wire mem_is_load;
    wire exe_is_store;
    wire mem_is_store;

    assign div_signed = (is_rtype && fe_inst_reg[5:0] == 6'b011010)? 1 : 0;
    assign div        = (is_rtype && fe_inst_reg[5:1] == 5'b01101) ? 1 : 0;
    assign de_mul     = (is_rtype && fe_inst_reg[5:1] == 5'b01100) ? 1 : 0;

    assign de_br_is_bneq = (fe_inst_reg[31:27] == 5'b00010) ? 1 : 0;
    assign is_rtype = (fe_inst_reg[31:26] == 6'b000000) ? 1 : 0;
    assign is_store = (fe_inst_reg[31:28] == 4'b1010 || fe_inst_reg[31:26] == 6'b101110) ? 1 : 0;
    assign exe_is_store = (exe_inst[31:28] == 4'b1010 || exe_inst[31:26] == 6'b101110) ? 1 : 0;
    assign mem_is_store = (mem_inst[31:28] == 4'b1010 || mem_inst[31:26] == 6'b101110) ? 1 : 0;
    assign is_load  = (fe_inst_reg[31:29] == 3'b100) ? 1 : 0;
    assign exe_is_load = (exe_inst[31:29] == 3'b100) ? 1 : 0;
    assign mem_is_load = (mem_inst[31:29] == 3'b100) ? 1 : 0;
    

    assign de_block =   ((exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr1 == exe_dest)) 
                     || ((is_rtype || de_br_is_bneq || is_store) && (exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr2 == exe_dest))
                     //
                     || ((mem_inst[31:26]==6'b100010 || mem_inst[31:26]==6'b100110) && (mem_dest != 5'b0) && (de_rf_raddr1 == mem_dest)) 
                     || ((is_rtype || (de_br_is_bneq) || (is_store)) && (mem_inst[31:26]==6'b100010 || mem_inst[31:26]==6'b100110) && (mem_dest != 5'b0) && (de_rf_raddr2 == mem_dest))
                     //
                     || ((exe_inst[31:26] == 6'b000000) && (exe_inst[5:1] == 5'b01101) && (~complete))
                     || ((exe_inst[31:26]==6'b000000) && (exe_inst[5:1] == 5'b01100) && (is_rtype && (fe_inst_reg[5:0] == 6'b010000 || fe_inst_reg[5:0] == 6'b010010)) && exe_mul)
                     || ((mem_inst[31:26]==6'b000000) && (mem_inst[5:1] == 5'b01100) && (is_rtype && (fe_inst_reg[5:0] == 6'b010000 || fe_inst_reg[5:0] == 6'b010010)) && mem_mul);

    always @(posedge clk) begin                                                                             
      if(~resetn) begin
        fe_inst_reg <= 32'h0;
        fe_pc_reg <= 32'hbfc00000;
      end
      else if(de_block) begin
        fe_inst_reg <= fe_inst_reg;
        fe_pc_reg <= fe_pc_reg;         
      end
      else begin
        fe_inst_reg <= fe_inst;
        fe_pc_reg <= fe_pc;
      end   
    end

    wire [31:0] SignExtend;
    wire [31:0] ZeroExtend;
    wire        equal;
    wire [ 3:0] ALUOp;
    wire        signedop;

    wire [31:0] de_fwd_rdata2;
    
    assign de_pc = fe_pc_reg;
    assign de_inst = fe_inst_reg;

    assign de_rf_raddr1 = fe_inst_reg[25:21];
    assign de_rf_raddr2 = fe_inst_reg[20:16];

    assign de_dest = (is_rtype) ? fe_inst_reg[15:11]:
                     (de_saveal)? 5'd31 :                  //let's pretend JALR's rd == 5'd31
                                  fe_inst_reg[20:16];
//    assign de_st_value = de_rf_rdata2;
//    assign de_vsrc1 = de_rf_rdata1;
    assign de_st_value = de_fwd_rdata2;
    assign de_vsrc1 = ((~exe_is_store) && (exe_inst[31:26]!=6'b000010) && (exe_inst[31:27]!=5'b00010) && (exe_dest != 5'b0) && (de_rf_raddr1 == exe_dest)) ? exe_value : 
                      ((~mem_is_store) && (mem_inst[31:26]!=6'b000010) && (mem_inst[31:27]!=5'b00010) && (mem_dest != 5'b0) && (de_rf_raddr1 == mem_dest)) ? mem_value :
                      ((|wb_rf_wen/*wb_rf_wen == 4'b1111*/) && (wb_rf_waddr!=0) && (de_rf_raddr1 == wb_rf_waddr)) ? wb_rf_wdata :
                      ((is_rtype && (fe_inst_reg[5:0] == 6'b010000)) && (exe_inst[31:26] == 6'b000000 && exe_inst[5:0] == 6'b010001))? exe_value:
                      ((is_rtype && (fe_inst_reg[5:0] == 6'b010010)) && (exe_inst[31:26] == 6'b000000 && exe_inst[5:0] == 6'b010011))? exe_value:
                      ((is_rtype && (fe_inst_reg[5:0] == 6'b010000)) && (mem_inst[31:26] == 6'b000000 && mem_inst[5:0] == 6'b010001))? mem_value:
                      ((is_rtype && (fe_inst_reg[5:0] == 6'b010010)) && (mem_inst[31:26] == 6'b000000 && mem_inst[5:0] == 6'b010011))? mem_value:
                      ((is_rtype && (fe_inst_reg[5:0] == 6'b010000)) && (HI_wen == 1)) ? HI_wdata:
                      ((is_rtype && (fe_inst_reg[5:0] == 6'b010010)) && (LO_wen == 1)) ? LO_wdata:
                      (is_rtype && (fe_inst_reg[5:0] == 6'b010000))        ? HI_rdata:
                      (is_rtype && (fe_inst_reg[5:0] == 6'b010010))        ? LO_rdata:
                                                                           de_rf_rdata1;




    assign SignExtend = {{16{fe_inst_reg[15]}}, fe_inst_reg[15:0]};
    assign ZeroExtend = {{16'b0}, fe_inst_reg[15:0]};

    assign de_fwd_rdata2 = ((~exe_is_store) && (exe_inst[31:26]!=6'b000010) && (exe_inst[31:27]!=5'b00010) && ((is_rtype) || (de_br_is_bneq) || (is_store)) && (exe_dest != 5'b0) && (de_rf_raddr2 == exe_dest)) ? exe_value : 
                           ((~mem_is_store) && (mem_inst[31:26]!=6'b000010) && (mem_inst[31:27]!=5'b00010) && ((is_rtype) || (de_br_is_bneq) || (is_store)) && (mem_dest != 5'b0) && (de_rf_raddr2 == mem_dest)) ? mem_value :
                           (((is_rtype) || (de_br_is_bneq) || (is_store)) && (|wb_rf_wen/*wb_rf_wen == 4'b1111*/) && (wb_rf_waddr!=5'b0) && (de_rf_raddr2 == wb_rf_waddr)) ? wb_rf_wdata : 
                                                                                                                                                               de_rf_rdata2;

    assign de_vsrc2 = (is_rtype)? de_fwd_rdata2:
                      (fe_inst_reg[31:26]==6'b001100 ||
                       fe_inst_reg[31:26]==6'b001101 ||
                       fe_inst_reg[31:26]==6'b001110)? ZeroExtend:    //ANDI, ORI
                                                       SignExtend;

    assign div_x = de_vsrc1;
    assign div_y = de_vsrc2;


    assign ALUOp = (is_rtype) ? 3'b010:  //R-type
                   (is_store) ? 3'b000:  //SW
                   (is_load)  ? 3'b000:  //LW
                   (fe_inst_reg[31:26]==6'b001001) ? 3'b000:  //ADDIU
                   (fe_inst_reg[31:26]==6'b001010) ? 3'b011:  //SLTI
                   (fe_inst_reg[31:26]==6'b001011) ? 3'b100:  //SLTIU
                   (fe_inst_reg[31:26]==6'b001111) ? 3'b101:  //LUI
                   (fe_inst_reg[31:26]==6'b001000) ? 3'b000:  //ADDI
                   (fe_inst_reg[31:26]==6'b001100) ? 3'b001:  //ANDI
                   (fe_inst_reg[31:26]==6'b001101) ? 3'b110:  //ORI
                   (fe_inst_reg[31:26]==6'b001110) ? 3'b111:  //XORI
                                                     3'b010;
    assign signedop = (fe_inst_reg[31:26]==6'b001000) ? 1 : 0; //ADDI
    assign de_out_op = ALUOp;

    wire gez;
    wire gtz;

    wire de_br_bgeltz;
    wire de_br_bgtlez;

    assign equal = (de_vsrc1 == de_fwd_rdata2) ? 1 : 0;
    assign gez = (~de_vsrc1[31]) ? 1 : 0;  //~gez == ltz
    assign gtz = (~de_vsrc1[31] & (de_vsrc1!=32'b0)) ? 1 : 0;  //~gtz == lez

    assign de_br_is_j    = (fe_inst_reg[31:27] == 5'b00001) ? 1 : 0; //JAL or J
    assign de_br_is_jr   = (is_rtype && fe_inst_reg[5:1] == 6'b00100) ? 1 : 0;
    assign de_br_bgtlez = (fe_inst_reg[31:27] == 5'b00011 ) ? 1 : 0;
    assign de_br_bgeltz = (fe_inst_reg[31:26] == 6'b000001) ? 1 : 0;
    assign de_br_is_br  = de_br_is_bneq | de_br_bgtlez | de_br_bgeltz;

    assign de_saveal = (fe_inst_reg[31:26] == 6'b000011)               //JAL
                     | (de_br_bgeltz & fe_inst_reg[20] == 1'b1)        //BGEZAL or BLTZAL
                     | (de_br_is_jr  & fe_inst_reg[ 0] == 1'b1);       //JALR
                       
    assign de_br_taken = de_br_is_bneq & (equal ^ fe_inst_reg[26])     //BNE or BEQ
                        |de_br_bgeltz  & (~(gez ^ fe_inst_reg[16]))    //BGEZ or BLTZ
                        |de_br_bgtlez  & (~(gtz ^ fe_inst_reg[26]));   //BGTZ or BLEZ
    assign de_br_offset = fe_inst_reg[15:0];
    assign de_br_index  = fe_inst_reg[25:0];
    assign de_br_target = de_vsrc1;

endmodule //decode_stage