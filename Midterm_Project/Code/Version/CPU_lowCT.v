//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
  
module CPU(

    clk,
    rst_n,

    IO_stall,

    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,

    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf,

    arid_m_inf,
    araddr_m_inf,
    arlen_m_inf,
    arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,

    arready_m_inf, 
    rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf; // 4 bits  =0
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf; // 32 bits 
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf; // 3 bits  =001 (2Bytes)
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf; // 2 bits  =01 (INCR)
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf; // 7 bits
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf; // 1 bit
input   wire [WRIT_NUMBER-1:0]                awready_m_inf; // 1 bit
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf; // 16 bits
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf; // 1 bit
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf; // 1 bit
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf; // 1 bit
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf; // 4 bits
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf; // 2 bits //00 (OKAY)
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf; // 1 bit
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf; // 1 bit

// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf; // 8 bits  =0
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf; // 64 bits
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf; // 14 bits
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf; // 6 bits = 001 001 (2Bytes)
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf; // 4 bits = 01  01(INCR)
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf; // 2 bits
input   wire [DRAM_NUMBER-1:0]               arready_m_inf; // 2 bits
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf; // 8 bits
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf; // 32 bits
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf; // 4 bits //00  00 (OKAY)
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf; // 2 bits
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf; // 2 bits
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf; // 2 bits
// -----------------------------
//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the X in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

//###########################################
// fixed value
//###########################################
assign awid_m_inf = 4'h0;
assign awsize_m_inf = 3'h1;
assign awburst_m_inf = 2'h1;
//==========================================
assign arid_m_inf = 8'h0;
assign arsize_m_inf = 6'b001001;
assign arburst_m_inf = 4'b0101;
//parameter
parameter IDLE    = 4'd0;
parameter FETCH   = 4'd1;
parameter JUMP    = 4'd2;
parameter EXECUTE = 4'd3;
parameter STORE   = 4'd4;
parameter LOAD    = 4'd5;
parameter BRANCH  = 4'd6;

reg [3:0] current_state, next_state;
reg sram_has_inst; //flag
wire update_data_finish = bvalid_m_inf; //flag 
wire read_data_finish;
reg  signed [15:0] inst_addr;
wire [15:0] instruction;
wire dram_data_valid;

reg  signed  [15:0] rs_data;
reg  signed  [15:0] rt_data;
reg  signed  [15:0] rd_data;

wire [3:0] rs     = instruction[12:9];
wire [3:0] rt     = instruction[8:5];
wire [3:0] rd     = instruction[4:1];
wire [2:0] opcode = instruction[15:13];
wire       func   = instruction[0];
wire signed [4:0] immediate = instruction[4:0];

wire [15:0] load_data;
wire sram_WEB_select;
wire [7:0] sram_addr_select;
wire [15:0] sram_data_select;
reg [15:0] sram_out;
reg [15:0] sram_out_reg;
wire [5:0] hit_tag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sram_out <=0;
    else sram_out <= sram_out_reg;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rt_data <=0;
    else if ((current_state == LOAD) && read_data_finish) rt_data <= load_data;
    else 
        case (rt)
            0: rt_data <= core_r0;
            1: rt_data <= core_r1;
            2: rt_data <= core_r2;
            3: rt_data <= core_r3;
            4: rt_data <= core_r4;
            5: rt_data <= core_r5;
            6: rt_data <= core_r6;
            7: rt_data <= core_r7;
            8: rt_data <= core_r8;
            9: rt_data <= core_r9;
            10: rt_data <= core_r10;
            11: rt_data <= core_r11;
            12: rt_data <= core_r12;
            13: rt_data <= core_r13;
            14: rt_data <= core_r14;
            15: rt_data <= core_r15;
            default : rt_data <= 0;
        endcase
end

reg signed [15:0] rs_data_comb;

always @(*) begin
    case(rs)
        0 : rs_data_comb = core_r0;
        1 : rs_data_comb = core_r1;
        2 : rs_data_comb = core_r2;
        3 : rs_data_comb = core_r3;
        4 : rs_data_comb = core_r4;
        5 : rs_data_comb = core_r5;
        6 : rs_data_comb = core_r6;
        7 : rs_data_comb = core_r7;
        8 : rs_data_comb = core_r8;
        9 : rs_data_comb = core_r9;
        10: rs_data_comb = core_r10;
        11: rs_data_comb = core_r11;
        12: rs_data_comb = core_r12;
        13: rs_data_comb = core_r13;
        14: rs_data_comb = core_r14;
        15: rs_data_comb = core_r15;
        default : rs_data_comb = 0;
    endcase
end

always @(posedge clk) begin
    if (sram_has_inst) 
        rs_data <= rs_data_comb;
    else
        rs_data <= rs_data;
end

always @(*) begin
    case(opcode)
        3'b000: // ADD SUB
            if(func) // ADD
                rd_data = rs_data + rt_data;
            else         // SUB
                rd_data = rs_data - rt_data;
        3'b001: // SLT MULT
            if(func) // SLT
                rd_data = (rs_data < rt_data) ? 16'd1 : 16'd0;
            else         // MULT
                rd_data = rs_data * rt_data;
        default: rd_data = 16'd0;
    endcase
end
//=========================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    case(current_state)
        IDLE: next_state = FETCH;
        FETCH: 
            if(sram_has_inst)
                case(opcode)
                    3'b000: next_state = EXECUTE; // ADD SUB
                    3'b001: next_state = EXECUTE; // slt mult
                    3'b010: next_state = STORE;   // store
                    3'b011: next_state = LOAD;    // load
                    3'b100: next_state = JUMP;    // jump
                    3'b101: next_state = BRANCH;  // branch
                    default: next_state = FETCH;
                endcase
            else
                 next_state = FETCH;
        EXECUTE: next_state = FETCH; 
        JUMP:    next_state = FETCH;
        STORE:   next_state = (update_data_finish)? FETCH : STORE;
        LOAD:    next_state = (read_data_finish) ? FETCH : LOAD;
        BRANCH:  next_state = FETCH;
        default: next_state = IDLE;
    endcase
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) inst_addr <= 'h1000 ;
    else
        case(current_state)
            EXECUTE: inst_addr <= inst_addr + 2 ;
            JUMP   : inst_addr <= {3'b000,instruction[12:0]};
            BRANCH : inst_addr <= (rs_data == rt_data) ? inst_addr + 2 + immediate*2 : inst_addr + 2 ;
            STORE  : inst_addr <= (update_data_finish)? inst_addr + 2 : inst_addr ;
            LOAD   : inst_addr <= (read_data_finish)? inst_addr + 2 : inst_addr ;
            default: inst_addr <= inst_addr ;
        endcase
end

wire inst_sram_WEB;
wire [6:0] inst_sram_addr;
wire [15:0] inst_sram_data; //from sram
reg inst_valid;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		inst_valid <= 1'b0;
	else if (current_state != FETCH && next_state == FETCH)
		inst_valid <= 1'b1;
    else 
        inst_valid <= 1'b0;
end

Read_DRAM  #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DRAM_NUMBER(1)
) Read_inst(
    .clk(clk),  .rst_n(rst_n), .in_valid(inst_valid),
    .in_address(inst_addr), .out_data (instruction) , .out_valid(sram_has_inst),

    .sram_WEB(inst_sram_WEB) , .sram_addr(inst_sram_addr), .sram_data(sram_out),

    .araddr_m_inf(araddr_m_inf[63:32]),
    .arlen_m_inf(arlen_m_inf[13:7]),
    .arvalid_m_inf(arvalid_m_inf[1]),
    .arready_m_inf(arready_m_inf[1]), 
                 
    .rdata_m_inf(rdata_m_inf[31:16]),
    .rlast_m_inf(rlast_m_inf[1]),
    .rvalid_m_inf(rvalid_m_inf[1]),
    .rready_m_inf(rready_m_inf[1]) 
);

