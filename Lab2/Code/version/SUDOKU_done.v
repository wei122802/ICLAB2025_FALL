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
integer i, j, k;
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
// FSM
reg [1:0] current_state;
reg [1:0] next_state;
// 	EXIST
wire rowhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
wire colhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
wire boxhas[1:9][0:8];	// [number in sudoku 1~9][position 0~8]
reg [6:0] remain_emptynum;  
wire done =(remain_emptynum==0 );
reg  [9:1] possible_values [0:8][0:8];

reg [6:0] count_out;  
reg solution_found;
// reg naked_single [0:8][0:8];
reg [3:0] naked_value [0:8][0:8];
wire row_has_unique [1:9][0:8][0:8];  
wire col_has_unique [1:9][0:8][0:8];  
wire box_has_unique [1:9][0:8][0:8]; 
//================================================================
//  emptynum
//================================================================
reg [6:0] emptynum;
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
// reg [6:0] remain_emptynum; 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	remain_emptynum <= 7'd0 ; 
	else begin
		if (current_state==INPUT)			remain_emptynum <= emptynum ;
		else if (next_state==SOLVE_UPDATE && solution_found)  remain_emptynum <= remain_emptynum - 1 ;
		else if (next_state==SCAN)		    remain_emptynum <= remain_emptynum ;
		else                           		remain_emptynum <= 0;
	end
end

//==============================
//   FSM                                                           
//==============================
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
//  Output count
//================================================================
// reg [6:0] count_out; 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	count_out <= 7'd0 ; 
	else begin
		if (next_state==OUTPUT)  count_out <= count_out + 1 ; 
        else count_out <= 0;
	end
end

//==============================
//   Possible Values                                                           
//==============================
wire [3:0] possible_count [0:8][0:8];
// wire possible_onlyonevalue[0:8][0:8];
wire naked_single [0:8][0:8];
genvar g_idx, g_val;
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_possible
		wire is_valid_blank = (board[g_idx/9][g_idx%9] == 0);
	    for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_val
            assign possible_values [g_idx/9][g_idx%9][g_val] = is_valid_blank && 
                											  !rowhas[g_val][g_idx/9] && 
                											  !colhas[g_val][g_idx%9] && 
                											  !boxhas[g_val][3*((g_idx/9)/3) + (g_idx%9)/3];
        end
        assign possible_count[g_idx/9][g_idx%9] = 
            (possible_values[g_idx/9][g_idx%9][1] ? 4'd1 : 4'd0) + 
            (possible_values[g_idx/9][g_idx%9][2] ? 4'd1 : 4'd0) +
            (possible_values[g_idx/9][g_idx%9][3] ? 4'd1 : 4'd0) + 
            (possible_values[g_idx/9][g_idx%9][4] ? 4'd1 : 4'd0) +
            (possible_values[g_idx/9][g_idx%9][5] ? 4'd1 : 4'd0) + 
            (possible_values[g_idx/9][g_idx%9][6] ? 4'd1 : 4'd0) +
            (possible_values[g_idx/9][g_idx%9][7] ? 4'd1 : 4'd0) + 
            (possible_values[g_idx/9][g_idx%9][8] ? 4'd1 : 4'd0) +
            (possible_values[g_idx/9][g_idx%9][9] ? 4'd1 : 4'd0);
    end
