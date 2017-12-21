module encoder_32_5(
    input  [31:0] in,
    output [ 4:0] out
);
    assign out = ({5{in[ 0]}} & 5'd0)  | ({5{in[ 1]}} & 5'd1)  | ({5{in[ 2]}} & 5'd2)  |
                 ({5{in[ 3]}} & 5'd3)  | ({5{in[ 4]}} & 5'd4)  | ({5{in[ 5]}} & 5'd5)  |
                 ({5{in[ 6]}} & 5'd6)  | ({5{in[ 7]}} & 5'd7)  | ({5{in[ 8]}} & 5'd8)  |
                 ({5{in[ 9]}} & 5'd9)  | ({5{in[10]}} & 5'd10) | ({5{in[11]}} & 5'd11) |
                 ({5{in[12]}} & 5'd12) | ({5{in[13]}} & 5'd13) | ({5{in[14]}} & 5'd14) |
                 ({5{in[15]}} & 5'd15) | ({5{in[16]}} & 5'd16) | ({5{in[17]}} & 5'd17) |
                 ({5{in[18]}} & 5'd18) | ({5{in[19]}} & 5'd19) | ({5{in[20]}} & 5'd20) |
                 ({5{in[21]}} & 5'd21) | ({5{in[22]}} & 5'd22) | ({5{in[23]}} & 5'd23) |
                 ({5{in[24]}} & 5'd18) | ({5{in[25]}} & 5'd25) | ({5{in[26]}} & 5'd26) |
                 ({5{in[27]}} & 5'd21) | ({5{in[28]}} & 5'd29) | ({5{in[23]}} & 5'd29) |
                 ({5{in[30]}} & 5'd18) | ({5{in[31]}} & 5'd31);
endmodule

module mmu(
    //input  [31:0] v_addr,
    input         clk,
    input         resetn,

    input  [ 4:0] index_min,
    input  [31:0] entryhi_min,
    input  [31:0] entrylo0_min,
    input  [31:0] entrylo1_min,
    input  [31:0] pagemask_min,

    output [31:0] index_mout,
    output [31:0] entryhi_mout,
    output [31:0] entrylo0_mout,
    output [31:0] entrylo1_mout,
    output [31:0] pagemask_mout,

    input         de_is_tlbr,
    input         de_is_tlbp,
    input         de_is_tlbwi
);

    reg [89:0] tlb_file [31:0];

    always @(posedge clk) begin
    	if (~resetn) begin
    		tlb_file[0] <= 90'b0;
    		tlb_file[1] <= 90'b0;
    		tlb_file[2] <= 90'b0;
    		tlb_file[3] <= 90'b0;
    		tlb_file[4] <= 90'b0;
    		tlb_file[5] <= 90'b0;
    		tlb_file[6] <= 90'b0;
    		tlb_file[7] <= 90'b0;
    		tlb_file[8] <= 90'b0;
    		tlb_file[9] <= 90'b0;
    		tlb_file[10] <= 90'b0;
    		tlb_file[11] <= 90'b0;
    		tlb_file[12] <= 90'b0;
    		tlb_file[13] <= 90'b0;
    		tlb_file[14] <= 90'b0;
    		tlb_file[15] <= 90'b0;
            tlb_file[16] <= 90'b0;
            tlb_file[17] <= 90'b0;
            tlb_file[18] <= 90'b0;
            tlb_file[19] <= 90'b0;
            tlb_file[20] <= 90'b0;
            tlb_file[21] <= 90'b0;
            tlb_file[22] <= 90'b0;
            tlb_file[23] <= 90'b0;
            tlb_file[24] <= 90'b0;
            tlb_file[25] <= 90'b0;
            tlb_file[26] <= 90'b0;
            tlb_file[27] <= 90'b0;
            tlb_file[28] <= 90'b0;
            tlb_file[29] <= 90'b0;
            tlb_file[30] <= 90'b0;
            tlb_file[31] <= 90'b0;
    	end
    	else if (de_is_tlbwi) begin
    		tlb_file[index_min] <= {entryhi_min[31:13], entryhi_min[7:0], pagemask_min[24:13],
    		                        entrylo0_min[0]&entrylo1_min[0], entrylo0_min[25:1], entrylo1_min[25:1]};
    	end
    end

    assign entryhi_mout = {32{de_is_tlbr}} & {tlb_file[index_min][89:71], 5'b0, tlb_file[index_min][70:63]};
    assign pagemask_mout = {32{de_is_tlbr}}& {7'b0, tlb_file[index_min][62:51], 13'b0};
    assign entrylo0_mout = {32{de_is_tlbr}}& {6'b0, tlb_file[index_min][49:25], tlb_file[index_min][50]};
    assign entrylo1_mout = {32{de_is_tlbr}}& {6'b0, tlb_file[index_min][24: 0], tlb_file[index_min][50]};

    wire [31:0] lkup_result_32;
    wire [ 4:0] lkup_result_5;
    assign lkup_result_32[0] = (tlb_file[0][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[0][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[0][50] || tlb_file[0][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[1] = (tlb_file[1][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[1][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[1][50] || tlb_file[1][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[2] = (tlb_file[2][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[2][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[2][50] || tlb_file[2][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[3] = (tlb_file[3][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[3][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[3][50] || tlb_file[3][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[4] = (tlb_file[4][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[4][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[4][50] || tlb_file[4][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[5] = (tlb_file[5][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[5][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[5][50] || tlb_file[5][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[6] = (tlb_file[6][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[6][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[6][50] || tlb_file[6][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[7] = (tlb_file[7][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[7][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[7][50] || tlb_file[7][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[8] = (tlb_file[8][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[8][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[8][50] || tlb_file[8][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[9] = (tlb_file[9][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[9][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[9][50] || tlb_file[9][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[10] =(tlb_file[10][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[10][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[10][50] || tlb_file[10][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[11] =(tlb_file[11][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[11][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[11][50] || tlb_file[11][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[12] =(tlb_file[12][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[12][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[12][50] || tlb_file[12][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[13] =(tlb_file[13][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[13][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[13][50] || tlb_file[13][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[14] =(tlb_file[14][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[14][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[14][50] || tlb_file[14][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[15] =(tlb_file[15][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[15][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[15][50] || tlb_file[15][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[16] =(tlb_file[16][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[16][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[16][50] || tlb_file[16][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[17] =(tlb_file[17][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[17][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[17][50] || tlb_file[17][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[18] =(tlb_file[18][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[18][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[18][50] || tlb_file[18][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[19] =(tlb_file[19][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[19][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[19][50] || tlb_file[19][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[20] =(tlb_file[20][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[20][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[20][50] || tlb_file[20][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[21] =(tlb_file[21][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[21][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[21][50] || tlb_file[21][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[22] =(tlb_file[22][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[22][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[22][50] || tlb_file[22][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[23] =(tlb_file[23][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[23][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[23][50] || tlb_file[23][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[24] =(tlb_file[24][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[24][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[24][50] || tlb_file[24][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[25] =(tlb_file[25][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[25][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[25][50] || tlb_file[25][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[26] =(tlb_file[26][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[26][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[26][50] || tlb_file[26][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[27] =(tlb_file[27][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[27][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[27][50] || tlb_file[27][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[28] =(tlb_file[28][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[28][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[28][50] || tlb_file[28][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[29] =(tlb_file[29][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[29][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[29][50] || tlb_file[29][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[30] =(tlb_file[30][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[30][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[30][50] || tlb_file[30][70:63] == entryhi_min[7:0]);
    assign lkup_result_32[31] =(tlb_file[31][89:71] == entryhi_min[31:13] ) &&
                               (tlb_file[31][62:51] == pagemask_min[24:13]) &&
                               (tlb_file[31][50] || tlb_file[31][70:63] == entryhi_min[7:0]);

    assign index_mout[31] = ~(|lkup_result_32);
    assign index_mout[30:5] = 26'b0;
    encoder_32_5 encoder_32_5_1(.in(lkup_result_32), .out(lkup_result_5));
    assign index_mout[4:0] = lkup_result_5;    

endmodule