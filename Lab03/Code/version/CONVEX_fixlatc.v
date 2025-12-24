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
parameter WAIT_FIRST = 4'd0;
parameter WAIT_SECOND = 4'd1;
parameter WAIT_THIRD = 4'd2;
parameter DEAL_TRIANGLE = 4'd3;
parameter CROSS = 4'd4;
parameter UPDATE = 4'd5; //update and add drop 
parameter OUTPUT = 4'd6;
parameter RESET= 4'd7;
parameter WAITCYCLE = 4'd8;
integer i;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [7:0] update_cnt,output_cnt;
reg [9:0] drop_x_reg[0:128];
reg [9:0] drop_y_reg[0:128];
reg [3:0] current_state,next_state;
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
reg [7:0] drop_cnt; 
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
//   done
//---------------------------------------------------------------------
wire cross_done,update_done,output_done,pattern_done;
assign cross_done =  ( Hull_num -1<= cross_cnt );
assign update_done = ( Hull_num < update_cnt);
assign output_done = (drop_num_comb == 0) ? (output_cnt >= 1) : (output_cnt >= drop_num_comb);
assign pattern_done =(point_count == point_most && current_state==RESET);
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
	if(current_state==CROSS||current_state == DEAL_TRIANGLE)
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
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) current_state <= WAIT_FIRST ; 
	else current_state <= next_state;
end

always @(*) begin
	case (current_state) 
		WAIT_FIRST    : next_state = point_count==1 ? WAIT_SECOND   : current_state; 
		WAIT_SECOND	  : next_state = point_count==2 ? WAIT_THIRD	: current_state; 
		WAIT_THIRD	  : next_state = point_count==3 ? DEAL_TRIANGLE	: current_state; 
		DEAL_TRIANGLE : next_state = in_valid		? CROSS 		: current_state; 
		CROSS         : next_state = cross_done  	? WAITCYCLE		: current_state;
		WAITCYCLE	  : next_state = UPDATE ;
		UPDATE        : next_state = update_done    ? OUTPUT		: current_state;
		OUTPUT        : next_state = output_done    ? RESET      	: current_state;
		RESET 		  : next_state = pattern_done   ? WAIT_FIRST    : in_valid ? CROSS : RESET ; 
		default 	  : next_state = current_state;
	endcase 
end
//---------------------------------------------------------------------
//   counter 
//---------------------------------------------------------------------
// reg [7:0] cross_cnt ;//max :128
// reg [7:0] Hull_num; //max :128
// reg [7:0] cross_negetive; //max maybe 126
// reg [6:0] continuous_cnt
// reg [7:0] drop_cnt; 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        drop_cnt <= 0;
    else if (current_state == UPDATE)
		if (cross_negetive == 0 )
			drop_cnt <=0;
        else if(index[update_cnt] == 2)
            drop_cnt <= drop_cnt + 1;
		else  drop_cnt <= drop_cnt;
    else if(current_state == RESET) begin
        drop_cnt <= 0;
	end
	else
		drop_cnt<=drop_cnt;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		update_cnt <= 0;
	else if (current_state == UPDATE &&!update_done)
		update_cnt <= update_cnt + 1;
	else 
		update_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		output_cnt <=0;
	else if (current_state == OUTPUT)
		output_cnt <= output_cnt + 1;
	else if (current_state == RESET)
		output_cnt <=0;
	else
		output_cnt <=output_cnt;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		point_count <=0;
	else if (in_valid)
		point_count <= point_count+1;
	else if (point_count == point_most && current_state==RESET) //maybe
		point_count <=0;
	else 
		point_count <= point_count;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_cnt <=0;
	else if(current_state == CROSS && !cross_done)
		cross_cnt <=cross_cnt +1 ;
	else
		cross_cnt <=0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		Hull_num <=0;
	else if (current_state ==WAIT_FIRST ||current_state ==WAIT_SECOND || current_state ==WAIT_THIRD)
		Hull_num <=3;
	else if(current_state == UPDATE && update_done)
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
			2 :  Hull_num <=Hull_num-cross_negetive;
			default: Hull_num <=Hull_num;
		endcase
	else
		Hull_num <=Hull_num;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_negetive <=0;
	else if(current_state ==RESET)
		cross_negetive <=0;
	else if(current_state ==CROSS && cross_[23] ==1)
		cross_negetive <=cross_negetive+1;
	else
		cross_negetive <=cross_negetive;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cross_zeronum <=0;
	else if(current_state ==RESET)
		cross_zeronum <=0;
	else if(current_state ==CROSS && cross_ ==0)
		cross_zeronum <=cross_zeronum+1;
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
		Hull_x[1] <= Hull_x[2];
		Hull_x[2] <= Hull_x[1];
	end	
	else if(current_state==WAIT_SECOND || current_state==WAIT_THIRD )begin
		Hull_x[point_count-1] <=new_x;
	end
	else if (current_state == UPDATE ) begin
		for(i = 0 ; i<129 ; i = i+1)
			Hull_x[i] <=Hull_new_x[i];
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
		Hull_y[1] <= Hull_y[2];
		Hull_y[2] <= Hull_y[1];
	end	
	else if(current_state==WAIT_SECOND || current_state==WAIT_THIRD )begin
		Hull_y[point_count-1] <=new_y;
	end
	else if (current_state == UPDATE && update_done) begin
		for(i = 0 ; i<129 ; i = i+1)
			Hull_y[i] <=Hull_new_y[i];
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
	else if(current_state==CROSS && cross_<0)negetive_index <=cross_cnt;
	else if (current_state==RESET) negetive_index <= 0;
	else  negetive_index <=negetive_index;