wire [19:0] store_addr = ( (rs_data + immediate)*2 ) + $signed(16'h1000); ;
// wire [15:0] store_data;
wire [6:0] data_sram_addr;
wire [15:0] data_sram_data;
wire data_sram_WEB;

reg signed [15:0] store_data;

always @(*) begin
    case(rt)
        0: store_data = core_r0;
        1: store_data = core_r1;
        2: store_data = core_r2;
        3: store_data = core_r3;
        4: store_data = core_r4;
        5: store_data = core_r5;
        6: store_data = core_r6;
        7: store_data = core_r7;
        8: store_data = core_r8;
        9: store_data = core_r9;
        10: store_data = core_r10;
        11: store_data = core_r11;
        12: store_data = core_r12;
        13: store_data = core_r13;
        14: store_data = core_r14;
        15: store_data = core_r15;
        default : store_data = 0;
    endcase
end


Write_DRAM #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .WRIT_NUMBER(1)
) Store_data
(
    .clk(clk),  .rst_n(rst_n), .in_valid( (next_state==STORE)), //v2
    .in_address(store_addr[15:0]), .in_data(store_data),

    .sram_WEB(data_sram_WEB),       .sram_addr(data_sram_addr), 
    .awaddr_m_inf(awaddr_m_inf),    .awlen_m_inf(awlen_m_inf),   .awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf),  
    .wdata_m_inf(wdata_m_inf),      .wlast_m_inf(wlast_m_inf),   .wvalid_m_inf(wvalid_m_inf),   .wready_m_inf(wready_m_inf),
    .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf) , .hit_tag(hit_tag)
);
wire [18:0] load_addr = ( (rs_data + immediate)*2 ) + $signed(16'h1000); //critical path
// wire load_valid;
wire load_sram_WEB;
wire [6:0] load_sram_addr;

reg read_data_valid;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        read_data_valid <= 1'b0;
    else if (current_state != LOAD && next_state == LOAD)
        read_data_valid <= 1'b1;
    else
        read_data_valid <= 1'b0;
end  //60467

Read_DRAM  #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DRAM_NUMBER(1)
) Read_data(
    .clk(clk),  .rst_n(rst_n), .in_valid(read_data_valid),
    .in_address(load_addr[15:0]), .out_data (load_data) , .out_valid(read_data_finish),

    .sram_WEB(load_sram_WEB) , .sram_addr(load_sram_addr), .sram_data(sram_out), //Opt

    .araddr_m_inf(araddr_m_inf[31:0]),     .arlen_m_inf(arlen_m_inf[6:0]),    .arvalid_m_inf(arvalid_m_inf[0]),   .arready_m_inf(arready_m_inf[0]), 
    .rdata_m_inf(rdata_m_inf[15:0]),       .rlast_m_inf(rlast_m_inf[0]),      .rvalid_m_inf(rvalid_m_inf[0]),     .rready_m_inf(rready_m_inf[0]) ,
    .tag_reg (hit_tag)
);

