//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2025 Fall
//   Lab05 Exercise		: H.264 Lite Prediction and Transform Engine (HLPTE)
//   Author     		: Bang-Yuan Xiao (xuan95732@gmail.com)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2025-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "HLPTE.v"
`elsif GATE
    `include "HLPTE_SYN.v"
`elsif POST
    `include "CHIP.v"
`endif

	  		  	
module TESTBED;

wire                clk;
wire                rst_n;
wire                in_valid_data;
wire                in_valid_param;

wire         [7:0]  data;
wire         [3:0]  index;
wire                mode;
wire         [4:0]  QP;

wire                out_valid;
wire signed [31:0]  out_value;

initial begin
	`ifdef RTL
		// $fsdbDumpfile("HLPTE.fsdb");
		// $fsdbDumpvars(0,"+mda");
		// $fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("HLPTE_SYN.sdf", u_HLPTE);
		//$fsdbDumpfile("HLPTE_SYN.fsdb");
		//$fsdbDumpvars();    
	`endif
	`ifdef POST
		$sdf_annotate("CHIP.sdf", u_CHIP);
		//$fsdbDumpfile("CHIP.fsdb");
		//$fsdbDumpvars();    
	`endif
end

`ifdef RTL
	HLPTE u_HLPTE(
		// input signals
    	.clk(clk),
    	.rst_n(rst_n),
    	.in_valid_data(in_valid_data),
    	.in_valid_param(in_valid_param),

    	.data(data),
		.index(index),
		.mode(mode),
    	.QP(QP),

    	// output signals
    	.out_valid(out_valid),
    	.out_value(out_value)
	);
`elsif GATE
	HLPTE u_HLPTE(
		// input signals
    	.clk(clk),
    	.rst_n(rst_n),
    	.in_valid_data(in_valid_data),
    	.in_valid_param(in_valid_param),

    	.data(data),
		.index(index),
		.mode(mode),
    	.QP(QP),

    	// output signals
    	.out_valid(out_valid),
    	.out_value(out_value)
	);
`elsif POST
	CHIP u_CHIP(
		// input signals
    	.clk(clk),
    	.rst_n(rst_n),
    	.in_valid_data(in_valid_data),
    	.in_valid_param(in_valid_param),

    	.data(data),
		.index(index),
		.mode(mode),
    	.QP(QP),

    	// output signals
    	.out_valid(out_valid),
    	.out_value(out_value)
	);
`endif

PATTERN u_PATTERN(
    // output signals
    .clk(clk),
    .rst_n(rst_n),
    .in_valid_data(in_valid_data),
    .in_valid_param(in_valid_param),

    .data(data),
	.index(index),
	.mode(mode),
    .QP(QP),

    // input signals
    .out_valid(out_valid),
    .out_value(out_value)
);
 
endmodule
