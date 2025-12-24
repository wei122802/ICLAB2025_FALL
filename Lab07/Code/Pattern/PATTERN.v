`timescale 1ns/1ps

module PATTERN #(
    parameter CYCLE_CLK1 = 14.1,
    parameter CYCLE_CLK2 = 10.1,
    parameter CYCLE_CLK3 = 20.7
)(
    output reg clk1,
    output reg clk2,
    output reg clk3,
    output reg rst_n,
    output reg in_valid,
    output reg [31:0] in_data,
    input out_valid,
    input [15:0] out_data
);

// Parameters
parameter PATTERN_NUM = 256;
parameter INPUT_CYCLE = 16;
parameter OUTPUT_CYCLE = 128;

// File handles
integer input_file;
integer output_file;
integer scan_result;

// Current pattern buffers (only store one pattern at a time)
reg [31:0] current_input [0:INPUT_CYCLE-1];
reg [15:0] current_output [0:OUTPUT_CYCLE-1];

// Counters
integer pat_cnt;
integer input_cnt;
integer output_cnt;
integer total_latency;
integer current_latency;
integer clk3_cnt;

// Control signals
reg start_check;

// Clock generation
initial clk1 = 0;
always #(CYCLE_CLK1/2) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE_CLK2/2) clk2 = ~clk2;

initial clk3 = 0;
always #(CYCLE_CLK3/2) clk3 = ~clk3;

// Main test procedure
initial begin
    // Initialize signals
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    rst_n = 1;
    in_valid = 0;
    in_data = 0;
    start_check = 0;
    pat_cnt = 0;
    total_latency = 0;
    clk3_cnt = 0;
    
    // Open files
    input_file = $fopen("../00_TESTBED/input.txt", "r");
    output_file = $fopen("../00_TESTBED/output.txt", "r");
    
    if (input_file == 0) begin
        $display("========================================");
        $display("  ERROR: Cannot open input.txt");
        $display("========================================");
        $finish;
    end
    
    if (output_file == 0) begin
        $display("========================================");
        $display("  ERROR: Cannot open output.txt");
        $display("========================================");
        $finish;
    end
    
    $display("========================================");
    $display("  Files loaded successfully!");
    $display("========================================");
    
    // Reset sequence
    reset_task;
    
    // Start patterns
    for (pat_cnt = 0; pat_cnt < PATTERN_NUM; pat_cnt = pat_cnt + 1) begin
        // Load one pattern's data
        load_pattern_task;
        
        // Execute test
        input_task;
        wait_output_task;
        check_idle_task;
        
        $display("PASS Pattern %0d", pat_cnt);
    end
    
    // Close files
    $fclose(input_file);
    $fclose(output_file);
    
    // Calculate average latency
    $display("========================================");
    $display("  Average Latency: %0d cycles (clk3)", total_latency / PATTERN_NUM);
    $display("========================================");
    $display("  Congratulations! All patterns PASS!");
    $display("========================================");
    
    repeat(3) @(negedge clk1);
    $finish;
end

// CLK3 counter for latency measurement
always @(posedge clk3) begin
    if (!rst_n)
        clk3_cnt <= 0;
    else
        clk3_cnt <= clk3_cnt + 1;
end

// Load one pattern's data from files
task load_pattern_task;
    integer i;
begin
    // Load input data (16 lines)
    for (i = 0; i < INPUT_CYCLE; i = i + 1) begin
        scan_result = $fscanf(input_file, "%h\n", current_input[i]);
        if (scan_result != 1) begin
            $display("========================================");
            $display("  ERROR: Failed to read input.txt at pattern %0d, line %0d", pat_cnt, i);
            $display("========================================");
            $finish;
        end
    end
    
    // Load output data (128 lines)
    for (i = 0; i < OUTPUT_CYCLE; i = i + 1) begin
        scan_result = $fscanf(output_file, "%h\n", current_output[i]);
        if (scan_result != 1) begin
            $display("========================================");
            $display("  ERROR: Failed to read output.txt at pattern %0d, line %0d", pat_cnt, i);
            $display("========================================");
            $finish;
        end
    end
end endtask

// Reset task
task reset_task; begin
    #1; rst_n = 0;
    #(CYCLE_CLK1 * 2);
    
    // Check reset state
    if (out_valid !== 0 || out_data !== 0) begin
        $display("========================================");
        $display("  Output signals are not reset!");
        $display("========================================");
        repeat(2) @(negedge clk1);
        $finish;
    end
    
    #(CYCLE_CLK1 * 2); rst_n = 1;
    #(CYCLE_CLK1 * 2);
end endtask

// Input task
task input_task; begin
    start_check = 0;
    current_latency = clk3_cnt;
    
    @(negedge clk1);
    in_valid = 1;
    
    for (input_cnt = 0; input_cnt < INPUT_CYCLE; input_cnt = input_cnt + 1) begin
        in_data = current_input[input_cnt];
        
        // Check output should be 0 during input
        if (out_valid !== 0 || out_data !== 0) begin
            $display("========================================");
            $display("  Output should be 0 when in_valid=1!");
            $display("  Pattern: %0d", pat_cnt);
            $display("========================================");
            repeat(2) @(negedge clk1);
            $finish;
        end
        
        @(negedge clk1);
    end
    
    in_valid = 0;
    in_data = 0;
    start_check = 1;
end endtask

// Wait and check output task
task wait_output_task;
    integer wait_cnt;
    integer out_cnt;
    integer timeout;
begin
    wait_cnt = 0;
    out_cnt = 0;
    timeout = 5000;
    
    // Wait for first out_valid
    while (out_valid === 0 && wait_cnt < timeout) begin
        @(negedge clk3);
        wait_cnt = wait_cnt + 1;
    end
    
    if (wait_cnt >= timeout) begin
        $display("========================================");
        $display("  Timeout! No output detected.");
        $display("  Pattern: %0d", pat_cnt);
        $display("========================================");
        repeat(2) @(negedge clk1);
        $finish;
    end
    
    // Check outputs
    while (out_cnt < OUTPUT_CYCLE) begin
        @(negedge clk3);
        if (out_valid === 1) begin
            if (out_data !== current_output[out_cnt]) begin
                $display("========================================");
                $display("  Output mismatch!");
                $display("  Pattern: %0d, Output: %0d", pat_cnt, out_cnt);
                $display("  Golden: 0x%h, Your: 0x%h", 
                         current_output[out_cnt], out_data);
                $display("========================================");
                repeat(30) @(negedge clk1);
                $finish;
            end
            out_cnt = out_cnt + 1;
        end
    end
    
    // Calculate latency (including output cycles)
    @(negedge clk3);
    current_latency = clk3_cnt - current_latency;
    total_latency = total_latency + current_latency;
    
    if (current_latency >= 5000) begin
        $display("========================================");
        $display("  Latency exceeds 5000 cycles!");
        $display("  Pattern: %0d, Latency: %0d", pat_cnt, current_latency);
        $display("========================================");
        repeat(2) @(negedge clk1);
        $finish;
    end
    
    $display("Pattern %0d Latency: %0d cycles (clk3)", pat_cnt, current_latency);
end endtask

// Check idle task
task check_idle_task;
    integer idle_cnt;
begin
    idle_cnt = 0;
    
    // Wait 1~3 clk1 cycles before next pattern
    while (idle_cnt < 3) begin
        @(negedge clk1);
        idle_cnt = idle_cnt + 1;
        
        // Check output should be reset after out_valid falls
        if (out_valid === 0 && out_data !== 0) begin
            $display("========================================");
            $display("  out_data should be 0 when out_valid=0!");
            $display("  Pattern: %0d", pat_cnt);
            $display("========================================");
            repeat(2) @(negedge clk1);
            $finish;
        end
    end
end endtask

// Timeout monitor
initial begin
    #(CYCLE_CLK3 * 5000 * PATTERN_NUM * 2);
    $display("========================================");
    $display("  Simulation timeout!");
    $display("========================================");
    $finish;
end

endmodule