assign sram_WEB_select = (current_state == FETCH) ? inst_sram_WEB : 
                         (current_state == STORE) ? data_sram_WEB :
                         (current_state == LOAD) ? load_sram_WEB : 1'b1;

assign sram_addr_select = (current_state == STORE) ? {1'b0,data_sram_addr} :
                          (next_state == FETCH) ? {1'b1,inst_sram_addr} : //not sure
                          (next_state == LOAD) ? {1'b0,load_sram_addr} : 8'b0;

assign sram_data_select = (current_state == FETCH) ? rdata_m_inf[31:16] :
                         (current_state == STORE) ? store_data :
                         (current_state == LOAD) ? rdata_m_inf[15:0] : 16'b0;


SRAM_256_16 SRAM_inst_data (
    .CK(clk),
    .WEB(sram_WEB_select),
    .OE(1'b1),
    .CS(1'b1),
    .A(sram_addr_select),
    .DI(sram_data_select),
    .DO(sram_out_reg)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r0 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==0) : core_r0 <= load_data;
            (current_state == EXECUTE && (rd==0) ) : core_r0 <= rd_data;
            default : core_r0 <= core_r0;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r1 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==1) : core_r1 <= load_data;
            (current_state == EXECUTE && (rd==1) ) : core_r1 <= rd_data;
            default : core_r1 <= core_r1;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r2 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==2) : core_r2 <= load_data;
            (current_state == EXECUTE && (rd==2) ) : core_r2 <= rd_data;
            default : core_r2 <= core_r2;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r3 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==3) : core_r3 <= load_data;
            (current_state == EXECUTE && (rd==3) ) : core_r3 <= rd_data;
            default : core_r3 <= core_r3;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r4 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==4) : core_r4 <= load_data;
            (current_state == EXECUTE && (rd==4) ) : core_r4 <= rd_data;
            default : core_r4 <= core_r4;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r5 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==5) : core_r5 <= load_data;
            (current_state == EXECUTE && (rd==5) ) : core_r5 <= rd_data;
            default : core_r5 <= core_r5;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r6 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==6) : core_r6 <= load_data;
            (current_state == EXECUTE && (rd==6) ) : core_r6 <= rd_data;
            default : core_r6 <= core_r6;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r7 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==7) : core_r7 <= load_data;
            (current_state == EXECUTE && (rd==7) ) : core_r7 <= rd_data;
            default : core_r7 <= core_r7;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r8 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==8) : core_r8 <= load_data;
            (current_state == EXECUTE && (rd==8) ) : core_r8 <= rd_data;
            default : core_r8 <= core_r8;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r9 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==9) : core_r9 <= load_data;
            (current_state == EXECUTE && (rd==9) ) : core_r9 <= rd_data;
            default : core_r9 <= core_r9;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r10 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==10) : core_r10 <= load_data;
            (current_state == EXECUTE && (rd==10) ) : core_r10 <= rd_data;
            default : core_r10 <= core_r10;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r11 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==11) : core_r11 <= load_data;
            (current_state == EXECUTE && (rd==11) ) : core_r11 <= rd_data;
            default : core_r11 <= core_r11;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r12 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==12) : core_r12 <= load_data;
            (current_state == EXECUTE && (rd==12) ) : core_r12 <= rd_data;
            default : core_r12 <= core_r12;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r13 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==13) : core_r13 <= load_data;
            (current_state == EXECUTE && (rd==13) ) : core_r13 <= rd_data;
            default : core_r13 <= core_r13;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r14 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==14) : core_r14 <= load_data;
            (current_state == EXECUTE && (rd==14) ) : core_r14 <= rd_data;
            default : core_r14 <= core_r14;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r15 <=0;
    else 
        case(1)
            (current_state == LOAD) && read_data_finish && (rt==15) : core_r15 <= load_data;
            (current_state == EXECUTE && (rd==15) ) : core_r15 <= rd_data;
            default : core_r15 <= core_r15;
        endcase
