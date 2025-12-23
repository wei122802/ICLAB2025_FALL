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
//
// Wrtie down your design below
//
//###########################################
// Fixed value
// assign awid_m_inf   = 4'b0000;
// assign awsize_m_inf = 3'b001; // 2Bytes
// assign awburst_m_inf= 2'b01;  // INCR

// assign arid_m_inf  = 8'b0000_0000;
// assign arsize_m_inf= 6'b001_001; // 2Bytes
// assign arburst_m_inf=4'b01_01;  // INCR

//####################################################
//               FSM
//####################################################
parameter IDLE = 4'd0;
parameter FETCH = 4'd1;
parameter JUMP = 4'd2;
parameter EXECUTE = 4'd3;
parameter STORE = 4'd4;
parameter LOAD = 4'd5;
parameter BRANCH = 4'd6;

reg [3:0] current_state, next_state;
reg sram_has_inst; //flag
wire update_data_finish; //flag 
wire read_data_finish;
reg  signed [15:0] inst_addr;
wire [15:0] instruction;
wire dram_data_valid;
wire branch_equal; //flag
wire [12:0] jump_addr;

reg  signed  [15:0] rs_data;
reg  signed  [15:0] rt_data;
reg  signed  [15:0] rd_data;
wire [3:0] rs = instruction[12:9];
wire [3:0] rt = instruction[8:5];
wire [3:0] rd = instruction[4:1];
wire [15:0] load_data ;
wire sram_WEB_select;
wire [7:0] sram_addr_select;
wire [15:0] sram_data_select;
reg [15:0] sram_out;
reg [15:0] sram_out_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sram_out <=0;
    else sram_out <= sram_out_reg;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rt_data <=0;
    // else if ((current_state == EXECUTE) && ())
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

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rs_data <=0;
    else if (sram_has_inst) 
        rs_data <=rs_data_comb;
    else
        rs_data <= rs_data;
end
wire [2:0] opcode = instruction[15:13];

wire func = instruction[0];

always @(*) begin
    case(current_state)
        EXECUTE: 
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
        default: rd_data = 16'd0;
    endcase
end

//=========================================

wire signed [4:0] immediate = instruction[4:0];
assign jump_addr ={ 3'b000 , instruction[12:0] };

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
                    3'b101: next_state = BRANCH;    // branch
                    default: next_state = FETCH;
                endcase
            else
                next_state = FETCH;
        EXECUTE: next_state = FETCH; 
        JUMP: next_state = FETCH;
        STORE: 
            if(update_data_finish)
                next_state = FETCH;
            else
                next_state = STORE;
        LOAD:
            if(read_data_finish)
                next_state = FETCH;
            else
                next_state = LOAD;
        BRANCH: next_state = FETCH;
        default: next_state = IDLE;
    endcase
end

assign branch_equal = (rs_data == rt_data) ;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) inst_addr <= 'h1000 ;
    else
        case(current_state)
            EXECUTE: inst_addr <= inst_addr + 2 ;
            JUMP   : inst_addr <= jump_addr;
            BRANCH : inst_addr <= (branch_equal) ? inst_addr + 2 + immediate*2 : inst_addr + 2 ;
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
		inst_valid <= 0;
	else
		inst_valid <= current_state != FETCH && next_state == FETCH;
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

         .arid_m_inf(arid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
       .araddr_m_inf(araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]),
        .arlen_m_inf(arlen_m_inf[13:7]),
       .arsize_m_inf(arsize_m_inf[5:3]),
      .arburst_m_inf(arburst_m_inf[3:2]),
      .arvalid_m_inf(arvalid_m_inf[1]),
      .arready_m_inf(arready_m_inf[1]), 
                 
          .rid_m_inf(rid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
        .rdata_m_inf(rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]),
        .rresp_m_inf(rresp_m_inf[3:2]),
        .rlast_m_inf(rlast_m_inf[1]),
       .rvalid_m_inf(rvalid_m_inf[1]),
       .rready_m_inf(rready_m_inf[1]) 
);

