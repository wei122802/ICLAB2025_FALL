module SUDOKU(
    //Input Port
    clk,
    rst_n,
	in_valid,
	in,

    //Output Port
    out_valid,
    out
    );

//==============================
//   INPUT/OUTPUT DECLARATION
//==============================
input clk;
input rst_n;
input in_valid;
input [3:0] in;

output reg out_valid;
output reg [3:0] out;
    
//==============================
//   PARAMETER DECLARATION
//==============================
integer i, j;
genvar idx, jdx, ndx;
// FSM
parameter INPUT        = 2'd0 ;
parameter SCAN 		   = 2'd1 ;
parameter SOLVE_UPDATE = 2'd2 ;
parameter OUTPUT       = 2'd3 ;

//==============================
//   LOGIC DECLARATION                                                 
//==============================
reg [6:0] count_in;
reg [3:0] board[0:8][0:8];
reg [3:0] blanks_row[63:0], blanks_col[63:0]; //most empty only 64
// FSM
reg [1:0] current_state;
reg [1:0] next_state;
// 	EXIST
wire rowhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
wire colhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
wire boxhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
// emptynum
reg [6:0] emptynum; 
// reg [6:0] blank_index;  
// 	FORWARD & BACKWARD
reg [6:0] remain_emptynum;  
reg [3:0] current_col, current_row;
// 	FORWARD
reg [3:0] next_value;
reg [9:1] possible_value ;
//  PRE_OUTPUT
reg [6:0] count_out;  
reg [5:0] scan_cnt ; 
// wire done = (current_state == FORWARD && remain_emptynum==0);
wire done =(remain_emptynum==0 );
//==============================
//   Design                                                            
//==============================
// reg  row_used [0:8][9:1];
// reg  col_used [0:8][9:1];
// reg  box_used [0:8][9:1];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) scan_cnt = 6'd0;
	if(current_state == SOLVE_UPDATE || scan_cnt>=emptynum) scan_cnt = 6'd0;
	else if(current_state == SCAN ) scan_cnt = scan_cnt + 1;
	else scan_cnt = 6'd0;
end

reg [2:0] possible_num  ;

always @(*) begin
	possible_num = possible_value[1] + possible_value[2] + possible_value[3] + possible_value[4] + possible_value[5] + possible_value[6] + possible_value[7] + possible_value[8] + possible_value[9];
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) current_state <= INPUT ;
	else 		current_state <= next_state ;
