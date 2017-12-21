
module writeback_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [ 2:0] mem_out_op,      //control signals used in WB stage
    input  wire [ 4:0] mem_dest,        //reg num of dest operand
    input  wire [31:0] mem_value,       //mem_stage final result

    output wire [ 3:0] wb_rf_wen,
    output wire [ 4:0] wb_rf_waddr,
    output wire [31:0] wb_rf_wdata,

    input  wire [31:0] mem_pc,          //pc @memory_stage
    input  wire [31:0] mem_inst,        //instr code @memory_stage
    output wire [31:0] wb_pc,

    output wire        HI_wen,
    output wire [31:0] HI_wdata,
    output wire        LO_wen,
    output wire [31:0] LO_wdata,

    input  wire [63:0] mul_result,
    input  wire [63:0] mul_div_result,
    input  wire        complete,
    input  wire [ 3:0] load_wen,
    input  wire        exc_handler_reg
);
    //registers for input signal
    reg [ 2:0] mem_out_op_reg;
    reg [ 4:0] mem_dest_reg;
    reg [31:0] mem_value_reg;
    reg [31:0] mem_pc_reg;
    reg [31:0] mem_inst_reg;
    reg [ 3:0] load_wen_reg;
    reg        exc_handler_reg2;
    reg        exc_handler_reg3;
    reg        exc_handler_reg4;

    always @(posedge clk) begin
      if(~resetn) begin
        mem_out_op_reg <= 3'b0;
        mem_dest_reg <= 5'b0;
        mem_value_reg <= 32'h0;
        mem_pc_reg <= 32'hbfc00000;
        mem_inst_reg <= 32'h0;
        load_wen_reg <= 4'b0;
        exc_handler_reg2 <= 1'b0;
        exc_handler_reg3 <= 1'b0;
        exc_handler_reg4 <= 1'b0;
      end
      else begin
        mem_out_op_reg <= mem_out_op;
        mem_dest_reg <= mem_dest;
        mem_value_reg <= mem_value;
        mem_pc_reg <= mem_pc;
        mem_inst_reg <= mem_inst;
        load_wen_reg <= load_wen;
        exc_handler_reg2 <= exc_handler_reg;
        exc_handler_reg3 <= exc_handler_reg2;
        exc_handler_reg4 <= exc_handler_reg3;
      end
    end

    wire wb_is_rtype;
    wire wb_is_load;
    wire wb_is_cp0;
    wire wb_is_mtc0;
    wire wb_is_mfc0;

    assign wb_is_rtype = (mem_inst_reg[31:26] == 6'b000000) ? 1 : 0;
    assign wb_is_load = (mem_inst_reg[31:29] == 3'b100) ? 1 : 0;
    assign wb_is_cp0 = (mem_inst_reg[31:26] == 6'b010000)? 1 : 0; 
    assign wb_is_mtc0 = (mem_inst_reg[25:21] == 5'b00100)? 1 : 0;
    assign wb_is_mfc0 = (mem_inst_reg[25:21] == 5'b00000)? 1 : 0;

    
    assign wb_rf_wen = (exc_handler_reg2)? 4'b0000:
                       (mem_inst_reg[31:0] == 32'b000000) ? 4'b0000:
                       (wb_is_rtype) ? 4'b1111:   //R-type including JALR
                       (wb_is_load)  ? load_wen_reg:   //LW
                       (mem_inst_reg[31:26] == 6'b001001) ? 4'b1111:   //ADDIU
                       (mem_inst_reg[31:26] == 6'b001010) ? 4'b1111:   //SLTI
                       (mem_inst_reg[31:26] == 6'b001011) ? 4'b1111:   //SLTIU
                       (mem_inst_reg[31:26] == 6'b001111) ? 4'b1111:   //LUI
                       (mem_inst_reg[31:26] == 6'b000011) ? 4'b1111:   //JAL
                       (mem_inst_reg[31:26] == 6'b001000) ? 4'b1111:   //ADDI
                       (mem_inst_reg[31:26] == 6'b001100) ? 4'b1111:   //ANDI
                       (mem_inst_reg[31:26] == 6'b001101) ? 4'b1111:   //ORI
                       (mem_inst_reg[31:26] == 6'b001110) ? 4'b1111:   //XORI
                       (mem_inst_reg[31:21] == 11'b01000000000) ? 4'b1111:       //MFC0
                       (mem_inst_reg[31:26] == 6'b000001 & mem_inst_reg[20]) ? 4'b1111: //BGEZAL and BLTZAL
                                                            4'b0000;

    assign wb_pc = mem_pc_reg;
    assign wb_rf_waddr = mem_dest_reg;            //JAL is considered in de and exe stage
    assign wb_rf_wdata = mem_value_reg;

    wire is_mthi;
    wire is_mtlo;
    wire is_mul;
    wire is_div;

    assign is_mthi = (wb_is_rtype && mem_inst_reg[5:0] == 6'b010001) ? 1 : 0;
    assign is_mtlo = (wb_is_rtype && mem_inst_reg[5:0] == 6'b010011) ? 1 : 0;
    assign is_mul  = (wb_is_rtype && mem_inst_reg[5:1] == 5'b01100)  ? 1 : 0;
    assign is_div  = (wb_is_rtype && mem_inst_reg[5:1] == 5'b01101)  ? 1 : 0;

    assign HI_wen   = (~exc_handler_reg3 && ~exc_handler_reg4)&&(is_mthi | is_mul | (is_div & complete));
    assign LO_wen   = (~exc_handler_reg3 && ~exc_handler_reg4)&&(is_mtlo | is_mul | (is_div & complete));
    assign HI_wdata = ({32{is_mthi}} & mem_value_reg) | ({32{is_mul}} & mul_result[63:32]) | ({32{is_div}} & mul_div_result[31: 0]);
    assign LO_wdata = ({32{is_mtlo}} & mem_value_reg) | ({32{is_mul}} & mul_result[31: 0]) | ({32{is_div}} & mul_div_result[63:32]);
endmodule //writeback_stage