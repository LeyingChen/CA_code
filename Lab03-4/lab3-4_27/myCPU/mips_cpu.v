module mycpu_top(
	input  resetn,
	input  clk,

	output        inst_sram_en,
	output [ 3:0] inst_sram_wen,
	output [31:0] inst_sram_addr,
	output [31:0] inst_sram_wdata,
	input  [31:0] inst_sram_rdata,

	output        data_sram_en,
	output [ 3:0] data_sram_wen,
	output [31:0] data_sram_addr,
	output [31:0] data_sram_wdata,
	input  [31:0] data_sram_rdata,

	output [31:0] debug_wb_pc,
	output [ 3:0] debug_wb_rf_wen,
	output [ 4:0] debug_wb_rf_wnum,
	output [31:0] debug_wb_rf_wdata
);

	//TODO: Insert your design of MIPS CPU here

    wire [31:0] nextpc;
    wire [31:0] fe_pc;
    wire [31:0] fe_inst;

    wire [ 4:0] de_rf_raddr1;
    wire [ 4:0] de_rf_raddr2;
    wire [31:0] de_rf_rdata1;
    wire [31:0] de_rf_rdata2;
    wire        de_br_taken;    
    wire        de_br_is_br;    
    wire        de_br_is_j;     
    wire        de_br_is_jr;    
    wire [15:0] de_br_offset;   
    wire [25:0] de_br_index;    
    wire [31:0] de_br_target;   
    wire [ 2:0] de_out_op;      
    wire [ 4:0] de_dest;         
    wire [31:0] de_vsrc1;        
    wire [31:0] de_vsrc2;        
    wire [31:0] de_st_value;
    wire [31:0] de_pc;
    wire [31:0] de_inst;

    wire [ 2:0] exe_out_op;
    wire [ 4:0] exe_dest;
    wire [31:0] exe_value;
    wire [31:0] exe_pc;
    wire [31:0] exe_inst;

    wire [ 2:0] mem_out_op;
    wire [ 4:0] mem_dest;
    wire [31:0] mem_value;
    wire [31:0] mem_pc;
    wire [31:0] mem_inst;

    wire [ 3:0] wb_rf_wen;
    wire [ 4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;
    wire [31:0] wb_pc;

    wire de_block;

    wire de_saveal;

    wire        HI_wen;
    wire [31:0] HI_wdata;
    wire [31:0] HI_rdata;

    wire        LO_wen;
    wire [31:0] LO_wdata;
    wire [31:0] LO_rdata;

    wire        mul_signed;
    wire [63:0] mul_result;

    wire        div;
    wire        div_signed;
    wire [63:0] div_result;
    wire        complete;

    wire [31:0] div_x;
    wire [31:0] div_y;
    wire [31:0] mul_x;
    wire [31:0] mul_y;
    wire [63:0] mul_div_result;
    //wire        div_r;
    wire        de_mul;
    wire        exe_mul;
    wire        mem_mul;
    wire [ 3:0] load_wen;

    assign inst_sram_en = 1'b1;
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    assign data_sram_en = 1'b1;

nextpc_gen nextpc_gen
    (
    .resetn         (resetn         ), //I, 1

    .fe_pc          (fe_pc          ), //I, 32

    .de_br_taken    (de_br_taken    ), //I, 1 
    .de_br_is_br    (de_br_is_br    ), //I, 1
    .de_br_is_j     (de_br_is_j     ), //I, 1
    .de_br_is_jr    (de_br_is_jr    ), //I, 1
    .de_br_offset   (de_br_offset   ), //I, 16
    .de_br_index    (de_br_index    ), //I, 26
    .de_br_target   (de_br_target   ), //I, 32

    .inst_sram_addr (inst_sram_addr ), //O, 32

    .nextpc         (nextpc         ), //O, 32
    .de_block       (de_block       )
    );


fetch_stage fe_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
                                    
    .nextpc         (nextpc         ), //I, 32
                                    
    .inst_sram_rdata(inst_sram_rdata), //I, 32
                                    
    .fe_pc          (fe_pc          ), //O, 32  
    .fe_inst        (fe_inst        ), //O, 32

    .de_block       (de_block       )
    );


