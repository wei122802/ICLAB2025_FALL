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
parameter BACKTRACK    = 2'd1 ;
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
wire done;
wire  [9:1] possible_values [0:8][0:8];
wire row_has_unique [1:9][0:8][0:8];  
wire col_has_unique [1:9][0:8][0:8];  
wire box_has_unique [1:9][0:8][0:8]; 
wire naked_single [0:8][0:8];
wire [3:0] possible_count [0:8][0:8];
wire hidden_single [0:8][0:8];
wire [3:0] hidden_value [0:8][0:8];

reg [6:0] remain_emptynum;  
reg [6:0] count_out;  
reg solution_found;
// reg naked_single [0:8][0:8];
reg [3:0] naked_value [0:8][0:8];
reg [6:0] emptynum;
assign done =(remain_emptynum==0 );
reg backtrackstart;
reg [6:0] num_filled ;
reg [6:0] num_filled_comb ; 
reg [3:0] backtrackboard [0:8][0:8];
reg [3:0] bt_col , bt_row ; 
reg [3:0] try_value ;
reg dead,rowdead,coldead,boxdead;
wire has_contradiction ;
// assign has_contradiction = dead || rowdead || coldead || boxdead ;
assign has_contradiction = dead || rowdead;
integer s,c1,c2;

always @(*) begin
    rowdead = 0;
    for (s=0; s<9; s=s+1) begin
        for (c1=0; c1<9; c1=c1+1) begin
            for (c2=c1+1; c2<9; c2=c2+1) begin
                if (board[s][c1] != 0 && board[s][c1] == board[s][c2]) begin
                    rowdead = (current_state==BACKTRACK);
                end
            end
        end
    end
end


assign dead	 =  (current_state==BACKTRACK) && (
						   (board[0][0]==0 && possible_count[0][0]==0 ) || ( board[0][1]==0 && possible_count[0][1]==0 ) || (
							board[0][2]==0 && possible_count[0][2]==0 ) || ( board[0][3]==0 && possible_count[0][3]==0 ) || (
							board[0][4]==0 && possible_count[0][4]==0 ) || ( board[0][5]==0 && possible_count[0][5]==0 ) || (
							board[0][6]==0 && possible_count[0][6]==0 ) || ( board[0][7]==0 && possible_count[0][7]==0 ) || (
							board[0][8]==0 && possible_count[0][8]==0 ) || ( board[1][0]==0 && possible_count[1][0]==0 ) || (
							board[1][1]==0 && possible_count[1][1]==0 ) || ( board[1][2]==0 && possible_count[1][2]==0 ) || (
							board[1][3]==0 && possible_count[1][3]==0 ) || ( board[1][4]==0 && possible_count[1][4]==0 ) || (
							board[1][5]==0 && possible_count[1][5]==0 ) || ( board[1][6]==0 && possible_count[1][6]==0 ) || (
							board[1][7]==0 && possible_count[1][7]==0 ) || ( board[1][8]==0 && possible_count[1][8]==0 ) || (
							board[2][0]==0 && possible_count[2][0]==0 ) || ( board[2][1]==0 && possible_count[2][1]==0 ) || (
							board[2][2]==0 && possible_count[2][2]==0 ) || ( board[2][3]==0 && possible_count[2][3]==0 ) || (
							board[2][4]==0 && possible_count[2][4]==0 ) || ( board[2][5]==0 && possible_count[2][5]==0 ) || (
							board[2][6]==0 && possible_count[2][6]==0 ) || ( board[2][7]==0 && possible_count[2][7]==0 ) || (
							board[2][8]==0 && possible_count[2][8]==0 ) || ( board[3][0]==0 && possible_count[3][0]==0 ) || (
							board[3][1]==0 && possible_count[3][1]==0 ) || ( board[3][2]==0 && possible_count[3][2]==0 ) || (
							board[3][3]==0 && possible_count[3][3]==0 ) || ( board[3][4]==0 && possible_count[3][4]==0 ) || (
							board[3][5]==0 && possible_count[3][5]==0 ) || ( board[3][6]==0 && possible_count[3][6]==0 ) || (
							board[3][7]==0 && possible_count[3][7]==0 ) || ( board[3][8]==0 && possible_count[3][8]==0 ) || (
							board[4][0]==0 && possible_count[4][0]==0 ) || ( board[4][1]==0 && possible_count[4][1]==0 ) || (
							board[4][2]==0 && possible_count[4][2]==0 ) || ( board[4][3]==0 && possible_count[4][3]==0 ) || (
							board[4][4]==0 && possible_count[4][4]==0 ) || ( board[4][5]==0 && possible_count[4][5]==0 ) || (
							board[4][6]==0 && possible_count[4][6]==0 ) || ( board[4][7]==0 && possible_count[4][7]==0 ) || (
							board[4][8]==0 && possible_count[4][8]==0 ) || ( board[5][0]==0 && possible_count[5][0]==0 ) || (
							board[5][1]==0 && possible_count[5][1]==0 ) || ( board[5][2]==0 && possible_count[5][2]==0 ) || (
							board[5][3]==0 && possible_count[5][3]==0 ) || ( board[5][4]==0 && possible_count[5][4]==0 ) || (
							board[5][5]==0 && possible_count[5][5]==0 ) || ( board[5][6]==0 && possible_count[5][6]==0 ) || (
							board[5][7]==0 && possible_count[5][7]==0 ) || ( board[5][8]==0 && possible_count[5][8]==0 ) || (
							board[6][0]==0 && possible_count[6][0]==0 ) || ( board[6][1]==0 && possible_count[6][1]==0 ) || (
							board[6][2]==0 && possible_count[6][2]==0 ) || ( board[6][3]==0 && possible_count[6][3]==0 ) || (
							board[6][4]==0 && possible_count[6][4]==0 ) || ( board[6][5]==0 && possible_count[6][5]==0 ) || (
							board[6][6]==0 && possible_count[6][6]==0 ) || ( board[6][7]==0 && possible_count[6][7]==0 ) || (
							board[6][8]==0 && possible_count[6][8]==0 ) || ( board[7][0]==0 && possible_count[7][0]==0 ) || (
							board[7][1]==0 && possible_count[7][1]==0 ) || ( board[7][2]==0 && possible_count[7][2]==0 ) || (
							board[7][3]==0 && possible_count[7][3]==0 ) || ( board[7][4]==0 && possible_count[7][4]==0 ) || (
							board[7][5]==0 && possible_count[7][5]==0 ) || ( board[7][6]==0 && possible_count[7][6]==0 ) || (
							board[7][7]==0 && possible_count[7][7]==0 ) || ( board[7][8]==0 && possible_count[7][8]==0 ) || (
							board[8][0]==0 && possible_count[8][0]==0 ) || ( board[8][1]==0 && possible_count[8][1]==0 ) || (
							board[8][2]==0 && possible_count[8][2]==0 ) || ( board[8][3]==0 && possible_count[8][3]==0 ) || (
							board[8][4]==0 && possible_count[8][4]==0 ) || ( board[8][5]==0 && possible_count[8][5]==0 ) || (
							board[8][6]==0 && possible_count[8][6]==0 ) || ( board[8][7]==0 && possible_count[8][7]==0 ) || (
							board[8][8]==0 && possible_count[8][8]==0 ) );


