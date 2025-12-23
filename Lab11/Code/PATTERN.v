//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   ICLAB 2025 Fall 
// Lab11 Exercise : Geometric Transform Engine (GTE)
//      File Name : GTE.v
//    Module Name : GTE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// `define CYCLE_TIME 6
`define PAT_NUM         1000  
`define SEED            125
`define Debug_16        0

`ifdef RTL
	`define MEM_PATH_0      u_GTE.MEM0.Memory
    `define MEM_PATH_1      u_GTE.MEM1.Memory
    `define MEM_PATH_2      u_GTE.MEM2.Memory
    `define MEM_PATH_3      u_GTE.MEM3.Memory
    // MEM4-5: 2048x16 (Images 64-95)
    `define MEM_PATH_4      u_GTE.MEM4.Memory
    `define MEM_PATH_5      u_GTE.MEM5.Memory
    // MEM6-7: 1024x32 (Images 96-127)
    `define MEM_PATH_6      u_GTE.MEM6.Memory
    `define MEM_PATH_7      u_GTE.MEM7.Memory
`elsif GATE
    `define MEM_PATH_0      u_GTE.MEM0.Memory
    `define MEM_PATH_1      u_GTE.MEM1.Memory
    `define MEM_PATH_2      u_GTE.MEM2.Memory
    `define MEM_PATH_3      u_GTE.MEM3.Memory
    // MEM4-5: 2048x16 (Images 64-95)
    `define MEM_PATH_4      u_GTE.MEM4.Memory
    `define MEM_PATH_5      u_GTE.MEM5.Memory
    // MEM6-7: 1024x32 (Images 96-127)
    `define MEM_PATH_6      u_GTE.MEM6.Memory
    `define MEM_PATH_7      u_GTE.MEM7.Memory
`elsif POST
    `define MEM_PATH_0      u_CHIP.CORE.MEM0.Memory
    `define MEM_PATH_1      u_CHIP.CORE.MEM1.Memory
    `define MEM_PATH_2      u_CHIP.CORE.MEM2.Memory
    `define MEM_PATH_3      u_CHIP.CORE.MEM3.Memory
    // MEM4-5: 2048x16 (Images 64-95)
    `define MEM_PATH_4      u_CHIP.CORE.MEM4.Memory
    `define MEM_PATH_5      u_CHIP.CORE.MEM5.Memory
    // MEM6-7: 1024x32 (Images 96-127)
    `define MEM_PATH_6      u_CHIP.CORE.MEM6.Memory
    `define MEM_PATH_7      u_CHIP.CORE.MEM7.Memory
`endif

`ifdef RTL
	`define CYCLE_TIME 6
`elsif GATE
    `define CYCLE_TIME 6
`elsif POST
    `define CYCLE_TIME 11.6
`endif

module PATTERN(
    // Output signals
    clk,
    rst_n,
	
    in_valid_data,
	data,
	
    in_valid_cmd,
    cmd,    

    // Input signals
	busy
);

// ========================================
// I/O declaration
// ========================================
// Output
output reg        clk, rst_n;
output reg        in_valid_data;
output reg  [7:0] data;
output reg        in_valid_cmd;
output reg [17:0] cmd;

// Input
input busy;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk; //clock