end
// reg [1:0] next_state;
always @(*) begin
	case(current_state)
		INPUT: begin
			if (count_in==7'd81)	next_state = SCAN ;
			else 				    next_state = INPUT ;
		end
		SCAN : begin
		  if (possible_num == 1) next_state = SOLVE_UPDATE;
		  else next_state = current_state;
		end
		SOLVE_UPDATE: begin
			if (done)	next_state = OUTPUT ; 
			else 		next_state = SCAN ;
		end

		OUTPUT: begin
			if (count_out> 7'd80)	next_state = INPUT ;
			else 					next_state = OUTPUT ;
		end
	endcase
end
//================================================================
//  OUTPUT : out_valid & out
//================================================================
// output reg out_valid;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out_valid <= 1'b0 ;
	else begin
		if (next_state==OUTPUT)	out_valid <= 1'b1 ; 
		else 		out_valid <= 1'b0 ;
	end
end
// output reg [3:0] out;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out <= 4'd0 ;
	else begin
		if (next_state==OUTPUT) 
			out <= board[ count_out/9 ][ count_out %9] ;
		else
            out <= 4'd0 ;
	end
end
//================================================================
//  PRE_OUTPUT
//================================================================
// reg [6:0] count_out; 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	count_out <= 7'd0 ; 
	else begin
		if (next_state==OUTPUT)  count_out <= count_out + 1 ; 
        else count_out <= 0;
	end
end
//================================================================
// 	FORWARD
//================================================================
// reg [3:0] next_value;
reg [3:0] possible_col , possible_row ;

always @(*) begin
	if(current_state == SCAN && possible_num==1) begin
		possible_col = current_col;
		possible_row = current_row;
	end
	else begin
		possible_col = 4'd0;
		possible_row = 4'd0;
	end
end

always @(*) begin
	case (possible_value)
		9'b0_0000_0001:	next_value = 4'd1 ;
		9'b0_0000_0010:	next_value = 4'd2 ;
		9'b0_0000_0100:	next_value = 4'd3 ;
		9'b0_0000_1000:	next_value = 4'd4 ;
		9'b0_0001_0000:	next_value = 4'd5 ;
		9'b0_0010_0000:	next_value = 4'd6 ;
		9'b0_0100_0000:	next_value = 4'd7 ;
		9'b0_1000_0000:	next_value = 4'd8 ;
		9'b1_0000_0000:	next_value = 4'd9 ;
		default: next_value = 4'd0;
	endcase
end

generate
for( ndx=1 ; ndx<10 ; ndx=ndx+1 ) begin
	always @(*) begin
		possible_value[ndx] = (board[current_row][current_col] == 0) && (rowhas[ndx][current_row]==1'b0) && (colhas[ndx][current_col]==1'b0) && (boxhas[ndx][ 3*(current_row/3) + current_col/3 ]==1'b0) ;
	end
end
endgenerate
//================================================================
// 	FORWARD & BACKWARD
//================================================================
// reg [6:0] remain_emptynum; 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	remain_emptynum <= 7'd0 ; 
	else begin
		if (current_state==INPUT)			remain_emptynum <= emptynum ;
		else if (next_state==SOLVE_UPDATE)  remain_emptynum <= remain_emptynum - 1 ;
		else if (next_state==SCAN)		    remain_emptynum <= remain_emptynum ;
		else                           		remain_emptynum <= 7'd0;
	end
end
// reg [3:0] current_col, current_row;
always @(*) begin
	if (next_state!= INPUT) begin
		current_row = blanks_row[scan_cnt] ;
		current_col = blanks_col[scan_cnt] ;
	end
	else begin
		current_row = 4'd0 ;
		current_col = 4'd0 ;
	end
end
//================================================================
//  EXIST
//================================================================
// whether a number ndx exists in a row/column/box or not
generate
for( ndx=1 ; ndx<10 ; ndx=ndx+1 ) begin
	// wire rowhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
	for( idx=0 ; idx<9 ; idx=idx+1 )
		assign rowhas[ndx][idx] = (board[idx][0]==ndx) || (board[idx][1]==ndx) || (board[idx][2]==ndx) ||
								  (board[idx][3]==ndx) || (board[idx][4]==ndx) || (board[idx][5]==ndx) ||
								  (board[idx][6]==ndx) || (board[idx][7]==ndx) || (board[idx][8]==ndx) ;
	// wire colhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
	for( jdx=0 ; jdx<9 ; jdx=jdx+1 )
		assign colhas[ndx][jdx] = (board[0][jdx]==ndx) || (board[1][jdx]==ndx) || (board[2][jdx]==ndx) ||
								  (board[3][jdx]==ndx) || (board[4][jdx]==ndx) || (board[5][jdx]==ndx) ||
								  (board[6][jdx]==ndx) || (board[7][jdx]==ndx) || (board[8][jdx]==ndx) ;
	// wire boxhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
	for( idx=1 ; idx<9 ; idx=idx+3 )
		for( jdx=1 ; jdx<9 ; jdx=jdx+3 )
			assign boxhas[ndx][ idx + (jdx-1)/3 - 1 ] = (board[idx-1][jdx-1]==ndx) || (board[idx-1][jdx]==ndx) || (board[idx-1][jdx+1]==ndx) ||
					 									(board[idx  ][jdx-1]==ndx) || (board[idx  ][jdx]==ndx) || (board[idx  ][jdx+1]==ndx) ||
					 									(board[idx+1][jdx-1]==ndx) || (board[idx+1][jdx]==ndx) || (board[idx+1][jdx+1]==ndx) ;
end
endgenerate
//================================================================
//  emptynum
//================================================================
// reg [6:0] emptynum;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	emptynum <= 7'd0 ;
	else begin
		if (current_state==INPUT) begin
			if (in_valid==1'b1 && in==4'd0)
				emptynum <= emptynum + 1 ;
		end
		else if (current_state==OUTPUT && next_state==INPUT)	emptynum <= 7'd0 ; 
	end
end

//================================================================
//  INPUT
//================================================================
// reg [6:0] count_in;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	count_in <= 7'd0 ;
	else begin
		if (in_valid==1'b1)					count_in <= count_in + 1 ;
		else if (next_state==OUTPUT)	    count_in <= 7'd0 ;
	end
end

// reg [3:0] board[0:8][0:8];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<9 ; i=i+1 )
			for( j=0 ; j<9 ; j=j+1 )
				board[i][j] <= 4'd0 ;
	end
	else begin
		if (next_state==INPUT) begin
			if (in_valid==1'b1) begin
				board[8][8] <= in ;			// neweset in
				for( i=0 ; i<9 ; i=i+1 )	// shift-register : except right-most column
					for( j=0 ; j<8 ; j=j+1 )
						board[i][j] <= board[i][j+1] ;
				for( i=0 ; i<8 ; i=i+1 )	// shift-register : right-most column
					board[i][8] <= board[i+1][0] ;
			end
		end
		else if (next_state==SOLVE_UPDATE) begin
			if (remain_emptynum <= emptynum)  
				board[possible_row][possible_col] <= next_value ;
		end
	end
end
// reg [3:0] blanks_row[80:0], blanks_col[80:0];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for( i=0 ; i<64 ; i=i+1 ) begin  
			blanks_row[i] <= 0 ;
			blanks_col[i] <= 0 ;
		end
	end
	else begin
		if (next_state==INPUT) begin
			if (in_valid==1'b1) begin
				if (in==4'd0) begin
					blanks_row[emptynum] <= count_in/9 ;  
					blanks_col[emptynum] <= count_in%9 ;
				end
			end
		end
		else if (current_state==OUTPUT && next_state==INPUT) begin
			for( i=0 ; i<64 ; i=i+1 ) begin
				blanks_row[i] <= 0 ;
				blanks_col[i] <= 0 ;
			end
		end
	end
end


endmodule