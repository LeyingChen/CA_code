module mult(
	input  resetn,
	input  mul_clk,
    input  mul_signed,
    input  exe_mul,

	input  [31:0] x,
	input  [31:0] y,
	output [63:0] result
);

    wire [32:0] x_e;
    wire [32:0] y_e;
    wire [65:0] result_e;

    assign x_e = /*{33{exe_mul}} & */{{mul_signed & x[31]}, x};
    assign y_e = /*{33{exe_mul}} & */{{mul_signed & y[31]}, y};

    mymult multiplier(
      .CLK     (mul_clk       ), // input wire CLK
      .A       (x_e           ), // input wire [32 : 0] A
      .B       (y_e           ), // input wire [32 : 0] B
      .P       (result_e      )      // output wire [65 : 0] P
    );

    assign result = result_e[63:0];

endmodule