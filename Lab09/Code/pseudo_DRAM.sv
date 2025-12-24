module pseudo_DRAM(input clk, INF.DRAM inf);
    //================================================================
    // parameters & integer
    //================================================================

    parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat"; // 注意路徑是否正確，通常跟pattern同一層可以不用../

    parameter DRAM_R_latency = 60; // 為了加速模擬，建議先設小一點，交出去前再改大測測看
    parameter DRAM_W_latency = 60;
    parameter DRAM_B_latency = 60;

    localparam [3:0] R_WAIT_AR_VALID    = 4'd0;
    localparam [3:0] R_AR_READY         = 4'd1;
    localparam [3:0] R_WAIT_R_READY     = 4'd2;
    localparam [3:0] R_VALID            = 4'd3;
    
    localparam [3:0] W_WAIT_AW_VALID    = 4'd0;
    localparam [3:0] W_AW_READY         = 4'd1;
    localparam [3:0] W_WAIT_W_VALID     = 4'd2;
    localparam [3:0] W_READY            = 4'd3;
    localparam [3:0] W_WAIT_B_READY     = 4'd4;
    localparam [3:0] W_B_VALID          = 4'd5;

    //================================================================
    // wire & registers 
    //================================================================
    logic [3:0] r_cs, r_ns;
    logic [3:0] w_cs, w_ns;

    // *** 修改 1: 記憶體大小 ***
    // 每個玩家 12 bytes，共 256 位玩家
    logic [7:0] golden_DRAM [((65536+12*256)-1):(65536+0)]; 

    logic [7:0] r_wait_rnd, w_wait_rnd, b_wait_rnd;
    logic [7:0] r_wait_cnt, w_wait_cnt, b_wait_cnt;
    logic [16:0] r_addr, w_addr;

    //================================================================
    // Design
    //================================================================
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            r_cs <= R_WAIT_AR_VALID;
        end else begin
            r_cs <= r_ns;
        end
    end

    always_comb begin
        case(r_cs)
            R_WAIT_AR_VALID: begin
                if (inf.AR_VALID) begin
                    r_ns = R_AR_READY;
                end else begin
                    r_ns = R_WAIT_AR_VALID;
                end
            end
            R_AR_READY: begin
                r_ns = R_WAIT_R_READY;
            end
            R_WAIT_R_READY: begin
                if (inf.R_READY) begin
                    r_ns = r_wait_cnt == r_wait_rnd ? R_VALID : R_WAIT_R_READY;
                end else begin
                    r_ns = R_WAIT_R_READY;
                end
            end
            R_VALID: begin
                r_ns = R_WAIT_AR_VALID;
            end
            default: begin
                r_ns = r_cs;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case (r_cs)
            R_AR_READY: begin
                r_wait_rnd <= $urandom_range(1, DRAM_R_latency);
                r_wait_cnt <= 'd0;
            end
            R_WAIT_R_READY: begin
                if (inf.R_READY) begin
                    r_wait_cnt <= r_wait_cnt + 1;
                end else begin
                    r_wait_cnt <= 'd0;
                end
            end
            default: begin
                r_wait_cnt <= 'd0;
            end
        endcase
    end
    
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.AR_READY <= 1'b0;
        end else begin
            inf.AR_READY <= r_cs == R_AR_READY;
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            r_addr <= 1'b0;
        end else begin
            r_addr <= r_cs == R_AR_READY ? inf.AR_ADDR : r_addr;
        end
    end

    // *** 修改 2: 讀取資料 (R_DATA) ***
    // 擴展為 96 bits (12 bytes)
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.R_DATA <= 96'h0; // Reset 也要改 96 bits
        end else begin
            inf.R_DATA <= r_cs == R_VALID ? {
                golden_DRAM[r_addr+11],
                golden_DRAM[r_addr+10],
                golden_DRAM[r_addr+9],
                golden_DRAM[r_addr+8],
                golden_DRAM[r_addr+7],
                golden_DRAM[r_addr+6],
                golden_DRAM[r_addr+5],
                golden_DRAM[r_addr+4],
                golden_DRAM[r_addr+3],
                golden_DRAM[r_addr+2],
                golden_DRAM[r_addr+1],
                golden_DRAM[r_addr+0]
            } : 'd0;
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.R_VALID <= 1'b0;
        end else begin
            inf.R_VALID <= r_cs == R_VALID;
        end
    end
    
    always_comb begin
        inf.R_RESP = 2'b00;
    end
    
    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            w_cs <= W_WAIT_AW_VALID;
        end else begin
            w_cs <= w_ns;
        end
    end

    always_comb begin
        case(w_cs)
            W_WAIT_AW_VALID: begin
                if (inf.AW_VALID) begin
                    w_ns = W_AW_READY;
                end else begin
                    w_ns = W_WAIT_AW_VALID;
                end
            end
            W_AW_READY: begin
                w_ns = W_WAIT_W_VALID;
            end
            W_WAIT_W_VALID: begin
                if (inf.W_VALID) begin
                    w_ns = w_wait_cnt == w_wait_rnd ? W_READY : W_WAIT_W_VALID;
                end else begin
                    w_ns = W_WAIT_W_VALID;
                end
            end
            W_READY: begin
                w_ns = W_WAIT_B_READY;
            end
            W_WAIT_B_READY: begin
                if (inf.B_READY) begin
                    w_ns = b_wait_cnt == b_wait_rnd ? W_B_VALID : W_WAIT_B_READY;
                end else begin
                    w_ns = W_WAIT_B_READY;
                end
            end
            W_B_VALID: begin
                w_ns = W_WAIT_AW_VALID;
            end
            default: begin
                w_ns = w_cs;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        case (w_cs)
            W_AW_READY: begin
                w_wait_rnd <= $urandom_range(1, DRAM_W_latency);
                w_wait_cnt <= 0;
            end
            W_WAIT_W_VALID: begin
                if (inf.W_VALID) begin
                    w_wait_cnt <= w_wait_cnt + 1;
                end else begin
                    w_wait_cnt <= 'd0;
                end
            end
            W_READY: begin
                b_wait_rnd <= $urandom_range(1, DRAM_B_latency);
                b_wait_cnt <= 0;
            end
            W_WAIT_B_READY: begin
                if (inf.B_READY) begin
                    b_wait_cnt <= b_wait_cnt + 1;
                end else begin
                    b_wait_cnt <= 'd0;
                end
            end
            default: begin
                w_wait_cnt <= 'd0;
                b_wait_cnt <= 'd0;
            end
        endcase
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.AW_READY <= 1'b0;
        end else begin
            inf.AW_READY <= w_cs == W_AW_READY;
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            w_addr <= 1'b0;
        end else begin
            w_addr <= w_cs == W_AW_READY ? inf.AW_ADDR : w_addr;
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.W_READY <= 1'b0;
        end else begin
            inf.W_READY <= w_cs == W_READY;
        end
    end

    always_ff @(posedge clk or negedge inf.rst_n) begin
        if (~inf.rst_n) begin
            inf.B_VALID <= 1'b0;
        end else begin
            inf.B_VALID <= w_cs == W_B_VALID;
        end
    end

    always_comb begin
        inf.B_RESP = 2'b00;
    end

    //================================================================
    // Read DRAM & Write DRAM
    //================================================================
    initial begin
        read_dram();
        while (1) begin
            @(posedge clk);
            // *** 修改 3: 寫入資料 (W_DATA) ***
            // 擴展為 12 bytes
            if (w_cs == W_READY) begin
                golden_DRAM[w_addr+0]  <= inf.W_DATA[7:0];
                golden_DRAM[w_addr+1]  <= inf.W_DATA[15:8];
                golden_DRAM[w_addr+2]  <= inf.W_DATA[23:16];
                golden_DRAM[w_addr+3]  <= inf.W_DATA[31:24];
                golden_DRAM[w_addr+4]  <= inf.W_DATA[39:32];
                golden_DRAM[w_addr+5]  <= inf.W_DATA[47:40];
                golden_DRAM[w_addr+6]  <= inf.W_DATA[55:48];
                golden_DRAM[w_addr+7]  <= inf.W_DATA[63:56];
                golden_DRAM[w_addr+8]  <= inf.W_DATA[71:64];
                golden_DRAM[w_addr+9]  <= inf.W_DATA[79:72];
                golden_DRAM[w_addr+10] <= inf.W_DATA[87:80];
                golden_DRAM[w_addr+11] <= inf.W_DATA[95:88];
            end
        end
    end

    task read_dram; begin
        $readmemh(DRAM_p_r, golden_DRAM);
    end endtask

endmodule