decode_stage de_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
                                    
    .fe_inst        (fe_inst        ), //I, 32
                                    
    .de_rf_raddr1   (de_rf_raddr1   ), //O, 5
    .de_rf_rdata1   (de_rf_rdata1   ), //I, 32
    .de_rf_raddr2   (de_rf_raddr2   ), //O, 5
    .de_rf_rdata2   (de_rf_rdata2   ), //I, 32
                                    
    .de_br_taken    (de_br_taken    ), //O, 1
    .de_br_is_br    (de_br_is_br    ), //O, 1
    .de_br_is_j     (de_br_is_j     ), //O, 1
    .de_br_is_jr    (de_br_is_jr    ), //O, 1
    .de_br_offset   (de_br_offset   ), //O, 16
    .de_br_index    (de_br_index    ), //O, 26
    .de_br_target   (de_br_target   ), //O, 32
                                    
    .de_out_op      (de_out_op      ), //O, ??
    .de_dest        (de_dest        ), //O, 5 
    .de_vsrc1       (de_vsrc1       ), //O, 32
    .de_vsrc2       (de_vsrc2       ), //O, 32
    .de_st_value    (de_st_value    ), //O, 32

    .fe_pc          (fe_pc          ), //I, 32
    .de_pc          (de_pc          ), //O, 32
    .de_inst        (de_inst        ), //O, 32 

    .de_block       (de_block       ),

    .wb_rf_wen      (wb_rf_wen      ), //I, 4
    .wb_rf_waddr    (wb_rf_waddr    ), //I, 5
    .wb_rf_wdata    (wb_rf_wdata    ), //I, 32

    .mem_dest       (mem_dest       ), //I, 5
    .mem_value      (mem_value      ), //I, 32
    .mem_inst       (mem_inst       ),

    .exe_dest       (exe_dest       ), //I, 5
    .exe_value      (exe_value      ), //I, 32
    .exe_inst       (exe_inst       ), //I, 32

    .de_saveal      (de_saveal      ), //O, 32

    .HI_rdata       (HI_rdata       ), //I, 32
    .LO_rdata       (LO_rdata       ), //I, 32
    .HI_wdata       (HI_wdata       ), //I, 32  output of wb_stage
    .LO_wdata       (LO_wdata       ), //I, 32
    .HI_wen         (HI_wen         ), //I, 1
    .LO_wen         (LO_wen         ), //I, 1 

    //.mul_signed     (mul_signed     ), //O, 1
    //.div_signed     (div_signed     ), //O, 1
    .div            (div            ), //O, 1
    .div_x          (div_x          ), //O, 32
    .div_y          (div_y          ), //O, 32
    .div_signed     (div_signed     ), //O, 1
    .complete       (complete       ), //I, 1

    .mul_div_result (mul_div_result ), //I, 32
    .de_mul         (de_mul         ), //O, 1
    .exe_mul        (exe_mul        ), //I, 1
    .mem_mul        (mem_mul        )
    );


execute_stage exe_stage
    (
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
                                    
    .de_out_op      (de_out_op      ), //I, ??
    .de_dest        (de_dest        ), //I, 5 
    .de_vsrc1       (de_vsrc1       ), //I, 32
    .de_vsrc2       (de_vsrc2       ), //I, 32
    .de_st_value    (de_st_value    ), //I, 32
                                    
    .exe_out_op     (exe_out_op     ), //O, ??
    .exe_dest       (exe_dest       ), //O, 5
    .exe_value      (exe_value      ), //O, 32

    .data_sram_wen  (data_sram_wen  ), //O, 4
    .data_sram_addr (data_sram_addr ), //O, 32
    .data_sram_wdata(data_sram_wdata), //O, 32


    .de_pc          (de_pc          ), //I, 32
    .de_inst        (de_inst        ), //I, 32
    .exe_pc         (exe_pc         ), //O, 32
    .exe_inst       (exe_inst       ), //O, 32

    .de_block       (de_block       ), //I, 1
    .de_saveal      (de_saveal      ), //I, 1

    .mul_x          (mul_x          ), //O, 32
    .mul_y          (mul_y          ), //O, 32
//    .div_signed     (div_signed     ), //O, 1
    .mul_signed     (mul_signed     ),
    .de_mul         (de_mul         ), //I, 1
    .exe_mul        (exe_mul        )  //O, 1
    );