end

reg find12;
always @(posedge clk or negedge rst_n)  begin
	if(!rst_n) find12<=0;
	else if (current_state== UPDATE && index[update_cnt%Hull_num]==1 &&index[(update_cnt+1)%Hull_num]==2)
		find12 <= 1;
	else if(current_state ==RESET)	 find12<=0;
	else find12<=find12;
end

reg [6:0]update_new_cnt;

wire [6:0] drop_temp;
assign drop_temp = ((next_state ==UPDATE||next_state==RESET || next_state==OUTPUT) && cross_negetive>0) ? cross_negetive+cross_zeronum-1 :0;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		update_new_cnt <= 0;
	else if (current_state ==RESET) 
		update_new_cnt <= 0;
	else if (current_state==UPDATE && index[update_cnt]!=2 &&!update_done)
		update_new_cnt <= update_new_cnt + 1;
	else 
		update_new_cnt <= update_new_cnt;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i=i+1) Hull_new_x[i] <=0;
	else if(current_state ==UPDATE) begin
		if(cross_negetive ==1 && cross_zeronum == 0) begin //maybe	
			if (update_cnt < negetive_index) 
				Hull_new_x[update_cnt] <= Hull_x[update_cnt];
			else if (update_cnt == negetive_index)
				Hull_new_x[update_cnt+1] <= new_x;
			else if (update_cnt <= Hull_num) 
				Hull_new_x[update_cnt+1] <= Hull_x[update_cnt];
			else
				Hull_new_x[update_cnt] <= Hull_x[update_cnt];
		end
		else begin
			if(index[0]==2 && cross_negetive>0) begin
				if(update_new_cnt < Hull_num-drop_temp)
					Hull_new_x [update_new_cnt] <= Hull_x[update_cnt];
				else if(update_new_cnt == Hull_num-drop_temp)
					Hull_new_x [update_new_cnt] <= new_x;
				else
					Hull_new_x [update_new_cnt] <= 0 ;
			end
			else begin
				if(index[update_cnt]==1 &&index[update_cnt+1]==2)
					Hull_new_x [update_cnt+1] <= new_x;
				else if (find12)
					Hull_new_x [update_cnt+1] <= Hull_x[update_cnt+drop_num_comb];
				else
					Hull_new_x[update_cnt] <= Hull_x[update_cnt];
			end
		end			
	end else begin
		for(i=0 ; i<=128 ; i=i+1)
			Hull_new_x[i] <= Hull_x[i];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i=i+1) Hull_new_y[i] <=0;
	else if(current_state ==UPDATE) begin
		if(cross_negetive ==1 && cross_zeronum == 0) begin //maybe	
			if (update_cnt < negetive_index) 
				Hull_new_y[update_cnt] <= Hull_y[update_cnt];
			else if (update_cnt == negetive_index)
				Hull_new_y[update_cnt+1] <= new_y;
			else if (update_cnt <= Hull_num) 
				Hull_new_y[update_cnt+1] <= Hull_y[update_cnt];
			else
				Hull_new_y[update_cnt] <= Hull_y[update_cnt];	
		end
		else 
			if(index[0]==2 && cross_negetive>0) begin
				if(update_new_cnt < Hull_num-drop_temp)
					Hull_new_y [update_new_cnt] <= Hull_y[update_cnt];
				else if(update_new_cnt == Hull_num-drop_temp)
					Hull_new_y [update_new_cnt] <=new_y;
				else
					Hull_new_y [update_new_cnt] <= 0 ;
			end
			else begin
				if(index[update_cnt]==1 &&index[update_cnt+1]==2)
					Hull_new_y [update_cnt+1] <=new_y;
				else if (find12)
					Hull_new_y [update_cnt+1] <= Hull_y[update_cnt+drop_num_comb];
				else
					Hull_new_y[update_cnt] <= Hull_y[update_cnt];
			end

	end else begin
		for(i=0 ; i<=128 ; i=i+1)
			Hull_new_y[i] <= Hull_y[i];
	end
