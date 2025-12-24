module FIFO_syn #(parameter WIDTH=16, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk3,
    flag_clk3_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output flag_fifo_to_clk2;
input  flag_clk2_to_fifo;

output flag_fifo_to_clk3;
input  flag_clk3_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr , wptr_d; //log2(64) = 6
reg [$clog2(WORDS):0] rptr , rptr_d;
reg [6:0] waddr , raddr;
wire [6:0] rq2_wptr , wq2_rptr;

reg [6:0] r_bin_d  ;
reg [6:0] w_bin_d ;

always @(*) begin
    r_bin_d = raddr + (rinc & ~rempty) ;
end

always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) raddr <=0;
    else raddr <= r_bin_d ;
end

always @(*) begin
    w_bin_d = waddr + (winc & ~wfull) ;
end

always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) waddr <=0;
    else waddr <= w_bin_d ;
end

always @(*) rptr_d = r_bin_d ^ (r_bin_d >> 1);
always @(*) wptr_d = w_bin_d ^ (w_bin_d >> 1);

always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) wptr <=0;
    else wptr <= wptr_d ;
end

always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) rptr <=0;
    else rptr <= rptr_d ;
end

always @(*) begin
    rempty = rptr == rq2_wptr ; 
end

always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) wfull <=0;
    else wfull <= ({~wptr_d[6:5],wptr_d[4:0]}== wq2_rptr) ;
end

NDFF_BUS_syn #(7) sync_wq2 (.D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n));
NDFF_BUS_syn #(7) sync_rq2 (.D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n));

// rdata
//  Add one more register stage to rdata
reg rinc_q;

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n)
        rinc_q <= 0;
    else
        rinc_q <= rinc;
end

always @(posedge rclk) begin
    if (rinc_q)
        rdata <= rdata_q;
end

wire wen;
assign wen = ~(winc);
DUAL_64X16X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(wen),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr[0]),
    .A1(waddr[1]),
    .A2(waddr[2]),
    .A3(waddr[3]),
    .A4(waddr[4]),
    .A5(waddr[5]),
    .B0(raddr[0]),
    .B1(raddr[1]),
    .B2(raddr[2]),
    .B3(raddr[3]),
    .B4(raddr[4]),
    .B5(raddr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DIB8(1'b0),
    .DIB9(1'b0),
    .DIB10(1'b0),
    .DIB11(1'b0),
    .DIB12(1'b0),
    .DIB13(1'b0),
    .DIB14(1'b0),
    .DIB15(1'b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15])
);


endmodule