memory_stage mem_stage(
    .clk            (clk            ), //I, 1
    .resetn         (resetn         ), //I, 1
                                    
    .exe_out_op     (exe_out_op     ), //I, ??
    .exe_dest       (exe_dest       ), //I, 5
    .exe_value      (exe_value      ), //I, 32
                                    
    .data_sram_rdata(data_sram_rdata), //I, 32
                                    
    .mem_out_op     (mem_out_op     ), //O, ??
    .mem_dest       (mem_dest       ), //O, 5
    .mem_value      (mem_value      ), //O, 32


    .exe_pc         (exe_pc         ), //I, 32
    .exe_inst       (exe_inst       ), //I, 32
    .mem_pc         (mem_pc         ), //O, 32
    .mem_inst       (mem_inst       ), //O, 32

    .mul_div_result (mul_div_result ),
    .div_result     (div_result     ),

    .exe_mul        (exe_mul        ),
    .mem_mul        (mem_mul        ),
    .load_wen       (load_wen       )  //O, 4
    );


    writeback_stage wb_stage(
      .clk            (clk            ), //I, 1
      .resetn         (resetn         ), //I, 1
                                    
      .mem_out_op     (mem_out_op     ), //I, ??
      .mem_dest       (mem_dest       ), //I, 5
      .mem_value      (mem_value      ), //I, 32
                                    
      .wb_rf_wen      (wb_rf_wen      ), //O, 1
      .wb_rf_waddr    (wb_rf_waddr    ), //O, 5
      .wb_rf_wdata    (wb_rf_wdata    ), //O, 32

      .mem_pc         (mem_pc         ), //I, 32
      .mem_inst       (mem_inst       ), //I, 32
      .wb_pc          (wb_pc          ), //O, 32

      .HI_wen         (HI_wen         ), //O, 1
      .HI_wdata       (HI_wdata       ), //O, 32
      .LO_wen         (LO_wen         ), //O, 1
      .LO_wdata       (LO_wdata       ), //O, 32
      .mul_result     (mul_result     ), //I, 64
      .mul_div_result (mul_div_result ), //I, 64
      .complete       (complete       ),
      .load_wen       (load_wen       )  //I, 4

    );

    reg_file reg_file1(
      .clk     (clk          ),
      .resetn  (resetn       ), 
      .waddr   (wb_rf_waddr  ), 
      .raddr1  (de_rf_raddr1 ), 
      .raddr2  (de_rf_raddr2 ), 
      .wen     (wb_rf_wen    ), 
      .wdata   (wb_rf_wdata  ),
      .rdata1  (de_rf_rdata1 ),
      .rdata2  (de_rf_rdata2 )
    );

    HILO_reg HI_reg(
      .clk     (clk          ), //I, 1
      .resetn  (resetn       ), //I, 1
      .wen     (HI_wen       ), //I, 1
      .wdata   (HI_wdata     ), //I, 32
      .rdata   (HI_rdata     )  //O, 32
    );

    HILO_reg LO_reg(
      .clk     (clk          ), //I, 1
      .resetn  (resetn       ), //I, 1
      .wen     (LO_wen       ), //I, 1
      .wdata   (LO_wdata     ), //I, 32
      .rdata   (LO_rdata     )  //O, 32
    );

    mult multiplier(
      .resetn      (resetn       ), //I, 1
      .mul_clk     (clk          ), //I, 1
      .mul_signed  (mul_signed   ),
      .exe_mul     (exe_mul      ),
      .x           (mul_x        ), //////////////
      .y           (mul_y        ), //////////////
      .result      (mul_result   )
);

    div divider(
      .resetn      (resetn       ),
      .div_clk     (clk          ),
      .div         (div          ),
      .div_signed  (div_signed   ),
      .x           (div_x        ), //x/y
      .y           (div_y        ),
      .result      (div_result   ), //shang
      //.r           (div_r        ), //remainder
      .complete    (complete     )
);

    assign debug_wb_pc       = wb_pc;
    assign debug_wb_rf_wen   = wb_rf_wen;
    assign debug_wb_rf_wnum  = wb_rf_waddr;
    assign debug_wb_rf_wdata = wb_rf_wdata;

endmodule