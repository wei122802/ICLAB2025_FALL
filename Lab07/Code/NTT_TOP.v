/**************************************************************************
 * Copyright (c) 2025, OASIS Lab
 * MODULE: NTT_TOP
 * FILE NAME: NTT_TOP.v
 * VERSRION: 1.0
 * DATE: Oct 29, 2025
 * AUTHOR: Chao-En Kuo, NYCU IAIS
 * DESCRIPTION: ICLAB2025FALL / LAB7 / NTT_TOP
 * MODIFICATION HISTORY:
 * Date                 Description
 * 
 *************************************************************************/
`include "DESIGN_module.v"
`include "synchronizer/Handshake_syn.v"
`include "synchronizer/FIFO_syn.v"
`include "synchronizer/NDFF_syn.v"
`include "synchronizer/NDFF_BUS_syn.v"

module NTT_TOP (
	// Input signals
	clk1,
	clk2,
	clk3,
	rst_n,
	in_valid,
	in_data,
	//  Output signals
	out_valid,
	out_data
);
//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------		
input         clk1; 
input         clk2;
input         clk3;			
input         rst_n;
input         in_valid;
input  [31:0] in_data;
output        out_valid;
output [15:0] out_data; 	

//---------------------------------------------------------------------
//   REG & WIRE
//---------------------------------------------------------------------
wire        sidle;
wire        data_valid_clk1;
wire [31:0] data_clk1;
wire        in_data_valid_clk2;
wire [31:0] in_data_clk2;
wire        mul_busy;
wire        out_data_valid_clk2;
wire [15:0] out_data_clk2;
wire        fifo_full;
wire        fifo_empty;
wire        fifo_rinc;
wire [15:0] fifo_rdata; 

// Custom flags to use if needed
wire flag_handshake_to_clk1;
wire flag_clk1_to_handshake;

wire flag_handshake_to_clk2;
wire flag_clk2_to_handshake;

wire flag_fifo_to_clk2;
wire flag_clk2_to_fifo;

wire flag_fifo_to_clk3;
wire flag_clk3_to_fifo;

CLK_1_MODULE u_input (
    .clk (clk1),
    .rst_n (rst_n),
    .in_valid (in_valid),
    .in_data (in_data),
    .out_idle (sidle),
    .out_valid (data_valid_clk1),
    .out_data (data_clk1),

    .flag_handshake_to_clk1(flag_handshake_to_clk1),
    .flag_clk1_to_handshake(flag_clk1_to_handshake)
);


Handshake_syn #(32) u_Handshake_syn (
    .sclk (clk1),
    .dclk (clk2),
    .rst_n (rst_n),
    .sready (data_valid_clk1),
    .din (data_clk1),
    .dbusy (mul_busy),
    .sidle (sidle),
    .dvalid (in_data_valid_clk2),
    .dout (in_data_clk2),

    .flag_handshake_to_clk1(flag_handshake_to_clk1),
    .flag_clk1_to_handshake(flag_clk1_to_handshake),

    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake)
);

CLK_2_MODULE u_NTT (
	.clk (clk2),
    .rst_n (rst_n),
    .in_valid (in_data_valid_clk2),
    .in_data (in_data_clk2),
    .fifo_full (fifo_full),
    .out_valid (out_data_valid_clk2),
    .out_data (out_data_clk2),
    .busy (mul_busy),

    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake),

    .flag_fifo_to_clk2(flag_fifo_to_clk2),
    .flag_clk2_to_fifo(flag_clk2_to_fifo)
);

FIFO_syn #(.WIDTH(16), .WORDS(64)) u_FIFO_syn (
    .wclk (clk2),
    .rclk (clk3),
    .rst_n (rst_n),
    .winc (out_data_valid_clk2),
    .wdata (out_data_clk2),
    .wfull (fifo_full),
    .rinc (fifo_rinc),
    .rdata (fifo_rdata),
    .rempty (fifo_empty),

    .flag_fifo_to_clk2(flag_fifo_to_clk2),
    .flag_clk2_to_fifo(flag_clk2_to_fifo),

    .flag_fifo_to_clk3(flag_fifo_to_clk3),
	.flag_clk3_to_fifo(flag_clk3_to_fifo)
);

CLK_3_MODULE u_output (
    .clk (clk3),
    .rst_n (rst_n),
    .fifo_empty (fifo_empty),
    .fifo_rdata (fifo_rdata),
    .fifo_rinc (fifo_rinc),
    .out_valid (out_valid),
    .out_data (out_data),

    .flag_fifo_to_clk3(flag_fifo_to_clk3),
	.flag_clk3_to_fifo(flag_clk3_to_fifo)
);

endmodule