//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		: Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps
`include "PATTERN.v"
`ifdef RTL
  `include "MPCA.v"
`endif
`ifdef GATE
  `include "MPCA_SYN.v"
`endif
 
module TESTBED;

//Connection wires
wire [127:0] packets;
wire  [11:0] channel_load;
wire   [8:0] channel_capacity;
wire  [63:0] KEY;

wire [15:0] grant_channel ;


initial begin
  `ifdef RTL
    $fsdbDumpfile("MPCA.fsdb");
	  $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("MPCA_SYN.sdf", DUT_MPCA);
    $fsdbDumpfile("MPCA_SYN.fsdb");
	  $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();    
  `endif
end

MPCA DUT_MPCA(

.packets(packets),
.channel_load(channel_load),
.channel_capacity(channel_capacity),
.KEY(KEY),

.grant_channel(grant_channel)

);

PATTERN My_PATTERN(
  .packets(packets),
  .channel_load(channel_load),
  .channel_capacity(channel_capacity),
  .KEY(KEY),

  .grant_channel(grant_channel)
);
 
endmodule
