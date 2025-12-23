/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: August 15, 2025
// AUTHOR: Chao-En Kuo, NYCU IAIS
// DESCRIPTION: ICLAB2025FALL / LAB3 / TESTBED
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
`timescale 1ns/10ps

// `include "PATTERN.v"
`include "PATTERN_TA.vp"
`ifdef RTL
    `include "CONVEX.v"
	// `include "CONVEX_encrypted.v"
`endif
`ifdef GATE
    `include "CONVEX_SYN.v"
`endif

module TESTBED;

wire			rst_n;
wire			clk;

wire			in_valid;
wire	[8:0]	pt_num;
wire	[9:0]	in_x;
wire	[9:0]	in_y;

wire			out_valid;
wire	[9:0]	out_x;
wire	[9:0]	out_y;
wire	[6:0]	drop_num;



initial begin
    `ifdef RTL
        $fsdbDumpfile("CONVEX.fsdb");
        $fsdbDumpvars(0,"+mda");
    `endif
    `ifdef GATE
        $sdf_annotate("CONVEX_SYN.sdf", u_CONVEX);
        $fsdbDumpfile("CONVEX_SYN.fsdb");
        $fsdbDumpvars(0,"+mda"); 
    `endif
end

CONVEX u_CONVEX(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(in_valid),
	.pt_num(pt_num),
	.in_x(in_x),
	.in_y(in_y),
	.out_valid(out_valid),
	.out_x(out_x),
	.out_y(out_y),
	.drop_num(drop_num)
);
    
PATTERN u_PATTERN(
	.rst_n(rst_n),
	.clk(clk),
	.in_valid(in_valid),
	.pt_num(pt_num),
	.in_x(in_x),
	.in_y(in_y),
	.out_valid(out_valid),
	.out_x(out_x),
	.out_y(out_y),
	.drop_num(drop_num)
);

endmodule
