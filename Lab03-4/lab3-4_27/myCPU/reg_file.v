module reg_file(
	input clk,
	input resetn,
	input [4:0] waddr,
	input [4:0] raddr1,
	input [4:0] raddr2,
	input [3:0] wen,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);

	// TODO: insert your code      
    reg [31:0] r [31:0];  // 32 32-bits registers;
    integer i;
    //wire wdata_en;
    /*assign wdata_en = {({8{wen[3]}} & wdata[31:24]), ({8{wen[2]}} & wdata[23:16]), 
                        ({8{wen[1]}} & wdata[15:8]), ({8{wen[0]}} & wdata[7:0])};
      */  
    always @ (posedge clk) begin
        if(~resetn) begin
            for(i=0; i<=31; i=i+1) r[i] <= 0; // Reset all registers to 0;
        end
        
        if(waddr!=0) begin
           if(wen[3]) r[waddr][31:24] <= wdata[31:24];
           if(wen[2]) r[waddr][23:16] <= wdata[23:16];
           if(wen[1]) r[waddr][15: 8] <= wdata[15: 8];
           if(wen[0]) r[waddr][ 7: 0] <= wdata[ 7: 0];
        end else if(waddr == 0) r[0] <= 0; //No.0 register keeps 0;
    end
        
    assign rdata1 = r[raddr1];  // Read without the clock;
    assign rdata2 = r[raddr2];
   
endmodule