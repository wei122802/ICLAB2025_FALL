/**************************************************************************/
// Copyright (c) 2025, SI2 Lab
// MODULE: TESTBED_IP
// FILE NAME: TESTBED_IP.v
// VERSRION: 1.0
// DATE: OCT 15, 2025
// AUTHOR: JHIH-YOU CHEN, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
/**************************************************************************/

`timescale 1ns/1ps

// PATTERN
`include "PATTERN_IP.v"
// `include "PATTERN_IP_design.v"
// `include "PATTERN_IP_python.v"
// DESIGN
`ifdef RTL
	`include "Poker.v"
`elsif GATE
	`include "Poker_SYN.v"
`endif


module TESTBED();

// Parameter
parameter IP_WIDTH =2;

// Connection wires
wire [IP_WIDTH*8-1:0]  IN_HOLE_CARD_NUM;
wire [IP_WIDTH*4-1:0]  IN_HOLE_CARD_SUIT;
wire [19:0]  IN_PUB_CARD_NUM;
wire [9:0]  IN_PUB_CARD_SUIT;
wire [IP_WIDTH-1:0]  OUT_WINNER;

initial begin
 	`ifdef RTL
    	$fsdbDumpfile("Poker.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		//$fsdbDumpfile("Division_IP_demo_SYN.fsdb");
		//$fsdbDumpvars(0,"+mda");
		$sdf_annotate("Poker_SYN.sdf", IP_Poker); 
	`endif
end

`ifdef RTL

	Poker #(.IP_WIDTH(IP_WIDTH)) IP_Poker (
    	.IN_HOLE_CARD_NUM(IN_HOLE_CARD_NUM),
		.IN_HOLE_CARD_SUIT(IN_HOLE_CARD_SUIT),
		.IN_PUB_CARD_NUM(IN_PUB_CARD_NUM),
		.IN_PUB_CARD_SUIT(IN_PUB_CARD_SUIT),
    	.OUT_WINNER(OUT_WINNER)
	);

	PATTERN #(.IP_WIDTH(IP_WIDTH)) I_PATTERN(
		.IN_HOLE_CARD_NUM(IN_HOLE_CARD_NUM),
		.IN_HOLE_CARD_SUIT(IN_HOLE_CARD_SUIT),
		.IN_PUB_CARD_NUM(IN_PUB_CARD_NUM),
		.IN_PUB_CARD_SUIT(IN_PUB_CARD_SUIT),
    	.OUT_WINNER(OUT_WINNER)
	);
	
`elsif GATE
    Poker #(.IP_WIDTH(IP_WIDTH)) IP_Poker (
    	.IN_HOLE_CARD_NUM(IN_HOLE_CARD_NUM),
		.IN_HOLE_CARD_SUIT(IN_HOLE_CARD_SUIT),
		.IN_PUB_CARD_NUM(IN_PUB_CARD_NUM),
		.IN_PUB_CARD_SUIT(IN_PUB_CARD_SUIT),
    	.OUT_WINNER(OUT_WINNER)
	);

	PATTERN #(.IP_WIDTH(IP_WIDTH)) MY_PATTERN(
		.IN_HOLE_CARD_NUM(IN_HOLE_CARD_NUM),
		.IN_HOLE_CARD_SUIT(IN_HOLE_CARD_SUIT),
		.IN_PUB_CARD_NUM(IN_PUB_CARD_NUM),
		.IN_PUB_CARD_SUIT(IN_PUB_CARD_SUIT),
    	.OUT_WINNER(OUT_WINNER)
	);

`endif  

endmodule
