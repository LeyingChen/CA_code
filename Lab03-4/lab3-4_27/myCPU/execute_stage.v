/*
 * Adjust data_sram_wen & data_sram_wdata
 * to unaligned store instruction.
 * updated by Chen Leying on Oct.30th, 2017
 */


module execute_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [ 2:0] de_out_op,       //control signals used in EXE, MEM, WB stages
    input  wire [ 4:0] de_dest,         //reg No. of dest operand, zero if no dest
    input  wire [31:0] de_vsrc1,        //value of source operand 1
    input  wire [31:0] de_vsrc2,        //value of source operand 2
    input  wire [31:0] de_st_value,     //value stored to memory

    output wire [ 2:0] exe_out_op,      //control signals used in MEM, WB stages
    output wire [ 4:0] exe_dest,        //reg num of dest operand
    output wire [31:0] exe_value,       //alu result from exe_stage or other intermediate 
                                        //value for the following stages

//  output wire        data_sram_en,
    output wire [ 3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,


    input  wire [31:0] de_pc,           //pc @decode_stage
    input  wire [31:0] de_inst,         //instr code @decode_stage
    output wire [31:0] exe_pc,          //pc @execute_stage
    output wire [31:0] exe_inst,         //instr code @execute_stage

    input  wire de_block,
    input  wire de_saveal,

    output wire [31:0] mul_x,
    output wire [31:0] mul_y,

//    output wire        div_signed,
    output wire        mul_signed,
    input  wire        de_mul,
    output wire        exe_mul
);

    reg [ 2:0] de_out_op_reg;
    reg [ 4:0] de_dest_reg;
    reg [31:0] de_vsrc1_reg;
    reg [31:0] de_vsrc2_reg;
    reg [31:0] de_st_value_reg;
    reg [31:0] de_pc_reg;
    reg [31:0] de_inst_reg;
    reg [ 4:0] de_rf_raddr1_reg;
    reg [ 4:0] de_rf_raddr2_reg;
    reg        de_saveal_reg;
    reg        de_mul_reg;

    always @(posedge clk) begin
      if(~resetn) begin
        de_out_op_reg <= 3'b0;
        de_dest_reg <= 5'b0;
        de_vsrc1_reg <= 32'h0;
        de_vsrc2_reg <= 32'h0;
        de_st_value_reg <= 32'h0;
        de_pc_reg <= 32'hbfc00000;
        de_inst_reg <= 32'h0;
        de_saveal_reg <= 1'b0;
        de_mul_reg <= 1'b0;
      end
      else if(de_block) begin
        de_out_op_reg <= 3'b0;
        de_dest_reg <= 5'b0;
        de_vsrc1_reg <= de_vsrc1_reg;
        de_vsrc2_reg <= de_vsrc2_reg;
        de_st_value_reg <= 32'b0;
        de_pc_reg <= de_pc_reg;
        de_inst_reg <= de_inst_reg;///////////////////////////////////////////
        de_saveal_reg <= 1'b0; /////////////////////////////////////
        de_mul_reg <= 1'b0;
      end
      else begin
        de_out_op_reg <= de_out_op;
        de_dest_reg <= de_dest;
        de_vsrc1_reg <= de_vsrc1;
        de_vsrc2_reg <= de_vsrc2;
        de_st_value_reg <= de_st_value;
        de_pc_reg <= de_pc;
        de_inst_reg <= de_inst;
        de_saveal_reg <= de_saveal;
        de_mul_reg <= de_mul;
      end  
    end

    wire [ 3:0] ALUop;  
    wire        Zero;
    wire        Overflow;
    wire [31:0] Result;
    wire        signedop;                   //ready for overflow exception
    wire        imm;

    assign exe_pc = de_pc_reg;
    assign exe_inst = de_inst_reg;
    assign exe_out_op = de_out_op_reg;
    assign exe_dest = de_dest_reg;
    assign exe_value = (de_saveal_reg)? de_pc_reg + 8 : Result;

    assign mul_x = de_vsrc1_reg;
    assign mul_y = de_vsrc2_reg;
    assign mul_signed = (exe_inst[31:26]==6'b000000 && exe_inst[5:0] == 6'b011000)? 1 : 0;
    assign exe_mul = de_mul_reg;
    
    ALUControl ALUControl1(                 //ALU control ALUOp->ALUop
      .ALUOp(de_out_op_reg),
      .Ins_reg(de_inst_reg[5:0]),
      .ALUop(ALUop),
      .is_signed(signedop),
      .imm(imm)
    );

    alu alu1(
      .A(de_vsrc1_reg), 
      .B(de_vsrc2_reg), 
      .ALUop(ALUop), 
      .sa(de_inst_reg[10:6]),
      .imm(imm),
      .Zero(Zero), 
      .Overflow(Overflow), 
      .Result(Result)
    );

    unaligned_st unaligned_st1(
      .h6_inst(exe_inst[31:26]),
      .vaddr(exe_value[1:0]),
      .regdata(de_st_value_reg),
      .wdata(data_sram_wdata),
      .wen(data_sram_wen)
    );
    
    assign data_sram_addr= exe_value;

