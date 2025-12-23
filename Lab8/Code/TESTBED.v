//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2025 ICLAB FALL Course
//   Lab08       : Testbench and Pattern
//   Author      : Ying-Yu (Inyi) Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps
`ifdef RTL
    `ifdef NCG
    `include "PATTERN.v"
    `endif
    `ifdef CG
    `include "PATTERN_CG.v"
    `endif
`endif
`ifdef GATE
    `ifdef NCG
    `include "PATTERN.v"
    `endif
    `ifdef CG
    `include "PATTERN_CG.v"
    `endif
`endif

`ifdef RTL
  `include "SAD.v"
`endif
`ifdef GATE
  `include "SAD_SYN.v"
`endif

	  		  	
module TESTBED;

    wire clk, rst_n, in_valid;
    wire cg_en;
    wire signed [5:0] in_data1;
    wire [3:0] T;
    wire signed [7:0] in_data2;
    wire signed [7:0] w_Q;
    wire signed [7:0] w_K;
    wire signed [7:0] w_V;
    wire out_valid;
    wire signed [91:0] out_data;


initial begin
  `ifdef RTL
    `ifdef NCG
    $fsdbDumpfile("SAD.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
    `endif

    `ifdef CG
    $fsdbDumpfile("SAD_CG.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
    `endif
  `endif
  `ifdef GATE
    `ifdef NCG
            $sdf_annotate("SAD_SYN.sdf", u_SAD,,,"maximum");
            $fsdbDumpfile("SAD_SYN.fsdb");
            $fsdbDumpvars();    
    `endif
    `ifdef CG   
            $sdf_annotate("SAD_SYN.sdf", u_SAD);
            $fsdbDumpfile("SAD_SYN_CG.fsdb");
            $fsdbDumpvars();    
    `endif

  `endif
end

`ifdef RTL
SAD u_SAD(
    // Input signals
    .clk(clk),
    .rst_n(rst_n),
    .cg_en(cg_en),
    .in_valid(in_valid),
    .in_data1(in_data1),
    .T(T),
    .in_data2(in_data2),
    .w_Q(w_Q),
    .w_K(w_K),
    .w_V(w_V),

    // Output signals
    .out_valid(out_valid),
    .out_data(out_data)
);
`endif

`ifdef GATE
SAD u_SAD(
    // Input signals
    .clk(clk),
    .rst_n(rst_n),
    .cg_en(cg_en),
    .in_valid(in_valid),
    .in_data1(in_data1),
    .T(T),
    .in_data2(in_data2),
    .w_Q(w_Q),
    .w_K(w_K),
    .w_V(w_V),

    // Output signals
    .out_valid(out_valid),
    .out_data(out_data)
);
`endif

PATTERN u_PATTERN
(
    // Output signals
    .clk(clk),
    .rst_n(rst_n),
    .cg_en(cg_en),
    .in_valid(in_valid),
    .in_data1(in_data1),
    .T(T),
    .in_data2(in_data2),
    .w_Q(w_Q),
    .w_K(w_K),
    .w_V(w_V),

    // Input signals
    .out_valid(out_valid),
    .out_data(out_data)
);
  
endmodule
