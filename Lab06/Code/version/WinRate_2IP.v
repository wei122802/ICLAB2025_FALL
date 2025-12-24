//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/10
//		Version		: v1.0
//   	File Name   : WinRate.v
//   	Module Name : WinRate
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Poker.v"

module WinRate (
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_hole_num,
    in_hole_suit,
    in_pub_num,
    in_pub_suit,
    out_valid,
    out_win_rate
);
// ===============================================================
// Input & Output
// ===============================================================
input clk;
input rst_n;
input in_valid;
input [71:0] in_hole_num;
input [35:0] in_hole_suit;
input [11:0] in_pub_num;
input [5:0]  in_pub_suit;

output reg out_valid;
output reg [62:0] out_win_rate;
reg [62:0] out_win_rate_comb;
// ===============================================================
// Parameter
// ===============================================================
parameter IDLE      = 3'd0;
parameter INPUT     = 3'd1;
parameter DEALPOKER = 3'd2;
parameter PREDICT   = 3'd3;
parameter OUTPUT    = 3'd4;
parameter DIVIDE    = 3'd5;

parameter J = 4'd11;
parameter Q = 4'd12;
parameter K = 4'd13;
parameter A = 4'd14;

parameter CLUB    = 2'd0;
parameter DIAMOND = 2'd1;
parameter HEART   = 2'd2;
parameter SPADE   = 2'd3;
integer i,j;
// ===============================================================
// Reg & Wire
// ===============================================================
reg [71:0] in_hole_num_reg;
reg [35:0] in_hole_suit_reg;
reg [11:0] in_pub_num_reg;
reg [5:0] in_pub_suit_reg;
reg [2:0] state_n, state_c;
reg [9:0] cnt;
reg [3:0] predict_num1;
reg [1:0] predict_suit1;
reg [3:0] predict_num2;
reg [1:0] predict_suit2;

reg [3:0] predict_num1_2;
reg [1:0] predict_suit1_2;
reg [3:0] predict_num2_2;
reg [1:0] predict_suit2_2;

reg [4:0] predict1_cnt; //0~6
reg [4:0] predict2_cnt ;//X~31

reg [4:0] predict1_2_cnt; //7~30
reg [4:0] predict2_2_cnt ;//X~31

reg [5:0] _31_card_num [0:30];
reg [1:0] _31_card_suit [0:30];
reg [4:0] deal_cnt;
reg [7:0] deal_num;
reg [3:0] deal_suit;
reg [8:0] winner;
reg exist_card;
reg [14:0] player_score [0:8];
reg [5:0]  weight;
reg [3:0]  div_cnt;
// ===============================================================
// Counter
// ===============================================================
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) div_cnt <= 4'b0;
    else if (state_c == IDLE) div_cnt <= 4'b0; 
    else if (state_c == DIVIDE) div_cnt <= div_cnt + 1;
    else div_cnt <= div_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) predict1_2_cnt <= 5'd9;
    else if (state_c == IDLE) predict1_2_cnt <= 5'd9; 
    else if (state_c == PREDICT && (predict2_2_cnt==30)) predict1_2_cnt <= predict1_2_cnt +1 ;
    else predict1_2_cnt <= predict1_2_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) predict2_2_cnt <= 5'd10;
    else if (state_c == IDLE) predict2_2_cnt <= 5'd10; 
    else if (state_c == PREDICT) begin
        if(predict2_2_cnt ==30) predict2_2_cnt <= predict1_2_cnt + 2;
        else predict2_2_cnt <= predict2_2_cnt + 1;
    end
    else predict2_2_cnt <= predict2_2_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) predict1_cnt <= 5'b0;
    else if (state_c == IDLE) predict1_cnt <= 5'b0; 
    else if (state_c == PREDICT && (predict2_cnt==30)) predict1_cnt <= predict1_cnt +1 ;
    else predict1_cnt <= predict1_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) predict2_cnt <= 5'b0;
    else if (state_c == IDLE) predict2_cnt <= 5'b1; 
    else if (state_c == PREDICT) begin
        if(predict2_cnt ==30) predict2_cnt <= predict1_cnt + 2;
        else predict2_cnt <= predict2_cnt + 1;
    end
    else predict2_cnt <= predict2_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) deal_cnt <= 8'b0;
    else if (state_c == IDLE) deal_cnt <= 8'b0; 
    else if (!exist_card) deal_cnt <= deal_cnt + 1;
    else deal_cnt <= deal_cnt;
