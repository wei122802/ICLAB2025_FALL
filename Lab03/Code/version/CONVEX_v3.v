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
parameter WAIT_FIRST = 3'd0;
parameter WAIT_SECOND = 3'd1;
parameter WAIT_THIRD = 3'd2;
parameter DEAL_TRIANGLE = 3'd3;
parameter CROSS_PRODUCT = 3'd4;

parameter IDLE   = 2'd0;
parameter UPDATE = 2'd1;
parameter OUTPUT = 2'd2;
integer i;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [9:0] drop_x_reg[0:128];
reg [9:0] drop_y_reg[0:128];
reg [2:0] current_state,next_state;
reg [9:0] new_x , new_y;
reg [9:0] Hull_x [0:128];
reg [9:0] Hull_y [0:128];
reg signed [23:0] cross_; //maybe
reg [1:0] index [0:128];
reg [6:0] needdrop_index;
reg [6:0] continuous_cnt;
reg [9:0] Hull_new_x [0:128];
reg [9:0] Hull_new_y [0:128];
reg [6:0] negetive_index ;
//---------------------------------------------------------------------
//   counter 
//---------------------------------------------------------------------
reg [7:0] cross_cnt ;//max :128
reg [7:0] Hull_num; //max :128
reg [7:0] cross_negetive; //max maybe 126
reg [3:0] cross_zeronum; //maybe [1:0] is enoght
reg [6:0] needdrop_cnt;
// reg [7:0] cross_posetive;
//---------------------------------------------------------------------
//   Output combination REG DECLARATION
//---------------------------------------------------------------------
reg in_valid_comb;
reg [6:0] drop_num_comb;
reg [9:0] out_y_comb ,out_x_comb;
reg out_valid_comb;
reg [8:0] point_most;
reg [8:0] point_count;
//---------------------------------------------------------------------
//   DESIGN
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
//---------------------------------------------------------------------
//   CROSS PRODUCT
//---------------------------------------------------------------------
always @(*) begin
	// if(next_state == DEAL_TRIANGLE)
	// 	cross_ =  cross_product_hw (Hull_x[0] , Hull_y[0],
	// 								Hull_x[1] , Hull_y[1],
	// 								new_x, new_y
	// 	);
	if((next_state==CROSS_PRODUCT||next_state == DEAL_TRIANGLE) && cross_cnt < Hull_num && out_valid_comb==0)
		cross_ =  cross_product_hw (Hull_x[cross_cnt] , Hull_y[cross_cnt],
									Hull_x[(cross_cnt+1)%Hull_num] , Hull_y[(cross_cnt+1)%Hull_num],
									new_x, new_y
		);
	else cross_ = 0;
end


//---------------------------------------------------------------------
//   input
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		in_valid_comb <=0;
	else 
		in_valid_comb <= in_valid;
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		point_most <=0;
	else if(in_valid && pt_num>0)
		point_most <= pt_num;
	else
		point_most <= point_most;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		new_x <=0;
	else if(in_valid)
		new_x <= in_x;
	else
		new_x <= new_x;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		new_y <=0;
	else if(in_valid)
		new_y <= in_y;
	else
		new_y <= new_y;
end

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
reg [1:0] c_dealstate , n_dealstate;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) c_dealstate <= IDLE ; 
	else if (current_state == CROSS_PRODUCT) c_dealstate <= n_dealstate;
	else c_dealstate<=c_dealstate;
end

always @(*) begin
	case (c_dealstate)
		IDLE: n_dealstate = (cross_cnt > Hull_num) ? UPDATE : IDLE ;
		UPDATE: n_dealstate = OUTPUT;
		OUTPUT: n_dealstate = (continuous_cnt==0) ? IDLE : OUTPUT;
		default: n_dealstate = c_dealstate;
	endcase
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state <= WAIT_FIRST ; 
	else current_state <= next_state;
end

always @(*) begin
	case (point_count)
		point_most: next_state = WAIT_FIRST;
		0: next_state = WAIT_FIRST;
		1: next_state = WAIT_SECOND;
		2: next_state = WAIT_THIRD;
		3: next_state = DEAL_TRIANGLE;
		default: next_state = CROSS_PRODUCT;
	endcase
end
//---------------------------------------------------------------------
//   counter 
//---------------------------------------------------------------------
// reg [7:0] cross_cnt ;//max :128
// reg [7:0] Hull_num; //max :128
// reg [7:0] cross_negetive; //max maybe 126
// reg [6:0] continuous_cnt
reg [6:0] out_cnt;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_cnt <=0;
	else if (cross_cnt>Hull_num || continuous_cnt>1) out_cnt <=out_cnt +1;
	else if (out_cnt < needdrop_cnt) out_cnt <= 0 ;
	else out_cnt <= 0 ;

