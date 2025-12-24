/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: CONVEX
// FILE NAME: CONVEX.v
// VERSRION: 1.0
// DATE: August 15, 2025
// AUTHOR: Chao-En Kuo, NYCU IAIS
// DESCRIPTION: ICLAB2025FALL / LAB3 / CONVEX
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module CONVEX (
	// Input
	rst_n,
	clk,
	in_valid,
	pt_num,
	in_x,
	in_y,
	// Output
	out_valid,
	out_x,
	out_y,
	drop_num
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n;
input				clk;

input				in_valid;
input		[8:0]	pt_num;
input		[9:0]	in_x;
input		[9:0]	in_y;

output reg			out_valid;
output reg	[9:0]	out_x;
output reg 	[9:0]	out_y;
output reg	[6:0]	drop_num;
//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter WAIT_TRIANGLE = 3'd0;
parameter CROSS =3'd1;
parameter UPDATE_HULL =3'd2;
parameter OUTPUT = 3'd3;
parameter RESET = 3'd4;
reg [2:0] current_state,next_state;

integer i;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [8:0] point_count;
reg [7:0] cross_cnt,update_cnt,output_cnt;
reg [7:0] Hull_num;
reg signed [23:0] cross_value; 
reg [9:0] Hull_x [0:128];
reg [9:0] Hull_y [0:128];
reg [9:0] out_x_reg[0:128];
reg [9:0] out_y_reg[0:128];
reg [1:0] index [0:128];
//---------------------------------------------------------------------
//   counter 
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   IO combination REG DECLARATION
//---------------------------------------------------------------------
reg in_valid_comb;
reg out_valid_comb;
reg [9:0] out_x_comb,out_y_comb;
reg [6:0] drop_num_comb,drop_num_reg;
reg [8:0] pt_num_comb;
reg [9:0] in_x_comb , in_y_comb;
reg [1:0] cross_zeronum; 
reg [7:0] cross_negetive_num;
//---------------------------------------------------------------------
//   Cross Function 
//---------------------------------------------------------------------
function signed [23:0] cross_product_hw; //bits maybe
    input [9:0] ax, ay, bx, by, cx, cy; //input is c     // end is b      //start is a 
    reg signed [11:0] ux, uy, vx, vy;  // Extended to handle subtraction
    reg signed [23:0] term1, term2;    // Extended to handle multiplication
begin
    ux = bx - ax;
    vy = cy - ay;
	uy = by - ay; 
    vx = cx - ax;
    term1 = ux * vy;
    term2 = uy * vx;
    cross_product_hw = term1 - term2;
end
endfunction

always @(*) begin
	if(current_state == CROSS) begin
	  cross_value =  cross_product_hw (Hull_x[cross_cnt] , Hull_y[cross_cnt],
									  Hull_x[cross_cnt+1] , Hull_y[cross_cnt+1],
									  in_x_comb, in_y_comb
									  );
	end
	else cross_value = 0;
end
//---------------------------------------------------------------------
//   CROSS PRODUCT
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_negetive_num <=0;
	else if(current_state==CROSS && cross_value[23] ==1)
		cross_negetive_num <=cross_negetive_num+1;
	else if(current_state == RESET)
		cross_negetive_num <=0;
	else
		cross_negetive_num <=cross_negetive_num;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_zeronum <=0;
	else if(current_state==CROSS && cross_value ==0)
		cross_zeronum <=cross_zeronum+1;
	else if(current_state == RESET)
		cross_zeronum <=0;
	else
		cross_zeronum <=cross_zeronum;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i=i+1) index[i] <=0;
	else if(current_state==CROSS && (cross_value <=0) ) begin
		index[cross_cnt] <= index[cross_cnt]+1;
		index[cross_cnt+1] <= index[cross_cnt+1]+1;
	end
	else if (current_state==RESET) for(i=0 ; i<=128 ; i=i+1) index[i] <=0;
	else for(i=0 ; i<=128 ; i=i+1) index[i] <=index[i];
end

//---------------------------------------------------------------------
//   input
//---------------------------------------------------------------------


//---------------------------------------------------------------------
//   done
//---------------------------------------------------------------------
wire triangle_done,cross_done,update_done,output_done,pattern_done;
assign triangle_done = (point_count ==3 ) && in_valid;
assign cross_done =  ( Hull_num <= cross_cnt );
assign update_done = ( Hull_num <= update_cnt);
assign output_done = ( drop_num < output_cnt) ;
assign pattern_done =(point_count > pt_num_comb);
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
// reg [2:0] current_state,next_state;
// parameter WAIT_TRIANGLE = 3'd0;
// parameter CROSS =3'd1;
// parameter UPDATE_HULL =3'd2;
// parameter OUTPUT = 3'd3;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state <= WAIT_TRIANGLE ; 
	else current_state <= next_state;
end

