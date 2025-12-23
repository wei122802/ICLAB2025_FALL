/**************************************************************************
 * Copyright (c) 2025, OASIS Lab
 * MODULE: TESTBED
 * FILE NAME: TESTBED.v
 * VERSRION: 1.0
 * DATE: Oct 29, 2025
 * AUTHOR: Chao-En Kuo, NYCU IAIS
 * DESCRIPTION: ICLAB2025FALL / LAB7 / TESTBED
 * MODIFICATION HISTORY:
 * Date                 Description
 * 
 *************************************************************************/
 `timescale 1ns/1ps
// `include "PATTERN.v"
// `include "PATTERN_other1.v"
// `include "PATTERN_other2.v"
// `include "PATTERN_other3.v"
`include "PATTERN.vp"
// `include "PATTERN_other4.v"
`ifdef RTL
`include "NTT_TOP.v"
`elsif GATE
`include "NTT_TOP_SYN.v"
`endif

module TESTBED();

wire            clk1, clk2, clk3;
wire            rst_n;
wire            in_valid;
wire    [31:0]  in_data;
wire            out_valid;
wire    [15:0]  out_data;

initial begin
  `ifdef RTL
    // $fsdbDumpfile("NTT_TOP.fsdb");
    // $fsdbDumpvars(0,"+mda");
  `elsif GATE
    // $fsdbDumpfile("NTT_TOP.fsdb");
    $sdf_annotate("NTT_TOP_SYN_pt.sdf",I_NTT,,,"maximum");      
    // $fsdbDumpvars(0,"+mda");
  `endif
end

NTT_TOP I_NTT (
    // Input signals
	.clk1(clk1),
	.clk2(clk2),
	.clk3(clk3),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_data(in_data),
    // Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);


PATTERN I_PATTERN (
    // Output signals
	.clk1(clk1),
	.clk2(clk2),
	.clk3(clk3),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_data(in_data),
    // Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);

endmodule