always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		try_value <= 4'd0 ;
	else if (current_state==BACKTRACK)
		case (1)
			(possible_values[bt_row][bt_col][1])  : try_value <= 4'd1 ;
			(possible_values[bt_row][bt_col][2])  : try_value <= 4'd2 ;
			(possible_values[bt_row][bt_col][3])  : try_value <= 4'd3 ;
			(possible_values[bt_row][bt_col][4])  : try_value <= 4'd4 ;
			(possible_values[bt_row][bt_col][5])  : try_value <= 4'd5 ;
			(possible_values[bt_row][bt_col][6])  : try_value <= 4'd6 ;
			(possible_values[bt_row][bt_col][7])  : try_value <= 4'd7 ;
			(possible_values[bt_row][bt_col][8])  : try_value <= 4'd8 ;
			(possible_values[bt_row][bt_col][9])  : try_value <= 4'd9 ;
			default: try_value <= try_value ;
		endcase
end
integer m;
// generate
	// for (idx = 0; idx < 64; idx = idx + 1) begin : gen_btcolandrow
		always @(posedge clk or negedge rst_n) begin
			if(!rst_n) begin
			bt_col <=0;
			bt_row <=0;
			end
			else if(backtrackstart) begin
				for (m =0 ; m<64 ;m=m+1 ) begin //maybe
					if( possible_count[m/9][m%9] == 2 && possible_count[m/9][m%9] > 0)
					begin
						bt_col <= m%9 ;
						bt_row <= m/9 ;
					end
				end
			end
			else begin
				bt_col <= bt_col;
				bt_row <= bt_row;
			end
		end
// 	end
// endgenerate
integer n,r;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		for(n=0 ; n<9 ; n=n+1)
			for(r=0 ; r<9 ; r=r+1)
				backtrackboard[n][r] <= 4'd0;

	else if(next_state == BACKTRACK) 
		for(n=0 ; n<9 ; n=n+1)
			for(r=0 ; r<9 ; r=r+1)
				if(backtrackstart)
					backtrackboard[n][r] <= board[n][r] ;
				else 
					backtrackboard[n][r] <= backtrackboard[n][r];
	else 	
		for(n=0 ; n<9 ; n=n+1)
			for(r=0 ; r<9 ; r=r+1)
				backtrackboard[n][r] <= 4'd0;