end
reg [6:0] drop_num_reg;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		drop_num_reg <=0;
	else if(n_dealstate == UPDATE)
		drop_num_reg <= drop_num_comb;
	else if (in_valid_comb) drop_num_reg <=0;
	else
		drop_num_reg <=drop_num_reg;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		continuous_cnt <=0;
	else if (cross_cnt  > Hull_num)
		continuous_cnt <= (drop_num_comb==0) ? 1 : drop_num_comb;
	else if (continuous_cnt!=0)
		continuous_cnt <=  continuous_cnt -1;
	else 
		continuous_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		point_count <=0;
	else if (in_valid)
		point_count <= point_count+1;
	else if (point_count == point_most) //maybe
		point_count <=0;
	else 
		point_count <= point_count;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_cnt <=0;
	else if(in_valid || out_valid)
		cross_cnt <=0;
	else if(cross_cnt<=Hull_num)
		cross_cnt <=cross_cnt +1 ;
	else
		cross_cnt <=0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		Hull_num <=0;
	else if (current_state !=CROSS_PRODUCT)
		Hull_num <=3;
	else if(current_state == CROSS_PRODUCT && cross_cnt>Hull_num)
		case (cross_zeronum)
			0 : begin
			  case (cross_negetive)
				0 : Hull_num <=Hull_num;
				1 : Hull_num <=Hull_num+1;
				2 : Hull_num <=Hull_num;
				default: Hull_num <=Hull_num-cross_negetive+2;
			  endcase
			end
			1 : begin
				if(cross_negetive>1) Hull_num <= Hull_num - (cross_negetive-1) ;
				else	Hull_num <=Hull_num;
			end
			2 :  Hull_num <=Hull_num;
			default: Hull_num <=Hull_num;
		endcase
	else
		Hull_num <=Hull_num;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_negetive <=0;
	else if(in_valid)
		cross_negetive <=0;
	else if(cross_[23] ==1 && cross_cnt<Hull_num && out_valid_comb==0)
		cross_negetive <=cross_negetive+1;
	else if(current_state == WAIT_FIRST)
		cross_negetive <=0;
	else
		cross_negetive <=cross_negetive;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_zeronum <=0;
	else if(in_valid)
		cross_zeronum <=0;
	else if(cross_ ==0 && cross_cnt<Hull_num && out_valid_comb==0)
		cross_zeronum <=cross_zeronum+1;
	else if(current_state == WAIT_FIRST)
		cross_zeronum <=0;
	else
		cross_zeronum <=cross_zeronum;
end
//---------------------------------------------------------------------
//   reset  Hull
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i<129 ; i = i+1)
			Hull_x[i] <=0;
	end
	else if(current_state == WAIT_FIRST)
		for(i = 0 ; i<129 ; i = i+1)
			Hull_x[i] <=0;
	else if (current_state == DEAL_TRIANGLE && cross_[21]==1 ) begin
		Hull_x[1] <= Hull_new_x[2];
		Hull_x[2] <= Hull_new_x[1];
	end	
	else if(next_state==WAIT_SECOND || next_state==WAIT_THIRD )begin
		Hull_x[point_count-1] <=new_x;
	end
	else if(next_state ==DEAL_TRIANGLE) begin
		if(cross_[23]==1 && cross_cnt==1) begin
			Hull_x[2] <= Hull_x[1];
			Hull_x[1] <= new_x;
		end
		else Hull_x[2] <=new_x;
	end
	else if(next_state == CROSS_PRODUCT && cross_cnt > Hull_num) begin
	  	for(i = 0 ; i<129 ; i = i+1)
			Hull_x[i] <=Hull_new_x[i] ;
	end
	else 
		for(i = 0 ; i<129 ; i = i+1)
			Hull_x[i] <=Hull_x[i] ;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i<129 ; i = i+1)
			Hull_y[i] <=0;
	end
	else if(current_state == WAIT_FIRST)
		for(i = 0 ; i<129 ; i = i+1)
			Hull_y[i] <=0;
	else if (current_state == DEAL_TRIANGLE && cross_[21]==1 ) begin
		Hull_y[1] <= Hull_new_y[2];
		Hull_y[2] <= Hull_new_y[1];
	end	
	else if(next_state==WAIT_SECOND || next_state==WAIT_THIRD )begin
		Hull_y[point_count-1] <=new_y;
	end
	else if(next_state ==DEAL_TRIANGLE) begin
		if(cross_[23]==1 && cross_cnt==1) begin
			Hull_y[2] <= Hull_y[1];
			Hull_y[1] <= new_y;
		end
		else Hull_y[2] <=new_y;
	end
	else if(next_state == CROSS_PRODUCT && cross_cnt > Hull_num) begin
		//here update
	  	for(i = 0 ; i<129 ; i = i+1)
			Hull_y[i] <=Hull_new_y[i] ;
	end
	else 
		for(i = 0 ; i<129 ; i = i+1)
			Hull_y[i] <=Hull_y[i] ;
