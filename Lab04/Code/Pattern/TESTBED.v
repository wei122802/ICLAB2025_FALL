//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2025 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Chung-Shuo Lee
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : V 1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
  `include "CNN.v"
`endif
`ifdef GATE
  `include "CNN_SYN.v"
`endif

module TESTBED;

wire          clk, rst_n, in_valid;
wire  [31:0]  Image;
wire  [31:0]  Kernel_ch1;
wire  [31:0]  Kernel_ch2;
wire  [31:0]  Weight_Bias;
wire          task_number;
wire  [1:0]   mode;
wire  [3:0]   capacity_cost;
wire          out_valid;
wire  [31:0]  out;

initial begin
  `ifdef RTL
    // $fsdbDumpfile("CNN.fsdb");
	  // $fsdbDumpvars(0,"+mda");
    // $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("CNN_SYN.sdf", u_CNN);
    // $fsdbDumpfile("CNN_SYN.fsdb");
    // $fsdbDumpvars();  
  `endif
end

`ifdef RTL
CNN u_CNN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .Image(Image),
    .Kernel_ch1(Kernel_ch1),
    .Kernel_ch2(Kernel_ch2),
    .Weight_Bias(Weight_Bias),
    .task_number(task_number),
    .mode(mode),
    .capacity_cost(capacity_cost),
    .out_valid(out_valid),
    .out(out)
    );
`endif

`ifdef GATE
CNN u_CNN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .Image(Image),
    .Kernel_ch1(Kernel_ch1),
    .Kernel_ch2(Kernel_ch2),
    .Weight_Bias(Weight_Bias),
    .task_number(task_number),
    .mode(mode),
    .capacity_cost(capacity_cost),
    .out_valid(out_valid),
    .out(out)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .Image(Image),
    .Kernel_ch1(Kernel_ch1),
    .Kernel_ch2(Kernel_ch2),
    .Weight_Bias(Weight_Bias),
    .task_number(task_number),
    .mode(mode),
    .capacity_cost(capacity_cost),
    .out_valid(out_valid),
    .out(out)
    );
  
 
endmodule
