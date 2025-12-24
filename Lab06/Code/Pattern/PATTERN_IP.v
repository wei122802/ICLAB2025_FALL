`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

module PATTERN #(parameter IP_WIDTH = 9)(
    // Output signals (from pattern)
    IN_HOLE_CARD_NUM, 
    IN_HOLE_CARD_SUIT, 
    IN_PUB_CARD_NUM, 
    IN_PUB_CARD_SUIT,
    // Input signals (to pattern)
    OUT_WINNER
);

// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*8-1:0]  IN_HOLE_CARD_NUM;
output reg [IP_WIDTH*4-1:0]  IN_HOLE_CARD_SUIT;
output reg [19:0]             IN_PUB_CARD_NUM;
output reg [9:0]              IN_PUB_CARD_SUIT;

input [IP_WIDTH-1:0]          OUT_WINNER;

// ========================================
// Parameter & Integer
// ========================================
parameter PATTERN_NUM = 100;
integer patcount;
integer i, j, k;
integer total_cycles;
integer you_pass_task;

// ========================================
// Wire & Reg
// ========================================
reg [3:0] card_pool_num [0:51];
reg [1:0] card_pool_suit [0:51];
reg [5:0] card_idx;

reg [3:0] player_hole_num [0:IP_WIDTH-1][0:1];
reg [1:0] player_hole_suit [0:IP_WIDTH-1][0:1];
reg [3:0] public_card_num [0:4];
reg [1:0] public_card_suit [0:4];

reg [3:0] expected_rank [0:IP_WIDTH-1];
reg [23:0] expected_value [0:IP_WIDTH-1];
reg [IP_WIDTH-1:0] expected_winner;

// ========================================
// Initial
// ========================================
initial begin
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    IN_HOLE_CARD_NUM = 0;
    IN_HOLE_CARD_SUIT = 0;
    IN_PUB_CARD_NUM = 0;
    IN_PUB_CARD_SUIT = 0;
    total_cycles = 0;
    you_pass_task = 0;
    
    #(`CYCLE_TIME);
    
    for (patcount = 0; patcount < PATTERN_NUM; patcount = patcount + 1) begin
        input_task;
        wait_output_task;
        check_ans_task;
        $display("PASS PATTERN NO.%4d", patcount);
    end
    
    you_pass_task = 1;
    pass_task;
end

// ========================================
// Task: Generate Random Cards
// ========================================
task input_task; begin
    // Initialize card pool (52 cards)
    for (i = 0; i < 13; i = i + 1) begin
        card_pool_num[i*4 + 0] = i + 2;  // 2-14 (A=14)
        card_pool_suit[i*4 + 0] = 2'd0;  // Clubs
        card_pool_num[i*4 + 1] = i + 2;
        card_pool_suit[i*4 + 1] = 2'd1;  // Diamonds
        card_pool_num[i*4 + 2] = i + 2;
        card_pool_suit[i*4 + 2] = 2'd2;  // Hearts
        card_pool_num[i*4 + 3] = i + 2;
        card_pool_suit[i*4 + 3] = 2'd3;  // Spades
    end
    
    // Shuffle cards using Fisher-Yates algorithm
    for (i = 51; i > 0; i = i - 1) begin
        j = $urandom % (i + 1);
        // Swap
        card_idx = card_pool_num[i];
        card_pool_num[i] = card_pool_num[j];
        card_pool_num[j] = card_idx;
        
        card_idx = card_pool_suit[i];
        card_pool_suit[i] = card_pool_suit[j];
        card_pool_suit[j] = card_idx;
    end
    
    // Deal cards
    card_idx = 0;
    
    // Deal hole cards to each player
    for (i = 0; i < IP_WIDTH; i = i + 1) begin
        player_hole_num[i][0] = card_pool_num[card_idx];
        player_hole_suit[i][0] = card_pool_suit[card_idx];
        card_idx = card_idx + 1;
        
        player_hole_num[i][1] = card_pool_num[card_idx];
        player_hole_suit[i][1] = card_pool_suit[card_idx];
        card_idx = card_idx + 1;
    end
    
    // Deal 5 public cards
    for (i = 0; i < 5; i = i + 1) begin
        public_card_num[i] = card_pool_num[card_idx];
        public_card_suit[i] = card_pool_suit[card_idx];
        card_idx = card_idx + 1;
    end
    
    // Pack into output signals
    IN_HOLE_CARD_NUM = 0;
    IN_HOLE_CARD_SUIT = 0;
    for (i = 0; i < IP_WIDTH; i = i + 1) begin
        IN_HOLE_CARD_NUM[i*8 +: 8] = {player_hole_num[i][0], player_hole_num[i][1]};
        IN_HOLE_CARD_SUIT[i*4 +: 4] = {player_hole_suit[i][0], player_hole_suit[i][1]};
    end
    
    IN_PUB_CARD_NUM = {public_card_num[0], public_card_num[1], public_card_num[2], 
                       public_card_num[3], public_card_num[4]};
    IN_PUB_CARD_SUIT = {public_card_suit[0], public_card_suit[1], public_card_suit[2], 
                        public_card_suit[3], public_card_suit[4]};
    
    // Display input
    if (patcount < 5 || patcount == PATTERN_NUM - 1) begin
        $display("========================================");
        $display("Pattern %0d:", patcount);
        $display("Public Cards: %s %s %s %s %s", 
                 card_str(public_card_num[0], public_card_suit[0]),
                 card_str(public_card_num[1], public_card_suit[1]),
                 card_str(public_card_num[2], public_card_suit[2]),
                 card_str(public_card_num[3], public_card_suit[3]),
                 card_str(public_card_num[4], public_card_suit[4]));
        for (i = 0; i < IP_WIDTH; i = i + 1) begin
            $display("Player %0d: %s %s", i,
                     card_str(player_hole_num[i][0], player_hole_suit[i][0]),
                     card_str(player_hole_num[i][1], player_hole_suit[i][1]));
        end
    end
    
    #(`CYCLE_TIME);