end
//---------------------------------------------------------------------
//   update  Hull
//---------------------------------------------------------------------
// reg [9:0] Hull_new_x [0:128];
// reg [9:0] Hull_new_y [0:128];
// reg [6:0] negetive_index
integer k;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) negetive_index <=0;
	else if(current_state==CROSS_PRODUCT && cross_<0)negetive_index <=cross_cnt;
	else if (current_state==RESET) negetive_index <= 0;
	else  negetive_index <=negetive_index;
end

always @(*) begin
	for(i=0 ; i<=128 ; i=i+1)
		Hull_new_x[i] = Hull_x[i];
	case (cross_negetive)
		0 : begin
			for(i=0 ; i<=128 ; i=i+1)
				Hull_new_x[i] = Hull_x[i];
		end
		1 : begin
				case (cross_zeronum) //maybe
					0 : begin
						for (k = 0; k < 127; k = k + 1) begin
							if (k < negetive_index) begin
								Hull_new_x[k] = Hull_x[k];
							end
							else if (k == negetive_index) begin
								Hull_new_x[k+1] = new_x;
							end
							else if (k <= Hull_num) begin
								Hull_new_x[k+1] = Hull_x[k];
							end
							else begin
								Hull_new_x[k] = Hull_x[k];
							end
						end
					end
					1 : begin
						for (k = 0; k < 127; k = k + 1) begin
							if(k ==negetive_index)
								Hull_new_x[k] = new_x;
							else
								Hull_new_x[k] = Hull_x[k];
						end
					end
					// default: 
				endcase
			end
		default : begin
			case (cross_zeronum) //maybe
					0 : begin
						if(index[0]==2) begin
							for (k = 0; k < 127; k = k + 1) begin
								if (k==Hull_num-drop_num_comb) begin
									Hull_new_x[k] = new_x;
								end
								else if (k < Hull_num-drop_num_comb) begin
									Hull_new_x[k] = Hull_x[k+drop_num_comb-1];
								end
								else if( k > Hull_num-drop_num_comb)
									Hull_new_x[k] = 0 ;
								else begin
									Hull_new_x[k] = Hull_x[k];
								end
							end
						end 

						else begin
							for (k = 0; k < 127; k = k + 1) begin
								if (k < negetive_index-cross_negetive+2) begin
										Hull_new_x[k] = Hull_x[k];
								end
								else if (k == negetive_index-cross_negetive+2) begin
										Hull_new_x[k] = new_x;
								end
								else if (k < Hull_num-cross_negetive+2) begin
										Hull_new_x[k] = Hull_x[k+(cross_negetive-2)];
								end
								else if( k >= Hull_num-cross_negetive+2)
										Hull_new_x[k] = 0 ;
								else begin
										Hull_new_x[k] = Hull_x[k];
								end
							end
						end
					end
					1 : begin
						for (k = 0; k < 127; k = k + 1) begin
							if(k ==negetive_index)
								Hull_new_x[k] = new_x;
							else if (k >negetive_index)
								Hull_new_x[k] = Hull_new_x[k+1] ;
							else
								Hull_new_x[k] = Hull_x[k];
						end
					end
					// default: 
				endcase
		end

	endcase
end

