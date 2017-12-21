
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

    output wire        div_signed,
    output wire [31:0] div_x,
    output wire [31:0] div_y,
    output wire        div,
    input  wire        complete,
    input  wire [63:0] div_result,

    output wire        de_mul,
    input  wire        exe_mul,
    input  wire        mem_mul,

    output wire [ 4:0] cp0_raddr,
    input  wire [31:0] cp0_rdata,
    output wire [ 4:0] cp0_waddr,
    output wire [31:0] cp0_wdata,
////////////////////////////////////////////////////

    output wire        de_is_mfc0,
    output wire        de_mtc0_wen,
    output wire        de_is_eret,
    output wire [31:0] de_eret_target,
    output wire        de_inst_exist,
    output wire        de_is_syscall,
    output wire        de_is_break,

    output wire        signedop,
    input  wire        exc_handler,
    input  wire        exc_handler_reg,
///////////////////////////////////////////////////

    input  wire        inst_block,
    input  wire        data_block,
    input  wire        data_data_ok,
    input  wire        axi_block,
    input  wire [31:0] data_rdata,
    output wire        de_ds_cancel
);

    //registers for input signal
    reg [31:0] fe_inst_reg;
    reg [31:0] fe_pc_reg;
    reg [31:0] cp0_wdata_reg;
    reg        data_data_ok_reg;


    always @(posedge clk) begin                                                                             
        if(~resetn) begin 
            data_data_ok_reg <= 1'b0;
        end
        else begin
            data_data_ok_reg <= data_data_ok;
        end
    end

    wire [ 5:0] op          = de_inst[31:26];
    wire [ 4:0] rs          = de_inst[25:21];
    wire [ 4:0] rt          = de_inst[20:16];  
    wire [ 4:0] rd          = de_inst[15:11];  
    wire [ 4:0] sa          = de_inst[10: 6]; 
    wire [ 5:0] func        = de_inst[ 5: 0]; 
    wire [15:0] imm         = de_inst[15: 0]; 
    wire [15:0] offset      = de_inst[15: 0];
    wire [25:0] instr_index = de_inst[25: 0];

    wire exe_is_load;
    wire mem_is_load;
    wire exe_is_store;
    wire mem_is_store;

    ///////////////////////////////////
    wire de_is_add   = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100000);
    wire de_is_addi  = (op == 6'b001000);
    wire de_is_addu  = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100001);
    wire de_is_addiu = (op == 6'b001001);
    wire de_is_sub   = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100010);
    wire de_is_subu  = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100011);
    wire de_is_slt   = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b101010);
    wire de_is_slti  = (op == 6'b001010);
    wire de_is_sltu  = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b101011);
    wire de_is_sltiu = (op == 6'b001011);
    wire de_is_div   = (op == 6'b000000) && (rd == 5'b00000) && (sa == 5'b00000) && (func == 6'b011010);
    wire de_is_divu  = (op == 6'b000000) && (rd == 5'b00000) && (sa == 5'b00000) && (func == 6'b011011);
    wire de_is_mult  = (op == 6'b000000) && (rd == 5'b00000) && (sa == 5'b00000) && (func == 6'b011000);
    wire de_is_multu = (op == 6'b000000) && (rd == 5'b00000) && (sa == 5'b00000) && (func == 6'b011001);
    wire de_is_and   = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100100);
    wire de_is_andi  = (op == 6'b001100);
    wire de_is_lui   = (op == 6'b001111) && (rs == 5'b00000);
    wire de_is_nor   = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100111);
    wire de_is_or    = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100101);
    wire de_is_ori   = (op == 6'b001101);
    wire de_is_xor   = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b100110);
    wire de_is_xori  = (op == 6'b001110);
    wire de_is_sllv  = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b000100);
    wire de_is_sll   = (op == 6'b000000) && (rs == 5'b00000) && (func == 6'b000000);
    wire de_is_srav  = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b000111);
    wire de_is_sra   = (op == 6'b000000) && (rs == 5'b00000) && (func == 6'b000011);
    wire de_is_srlv  = (op == 6'b000000) && (sa == 5'b00000) && (func == 6'b000110);
    wire de_is_srl   = (op == 6'b000000) && (rs == 5'b00000) && (func == 6'b000010);

    wire de_br_is_bneq = (op[5:1] == 5'b00010);
    wire de_br_bgtlez  = (op[5:1] == 5'b00011)  && (rt == 5'b0);
    wire de_br_bgeltz  = (op      == 6'b000001) && (rt[3:1] == 3'b0);
    wire de_br_is_jalr = (op == 6'b000000) && (rt == 5'b0) && (sa == 5'b0) && (func == 6'b001001);
    wire de_is_j       = (op[5:1] == 5'b00001); 
    wire de_is_jr      = (op == 6'b000000) && (rt == 5'b0) && (rd == 5'b0) && (sa == 5'b0) && (func == 6'b001000)  || de_br_is_jalr;
    assign de_br_is_j  = de_is_j && (~exc_handler&&~exc_handler_reg);                             //JAL or J
    assign de_br_is_jr = de_is_jr && (~exc_handler&&~exc_handler_reg);


    wire de_is_mfhi   = (op == 6'b000000) && (rs == 5'b0) && (rt == 5'b0) && (sa == 5'b0) && (func == 6'b010000);
    wire de_is_mflo   = (op == 6'b000000) && (rs == 5'b0) && (rt == 5'b0) && (sa == 5'b0) && (func == 6'b010010);
    wire de_is_mthi   = (op == 6'b000000) && (rt == 5'b0) && (rd == 5'b0) && (sa == 5'b0) && (func == 6'b010001);
    wire de_is_mtlo   = (op == 6'b000000) && (rt == 5'b0) && (rd == 5'b0) && (sa == 5'b0) && (func == 6'b010011);

    assign de_is_break  = (op == 6'b000000) && (func == 6'b001101);
    assign de_is_syscall= (op == 6'b000000) && (func == 6'b001100);

    wire de_is_store = (op[5:2] == 4'b1010) || (op == 6'b101110);
    wire de_is_load  = (op[5:3] == 3'b100)  && (op[2:0] != 3'b111);

    assign de_is_eret  = (op == 6'b010000) && (rs == 5'b10000) && (rt == 5'b0) && (rd == 5'b0) && (sa == 5'b0) && (func == 6'b011000);
    assign de_is_mfc0  = (op == 6'b010000) && (rs == 5'b00000) && (sa == 5'b0) && (func[5:3] == 3'b0);
    assign de_is_mtc0  = (op == 6'b010000) && (rs == 5'b00100) && (sa == 5'b0) && (func[5:3] == 3'b0);
    assign de_mtc0_wen = de_is_mtc0 && (~exc_handler&&~exc_handler_reg) && ~(exe_inst[31:25] == 7'b0100001);//exe is eret

    wire de_is_rtype = (op == 6'b0);

    assign div_signed = de_is_div;
    assign div        = (~exc_handler&&~exc_handler_reg)&&(de_is_div||de_is_divu);
    assign de_mul     = de_is_mult || de_is_multu;

    assign exe_is_store = (exe_inst[31:28] == 4'b1010) || (exe_inst[31:26] == 6'b101110);
    assign mem_is_store = (mem_inst[31:28] == 4'b1010) || (mem_inst[31:26] == 6'b101110);
    assign exe_is_load = (exe_inst[31:29] == 3'b100);
    assign mem_is_load = (mem_inst[31:29] == 3'b100);

    wire exe_is_div = (exe_inst[31:26] == 6'b0) && (exe_inst[5:1] == 5'b01101);
    wire mem_is_div = (mem_inst[31:26] == 6'b0) && (mem_inst[5:1] == 5'b01101);
    wire mem_is_mul = (mem_inst[31:26] == 6'b0) && (mem_inst[5:1] == 5'b01100);
    reg mem_is_mul_reg;
    reg complete_keep;
    always @(posedge clk) begin
      mem_is_mul_reg <= (!resetn) ? 1'b0: mem_is_mul;
    end
    /*reg mem_is_mul_reg2;
    always @(posedge clk) begin
      mem_is_mul_reg2 <= (!resetn) ? 1'b0: mem_is_mul_reg;
    end*/

    always @(posedge clk) begin
      complete_keep <= (!resetn) ? 1'b0:
                       (complete) ? 1'b1:
                       (~exe_is_div) ? 1'b0: complete_keep;
    end

    wire de_delay_slot;
    assign de_delay_slot = exe_inst[31:28] == 4'b0001 || exe_inst[31:26] == 6'b000001 || exe_inst[31:27] == 5'b00001  ||
                        exe_inst[31:26] == 6'b0 && exe_inst[5:1] == 5'b00100;

    assign de_ds_cancel = de_delay_slot && (de_is_syscall || de_is_break);

    assign de_block =  /* */(~exc_handler&&~exc_handler_reg) && ((exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr1 == exe_dest) && ~data_data_ok_reg) 
                     ||((de_is_rtype || de_br_is_bneq || de_is_store) && (exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr2 == exe_dest) && ~data_data_ok_reg)
                     //
                     || ((mem_inst[31:26]==6'b100010 || mem_inst[31:26]==6'b100110) && (mem_dest != 5'b0) && (de_rf_raddr1 == mem_dest) && ~data_data_ok_reg) 
                     || ((de_is_rtype || (de_br_is_bneq) || (de_is_store)) && (mem_inst[31:26]==6'b100010 || mem_inst[31:26]==6'b100110) && (mem_dest != 5'b0) && (de_rf_raddr2 == mem_dest) && ~data_data_ok_reg)
                     //
                     || ((exe_inst[31:26]==6'b000000) && (exe_inst[5:1] == 5'b01101) && (~complete) && (~complete_keep) && ~exc_handler_reg)
                     || ((exe_inst[31:26]==6'b000000) && (exe_inst[5:1] == 5'b01100) && (de_is_mfhi || de_is_mflo) && ~(mem_is_mul_reg));

    assign de_inst_exist = de_is_add||de_is_addi||de_is_addu||de_is_addiu
                         ||de_is_sub||de_is_subu||de_is_slt||de_is_slti||de_is_sltu
                         ||de_is_sltiu||de_is_div||de_is_divu||de_is_mult||de_is_multu
                         ||de_is_and||de_is_andi||de_is_lui||de_is_nor||de_is_or||de_is_ori
                         ||de_is_xor||de_is_xori||de_is_sllv||de_is_sll||de_is_srav||de_is_sra
                         ||de_is_srlv||de_is_srl||de_br_is_bneq||de_br_bgeltz||de_br_bgtlez
                         ||de_is_j||de_is_jr||de_is_mfhi||de_is_mflo||de_is_mthi||de_is_mtlo
                         ||de_is_break||de_is_syscall||de_is_load||de_is_store
                         ||de_is_eret||de_is_mfc0||de_is_mtc0;

    always @(posedge clk) begin                                                                             
      if(~resetn) begin
        fe_inst_reg <= 32'h0;
        fe_pc_reg <= 32'hbfc00000;
      end
      else if(de_block||inst_block||data_block||axi_block) begin
        fe_inst_reg <= fe_inst_reg;
        fe_pc_reg <= fe_pc_reg;         
      end
      else begin
        fe_inst_reg <= fe_inst;
        fe_pc_reg <= fe_pc;
      end   
    end

    always @(posedge clk) begin
    	if (~resetn)
    	    cp0_wdata_reg <= 32'h0;
    	else
    		cp0_wdata_reg <= cp0_wdata;
    end

    wire [31:0] SignExtend;
    wire [31:0] ZeroExtend;
    wire        equal;
    wire [ 3:0] ALUOp;

    wire [31:0] de_fwd_rdata2;
    reg  [63:0] div_result_reg;

    always @(posedge clk) begin
        div_result_reg <= (~resetn)? 64'b0:
                          (complete) ? div_result:
                          (~exe_is_div) ? div_result: div_result_reg;
    end
    
    assign de_pc = fe_pc_reg;
    assign de_inst = fe_inst_reg;

    assign de_rf_raddr1 = (de_is_mfc0) ? 5'b0 : rs;
    assign de_rf_raddr2 = rt;
    assign cp0_raddr    = (de_is_eret) ? 5'd14 : rd;
    assign cp0_waddr    = rd;
    assign cp0_wdata    = de_fwd_rdata2;


    assign de_dest = (de_is_rtype ) ? rd:
                     (de_saveal) ? 5'd31:                  //let's pretend JALR's rd == 5'd31
                                   rt;

    assign de_st_value = de_fwd_rdata2;
    assign de_vsrc1 = (~exc_handler&&~exc_handler_reg) && (((exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr1 == exe_dest))) ? data_rdata: 
                      ((~exe_is_store) && (exe_inst[31:26]!=6'b000010) && (exe_inst[31:27]!=5'b00010) && (exe_dest != 5'b0) && (de_rf_raddr1 == exe_dest)) ? exe_value : 
                      ((~mem_is_store) && (mem_inst[31:26]!=6'b000010) && (mem_inst[31:27]!=5'b00010) && (mem_dest != 5'b0) && (de_rf_raddr1 == mem_dest)) ? mem_value :
                      ((|wb_rf_wen/*wb_rf_wen == 4'b1111*/) && (wb_rf_waddr!=0) && (de_rf_raddr1 == wb_rf_waddr)) ? wb_rf_wdata :
                      (de_is_mfhi && (exe_inst[31:26] == 6'b000000 && exe_inst[5:0] == 6'b010001))? exe_value:
                      (de_is_mflo && (exe_inst[31:26] == 6'b000000 && exe_inst[5:0] == 6'b010011))? exe_value:
                      (de_is_mfhi && complete) ? div_result[31: 0]:
                      (de_is_mflo && complete) ? div_result[63:32]:
                      (de_is_mfhi && complete_keep && exe_is_div) ? div_result_reg[31: 0]:
                      (de_is_mflo && complete_keep && exe_is_div) ? div_result_reg[63:32]:
                      (de_is_mfhi && (mem_inst[31:26] == 6'b000000 && mem_inst[5:0] == 6'b010001))? mem_value:
                      (de_is_mflo && (mem_inst[31:26] == 6'b000000 && mem_inst[5:0] == 6'b010011))? mem_value:
                      (de_is_mfhi && (mem_is_div||mem_is_mul)) ? mem_value:
                      (de_is_mflo && (mem_is_div||mem_is_mul)) ? mem_value:
                      (de_is_mfhi && (HI_wen == 1)) ? HI_wdata:
                      (de_is_mflo && (LO_wen == 1)) ? LO_wdata:
                      (de_is_mfhi)        ? HI_rdata:
                      (de_is_mflo)        ? LO_rdata:
                                            de_rf_rdata1;

    assign SignExtend = {{16{imm[15]}}, imm};
    assign ZeroExtend = {{16'b0}, imm};

    assign de_fwd_rdata2 = (de_is_rtype || de_br_is_bneq || de_is_store) && (exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr2 == exe_dest) ? data_rdata: 
                           ((~exe_is_store && exe_inst[31:26]!=6'b000010 && exe_inst[31:27]!=5'b00010 && (de_is_rtype || de_br_is_bneq || de_is_store ||de_is_mtc0) && exe_dest != 5'b0 && de_rf_raddr2 == exe_dest)) ? exe_value : 
                           ((~mem_is_store) && (mem_inst[31:26]!=6'b000010) && (mem_inst[31:27]!=5'b00010) && ((de_is_rtype) || (de_br_is_bneq) || de_is_store||de_is_mtc0) && (mem_dest != 5'b0) && (de_rf_raddr2 == mem_dest)) ? mem_value :
                           (((de_is_rtype) || (de_br_is_bneq) || (de_is_store) || de_is_mtc0) && (|wb_rf_wen/*wb_rf_wen == 4'b1111*/) && (wb_rf_waddr!=5'b0) && (de_rf_raddr2 == wb_rf_waddr)) ? wb_rf_wdata : 
                                                                                                                                                               de_rf_rdata2;

    assign de_vsrc2 = //(de_is_rtype || de_br_is_bneq || de_is_store) && (exe_is_load) && (exe_dest != 5'b0) && (de_rf_raddr2 == exe_dest) ? data_rdata:
                      (de_is_rtype)   ? de_fwd_rdata2:
                      (de_is_mfc0 && exe_inst[31:21] == 11'b01000000100 &&(exe_inst[15:11]==cp0_raddr))? cp0_wdata_reg:
                      (de_is_mfc0) ? cp0_rdata: 
                      (de_is_andi || de_is_ori || de_is_xori)? ZeroExtend:    //ANDI, ORI
                                                               SignExtend;

    assign div_x = de_vsrc1;
    assign div_y = de_vsrc2;

    assign ALUOp = (de_is_rtype) ? 3'b010:  //R-type
                   (de_is_store) ? 3'b000:  //SW
                   (de_is_load)  ? 3'b000:  //LW
                   (de_is_mfc0)  ? 3'b000:  //MTC0 MFC0
                   (de_is_addiu) ? 3'b000:  //ADDIU
                   (de_is_slti)  ? 3'b011:  //SLTI
                   (de_is_sltiu) ? 3'b100:  //SLTIU
                   (de_is_lui)   ? 3'b101:  //LUI
                   (de_is_addi)  ? 3'b000:  //ADDI
                   (de_is_andi)  ? 3'b001:  //ANDI
                   (de_is_ori)   ? 3'b110:  //ORI
                   (de_is_xori)  ? 3'b111:  //XORI
                                   3'b010;
    assign signedop = de_is_add || de_is_addi || de_is_sub;
    assign de_out_op = ALUOp;

    wire gez;
    wire gtz;

    assign equal = (de_vsrc1 == de_fwd_rdata2) ? 1 : 0;
    assign gez = (~de_vsrc1[31]) ? 1 : 0;  //~gez == ltz
    assign gtz = (~de_vsrc1[31] & (de_vsrc1!=32'b0)) ? 1 : 0;  //~gtz == lez


    assign de_br_is_br  = de_br_is_bneq | de_br_bgtlez | de_br_bgeltz;

    assign de_saveal = (op == 6'b000011)               //JAL
                     || (de_br_bgeltz & rt[4] == 1'b1)        //BGEZAL or BLTZAL
                     || de_br_is_jalr;       //JALR
                       
    assign de_br_taken = (de_br_is_bneq & (equal ^ op[0])     //BNE or BEQ
                       ||de_br_bgeltz  & (~(gez ^ rt[0]))    //BGEZ or BLTZ
                       ||de_br_bgtlez  & (~(gtz ^ op[0])))&&(~exc_handler&&~exc_handler_reg);   //BGTZ or BLEZ
    assign de_br_offset = offset;
    assign de_br_index  = instr_index;
    assign de_br_target = de_vsrc1;
    assign de_eret_target = cp0_rdata;
    
endmodule //decode_stage