endmodule //execute_stage

module ALUControl(
    input  [2:0] ALUOp,
    input  [5:0] Ins_reg,
    output reg [3:0] ALUop,
    output reg is_signed,        //ready for overflow exception
    output reg imm
);   
    always @(*) begin //assign ALUop signal
      case(ALUOp)
        3'b000: ALUop = 4'b0010; //ADDIU, ADDI, LW or SW
        3'b001: ALUop = 4'b0000; //ANDI
        3'b011: ALUop = 4'b0111; //SLTI
        3'b100: ALUop = 4'b0100; //SLTIU
        3'b101: ALUop = 4'b0101; //LUI
        3'b110: ALUop = 4'b0001; //ORI
        3'b111: ALUop = 4'b1001; //XORI
        3'b010: begin                                       //R-type
                  case(Ins_reg)
                    6'b100001: ALUop = 4'b0010; //ADDU
                    6'b100010: ALUop = 4'b0110; //SUB
                    6'b100100: ALUop = 4'b0000; //AND
                    6'b100101: ALUop = 4'b0001; //OR
                    6'b101010: ALUop = 4'b0111; //SLT
                    6'b000000: ALUop = 4'b0011; //SLL
                    6'b100000: ALUop = 4'b0010; //ADD
                    6'b100011: ALUop = 4'b0110; //SUBU
                    6'b101011: ALUop = 4'b0100; //SLTU
                    6'b100111: ALUop = 4'b1000; //NOR
                    6'b100110: ALUop = 4'b1001; //XOR
                    6'b000100: ALUop = 4'b0011; //SLLV
                    6'b000111: ALUop = 4'b1011; //SRAV
                    6'b000011: ALUop = 4'b1011; //SRA
                    6'b000110: ALUop = 4'b1010; //SRLV
                    6'b000010: ALUop = 4'b1010; //SRL
                    6'b010000: ALUop = 4'b0010; //MFHI
                    6'b010010: ALUop = 4'b0010; //MFLO
                    6'b010001: ALUop = 4'b0010; //MTHI
                    6'b010011: ALUop = 4'b0010; //MTLO
                    default:   ALUop = 4'b0000; 
                  endcase
                end
        default: ALUop = 4'b0;
      endcase
    end

    always @(*) begin //assign is_signed signal
      if (ALUOp == 3'b010) begin
          case(Ins_reg)
            6'b100010: is_signed = 1'b1;
            6'b100000: is_signed = 1'b1;
            default:   is_signed = 1'b0;
          endcase
      end else begin
        is_signed = 1'b0;
      end
    end

    always @(*) begin //assign imm signal
      if (ALUOp == 3'b010) begin
        case(Ins_reg)
          6'b000000: imm = 1'b1;
          6'b000011: imm = 1'b1;
          6'b000010: imm = 1'b1;
          default:   imm = 1'b0;
        endcase
      end else begin
        imm = 1'b0;
      end
    end
endmodule

module unaligned_st(
    input  [ 5:0] h6_inst,
    input  [ 1:0] vaddr,
    input  [31:0] regdata,
    output [31:0] wdata,
    output [ 3:0] wen
);
    wire is_swl;
    wire is_swr;
    wire addr_0;
    wire addr_1;
    wire addr_2;
    wire addr_3;

    wire is_sb;
    wire is_sh;
    wire is_swl1; //1 Byte
    wire is_swl2; //2 Byte
    wire is_swl3; //3 Byte
    wire is_s4;   //4 Byte
    wire is_swr1; //according to byte changed instead of addr
    wire is_swr2;
    wire is_swr3;

    assign is_swl = (h6_inst == 6'b101010) ? 1 : 0;
    assign is_swr = (h6_inst == 6'b101110) ? 1 : 0;
    assign addr_0 = (vaddr == 2'd0) ? 1 : 0;
    assign addr_1 = (vaddr == 2'd1) ? 1 : 0;
    assign addr_2 = (vaddr == 2'd2) ? 1 : 0;
    assign addr_3 = (vaddr == 2'd3) ? 1 : 0;

    assign is_s4   = (h6_inst == 6'b101011 || (is_swl && addr_3) || (is_swr && addr_0)) ? 1 : 0;
    assign is_sb   = (h6_inst == 6'b101000) ? 1 : 0;
    assign is_sh   = (h6_inst == 6'b101001) ? 1 : 0;
    assign is_swl1 = (is_swl && addr_0) ? 1 : 0;
    assign is_swl2 = (is_swl && addr_1) ? 1 : 0;
    assign is_swl3 = (is_swl && addr_2) ? 1 : 0;
    assign is_swr1 = (is_swr && addr_3) ? 1 : 0;
    assign is_swr2 = (is_swr && addr_2) ? 1 : 0;
    assign is_swr3 = (is_swr && addr_1) ? 1 : 0;

    wire [31:0] sbdata;
    wire [31:0] shdata;
    assign sbdata = addr_0 ? {24'b0, regdata[7:0]}:
                    addr_1 ? {16'b0, regdata[7:0],  8'b0}:
                    addr_2 ? { 8'b0, regdata[7:0], 16'b0}:
                    addr_3 ? {regdata[7:0], 24'b0}:
                             32'b0;
    assign shdata = addr_0 ? {16'b0, regdata[15:0]}:
                    addr_2 ? {regdata[15:0], 16'b0}:
                             32'b0;

    assign wen = (is_s4) ? 4'b1111:
                 (is_sh) ? {{2{addr_2}}, {2{addr_0}}}:
                 (is_sb) ? {addr_3, addr_2, addr_1, addr_0}:
                 (is_swl3) ? 4'b0111:
                 (is_swl2) ? 4'b0011:
                 (is_swl1) ? 4'b0001:
                 (is_swr1) ? 4'b1000:
                 (is_swr2) ? 4'b1100:
                 (is_swr3) ? 4'b1110:
                             4'b0000;

    assign wdata = (is_s4)   ? regdata:
                   (is_sb)   ? sbdata:
                   (is_sh)   ? shdata:
                   (is_swl1) ? {24'b0, regdata[31:24]}:
                   (is_swl2) ? {16'b0, regdata[31:16]}:
                   (is_swl3) ? { 8'b0, regdata[31: 8]}:
                   (is_swr1) ? {regdata[ 7: 0], 24'b0}:
                   (is_swr2) ? {regdata[15: 0], 16'b0}:
                   (is_swr3) ? {regdata[23: 0],  8'b0}:
                                   32'b0;
endmodule