always @(*) begin
	for(i=0 ; i<=128 ; i=i+1)
		Hull_new_y[i] = Hull_y[i];

	case (cross_negetive)
		0 : begin
			for(i=0 ; i<=128 ; i=i+1)
				Hull_new_y[i] = Hull_y[i];
		end
		1 : begin
				case (cross_zeronum) //maybe
					0 : begin
						for (k = 0; k < 127; k = k + 1) begin
							if (k < negetive_index) begin
								Hull_new_y[k] = Hull_y[k];
							end
							else if (k == negetive_index) begin
								Hull_new_y[k+1] = new_y;
							end
							else if (k <= Hull_num) begin
								Hull_new_y[k+1] = Hull_y[k];
							end
							else begin
								Hull_new_y[k] = Hull_y[k];
							end
						end
						// Hull_new_x[negetive_index+cross_cnt] = Hull_x[negetive_index+cross_cnt-(negetive_index+cross_cnt >= Hull_num)];
				
						// else
						// 	Hull_new_x
						// Hull_new_x[(negetive_index+2)%(Hull_num+1)] = Hull_x[(negetive_index+2)%Hull_num] ;
					end
					// default: 
				endcase
			end
		// 2: begin
		// 	case (cross_zeronum)
		// 		0 : begin
		// 			Hull_new_y[needdrop_index] = new_y;
		// 		end
		// 		// default: 
		// 	endcase
		// end
		default : begin
			if(index[0]==2) begin
				for (k = 0; k < 127; k = k + 1) begin
					if (k==Hull_num-drop_num_comb) begin
						Hull_new_y[k] = new_y;
					end
					else if (k < Hull_num-drop_num_comb) begin
						Hull_new_y[k] = Hull_y[k+drop_num_comb-1];
					end
					else if( k > Hull_num-drop_num_comb)
						Hull_new_y[k] = 0 ;
					else begin
						Hull_new_y[k] = Hull_y[k];
					end
				end
			end 
			else begin
				for (k = 0; k < 127; k = k + 1) begin
					if (k < negetive_index-cross_negetive+2) begin
						Hull_new_y[k] = Hull_y[k];
					end
					else if (k == negetive_index-cross_negetive+2) begin
						Hull_new_y[k] = new_y;
					end
					else if (k < Hull_num-cross_negetive+2) begin
						Hull_new_y[k] = Hull_y[k+(cross_negetive-2)];
					end
					else if( k >= Hull_num-cross_negetive+2)
						Hull_new_y[k] = 0 ;
					else begin
						Hull_new_y[k] = Hull_y[k];
					end
				end
			end
		end
		// default: 
		// 	for(i=0 ; i<=128 ; i=i+1)
		// 		Hull_new_y[i] = Hull_y[i];
	endcase
end

//---------------------------------------------------------------------
//   drop hull or input 
//---------------------------------------------------------------------
// reg [6:0] needdrop_index
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i=i+1) index[i] <=0;
	else if(next_state==CROSS_PRODUCT && (cross_[23] ==1) && out_valid_comb==0 && cross_cnt<Hull_num) begin
		index[cross_cnt] <= index[cross_cnt]+1;
		index[(cross_cnt+1)%Hull_num] <= index[(cross_cnt+1)%Hull_num]+1;
	end
	else if (cross_cnt == 0) for(i=0 ; i<=128 ; i=i+1) index[i] <=0;
	else for(i=0 ; i<=128 ; i=i+1) index[i] <=index[i];
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) needdrop_index<=0;
	else if(cross_cnt>0 && (index[cross_cnt-1]==2) ) needdrop_index <=cross_cnt-1;
	else if(cross_cnt == 0) needdrop_index<=0;
	else needdrop_index <= needdrop_index;
end
// reg [9:0] drop_x_reg[0:128];
// reg [9:0] drop_y_reg[0:128];
// reg [6:0] needdrop_cnt;
reg hasrotation;
always @(*) begin
	hasrotation =  (index[0]==2);
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) needdrop_cnt<=0;
	else if (index[0]==2) needdrop_cnt <=needdrop_cnt +1;
	else if (cross_zeronum >0) needdrop_cnt<=needdrop_cnt +1;
	else if(index[cross_cnt-1]==2)  needdrop_cnt <=needdrop_cnt +1+(index[0]==2);
	// else if (cross_cnt==0 && (index[11]==2) ) needdrop_cnt <=needdrop_cnt +1 ;
	else if(cross_cnt == 0) needdrop_cnt<=0;
	else needdrop_cnt<=needdrop_cnt;
end
reg [6:0] zero_index;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) zero_index <=0;
	else zero_index <= (cross_==0) ? cross_cnt :zero_index;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=0;
	else if (in_valid)  for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=0;
	else if (out_valid_comb)  for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=drop_x_reg[i];
	else if (cross_zeronum >0 )
		drop_x_reg[1] <= Hull_x[zero_index];
	else if (needdrop_index == 0 && hasrotation)
		drop_x_reg[0] <=Hull_x[0];
	else if(cross_cnt>0 && (index[cross_cnt-1]==2) ) begin
		drop_x_reg[needdrop_cnt] <=Hull_x[cross_cnt-1];
		if(index[0]==2)
			drop_x_reg[needdrop_cnt+1] <=Hull_x[0];
		else
			drop_x_reg[needdrop_cnt+1] <= 0 ;
		// drop_x_reg[needdrop_cnt-1] <=Hull_x[cross_cnt-1];
	end
	// else if(cross_cnt == 0) for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=0;
	else for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=drop_x_reg[i];
