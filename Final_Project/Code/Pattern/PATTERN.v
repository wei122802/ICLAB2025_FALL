`ifdef RTL
    `define CYCLE_TIME 11.1
`endif
`ifdef GATE
    `define CYCLE_TIME 11.1
`endif
`ifdef POST
    `define CYCLE_TIME 11.4
`endif

// `ifndef CYCLE_TIME
//     `define CYCLE_TIME 11.1
// `endif

`define SEED_NUMBER 1228

`define PAT_NUM 100

`define DISPALY 0
// Color Definitions
`define COLOR_RED    "\033[1;31m"
`define COLOR_GREEN  "\033[1;32m"
`define COLOR_BLUE   "\033[1;34m"
`define COLOR_YELLOW "\033[1;33m"
`define COLOR_CYAN   "\033[1;36m"
`define COLOR_RESET  "\033[0m"

module PATTERN(
    clk,
    rst_n,
    in_valid,
    in_valid2,
    in_data,
    out_valid,
    out_sad
);
output reg clk, rst_n, in_valid, in_valid2;
output reg [8:0] in_data;
input out_valid;
input out_sad;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;

// [Fix 1] Initialize clk to 0 so it can toggle properly
initial clk = 0; 
always  #(CYCLE/2.0) clk = ~clk; //clock

// ========================================
// integer & parameter
// ========================================
parameter PAT_NUM = `PAT_NUM;
parameter TOTAL_MV_SETS = 64;

integer total_latency, i, wait_val_time;
integer in_L0_read, in_L1_read, in_MV_read, out_read;
integer in_temp_val;
integer patcount, testcnt;
integer SEED = `SEED_NUMBER;

// ========================================
// wire & reg
// ========================================
reg [55:0] golden_ans;
reg [7:0]  img_pixel_temp;
reg [8:0]  mv_temp; // MV data can use up to 9 bits

reg [55:0] your_ans_reg;
reg [23:0] gold_p1_satd;
reg [3:0]  gold_p1_idx;
reg [23:0] gold_p2_satd;
reg [3:0]  gold_p2_idx;
reg [128*8-1:0] file_path_L0;
reg [128*8-1:0] file_path_L1;
reg [128*8-1:0] file_path_MV;
reg [128*8-1:0] file_path_out;
//================================================================
// design
//================================================================
initial begin
    file_path_L0 = $sformatf("../00_TESTBED/data/%0d/L0.txt", `PAT_NUM);
    file_path_L1 = $sformatf("../00_TESTBED/data/%0d/L1.txt", `PAT_NUM);
    file_path_MV = $sformatf("../00_TESTBED/data/%0d/MV.txt", `PAT_NUM);
    file_path_out = $sformatf("../00_TESTBED/data/%0d/output_golden.txt", `PAT_NUM);
    // Open Files (Matches Python Generator)
    in_L0_read = $fopen(file_path_L0, "r");
    in_L1_read = $fopen(file_path_L1, "r");
    in_MV_read = $fopen(file_path_MV, "r");
    out_read   = $fopen(file_path_out, "r"); 

    // Check file open status
    if(in_L0_read == 0 || in_L1_read == 0 || in_MV_read == 0 || out_read == 0) begin
        $display("%0sError: Input files not found. Please run Python generator first.%0s", `COLOR_RED, `COLOR_RESET);
        $finish;
    end

    // Initial Signals
    rst_n = 1'b1;
    in_valid = 1'b0;
    in_valid2 = 1'b0;
    in_data = 9'dx; 
    
    // [Fix 1] Ensure force logic works with initialized clock
    force clk = 0; 
    
    total_latency = 0;

    // System Reset
    reset_signal_task;

    // Pattern Loop
    for(patcount = 0; patcount < PAT_NUM; patcount = patcount + 1) begin
        if(`DISPALY == 1)
            $display( "%0s Starting Pattern %0d / %0d %0s" ,`COLOR_BLUE, patcount, PAT_NUM-1,`COLOR_RESET);

        // 1. Send Image Data (L0 + L1)
        input_image_task;

        // 2. Send 64 Sets of MV & Check Output
        for(testcnt = 0; testcnt < TOTAL_MV_SETS; testcnt = testcnt + 1) begin
            input_mv_task;
            wait_out_valid;
            check_ans;
        end
        $display("%0sPASS PATTERN NO.%4d%0s", `COLOR_GREEN, patcount, `COLOR_RESET);
    end 
    
    display_pass;
    repeat(3) @(negedge clk);
    $finish;