// ========================================
// integer & parameter
// ========================================
// Total 128 images, 16x16 pixels, 8-bit depth
logic [7:0] golden_mem [0:127][0:15][0:15];
logic [1:0] op;
logic [1:0] func;
logic [6:0] ms;
logic [6:0] md;
logic Debug_16 = `Debug_16;
integer total_latency;
integer latency;
integer pat_i;

// Operation Enums for readability
typedef enum logic [3:0] {
    CMD_MX   = 4'b0000,
    CMD_MY   = 4'b0001,
    CMD_TRP  = 4'b0010,
    CMD_STRP = 4'b0011,
    CMD_R90  = 4'b0100,
    CMD_R180 = 4'b0101,
    CMD_R270 = 4'b0110,
    CMD_RS   = 4'b1000,
    CMD_LS   = 4'b1001,
    CMD_US   = 4'b1010,
    CMD_DS   = 4'b1011,
    CMD_ZZ4  = 4'b1100,
    CMD_ZZ8  = 4'b1101,
    CMD_MO4  = 4'b1110,
    CMD_MO8  = 4'b1111
} cmd_type_t;

//================================================================
//  INITIAL BLOCK
//================================================================
initial begin
    // 1. Initialization
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    reset_task;
    total_latency = 0;

    // 2. Input Data Phase (Send 128 images)
    $display("\033[1;34m[INFO]\033[0m Starting Input Data Phase...");
    input_data_task;
    // 3. Command & Verify Loop
    $display("\033[1;34m[INFO]\033[0m Starting Command Phase...");
    for (pat_i = 0; pat_i < `PAT_NUM; pat_i++) begin
        input_cmd_task;
        compute_golden_task;
        wait_busy_task;
        verify_sram_task;
        
        // if(pat_i % 100 == 0) 
        $display("\033[1;32m~~~PASS~~~\033[0m %0d/%0d patterns...", pat_i, `PAT_NUM);
    end

    // 4. Finish
    congratulation_task;
end


task reset_task; begin
    rst_n = 1'b1;
    in_valid_data = 1'b0;
    data = 'b0;
    in_valid_cmd = 1'b0;
    cmd = 'b0;
    
    force clk = 0;
    #(`CYCLE_TIME);  rst_n = 0;
    #(`CYCLE_TIME);  rst_n = 1;
    release clk;
    
    // Wait for a few cycles
    repeat(2) @(negedge clk);
end endtask

task input_data_task; begin
    integer i, r, c;
    // Wait until reset release
    @(negedge clk);

    in_valid_data = 1'b1;
    
    for (i = 0; i < 128; i++) begin
        for (r = 0; r < 16; r++) begin
            for (c = 0; c < 16; c++) begin
                data = $urandom_range(0, 255);
                golden_mem[i][r][c] = data; // Store to golden memory
                @(negedge clk);
            end
        end
    end
    
    in_valid_data = 1'b0;
    data = 'bx;
end endtask

task input_cmd_task; begin
    // Randomize command
    op   = $urandom_range(0, 3);
    func = $urandom_range(0, 3);
    ms   = $urandom_range(0, 127);
    md   = $urandom_range(0, 127); // Destination can be anywhere
    // case(pat_i/16384)
    //     0 : begin op=0 ; func = 0 ; end
    //     1 : begin op=0 ; func = 1 ; end
    //     2 : begin op=1 ; func = 0 ; end
    //     3 : begin op=1 ; func = 1 ; end
    // endcase
    // ms   = pat_i % 128 ;
    // md   = pat_i / 128 ;

    // Wait 2-4 cycles as per spec
    repeat($urandom_range(2, 4)) @(negedge clk);

    in_valid_cmd = 1'b1;
    cmd = {op, func, ms, md};
    @(negedge clk);
    in_valid_cmd = 1'b0;
    cmd = 'bx;
end endtask