end  

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=0;
	else if (in_valid)  for(i=0 ; i<=128 ; i = i+1 )  drop_y_reg[i]<=0;
	else if (out_valid_comb)  for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=drop_y_reg[i];
	else if (cross_zeronum >0 )
		drop_y_reg[1] <=Hull_y[zero_index];
	else if (needdrop_index == 0 && hasrotation)
		drop_y_reg[0] <=Hull_y[0];
	else if(cross_cnt>0 && (index[cross_cnt-1]==2) ) begin
		drop_y_reg[needdrop_cnt] <=Hull_y[cross_cnt-1];
		if(index[0]==2)
			drop_y_reg[needdrop_cnt+1] <=Hull_y[0];
		else
			drop_y_reg[needdrop_cnt+1] <= 0 ;
		// drop_x_reg[needdrop_cnt-1] <=Hull_x[cross_cnt-1];
	end
	// else if(cross_cnt == 0) for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=0;
	else for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=drop_y_reg[i];
end

//---------------------------------------------------------------------
//   output
//---------------------------------------------------------------------
always @(*) begin
	case (current_state)
		WAIT_FIRST : drop_num_comb = 0 ; //maybe
		WAIT_SECOND : drop_num_comb = 0 ;
		WAIT_THIRD  : drop_num_comb = 0 ;
		DEAL_TRIANGLE: drop_num_comb = 0 ;
		CROSS_PRODUCT : begin
			if(out_valid_comb)
				case (cross_zeronum)
					0 : begin
						if(cross_negetive<2) drop_num_comb = !cross_negetive;
						else drop_num_comb=cross_negetive-1;
					end
					1 : begin
						if(cross_negetive>0) drop_num_comb = cross_negetive;
						else	drop_num_comb =1;
					end
					2 :  drop_num_comb = 1;
					default: drop_num_comb =drop_num;
				endcase
			else
				drop_num_comb =0; //drop_num_comb =0;
		end	
		default: drop_num_comb =drop_num;
	endcase
end

always @(*) begin
	case (current_state)
		WAIT_FIRST : out_x_comb = 0 ;
		WAIT_SECOND : out_x_comb = 0 ;
		WAIT_THIRD  : out_x_comb = 0 ;
		DEAL_TRIANGLE: out_x_comb = 0 ;
		CROSS_PRODUCT : begin
			if(out_valid_comb)
				if(cross_negetive==0)  out_x_comb = new_x;
				// else if (hasrotation) out_x_comb = Hull_x[0];
				else begin
					case (cross_zeronum)
						0 : begin
							if(cross_negetive==1) out_x_comb =0;
							else out_x_comb = drop_x_reg[out_cnt];
						end
						1 : begin
							if(cross_negetive==1) out_x_comb = Hull_x[negetive_index];
							else out_x_comb = drop_x_reg[out_cnt];
						end
						// 2 : 
						default: out_x_comb =0;
					endcase
				end
			else
				out_x_comb =0; //drop_num_comb =0;
		end	

		default: out_x_comb = out_x ;
	endcase
end

always @(*) begin
	case (current_state)
		WAIT_FIRST : out_y_comb = 0 ;
		WAIT_SECOND : out_y_comb = 0 ;
		WAIT_THIRD  : out_y_comb = 0 ;
		DEAL_TRIANGLE: out_y_comb = 0 ;
		CROSS_PRODUCT : begin
			if(out_valid_comb)
				if(cross_negetive==0)  out_y_comb = new_y;
				else begin
					case (cross_zeronum)
						0 : begin
							if(cross_negetive==1) out_y_comb =0;
							else out_y_comb = drop_y_reg[out_cnt];
						end
						1 : begin
							if(cross_negetive==1) out_y_comb = Hull_y[negetive_index];
							else out_y_comb = drop_y_reg[out_cnt];
						end
						// 2 : 
						default: out_y_comb =0;
					endcase
				end
			else
				out_y_comb =0; //drop_num_comb =0;
		end	
		default: out_y_comb = out_y ;
	endcase
end

always @(*) begin
	case (next_state)
		WAIT_FIRST : out_valid_comb = (in_valid_comb)? 1:0 ;
		WAIT_SECOND : out_valid_comb = (in_valid_comb)? 1:0 ;
		WAIT_THIRD  : out_valid_comb = (in_valid_comb)? 1:0 ;
		DEAL_TRIANGLE: out_valid_comb = (in_valid_comb)? 1:0 ;
		CROSS_PRODUCT : out_valid_comb = (cross_cnt>Hull_num || continuous_cnt>1) ; 
		default: out_valid_comb = out_valid;
	endcase
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