wire [19:0] store_addr = ( (rs_data_comb + immediate)*2 ) + $signed(16'h1000); ;
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
    .clk(clk),  .rst_n(rst_n), .in_valid( (current_state==STORE)),
    .in_address(store_addr[15:0]), .in_data(store_data), .out_valid(update_data_finish),

    .sram_WEB(data_sram_WEB), .sram_addr(data_sram_addr), .sram_data(data_sram_data),

    .awid_m_inf(awid_m_inf),   .awaddr_m_inf(awaddr_m_inf),
    .awsize_m_inf(awsize_m_inf), .awburst_m_inf(awburst_m_inf),
    .awlen_m_inf(awlen_m_inf),   .awvalid_m_inf(awvalid_m_inf),
    .awready_m_inf(awready_m_inf),
    .wdata_m_inf(wdata_m_inf),   .wlast_m_inf(wlast_m_inf),
    .wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
    .bid_m_inf(bid_m_inf),     .bresp_m_inf(bresp_m_inf),
    .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf)
);

wire [19:0] load_addr = ( (rs_data_comb + immediate)*2 ) + $signed(16'h1000);

// wire load_valid;
wire load_sram_WEB;
wire [6:0] load_sram_addr;
// wire [15:0] load_sram_data;
// wire read_data_valid = (current_state!=LOAD) && (next_state==LOAD); //problem
reg read_data_valid;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        read_data_valid <= 0;
    else
        read_data_valid <= current_state != LOAD && next_state == LOAD;
end  //60467

Read_DRAM  #(
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DRAM_NUMBER(1)
) Read_data(
    .clk(clk),  .rst_n(rst_n), .in_valid(read_data_valid),
    .in_address(load_addr[15:0]), .out_data (load_data) , .out_valid(read_data_finish),

    .sram_WEB(load_sram_WEB) , .sram_addr(load_sram_addr), .sram_data(sram_out),

        .arid_m_inf(arid_m_inf[ID_WIDTH-1:0]),
       .araddr_m_inf(araddr_m_inf[ADDR_WIDTH-1:0]),
        .arlen_m_inf(arlen_m_inf[6:0]),
       .arsize_m_inf(arsize_m_inf[2:0]),
      .arburst_m_inf(arburst_m_inf[1:0]),
      .arvalid_m_inf(arvalid_m_inf[0]),
      .arready_m_inf(arready_m_inf[0]), 
                 
          .rid_m_inf(rid_m_inf[ID_WIDTH-1:0]),
        .rdata_m_inf(rdata_m_inf[DATA_WIDTH-1:0]),
        .rresp_m_inf(rresp_m_inf[1:0]),
        .rlast_m_inf(rlast_m_inf[0]),
       .rvalid_m_inf(rvalid_m_inf[0]),
       .rready_m_inf(rready_m_inf[0]) 
);


assign sram_WEB_select = (current_state == FETCH) ? inst_sram_WEB : 
                         (current_state == STORE) ? data_sram_WEB :
                         (current_state == LOAD) ? load_sram_WEB : 1'b1;