end


//####################################################
//               output
//####################################################
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		IO_stall <= 1;
	end else 
		IO_stall <= !(current_state != FETCH && next_state == FETCH && current_state != IDLE);
end

endmodule

module Read_DRAM #(
  parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1
)
(
    clk,  rst_n, in_valid,

    in_address,  out_data , out_valid,
    sram_WEB,    sram_addr, sram_data, tag_reg,

    araddr_m_inf,   arlen_m_inf,    arvalid_m_inf,  arready_m_inf,  
    rdata_m_inf,    rlast_m_inf,    rvalid_m_inf,   rready_m_inf
);
input  clk, rst_n , in_valid;
output reg   [DRAM_NUMBER * ADDR_WIDTH-1:0]  araddr_m_inf;  // 32 bits
output       [DRAM_NUMBER * 7 -1:0]          arlen_m_inf;   // 7 bits = 1111111 (read 127+1)
output reg                                   arvalid_m_inf; // 1 bits
input                                        arready_m_inf; // 1 bits

input        [DRAM_NUMBER * DATA_WIDTH-1:0] rdata_m_inf;  // 16 bits
input                                       rlast_m_inf;  // 1 bits
input                                       rvalid_m_inf; // 1 bits
output                                      rready_m_inf; // 1 bits

input      [15:0]           in_address;
output reg [DATA_WIDTH-1:0] out_data;
output reg                  out_valid;
//sram
input      [DATA_WIDTH-1:0] sram_data;
output                      sram_WEB;
output reg [6:0]            sram_addr;
output reg [5:0] tag_reg ;
// reg [ID_WIDTH-1:0]  data;
//=============================================
assign arlen_m_inf = 7'b111_1111;
//==============================================
// reg define
//=============================================
wire [5:0] tag = in_address[13:8];
reg sram_valid;
wire hit = (sram_valid && (tag_reg == tag)) ? 1'b1 : 1'b0;

