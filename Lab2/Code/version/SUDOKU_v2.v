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
integer i, j,mrv_i , k;
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
reg [3:0] next_value [0:63];
reg [9:1]possible_values[0:63] ;
//  PRE_OUTPUT
reg [6:0] count_out;  
reg [5:0] scan_cnt ; 
reg       update_valid [0:63];
// wire done = (current_state == FORWARD && remain_emptynum==0);
wire done =(remain_emptynum==0 );
//==============================
//   Design                                                            
//==============================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) scan_cnt = 6'd0;
	else if(current_state == SOLVE_UPDATE || scan_cnt>=emptynum) scan_cnt = 6'd0;
	else if(current_state == SCAN ) scan_cnt = scan_cnt + 1;
	else scan_cnt = 6'd0;
end

reg [2:0] possible_num [0:63] ;

genvar g_idx, g_val;
generate
    for (g_idx = 0; g_idx < 64; g_idx = g_idx + 1) begin : gen_possible
        wire [3:0] temp_row = blanks_row[g_idx];
        wire [3:0] temp_col = blanks_col[g_idx];
        wire is_valid_blank = (board[temp_row][temp_col] == 0);
        
        for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_val
            assign possible_values[g_idx][g_val] = is_valid_blank && 
                !rowhas[g_val][temp_row] && 
                !colhas[g_val][temp_col] && 
                !boxhas[g_val][3*(temp_row/3) + temp_col/3];
        end
        
        assign possible_num[g_idx] = possible_values[g_idx][1] + 
                                     possible_values[g_idx][2] + possible_values[g_idx][3] +
                                     possible_values[g_idx][4] + possible_values[g_idx][5] +
                                     possible_values[g_idx][6] + possible_values[g_idx][7] +
                                     possible_values[g_idx][8] + possible_values[g_idx][9] ;
    end
endgenerate

reg [8:0] best_possible [0:63];


always @(*) begin
    for (mrv_i = 0; mrv_i < 64; mrv_i = mrv_i + 1) begin
        if (board[blanks_row[mrv_i]][blanks_col[mrv_i]] == 0 && mrv_i<emptynum) begin
            if (possible_num[mrv_i] ==1) begin
				update_valid[mrv_i] = 1 ;
                // best_count = possible_num[mrv_i];
                best_possible[mrv_i] = possible_values[mrv_i];
            end
			else begin
			  update_valid[mrv_i] = 0 ;
			  best_possible[mrv_i] = 0;
			end
        end
		else begin
			update_valid[mrv_i] = 0 ;
			best_possible[mrv_i] = 0;
		end
    end
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
		  next_state = SOLVE_UPDATE;
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
reg [6:0] num_filled;

always @(*) begin
	num_filled = update_valid[0] + update_valid[1] + update_valid[2] + update_valid[3] + update_valid[4] + update_valid[5] + update_valid[6] + update_valid[7] +
				 update_valid[8] + update_valid[9] + update_valid[10] + update_valid[11] + update_valid[12] + update_valid[13] + update_valid[14] + update_valid[15] +
				 update_valid[16] + update_valid[17] + update_valid[18] + update_valid[19] + update_valid[20] + update_valid[21] + update_valid[22] + update_valid[23] +
				 update_valid[24] + update_valid[25] + update_valid[26] + update_valid[27] + update_valid[28] + update_valid[29] + update_valid[30] + update_valid[31] +
				 update_valid[32] + update_valid[33] + update_valid[34] + update_valid[35] + update_valid[36] + update_valid[37] + update_valid[38] + update_valid[39] +
				 update_valid[40] + update_valid[41] + update_valid[42] + update_valid[43] + update_valid[44] + update_valid[45] + update_valid[46] + update_valid[47] +
				 update_valid[48] + update_valid[49] + update_valid[50] + update_valid[51] + update_valid[52] + update_valid[53] + update_valid[54] + update_valid[55] +
				 update_valid[56] + update_valid[57] + update_valid[58] + update_valid[59] + update_valid[60] + update_valid[61]+ update_valid[62]+ update_valid[63];
end

genvar l;
generate
for(l=0;l<64;l=l+1) begin : assign_next_value
	always @(*) begin
		case (best_possible[l])
			9'b0_0000_0001:	next_value[l] = 4'd1 ;
			9'b0_0000_0010:	next_value[l] = 4'd2 ;
			9'b0_0000_0100:	next_value[l] = 4'd3 ;
			9'b0_0000_1000:	next_value[l] = 4'd4 ;
			9'b0_0001_0000:	next_value[l] = 4'd5 ;
			9'b0_0010_0000:	next_value[l] = 4'd6 ;
			9'b0_0100_0000:	next_value[l] = 4'd7 ;
			9'b0_1000_0000:	next_value[l] = 4'd8 ;
			9'b1_0000_0000:	next_value[l] = 4'd9 ;
			default: next_value[l] = 4'd0;
		endcase
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
		else if (next_state==SOLVE_UPDATE)  remain_emptynum <= remain_emptynum - num_filled ;
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
		else if (current_state==OUTPUT)	emptynum <= 7'd0 ; 
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
			for (i=0;i<64;i=i+1) begin
				if (update_valid[i]) begin
					board[blanks_row[i]][blanks_col[i]] <= next_value[i];
				end
        end
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


// Cycle: 10.00
// Area: 1296477.733268
