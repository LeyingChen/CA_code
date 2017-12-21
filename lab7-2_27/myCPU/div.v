module div(
	input         resetn,
    input         div_clk,
    input         div,
    input         div_signed,

	input  [31:0] x, //x/y
	input  [31:0] y,
//	output [31:0] s, //shang
//    output [31:0] r, //remainder
    output [63:0] result,
    output        complete
);

wire [31:0] s; //shang
wire [31:0] r; //remainder

reg  [ 5:0] step;
wire        x_sig;
wire        y_sig;
wire        s_sig;
wire        r_sig;
reg         div_signed_reg;
reg         s_sig_reg;
reg         r_sig_reg;
wire [31:0] x1;
wire [31:0] y1;

wire [63:0] A;
wire [63:0] B;
reg  [63:0] A_reg;
reg  [63:0] B_reg;
reg  [31:0] s_reg;
wire [31:0] s_reg_next;

wire [63:0] dif;
wire        dif_sig;

wire [31:0] s1;
wire [31:0] r1;


always @(posedge div_clk) begin
	if (~resetn) begin
	    step <= 6'b0;
	end
	else if(~div && step==0) begin
	    step <= 6'b0;
	end
	else begin
	    step <= (step + 1)%34;
	end
end
assign complete = (step == 6'd33);

assign x_sig = x[31];
assign y_sig = y[31];
assign s_sig = x_sig ^ y_sig;
assign r_sig = x_sig;

always @(posedge div_clk) begin
	if (~resetn) begin
	    s_sig_reg <= 1'b0;
	    r_sig_reg <= 1'b0;
	    div_signed_reg <= 1'b0;
	end
	else if(div && step==0) begin
	    s_sig_reg <= s_sig;
        r_sig_reg <= r_sig;
        div_signed_reg <= div_signed;
	end
end

assign x1 = (div_signed) ? ({32{x_sig}} ^ x) + x_sig : x;
assign y1 = (div_signed) ? ({32{y_sig}} ^ y) + y_sig : y;


assign A = {32'b0, x1};
assign B = { 1'b0, y1, 31'b0};

assign dif = A_reg - B_reg;
assign dif_sig = dif[63];
assign s_reg_next = {s_reg[30:0], ~dif_sig};

always @(posedge div_clk) begin
	if (~resetn) begin
	    A_reg <= 32'b0;
	    B_reg <= 32'b0;
	    s_reg <= 32'b0;
	end
	else if (step==6'b0) begin
	    A_reg <= A;
	    B_reg <= B;		
	end
	else begin
		A_reg <= (dif_sig) ? A_reg : dif;
		B_reg <= B_reg >> 1;
		s_reg <= s_reg_next;
	end
end


assign s1 = s_reg;
assign r1 = A_reg[31:0];
assign s = (div_signed_reg) ? ({32{s_sig_reg}} ^ s1) + s_sig_reg : s1;
assign r = (div_signed_reg) ? ({32{r_sig_reg}} ^ r1) + r_sig_reg : r1;

assign result = {s, r};
endmodule