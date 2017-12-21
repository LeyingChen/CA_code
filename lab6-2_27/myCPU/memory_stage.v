
module memory_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [ 2:0] exe_out_op,      //control signals used in MEM, WB stages
    input  wire [ 4:0] exe_dest,        //reg num of dest operand
    input  wire [31:0] exe_value,       //alu result from exe_stage or other intermediate 
                                        //value for the following stages

//  input  wire [31:0] data_sram_rdata,

    input  wire [31:0] data_rdata,

    output wire [ 2:0] mem_out_op,      //control signals used in WB stage
    output wire [ 4:0] mem_dest,        //reg num of dest operand
    output wire [31:0] mem_value,       //mem_stage final result

    input  wire [31:0] exe_pc,          //pc @execute_stage
    input  wire [31:0] exe_inst,        //instr code @execute_stage
    output wire [31:0] mem_pc,          //pc @memory_stage
    output wire [31:0] mem_inst,        //instr code @memory_stage

    output wire [63:0] mul_div_result,
    output reg  [63:0] mul_div_result_reg,
    input  wire [63:0] mul_result,
    input  wire [63:0] div_result,
    input  wire        exe_mul,
    output wire        mem_mul,
    output wire [ 3:0] load_wen,

    input  wire        de_block,

    input  wire        inst_block,
    input  wire        data_block,
    input  wire        axi_block,
    input  wire [31:0] de_inst,
    input  wire        complete,
    input  wire [31:0] wb_inst
);

    //registers for input signal
    reg [ 2:0] exe_out_op_reg;
    reg [ 4:0] exe_dest_reg;
    reg [31:0] exe_value_reg;
    reg [31:0] exe_pc_reg;
    reg [31:0] exe_inst_reg;
    reg        exe_mul_reg;
    reg [31:0] data_rdata_reg;
    //wire [63:0] mul_div_result;
    
    wire is_mul;
    wire is_div;
    wire mem_is_load;
    wire mem_is_div = (mem_inst[31:26] == 6'b0) && (mem_inst[5:1] == 5'b01101);

    assign is_mul = (mem_inst[31:26] == 6'b0) && (mem_inst[5:1] == 5'b01100);
    wire em_is_mul = is_mul || (exe_inst[31:26] == 6'b0) && (exe_inst[5:1] == 5'b01100);
    assign is_div = (mem_inst[31:26] == 6'b0) && (mem_inst[5:1] == 5'b01101);
    wire em_is_div = is_div || (exe_inst[31:26] == 6'b0) && (exe_inst[5:1] == 5'b01101);

    assign mul_div_result = {64{is_div}} & div_result | {64{is_mul}} & mul_result;
    assign mem_is_load = (mem_inst[31:29] == 3'b100)  ? 1 : 0;

    always @(posedge clk) begin
        if (~resetn) begin
          exe_mul_reg <= 1'b0;
        end
        else begin
          exe_mul_reg <= exe_mul;
        end
    end
    assign mem_mul = exe_mul_reg;


    always @(posedge clk) begin
      if (~resetn) begin
        exe_out_op_reg <= 3'b0;
        exe_dest_reg <= 5'b0;
        exe_value_reg <= 32'h0;
        exe_pc_reg <= 32'hbfc00000;
        exe_inst_reg <= 32'h0;
        data_rdata_reg <= 32'h0;
        mul_div_result_reg <= 64'b0;
        //exe_mul_reg <= 1'b0;
      end
      else if (inst_block||data_block||axi_block) begin
        exe_out_op_reg <= exe_out_op_reg;
        exe_dest_reg <= exe_dest_reg;
        exe_value_reg <= exe_value_reg;
        exe_pc_reg <= exe_pc_reg;
        exe_inst_reg <= exe_inst_reg;
        data_rdata_reg <= data_rdata_reg;
        mul_div_result_reg <= mul_div_result_reg;
      end
      else begin
        exe_out_op_reg <= exe_out_op;
        exe_dest_reg <= exe_dest;
        exe_value_reg <= exe_value;
        exe_pc_reg <= exe_pc;
        exe_inst_reg <= exe_inst;
        data_rdata_reg <= data_rdata;
        mul_div_result_reg <= {64{em_is_div}} & div_result | {64{em_is_mul}} & mul_result/*mul_div_result*/;
      end
    end
    
    wire [31:0] unaligned_wdata;
    //wire [ 3:0] load_wen;

    unaligned_ld unaligned_ld1(
      .h6_inst(mem_inst[31:26]),
      .vaddr(mem_exe_value[1:0]),
      .memdata(data_rdata_reg),
      .wdata(unaligned_wdata),
      .wen(load_wen)
    );
    wire wb_is_mul = (wb_inst[31:26] == 6'b0) && (wb_inst[5:1] == 5'b01100);
    
    wire [31:0] mem_exe_value;

    reg  [31:0] mem_hi_data;
    reg  [31:0] mem_lo_data;

    always @(posedge clk) begin
        mem_hi_data <= (~resetn)? 32'b0:
                       (complete) ? div_result[31:0]:
                       (is_mul && ~wb_is_mul) ? mul_result[63:32]:
                       /*(~exe_is_div) ? mul_div_result[31:0]:*/ mem_hi_data;
    end

    always @(posedge clk) begin
        mem_lo_data <= (~resetn)? 32'b0:
                       (complete) ? div_result[63:32]:
                       (is_mul && ~wb_is_mul) ? mul_result[31:0]:
                       /*(~exe_is_div) ? mul_div_result[63:32]: */mem_lo_data;
    end

    wire de_is_mfhi = (de_inst[31:26] == 6'b000000) && (de_inst[5:0] == 6'b010000);
    wire de_is_mflo = (de_inst[31:26] == 6'b000000) && (de_inst[5:0] == 6'b010010);

    assign mem_pc = exe_pc_reg;
    assign mem_inst = exe_inst_reg;
    assign mem_out_op = exe_out_op_reg;
    assign mem_dest = exe_dest_reg;
    assign mem_exe_value = exe_value_reg;
    assign mem_value = (mem_is_load) ? unaligned_wdata : 
                       (mem_is_div && de_is_mfhi) ? mem_hi_data:
                       (mem_is_div && de_is_mflo) ? mem_lo_data:
                       (is_mul && de_is_mfhi) ? mem_hi_data:
                       (is_mul && de_is_mflo) ? mem_lo_data:mem_exe_value;
endmodule //memory_stage


module unaligned_ld(
    input  [ 5:0] h6_inst,
    input  [ 1:0] vaddr,
    input  [31:0] memdata,
    output [31:0] wdata,
    output [ 3:0] wen
);
    wire addr_0;
    wire addr_1;
    wire addr_2;
    wire addr_3;

    wire is_lb;
    wire is_lbu;
    wire is_lh;
    wire is_lhu;
    wire is_lwl;
    wire is_lwr;

    wire is_lwl1; //1 Byte
    wire is_lwl2; //2 Byte
    wire is_lwl3; //3 Byte
    wire is_l4;   //4 Byte
    wire is_lwr1; //according to byte changed instead of addr
    wire is_lwr2;
    wire is_lwr3;

    assign is_lb  = (h6_inst == 6'b100000) ? 1 : 0;
    assign is_lbu = (h6_inst == 6'b100100) ? 1 : 0;
    assign is_lh  = (h6_inst == 6'b100001) ? 1 : 0;
    assign is_lhu = (h6_inst == 6'b100101) ? 1 : 0;
    assign is_lwl = (h6_inst == 6'b100010) ? 1 : 0;
    assign is_lwr = (h6_inst == 6'b100110) ? 1 : 0;

    assign addr_0 = (vaddr == 2'd0) ? 1 : 0;
    assign addr_1 = (vaddr == 2'd1) ? 1 : 0;
    assign addr_2 = (vaddr == 2'd2) ? 1 : 0;
    assign addr_3 = (vaddr == 2'd3) ? 1 : 0;

    wire [7:0] lbdata;
    wire [15:0] lhdata;
    assign lbdata = addr_0 ? memdata[7:0]:
                    addr_1 ? memdata[15:8]:
                    addr_2 ? memdata[23:16]:
                    addr_3 ? memdata[31:24]:
                             8'b0;
    assign lhdata = addr_0 ? memdata[15:0]:
                    addr_2 ? memdata[31:16]:
                             16'b0;

    assign is_l4   = (h6_inst == 6'b100011 || (is_lwl && addr_3) || (is_lwr && addr_0)) ? 1 : 0;
    assign is_lwl1 = (is_lwl && addr_0) ? 1 : 0;
    assign is_lwl2 = (is_lwl && addr_1) ? 1 : 0;
    assign is_lwl3 = (is_lwl && addr_2) ? 1 : 0;
    assign is_lwr1 = (is_lwr && addr_3) ? 1 : 0;
    assign is_lwr2 = (is_lwr && addr_2) ? 1 : 0;
    assign is_lwr3 = (is_lwr && addr_1) ? 1 : 0;

    assign wdata = (is_lb)  ? {{24{lbdata[7]}}, lbdata}:
                   (is_lbu) ? {24'b0, lbdata}:
                   (is_lh)  ? {{16{lhdata[15]}}, lhdata}:
                   (is_lhu) ? {16'b0, lhdata}:
                   (is_l4) ? memdata:
                   (is_lwl1) ? {memdata[ 7: 0], 24'b0}:
                   (is_lwl2) ? {memdata[15: 0], 16'b0}:
                   (is_lwl3) ? {memdata[23: 0],  8'b0}:
                   (is_lwr3) ? {8'b0, memdata[31:8]}:
                   (is_lwr2) ? {16'b0, memdata[31:16]}:
                   (is_lwr1) ? {24'b0, memdata[31:24]}:
                               32'b0;

    assign wen = (is_lb || is_lbu || is_lh || is_lhu || is_l4) ? 4'b1111:
                 (is_lwl1) ? 4'b1000:
                 (is_lwl2) ? 4'b1100:
                 (is_lwl3) ? 4'b1110:
                 (is_lwr1) ? 4'b0001:
                 (is_lwr2) ? 4'b0011:
                 (is_lwr3) ? 4'b0111:
                             4'b0000;
endmodule