/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2025
// AUTHOR: Chao-En Kuo, NYCU IAIS
// DESCRIPTION: ICLAB2025FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 12
`endif
`ifdef GATE
    `define CYCLE_TIME 12
`endif

module PATTERN (
	// Output
	rst_n,
	clk,
	in_valid,
	pt_num,
	in_x,
	in_y,
	// Input
	out_valid,
	out_x,
	out_y,
	drop_num
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n;
output reg			clk;
output reg			in_valid;
output reg	[8:0]	pt_num;
output reg	[9:0]	in_x;
output reg	[9:0]	in_y;

input				out_valid;
input		[9:0]	out_x;
input		[9:0]	out_y;
input		[6:0]	drop_num;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency,latency;
real CYCLE = `CYCLE_TIME;
integer f_in;
integer i;
integer total_patnum,ret_val,i_pat,i_tetro;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [9:0] golden_out_x [0:127];
reg [9:0] golden_out_y [0:127];
reg [6:0] golden_drop_num;
reg [9:0] calu_in_x [0:499];
reg [9:0] calu_in_y [0:499];
reg [8:0] calu_pt_num;
reg out_valid_d;
reg [9:0] Hull_x [0:127] ; 
reg [9:0] Hull_y [0:127] ;
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
always #(CYCLE/2.0) clk = ~clk;
//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
reg out_valid_d;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid_d <= 0;
    else
        out_valid_d <= out_valid;
end

always @(negedge clk) begin
    if (out_valid===0 && (out_x!==0 || out_y!==0 || drop_num!==0)) begin
        $display("**************************************************");
        $display("                    SPEC-5 FAIL                   ");
        $display("**************************************************");
        // repeat (2) @(negedge clk);
		$finish;            
    end 
    else if (out_valid===1 && drop_num===0 && (out_x!==0 || out_y!==0 )) begin
        $display("**************************************************");
        $display("                    SPEC-5 FAIL                   ");
        $display("**************************************************");
        // repeat (2) @(negedge clk);
		$finish;  
    end
end

always @(*) begin
    if (in_valid===1 && out_valid===1) begin
        $display("************************************************************");  
        $display("                        SPEC-6 FAIL                          ");    
        $display("*  The out_valid signal cannot overlap with in_valid.      *");
        $display("************************************************************");
        // repeat (2) @(negedge clk);
        $finish;            
    end    
end

initial begin
    // Open input files
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    f_in  = $fopen("../00_TESTBED/input.txt", "r");
    // f_in  = $fopen("../00_TESTBED/input_1.txt", "r");
    if (f_in == 0) begin
        $finish;
    end

	ret_val = $fscanf(f_in, "%d", total_patnum);
	reset_task;
	for (i_pat = 0; i_pat < total_patnum; i_pat = i_pat + 1) begin
        reset_array;
		ret_val = $fscanf(f_in, "%d", calu_pt_num);

        for (i_tetro = 0; i_tetro < calu_pt_num; i_tetro = i_tetro + 1) begin  
            ret_val = $fscanf(f_in, "%d %d", calu_in_x[i_tetro], calu_in_y[i_tetro]);
        end

        for (i_tetro = 0; i_tetro < calu_pt_num; i_tetro = i_tetro + 1) begin  
            input_task(i_tetro);
			golden_calculate(i_tetro);
			wait_out_valid_task;
			check_ans_task;
            // if(i_tetro == 11 ) begin
                $display("-------------------");
                $display("PASS Point NO.%4d, Point Cycle: %3d , Hullnumber : %3d", i_tetro, latency,Hull_size);
            // end
        end

	end
	$fclose(f_in);
    YOU_PASS_task;
end 


function signed [23:0] cross_product_hw;
    input [9:0] ax, ay, bx, by, cx, cy; //input is c     // end is b      //start is a 
    reg signed [11:0] ux, uy, vx, vy;  // Extended to handle subtraction
    reg signed [23:0] term1, term2;    // Extended to handle multiplication
begin
    ux = bx - ax;
    uy = by - ay; 
    vx = cx - ax;
    vy = cy - ay;
    term1 = ux * vy;
    term2 = uy * vx;
    cross_product_hw = term1 - term2;
end
endfunction

// reg signed [23:0] in_cross [0:127];

integer new_x, new_y;
integer left_idx, right_idx;
integer j, next, cross_val;
integer Hull_size;

reg found_negative;
integer temp_left, temp_right;
integer new_hull_size,neg_count;

task update_hull(input integer new_idx);
    integer new_hull_x[0:127], new_hull_y[0:127];
    integer i;
    reg new_point_inserted;
    reg found_negative;
    integer temp_left, temp_right;
    integer next_next ;
    integer next_cross ;
    reg found_collinear;
    integer collinear_edge_start, collinear_edge_end;
    integer dist_new, dist_old;
begin
    new_x = calu_in_x[new_idx];
    new_y = calu_in_y[new_idx];
    left_idx  = -1;
    right_idx = -1;
    golden_drop_num = 0;
    found_collinear = 0;
        
        found_negative = 0;
        temp_left = -1;
        temp_right = -1;

        for(j=0; j<Hull_size; j=j+1) begin
            next = (j+1) % Hull_size;
            cross_val = cross_product_hw(Hull_x[j], Hull_y[j],
                                        Hull_x[next], Hull_y[next],
                                        new_x, new_y);
            if(cross_val <= 0) begin
                if(!found_negative) begin
                    temp_left = j;
                    found_negative = 1;
                end
                next_next = (next + 1) % Hull_size;
                next_cross = cross_product_hw(Hull_x[next], Hull_y[next],
                                                    Hull_x[next_next], Hull_y[next_next],
                                                    new_x, new_y);
                
                if(next_cross >= 0) begin
                    temp_right = next;  
                end
            end
        end
        
        if(found_negative) begin
            next = (temp_left + Hull_size - 1) % Hull_size; 
            cross_val = cross_product_hw(Hull_x[next], Hull_y[next],
                                        Hull_x[temp_left], Hull_y[temp_left],
                                        new_x, new_y);
            
            while(cross_val < 0) begin
                temp_left = next;
                next = (temp_left + Hull_size - 1) % Hull_size;
                if(next == temp_right) break;  
                cross_val = cross_product_hw(Hull_x[next], Hull_y[next],
                                            Hull_x[temp_left], Hull_y[temp_left],
                                            new_x, new_y);
            end
            
            left_idx = temp_left;
            right_idx = temp_right;
        end else begin
            left_idx = -1;
            right_idx = -1;
        end

        new_hull_size = 0;
        new_point_inserted = 0;
        
        for(i = 0; i < Hull_size; i = i + 1) begin
            if(is_in_drop_range(i, left_idx, right_idx, Hull_size)) begin
                golden_out_x[golden_drop_num] = Hull_x[i];
                golden_out_y[golden_drop_num] = Hull_y[i];
                golden_drop_num = golden_drop_num + 1;
            end
            else if(i == left_idx) begin
                new_hull_x[new_hull_size] = Hull_x[i];
                new_hull_y[new_hull_size] = Hull_y[i];
                new_hull_size = new_hull_size + 1;
                
                new_hull_x[new_hull_size] = new_x;
                new_hull_y[new_hull_size] = new_y;
                new_hull_size = new_hull_size + 1;
                new_point_inserted = 1;
            end
            else begin
                new_hull_x[new_hull_size] = Hull_x[i];
                new_hull_y[new_hull_size] = Hull_y[i];
                new_hull_size = new_hull_size + 1;
            end
        end
        
        Hull_size = new_hull_size;
        for(i = 0; i < Hull_size; i = i + 1) begin
            Hull_x[i] = new_hull_x[i];
            Hull_y[i] = new_hull_y[i];
        end
        for(i=Hull_size ; i <128 ; i =i +1) begin
            Hull_x[i] = 0;
            Hull_y[i] = 0;
        end

end
endtask

function is_in_drop_range;
    input integer idx, left, right, total_size;
begin
        if(right > left) begin
            is_in_drop_range = (idx > left && idx < right);
        end else begin
            is_in_drop_range = (idx > left || idx < right);
        end
end
endfunction

integer j, next, cross_val, sign_pos, sign_neg;
reg will_cause_collinear;
integer zero_count;
task golden_calculate(input integer index);
    integer negative_edge_idx;
    integer new_hull_x[0:127], new_hull_y[0:127];
    integer new_hull_size;
    integer i;
    integer collinear_check_cross;
    integer dist_new_to_start, dist_end_to_start, dist_new_to_end;
    reg has_collinear;
    integer collinear_edge_start, collinear_edge_end;
    
    integer check_edge_start, check_edge_end;
    integer cross_product_012;
    integer temp_x, temp_y;
    
    integer first_zero_idx, second_zero_idx;
    integer neg_start, neg_end;
    reg found_first_zero;
    reg new_point_inserted;
    integer zero_edge_start[0:1], zero_edge_end[0:1];
    integer zero_idx;
    integer intersection_point;
    integer intersection_1 ;
    integer intersection_2;
begin
    if(index==0 || index==1 || index==2) begin
        Hull_x[index] = calu_in_x[index];
        Hull_y[index] = calu_in_y[index];
        Hull_size = index + 1;
        golden_drop_num = 0;
        for(j=0; j<128; j=j+1) begin
            golden_out_x[j] = 0;
            golden_out_y[j] = 0;
        end
        if(index == 2) begin
            cross_product_012 = cross_product_hw(
                Hull_x[0], Hull_y[0],   
                Hull_x[1], Hull_y[1],    
                Hull_x[2], Hull_y[2]   
            );
            
            if(cross_product_012 < 0) begin
                temp_x = Hull_x[1];
                temp_y = Hull_y[1];
                Hull_x[1] = Hull_x[2];
                Hull_y[1] = Hull_y[2];
                Hull_x[2] = temp_x;
                Hull_y[2] = temp_y;
            end 
        end
    end
    else begin
        will_cause_collinear = 0 ;
        for(j=0; j<128; j=j+1) begin
            golden_out_x[j] = 0;
            golden_out_y[j] = 0;
        end
        sign_pos = 0;
        sign_neg = 0;
        neg_count = 0;
        zero_count=0;
        negative_edge_idx = -1;
        has_collinear = 0;
        zero_idx = 0;
        
        for(j=0; j<Hull_size; j=j+1) begin
            next = (j+1) % Hull_size;
            cross_val = cross_product_hw(
                            Hull_x[j], Hull_y[j],
                            Hull_x[next], Hull_y[next],
                            calu_in_x[index], calu_in_y[index]
                        );
            
            if(cross_val == 0) begin
                zero_count = zero_count + 1 ;
                has_collinear = 1;
                zero_edge_start[zero_idx] = j;
                zero_edge_end[zero_idx] = next;
                zero_idx = zero_idx + 1;
            end else if(cross_val < 0) begin
                neg_count = neg_count + 1;
                if(negative_edge_idx == -1) begin
                    negative_edge_idx = j;
                end
            end
            
            if(cross_val > 0) sign_pos = 1;
            else if(cross_val < 0) sign_neg = 1;
        end

        if((sign_pos && sign_neg)==0) begin
            if(sign_pos && !sign_neg) begin
                golden_drop_num = 1;
                golden_out_x[0] = calu_in_x[index];
                golden_out_y[0] = calu_in_y[index];
            end
        end
        else begin 
            if(neg_count == 1 && zero_count == 1) begin
                neg_start = negative_edge_idx;
                neg_end = (negative_edge_idx + 1) % Hull_size;

                if(zero_edge_start[0] == neg_start || zero_edge_start[0] == neg_end) begin
                    intersection_point = zero_edge_start[0];
                end else if(zero_edge_end[0] == neg_start || zero_edge_end[0] == neg_end) begin
                    intersection_point = zero_edge_end[0];
                end else begin
                    intersection_point = -1; 
                end
                
                if(intersection_point != -1) begin
                    new_hull_size = 0;
                    golden_drop_num = 1;
                    golden_out_x[0] = Hull_x[intersection_point];
                    golden_out_y[0] = Hull_y[intersection_point];
                    
                    for(i = 0; i < Hull_size; i = i + 1) begin
                        if(i == intersection_point) begin
                            new_hull_x[new_hull_size] = calu_in_x[index];
                            new_hull_y[new_hull_size] = calu_in_y[index];
                            new_hull_size = new_hull_size + 1;
                        end else begin
                            new_hull_x[new_hull_size] = Hull_x[i];
                            new_hull_y[new_hull_size] = Hull_y[i];
                            new_hull_size = new_hull_size + 1;
                        end
                    end
                    
                    Hull_size = new_hull_size;
                    for(i = 0; i < Hull_size; i = i + 1) begin
                        Hull_x[i] = new_hull_x[i];
                        Hull_y[i] = new_hull_y[i];
                    end
                    
                    for(i = Hull_size; i < 128; i = i + 1) begin
                        Hull_x[i] = 0;
                        Hull_y[i] = 0;
                    end
                end
            end
            else if(neg_count == 1 && zero_count == 2) begin

                neg_start = negative_edge_idx;
                neg_end = (negative_edge_idx + 1) % Hull_size;
                
                intersection_1 = -1;
                intersection_2 = -1;
                
                if(zero_edge_start[0] == neg_start || zero_edge_start[0] == neg_end) begin
                    if(intersection_1 == -1) intersection_1 = zero_edge_start[0];
                    else intersection_2 = zero_edge_start[0];
                end
                if(zero_edge_end[0] == neg_start || zero_edge_end[0] == neg_end) begin
                    if(intersection_1 == -1) intersection_1 = zero_edge_end[0];
                    else intersection_2 = zero_edge_end[0];
                end
                
                if(zero_edge_start[1] == neg_start || zero_edge_start[1] == neg_end) begin
                    if(intersection_1 == -1) intersection_1 = zero_edge_start[1];
                    else intersection_2 = zero_edge_start[1];
                end
                if(zero_edge_end[1] == neg_start || zero_edge_end[1] == neg_end) begin
                    if(intersection_1 == -1) intersection_1 = zero_edge_end[1];
                    else intersection_2 = zero_edge_end[1];
                end
                
                if(intersection_1 != -1 && intersection_2 != -1) begin
                    new_hull_size = 0;
                    golden_drop_num = 2;
                    golden_out_x[0] = Hull_x[intersection_1];
                    golden_out_y[0] = Hull_y[intersection_1];
                    golden_out_x[1] = Hull_x[intersection_2];
                    golden_out_y[1] = Hull_y[intersection_2];
                    
                    new_point_inserted = 0;
                    for(i = 0; i < Hull_size; i = i + 1) begin
                        if(i == intersection_1 || i == intersection_2) begin
                            if(!new_point_inserted) begin
                                new_hull_x[new_hull_size] = calu_in_x[index];
                                new_hull_y[new_hull_size] = calu_in_y[index];
                                new_hull_size = new_hull_size + 1;
                                new_point_inserted = 1;
                            end
                        end else begin
                            new_hull_x[new_hull_size] = Hull_x[i];
                            new_hull_y[new_hull_size] = Hull_y[i];
                            new_hull_size = new_hull_size + 1;
                        end
                    end
                    
                    Hull_size = new_hull_size;
                    for(i = 0; i < Hull_size; i = i + 1) begin
                        Hull_x[i] = new_hull_x[i];
                        Hull_y[i] = new_hull_y[i];
                    end

                    for(i = Hull_size; i < 128; i = i + 1) begin
                        Hull_x[i] = 0;
                        Hull_y[i] = 0;
                    end
                end
            end
            else begin
                update_hull(index);
            end
        end
    end
end
endtask

task reset_array;
    begin
        will_cause_collinear = 0;
        neg_count = 0 ;
        calu_pt_num = 0 ; 
		golden_drop_num 	= 0;
        left_idx = -1;
        right_idx = -1;
        new_hull_size =0;
        for (i = 0 ; i <128 ; i = i+1) begin
            golden_out_x[i] = 0 ;
            golden_out_y[i] = 0 ; 
            Hull_x[i] =0;
            Hull_y[i] =0;
        end
        for (i = 0 ; i <500 ; i = i+1) begin
            calu_in_x[i] = 0 ;
            calu_in_y[i] = 0 ; 
		end
    end
endtask

task reset_task; begin 
    rst_n 		= 1'b1;
    in_valid 	= 1'b0;
    pt_num      = 9'bxxxxxxxxx;
    in_x 	    = 10'bxxxxxxxxxx;
	in_y 	    = 10'bxxxxxxxxxx;

    force clk = 0;
	
    #CYCLE; rst_n = 1'b0; 
    #CYCLE; rst_n = 1'b1;
	#(100-CYCLE); 
	if (out_valid !== 1'b0 || out_x !== 0 || out_y !== 0 || drop_num !== 0) begin
        $display("************************************************************"); 
        $display("                    SPEC-4 FAIL                   ");
        $display("************************************************************"); 
        $finish;
    end
    #CYCLE; release clk;
end endtask

integer random_1to4;
task input_task(input integer index); 
begin
    random_1to4 = 1 + {$random} % 4;
    repeat (random_1to4) @(negedge clk);
	in_valid 		= 1'b1;
    if(index == 0) pt_num = calu_pt_num;
    else pt_num =9'bxxxxxxxxx ; 
    in_x = calu_in_x [index] ; 
    in_y = calu_in_y [index] ;

	@(negedge clk);
    in_valid 	= 1'b0;
    pt_num      = 9'bxxxxxxxxx;
    in_x 	    = 10'bxxxxxxxxxx;
	in_y 	    = 10'bxxxxxxxxxx;
end endtask


reg latency_count_en;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)              latency_count_en = 0;
	else if(in_valid)       latency_count_en = 1;
	else if(out_valid_d && !out_valid)      latency_count_en = 0;
end

always @(posedge clk) begin
	if(!rst_n) latency = 0;
	else if(latency_count_en) latency = latency + 1;
	else latency = 0;
end

task wait_out_valid_task; begin
    while (out_valid !== 1'b1) begin
        if (latency == 999) begin
            $display("************************************************************");  
			$display("                        SPEC-7 FAIL                         ");
            $display("************************************************************");    
            // repeat (2) @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask


task check_ans_task;
    reg [9:0] received_x [0:127];
    reg [9:0] received_y [0:127];
    integer received_count;
    reg [0:127] golden_matched, received_matched;
    integer matches_found;
begin
    if (out_valid === 1) begin
        if (drop_num !== golden_drop_num) begin
            $display("************************************************************");
            $display("                    SPEC-8 FAIL (drop_num mismatch)");
            $display("************************************************************");  
            $display(" Expected: dropnum = %d", golden_drop_num);
            $display(" Received: dropnum = %d", drop_num);
            $display("************************************************************");
            // repeat (2) @(negedge clk);
            $finish;
        end

        received_count = 0;
        while (received_count < golden_drop_num && out_valid) begin
            received_x[received_count] = out_x;
            received_y[received_count] = out_y;
            received_count = received_count + 1;
            
            if (received_count < golden_drop_num) begin
                @(negedge clk);
                if (out_valid !== 1) begin
                    $display("************************************************************");
                    $display("                    SPEC-9 FAIL  (gap detected)");
                    $display("************************************************************");  
                    // repeat (2) @(negedge clk);
                    $finish;
                end
            end
        end

        for (i = 0; i < 128; i = i + 1) begin
            golden_matched[i] = 0;
            received_matched[i] = 0;
        end
        
        matches_found = 0;
        for (i = 0; i < received_count; i = i + 1) begin
            for (j = 0; j < golden_drop_num; j = j + 1) begin
                if (!golden_matched[j] && !received_matched[i] &&
                    received_x[i] === golden_out_x[j] && 
                    received_y[i] === golden_out_y[j]) begin
                    golden_matched[j] = 1;
                    received_matched[i] = 1;
                    matches_found = matches_found + 1;
                    break;
                end
            end
        end
        
        if (matches_found !== golden_drop_num) begin
            $display("************************************************************");
            $display("                    SPEC-8 FAIL (mismatch)");
            $display("************************************************************");  
            $display(" Expected %d points, matched %d points", golden_drop_num, matches_found);
            
            $display(" Expected points:");
            for (i = 0; i < golden_drop_num; i = i + 1) begin
                $display("   (%d, %d) %s", golden_out_x[i], golden_out_y[i], 
                        golden_matched[i] ? "✓" : "✗");
            end
            
            $display(" Received points:");
            for (i = 0; i < received_count; i = i + 1) begin
                $display("   (%d, %d) %s", received_x[i], received_y[i], 
                        received_matched[i] ? "✓" : "✗");
            end
            $display("************************************************************");
            // repeat (3) @(negedge clk);
            $finish;
        end
        
    end
end 
endtask

task YOU_PASS_task; begin
    
    $display("----------------------------------------------------------------------------------------------------------------------");
    $display("                                                  \033[0;32mCongratulations!\033[m                                                    ");
    $display("----------------------------------------------------------------------------------------------------------------------");
    // repeat (2) @(negedge clk);
    $finish;
end endtask

endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// $display("                    SPEC-9 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);