endgenerate
//==============================
//   Naked Single                                                           
//==============================
generate
	for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_naked_single
		assign naked_single[g_idx/9][g_idx%9] = 
            (board[g_idx/9][g_idx%9] == 0) && (possible_count[g_idx/9][g_idx%9] == 4'd1);
            
		always @(*) begin
			naked_value[g_idx/9][g_idx%9] = 
				possible_values[g_idx/9][g_idx%9][1] ? 4'd1 :
				possible_values[g_idx/9][g_idx%9][2] ? 4'd2 :
				possible_values[g_idx/9][g_idx%9][3] ? 4'd3 :
				possible_values[g_idx/9][g_idx%9][4] ? 4'd4 :
				possible_values[g_idx/9][g_idx%9][5] ? 4'd5 :
				possible_values[g_idx/9][g_idx%9][6] ? 4'd6 :
				possible_values[g_idx/9][g_idx%9][7] ? 4'd7 :
				possible_values[g_idx/9][g_idx%9][8] ? 4'd8 :
				possible_values[g_idx/9][g_idx%9][9] ? 4'd9 : 4'd0;
			// case (possible_values[g_idx/9][g_idx%9])
			// 	9'b0_0000_0001 : naked_value[g_idx/9][g_idx%9] = 4'd1;
			// 	9'b0_0000_0010 : naked_value[g_idx/9][g_idx%9] = 4'd2;
			// 	9'b0_0000_0100 : naked_value[g_idx/9][g_idx%9] = 4'd3;
			// 	9'b0_0000_1000 : naked_value[g_idx/9][g_idx%9] = 4'd4;
			// 	9'b0_0001_0000 : naked_value[g_idx/9][g_idx%9] = 4'd5;
			// 	9'b0_0010_0000 : naked_value[g_idx/9][g_idx%9] = 4'd6;
			// 	9'b0_0100_0000 : naked_value[g_idx/9][g_idx%9] = 4'd7;
			// 	9'b0_1000_0000 : naked_value[g_idx/9][g_idx%9] = 4'd8;
			// 	9'b1_0000_0000 : naked_value[g_idx/9][g_idx%9] = 4'd9; 
			// 	default: naked_value[g_idx/9][g_idx%9] = 0;
			// endcase
			// if( possible_onlyonevalue[g_idx/9][g_idx%9] ) begin
			// 	naked_single[g_idx/9][g_idx%9] = 1'b1;
			// end
			// else begin
			// 	naked_single[g_idx/9][g_idx%9] = 1'b0;
			// end
		end
	end
endgenerate
//================================================================
//  Hidden Single
//================================================================
genvar g_jdx;
generate
    for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_hidden_val
        for (g_idx = 0; g_idx < 9; g_idx = g_idx + 1) begin : gen_hidden_row
            for (g_jdx = 0; g_jdx < 9; g_jdx = g_jdx + 1) begin : gen_hidden_col
                // row
                wire [8:0] row_possible_mask;
                assign row_possible_mask = {
                    possible_values[g_idx][8][g_val], possible_values[g_idx][7][g_val],
                    possible_values[g_idx][6][g_val], possible_values[g_idx][5][g_val],
                    possible_values[g_idx][4][g_val], possible_values[g_idx][3][g_val],
                    possible_values[g_idx][2][g_val], possible_values[g_idx][1][g_val],
                    possible_values[g_idx][0][g_val]
                };
				wire row_count_is_onlyone;
				assign row_count_is_onlyone=
					// ( (row_possible_mask & (row_possible_mask-1) )==0 ) ;
					(row_possible_mask[0] & ~|row_possible_mask[8:1]) |
                    (row_possible_mask[1] & ~(|row_possible_mask[8:2] | row_possible_mask[0])) |
                    (row_possible_mask[2] & ~(|row_possible_mask[8:3] | |row_possible_mask[1:0])) |
                    (row_possible_mask[3] & ~(|row_possible_mask[8:4] | |row_possible_mask[2:0])) |
                    (row_possible_mask[4] & ~(|row_possible_mask[8:5] | |row_possible_mask[3:0])) |
                    (row_possible_mask[5] & ~(|row_possible_mask[8:6] | |row_possible_mask[4:0])) |
                    (row_possible_mask[6] & ~(|row_possible_mask[8:7] | |row_possible_mask[5:0])) |
                    (row_possible_mask[7] & ~(row_possible_mask[8] | |row_possible_mask[6:0])) |
                    (row_possible_mask[8] & ~|row_possible_mask[7:0]);


				assign row_has_unique[g_val][g_idx][g_jdx] = 
					(possible_values[g_idx][g_jdx][g_val] && row_count_is_onlyone);
				// col
				wire [8:0] col_possible_mask;
				assign col_possible_mask = {
					possible_values[8][g_jdx][g_val], possible_values[7][g_jdx][g_val],
					possible_values[6][g_jdx][g_val], possible_values[5][g_jdx][g_val],
					possible_values[4][g_jdx][g_val], possible_values[3][g_jdx][g_val],
					possible_values[2][g_jdx][g_val], possible_values[1][g_jdx][g_val],
					possible_values[0][g_jdx][g_val]
				};
				wire col_count_is_onlyone;
				assign col_count_is_onlyone=
					// ( (col_possible_mask & (col_possible_mask-1) )==0 ) ;
					(col_possible_mask[0] & ~|col_possible_mask[8:1]) |
                    (col_possible_mask[1] & ~(|col_possible_mask[8:2] | col_possible_mask[0])) |
                    (col_possible_mask[2] & ~(|col_possible_mask[8:3] | |col_possible_mask[1:0])) |
                    (col_possible_mask[3] & ~(|col_possible_mask[8:4] | |col_possible_mask[2:0])) |
                    (col_possible_mask[4] & ~(|col_possible_mask[8:5] | |col_possible_mask[3:0])) |
                    (col_possible_mask[5] & ~(|col_possible_mask[8:6] | |col_possible_mask[4:0])) |
                    (col_possible_mask[6] & ~(|col_possible_mask[8:7] | |col_possible_mask[5:0])) |
                    (col_possible_mask[7] & ~(col_possible_mask[8] | |col_possible_mask[6:0])) |
                    (col_possible_mask[8] & ~|col_possible_mask[7:0]);

				assign col_has_unique[g_val][g_idx][g_jdx] = 
					(possible_values[g_idx][g_jdx][g_val] && col_count_is_onlyone);
				//box
				wire [8:0] box_possible_mask;
				wire [2:0] box_row_start = (g_idx / 3) * 3;
                wire [2:0] box_col_start = (g_jdx / 3) * 3;
				assign box_possible_mask = {
					possible_values[box_row_start+2][box_col_start+2][g_val],
					possible_values[box_row_start+2][box_col_start+1][g_val],
					possible_values[box_row_start+2][box_col_start+0][g_val],
                    possible_values[box_row_start+1][box_col_start+2][g_val],
                    possible_values[box_row_start+1][box_col_start+1][g_val],
                    possible_values[box_row_start+1][box_col_start+0][g_val],
                    possible_values[box_row_start+0][box_col_start+2][g_val],
                    possible_values[box_row_start+0][box_col_start+1][g_val],
                    possible_values[box_row_start+0][box_col_start+0][g_val]
				};
				wire box_count_is_onlyone;
				assign box_count_is_onlyone=
					// ( (box_possible_mask & (box_possible_mask-1) )==0 ) ;
					(box_possible_mask[0] & ~|box_possible_mask[8:1]) |
                    (box_possible_mask[1] & ~(|box_possible_mask[8:2] | box_possible_mask[0])) |
                    (box_possible_mask[2] & ~(|box_possible_mask[8:3] | |box_possible_mask[1:0])) |
                    (box_possible_mask[3] & ~(|box_possible_mask[8:4] | |box_possible_mask[2:0])) |
                    (box_possible_mask[4] & ~(|box_possible_mask[8:5] | |box_possible_mask[3:0])) |
                    (box_possible_mask[5] & ~(|box_possible_mask[8:6] | |box_possible_mask[4:0])) |
                    (box_possible_mask[6] & ~(|box_possible_mask[8:7] | |box_possible_mask[5:0])) |
                    (box_possible_mask[7] & ~(box_possible_mask[8] | |box_possible_mask[6:0])) |
                    (box_possible_mask[8] & ~|box_possible_mask[7:0]);

				assign box_has_unique[g_val][g_idx][g_jdx] =
					(possible_values[g_idx][g_jdx][g_val] && box_count_is_onlyone);
			end
		end
	end
endgenerate

wire hidden_single [0:8][0:8];
wire [3:0] hidden_value [0:8][0:8];

generate
	for(g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_hidden_final
		assign hidden_single[g_idx/9][g_idx%9] = 
			(board[g_idx/9][g_idx%9] == 0) && 
			(   row_has_unique[1][g_idx/9][g_idx%9] || col_has_unique[1][g_idx/9][g_idx%9] || box_has_unique[1][g_idx/9][g_idx%9] ||
                row_has_unique[2][g_idx/9][g_idx%9] || col_has_unique[2][g_idx/9][g_idx%9] || box_has_unique[2][g_idx/9][g_idx%9] ||
                row_has_unique[3][g_idx/9][g_idx%9] || col_has_unique[3][g_idx/9][g_idx%9] || box_has_unique[3][g_idx/9][g_idx%9] ||
                row_has_unique[4][g_idx/9][g_idx%9] || col_has_unique[4][g_idx/9][g_idx%9] || box_has_unique[4][g_idx/9][g_idx%9] ||
                row_has_unique[5][g_idx/9][g_idx%9] || col_has_unique[5][g_idx/9][g_idx%9] || box_has_unique[5][g_idx/9][g_idx%9] ||
                row_has_unique[6][g_idx/9][g_idx%9] || col_has_unique[6][g_idx/9][g_idx%9] || box_has_unique[6][g_idx/9][g_idx%9] ||
                row_has_unique[7][g_idx/9][g_idx%9] || col_has_unique[7][g_idx/9][g_idx%9] || box_has_unique[7][g_idx/9][g_idx%9] ||
                row_has_unique[8][g_idx/9][g_idx%9] || col_has_unique[8][g_idx/9][g_idx%9] || box_has_unique[8][g_idx/9][g_idx%9] ||
                row_has_unique[9][g_idx/9][g_idx%9] || col_has_unique[9][g_idx/9][g_idx%9] || box_has_unique[9][g_idx/9][g_idx%9]
			);
		assign hidden_value[g_idx/9][g_idx%9] = 
            (row_has_unique[1][g_idx/9][g_idx%9] || col_has_unique[1][g_idx/9][g_idx%9] || box_has_unique[1][g_idx/9][g_idx%9]) ? 4'd1 :
            (row_has_unique[2][g_idx/9][g_idx%9] || col_has_unique[2][g_idx/9][g_idx%9] || box_has_unique[2][g_idx/9][g_idx%9]) ? 4'd2 :
            (row_has_unique[3][g_idx/9][g_idx%9] || col_has_unique[3][g_idx/9][g_idx%9] || box_has_unique[3][g_idx/9][g_idx%9]) ? 4'd3 :
            (row_has_unique[4][g_idx/9][g_idx%9] || col_has_unique[4][g_idx/9][g_idx%9] || box_has_unique[4][g_idx/9][g_idx%9]) ? 4'd4 :
            (row_has_unique[5][g_idx/9][g_idx%9] || col_has_unique[5][g_idx/9][g_idx%9] || box_has_unique[5][g_idx/9][g_idx%9]) ? 4'd5 :
            (row_has_unique[6][g_idx/9][g_idx%9] || col_has_unique[6][g_idx/9][g_idx%9] || box_has_unique[6][g_idx/9][g_idx%9]) ? 4'd6 :
            (row_has_unique[7][g_idx/9][g_idx%9] || col_has_unique[7][g_idx/9][g_idx%9] || box_has_unique[7][g_idx/9][g_idx%9]) ? 4'd7 :
            (row_has_unique[8][g_idx/9][g_idx%9] || col_has_unique[8][g_idx/9][g_idx%9] || box_has_unique[8][g_idx/9][g_idx%9]) ? 4'd8 :
            (row_has_unique[9][g_idx/9][g_idx%9] || col_has_unique[9][g_idx/9][g_idx%9] || box_has_unique[9][g_idx/9][g_idx%9]) ? 4'd9 : 4'd0;

		// always @(*) begin
		// 	if 		(row_has_unique[1][g_idx/9][g_idx%9] || col_has_unique[1][g_idx/9][g_idx%9] || box_has_unique[1][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd1;
		// 	else if (row_has_unique[2][g_idx/9][g_idx%9] || col_has_unique[2][g_idx/9][g_idx%9] || box_has_unique[2][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd2;
		// 	else if (row_has_unique[3][g_idx/9][g_idx%9] || col_has_unique[3][g_idx/9][g_idx%9] || box_has_unique[3][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd3;
		// 	else if (row_has_unique[4][g_idx/9][g_idx%9] || col_has_unique[4][g_idx/9][g_idx%9] || box_has_unique[4][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd4;
		// 	else if (row_has_unique[5][g_idx/9][g_idx%9] || col_has_unique[5][g_idx/9][g_idx%9] || box_has_unique[5][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd5;
		// 	else if (row_has_unique[6][g_idx/9][g_idx%9] || col_has_unique[6][g_idx/9][g_idx%9] || box_has_unique[6][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd6;
		// 	else if (row_has_unique[7][g_idx/9][g_idx%9] || col_has_unique[7][g_idx/9][g_idx%9] || box_has_unique[7][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd7;
		// 	else if (row_has_unique[8][g_idx/9][g_idx%9] || col_has_unique[8][g_idx/9][g_idx%9] || box_has_unique[8][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd8;
		// 	else if (row_has_unique[9][g_idx/9][g_idx%9] || col_has_unique[9][g_idx/9][g_idx%9] || box_has_unique[9][g_idx/9][g_idx%9]) hidden_value[g_idx/9][g_idx%9] = 4'd9;
		// 	else 											hidden_value[g_idx/9][g_idx%9] = 4'd0;
		// end
	end

endgenerate

//================================================================
//  Found Solution?
//================================================================
always @(*) begin
    solution_found = 0;
    for (i = 0; i < 9; i = i + 1) begin
        for (j = 0; j < 9; j = j + 1) begin
            if (naked_single[i][j] || hidden_single[i][j]) begin
                solution_found = 1;
            end
        end
    end
end
//================================================================
//  EXIST
//================================================================
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
//  INPUT
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	count_in <= 7'd0 ;
	else begin
		if (in_valid==1'b1)					count_in <= count_in + 1 ;
		else if (next_state==OUTPUT)	    count_in <= 7'd0 ;
	end
end

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
			for( i=0 ; i<9 ; i=i+1 )
				for( j=0 ; j<9 ; j=j+1 ) begin
					if (naked_single[i][j]) 
						board[i][j] <= naked_value[i][j];
					else if (hidden_single[i][j]) begin
						board[i][j] <= hidden_value[i][j];
					end
				end
		end
		// else
		// 	board[i][j] <= board[i][j] ;
	end
end
endmodule
//v1
// //Cycle: 10.00
// Area: 210255.095618
// Performance: 442072052333.34322801924000