end


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) cnt <= 10'b0;
    else if (state_c == IDLE) cnt <= 10'b0;
    else if (state_c == PREDICT || state_c==DEALPOKER) cnt <= cnt + 1;
    else cnt <= cnt;
end

// ===============================================================
// FSM
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)  state_c <= IDLE;
    else state_c <= state_n;
end

always @ (*) begin
    case (state_c)
        IDLE: begin
            if (in_valid) state_n = INPUT;
            else state_n = IDLE;
        end
        INPUT:
            state_n = DEALPOKER;
        DEALPOKER:
            if(cnt == 10'd52) state_n = PREDICT;
            else state_n = DEALPOKER;
        PREDICT: 
            if(cnt == 10'd288) state_n = DIVIDE;
            else state_n = PREDICT;
        DIVIDE: begin
            if(div_cnt == 4'd8) state_n = OUTPUT;
            else state_n = DIVIDE;
        end
        OUTPUT: begin
            state_n = IDLE;
        end
        default: state_n = IDLE;
    endcase
end

// ===============================================================
// 31Card arragement
// ===============================================================
always @(*) begin
    if(state_c == DEALPOKER)
        case(cnt)
            0,1,2,3,4,5,6,7,8,9,10,11,12 : deal_num = cnt+2;
            13,14,15,16,17,18,19,20,21,22,23,24,25 : deal_num = cnt - 11;
            26,27,28,29,30,31,32,33,34,35,36,37,38 : deal_num = cnt - 24;
            39,40,41,42,43,44,45,46,47,48,49,50,51 : deal_num = cnt - 37;
            default : deal_num = 0 ;
        endcase
    else
        deal_num = 0 ;
end

always @(*)begin
    if(state_c == DEALPOKER)
        case(cnt)
            0,1,2,3,4,5,6,7,8,9,10,11,12 : deal_suit = CLUB;
            13,14,15,16,17,18,19,20,21,22,23,24,25 : deal_suit = DIAMOND;
            26,27,28,29,30,31,32,33,34,35,36,37,38 : deal_suit = HEART;
            39,40,41,42,43,44,45,46,47,48,49,50,51 : deal_suit = SPADE;
            default : deal_suit = 0 ;
        endcase
    else
        deal_suit = 0 ;
end
// reg [71:0] in_hole_num_reg;
always @(*) begin
    exist_card= (in_hole_num_reg[71:68]==deal_num && in_hole_suit_reg[35:34]==deal_suit) ||
                (in_hole_num_reg[67:64]==deal_num && in_hole_suit_reg[33:32]==deal_suit) ||
                (in_hole_num_reg[63:60]==deal_num && in_hole_suit_reg[31:30]==deal_suit) ||
                (in_hole_num_reg[59:56]==deal_num && in_hole_suit_reg[29:28]==deal_suit) ||
                (in_hole_num_reg[55:52]==deal_num && in_hole_suit_reg[27:26]==deal_suit) ||
                (in_hole_num_reg[51:48]==deal_num && in_hole_suit_reg[25:24]==deal_suit) ||
                (in_hole_num_reg[47:44]==deal_num && in_hole_suit_reg[23:22]==deal_suit) ||
                (in_hole_num_reg[43:40]==deal_num && in_hole_suit_reg[21:20]==deal_suit) ||
                (in_hole_num_reg[39:36]==deal_num && in_hole_suit_reg[19:18]==deal_suit) ||
                (in_hole_num_reg[35:32]==deal_num && in_hole_suit_reg[17:16]==deal_suit) ||
                (in_hole_num_reg[31:28]==deal_num && in_hole_suit_reg[15:14]==deal_suit) ||
                (in_hole_num_reg[27:24]==deal_num && in_hole_suit_reg[13:12]==deal_suit) ||
                (in_hole_num_reg[23:20]==deal_num && in_hole_suit_reg[11:10]==deal_suit) ||
                (in_hole_num_reg[19:16]==deal_num && in_hole_suit_reg[9:8]  ==deal_suit) ||
                (in_hole_num_reg[15:12]==deal_num && in_hole_suit_reg[7:6]  ==deal_suit) ||
                (in_hole_num_reg[11:8] ==deal_num && in_hole_suit_reg[5:4]  ==deal_suit) ||
                (in_hole_num_reg[7:4]  ==deal_num && in_hole_suit_reg[3:2]  ==deal_suit) ||
                (in_hole_num_reg[3:0]  ==deal_num && in_hole_suit_reg[1:0]  ==deal_suit) ||
                (in_pub_num_reg[11:8]  ==deal_num && in_pub_suit_reg[5:4]==deal_suit)    ||
                (in_pub_num_reg[7:4]   ==deal_num && in_pub_suit_reg[3:2]==deal_suit)    ||
                (in_pub_num_reg[3:0]   ==deal_num && in_pub_suit_reg[1:0]==deal_suit);
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0 ; i<31 ; i = i+1) 
            _31_card_num[i] <= 6'b0;
    end
    else if (state_c == IDLE) begin
        for(i = 0 ; i<31 ; i = i+1) begin
            _31_card_num[i] <= 6'b0;
        end
    end
    else if (state_c == DEALPOKER) begin
        if(!exist_card)
            _31_card_num[deal_cnt-1] <= deal_num;
        else
            _31_card_num[deal_cnt-1] <= _31_card_num[deal_cnt-1];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0 ; i<31 ; i = i+1) 
            _31_card_suit[i] <= 2'b0;
    end
    else if (state_c == IDLE) begin
        for(i = 0 ; i<31 ; i = i+1) begin
            _31_card_suit[i] <= 2'b0;
        end
    end
    else if (state_c == DEALPOKER) begin
        if(!exist_card)
            _31_card_suit[deal_cnt-1] <= deal_suit;
        else
            _31_card_suit[deal_cnt-1] <= _31_card_suit[deal_cnt-1];
    end
end

// ===============================================================
// Prediction
// ===============================================================
always @(*) begin
    if(state_c == PREDICT) predict_num1 = _31_card_num[predict1_cnt];
    else predict_num1 = 0;
end

always @(*) begin
    if(state_c == PREDICT) predict_suit1 = _31_card_suit[predict1_cnt];
    else predict_suit1 = 0;
end

always @(*) begin
    if((state_c == PREDICT)) predict_num2 = _31_card_num[predict2_cnt];
    else predict_num2 = 0;
end

always @(*) begin
    if((state_c == PREDICT)) predict_suit2 = _31_card_suit[predict2_cnt];
    else predict_suit2 = 0;
end

// ===============================================================
// Prediction 2 
// ===============================================================
always @(*) begin
    if(state_c == PREDICT) predict_num1_2 = _31_card_num[predict1_2_cnt];
    else predict_num1_2 = 0;
end

always @(*) begin
    if(state_c == PREDICT) predict_suit1_2 = _31_card_suit[predict1_2_cnt];
    else predict_suit1_2 = 0;
end

always @(*) begin
    if((state_c == PREDICT)&&(cnt<284)) predict_num2_2 = _31_card_num[predict2_2_cnt];
    else predict_num2_2 = 0;
end

always @(*) begin
    if((state_c == PREDICT)&&(cnt<284)) predict_suit2_2 = _31_card_suit[predict2_2_cnt];
    else predict_suit2_2 = 0;
end
// ===============================================================
// Winner 2 
// ===============================================================
wire [19:0] poker_pub_num_2;
wire [9:0] poker_pub_suit_2;
wire [3:0] winner_number_2;
wire [8:0] winner_reg_2;
reg [8:0] winner_2;
reg [5:0] weight_2;
reg [14:0] player_score_2 [0:8];

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) winner_2 <= 9'b0;
    else if (state_c == PREDICT) winner_2 <= winner_reg_2;
    else winner_2 <= 9'b0;
