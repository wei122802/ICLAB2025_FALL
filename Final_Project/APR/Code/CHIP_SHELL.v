// ##############################################################
//   You can modify by your own
//   You can modify by your own
//   You can modify by your own
// ##############################################################

module CHIP(
    // input signals
    clk,
    rst_n,
    in_valid,
    in_valid2,
    in_data,
    // output signals
    out_valid,
    out_sad
);


input            clk, rst_n, in_valid, in_valid2;
input     [8:0]  in_data;

output           out_valid;
output           out_sad;

//==================================================================
// reg & wire
//==================================================================
wire             C_clk;
wire             C_rst_n;
wire             C_in_valid;
wire             C_in_valid2;


wire     [8:0]  C_in_data;

wire             C_out_valid;
wire             C_out_sad;

//==================================================================
// CORE
//==================================================================
MVDM CORE(
	// input signals
    .clk(C_clk),
    .rst_n(C_rst_n),
    .in_valid(C_in_valid), 
    .in_valid2(C_in_valid2),
    
    .in_data(C_in_data),
	
    // output signals
    .out_valid(C_out_valid),
    .out_sad(C_out_sad)
);

//==================================================================
// INPUT PAD
// Syntax: XMD PAD_NAME ( .O(CORE_PORT_NAME), .I(CHIP_PORT_NAME), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//     Ex: XMD    I_CLK ( .O(C_clk),          .I(clk),            .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//==================================================================
// You need to finish this part

XMD    I_CLK      ( .O(C_clk),          .I(clk),         .PU(1'b0), .PD(1'b0), .SMT(1'b0)); //
XMD    I_RSTN     ( .O(C_rst_n),       .I(rst_n),        .PU(1'b0), .PD(1'b0), .SMT(1'b0)); //
XMD    I_INVALID  ( .O(C_in_valid),    .I(in_valid),     .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INVALID2 ( .O(C_in_valid2),   .I(in_valid2),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA0  ( .O(C_in_data[0]), .I(in_data[0]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA1  ( .O(C_in_data[1]), .I(in_data[1]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA2  ( .O(C_in_data[2]), .I(in_data[2]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA3  ( .O(C_in_data[3]), .I(in_data[3]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA4  ( .O(C_in_data[4]), .I(in_data[4]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA5  ( .O(C_in_data[5]), .I(in_data[5]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA6  ( .O(C_in_data[6]), .I(in_data[6]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA7  ( .O(C_in_data[7]), .I(in_data[7]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_INDATA8  ( .O(C_in_data[8]), .I(in_data[8]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));

//==================================================================
// OUTPUT PAD
// Syntax: YA2GSD PAD_NAME (.I(CORE_PIN_NAME), .O(PAD_PIN_NAME), .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//     Ex: YA2GSD  O_VALID (.I(C_out_valid),   .O(out_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//==================================================================
// You need to finish this part
YA2GSD  O_OUTVALID (.I(C_out_valid),   .O(out_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD  O_OUTSAD   (.I(C_out_sad),     .O(out_sad),      .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//==================================================================
// I/O power 3.3V pads x? (DVDD + DGND)
// Syntax: VCC3IOD/GNDIOD PAD_NAME ();
//    Ex1: VCC3IOD        VDDP0 ();
//    Ex2: GNDIOD         GNDP0 ();
//==================================================================
// You need to finish this part
VCC3IOD     VDDP0 (); 
GNDIOD      GNDP0 (); 
VCC3IOD     VDDP1 ();
GNDIOD      GNDP1 ();
VCC3IOD     VDDP2 ();
GNDIOD      GNDP2 ();
VCC3IOD	    VDDP3 ();	
GNDIOD	    GNDP3 ();
//==================================================================
// Core power 1.8V pads x? (VDD + GND)
// Syntax: VCCKD/GNDKD PAD_NAME ();
//    Ex1: VCCKD       VDDC0 ();
//    Ex2: GNDKD       GNDC0 ();
//==================================================================
// You need to finish this part
VCCKD       VDDC0 ();
GNDKD       GNDC0 ();
VCCKD       VDDC1 ();
GNDKD       GNDC1 ();
VCCKD       VDDC2 ();
GNDKD       GNDC2 ();
VCCKD	    VDDC3 ();
GNDKD	    GNDC3 ();

endmodule