end

//================================================================
//  Back track start or not
//================================================================
always @(*) begin
	if (current_state==SOLVE_UPDATE)
		backtrackstart = (num_filled==0 && remain_emptynum!=0) ;
	else backtrackstart = 0;
end
//================================================================
//  emptynum
//================================================================


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	num_filled <= 7'd0 ;
	else if (backtrackstart) num_filled <=1;
	else num_filled <= num_filled_comb ; 
end

always @(*) begin
	if(next_state==SOLVE_UPDATE || next_state==BACKTRACK)
		num_filled_comb =  (naked_single[0][0] | hidden_single[0][0] )  + (naked_single[0][1] | hidden_single[0][1] )  
					+ (naked_single[0][2] | hidden_single[0][2] )  + (naked_single[0][3] | hidden_single[0][3] )  
					+ (naked_single[0][4] | hidden_single[0][4] )  + (naked_single[0][5] | hidden_single[0][5] )  
					+ (naked_single[0][6] | hidden_single[0][6] )  + (naked_single[0][7] | hidden_single[0][7] )  
					+ (naked_single[0][8] | hidden_single[0][8] )  
					+ (naked_single[1][0] | hidden_single[1][0] )  + (naked_single[1][1] | hidden_single[1][1] )  
					+ (naked_single[1][2] | hidden_single[1][2] )  + (naked_single[1][3] | hidden_single[1][3] )  
					+ (naked_single[1][4] | hidden_single[1][4] )  + (naked_single[1][5] | hidden_single[1][5] )  
					+ (naked_single[1][6] | hidden_single[1][6] )  + (naked_single[1][7] | hidden_single[1][7] )  
					+ (naked_single[1][8] | hidden_single[1][8] )  
					+ (naked_single[2][0] | hidden_single[2][0] )  + (naked_single[2][1] | hidden_single[2][1] )  
					+ (naked_single[2][2] | hidden_single[2][2] )  + (naked_single[2][3] | hidden_single[2][3] )  
					+ (naked_single[2][4] | hidden_single[2][4] )  + (naked_single[2][5] | hidden_single[2][5] )  
					+ (naked_single[2][6] | hidden_single[2][6] )  + (naked_single[2][7] | hidden_single[2][7] )  
					+ (naked_single[2][8] | hidden_single[2][8] )  
					+ (naked_single[3][0] | hidden_single[3][0] ) + (naked_single[3][1] | hidden_single[3][1] )
					+ (naked_single[3][2] | hidden_single[3][2] ) + (naked_single[3][3] | hidden_single[3][3] )
					+ (naked_single[3][4] | hidden_single[3][4] ) + (naked_single[3][5] | hidden_single[3][5] )
					+ (naked_single[3][6] | hidden_single[3][6] ) + (naked_single[3][7] | hidden_single[3][7] )
					+ (naked_single[3][8] | hidden_single[3][8] )
					+ (naked_single[4][0] | hidden_single[4][0] ) + (naked_single[4][1] | hidden_single[4][1] )
					+ (naked_single[4][2] | hidden_single[4][2] ) + (naked_single[4][3] | hidden_single[4][3] )
					+ (naked_single[4][4] | hidden_single[4][4] ) + (naked_single[4][5] | hidden_single[4][5] )
					+ (naked_single[4][6] | hidden_single[4][6] ) + (naked_single[4][7] | hidden_single[4][7] )
					+ (naked_single[4][8] | hidden_single[4][8] )
					+ (naked_single[5][0] | hidden_single[5][0] ) + (naked_single[5][1] | hidden_single[5][1] )
					+ (naked_single[5][2] | hidden_single[5][2] ) + (naked_single[5][3] | hidden_single[5][3] )
					+ (naked_single[5][4] | hidden_single[5][4] ) + (naked_single[5][5] | hidden_single[5][5] )
					+ (naked_single[5][6] | hidden_single[5][6] ) + (naked_single[5][7] | hidden_single[5][7] )
					+ (naked_single[5][8] | hidden_single[5][8] )
					+ (naked_single[6][0] | hidden_single[6][0] ) + (naked_single[6][1] | hidden_single[6][1] )
					+ (naked_single[6][2] | hidden_single[6][2] ) + (naked_single[6][3] | hidden_single[6][3] )
					+ (naked_single[6][4] | hidden_single[6][4] ) + (naked_single[6][5] | hidden_single[6][5] )
					+ (naked_single[6][6] | hidden_single[6][6] ) + (naked_single[6][7] | hidden_single[6][7] )
					+ (naked_single[6][8] | hidden_single[6][8] )
					+ (naked_single[7][0] | hidden_single[7][0] ) + (naked_single[7][1] | hidden_single[7][1] )
					+ (naked_single[7][2] | hidden_single[7][2] ) + (naked_single[7][3] | hidden_single[7][3] )
					+ (naked_single[7][4] | hidden_single[7][4] ) + (naked_single[7][5] | hidden_single[7][5] )
					+ (naked_single[7][6] | hidden_single[7][6] ) + (naked_single[7][7] | hidden_single[7][7] )
					+ (naked_single[7][8] | hidden_single[7][8] )
					+ (naked_single[8][0] | hidden_single[8][0] ) + (naked_single[8][1] | hidden_single[8][1] )
					+ (naked_single[8][2] | hidden_single[8][2] ) + (naked_single[8][3] | hidden_single[8][3] )
					+ (naked_single[8][4] | hidden_single[8][4] ) + (naked_single[8][5] | hidden_single[8][5] )
					+ (naked_single[8][6] | hidden_single[8][6] ) + (naked_single[8][7] | hidden_single[8][7] )
					+ (naked_single[8][8] | hidden_single[8][8] ) ;
	else 
		num_filled_comb = 0;