end endtask

// ========================================
// Task: Wait Output (Combinational delay)
// ========================================
task wait_output_task; begin
    #(`CYCLE_TIME);
end endtask

// ========================================
// Task: Check Answer
// ========================================
task check_ans_task; begin
    reg [3:0] out_rank;
    reg [19:0] out_value;
    
    // Calculate expected winner
    calculate_expected_winner;
    
    // Check result
    if (OUT_WINNER !== expected_winner) begin
        $display("========================================");
        $display("                FAIL!                   ");
        $display("========================================");
        $display("Pattern %0d:", patcount);
        
        $display("\nPublic Cards: %s %s %s %s %s", 
                 card_str(public_card_num[0], public_card_suit[0]),
                 card_str(public_card_num[1], public_card_suit[1]),
                 card_str(public_card_num[2], public_card_suit[2]),
                 card_str(public_card_num[3], public_card_suit[3]),
                 card_str(public_card_num[4], public_card_suit[4]));
        
        for (i = 0; i < IP_WIDTH; i = i + 1) begin
            out_value = expected_value[i];
            out_rank = expected_value[i][23:20];
            $display("Player %0d: %s %s - Rank=%0d (%s), Value=%h", i,
                     card_str(player_hole_num[i][0], player_hole_suit[i][0]),
                     card_str(player_hole_num[i][1], player_hole_suit[i][1]),
                     expected_rank[i], rank_str(expected_rank[i]), out_value);
        end
        
        $display("\nExpected Winner: %b", expected_winner);
        $display("Your Output:     %b", OUT_WINNER);
        
        #(`CYCLE_TIME);
        $finish;
    end
    
    total_cycles = total_cycles + 1;
    #(`CYCLE_TIME);
end endtask

// ========================================
// Task: Calculate Expected Winner
// ========================================
task calculate_expected_winner; begin
    reg [3:0] best_rank;
    reg [19:0] best_value;
    
    // Evaluate each player
    for (i = 0; i < IP_WIDTH; i = i + 1) begin
        evaluate_player(i, expected_rank[i], expected_value[i]);
    end
    
    // Find winner(s)
    best_rank = 0;
    best_value = 0;
    expected_winner = 0;
    
    // Find the best hand
    for (i = 0; i < IP_WIDTH; i = i + 1) begin
        if (expected_rank[i] > best_rank || 
            (expected_rank[i] == best_rank && expected_value[i][19:0] > best_value)) begin
            best_rank = expected_rank[i];
            best_value = expected_value[i][19:0];
        end
    end
    
    // Mark all winners (handle ties)
    for (i = 0; i < IP_WIDTH; i = i + 1) begin
        if (expected_rank[i] == best_rank && expected_value[i][19:0] == best_value) begin
            expected_winner[i] = 1'b1;
        end
    end