task compute_golden_task;  begin
    logic [7:0] src_img [0:15][0:15];
    logic [7:0] dst_img [0:15][0:15];
    integer r, c, k;
    logic [3:0] full_op;

    // Load Source
    src_img = golden_mem[ms];
    full_op = {op, func};

    case (full_op)
        // --- Mirror ---
        CMD_MX: begin // Mirror X (Vertical Flip)
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[15-r][c] = src_img[r][c];
        end
        CMD_MY: begin // Mirror Y (Horizontal Flip)
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[r][15-c] = src_img[r][c];
        end
        
        // --- Transpose ---
        CMD_TRP: begin // Transpose (Main diagonal)
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[c][r] = src_img[r][c];
        end
        CMD_STRP: begin // Secondary Transpose
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[15-c][15-r] = src_img[r][c];
        end

        // --- Rotation ---
        CMD_R90: begin // CW 90
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[c][15-r] = src_img[r][c];
        end
        CMD_R180: begin // 180
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[15-r][15-c] = src_img[r][c];
        end
        CMD_R270: begin // CW 270 (CCW 90)
            for(r=0; r<16; r++) 
                for(c=0; c<16; c++) 
                    dst_img[15-c][r] = src_img[r][c];
        end

        // --- Shift (with Mirror Padding) ---
        // Shift amount is fixed at 5 pixels per Spec figures/desc?
        // "The image is shifted 5 pixels..." (Source 295, 333, 369, 410)
        CMD_RS: begin // Right Shift 5
            for(r=0; r<16; r++) begin
                for(c=0; c<16; c++) begin
                    if(c >= 5) dst_img[r][c] = src_img[r][c-5];
                    else       dst_img[r][c] = src_img[r][4-c]; // Mirror padding 4,3,2,1,0
                end
            end
        end
        CMD_LS: begin // Left Shift 5
            for(r=0; r<16; r++) begin
                for(c=0; c<16; c++) begin
                    if(c < 11) dst_img[r][c] = src_img[r][c+5];
                    else       dst_img[r][c] = src_img[r][15-(c-11)]; // Mirror padding 15,14...
                end
            end
        end
        CMD_US: begin // Up Shift 5
            for(r=0; r<16; r++) begin
                for(c=0; c<16; c++) begin
                    if(r < 11) dst_img[r][c] = src_img[r+5][c];
                    else       dst_img[r][c] = src_img[15-(r-11)][c];
                end
            end
        end
        CMD_DS: begin // Down Shift 5
            for(r=0; r<16; r++) begin
                for(c=0; c<16; c++) begin
                    if(r >= 5) dst_img[r][c] = src_img[r-5][c];
                    else       dst_img[r][c] = src_img[4-r][c];
                end
            end
        end

        // --- Reorder (Zigzag / Morton) ---
        CMD_ZZ4: begin // 4x4 Zigzag
            // Process each 4x4 block
            for(integer br=0; br<4; br++) begin
                for(integer bc=0; bc<4; bc++) begin
                    apply_zz4_block(src_img, dst_img, br*4, bc*4);
                end
            end
        end
        CMD_ZZ8: begin // 8x8 Zigzag
            for(integer br=0; br<2; br++) begin
                for(integer bc=0; bc<2; bc++) begin
                    apply_zz8_block(src_img, dst_img, br*8, bc*8);
                end
            end
        end
        CMD_MO4: begin // 4x4 Morton
                for(integer br=0; br<4; br++) begin
                for(integer bc=0; bc<4; bc++) begin
                    apply_mo4_block(src_img, dst_img, br*4, bc*4);
                end
            end
        end
        CMD_MO8: begin // 8x8 Morton
            for(integer br=0; br<2; br++) begin
                for(integer bc=0; bc<2; bc++) begin
                    apply_mo8_block(src_img, dst_img, br*8, bc*8);
                end
            end
        end
        default: dst_img = src_img; // Should not happen
    endcase

    // Store back to Golden Memory
    golden_mem[md] = dst_img;
end endtask

task apply_zz4_block(input logic [7:0] src[16][16], inout logic [7:0] dst[16][16], input int off_r, input int off_c);
    // Zigzag 4x4 path coordinates (row, col)
    const int path_r[16] = '{0,0,1,2,1,0,0,1,2,3,3,2,1,2,3,3};
    const int path_c[16] = '{0,1,0,0,1,2,3,2,1,0,1,2,3,3,2,3};
    int k, dr, dc;
    for(k=0; k<16; k++) begin
        dr = k / 4; 
        dc = k % 4;
        // Dest(Raster) = Src(Zigzag Path)
        dst[off_r + dr][off_c + dc] = src[off_r + path_r[k]][off_c + path_c[k]];
    end
endtask

task apply_zz8_block(input logic [7:0] src[16][16], inout logic [7:0] dst[16][16], input int off_r, input int off_c);
    // Zigzag 8x8 path
    // Generated standard zigzag path
    const int path_r[64] = '{
            0, 0, 1, 2, 1, 0, 0, 1, 2, 3, 4, 3, 2, 1, 0, 0,
            1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0, 0, 1, 2, 3,
            4, 5, 6, 7, 7, 6, 5, 4, 3, 2, 1, 2, 3, 4, 5, 6,
            7, 7, 6, 5, 4, 3, 4, 5, 6, 7, 7, 6, 5, 6, 7, 7
        };
        
        const int path_c[64] = '{
            0, 1, 0, 0, 1, 2, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5,
            4, 3, 2, 1, 0, 0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4,
            3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 3,
            2, 3, 4, 5, 6, 7, 7, 6, 5, 4, 5, 6, 7, 7, 6, 7
        };
    int k, dr, dc;
    for(k=0; k<64; k++) begin
        dr = k / 8;
        dc = k % 8;
        dst[off_r + dr][off_c + dc] = src[off_r + path_r[k]][off_c + path_c[k]];
    end
endtask

