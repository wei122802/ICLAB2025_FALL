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
parameter SOLVE_UPDATE = 2'd1 ;
parameter OUTPUT       = 2'd2 ;

//==============================
//   LOGIC DECLARATION                                                 
//==============================
reg [6:0] count_in;
reg [3:0] board[0:8][0:8];
// FSM
reg [1:0] current_state;
reg [1:0] next_state;
reg [6:0] count_out;  
reg [3:0] naked_value [0:8][0:8];
reg done;
wire  [9:1] possible_values [0:8][0:8];
wire row_has_unique [1:9][0:8][0:8];  
wire col_has_unique [1:9][0:8][0:8];  
wire box_has_unique [1:9][0:8][0:8]; 
wire naked_single [0:8][0:8];
wire [3:0] possible_count [0:8][0:8];
wire hidden_single [0:8][0:8];
wire [3:0] hidden_value [0:8][0:8];
wire rowhas[1:9][0:8];
wire colhas[1:9][0:8];	
wire boxhas[1:9][0:8];	

//==============================
//   FSM                                                           
//==============================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) current_state <= INPUT ;
	else 		current_state <= next_state ;
end

always @(*) begin
	case(current_state)
		INPUT: begin
			if (count_in==7'd81)	next_state = SOLVE_UPDATE ;
			else 				    next_state = INPUT ;
		end
		SOLVE_UPDATE: begin
			if (done)	next_state = OUTPUT ; 
			else 		next_state = SOLVE_UPDATE ;
		end
		OUTPUT: begin
			if (count_out> 7'd80)	next_state = INPUT ;
			else 					next_state = OUTPUT ;
		end
		default next_state = current_state;
	endcase
end
//================================================================
//  OUTPUT : out_valid & out
//================================================================

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)						out_valid <= 1'b0 ;
	else if (next_state==OUTPUT)	out_valid <= 1'b1 ; 
	else 							out_valid <= 1'b0 ;
end
// output reg [3:0] out;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)		out <= 4'd0 ;
	else if (next_state==OUTPUT) 
		out <= board[ count_out/9 ][ count_out %9] ;
	else
        out <= 4'd0 ;
end
//================================================================
//  Output count
//================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)	count_out <= 7'd0 ; 
	else if (next_state==OUTPUT)  count_out <= count_out + 1 ; 
    else count_out <= 0;
end
//==============================
//   Possible Values                                                           
//==============================
// wire possible_onlyonevalue[0:8][0:8];
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
    end
endgenerate
//==============================
//   Naked Single                                                           
//==============================
generate
	for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_naked_single
		assign naked_single[g_idx/9][g_idx%9] = 
            (board[g_idx/9][g_idx%9] == 0) && ((possible_values[g_idx/9][g_idx%9] & (possible_values[g_idx/9][g_idx%9]-1) )==0 );
	end
endgenerate

generate
	for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin 
		always @(*) begin
			case (possible_values[g_idx/9][g_idx%9])
				9'b0_0000_0001 : naked_value[g_idx/9][g_idx%9] = 4'd1;
				9'b0_0000_0010 : naked_value[g_idx/9][g_idx%9] = 4'd2;
				9'b0_0000_0100 : naked_value[g_idx/9][g_idx%9] = 4'd3;
				9'b0_0000_1000 : naked_value[g_idx/9][g_idx%9] = 4'd4;
				9'b0_0001_0000 : naked_value[g_idx/9][g_idx%9] = 4'd5;
				9'b0_0010_0000 : naked_value[g_idx/9][g_idx%9] = 4'd6;
				9'b0_0100_0000 : naked_value[g_idx/9][g_idx%9] = 4'd7;
				9'b0_1000_0000 : naked_value[g_idx/9][g_idx%9] = 4'd8;
				9'b1_0000_0000 : naked_value[g_idx/9][g_idx%9] = 4'd9; 
				default: naked_value[g_idx/9][g_idx%9] = 0;
			endcase
		end
	end
endgenerate
//================================================================
//  Hidden Single
//================================================================
wire [8:0] row_possible_mask [0:8][1:9] ;
genvar g_jdx;

generate
	for (g_val = 1; g_val <= 9; g_val = g_val + 1)
        for (g_idx = 0; g_idx < 9; g_idx = g_idx + 1) 
			assign row_possible_mask[g_idx][g_val] = {
                possible_values[g_idx][8][g_val], possible_values[g_idx][7][g_val],
                possible_values[g_idx][6][g_val], possible_values[g_idx][5][g_val],
                possible_values[g_idx][4][g_val], possible_values[g_idx][3][g_val],
                possible_values[g_idx][2][g_val], possible_values[g_idx][1][g_val],
                possible_values[g_idx][0][g_val]
                };
endgenerate

generate
    for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_hidden_val
        for (g_idx = 0; g_idx < 9; g_idx = g_idx + 1) begin : gen_hidden_row
            for (g_jdx = 0; g_jdx < 9; g_jdx = g_jdx + 1) begin : gen_hidden_col
				assign row_has_unique[g_val][g_idx][g_jdx] = ((row_possible_mask[g_idx][g_val] != 0)&(row_possible_mask[g_idx][g_val] & (row_possible_mask[g_idx][g_val]-1) )==0 ) ?
					(possible_values[g_idx][g_jdx][g_val]) :0;
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
					(col_possible_mask == 0) ? 0 : 
					(col_possible_mask[0] & ~|col_possible_mask[8:1]) |
                    (col_possible_mask[1] & ~(|col_possible_mask[8:2] | col_possible_mask[0])) |
                    (col_possible_mask[2] & ~(|col_possible_mask[8:3] | (|col_possible_mask[1:0]))) |
                    (col_possible_mask[3] & ~(|col_possible_mask[8:4] | (|col_possible_mask[2:0]))) |
                    (col_possible_mask[4] & ~(|col_possible_mask[8:5] | (|col_possible_mask[3:0]))) |
                    (col_possible_mask[5] & ~(|col_possible_mask[8:6] | (|col_possible_mask[4:0]))) |
                    (col_possible_mask[6] & ~(|col_possible_mask[8:7] | (|col_possible_mask[5:0]))) |
                    (col_possible_mask[7] & ~(col_possible_mask[8] | (|col_possible_mask[6:0]))) |
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
	end

endgenerate

//================================================================
//  Found Solution?
//================================================================
always @(*) begin
	done =     board[0][0] != 0 && board[0][1] != 0 && board[0][2] != 0 && board[0][3] != 0 && board[0][4] != 0 && board[0][5] != 0 && board[0][6] != 0 && board[0][7] != 0 && board[0][8] != 0
		&& board[1][0] != 0 && board[1][1] != 0 && board[1][2] != 0 && board[1][3] != 0 && board[1][4] != 0 && board[1][5] != 0 && board[1][6] != 0 && board[1][7] != 0 && board[1][8] != 0
		&& board[2][0] != 0 && board[2][1] != 0 && board[2][2] != 0 && board[2][3] != 0 && board[2][4] != 0 && board[2][5] != 0 && board[2][6] != 0 && board[2][7] != 0 && board[2][8] != 0
		&& board[3][0] != 0 && board[3][1] != 0 && board[3][2] != 0 && board[3][3] != 0 && board[3][4] != 0 && board[3][5] != 0 && board[3][6] != 0 && board[3][7] != 0 && board[3][8] != 0
		&& board[4][0] != 0 && board[4][1] != 0 && board[4][2] != 0 && board[4][3] != 0 && board[4][4] != 0 && board[4][5] != 0 && board[4][6] != 0 && board[4][7] != 0 && board[4][8] != 0
		&& board[5][0] != 0 && board[5][1] != 0 && board[5][2] != 0 && board[5][3] != 0 && board[5][4] != 0 && board[5][5] != 0 && board[5][6] != 0 && board[5][7] != 0 && board[5][8] != 0
		&& board[6][0] != 0 && board[6][1] != 0 && board[6][2] != 0 && board[6][3] != 0 && board[6][4] != 0 && board[6][5] != 0 && board[6][6] != 0 && board[6][7] != 0 && board[6][8] != 0
		&& board[7][0] != 0 && board[7][1] != 0 && board[7][2] != 0 && board[7][3] != 0 && board[7][4] != 0 && board[7][5] != 0 && board[7][6] != 0 && board[7][7] != 0 && board[7][8] != 0
		&& board[8][0] != 0 && board[8][1] != 0 && board[8][2] != 0 && board[8][3] != 0 && board[8][4] != 0 && board[8][5] != 0 && board[8][6] != 0 && board[8][7] != 0 && board[8][8] != 0 ;
end

//================================================================
//  row col box Has 
//================================================================
generate
for( ndx=1 ; ndx<10 ; ndx=ndx+1 ) begin
	for( idx=0 ; idx<9 ; idx=idx+1 )
		assign rowhas[ndx][idx] = (board[idx][0]==ndx) || (board[idx][1]==ndx) || (board[idx][2]==ndx) ||
								  (board[idx][3]==ndx) || (board[idx][4]==ndx) || (board[idx][5]==ndx) ||
								  (board[idx][6]==ndx) || (board[idx][7]==ndx) || (board[idx][8]==ndx) ;
	for( jdx=0 ; jdx<9 ; jdx=jdx+1 )
		assign colhas[ndx][jdx] = (board[0][jdx]==ndx) || (board[1][jdx]==ndx) || (board[2][jdx]==ndx) ||
								  (board[3][jdx]==ndx) || (board[4][jdx]==ndx) || (board[5][jdx]==ndx) ||
								  (board[6][jdx]==ndx) || (board[7][jdx]==ndx) || (board[8][jdx]==ndx) ;
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
	if (!rst_n)			count_in <= 7'd0 ;
	else if (in_valid)	count_in <= count_in + 1 ;
	else 	            count_in <= 7'd0 ;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		for( i=0 ; i<9 ; i=i+1 )
			for( j=0 ; j<9 ; j=j+1 )
				board[i][j] <= 4'd0 ;
	else if (next_state==INPUT) begin
			if (in_valid==1'b1) begin
				board[8][8] <= in ;		
				for( i=0 ; i<9 ; i=i+1 )	
					for( j=0 ; j<8 ; j=j+1 )
						board[i][j] <= board[i][j+1] ;
				for( i=0 ; i<8 ; i=i+1 )
					board[i][8] <= board[i+1][0] ;
			end
		end
	else if (next_state==SOLVE_UPDATE) begin
			for( i=0 ; i<9 ; i=i+1 )
				for( j=0 ; j<9 ; j=j+1 ) begin
					if (naked_single[i][j]) 
						board[i][j] <= naked_value[i][j];
					else if (hidden_single[i][j]) 
						board[i][j] <= hidden_value[i][j];
				end
		end
	else
			for( i=0 ; i<9 ; i=i+1 )
				for( j=0 ; j<9 ; j=j+1 )
					board[i][j] <= board[i][j] ;
	end
endmodule