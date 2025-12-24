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
integer i, j, k, val;
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
reg  possible_values [1:9][0:8][0:8];

reg [6:0] count_out;  

// 新增：求解相關變數
wire [3:0] possible_count [0:8][0:8];
wire naked_single [0:8][0:8];
wire [3:0] naked_value [0:8][0:8];
wire hidden_single [0:8][0:8];
wire [3:0] hidden_value [0:8][0:8];
reg solution_found;

// Hidden Single 檢測用的中間信號
wire row_has_unique [1:9][0:8][0:8];  // [value][row][col] 該值在該行是否只能放在此格
wire col_has_unique [1:9][0:8][0:8];  // [value][row][col] 該值在該列是否只能放在此格
wire box_has_unique [1:9][0:8][0:8];  // [value][row][col] 該值在該箱是否只能放在此格

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
		else                           		remain_emptynum <= 7'd0;
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
//   Design                                                            
//==============================
genvar g_idx, g_val;
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_possible
        wire is_valid_blank = (board[g_idx/9][g_idx%9] == 0);
        
        for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_val
            assign possible_values [g_val][g_idx/9][g_idx%9] = is_valid_blank && 
                											  !rowhas[g_val][g_idx/9] && 
                											  !colhas[g_val][g_idx%9] && 
                											  !boxhas[g_val][3*((g_idx/9)/3) + (g_idx%9)/3];
        end
    end
endgenerate