end

assign poker_pub_num_2 = {in_pub_num_reg, predict_num1_2, predict_num2_2};
assign poker_pub_suit_2 = {in_pub_suit_reg, predict_suit1_2, predict_suit2_2}; //10bits

Poker #(9) Poker_U_2(
    .IN_HOLE_CARD_NUM(in_hole_num_reg),
    .IN_HOLE_CARD_SUIT(in_hole_suit_reg),
    .IN_PUB_CARD_NUM(poker_pub_num_2),
    .IN_PUB_CARD_SUIT(poker_pub_suit_2),
    .OUT_WINNER (winner_reg_2)
);

assign winner_number_2 = winner_2[0]+winner_2[1]+winner_2[2]+winner_2[3]+
                       winner_2[4]+winner_2[5]+winner_2[6]+winner_2[7]+winner_2[8];

always @(*) begin
    case(winner_number_2)
        1: weight_2 = 36;
        2: weight_2 = 18;
        3: weight_2 = 12;
        4: weight_2 = 9;
        9: weight_2 = 4;
        default: weight_2 = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1)
            player_score_2[i] <= 15'd0;
    end else if (state_c == IDLE) begin
        for(i = 0; i < 9; i = i + 1)
            player_score_2[i] <= 15'd0;
    end else if((state_c == PREDICT &&(cnt<285))) begin
        for(i = 0; i < 9; i = i + 1) begin
            if(winner_2[i])
                player_score_2[i] <= player_score_2[i] + weight_2;
            else
                player_score_2[i] <= player_score_2[i];
        end
    end
    // else for(i = 0; i < 9; i = i + 1) player_score_2[i] <= player_score_2[i];
