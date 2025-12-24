
`define CYCLE_TIME 27

module PATTERN(
    // Output Port
    clk,
    rst_n,
    in_valid,
    Image,
    Kernel_ch1,
    Kernel_ch2,
	Weight_Bias,
    task_number,
    mode,
    capacity_cost,
    // Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg       clk, rst_n, in_valid;
output reg [31:0]  Image;
output reg [31:0]  Kernel_ch1;
output reg [31:0]  Kernel_ch2;
output reg [31:0]  Weight_Bias;
output reg        task_number;
output reg [1:0]   mode;
output reg [3:0]   capacity_cost;

input           out_valid;
input   [31:0]  out;
`define SEED_NUMBER     28825252
//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
integer img_txt, mode_txt, out_txt, kernel_ch1_txt, kernel_ch2_txt, weight_txt ,task_txt,cost_txt;
integer img_txt_scan, mode_txt_scan, out_txt_scan, kernel_ch1_txt_scan, kernel_ch2_txt_scan, weight_txt_scan, task_txt_scan,cost_txt_scan;
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;
integer latency = 0;
integer total_latency = 0;
reg [31:0] s_img, s_kernel_ch1, s_kernel_ch2, s_weight;
reg [1:0]  s_mode;
reg [3:0]  s_cost;
reg        s_task;
reg  [31:0] s_out_arr [2:0];
reg  [31:0] s_ans [2:0];
wire [31:0] maximum_error = 32'b00110101000001100011011110111101; // 0.0001
wire [31:0] s_golden_ans_diff [2:0];
wire [31:0] s_ans_err [2:0];
integer img_txt_id, mode_txt_id, out_txt_id, kernel_ch1_txt_id, kernel_ch2_txt_id, weight_txt_id, task_txt_id,cost_txt_id;
integer i, j, k, l, m, n, p,r,s;
reg all_error_flag = 0;
wire error_flag [2:0];
reg [31:0] random_int;
reg file_error_flag = 0;
real SEED = `SEED_NUMBER;

initial begin
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    open_file;  
    reset;
    while ($feof(img_txt) !=1 && file_error_flag == 0 ) begin
        read_file_id;
        read_and_send;
        if (file_error_flag) begin
            break;
        end
        read_out;
        wait_out;
        check_ans;
        random_int = $random(SEED);
        repeat (random_int[2:0]) @(negedge clk);
    end
    if(!all_error_flag) begin
        
        $display("**************************************************");
        $display("                 ALL PATTERN PASS                 ");
        $display("**************************************************");
        $display("           Total Latency: %d cycles", total_latency);
    end
    $finish(1);
end

task reset; begin
        force clk   = 0;
        rst_n       = 1'b1;
        in_valid    = 1'b0;
        Image       = 32'bX;
        Kernel_ch1  = 32'bX;
        Kernel_ch2  = 32'bX;
        Weight_Bias = 32'bX;
        mode        = 2'bX;
        task_number = 1'bX;
        capacity_cost = 4'bX;
        #50;
        rst_n = 0;
        #100;
        rst_n = 1;
        #50;
        release clk;
        repeat (3) @(negedge clk);
end endtask

task open_file; begin
        img_txt = $fopen("../00_TESTBED/output_test/image.txt", "r");
        mode_txt = $fopen("../00_TESTBED/output_test/mode.txt", "r");
        out_txt = $fopen("../00_TESTBED/output_test/out.txt", "r");
        kernel_ch1_txt = $fopen("../00_TESTBED/output_test/kernel_ch1.txt", "r");
        kernel_ch2_txt = $fopen("../00_TESTBED/output_test/kernel_ch2.txt", "r");
        weight_txt = $fopen("../00_TESTBED/output_test/weight.txt", "r");
        task_txt = $fopen("../00_TESTBED/output_test/task.txt", "r");
        cost_txt = $fopen("../00_TESTBED/output_test/capacity_cost.txt", "r");
    end
endtask

// task open_file; begin
//         img_txt = $fopen("../00_TESTBED/output/image.txt", "r");
//         mode_txt = $fopen("../00_TESTBED/output/mode.txt", "r");
//         out_txt = $fopen("../00_TESTBED/output/out.txt", "r");
//         kernel_ch1_txt = $fopen("../00_TESTBED/output/kernel_ch1.txt", "r");
//         kernel_ch2_txt = $fopen("../00_TESTBED/output/kernel_ch2.txt", "r");
//         weight_txt = $fopen("../00_TESTBED/output/weight.txt", "r");
//         task_txt = $fopen("../00_TESTBED/output/task.txt", "r");
//         cost_txt = $fopen("../00_TESTBED/output/capacity_cost.txt", "r");
//     end
// endtask

task read_file_id; begin
        img_txt_scan = $fscanf(img_txt, "%d", img_txt_id);
        mode_txt_scan = $fscanf(mode_txt, "%d", mode_txt_id);
        out_txt_scan = $fscanf(out_txt, "%d", out_txt_id);
        kernel_ch1_txt_scan = $fscanf(kernel_ch1_txt, "%d", kernel_ch1_txt_id);
        kernel_ch2_txt_scan = $fscanf(kernel_ch2_txt, "%d", kernel_ch2_txt_id);
        weight_txt_scan = $fscanf(weight_txt, "%d", weight_txt_id);
        task_txt_scan = $fscanf(task_txt, "%d", task_txt_id);
        cost_txt_scan = $fscanf(cost_txt, "%d", cost_txt_id);

end
endtask

task read_and_send; begin
        // in_valid = 1'b1;
        fork
            read_and_send_task;
            read_and_send_img;
            read_and_send_kernel_ch1;
            read_and_send_kernel_ch2;
            read_and_send_weight;
            read_and_send_mode;    
            read_and_send_capacity_cost;
        join
        // in_valid = 1'b0;
    end
endtask

task read_and_send_img; begin
    if (s_task == 0) begin
        // Task 0: CNN → 72 筆
        in_valid = 1'b1;
        for (i = 0; i < 72; i = i + 1) begin
            img_txt_scan = $fscanf(img_txt, "%H", s_img);
            assert (img_txt_scan == 1) else begin
                $display("Error: Img File Error");
                file_error_flag = 1;
                return;
            end
            Image = s_img;
            @(negedge clk);
        end
        in_valid = 1'b0;
    end
    else begin
        in_valid = 1'b1;
        // Task 1: Cost → 36 筆
        for (i = 0; i < 36; i = i + 1) begin
            img_txt_scan = $fscanf(img_txt, "%H", s_img);
            assert (img_txt_scan == 1) else begin
                $display("Error: Img File Error");
                file_error_flag = 1;
                return;
            end
            Image = s_img;
            @(negedge clk);
        end
        in_valid = 1'b0;
    end
    Image = 32'bX;
end
endtask

task read_and_send_kernel_ch1; begin
        for (j = 0; j < 18; j = j + 1) begin
            kernel_ch1_txt_scan = $fscanf(kernel_ch1_txt, "%H", s_kernel_ch1);
            Kernel_ch1 = s_kernel_ch1;
            @(negedge clk);
        end
        Kernel_ch1 = 32'bX;
    end
endtask

task read_and_send_kernel_ch2; begin
        for (k = 0; k < 18; k = k + 1) begin
            kernel_ch2_txt_scan = $fscanf(kernel_ch2_txt, "%H", s_kernel_ch2);
            Kernel_ch2 = s_kernel_ch2;
            @(negedge clk);
        end
        Kernel_ch2 = 32'bX;
    end
endtask

task read_and_send_weight; begin
    if (s_task == 0) begin
        // Task 0 要讀 57 筆
        for (l = 0; l < 57; l = l + 1) begin
            weight_txt_scan = $fscanf(weight_txt, "%H", s_weight);
            Weight_Bias = s_weight;
            @(negedge clk);
        end
    end
    else begin
        // Task 1 不用 → 填 X
        // for (l = 0; l < 57; l = l + 1) begin
        weight_txt_scan = $fscanf(weight_txt, "%H", s_weight);
        // $display("%H"   ,s_weight);
        Weight_Bias = 32'bX;
            // @(negedge clk);
        // end
    end
    Weight_Bias = 32'bX;
end
endtask

task read_and_send_mode; begin
        mode_txt_scan = $fscanf(mode_txt, "%d", s_mode);
        mode = s_mode;
        @(negedge clk);
        mode = 2'bX;
    end
endtask

task read_and_send_task; begin
        task_txt_scan = $fscanf(task_txt, "%b", s_task);
        assert (task_txt_scan == 1) else begin
            $display("Error: Task File Error");
            file_error_flag = 1;
            return;
        end
        task_number = s_task;
        @(negedge clk);
        task_number = 1'bX;
    end
endtask

task read_and_send_capacity_cost; begin
    if (s_task == 1) begin
        // Task 1 要讀
        for (p = 0; p < 5; p = p + 1) begin
            cost_txt_scan = $fscanf(cost_txt, "%d", s_cost);
            capacity_cost = s_cost;
            @(negedge clk);
        end
    end
    else begin
        // Task 0 不用 → 填 X
        for (p = 0; p < 5; p = p + 1) begin
            cost_txt_scan = $fscanf(cost_txt, "%d", s_cost);
            capacity_cost = 4'bX;
            @(negedge clk);
        end
    end
    capacity_cost = 4'bX;
end
endtask

task read_out; begin
    if (s_task == 0) begin
        for (n = 0; n < 3; n = n + 1) begin
            out_txt_scan = $fscanf(out_txt, "%H", s_out_arr[n]);
        end
    end
    else 
        out_txt_scan = $fscanf(out_txt, "%H", s_out_arr[0]);
    end
endtask

task wait_out; begin
        latency = 0;
        while (out_valid !== 1'b1) begin
            latency = latency + 1;
            @(negedge clk);
        end
        total_latency = total_latency + latency;
        if (s_task == 0) begin
            for (r = 0; r < 3; r = r + 1) begin
                s_ans[r] = out;
                @(negedge clk);
            end
        end else begin
          s_ans[0] = out;
          @(negedge clk);
        end
    end
endtask

task check_ans; begin
    if(s_task == 0) begin
        if (|{error_flag[0], error_flag[1], error_flag[2]} == 1'b0) begin
            $display("\033[32mPattern %d Pass.\033[0m", img_txt_id);
        end else begin
            $display("\033[31mPattern %d Fail.\033[0m", img_txt_id);
            all_error_flag = 1;
        end
        for (s = 0; s < 3; s = s + 1) begin
            $display("\033[95mClass: %d \033[93mGolden: %H \t \033[96mOutput: %H \t \033[36mDiff: %H \t \033[91mError: %H \033[32mLatency: %d\033[0m", s, s_out_arr[s], s_ans[s], s_golden_ans_diff[s], {1'b0,s_ans_err[s][30:0]}, latency);
        end
        if (|{error_flag[0], error_flag[1], error_flag[2]} == 1'b1) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC2 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("The error is larger than 0.0001 at pattern[%d]", img_txt_id);
            $display("\033[0m");
            $finish(1);
        end
    end
    else begin
        if (s_out_arr[0] == s_ans[0]) begin
            $display("\033[32mPattern %d Pass.\033[0m", img_txt_id);
        end else begin
            $display("\033[31mPattern %d Fail.\033[0m", img_txt_id);
            all_error_flag = 1;
        end
        $display("\033[95mResult:            \033[93mGolden: %H \t \033[96mOutput: %H \t \033[36mDiff: %H \t \033[91mError: %H \033[32mLatency: %d\033[0m", 
                 s_out_arr[0], s_ans[0], s_golden_ans_diff[0], {1'b0,s_ans_err[0][30:0]}, latency);
    end
end
endtask


genvar gr;
    generate for (gr = 0; gr < 3; gr = gr + 1) begin : g10
        DW_fp_sub #(
            .sig_width(inst_sig_width),
            .exp_width(inst_exp_width),
            .ieee_compliance(inst_ieee_compliance)
        ) DW_fp_sub_instance (
            .a(s_out_arr[gr]),
            .b(s_ans[gr]),
            .rnd(3'd0),
            .z(s_golden_ans_diff[gr]),
            .status()
        );
        DW_fp_div #(
            .sig_width(inst_sig_width),
            .exp_width(inst_exp_width),
            .ieee_compliance(inst_ieee_compliance),
            .faithful_round(0)
        ) DW_fp_div_instance (
            .a(s_golden_ans_diff[gr]),
            .b(s_out_arr[gr]),
            .rnd(3'd0),
            .z(s_ans_err[gr]),
            .status()
        );
        DW_fp_cmp #(
            .sig_width(inst_sig_width),
            .exp_width(inst_exp_width),
            .ieee_compliance(inst_ieee_compliance)
        ) DW_fp_cmp_instance (
            .a({1'b0,s_ans_err[gr][30:0]}), // abs
            .b(maximum_error),
            .zctr(),
            .aeqb(),
            .altb(),
            .agtb(error_flag[gr]),
            .unordered(),
            .z0(),
            .z1(),
            .status0(),
            .status1()
        );
    end endgenerate

always @(negedge rst_n) begin #20; spec3_checker; end

task spec3_checker; begin
        if (out !== 32'b0 || out_valid) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC4 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("out and out_valid should be reset to 0 after reset at %d", $time);
            $display("out: %H, out_valid: %b", out, out_valid);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end
endtask

always @(negedge clk) spec5_checker;
    task spec5_checker; begin
        if (out_valid === 1'b0) begin
            if (out !== 32'b0) begin
                $display("\033[31m");
                $display("**************************************************");
                $display("              SPEC5 CHECKER ERROR                 ");
                $display("**************************************************");
                $display("out should be 0 when out_valid is 0 at time %d", $time);
                $display("\033[0m");
                repeat (20) @(negedge clk);
                $finish(1);
            end
        end
    end
endtask

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

always @(negedge clk) spec6_checker;
    task spec6_checker; begin
        if (latency > 150) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC7 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("latency should be less than 150 at time %d", $time);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end
endtask

endmodule