//==============================================
// FSM
//=============================================
reg [2:0] current_state, next_state;
parameter IDLE = 3'b000;
parameter REQ = 3'b001;
parameter WAIT = 3'b010;
parameter HIT = 3'b011;
parameter DATA_FINISH = 3'b100; //4
parameter WAIT_SRAM = 3'b101;
parameter WAIT_SRAM2= 3'b110;
//IDLE(0) HIT(3)  WAIT_SRAM(5) DATA_FINISH(4) WAIT_SRAM2(6)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    case(current_state)
        IDLE: 
            if(in_valid)
                next_state = (hit) ? HIT : REQ;
            else
                next_state = IDLE;
        REQ:        next_state = (arready_m_inf)? WAIT : REQ;
        WAIT:       next_state =  (rlast_m_inf) ? DATA_FINISH : WAIT;
        HIT:        next_state = WAIT_SRAM;
        WAIT_SRAM:  next_state = WAIT_SRAM2; //reduce here latency
        DATA_FINISH:next_state = WAIT_SRAM2;
        WAIT_SRAM2: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end
//==============================================
// design
//=============================================
//araddr_m_inf
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        araddr_m_inf = 32'b0;
    else if(in_valid || current_state ==REQ) begin 
        araddr_m_inf = {17'd0,in_address[14:8] ,8'd0} ;
    end
    else begin
        araddr_m_inf = 32'b0;
    end
end

//arvalid_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        arvalid_m_inf <= 1'b0;
    else if((in_valid && !hit) || next_state == REQ)
        arvalid_m_inf <= 1'b1;
    else
        arvalid_m_inf <= 1'b0;
end

//rready_m_inf
assign rready_m_inf =( (current_state==REQ) ||(current_state == WAIT) ) ? 1'b1 : 1'b0;

//=============================================
//tag_reg 
always @(posedge clk) begin
    if(in_valid)
        tag_reg <= tag;
    else
        tag_reg <= tag_reg;
end

//sram_valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        sram_valid <= 0;
    else if(rlast_m_inf)
        sram_valid <= 1;
    else
        sram_valid <= sram_valid;
end

//sram_WEB
assign sram_WEB = !(current_state == WAIT);
reg [7:0] count_addr;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count_addr <= 0;
    end 
    else begin
        case(1)
            (rvalid_m_inf) : count_addr <= count_addr + 1;
            (current_state == IDLE) : count_addr <= 0;
            default: count_addr <= count_addr;
        endcase
    end
end

//sram addr
always @(*) begin
    if(current_state == WAIT)  sram_addr = count_addr;
    else sram_addr = in_address[7:1];