end

// wire [15:0] player_score_temp [0:8];
// assign player_score_temp[0] = player_score[0] + player_score_2[0];
// assign player_score_temp[1] = player_score[1] + player_score_2[1];
// assign player_score_temp[2] = player_score[2] + player_score_2[2];
// assign player_score_temp[3] = player_score[3] + player_score_2[3];
// assign player_score_temp[4] = player_score[4] + player_score_2[4];
// assign player_score_temp[5] = player_score[5] + player_score_2[5];
// assign player_score_temp[6] = player_score[6] + player_score_2[6];
// assign player_score_temp[7] = player_score[7] + player_score_2[7];
// assign player_score_temp[8] = player_score[8] + player_score_2[8];

// ===============================================================
// Winner
// ===============================================================
wire [19:0] poker_pub_num;
wire [9:0] poker_pub_suit;
wire [3:0] winner_number;
wire [8:0] winner_reg;


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) winner <= 9'b0;
    else if (state_c == PREDICT) winner <= winner_reg;
    else winner <= 9'b0;
end

assign poker_pub_num = {in_pub_num_reg, predict_num1, predict_num2};
assign poker_pub_suit = {in_pub_suit_reg, predict_suit1, predict_suit2}; //10bits

Poker #(9) Poker_U(
    .IN_HOLE_CARD_NUM(in_hole_num_reg),
    .IN_HOLE_CARD_SUIT(in_hole_suit_reg),
    .IN_PUB_CARD_NUM(poker_pub_num),
    .IN_PUB_CARD_SUIT(poker_pub_suit),
    .OUT_WINNER (winner_reg)
);
assign winner_number = winner[0]+winner[1]+winner[2]+winner[3]+
                       winner[4]+winner[5]+winner[6]+winner[7]+winner[8];

always @(*) begin
    case(winner_number)
        1: weight = 36;
        2: weight = 18;
        3: weight = 12;
        4: weight = 9;
        9: weight = 4;
        default: weight = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1)
            player_score[i] <= 15'd0;
    end else if (state_c == IDLE) begin
        for(i = 0; i < 9; i = i + 1)
            player_score[i] <= 15'd0;
    end else if( (state_c == PREDICT) && (cnt<288))  begin
        for(i = 0; i < 9; i = i + 1) begin
            if(winner[i])
                player_score[i] <= player_score[i] + weight;
            else
                player_score[i] <= player_score[i];
        end
    end