end
wire emptytemp[0:8][0:8];
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	emptynum <= 7'd0 ;
	else begin
		if (current_state==INPUT) begin
			if (in_valid==1'b1 && in==4'd0) begin
			    emptynum <= emptynum + 1 ;
				// emptytemp[count_in] <= 1'b1;
			end
		end
		else if (current_state==OUTPUT)	emptynum <= 7'd0 ; 
	end
end
// reg [6:0] remain_emptynum; 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) 	remain_emptynum <= 7'd0 ; 
	else begin
		if (current_state==INPUT)			  remain_emptynum <= emptynum ;
		else if (next_state==SOLVE_UPDATE || next_state==BACKTRACK)    remain_emptynum <= remain_emptynum - num_filled ;
		else if (next_state==OUTPUT)		  remain_emptynum <= 0;
		else                           		  remain_emptynum <= remain_emptynum ;
	end
end

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
			else if (backtrackstart || has_contradiction) next_state = BACKTRACK;
			else 		next_state = SOLVE_UPDATE ;
		end
		BACKTRACK : 
			if(has_contradiction) next_state = SOLVE_UPDATE ;
			else if (done)	next_state = OUTPUT ; 
			else next_state = BACKTRACK ;
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

// wire possible_onlyonevalue[0:8][0:8];
genvar g_idx, g_val;
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_possible
		wire is_valid_blank = (board[g_idx/9][g_idx%9] == 0);
		assign emptytemp[g_idx/9][g_idx%9] = is_valid_blank;
	    for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_val
            assign possible_values [g_idx/9][g_idx%9][g_val] = is_valid_blank && 
                											  !rowhas[g_val][g_idx/9] && 
                											  !colhas[g_val][g_idx%9] && 
                											  !boxhas[g_val][3*((g_idx/9)/3) + (g_idx%9)/3];
        end
    end
endgenerate
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_count
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
				assign row_count_is_onlyone= (row_possible_mask == 0) ? 0 : 
					( (row_possible_mask & (row_possible_mask-1) )==0 ) ;

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
				assign col_count_is_onlyone=  (col_possible_mask == 0) ? 0 : 
					( (col_possible_mask & (col_possible_mask-1) )==0 ) ;

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
					else if( has_contradiction )
						board[i][j] <= backtrackboard[i][j] ;
				end	
		end
		else if (current_state==BACKTRACK) begin
			for( i=0 ; i<9 ; i=i+1 )
				for( j=0 ; j<9 ; j=j+1 ) begin
					if (naked_single[i][j]) 
						board[i][j] <= naked_value[i][j];
					else if (hidden_single[i][j]) begin
						board[i][j] <= hidden_value[i][j];
					end 
					else if( has_contradiction )
						board[i][j] <= backtrackboard[i][j] ;
					else 
						board[bt_row][bt_col] <= try_value;
				end	
			
		end
		else
			board[i][j] <= board[i][j] ;
	end
end
endmodule
//v1
// //Cycle: 10.00
// Area: 210255.095618
// Performance: 442072052333.34322801924000

//v2 use x & (x-1) ==0 to check onehot or not
// Cycle: 10.00
// Area: 216718.290957
// Performance: 469668176353.22907975849000

//v3 use case to assign naked_value
// Cycle: 10.00
// Area: 215574.009177 216
// Performance: 464721534326.45280217329000

// Cycle: 9.00
// Area: 215580.661975
// Performance: 418275196358.21289810562500

// Cycle: 8.50
// Area: 215607.273171
// Performance: 395135218075.99083935954850