end

//---------------------------------------------------------------------
//   drop hull or input 
//---------------------------------------------------------------------
// reg [6:0] needdrop_index
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i=i+1) index[i] <=0;
	else if(current_state == CROSS && cross_ <=0) begin
		index[cross_cnt] <= index[cross_cnt]+1;
		index[(cross_cnt+1)%Hull_num] <= index[(cross_cnt+1)%Hull_num]+1;
	end
	else if (current_state == RESET) for(i=0 ; i<=128 ; i=i+1) index[i] <=0;
	else for(i=0 ; i<=128 ; i=i+1) index[i] <=index[i];
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) needdrop_index<=0;
	else if(cross_cnt>0 && (index[cross_cnt-1]==2) ) needdrop_index <=cross_cnt-1;
	else if(cross_cnt == 0) needdrop_index<=0;
	else needdrop_index <= needdrop_index;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=0;
	else if (current_state == UPDATE ) begin
		if(index[update_cnt] == 2)	drop_x_reg[drop_cnt] <= Hull_x[update_cnt];
		else if (cross_negetive == 0 ) drop_x_reg[drop_cnt] <=new_x;
	end
	else if(current_state == RESET) for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=0;
	else for(i=0 ; i<=128 ; i = i+1 ) drop_x_reg[i]<=drop_x_reg[i];
end  

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=0;
	else if (current_state == UPDATE ) begin
		if(index[update_cnt] == 2)	drop_y_reg[drop_cnt] <= Hull_y[update_cnt];
		else if (cross_negetive == 0) drop_y_reg[drop_cnt] <=new_y;
	end
	else if(current_state == RESET) for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=0;
	else for(i=0 ; i<=128 ; i = i+1 ) drop_y_reg[i]<=drop_y_reg[i];
end  

//---------------------------------------------------------------------
//   output
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) drop_num_comb<=0;
	else 
		case (current_state)
			WAIT_FIRST : drop_num_comb <= 0 ; //maybe
			WAIT_SECOND : drop_num_comb <= 0 ;
			WAIT_THIRD  : drop_num_comb <= 0 ;
			DEAL_TRIANGLE: drop_num_comb <= 0 ;
			UPDATE : begin
					case (cross_zeronum)
						0 : if(cross_negetive<2) drop_num_comb <= !cross_negetive;
							else drop_num_comb<=cross_negetive-1;
						1 : if(cross_negetive>0) drop_num_comb <= cross_negetive;
							else	drop_num_comb <=1;
						2 : drop_num_comb <= cross_negetive+1;
						default: drop_num_comb <=drop_num;
					endcase
			end	
			RESET : drop_num_comb <=0;
			default: drop_num_comb <=drop_num_comb;
		endcase
end

always @(*) begin
	case (current_state)
		WAIT_FIRST : out_x_comb = 0 ;
		WAIT_SECOND : out_x_comb = 0 ;
		WAIT_THIRD  : out_x_comb = 0 ;
		DEAL_TRIANGLE: out_x_comb = 0 ;
		OUTPUT : begin
			out_x_comb = (output_cnt >0) ?drop_x_reg[output_cnt-1] : 0;
		end	
		default: out_x_comb = 0 ;
	endcase
end

always @(*) begin
	case (current_state)
		WAIT_FIRST : out_y_comb = 0 ;
		WAIT_SECOND : out_y_comb = 0 ;
		WAIT_THIRD  : out_y_comb = 0 ;
		DEAL_TRIANGLE: out_y_comb = 0 ;
		OUTPUT : begin
			out_y_comb = (output_cnt >0) ? drop_y_reg [output_cnt-1] : 0;
		end	
		default: out_y_comb = 0 ;
	endcase
end

always @(*) begin
	case (current_state)
		WAIT_FIRST : out_valid_comb = (in_valid_comb)? 1:0 ;
		WAIT_SECOND : out_valid_comb = (in_valid_comb)? 1:0 ;
		WAIT_THIRD  : out_valid_comb = (in_valid_comb)? 1:0 ;
		DEAL_TRIANGLE: out_valid_comb = (in_valid_comb)? 1:0 ;
		OUTPUT : out_valid_comb = output_cnt>0; 
		default: out_valid_comb = 0;
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
	else if (current_state == OUTPUT && out_valid_comb) begin
		drop_num <=drop_num_comb ; 
	end
	else drop_num<=0;
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