end

//output Valid and data
always @(*) begin
    if(current_state == WAIT_SRAM2)
        out_valid = 1'b1;
    else
        out_valid = 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        out_data <= 0;
    else begin
        case(1)
            (rvalid_m_inf && (sram_addr == in_address[7:1])) :out_data <= rdata_m_inf;
            (current_state == WAIT_SRAM): out_data <= sram_data;
            // (current_state == DATA_FINISH): out_data <= out_data;
            default: out_data <= out_data;
        endcase
    end
end

endmodule

module Write_DRAM#(
  parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, WRIT_NUMBER=1
)
(
    clk, rst_n, in_valid,

    in_address,
    in_data,
    sram_WEB,
    sram_addr,

    awaddr_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,

    bvalid_m_inf,
    bready_m_inf,
    hit_tag
);
input    clk, rst_n , in_valid;
input  [DATA_WIDTH-1:0]    in_address;
input  [DATA_WIDTH-1:0]    in_data;
//sram
// output   [DATA_WIDTH-1:0]  sram_data;
output                  sram_WEB;
output [6:0]            sram_addr;
// axi write address channel 
output reg [WRIT_NUMBER * ADDR_WIDTH-1:0]   awaddr_m_inf; // 32 bits 
output [WRIT_NUMBER * 7 -1:0]           awlen_m_inf; // 7 bits = 0 (write 1)
output [WRIT_NUMBER-1:0]                awvalid_m_inf; // 1 bit
input  [WRIT_NUMBER-1:0]                awready_m_inf; // 1 bit
// axi write data channel 
output reg  [WRIT_NUMBER * DATA_WIDTH-1:0]   wdata_m_inf; // 16 bits
output [WRIT_NUMBER-1:0]                wlast_m_inf; // 1 bit
output [WRIT_NUMBER-1:0]                wvalid_m_inf; // 1 bit
input  [WRIT_NUMBER-1:0]                wready_m_inf; // 1 bit
// axi write response channel
input  [WRIT_NUMBER-1:0]                bvalid_m_inf; // 1 bit
output [WRIT_NUMBER-1:0]                bready_m_inf; // 1 bit
input  [5:0] hit_tag ;
assign awlen_m_inf = 7'd0;

//==============================================
// FSM
//=============================================
reg [1:0] current_state, next_state;
parameter IDLE = 2'b00;
parameter REQ = 2'b01;
parameter WRITE = 2'b10;
parameter WAIT = 2'b11;

wire [5:0] tag = in_address[13:8];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    case(current_state)
        IDLE : next_state = (in_valid) ? REQ : IDLE;
        REQ  : next_state = (awready_m_inf) ? WRITE : REQ;
        WRITE: next_state = (wready_m_inf) ? WAIT : WRITE;
        WAIT : next_state = (bvalid_m_inf) ? IDLE : WAIT;
        default: next_state = IDLE;
    endcase
end
//==============================================
// design
//=============================================

// assign awaddr_m_inf  = (current_state == REQ) ? {16'd0,in_address}  :0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        awaddr_m_inf <= 0;
    else begin
        case(1)
            (current_state == REQ) : awaddr_m_inf <= {16'd0,in_address} ;
            default : awaddr_m_inf <= awaddr_m_inf ;
        endcase
    end
end

assign awvalid_m_inf = (current_state == REQ) ;
assign wlast_m_inf   = (current_state == WRITE);
assign wvalid_m_inf  = (current_state == WRITE);
assign bready_m_inf  = (current_state == WRITE) || (current_state == WAIT);
// assign wdata_m_inf   = (current_state == WRITE) ? in_data : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wdata_m_inf <= 0;
    else begin
        case(1)
            (current_state == WRITE) : wdata_m_inf <= in_data;
            default : wdata_m_inf <= wdata_m_inf ;
        endcase
    end
end

assign sram_WEB      = (current_state != WAIT) || (hit_tag != tag) ;
assign sram_addr     = in_address[7:1] ;
endmodule

module SRAM_256_16 (
    input CK,WEB,OE,CS,
    input [7:0] A,
    input [15:0] DI,
    output [15:0] DO
);

SRAM_256X16 SRAM_inst (
  .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]),
  .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]),
  
  .DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]),
  .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
  .DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]),
  .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),

  .DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]),
  .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]),
  .DO8(DO[8]), .DO9(DO[9]), .DO10(DO[10]), .DO11(DO[11]),
  .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),

  .CK(CK) , .WEB(WEB) , .OE(OE) , .CS(CS)
);
endmodule

