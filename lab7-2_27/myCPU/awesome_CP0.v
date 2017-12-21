module awesome_CP0(
	input         clk,
	input         resetn,
    input  [ 4:0] cp0_waddr,
	input  [31:0] cp0_wdata,
    input  [ 4:0] cp0_raddr,
	output [31:0] cp0_rdata,

    input  [ 7:0] exc_sig,
    input         de_is_eret,
    input         de_is_mfc0,
    input         de_mtc0_wen,
    input  [31:0] wt_epc,
    input  [31:0] bad_addr,
    input         delay_slot,
    input  [5 :0] hw_int,
    output        int_sig,

    input         de_is_tlbp,
    input         de_is_tlbr,
    input         de_is_tlbwi,

    output [ 4:0] index_min,
    output [31:0] entryhi_min,
    output [31:0] entrylo0_min,
    output [31:0] entrylo1_min,
    output [31:0] pagemask_min,

    input  [31:0] index_mout,
    input  [31:0] entryhi_mout,
    input  [31:0] entrylo0_mout,
    input  [31:0] entrylo1_mout,
    input  [31:0] pagemask_mout
);

    wire [31:0] cp0_cause;
    wire [31:0] cp0_status;
    wire [31:0] cp0_epc;
    wire [31:0] cp0_compare;
    wire [31:0] cp0_count;
    wire [31:0] cp0_badvaddr;
    wire        timer_int;
    wire        exc_handler = exc_sig || int_sig;

    reg  [31:0] cp0_epc_reg;
    reg  [31:0] cp0_compare_reg;
    reg  [31:0] cp0_count_reg;
    reg  [31:0] cp0_badvaddr_reg;
    reg         de_is_eret_reg;
    reg         de_is_eret_reg2;

    always @(posedge clk) begin
        if (~resetn) begin
            de_is_eret_reg  <= 1'b0;
            de_is_eret_reg2 <= 1'b0;
        end else begin
            de_is_eret_reg  <= de_is_eret;
            de_is_eret_reg2 <= de_is_eret_reg;
        end
    end

    //#12 status
    wire status_CU0 = 1'b0;
    wire status_BEV = 1'b1;
    reg  status_IM7;
    reg  status_IM6;
    reg  status_IM5;
    reg  status_IM4;
    reg  status_IM3;
    reg  status_IM2;
    reg  status_IM1;
    reg  status_IM0;
    reg  status_EXL;
    reg  status_IE;

    assign cp0_status = {3'b0, status_CU0, 5'b0, status_BEV, 6'b0, status_IM7,
                         status_IM6, status_IM5, status_IM4, status_IM3, status_IM2,
                         status_IM1, status_IM0, 6'b0, status_EXL, status_IE};
    //#13 cause
    reg        cause_BD;
    reg        cause_TI;
    reg        cause_IP7;
    reg        cause_IP6;
    reg        cause_IP5;
    reg        cause_IP4;
    reg        cause_IP3;
    reg        cause_IP2;
    reg        cause_IP1;
    reg        cause_IP0;
    reg  [4:0] cause_ExcCode;

    assign timer_int = cause_TI;
    assign cp0_cause = {cause_BD, cause_TI, 14'b0, cause_IP7, cause_IP6, cause_IP5, 
                        cause_IP4, cause_IP3, cause_IP2, cause_IP1, cause_IP0, 1'b0, 
                        cause_ExcCode, 2'b0};

    assign cp0_epc = cp0_epc_reg;
    assign cp0_compare = cp0_compare_reg;
    assign cp0_count = cp0_count_reg;
    assign cp0_badvaddr = cp0_badvaddr_reg;

    reg  [18:0] entryhi_VPN2;
    reg  [ 7:0] entryhi_ASID;
    wire [31:0] cp0_entryhi;
    assign cp0_entryhi = {entryhi_VPN2, 5'b0, entryhi_ASID};

    reg  [11:0] pagemask_mask;
    wire [31:0] cp0_pagemask;
    assign cp0_pagemask = {7'b0, pagemask_mask, 13'b0};

    reg  [19:0] entrylo0_PFN;
    reg  [ 2:0] entrylo0_C;
    reg         entrylo0_D;
    reg         entrylo0_V;
    reg         entrylo0_G;
    wire [31:0] cp0_entrylo0;
    assign cp0_entrylo0 = {6'b0, entrylo0_PFN, entrylo0_C, entrylo0_D, entrylo0_V, entrylo0_G};

    reg  [19:0] entrylo1_PFN;
    reg  [ 2:0] entrylo1_C;
    reg         entrylo1_D;
    reg         entrylo1_V;
    reg         entrylo1_G;
    wire [31:0] cp0_entrylo1;
    assign cp0_entrylo1 = {6'b0, entrylo1_PFN, entrylo1_C, entrylo1_D, entrylo1_V, entrylo1_G};

    reg         index_P;
    reg  [ 4:0] index_Index;
    wire [31:0] cp0_index;
    assign cp0_index = {index_P, 26'b0, index_Index};

    assign int_sig = status_IE && (~status_EXL)
                 && (cause_IP7&&status_IM7||cause_IP6&&status_IM6
                   ||cause_IP5&&status_IM5||cause_IP4&&status_IM4
                   ||cause_IP3&&status_IM3||cause_IP2&&status_IM2
                   ||cause_IP1&&status_IM1||cause_IP0&&status_IM0);

    reg count_add_en;
    always @(posedge clk) begin
        count_add_en <= (~resetn)? 1'b0: ~count_add_en;
    end

    always @ (posedge clk) begin
        if(~resetn) begin
            status_IM7 <= 1'b0;
            status_IM6 <= 1'b0;
            status_IM5 <= 1'b0;
            status_IM4 <= 1'b0;
            status_IM3 <= 1'b0;
            status_IM2 <= 1'b0;
            status_IM1 <= 1'b0;
            status_IM0 <= 1'b0;
            status_EXL <= 1'b0;
            status_IE  <= 1'b0;
        end else begin

            if(exc_sig || int_sig) begin
                status_EXL <= 1'b1;
            end else if(de_is_eret_reg2) begin
                status_EXL <= 1'b0;
            end else if (de_mtc0_wen && cp0_waddr == 5'd12) begin
                status_EXL <= cp0_wdata[1];
            end

            if(de_mtc0_wen && cp0_waddr == 5'd12) begin
                status_IM7 <= cp0_wdata[15];
                status_IM6 <= cp0_wdata[14];
                status_IM5 <= cp0_wdata[13];
                status_IM4 <= cp0_wdata[12];
                status_IM3 <= cp0_wdata[11];
                status_IM2 <= cp0_wdata[10];
                status_IM1 <= cp0_wdata[ 9];
                status_IM0 <= cp0_wdata[ 8];
                status_IE  <= cp0_wdata[ 0];
            end

        end
        
        if(~resetn)
            cause_TI <= 1'b0;
        else if(de_mtc0_wen && cp0_waddr == 5'd11)
            cause_TI <= 1'b0;
        else if(~status_EXL && status_IE && cp0_count == cp0_compare)
            cause_TI <= 1'b1; 

        if(~resetn) begin
            cause_BD  <= 1'b0;
            cause_TI  <= 1'b0;
            cause_IP7 <= 1'b0;
            cause_IP6 <= 1'b0;
            cause_IP5 <= 1'b0;
            cause_IP4 <= 1'b0;
            cause_IP3 <= 1'b0;
            cause_IP2 <= 1'b0;
            cause_IP1 <= 1'b0;
            cause_IP0 <= 1'b0;
            cause_ExcCode <= 5'b0;
        end else begin
            if(de_mtc0_wen && cp0_waddr == 5'd13) begin
                //cause_TI  <= cp0_wdata[30];
                cause_IP1 <= cp0_wdata[9];
                cause_IP0 <= cp0_wdata[8];
                cause_ExcCode <= cp0_wdata[6:2];
            end
            cause_ExcCode <= (int_sig)? 5'h0:
                             (exc_sig[4])? 5'h4:
                             (exc_sig[3])? 5'ha:
                             (exc_sig[0])? 5'hc:
                             (exc_sig[1])? 5'h8:
                             (exc_sig[2])? 5'h9:
                             (exc_sig[5])? 5'h4:
                             (exc_sig[6])? 5'h5:cause_ExcCode;

            if((exc_sig || int_sig) && delay_slot) begin
                cause_BD <= 1'b1;
            end else if(de_is_eret) begin
                cause_BD <= 1'b0;
            end
            //cause_BD <= /*delay_slot*/1'b0;

            cause_IP7 <= hw_int[5] || timer_int;
            cause_IP6 <= hw_int[4];
            cause_IP5 <= hw_int[3];
            cause_IP4 <= hw_int[2];
            cause_IP3 <= hw_int[1];
            cause_IP2 <= hw_int[0];
        end

        if(~resetn) begin
            cp0_epc_reg <= 32'hbfc00000;
        end else begin
            if(de_mtc0_wen && cp0_waddr == 5'd14)
                cp0_epc_reg <= cp0_wdata;
            else if(~status_EXL&&(exc_sig[4]))
                cp0_epc_reg <= bad_addr;
            else if(~status_EXL&&(cause_IP1&&status_IM1||cause_IP0&&status_IM0))
                cp0_epc_reg <= wt_epc+4;
            else if(~status_EXL&&(exc_sig || int_sig))
                cp0_epc_reg <= wt_epc;
        end

        if(~resetn)
            cp0_compare_reg <= 32'h0;
        else if(de_mtc0_wen && cp0_waddr == 5'd11)
                cp0_compare_reg <= cp0_wdata;

        if(~resetn)
            cp0_count_reg <= 32'h0;
        else if(de_mtc0_wen && cp0_waddr == 5'd9)
            cp0_count_reg <= cp0_wdata;
        else if(count_add_en)
            cp0_count_reg <= cp0_count_reg + 1'b1;

        if(~resetn) begin
            cp0_badvaddr_reg <= 32'h0;
        end else begin
            cp0_badvaddr_reg <= (bad_addr)?bad_addr:cp0_badvaddr_reg;
        end

        if(~resetn) begin
            entryhi_VPN2 <= 19'b0;
            entryhi_ASID <= 8'b0;
        end else if(de_mtc0_wen && cp0_waddr == 5'd10) begin
            entryhi_VPN2 <= cp0_wdata[31:13];
            entryhi_ASID <= cp0_wdata[ 7: 0];
        end else if(de_is_tlbr) begin
        	entryhi_VPN2 <= entryhi_mout[31:13];
        	entryhi_ASID <= entryhi_mout[ 7: 0];
        end

        if(~resetn) begin
            pagemask_mask <= 12'b0;
        end else if(de_mtc0_wen && cp0_waddr == 5'd5) begin
            pagemask_mask <= cp0_wdata[24:13];
        end else if(de_is_tlbr) begin
        	pagemask_mask <= pagemask_mout[24:13];
        end

        if(~resetn) begin
            entrylo0_PFN <= 20'b0;
            entrylo0_C <= 3'b0;
            entrylo0_D <= 1'b0;
            entrylo0_V <= 1'b0;
            entrylo0_G <= 1'b0;
        end else if(de_mtc0_wen && cp0_waddr == 5'd2) begin
            entrylo0_PFN <= cp0_wdata[25:6];
            entrylo0_C <= cp0_wdata[5:3];
            entrylo0_D <= cp0_wdata[2];
            entrylo0_V <= cp0_wdata[1];
            entrylo0_G <= cp0_wdata[0];
        end else if(de_is_tlbr) begin
        	entrylo0_PFN <= entrylo0_mout[25:6];
            entrylo0_C <= entrylo0_mout[5:3];
            entrylo0_D <= entrylo0_mout[2];
            entrylo0_V <= entrylo0_mout[1];
            entrylo0_G <= entrylo0_mout[0];
        end

        if(~resetn) begin
            entrylo1_PFN <= 20'b0;
            entrylo1_C <= 3'b0;
            entrylo1_D <= 1'b0;
            entrylo1_V <= 1'b0;
            entrylo1_G <= 1'b0;
        end else if(de_mtc0_wen && cp0_waddr == 5'd3) begin
            entrylo1_PFN <= cp0_wdata[25:6];
            entrylo1_C <= cp0_wdata[5:3];
            entrylo1_D <= cp0_wdata[2];
            entrylo1_V <= cp0_wdata[1];
            entrylo1_G <= cp0_wdata[0];
        end else if(de_is_tlbr) begin
        	entrylo1_PFN <= entrylo1_mout[25:6];
            entrylo1_C <= entrylo1_mout[5:3];
            entrylo1_D <= entrylo1_mout[2];
            entrylo1_V <= entrylo1_mout[1];
            entrylo1_G <= entrylo1_mout[0];
        end

        if(~resetn) begin
            index_P <= 1'b0;
            index_Index <= 5'b0;
        end else if(de_mtc0_wen && cp0_waddr == 5'd0) begin
            index_Index <= cp0_wdata[4:0];
        end else if(de_is_tlbp) begin
        	index_Index <= index_mout[4:0];
        	index_P <= index_mout[31];
        end
    end

    assign index_min = cp0_index[4:0];
    assign entryhi_min = cp0_entryhi;
    assign entrylo0_min = cp0_entrylo0;
    assign entrylo1_min = cp0_entrylo1;
    assign pagemask_min = cp0_pagemask;

    assign cp0_rdata = ({32{de_is_mfc0 && cp0_raddr==5'd12}} & cp0_status)  |
                       ({32{de_is_mfc0 && cp0_raddr==5'd13}} & cp0_cause)   |
                       ({32{de_is_mfc0 && cp0_raddr==5'd14}} & cp0_epc)     |
                       ({32{de_is_mfc0 && cp0_raddr==5'd8 }} & cp0_badvaddr)|
                       ({32{de_is_mfc0 && cp0_raddr==5'd9 }} & cp0_count)   |
                       ({32{de_is_mfc0 && cp0_raddr==5'd11}} & cp0_compare) |
                       ({32{de_is_mfc0 && cp0_raddr==5'd10}} & cp0_entryhi) |
                       ({32{de_is_mfc0 && cp0_raddr==5'd2 }} & cp0_entrylo0)|
                       ({32{de_is_mfc0 && cp0_raddr==5'd3 }} & cp0_entrylo1)|
                       ({32{de_is_mfc0 && cp0_raddr==5'd5 }} & cp0_pagemask)|
                       ({32{de_is_mfc0 && cp0_raddr==5'd0 }} & cp0_index)   |
                       ({32{de_is_eret}} & cp0_epc);
endmodule