end
//===============
// Win Rate Calculation
reg [6:0] player_win_rate [0:8];
reg [14:0] div_temp;
wire [6:0] player_temp;

always @(*) begin
    // if(state_c == DIVIDE)
        div_temp = player_score[div_cnt] + player_score_2[div_cnt];
    // else
    //     div_temp = 15'b0;
end

assign player_temp = (div_temp * 100) / 16740;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 9; i = i + 1)
            player_win_rate[i] <= 7'b0;
    end
    else if (state_c == IDLE) begin
        for(i = 0; i < 9; i = i + 1)
            player_win_rate[i] <= 7'b0;
    end
    else if (state_c == DIVIDE) begin
        player_win_rate[div_cnt] <= player_temp;
        // player_win_rate[8] <= player_temp;
        // player_win_rate[7] <=player_win_rate[8];  player_win_rate[6] <=player_win_rate[7];
        // player_win_rate[5] <=player_win_rate[6];  player_win_rate[4] <=player_win_rate[5];
        // player_win_rate[3] <=player_win_rate[4];  player_win_rate[2] <=player_win_rate[3];
        // player_win_rate[1] <=player_win_rate[2];  player_win_rate[0] <=player_win_rate[1];
    end
end

// always @(*) begin
//     case (div_cnt)
//         0: player_win_rate[0] = player_temp;
//         1: player_win_rate[1] = player_temp;
//         2: player_win_rate[2] = player_temp;
//         3: player_win_rate[3] = player_temp;
//         4: player_win_rate[4] = player_temp;
//         5: player_win_rate[5] = player_temp;
//         6: player_win_rate[6] = player_temp;
//         7: player_win_rate[7] = player_temp;
//         8: player_win_rate[8] = player_temp;
//         // default: for (i=0; i<9; i=i+1) player_win_rate[i] = 7'b0;
//     endcase
// end

// assign 
// assign player_win_rate[0] = (cnt ==519 ) ? (player_score[0]*100 ) /16740 : 0;
// assign player_win_rate[1] = (cnt ==519 ) ? (player_score[1]*100 ) /16740 : 0;
// assign player_win_rate[2] = (cnt ==519 ) ? (player_score[2]*100 ) /16740 : 0;
// assign player_win_rate[3] = (cnt ==519 ) ? (player_score[3]*100 ) /16740 : 0;
// assign player_win_rate[4] = (cnt ==519 ) ? (player_score[4]*100 ) /16740 : 0;
// assign player_win_rate[5] = (cnt ==519 ) ? (player_score[5]*100 ) /16740 : 0;
// assign player_win_rate[6] = (cnt ==519 ) ? (player_score[6]*100 ) /16740 : 0;
// assign player_win_rate[7] = (cnt ==519 ) ? (player_score[7]*100 ) /16740 : 0;
// assign player_win_rate[8] = (cnt ==519 ) ? (player_score[8]*100 ) /16740 : 0;

always @(*) begin
    if(state_c == IDLE) begin
        out_win_rate_comb = 63'b0;
    end else begin
        out_win_rate_comb = {player_win_rate[8], player_win_rate[7], player_win_rate[6], player_win_rate[5], player_win_rate[4], player_win_rate[3], player_win_rate[2], player_win_rate[1], player_win_rate[0]};
    end
end

// ===============================================================
// Output
// ===============================================================
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 1'b0;
    else if (state_c == OUTPUT) out_valid <= 1'b1;
    else out_valid <= 1'b0;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) out_win_rate <= 63'b0;
    else if (state_c == OUTPUT) 
        out_win_rate <= out_win_rate_comb;
    else out_win_rate <= 63'b0;
