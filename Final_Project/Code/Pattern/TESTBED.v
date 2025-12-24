//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2018 Fall
//   Lab02 Practice		: Complex Number Calculater
//   Author     		: Ping-Yuan Tsai (bubblegame@si2lab.org)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESETBED.v
//   Module Name : TESETBED
//   Release version : V1.0 (Release Date: 2018-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps

// `include "PATTERN.v"
// `include "PATTERN_other1.v"
`include "PATTERN_other2.v"
// `include "PATTERN_other3.v"


`ifdef RTL
  `include "MVDM.v"
`endif
`ifdef GATE
  `include "MVDM_SYN.v"
`endif
`ifdef POST
  `include "CHIP.v"
`endif

	  		  	
module TESTBED;

wire clk, rst_n, in_valid, in_valid2;
wire [8:0] in_data;
wire out_valid;
wire out_sad;


initial begin
  `ifdef RTL
    // $fsdbDumpfile("MVDM.fsdb");
	  // $fsdbDumpvars(0,"+mda");
    // $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("MVDM_SYN.sdf", u_MVDM);
    //$fsdbDumpfile("MVDM_SYN.fsdb");
    //$fsdbDumpvars();    
  `endif
  `ifdef POST
    $sdf_annotate("CHIP.sdf", u_CHIP);
    //$fsdbDumpfile("MVDM_POST.fsdb");
    //$fsdbDumpvars();    
  `endif
end

`ifdef RTL
MVDM u_MVDM(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid), 
    .in_valid2(in_valid2),
    .in_data(in_data),
    .out_valid(out_valid),
    .out_sad(out_sad)
    );
`endif

`ifdef GATE
MVDM u_MVDM(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid), 
    .in_valid2(in_valid2),
    .in_data(in_data),
    .out_valid(out_valid),
    .out_sad(out_sad)
    );
`endif

`ifdef POST
CHIP u_CHIP(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid), 
    .in_valid2(in_valid2),
    .in_data(in_data),
    .out_valid(out_valid),
    .out_sad(out_sad)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid), 
    .in_valid2(in_valid2),
    .in_data(in_data),
    .out_valid(out_valid),
    .out_sad(out_sad)
    );
  
 
endmodule