//done_v1

// Cycle: 20.00
// Area: 130648.276623
// Performance: 191073527286701341.3788000000

// Cycle: 10.00
// Area: 132198.177321
// Performance: 48335065518096259.9569000000

// Cycle: 7.50
// Area: 137622.830095
// Performance: 28304132949332796.8505937500

// Cycle: 6.90 
// Area: 144628.631593
// Performance: 25176149154196012.0670429700
//=======================================================
//done_v2  let write early 1 cycle (59488 cycle) (av= 59488/4129=14.40)
// .in_valid( (current_state==STORE)), -> in_valid( (next_state==STORE)),
// Cycle: 6.90
// Area: 143806.809194
// Performance: 24229048978892932.7160729600
//=======================================================
//done_v3 let store_addr and load_addr use rs_data DFF output 
// (reduce critical path)
// Cycle: 5.60
// Area: 137179.108586
// Performance: 15223789370084831.4181222400

// Cycle: 4.80 
// Area: 143256.844394
// Performance: 11680369763812979.5753574400

// Cycle: 4.80 ******
// Area: 143013.110067
// Performance: 11660497016541901.6008499200

//=======================================================
// let DRAM update correcter 
// Cycle: 4.80
// Area: 144222.407638
// Performance: 11759096443630444.0904908800

//remove hit_tag reset 
// Cycle: 4.80
// Area: 144047.418884
// Performance: 11744828829682397.9664998400

//combine hit_tag and tag_reg
// Cycle: 4.80
// Area: 143853.681335
// Performance: 11729032542817170.7908096000

//remove tag_reg reset  ******
// Cycle: 4.80
// Area: 143378.711663
// Performance: 11690306146050404.3244748800

//remove count_addr reset
// Cycle: 4.80
// Area: 143606.822111
// Performance: 11708905008749774.4226713600

//best
//remove rs_data reset ******
// Cycle: 4.80
// Area: 142510.017240
// Performance: 11619477613456905.8893824000

// remove rt_data reset
// Cycle: 4.80
// Area: 143363.087661
// Performance: 11689032251449957.5978393600

// remove read_data_valid reset
// Cycle: 4.80
// Area: 144172.410906
// Performance: 11755019986975178.5527705600

//remove readDram out_data reset
// Cycle: 4.80
// Area: 143588.073051
// Performance: 11707376314225960.8885657600

//reset cant move : sram_out
//reset not good : inst_valid rt_data count_addr read_data_valid
//                 readDram :  out_data

//=======================================

//CPU_done_pat2_v2 :  (59488 cycle) -> (54500 cycle) (av= 13.196)
// let instruction fetch reduce 1 cycle
// Cycle: 4.80
// Area: 143641.194887
// Performance: 9830021969966094.7200000000

//=======================================
//perf (148735 cycle) (av=  36.01)
// Cycle: 4.80
// Area: 143641.194887

//read data in_address 16bits -> 15bits
// Cycle: 4.80
// Area: 142722.503696
// Performance: 72744688077139467.2240640000

//add AXI DFF ( 148906 Cycle) (av= 36.05)
// Cycle: 4.30
// Area: 146422.266870
// Performance: 60030012305926181.4551868000
