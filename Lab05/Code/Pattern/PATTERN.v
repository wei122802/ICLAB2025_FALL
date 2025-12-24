`define CYCLE_TIME  20.0

module PATTERN(
    // output signals
    clk,
    rst_n,
    in_valid_data,
    in_valid_param,
    
    data,
    index,
    mode,
    QP,
    
    // input signals
    out_valid,
    out_value
);

// ========================================
// I/O declaration
// ========================================
// Output
output reg          clk;
output reg          rst_n;
output reg          in_valid_data;
output reg          in_valid_param;

output reg    [7:0] data;
output reg    [3:0] index;
output reg          mode;
output reg    [4:0] QP;

// Input
input               out_valid;
input signed [31:0] out_value;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk; //clock

// ========================================
// integer & parameter
// ========================================
`define SEED_NUMBER     28825252
integer i, j, k, l, m, n, p, r, s;
integer img_txt, mode_txt, index_txt, QP_txt;
integer pat_count;
integer ret;

// ========================================
// wire & reg
// ========================================
real SEED = `SEED_NUMBER;
reg [7:0] data_buffer;
reg [3:0] index_buffer;
reg [4:0] QP_buffer;
reg mode_buffer [0:3];
reg [100:0] comment_line;

//================================================================
// design
//================================================================
initial begin
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    open_file;  
    reset;
    
    // Main test loop
    pat_count = 0;
    
    // Read first pattern (you can add loop here for multiple patterns)
    read_and_send_pattern(pat_count);
    
    repeat (4000) @(negedge clk); // Wait for output
    // send_param(1);
    $finish;
end

task open_file; begin
    img_txt = $fopen("../00_TESTBED/input/input_data.txt", "r");
    mode_txt = $fopen("../00_TESTBED/input/input_para_mode.txt", "r");
    index_txt = $fopen("../00_TESTBED/input/input_para_index.txt", "r");
    QP_txt = $fopen("../00_TESTBED/input/input_para_QP.txt", "r");
    
    if (img_txt == 0 || mode_txt == 0 || index_txt == 0 || QP_txt == 0) begin
        $display("Error: Cannot open input files!");
        $finish;
    end
end endtask

task reset; begin
    force clk = 0;
    rst_n = 1'b1;
    in_valid_data = 1'b0;
    in_valid_param = 1'b0;
    data = 8'bX;
    index = 4'bX;
    mode = 1'bX;
    QP = 5'bX;
    #50;
    rst_n = 0;
    #100;
    rst_n = 1;
    #50;
    release clk;
    repeat (3) @(negedge clk);
end endtask

task read_and_send_pattern; 
    input integer pat_num;
    begin
        $display("========================================");
        $display("Starting Pattern %0d", pat_num);
        $display("========================================");
        
        // Send 16384 data
        send_data;
        
        // Wait 3 cycles
        repeat (3) @(negedge clk);
        
        // Send 16 sets of parameters
        // for (i = 0; i < 16; i = i + 1) begin
            send_param(0);
        // end
        
        $display("Pattern %0d input completed", pat_num);
    end
endtask

task send_data; begin
    // Skip comment line
    ret = $fgets(comment_line, img_txt);
    
    $display("Sending 16384 data cycles...");
    
    for (i = 0; i < 16384; i = i + 1) begin
        
        in_valid_data = 1'b1;
        ret = $fscanf(img_txt, "%d", data_buffer);
        data = data_buffer;
        @(negedge clk);
        if (i % 4096 == 0) begin
            $display("  Data progress: %0d/16384", i);
        end
    end
    
    // @(negedge clk);
    in_valid_data = 1'b0;
    data = 8'bX;
    
    $display("  Data progress: 16384/16384 - Complete!");
end endtask

task send_param;
    input integer param_idx;
    begin
        // Read QP value
        if (param_idx == 0) begin
            ret = $fgets(comment_line, QP_txt); // Skip comment
        end
        ret = $fscanf(QP_txt, "%d", QP_buffer);
        
        // Read index value
        if (param_idx == 0) begin
            ret = $fgets(comment_line, index_txt); // Skip comment
        end
        ret = $fscanf(index_txt, "%d", index_buffer);
        
        // Read 4 mode bits
        if (param_idx == 0) begin
            ret = $fgets(comment_line, mode_txt); // Skip comment
        end
        for (j = 0; j < 4; j = j + 1) begin
            ret = $fscanf(mode_txt, "%d", mode_buffer[j]);
        end
        
        $display("  Param %0d: QP=%0d, Index=%0d, Mode=%b%b%b%b", 
                 param_idx, QP_buffer, index_buffer, 
                 mode_buffer[0], mode_buffer[1], mode_buffer[2], mode_buffer[3]);
        
        // Cycle 1: Send QP, index, and mode[0]
        @(negedge clk);
        in_valid_param = 1'b1;
        QP = QP_buffer;
        index = index_buffer;
        mode = mode_buffer[0];
        
        // Cycle 2: Send mode[1]
        @(negedge clk);
        QP = 5'bX;
        index = 4'bX;
        mode = mode_buffer[1];
        
        // Cycle 3: Send mode[2]
        @(negedge clk);
        mode = mode_buffer[2];
        
        // Cycle 4: Send mode[3]
        @(negedge clk);
        mode = mode_buffer[3];
        
        // Deassert valid signal
        @(negedge clk);
        in_valid_param = 1'b0;
        QP = 5'bX;
        index = 4'bX;
        mode = 1'bX;
    end
endtask

endmodule