//================================================================
//  新增：計算每格的可能數字數量 (不使用$countones)
//================================================================
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_count
        assign possible_count[g_idx/9][g_idx%9] = 
            (possible_values[1][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) + 
            (possible_values[2][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) +
            (possible_values[3][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) + 
            (possible_values[4][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) +
            (possible_values[5][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) + 
            (possible_values[6][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) +
            (possible_values[7][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) + 
            (possible_values[8][g_idx/9][g_idx%9] ? 4'd1 : 4'd0) +
            (possible_values[9][g_idx/9][g_idx%9] ? 4'd1 : 4'd0);
    end
endgenerate

//================================================================
//  新增：Naked Single 檢測
//================================================================
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_naked
        assign naked_single[g_idx/9][g_idx%9] = 
            (board[g_idx/9][g_idx%9] == 0) && (possible_count[g_idx/9][g_idx%9] == 4'd1);
            
        // 找出唯一可能的值
        assign naked_value[g_idx/9][g_idx%9] = 
            possible_values[1][g_idx/9][g_idx%9] ? 4'd1 :
            possible_values[2][g_idx/9][g_idx%9] ? 4'd2 :
            possible_values[3][g_idx/9][g_idx%9] ? 4'd3 :
            possible_values[4][g_idx/9][g_idx%9] ? 4'd4 :
            possible_values[5][g_idx/9][g_idx%9] ? 4'd5 :
            possible_values[6][g_idx/9][g_idx%9] ? 4'd6 :
            possible_values[7][g_idx/9][g_idx%9] ? 4'd7 :
            possible_values[8][g_idx/9][g_idx%9] ? 4'd8 :
            possible_values[9][g_idx/9][g_idx%9] ? 4'd9 : 4'd0;
    end
endgenerate

//================================================================
//  新增：Hidden Single 檢測 (可合成版本)
//================================================================
genvar g_jdx;
generate
    for (g_val = 1; g_val <= 9; g_val = g_val + 1) begin : gen_hidden_val
        for (g_idx = 0; g_idx < 9; g_idx = g_idx + 1) begin : gen_hidden_row
            for (g_jdx = 0; g_jdx < 9; g_jdx = g_jdx + 1) begin : gen_hidden_col
                // 檢查該值在該行是否只能放在此位置
                wire [8:0] row_possible_mask;
                assign row_possible_mask = {
                    possible_values[g_val][g_idx][8], possible_values[g_val][g_idx][7],
                    possible_values[g_val][g_idx][6], possible_values[g_val][g_idx][5],
                    possible_values[g_val][g_idx][4], possible_values[g_val][g_idx][3],
                    possible_values[g_val][g_idx][2], possible_values[g_val][g_idx][1],
                    possible_values[g_val][g_idx][0]
                };
                
                // 手動計算位元數量是否為1 (用於行檢查)
                wire row_count_is_one;
                assign row_count_is_one = 
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
                    possible_values[g_val][g_idx][g_jdx] && row_count_is_one;
                
                // 檢查該值在該列是否只能放在此位置
                wire [8:0] col_possible_mask;
                assign col_possible_mask = {
                    possible_values[g_val][8][g_jdx], possible_values[g_val][7][g_jdx],
                    possible_values[g_val][6][g_jdx], possible_values[g_val][5][g_jdx],
                    possible_values[g_val][4][g_jdx], possible_values[g_val][3][g_jdx],
                    possible_values[g_val][2][g_jdx], possible_values[g_val][1][g_jdx],
                    possible_values[g_val][0][g_jdx]
                };
                
                // 手動計算位元數量是否為1 (用於列檢查)
                wire col_count_is_one;
                assign col_count_is_one = 
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
                    possible_values[g_val][g_idx][g_jdx] && col_count_is_one;
                
                // 檢查該值在該箱是否只能放在此位置
                wire [8:0] box_possible_mask;
                wire [2:0] box_row_start = (g_idx / 3) * 3;
                wire [2:0] box_col_start = (g_jdx / 3) * 3;
                assign box_possible_mask = {
                    possible_values[g_val][box_row_start+2][box_col_start+2],
                    possible_values[g_val][box_row_start+2][box_col_start+1],
                    possible_values[g_val][box_row_start+2][box_col_start+0],
                    possible_values[g_val][box_row_start+1][box_col_start+2],
                    possible_values[g_val][box_row_start+1][box_col_start+1],
                    possible_values[g_val][box_row_start+1][box_col_start+0],
                    possible_values[g_val][box_row_start+0][box_col_start+2],
                    possible_values[g_val][box_row_start+0][box_col_start+1],
                    possible_values[g_val][box_row_start+0][box_col_start+0]
                };
                
                // 手動計算位元數量是否為1 (用於箱檢查)
                wire box_count_is_one;
                assign box_count_is_one = 
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
                    possible_values[g_val][g_idx][g_jdx] && box_count_is_one;
            end
        end
    end
endgenerate

// 綜合Hidden Single檢測結果
generate
    for (g_idx = 0; g_idx < 81; g_idx = g_idx + 1) begin : gen_hidden_final
        assign hidden_single[g_idx/9][g_idx%9] = 
            (board[g_idx/9][g_idx%9] == 0) && (
                row_has_unique[1][g_idx/9][g_idx%9] || col_has_unique[1][g_idx/9][g_idx%9] || box_has_unique[1][g_idx/9][g_idx%9] ||
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
//  求解邏輯：檢查是否找到解
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
				board[8][8] <= in ;			// newest in
				for( i=0 ; i<9 ; i=i+1 )	// shift-register : except right-most column
					for( j=0 ; j<8 ; j=j+1 )
						board[i][j] <= board[i][j+1] ;
				for( i=0 ; i<8 ; i=i+1 )	// shift-register : right-most column
					board[i][8] <= board[i+1][0] ;
			end
		end
		// 新增：SOLVE_UPDATE階段的更新邏輯
		else if (current_state == SOLVE_UPDATE) begin
			for (i = 0; i < 9; i = i + 1) begin
				for (j = 0; j < 9; j = j + 1) begin
					if (naked_single[i][j]) begin
						board[i][j] <= naked_value[i][j];
					end
					else if (hidden_single[i][j]) begin
						board[i][j] <= hidden_value[i][j];
					end
				end
			end
		end
	end
end

endmodule

// Cycle: 10.00
// Area: 211156.549902