end
// ===============================================================
// Input_register
// ===============================================================
// reg [71:0] in_hole_num_reg;
// reg [35:0] in_hole_suit_reg;
// reg [11:0] in_pub_num_reg;
// reg [5:0] in_pub_suit_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_hole_num_reg <= 72'b0;
    end
    else if (in_valid) begin
        in_hole_num_reg <= in_hole_num;
    end
    else begin
        in_hole_num_reg <= in_hole_num_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_hole_suit_reg <= 36'b0;
    end
    else if (in_valid) begin
        in_hole_suit_reg <= in_hole_suit;
    end
    else begin
        in_hole_suit_reg <= in_hole_suit_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_pub_num_reg <= 12'b0;
    end
    else if (in_valid) begin
        in_pub_num_reg <= in_pub_num;
    end
    else begin
        in_pub_num_reg <= in_pub_num_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_pub_suit_reg <= 6'b0;
    end
    else if (in_valid) begin
        in_pub_suit_reg <= in_pub_suit;
    end
    else begin
        in_pub_suit_reg <= in_pub_suit_reg;
    end
end

endmodule

//original
// Cycle: 20.00
// Area: 574313.241724
// Performance: 11486264.83448000

//improve Poker.v
// Cycle: 20.00
// Area: 541346.601776
// Performance: 10826932.03552000

// Cycle 12 15 
// NOT MET
  

// Cycle: 18.00
// Area: 691308.877953
// Performance: 12443559.80315400

//add reg before winner ********
// Cycle: 18.00
// Area: 488546.856269
// Performance: 8793843.41284200
// 8793843.412842000*52100 = 458159241809.0682

// Cycle: 17.50
// Area: 515573.251058
// Performance: 9022531.89351500

// Cycle: 17.00
// Area: 534634.530882
// Performance: 9088787.02499400

// Cycle: 15.00
// Area: 712851.248445
// Performance: 10692768.72667500

// remove winner rst_n X

//let 9 div -> 1 div

// Cycle: 18.00 X
// Area: 385856.553541
// Performance: 6945417.96373800
// 6945417.96373800*53000 =  368306754769.1400

// Cycle: 18.00 
// Area: 420141.859188
// Performance: 7562553.46538400

// Cycle: 18.00 **********
// Area: 415426.536132
// Performance: 7477677.65037600

//improve Poker.v findmax
// Cycle: 18.00
// Area: 377557.086442
// Performance: 6796027.55595600

// Cycle: 17.70
// Area: 385259.718435
// Performance: 6819097.01629950

// Cycle: 17.50 *****
// Area: 383806.686438
// Performance: 6716617.01266500

// Cycle: 17.00 
// Area: 397243.325490
// Performance: 6753136.53333000

// Cycle: 15.00 *****
// Area: 421957.368713
// Performance: 6329360.53069500

// Cycle: 14.20
// Area: 444849.653295
// Performance: 6316865.07678900

// Cycle: 14.00
// Area: 452149.185899
// Performance: 6330088.60258600

// Cycle: 13.20
// Area: 479288.073741
// Performance: 6326602.57338120

// Cycle: 13.10
// Area: 478213.142131
// Performance: 6264592.16191610

// Cycle: 13.00  *******************
// Area: 479906.784067
// Performance: 6238788.19287100 * 53000 = 330463812277.063

// Cycle: 12.90
// Area: 487928.145154
// Performance: 6294273.07248660

//12.8 5
// Cycle: 12.80
// Area: 497015.063933
// Performance: 6361792.81834240

// Cycle: 12.70
// Area: 500689.828698
// Performance: 6358760.82446460

// Cycle: 12.50
// Area: 504048.988557
// Performance: 6300612.35696250

// Cycle: 12.00
// Area: 545433.839539
// Performance: 6545206.07446800

// Cycle: 11.50
// Area: 597652.371946
// Performance: 6873002.27737900

//10 XXXXX

// Cycle: 13.00  *******************
// Area: 479906.784067
// Performance: 6238788.19287100 * 53000 = 330463812277.063

//use 2 IP
// Cycle: 13.00
// Area: 1000582.832516
// Performance: 13007576.82270800 *30000 = 390227304660.240

// Cycle: 14.00
// Area: 899042.457369
// Performance: 12586594.40316600 *30000 = 377597832094.980

// Cycle: 15.00
// Area: 805576.565631
// Performance: 12083648.48446500 *30000=  362509454535.950

// Cycle: 16.00
// Area: 747517.782120
// Performance: 11960284.51392000 *30000 = 358808535390.600

// Cycle: 17.00
// Area: 727484.689199
// Performance: 12367239.71638300