task apply_mo4_block(input logic [7:0] src[16][16], inout logic [7:0] dst[16][16], input int off_r, input int off_c);
    // Morton 4x4 path (Z-order)
    const int path_r[16] = '{0,0,1,1,0,0,1,1,2,2,3,3,2,2,3,3};
    const int path_c[16] = '{0,1,0,1,2,3,2,3,0,1,0,1,2,3,2,3};
    int k, dr, dc;
    for(k=0; k<16; k++) begin
        dr = k / 4;
        dc = k % 4;
        dst[off_r + dr][off_c + dc] = src[off_r + path_r[k]][off_c + path_c[k]];
    end
endtask

task apply_mo8_block(input logic [7:0] src[16][16], inout logic [7:0] dst[16][16], input int off_r, input int off_c);
    int k, dr, dc;
    int mr, mc; // Morton coordinates
    for(k=0; k<64; k++) begin
        dr = k / 8;
        dc = k % 8;
        mr = 0; mc = 0;
        // De-interleave k to get Morton row/col
        if(k[0]) mc[0]=1; if(k[1]) mr[0]=1;
        if(k[2]) mc[1]=1; if(k[3]) mr[1]=1;
        if(k[4]) mc[2]=1; if(k[5]) mr[2]=1;
        
        dst[off_r + dr][off_c + dc] = src[off_r + mr][off_c + mc];
    end
endtask

