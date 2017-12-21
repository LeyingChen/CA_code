module HILO_reg(
	input         clk,
	input         resetn,
	input         wen,
	input  [31:0] wdata,
	output [31:0] rdata
);

	// TODO: insert your code      
     reg [31:0] r;  // 32 32-bits registers;
        
    always @ (posedge clk) begin
        if(~resetn)
            r <= 0; // Reset all registers to 0;
        else begin
            if(wen) r <= wdata; // Write under the clock when wen=1;
        end
    end
    assign rdata = r;
endmodule