always @(*) begin
	case (current_state) 
		WAIT_TRIANGLE : next_state = triangle_done ? CROSS 			: current_state;
		CROSS 		  : next_state = cross_done    ? UPDATE_HULL	: current_state;
		UPDATE_HULL   : next_state = update_done   ? OUTPUT			: current_state;
		OUTPUT        : next_state = output_done   ? RESET      	: current_state;
		RESET 		  : next_state = pattern_done  ? WAIT_TRIANGLE  : CROSS ; 
		default 	  : next_state = current_state;
	endcase 
end

//---------------------------------------------------------------------
//   counter 
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		update_cnt <= 0;
	else if (current_state == UPDATE_HULL)
		update_cnt <= update_cnt + 1;
	else 
		update_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_cnt <=0;
	else if (current_state == CROSS && !cross_done)
		cross_cnt <= cross_cnt + 1;
	else 
		cross_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		output_cnt <=0;
	else if (current_state == OUTPUT)
		output_cnt <= output_cnt + 1;
	else 
		output_cnt <= 0;
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		point_count <=0;
	else if (in_valid)
		point_count <= point_count+1;
	else if (current_state == RESET && pattern_done) //maybe
		point_count <=0;
	else 
		point_count <= point_count;
end
//---------------------------------------------------------------------
//   Hull number
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		Hull_num <=0;
	else if (current_state ==RESET)
		Hull_num <=0;
	else if (current_state ==WAIT_TRIANGLE)
		Hull_num <=3;
	else
		case (cross_zeronum)
			0 : begin
			  case (cross_negetive_num)
				0 : Hull_num <=Hull_num;
				1 : Hull_num <=Hull_num+1;
				2 : Hull_num <=Hull_num;
				default: Hull_num <=Hull_num-cross_negetive_num+2;
			  endcase
			end
			1 : begin
				if(cross_negetive_num>1) Hull_num <= Hull_num - (cross_negetive_num-1) ;
				else	Hull_num <=Hull_num;
			end
			default: Hull_num <=Hull_num;
		endcase
end
//---------------------------------------------------------------------
//   reset  Hull
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   update  Hull
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i<129 ; i = i+1)
			Hull_x[i] <=0;
	end
	else if(current_state == WAIT_TRIANGLE)
		Hull_x[point_count-1] <=in_x_comb;
	// else if (current_state == UPDATE_HULL)
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i<129 ; i = i+1)
			Hull_y[i] <=0;
	end
	else if(current_state == WAIT_TRIANGLE)
		Hull_y[point_count-1] <=in_y_comb;
	// else if (current_state == UPDATE_HULL)
end
//---------------------------------------------------------------------
//   drop number 
//---------------------------------------------------------------------
always @(*) begin
	if(current_state == OUTPUT) drop_num_comb = drop_num_reg;
	else drop_num_comb = 0 ;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) drop_num_reg<=0;
	else if(current_state == WAIT_TRIANGLE || current_state ==RESET) drop_num_reg<=0;
	else if(current_state == CROSS)
	begin
		case (cross_zeronum)
			0 : begin
				if(cross_negetive_num<2) drop_num_reg <= !cross_negetive_num;
				else drop_num_reg<=cross_negetive_num-1;
			end
			1 : begin
				if(cross_negetive_num>0) drop_num_reg <= cross_negetive_num;
				else	drop_num_reg <=1;
			end
			2 :  drop_num_reg <= 1;
			// default: drop_num_reg <=drop_num;
		endcase
	end
end

//---------------------------------------------------------------------
//   drop hull or input 
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   output
//---------------------------------------------------------------------

always @(*) begin
	if(current_state == OUTPUT) out_valid_comb =1;
	else if (current_state ==WAIT_TRIANGLE && in_valid_comb) out_valid_comb =1;
	else  out_valid_comb =0;
end

always @(*) begin
	if (current_state == WAIT_TRIANGLE) out_x_comb = 0 ;
	else if(current_state == OUTPUT) out_x_comb = out_x_reg[output_cnt];
	else out_x_comb = 0;
end

always @(*) begin
	if (current_state == WAIT_TRIANGLE) out_y_comb = 0 ;
	else if(current_state == OUTPUT) out_y_comb = out_y_reg[output_cnt];
	else out_y_comb = 0;
end

//---------------------------------------------------------------------
//   input reset 
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		in_valid_comb <=0;
	else 
		in_valid_comb <= in_valid;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pt_num_comb <=0;
	end
	else if(in_valid && pt_num>0)begin
		pt_num_comb <=pt_num ; 
	end
	else  pt_num_comb <=pt_num_comb;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)			in_x_comb <= 0;
	else if(in_valid)	in_x_comb <= in_x;
	else  				in_x_comb <= in_x_comb;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)			in_y_comb <= 0;
	else if(in_valid)	in_y_comb <= in_y;
	else  				in_y_comb <= in_y_comb;
end
//---------------------------------------------------------------------
//   output reset 
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <=0;
	end
	else begin
		out_valid <=out_valid_comb ; 
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		drop_num <=0;
	end
	else begin
		drop_num <=drop_num_comb ; 
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_x <=0;
	end
	else begin
		out_x <=out_x_comb ; 
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_y <=0;
	end
	else begin
		out_y <=out_y_comb ; 
	end
end

endmodule