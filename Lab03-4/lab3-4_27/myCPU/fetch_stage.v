module fetch_stage(
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] nextpc,

    input  wire [31:0] inst_sram_rdata,

    output reg  [31:0] fe_pc,           //fetch_stage pc
    output wire  [31:0] fe_inst,        //instr code sent from fetch_stage

    input  wire de_block
);

    always @(posedge clk) begin
      if(~resetn) fe_pc <= 32'hbfc00000;
      else fe_pc <= nextpc;
    end

   assign fe_inst = inst_sram_rdata;  

endmodule //fetch_stage