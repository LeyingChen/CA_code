/* 
 * ALU_v1.1 using a better coding style
 * having set overflow for exception
 * having expanded op from 3-bit to 4-bit 
 * having added nor operation
 * having changed the relazition of sltu
 * updated by Chen Leying on Oct.12th, 2017
 */

module decoder_4_16(
    input  [ 3:0] in,
    output [15:0] out
);
    assign out[0]  = (in == 4'd0);
    assign out[1]  = (in == 4'd1);
    assign out[2]  = (in == 4'd2);
    assign out[3]  = (in == 4'd3);
    assign out[4]  = (in == 4'd4);
    assign out[5]  = (in == 4'd5);
    assign out[6]  = (in == 4'd6);
    assign out[7]  = (in == 4'd7);
    assign out[8]  = (in == 4'd8);
    assign out[9]  = (in == 4'd9);
    assign out[10] = (in == 4'd10);
    assign out[11] = (in == 4'd11);
    assign out[12] = (in == 4'd12);
    assign out[13] = (in == 4'd13);
    assign out[14] = (in == 4'd14);
    assign out[15] = (in == 4'd15);
endmodule

module alu(
	input [31:0] A,
	input [31:0] B,
	input [ 3:0] ALUop,
	input [ 4:0] sa,     //input for SLL
    input        imm,

	output Zero,
    output Overflow,     //only available under signed-operation
	output [31:0] Result
);
	wire [15:0] alu_ctrl;
	decoder_4_16 sign_de(.in(ALUop),.out(alu_ctrl));//decode aluop first
   
    wire alu_add;
    wire alu_sub;
    wire alu_slt;
    wire alu_sltu;
    wire alu_and;
    wire alu_or;
    wire alu_sll;
    wire alu_lui;
    /******ADDED*******/
    wire alu_nor;
    wire alu_xor;
    wire alu_srl;
    wire alu_sra;

    assign alu_and  = alu_ctrl[0];
    assign alu_or   = alu_ctrl[1];
    assign alu_add  = alu_ctrl[2];
    assign alu_sll  = alu_ctrl[3];
    assign alu_sltu = alu_ctrl[4];
    assign alu_lui  = alu_ctrl[5];
    assign alu_sub  = alu_ctrl[6];
    assign alu_slt  = alu_ctrl[7];
    /*******ADDED********/
    assign alu_nor  = alu_ctrl[8];
    assign alu_xor  = alu_ctrl[9];
    assign alu_srl  = alu_ctrl[10];
    assign alu_sra  = alu_ctrl[11];

    wire [31:0] and_result;
    wire [31:0] or_result;
    wire [31:0] add_sub_result;
    wire [31:0] sll_result;
    wire [31:0] sltu_result;
    wire [31:0] lui_result;
    wire [31:0] slt_result;
    /******ADDED********/
    wire [31:0] nor_result;
    wire [31:0] xor_result;
    wire [31:0] sr_result;
    wire [63:0] sr64_result;

    assign and_result = A & B;
    assign or_result  = A | B;
    assign nor_result = ~or_result;
    assign xor_result = A ^ B;
    assign lui_result = {B[15:0], 16'b0};

    /*assign result for */
    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire        adder_cin;
    wire [31:0] adder_result;
    wire        adder_cout;
    wire        is_sub;
    wire        add_or_sub;
    wire        oftemp;

    assign is_sub = alu_sub | alu_slt | alu_sltu;
    assign add_or_sub = is_sub | alu_add;
    assign adder_a = A;
    assign adder_b = B ^ {32{is_sub}};
    assign adder_cin = is_sub;
    assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;
    assign oftemp = adder_cout ^ adder_result[31];
    assign add_sub_result = adder_result;

    assign slt_result[31:1] = 31'd0;
    assign slt_result[0]    = (A[31] & ~B[31]) | (~(A[31] ^ B[31]) & adder_result[31]);

    assign sltu_result[31:1] = 31'd0;
    assign sltu_result[0]    = ~adder_cout;

    wire [4:0] s;
    assign s = (imm)? sa : A[4:0];

    assign sll_result = B << s;
    //assign srl_result = B >> s;
    assign sr64_result = {{32{alu_sra & B[31]}}, B[31:0]} >> s;
    assign sr_result = sr64_result[31:0];

    assign Zero = (Result == 0) ? 1 : 0;
    assign Overflow = (add_or_sub)? oftemp : 0;    //not avaliable when it is not add or sub

    assign Result =   ({32{alu_add|alu_sub}} & add_sub_result)
    				| ({32{alu_and}}         & and_result)
    				| ({32{alu_or}}          & or_result )
    				| ({32{alu_slt}}         & slt_result)
    				| ({32{alu_sltu}}        & sltu_result)
    				| ({32{alu_sll}}         & sll_result)
    				| ({32{alu_lui}}         & lui_result)
                    | ({32{alu_nor}}         & nor_result)
                    | ({32{alu_xor}}         & xor_result)
                    | ({32{alu_srl|alu_sra}} & sr_result);
                    //| ({32{alu_sra}}  & sra_result);
endmodule