task wait_busy_task; begin
    latency = 0;
    while (busy === 1'b1) begin
        latency++;
        if (latency > 5000) begin // Spec limit
            $display("\033[1;31m[FAIL]\033[0m Latency exceeded 5000 cycles!");
            $finish;
        end
        @(negedge clk);
    end
    total_latency += latency;
end endtask

task verify_sram_task; begin
    integer i, j;
    logic [7:0] expected_val;
    logic [7:0] sram_val;
    logic [31:0] word_32;
    logic [15:0] word_16;
    logic [7:0]  word_8;
    integer addr;
    string mem_name , mem_source;

    for(i=0; i<16; i++) begin
        for(j=0; j<16; j++) begin
            expected_val = golden_mem[md][i][j];
            
            // --- Determine Memory and Address ---
            if (md < 16) begin // MEM0
                mem_name = "MEM0";
                addr = md * 256 + i * 16 + j;
                sram_val = `MEM_PATH_0[addr];
            end else if (md < 32) begin // MEM1
                mem_name = "MEM1";
                addr = (md - 16) * 256 + i * 16 + j;
                sram_val = `MEM_PATH_1[addr];
            end else if (md < 48) begin // MEM2
                mem_name = "MEM2";
                addr = (md - 32) * 256 + i * 16 + j;
                sram_val = `MEM_PATH_2[addr];
            end else if (md < 64) begin // MEM3
                mem_name = "MEM3";
                addr = (md - 48) * 256 + i * 16 + j;
                sram_val = `MEM_PATH_3[addr];
            end else if (md < 80) begin // MEM4 (16-bit)
                mem_name = "MEM4";
                // 2 pixels per word. 
                addr = (md - 64) * 128 + (i * 16 + j) / 2;
                word_16 = `MEM_PATH_4[addr];
                if (j % 2 == 0) sram_val = word_16[15:8]; // High byte
                else            sram_val = word_16[7:0];  // Low byte

            end else if (md < 96) begin // MEM5 (16-bit)
                mem_name = "MEM5";
                addr = (md - 80) * 128 + (i * 16 + j) / 2;
                word_16 = `MEM_PATH_5[addr];
                if (j % 2 == 0) sram_val = word_16[15:8];
                else            sram_val = word_16[7:0];
            end else if (md < 112) begin // MEM6 (32-bit)
                mem_name = "MEM6";
                // 4 pixels per word.
                addr = (md - 96) * 64 + (i * 16 + j) / 4;
                word_32 = `MEM_PATH_6[addr];
                case (j % 4)
                    0: sram_val = word_32[31:24]; // MSB
                    1: sram_val = word_32[23:16];
                    2: sram_val = word_32[15:8];
                    3: sram_val = word_32[7:0];   // LSB
                endcase
            end else begin // MEM7 (32-bit)
                mem_name = "MEM7";
                addr = (md - 112) * 64 + (i * 16 + j) / 4;
                word_32 = `MEM_PATH_7[addr];
                case (j % 4)
                    0: sram_val = word_32[31:24];
                    1: sram_val = word_32[23:16];
                    2: sram_val = word_32[15:8];
                    3: sram_val = word_32[7:0];
                endcase
            end

            if( ms < 16)
                mem_source = "MEM0";
            else if (ms < 32)
                mem_source = "MEM1";
            else if (ms < 48)
                mem_source = "MEM2";
            else if (ms < 64)
                mem_source = "MEM3";
            else if (ms < 80)
                mem_source = "MEM4";
            else if (ms < 96)
                mem_source = "MEM5";
            else if (ms < 112)
                mem_source = "MEM6";
            else 
                mem_source = "MEM7";

            // --- Verify and Report Mismatch ---
            if (sram_val !== expected_val) begin
                dump_debug_images;
                $display("\n========================================================================");
                $display("                      \033[1;31m[FAIL] DATA MISMATCH DETECTED\033[0m");
                $display("========================================================================");
                $display(" Pattern Index       : %0d", pat_i);
                $display(" Operation           : %s (Op: %b, Func: %b)", get_op_name(op, func), op, func);
                $display(" Source Image (ms)   : ID %0d", ms);
                $display(" Target Image (md)   : ID %0d", md);
                $display("------------------------------------------------------------------------");
                $display(" Error Location:");
                $display("   Image Pixel (row, col) : (%0d, %0d)", i, j);
                $display("   Source SRAM            : %s", mem_source);
                $display("   Target SRAM            : %s", mem_name);
                $display("   SRAM Address           : %0d (0x%h)", addr, addr);
                if (md >= 64 && md < 96)
                    $display("   Raw Word (16-bit)      : 0x%h (Checking byte index: %0d)", word_16, j%2);
                else if (md >= 96)
                    $display("   Raw Word (32-bit)      : 0x%h (Checking byte index: %0d)", word_32, j%4);
                $display("------------------------------------------------------------------------");
                $display(" Data Comparison (Decimal / Hex):");
                $display("   Expected (Golden)      : \033[1;32m%3d / 0x%02h\033[0m", expected_val, expected_val);
                $display("   Actual   (SRAM)        : \033[1;31m%3d / 0x%02h\033[0m", sram_val, sram_val);
                $display("========================================================================");
                $finish;
            end
        end
    end
end endtask

function string get_op_name(input [1:0] op, input [1:0] func);
    case ({op, func})
        4'b0000: return "MX (Mirror X)";
        4'b0001: return "MY (Mirror Y)";
        4'b0010: return "TRP (Transpose)";
        4'b0011: return "STRP (Sec. Transpose)";
        4'b0100: return "R90 (Rotate 90)";
        4'b0101: return "R180 (Rotate 180)";
        4'b0110: return "R270 (Rotate 270)";
        4'b1000: return "RS (Right Shift)";
        4'b1001: return "LS (Left Shift)";
        4'b1010: return "US (Up Shift)";
        4'b1011: return "DS (Down Shift)";
        4'b1100: return "ZZ4 (4x4 ZigZag)";
        4'b1101: return "ZZ8 (8x8 ZigZag)";
        4'b1110: return "MO4 (4x4 Morton)";
        4'b1111: return "MO8 (8x8 Morton)";
        default: return "UNKNOWN";
    endcase
endfunction

// =================================================================
//  Debug Task: Dump Full 16x16 Images (Source, Golden, Actual)
// =================================================================
task dump_debug_images; begin
    integer r, c;
    integer addr;
    logic [7:0] sram_full_img [0:15][0:15];
    logic [31:0] word_32;
    logic [15:0] word_16;

    for(r=0; r<16; r++) begin
        for(c=0; c<16; c++) begin
            if (md < 16) begin // MEM0
                addr = md * 256 + r * 16 + c;
                sram_full_img[r][c] = `MEM_PATH_0[addr];
            end else if (md < 32) begin // MEM1
                addr = (md - 16) * 256 + r * 16 + c;
                sram_full_img[r][c] = `MEM_PATH_1[addr];
            end else if (md < 48) begin // MEM2
                addr = (md - 32) * 256 + r * 16 + c;
                sram_full_img[r][c] = `MEM_PATH_2[addr];
            end else if (md < 64) begin // MEM3
                addr = (md - 48) * 256 + r * 16 + c;
                sram_full_img[r][c] = `MEM_PATH_3[addr];
            end else if (md < 80) begin // MEM4 (16-bit)
                addr = (md - 64) * 128 + (r * 16 + c) / 2;
                word_16 = `MEM_PATH_4[addr];
                sram_full_img[r][c] = (c % 2 == 0) ? word_16[15:8] : word_16[7:0];
            end else if (md < 96) begin // MEM5 (16-bit)
                addr = (md - 80) * 128 + (r * 16 + c) / 2;
                word_16 = `MEM_PATH_5[addr];
                sram_full_img[r][c] = (c % 2 == 0) ? word_16[15:8] : word_16[7:0];
            end else if (md < 112) begin // MEM6 (32-bit)
                addr = (md - 96) * 64 + (r * 16 + c) / 4;
                word_32 = `MEM_PATH_6[addr];
                case(c%4)
                    0: sram_full_img[r][c] = word_32[31:24];
                    1: sram_full_img[r][c] = word_32[23:16];
                    2: sram_full_img[r][c] = word_32[15:8];
                    3: sram_full_img[r][c] = word_32[7:0];
                endcase
            end else begin // MEM7 (32-bit)
                addr = (md - 112) * 64 + (r * 16 + c) / 4;
                word_32 = `MEM_PATH_7[addr];
                case(c%4)
                    0: sram_full_img[r][c] = word_32[31:24];
                    1: sram_full_img[r][c] = word_32[23:16];
                    2: sram_full_img[r][c] = word_32[15:8];
                    3: sram_full_img[r][c] = word_32[7:0];
                endcase
            end
        end
    end

    // ---------------------------------------------------------
    // 2.  Source Image 
    // ---------------------------------------------------------
    $display("\n\033[1;36m[DEBUG] Source Image (ID: %0d) - The Input\033[0m", ms);
    $display("     00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15");
    $display("   +-----------------------------------------------");
    for(r=0; r<16; r++) begin
        $write("%2d | ", r);
        for(c=0; c<16; c++) begin
            if (Debug_16 == 1)
                $write("%2h ", golden_mem[ms][r][c]);
            else
                $write("%3d ", golden_mem[ms][r][c]);
        end
        $write("\n");
    end

    // ---------------------------------------------------------
    // 3. Expected vs Actual 
    // ---------------------------------------------------------
    $display("\n\033[1;33m[DEBUG] Comparison: Expected (Golden) vs Actual (SRAM ID: %0d)\033[0m", md);
    $display("      Expected (Golden) Pattern                            Actual (Your Design) Output");
    $display("     00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15       00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15");
    $display("   +-----------------------------------------------      +-----------------------------------------------");
    
    for(r=0; r<16; r++) begin
        // Left Side: Golden
        $write("%2d | ", r);
        for(c=0; c<16; c++) begin
            if(golden_mem[md][r][c] !== sram_full_img[r][c])
                if (Debug_16 == 1)
                    $write("\033[1;31m%2h\033[0m ", golden_mem[md][r][c]); 
                else
                    $write("\033[1;31m%3d\033[0m ", golden_mem[md][r][c]);
            else
                if (Debug_16 == 1)
                    $write("\033[1;37m%2h\033[0m ", golden_mem[md][r][c]);
                else
                    $write("\033[1;37m%3d\033[0m ", golden_mem[md][r][c]);
        end

        $write("   "); // Gap between two images

        // Right Side: SRAM
        $write("%2d | ", r);
        for(c=0; c<16; c++) begin
            if(golden_mem[md][r][c] !== sram_full_img[r][c])
                if (Debug_16 == 0)
                    $write("\033[1;31m%3d\033[0m ", sram_full_img[r][c]); 
                else
                    $write("\033[1;31m%2h\033[0m ", sram_full_img[r][c]); 
            else
                if (Debug_16 == 0)
                    $write("\033[1;32m%3d\033[0m ", sram_full_img[r][c]);
                else
                    $write("\033[1;32m%2h\033[0m ", sram_full_img[r][c]);
        end
        $write("\n");
    end
    $display("\n");
end endtask

task congratulation_task; begin
    $display("----------------------------------------------------------------");
    $display("     \033[1;32mCongratulation! All %0d patterns passed!\033[0m", `PAT_NUM);
    $display("     Total Latency: %0d cycles", total_latency);
    $display("     Average Latency: %3f cycles", total_latency /(`PAT_NUM *1.0));
    $display("----------------------------------------------------------------");
    $finish;
end endtask

/*
You should fetch the data in SRAMs first and then check answer!
Example code:
	golden_ans = u_GTE.MEM7.Memory[ 5 ];  (used in 01_RTL / 03_GATE simulation)
	golden_ans = u_CHIP.MEM7.Memory[ 5 ]; (used in 06_POST simulation)
*/

endmodule



