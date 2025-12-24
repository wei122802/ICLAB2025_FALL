//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   ICLAB 2025 Fall 
// Lab11 Exercise : Geometric Transform Engine (GTE)
//      File Name : GTE.v
//    Module Name : GTE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`timescale 1ns/10ps

`include "PATTERN.v"
// `include "PATTERN.sv"

`ifdef RTL
    `include "GTE.v"
`elsif GATE
    `include "GTE_SYN.v"
`elsif POST
    `include "CHIP.v"
`endif
		  	
module TESTBED;

wire          clk;
wire          rst_n;
wire          in_valid_data;
wire   [7:0]  data;
wire          in_valid_cmd;
wire  [17:0]  cmd;
wire          busy;

initial begin
	`ifdef RTL
		// $fsdbDumpfile("GTE.fsdb");
		// $fsdbDumpvars(0,"+mda");
		// $fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("GTE_SYN.sdf", u_GTE);
		//$fsdbDumpfile("GTE_SYN.fsdb");
		//$fsdbDumpvars();    
	`endif
	`ifdef POST
		$sdf_annotate("CHIP.sdf", u_CHIP);
		//$fsdbDumpfile("CHIP.fsdb");
		//$fsdbDumpvars();    
	`endif
end

`ifdef RTL
	GTE u_GTE(
		// input signals
		.clk(clk),
		.rst_n(rst_n),

		.in_valid_data(in_valid_data),
		.data(data),

		.in_valid_cmd(in_valid_cmd),
		.cmd(cmd),

		// output signals
		.busy(busy)
	);
`elsif GATE
	GTE u_GTE(
		// input signals
		.clk(clk),
		.rst_n(rst_n),

		.in_valid_data(in_valid_data),
		.data(data),

		.in_valid_cmd(in_valid_cmd),
		.cmd(cmd),

		// output signals
		.busy(busy)
	);
`elsif POST
	CHIP u_CHIP(
		// input signals
		.clk(clk),
		.rst_n(rst_n),

		.in_valid_data(in_valid_data),
		.data(data),

		.in_valid_cmd(in_valid_cmd),
		.cmd(cmd),

		// output signals
		.busy(busy)
	);
`endif

PATTERN u_PATTERN(
    // Output signals
    .clk(clk),
	.rst_n(rst_n),

	.in_valid_data(in_valid_data),
	.data(data),

	.in_valid_cmd(in_valid_cmd),
	.cmd(cmd),

    // Input signals
	.busy(busy)
);
 
endmodule