assign sram_addr_select = (current_state == STORE) ? {1'b0,data_sram_addr} :
                          (next_state == FETCH) ? {1'b1,inst_sram_addr} : //not sure
                          (next_state == LOAD) ? {1'b0,load_sram_addr} : 8'b0;

assign sram_data_select = (current_state == FETCH) ? rdata_m_inf[31:16] :
                         (current_state == STORE) ? data_sram_data :
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
    else if ((current_state == LOAD) && read_data_finish && (rt==0)) core_r0 <= load_data;
    else if (current_state == EXECUTE && (rd==0) ) core_r0 <= rd_data;
    else core_r0 <= core_r0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r1 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==1)) core_r1 <= load_data;
    else if (current_state == EXECUTE && (rd==1)) core_r1 <= rd_data;
    else core_r1 <= core_r1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r2 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==2)) core_r2 <= load_data;
    else if (current_state == EXECUTE && (rd==2)) core_r2 <= rd_data;
    else core_r2 <= core_r2;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r3 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==3)) core_r3 <= load_data;
    else if (current_state == EXECUTE && (rd==3)) core_r3 <= rd_data;
    else core_r3 <= core_r3;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r4 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==4)) core_r4 <= load_data;
    else if (current_state == EXECUTE && (rd==4)) core_r4 <= rd_data;
    else core_r4 <= core_r4;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r5 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==5)) core_r5 <= load_data;
    else if (current_state == EXECUTE && (rd==5)) core_r5 <= rd_data;
    else core_r5 <= core_r5;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r6 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==6)) core_r6 <= load_data;
    else if (current_state == EXECUTE && (rd==6)) core_r6 <= rd_data;
    else core_r6 <= core_r6;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r7 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==7)) core_r7 <= load_data;
    else if (current_state == EXECUTE && (rd==7)) core_r7 <= rd_data;
    else core_r7 <= core_r7;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r8 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==8)) core_r8 <= load_data;
    else if (current_state == EXECUTE && (rd==8)) core_r8 <= rd_data;
    else core_r8 <= core_r8;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r9 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==9)) core_r9 <= load_data;
    else if (current_state == EXECUTE && (rd==9)) core_r9 <= rd_data;
    else core_r9 <= core_r9;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r10 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==10)) core_r10 <= load_data;
    else if (current_state == EXECUTE && (rd==10)) core_r10 <= rd_data;
    else core_r10 <= core_r10;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r11 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==11)) core_r11 <= load_data;
    else if (current_state == EXECUTE && (rd==11)) core_r11 <= rd_data;
    else core_r11 <= core_r11;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r12 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==12)) core_r12 <= load_data;
    else if (current_state == EXECUTE && (rd==12)) core_r12 <= rd_data;
    else core_r12 <= core_r12;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r13 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==13)) core_r13 <= load_data;
    else if (current_state == EXECUTE && (rd==13)) core_r13 <= rd_data;
    else core_r13 <= core_r13;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r14 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==14)) core_r14 <= load_data;
    else if (current_state == EXECUTE && (rd==14)) core_r14 <= rd_data;
    else core_r14 <= core_r14;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  core_r15 <=0;
    else if ((current_state == LOAD) && read_data_finish && (rt==15)) core_r15 <= load_data;
    else if (current_state == EXECUTE && (rd==15)) core_r15 <= rd_data;
    else core_r15 <= core_r15;
end


//####################################################
//               output
//####################################################
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		IO_stall <= 1;
	end else if(current_state != FETCH && next_state == FETCH && current_state != IDLE) begin
		IO_stall <= 0;
	end else
		IO_stall <= 1;
end

endmodule

module Read_DRAM #(
  parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1
)
(
    clk,  rst_n, in_valid,

    in_address,     out_data , out_valid,
    sram_WEB, sram_addr,sram_data,

    arid_m_inf,     araddr_m_inf,
    arlen_m_inf,    arsize_m_inf,
    arburst_m_inf,  arvalid_m_inf,
    arready_m_inf,  rid_m_inf,
    rdata_m_inf,    rresp_m_inf,
    rlast_m_inf,    rvalid_m_inf,
    rready_m_inf
);
input  clk, rst_n , in_valid;
output  wire [ID_WIDTH-1:0]                  arid_m_inf;    // 4 bits  =0
output  reg  [DRAM_NUMBER * ADDR_WIDTH-1:0]  araddr_m_inf;  // 32 bits
output  wire [DRAM_NUMBER * 7 -1:0]          arlen_m_inf;   // 7 bits = 1111111 (read 127+1)
output  wire [DRAM_NUMBER * 3 -1:0]          arsize_m_inf;  // 3 bits = 001 
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf; // 2 bits = 01 (INCR)
output  reg                                  arvalid_m_inf; // 1 bits
input   wire                                 arready_m_inf; // 1 bits

input   wire [DRAM_NUMBER * ID_WIDTH-1:0]   rid_m_inf;    // 4 bits
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0] rdata_m_inf;  // 16 bits
input   wire [DRAM_NUMBER * 2 -1:0]         rresp_m_inf;  // 2 bits //00  (OKAY)
input   wire                                rlast_m_inf;  // 1 bits
input   wire                                rvalid_m_inf; // 1 bits
output  wire                                rready_m_inf; // 1 bits