end endtask

// ========================================
// Task: Evaluate Single Player
// ========================================
task evaluate_player;
    input integer player_id;
    output [3:0] rank;
    output [23:0] value;
    
    reg [3:0] seven_nums [0:6];
    reg [1:0] seven_suits [0:6];
    reg [3:0] sorted_nums [0:6];
    reg [1:0] sorted_suits [0:6];
    reg [3:0] temp_n;
    reg [1:0] temp_s;
    reg [2:0] num_count [2:14];
    reg [2:0] suit_count [0:3];
    reg [3:0] quads, trips;
    reg [3:0] pairs [0:1];
    reg [3:0] kickers [0:6];
    reg [2:0] pair_cnt, kicker_cnt;
    reg has_flush, has_straight;
    reg [1:0] flush_suit;
    reg [3:0] straight_high;
    integer a, b, c;
    
    begin
        // Collect 7 cards
        seven_nums[0] = player_hole_num[player_id][0];
        seven_suits[0] = player_hole_suit[player_id][0];
        seven_nums[1] = player_hole_num[player_id][1];
        seven_suits[1] = player_hole_suit[player_id][1];
        seven_nums[2] = public_card_num[0];
        seven_suits[2] = public_card_suit[0];
        seven_nums[3] = public_card_num[1];
        seven_suits[3] = public_card_suit[1];
        seven_nums[4] = public_card_num[2];
        seven_suits[4] = public_card_suit[2];
        seven_nums[5] = public_card_num[3];
        seven_suits[5] = public_card_suit[3];
        seven_nums[6] = public_card_num[4];
        seven_suits[6] = public_card_suit[4];
        
        // Sort (descending)
        for (a = 0; a < 7; a = a + 1) begin
            sorted_nums[a] = seven_nums[a];
            sorted_suits[a] = seven_suits[a];
        end
        
        for (a = 0; a < 6; a = a + 1) begin
            for (b = a + 1; b < 7; b = b + 1) begin
                if (sorted_nums[b] > sorted_nums[a]) begin
                    temp_n = sorted_nums[a];
                    temp_s = sorted_suits[a];
                    sorted_nums[a] = sorted_nums[b];
                    sorted_suits[a] = sorted_suits[b];
                    sorted_nums[b] = temp_n;
                    sorted_suits[b] = temp_s;
                end
            end
        end
        
        // Count occurrences
        for (a = 2; a <= 14; a = a + 1) begin
            num_count[a] = 0;
        end
        for (a = 0; a < 4; a = a + 1) begin
            suit_count[a] = 0;
        end
        
        for (a = 0; a < 7; a = a + 1) begin
            num_count[sorted_nums[a]] = num_count[sorted_nums[a]] + 1;
            suit_count[sorted_suits[a]] = suit_count[sorted_suits[a]] + 1;
        end
        
        // Analyze hand
        quads = 0;
        trips = 0;
        pairs[0] = 0;
        pairs[1] = 0;
        pair_cnt = 0;
        kicker_cnt = 0;
        
        for (a = 14; a >= 2; a = a - 1) begin
            if (num_count[a] == 4) begin
                quads = a;
            end else if (num_count[a] == 3) begin
                if (trips == 0) trips = a;
            end else if (num_count[a] == 2) begin
                if (pair_cnt == 0) begin
                    pairs[0] = a;
                    pair_cnt = 1;
                end else if (pair_cnt == 1) begin
                    pairs[1] = a;
                    pair_cnt = 2;
                end
            end else if (num_count[a] == 1) begin
                if (kicker_cnt < 7) begin
                    kickers[kicker_cnt] = a;
                    kicker_cnt = kicker_cnt + 1;
                end
            end
        end
        
        // Check flush
        has_flush = 0;
        flush_suit = 0;
        for (a = 0; a < 4; a = a + 1) begin
            if (suit_count[a] >= 5) begin
                has_flush = 1;
                flush_suit = a;
            end
        end
        
        // Check straight
        has_straight = 0;
        straight_high = 0;
        
        for (a = 0; a <= 2; a = a + 1) begin
            if (sorted_nums[a] == sorted_nums[a+1] + 1 &&
                sorted_nums[a+1] == sorted_nums[a+2] + 1 &&
                sorted_nums[a+2] == sorted_nums[a+3] + 1 &&
                sorted_nums[a+3] == sorted_nums[a+4] + 1) begin
                has_straight = 1;
                if (sorted_nums[a] > straight_high) begin
                    straight_high = sorted_nums[a];
                end
            end
        end
        
        // Check A-2-3-4-5 straight
        if (sorted_nums[0] == 14) begin
            for (a = 1; a <= 3; a = a + 1) begin
                if (sorted_nums[a] == 5 && sorted_nums[a+1] == 4 &&
                    sorted_nums[a+2] == 3 && sorted_nums[a+3] == 2) begin
                    has_straight = 1;
                    if (straight_high == 0 || 5 > straight_high) begin
                        straight_high = 5;
                    end
                end
            end
        end
        
        // Determine hand rank and value
        if (quads != 0) begin
            rank = 4'd8;
            value = {rank, quads, kickers[0], 12'd0};
        end else if (trips != 0 && pairs[0] != 0) begin
            rank = 4'd7;
            value = {rank, trips, pairs[0], 12'd0};
        end else if (has_flush) begin
            rank = 4'd6;
            // Get flush cards
            c = 0;
            for (a = 0; a < 7; a = a + 1) begin
                if (sorted_suits[a] == flush_suit && c < 5) begin
                    kickers[c] = sorted_nums[a];
                    c = c + 1;
                end
            end
            value = {rank, kickers[0], kickers[1], kickers[2], kickers[3], kickers[4]};
        end else if (has_straight) begin
            rank = 4'd5;
            if (straight_high == 5) begin
                value = {rank, 4'd5, 4'd4, 4'd3, 4'd2, 4'd14};
            end else begin
                value = {rank, straight_high,4'd0,4'd0,4'd0,4'd0};
            end
        end else if (trips != 0) begin
            rank = 4'd4;
            value = {rank, trips, kickers[0], kickers[1], 8'd0};
        end else if (pair_cnt >= 2) begin
            rank = 4'd3;
            value = {rank, pairs[0], pairs[1], kickers[0], 8'd0};
        end else if (pair_cnt == 1) begin
            rank = 4'd2;
            value = {rank, pairs[0], kickers[0], kickers[1], kickers[2], 4'd0};
        end else begin
            rank = 4'd1;
            value = {rank, kickers[0], kickers[1], kickers[2], kickers[3], kickers[4]};
        end
    end
endtask

// ========================================
// Function: Card String
// ========================================
function [23:0] card_str;
    input [3:0] num;
    input [1:0] suit;
    reg [15:0] num_s;
    reg [7:0] suit_s;
    begin
        case (num)
            4'd2:  num_s = "2 ";
            4'd3:  num_s = "3 ";
            4'd4:  num_s = "4 ";
            4'd5:  num_s = "5 ";
            4'd6:  num_s = "6 ";
            4'd7:  num_s = "7 ";
            4'd8:  num_s = "8 ";
            4'd9:  num_s = "9 ";
            4'd10: num_s = "10";
            4'd11: num_s = "J ";
            4'd12: num_s = "Q ";
            4'd13: num_s = "K ";
            4'd14: num_s = "A ";
            default: num_s = "? ";
        endcase
        
        case (suit)
            2'd0: suit_s = "C";
            2'd1: suit_s = "D";
            2'd2: suit_s = "H";
            2'd3: suit_s = "S";
        endcase
        
        card_str = {num_s, suit_s};
    end
endfunction

// ========================================
// Function: Rank String
// ========================================
function [127:0] rank_str;
    input [3:0] rank;
    begin
        case (rank)
            4'd10: rank_str = "Royal Flush";
            4'd9:  rank_str = "Straight Flush";
            4'd8:  rank_str = "Four of a Kind";
            4'd7:  rank_str = "Full House";
            4'd6:  rank_str = "Flush";
            4'd5:  rank_str = "Straight";
            4'd4:  rank_str = "Three of a Kind";
            4'd3:  rank_str = "Two Pair";
            4'd2:  rank_str = "One Pair";
            4'd1:  rank_str = "High Card";
            default: rank_str = "Unknown";
        endcase
    end
endfunction

// ========================================
// Task: Pass Display
// ========================================
task pass_task; begin
    $display("========================================");
    $display("        Congratulations!                ");
    $display("     You have passed all patterns!     ");
    $display("     Total Patterns: %4d              ", PATTERN_NUM);
    $display("========================================");
    $finish;
end endtask

endmodule