/**************************************************************************/
// CopyrigBCH (c) 2025, SI2 Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: Oct 15, 2025
// AUTHOR: JHIH-YOU CHEN, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
// 
/**************************************************************************/

`timescale 1ns/1ps

// PATTERN
`include "PATTERN.v"
// `include "PATTERN_1.v"
// DESIGN
`ifdef RTL
	`include "WinRate.v"
`elsif GATE
	`include "WinRate_SYN.v"
`endif


module TESTBED();

	wire clk, in_valid, out_valid;
	wire [71:0] in_hole_num;
    wire [35:0] in_hole_suit;
    wire [11:0] in_pub_num;
    wire [6:0] in_pub_suit;
    wire [62:0] out_win_rate;

initial begin
 	`ifdef RTL
    	$fsdbDumpfile("WinRate.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		//$fsdbDumpfile("BCH_TOP_SYN.fsdb");
		//$fsdbDumpvars(0,"+mda");
		$sdf_annotate("WinRate_SYN.sdf",I_WinRate); 
	`endif
end

WinRate I_WinRate(
    .clk(clk),
	.rst_n(rst_n),
    .in_valid(in_valid),
    .in_hole_num(in_hole_num),
    .in_hole_suit(in_hole_suit),
    .in_pub_num(in_pub_num),
    .in_pub_suit(in_pub_suit),
    .out_valid(out_valid),
    .out_win_rate(out_win_rate)
);


PATTERN I_PATTERN
(
    .clk(clk),
	.rst_n(rst_n),
    .in_valid(in_valid),
    .in_hole_num(in_hole_num),
    .in_hole_suit(in_hole_suit),
    .in_pub_num(in_pub_num),
    .in_pub_suit(in_pub_suit),
    .out_valid(out_valid),
    .out_win_rate(out_win_rate)
);

endmodule