input      [15:0]           in_address;
output reg [DATA_WIDTH-1:0] out_data;
output reg                  out_valid;
//sram
input      [DATA_WIDTH-1:0] sram_data;
output                      sram_WEB;
output reg [6:0]            sram_addr;
// reg [ID_WIDTH-1:0]  data;
//=============================================
assign arid_m_inf = 0;
assign arlen_m_inf = 7'b111_1111;
assign arsize_m_inf = 3'b001;
assign arburst_m_inf = 2'b01;
//==============================================
// reg define
//=============================================
reg hit;
wire [5:0] tag = in_address[13:8];
reg  [5:0] tag_reg;
reg sram_valid;
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
        REQ:
            if(arready_m_inf)
                next_state = WAIT;
            else
                next_state = REQ;
        WAIT:
            if(rlast_m_inf)
                next_state = DATA_FINISH;
            else
                next_state = WAIT;
        HIT:
            next_state = WAIT_SRAM;
        WAIT_SRAM:
            next_state = DATA_FINISH;
        DATA_FINISH:
            next_state = WAIT_SRAM2;
        WAIT_SRAM2:
            next_state = IDLE;
        default: next_state = IDLE;
    endcase
end
//==============================================
// design
//=============================================
//araddr_m_inf
always @(*) begin
    if(in_valid || current_state ==REQ) begin 
        araddr_m_inf = {16'd0 , in_address[15:8] ,8'd0} ;
    end
    else begin
        araddr_m_inf = 32'b0;
    end
end

//arvalid_m_inf
always @(*) begin
    if((in_valid && !hit) || current_state == REQ)
        arvalid_m_inf = 1'b1;
    else
        arvalid_m_inf = 1'b0;
end

//rready_m_inf
assign rready_m_inf =( (current_state==REQ) ||(current_state == WAIT) ) ? 1'b1 : 1'b0;

//=============================================
//tag_reg 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        tag_reg <= 5'b0;
    else if(in_valid)
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

//hit
always @(*) begin
    if(sram_valid && (tag_reg == tag))
        hit = 1'b1;
    else
        hit = 1'b0;
end
//sram_WEB
assign sram_WEB = !(current_state == WAIT);
reg [7:0] count_addr;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_addr <= 0;
	end else if(rvalid_m_inf)
		count_addr <= count_addr + 1;
    else if(current_state == IDLE) 
        count_addr <= 0;
	else
		count_addr <= count_addr;
end

//sram addr
always @(*) begin
    if(current_state == WAIT)  sram_addr = count_addr;
    // else if (current_state == IDLE) sram_addr = in_address[7:0];
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
        out_data <= 1'b0;
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
    out_valid,
    sram_WEB,
    sram_addr,sram_data,

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
    bready_m_inf
);
input  clk, rst_n , in_valid;
input [15:0]                in_address;
input [DATA_WIDTH-1:0]      in_data;
output  wire                out_valid;
//sram
output  wire [DATA_WIDTH-1:0]sram_data;
output  wire                 sram_WEB;
output  wire [6:0]           sram_addr;
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf; // 4 bits  =0
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf; // 32 bits 
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf; // 3 bits  =001 (2Bytes)
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf; // 2 bits  =01 (INCR)
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf; // 7 bits = 0 (write 1)
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

assign awid_m_inf = 4'd0;
assign awsize_m_inf = 3'b001;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 7'd0;

//==============================================
// reg define
//=============================================
// wire [4:0] tag = in_address[11:7];
// wire [6:0] index = in_address[6:0];
//==============================================
// FSM
//=============================================
reg [1:0] current_state, next_state;
parameter IDLE = 2'b00;
parameter REQ = 2'b01;
parameter WRITE = 2'b10;
parameter WAIT = 2'b11;

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
// awaddr_m_inf maybe
assign awaddr_m_inf  = (current_state == REQ) ? {16'd0,in_address}  :0;
assign awvalid_m_inf = (current_state == REQ) ;
assign wlast_m_inf   = (current_state == WRITE);
assign wvalid_m_inf  = (current_state == WRITE);
assign bready_m_inf  = (current_state == WRITE) || (current_state == WAIT);
assign wdata_m_inf   = (wvalid_m_inf) ? in_data : 0;
assign out_valid     = bvalid_m_inf;
assign sram_data     = in_data ;
assign sram_WEB      = !(current_state== WAIT) ;
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
