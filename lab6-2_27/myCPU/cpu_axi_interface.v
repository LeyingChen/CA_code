module cpu_axi_interface
(
    input         clk,
    input         resetn, 

    //inst sram-like 
    input         inst_req     ,
    input         inst_wr      ,
    input  [1 :0] inst_size    ,
    input  [31:0] inst_addr    ,
    input  [31:0] inst_wdata   ,
    output reg [31:0] inst_rdata   ,
    output        inst_addr_ok ,
    output        inst_data_ok ,
    
    //data sram-like 
    input         data_req     ,
    input         data_wr      ,
    input  [1 :0] data_size    ,
    input  [31:0] data_addr    ,
    input  [31:0] data_wdata   ,
    output reg [31:0] data_rdata   ,
    output        data_addr_ok ,
    output        data_data_ok ,

    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       ,

    output        inst_block,
    output        data_block,

    input  [3 :0] data_wen
);

//-----sram-like-----

reg        type;    //0 is inst; 1 is data.
reg        req_reg;
reg        wr_reg;
reg [ 1:0] size_reg;
reg [31:0] addr_reg;
reg [31:0] wdata_reg;
reg [ 3:0] data_wen_reg;

wire rdata_back;
wire wdata_into;
wire rwfinish;
reg ar_shake;
reg aw_shake;
reg w_shake;

always @(posedge clk) begin
/*    if(~resetn) begin
        type <=1'b0;
        req_reg <=1'b0;
        wr_reg <=1'b0;
        size_reg <=2'b0;
        addr_reg <=32'b0;
        wdata_reg <=32'b0;        
    end
    else begin
        if((inst_req||data_req)&&!req_reg) begin
            req_reg <= 1'b1;
            type <= data_req;
        end
        else if(rwfinish) begin
            req_reg <= 1'b0;
        end

        if(data_req&&data_addr_ok) begin
            wr_reg    <= data_wr;
            size_reg  <= data_size;
            addr_reg  <= data_addr;
            wdata_reg <= data_wdata;  
        end
        else if(inst_req&&inst_addr_ok) begin
            wr_reg    <= inst_wr;
            size_reg  <= inst_size;
            addr_reg  <= inst_addr;
            wdata_reg <= inst_wdata; 
        end
    end  */
    req_reg     <= (!resetn && inst_req)          ? 1'b0 : 
                   (inst_req||data_req)&&!req_reg ? 1'b1 :
                   rwfinish                     ? 1'b0 : req_reg;
    
    type      <=   !resetn ? 1'b0 : 
                   (inst_req||data_req)&&!req_reg ? data_req : type;

    wr_reg    <= data_req&&data_addr_ok ? data_wr :
                 inst_req&&inst_addr_ok ? inst_wr : wr_reg;
    size_reg  <= data_req&&data_addr_ok ? data_size :
                 inst_req&&inst_addr_ok ? inst_size : size_reg;
    addr_reg  <= data_req&&data_addr_ok ? data_addr :
                 inst_req&&inst_addr_ok ? inst_addr : addr_reg;
    wdata_reg <= data_req&&data_addr_ok ? data_wdata :
                 inst_req&&inst_addr_ok ? inst_wdata :wdata_reg;
    data_wen_reg <= !resetn ? 4'b0:
                    (data_req&&data_wr)&&!req_reg ? data_wen:
                    wdata_into? 4'b0: data_wen_reg;

end

//assign inst_rdata = rdata;
//assign data_rdata = rdata;

always @(posedge clk) begin
    inst_rdata <= (!resetn) ? 32'h0 :
                  (inst_data_ok) ? rdata : inst_rdata;
    data_rdata <= (!resetn) ? 32'h0 :
                  (data_data_ok) ? rdata : data_rdata;
end


assign inst_addr_ok = inst_req && !req_reg && !data_req;  //?
assign data_addr_ok = data_req && !req_reg;  //?
assign inst_data_ok = !type && rwfinish;
assign data_data_ok =  type && rwfinish;

assign inst_block = !type && /*inst_req &&*/ req_reg/*&&~inst_data_ok*/;
assign data_block = type /*&& data_req */&&(data_addr_ok||req_reg)/* && ~data_data_ok*/;

//-----axi-----
assign rwfinish   = rdata_back || wdata_into;
assign rdata_back = ar_shake&&rvalid&&rready;
assign wdata_into = aw_shake&&bvalid&&bready;

always @(posedge clk)
begin
    if(~resetn) begin
        ar_shake <= 1'b0;
    end
    else if(arvalid&&arready) begin
        ar_shake <= 1'b1;
    end
    else if(rwfinish) begin
        ar_shake <= 1'b0;
    end

    if(~resetn) begin
        aw_shake <= 1'b0;
    end
    else if(awvalid&&awready) begin
        aw_shake <= 1'b1;
    end
    else if(rwfinish) begin
        aw_shake <= 1'b0;
    end 

    if(~resetn) begin
        w_shake <= 1'b0;
    end
    else if(wvalid&&wready) begin
        w_shake <= 1'b1;
    end
    else if(rwfinish) begin
        w_shake <= 1'b0;
    end           
end

//ar
assign araddr  = addr_reg;
assign arsize  = size_reg;
assign arvalid = req_reg&&!wr_reg&&!ar_shake;
//assign arready = ;

//r
//assign rdata  = ;
//assign rvalid = ;
assign rready = 1'b1;

//aw
assign awaddr  = addr_reg;
assign awsize  = size_reg;
assign awvalid = req_reg&&wr_reg&&!aw_shake;
//assign awready = ;

//w
assign wdata  = wdata_reg;
assign wstrb  = /*size_reg==2'd00 ? 4'b0001<<addr_reg[1:0] :
                size_reg==2'd01 ? 4'b0011<<addr_reg[1:0] : 
                size_reg==2'd10 ? 4'b1111:
                                  4'b0000*/data_wen_reg;
                                 
assign wvalid = req_reg&&wr_reg&&!w_shake;
//assign wready = ;

//b
//assign bvalid = ;
assign bready = 1'b1;


//not care
assign arid    = 4'b0;
assign arlen   = 8'b0;
assign arburst = 2'b01;
assign arlock  = 2'b0;
assign arcache = 4'b0;
assign arprot  = 3'b0;
//assign rid     = 4'b0; //ignore
//assign rresp   = 2'b0; //ignore
//assign rlast   = 1'b0; //ignore
assign awid    = 4'b0;
assign awlen   = 8'b0;
assign awburst = 2'b01;
assign awlock  = 2'b0;
assign awcache = 4'b0;
assign awprot  = 3'b0;
assign wid     = 4'b0;
assign wlast   = 1'b1;
//assign bid     = 4'b0; //ignore
//assign bresp   = 2'b0; //ignore

endmodule