end

//======================================
//              TASKS
//======================================

// --- Reset Task ---
task reset_signal_task; 
begin 
    #(CYCLE); rst_n = 0;
    #(CYCLE*5);
    
    // Check reset behavior
    if((out_valid !== 0) || (out_sad !== 0)) begin
        display_fail;
        $display("------------------------------------------------------------");
        $display("                    Reset FAIL                              ");
        $display(" Output signals should be 0 after reset asserted.           ");
        $display("------------------------------------------------------------");
        $finish;
    end
    
    #(CYCLE); rst_n = 1;
    #(CYCLE); release clk; // Release force
end 
endtask

// --- Input Image Task (L0 then L1) ---
task input_image_task; 
begin   
    // Random wait before in_valid
    repeat(({$random(SEED)} % 3 + 3)) @(negedge clk);

    in_valid = 1'b1;
    
    // Send L0 (128x128 = 16384 pixels)
    for(i=0; i<16384; i=i+1) begin
        // [Fix 2] Check if Output is 0 during in_valid high
        if(out_valid !== 0 || out_sad !== 0) begin
            display_fail; 
            $display("------------------------------------------------------------");
            $display("Error: out_valid or out_sad went high while in_valid is HIGH (L0 loading)!"); 
            $display("------------------------------------------------------------");
            $finish; 
        end
        
        in_temp_val = $fscanf(in_L0_read, "%d", img_pixel_temp);
        // SPEC: in_data[8:1] is image data, in_data[0] is don't care
        in_data = {img_pixel_temp, 1'bx}; 
        @(negedge clk);
    end

    // Send L1 (128x128 = 16384 pixels)
    for(i=0; i<16384; i=i+1) begin
        // [Fix 2] Check if Output is 0 during in_valid high
        if(out_valid !== 0 || out_sad !== 0) begin
            display_fail; 
            $display("------------------------------------------------------------");
            $display("Error: out_valid or out_sad went high while in_valid is HIGH (L1 loading)!"); 
            $display("------------------------------------------------------------");
            $finish; 
        end

        in_temp_val = $fscanf(in_L1_read, "%d", img_pixel_temp);
        // SPEC: in_data[8:1] is image data
        in_data = {img_pixel_temp, 1'bx}; 
        @(negedge clk);
    end

    // End Input
    in_valid = 1'b0;
    in_data = 9'dx;
end 
endtask

// --- Input MV Task ---
task input_mv_task; 
begin   
    // Wait random cycles (3~6 cycles after in_valid falls or out_valid falls)
    repeat(({$random(SEED)} % 4 + 3)) @(negedge clk);

    in_valid2 = 1'b1;
    
    // Send 8 MV bytes (Standard Table 2 sequence)
    for(i=0; i<8; i=i+1) begin
        // [Fix 2] Check if Output is 0 during in_valid2 high
        if(out_valid !== 0 || out_sad !== 0) begin
            display_fail;
            $display("Error: out_valid or out_sad went high while in_valid2 is HIGH (MV input)!");
            $finish;
        end
        
        in_temp_val = $fscanf(in_MV_read, "%h", mv_temp); 
        in_data = mv_temp; 
        @(negedge clk);
    end

    // End MV Input
    in_valid2 = 1'b0;
    in_data = 9'dx;
end 
endtask

// --- Wait Output Task ---
task wait_out_valid; 
begin
    wait_val_time = 0;
    while(out_valid !== 1) begin
        if(out_sad !== 0) begin
            display_fail;
            $display("Error: out_sad is high but out_valid is low!");
            $finish;
        end
        
        wait_val_time = wait_val_time + 1;
        
        // Latency Limit Check (SPEC: 1000 cycles)
        if(wait_val_time > 1000) begin
            display_fail;
            $display("Error: Execution latency exceeded 1000 cycles!");
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + wait_val_time;
end 
endtask

// --- Check Answer Task ---
task check_ans; 
begin
    // Read Golden Answer (56-bit hex)
    in_temp_val = $fscanf(out_read, "%h", golden_ans);
    
    gold_p1_satd = golden_ans[23:0];
    gold_p1_idx  = golden_ans[27:24];
    gold_p2_satd = golden_ans[51:28];
    gold_p2_idx  = golden_ans[55:52];
    
    your_ans_reg = 0;

    i = 0;
    while(out_valid) begin
        if(i >= 56) begin
            display_fail;
            $display("Error: out_valid is high for more than 56 cycles!");
            $finish;
        end
        your_ans_reg[i] = out_sad;
        // Serial Check (Bit by Bit, from LSB)
        if(out_sad !== golden_ans[i]) begin // Checking ith bit
            display_fail;
            $display("%0s---------------- DEBUG INFO ----------------%0s", `COLOR_YELLOW, `COLOR_RESET);
            $display(" Pattern: %0d, MV Set: %0d", patcount, testcnt);
            $display(" Failed at Bit Index: %0d", i);
            
            // Smart Error Analysis
            if(i < 24) begin
                $display("%0s  [Error Location]: Point 1 SATD Value%0s", `COLOR_RED, `COLOR_RESET);
                $display("  Expected P1 SATD : %d (Hex: %6h)", gold_p1_satd, gold_p1_satd);
            end else if(i < 28) begin
                $display("%0s  [Error Location]: Point 1 Search Index%0s", `COLOR_RED, `COLOR_RESET);
                $display("  Expected P1 IDX  : %d (Hex: %1h)", gold_p1_idx, gold_p1_idx);
            end else if(i < 52) begin
                $display("%0s  [Error Location]: Point 2 SATD Value%0s", `COLOR_RED, `COLOR_RESET);
                $display("  Expected P2 SATD : %d (Hex: %6h)", gold_p2_satd, gold_p2_satd);
            end else begin
                $display("%0s  [Error Location]: Point 2 Search Index%0s", `COLOR_RED, `COLOR_RESET);
                $display("  Expected P2 IDX  : %d (Hex: %1h)", gold_p2_idx, gold_p2_idx);
            end

            $display("--------------------------------------------");
            $display("  Expected Bit     : %b", golden_ans[i]);
            $display("  Your Output Bit  : %b", out_sad);
            $display("--------------------------------------------");
            $display("  Full Golden Hex  : %h", golden_ans);
            $display("  Your Output So Far: %h (LSB First)", your_ans_reg);
            
            repeat(2) @(negedge clk);
            $finish;
        end
        
        @(negedge clk);
        i = i + 1;
    end 
    
    // [Fix] Display latency after each set
    if(`DISPALY == 1)
        $display("%0s Set PASS: %2d  |  Latency: %3d cycles %0s", `COLOR_GREEN, testcnt, wait_val_time, `COLOR_RESET );
    
    if(i < 56) begin
        display_fail;
        $display("Error: out_valid duration too short! (Expected 56, Got %0d)", i);
        $finish;
    end
end 
endtask

// --- Display Tasks ---
task display_fail; begin
    wei_mark;
    $display("\033[31m  /============================================\\ \033[0m");
    $display("\033[31m  |                FAIL :(                     | \033[0m");
    $display("\033[31m  \\============================================/ \033[0m");
end endtask

task display_pass; begin
    // [Fix] Calculate Average Latency
    // Total sets = PAT_NUM * 64
    real avg_latency;
    avg_latency = total_latency / (PAT_NUM * 64.0);

    wei_mark;
    $display("\033[32m  /============================================\\ \033[0m");
    $display("\033[32m  |  Congratulations! All Patterns Passed! :)  | \033[0m");
    $display("\033[32m  \\============================================/ \033[0m");
    $display("\033[33m  Total Execution Latency  : %d cycles \033[0m", total_latency);
    $display("\033[33m  Average Execution Latency:    %f cycles \033[0m", avg_latency);
    $display("\n");
end endtask

task wei_mark; begin
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
end endtask

endmodule