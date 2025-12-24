//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/10
//		Version		: v1.0
//   	File Name   : Poker.v
//   	Module Name : Poker
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module Poker #(parameter IP_WIDTH = 9) (
    // Input signals
    IN_HOLE_CARD_NUM, IN_HOLE_CARD_SUIT, IN_PUB_CARD_NUM, IN_PUB_CARD_SUIT,
    // Output signals
    OUT_WINNER
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*8-1:0]  IN_HOLE_CARD_NUM; //[71:0]
input [IP_WIDTH*4-1:0]  IN_HOLE_CARD_SUIT;//[35:0]
input [19:0]  IN_PUB_CARD_NUM;
input [9:0]  IN_PUB_CARD_SUIT;

output [IP_WIDTH-1:0]  OUT_WINNER;

parameter J = 4'd11;
parameter Q = 4'd12;
parameter K = 4'd13;
parameter A = 4'd14;

parameter CLUB    = 2'd0;
parameter DIAMOND = 2'd1;
parameter HEART   = 2'd2;
parameter SPADE   = 2'd3;
genvar i;
// ===============================================================
// Reg & Wire
// ===============================================================
reg [23:0] score [0:IP_WIDTH-1]; //score = {rank(4), high card(4), 2nd high card(4), other1(4), other2(4), other3(4)}

generate
    for(i=0; i<IP_WIDTH; i=i+1) begin : Player_score
        oneplayerscore player (
            .hole_card_num(IN_HOLE_CARD_NUM[(i+1)*8-1:i*8]), .hole_card_suit(IN_HOLE_CARD_SUIT[(i+1)*4-1:i*4]), 
            .pub_card_num(IN_PUB_CARD_NUM), .pub_card_suit(IN_PUB_CARD_SUIT),
            .score(score[i])
        );
    end
endgenerate

reg [23:0] maxscore;
wire [23:0] max_temp,max_temp1;
generate
    case(IP_WIDTH)
        2: compare compare2 (.a(score[0]), .b(score[1]), .max(maxscore));
        3: begin
            compare compare3_1 (.a(score[0]), .b(score[1]), .max(max_temp));
            compare compare3_2 (.a(max_temp), .b(score[2]), .max(maxscore));
        end
        4: findmax4 findmax4 (.in1(score[0]), .in2(score[1]), .in3(score[2]), .in4(score[3]) , .maxvalue(maxscore));
        5: begin
            findmax4 findmax5_1 (.in1(score[0]), .in2(score[1]), .in3(score[2]), .in4(score[3]) , .maxvalue(max_temp));
            compare compare5 (.a(max_temp), .b(score[4]), .max(maxscore));
        end
        6: begin
            findmax4 findmax6_1 (.in1(score[0]), .in2(score[1]), .in3(score[2]), .in4(score[3]) , .maxvalue(max_temp));
            compare compare6 (.a(score[4]), .b(score[5]), .max(max_temp1));
            compare compare6_1 (.a(max_temp), .b(max_temp1), .max(maxscore));
        end
        7: begin
            findmax4 findmax7_1 (.in1(score[0]), .in2(score[1]), .in3(score[2]), .in4(score[3]) , .maxvalue(max_temp));
            findmax4 findmax7_2 (.in1(score[4]), .in2(score[5]), .in3(score[6]), .in4(24'b0) , .maxvalue(max_temp1));
            compare compare7 (.a(max_temp), .b(max_temp1), .max(maxscore));
        end
        8: begin
            findmax4 findmax8_1 (.in1(score[0]), .in2(score[1]), .in3(score[2]), .in4(score[3]) , .maxvalue(max_temp));
            findmax4 findmax8_2 (.in1(score[4]), .in2(score[5]), .in3(score[6]), .in4(score[7]) , .maxvalue(max_temp1));
            compare compare8 (.a(max_temp), .b(max_temp1), .max(maxscore));
        end
        // 9: 
        default : findmax9 findmax9 (.in1(score[0]), .in2(score[1]), .in3(score[2]), .in4(score[3]),
                            .in5(score[4]), .in6(score[5]), .in7(score[6]), .in8(score[7]), .in9(score[8]), .maxvalue(maxscore));
    endcase
endgenerate

generate
    for(i=0; i<IP_WIDTH; i=i+1) begin : WINNER
        assign OUT_WINNER[i] = (score[i] == maxscore) ? 1'b1 : 1'b0;
    end
endgenerate
// ===============================================================
// Design
// ===============================================================
endmodule


module oneplayerscore(
    hole_card_num,hole_card_suit,pub_card_num,pub_card_suit,score
);
parameter J = 4'd11;
parameter Q = 4'd12;
parameter K = 4'd13;
parameter A = 4'd14;

parameter CLUB    = 2'd0;
parameter DIAMOND = 2'd1;
parameter HEART   = 2'd2;
parameter SPADE   = 2'd3;

input [7:0] hole_card_num;
input [3:0] hole_card_suit;
input [19:0] pub_card_num;
input [9:0] pub_card_suit;
output reg [23:0] score;
//score = {rank(4), high card(4), 2nd high card(4), other1(4), other2(4), other3(4)}
reg [3:0] A_2_cnt [2:14]; //[2 3 4 5 6 7 8 9 10 J Q K A]
wire [3:0] card_num [6:0];
// ===============================================================
// Card Number
// ===============================================================
assign card_num[0] = hole_card_num[3:0];
assign card_num[1] = hole_card_num[7:4];
assign card_num[2] = pub_card_num[3:0];
assign card_num[3] = pub_card_num[7:4];
assign card_num[4] = pub_card_num[11:8];
assign card_num[5] = pub_card_num[15:12];
assign card_num[6] = pub_card_num[19:16];

genvar i ,j;
generate
    for(i=2;i<=14;i=i+1) begin: count_A_to_2
        always @(*) begin
            A_2_cnt[i] = (card_num[0] == i) + (card_num[1] == i) + (card_num[2] == i) +
                         (card_num[3] == i) + (card_num[4] == i) + (card_num[5] == i) + (card_num[6] == i) ;
        end
    end
endgenerate

// reg [3:0] flush_onehot [2:14]; // CLUB DIAMOND HEART SPADE
// generate
//     for(j=2 ; j<=14 ; j=j+1) begin : flush
//         always @(*) begin
//             flush_onehot[ card_num[j] ]
//         end
//     end
// endgenerate

reg [3:0] straight; //0 is no straight, others is straight max
reg [3:0] quads; //0 is no quads, others is quads num
reg [3:0] trips; //0 is no trips, others is trips num
reg [3:0] pairs; //0 is no pairs, others is pairs num

always @ (*) begin
    case(1)  
        (A_2_cnt[10] && A_2_cnt[J] && A_2_cnt[Q] && A_2_cnt[K] && A_2_cnt[A]) : straight = A;
        (A_2_cnt[9]  && A_2_cnt[10]&& A_2_cnt[J] && A_2_cnt[Q] && A_2_cnt[K]) : straight = K;
        (A_2_cnt[8]  && A_2_cnt[9] && A_2_cnt[10]&& A_2_cnt[J] && A_2_cnt[Q]) : straight = Q;
        (A_2_cnt[7]  && A_2_cnt[8] && A_2_cnt[9] && A_2_cnt[10]&& A_2_cnt[J]) : straight = J;
        (A_2_cnt[6]  && A_2_cnt[7] && A_2_cnt[8] && A_2_cnt[9] && A_2_cnt[10]): straight = 4'd10;
        (A_2_cnt[5]  && A_2_cnt[6] && A_2_cnt[7] && A_2_cnt[8] && A_2_cnt[9]) : straight = 4'd9;
        (A_2_cnt[4]  && A_2_cnt[5] && A_2_cnt[6] && A_2_cnt[7] && A_2_cnt[8]) : straight = 4'd8;
        (A_2_cnt[3]  && A_2_cnt[4] && A_2_cnt[5] && A_2_cnt[6] && A_2_cnt[7]) : straight = 4'd7;
        (A_2_cnt[2]  && A_2_cnt[3] && A_2_cnt[4] && A_2_cnt[5] && A_2_cnt[6]) : straight = 4'd6;
        (A_2_cnt[A]  && A_2_cnt[2] && A_2_cnt[3] && A_2_cnt[4] && A_2_cnt[5]) : straight = 4'd5;
        default : straight = 4'b0;  
    endcase
end

always @ (*) begin
    case (1)
        (A_2_cnt[A]==4) : quads = A;
        (A_2_cnt[K]==4) : quads = K;
        (A_2_cnt[Q]==4) : quads = Q;
        (A_2_cnt[J]==4) : quads = J;
        (A_2_cnt[10]==4): quads = 4'd10;
        (A_2_cnt[9]==4) : quads = 4'd9;
        (A_2_cnt[8]==4) : quads = 4'd8;
        (A_2_cnt[7]==4) : quads = 4'd7;
        (A_2_cnt[6]==4) : quads = 4'd6;
        (A_2_cnt[5]==4) : quads = 4'd5;
        (A_2_cnt[4]==4) : quads = 4'd4;
        (A_2_cnt[3]==4) : quads = 4'd3;
        (A_2_cnt[2]==4) : quads = 4'd2;
        default : quads = 4'b0;
    endcase
end

always @ (*) begin
    case (1)
        (A_2_cnt[A]==3) : trips = A;
        (A_2_cnt[K]==3) : trips = K;
        (A_2_cnt[Q]==3) : trips = Q;
        (A_2_cnt[J]==3) : trips = J;
        (A_2_cnt[10]==3): trips = 4'd10;
        (A_2_cnt[9]==3) : trips = 4'd9;
        (A_2_cnt[8]==3) : trips = 4'd8;
        (A_2_cnt[7]==3) : trips = 4'd7;
        (A_2_cnt[6]==3) : trips = 4'd6;
        (A_2_cnt[5]==3) : trips = 4'd5;
        (A_2_cnt[4]==3) : trips = 4'd4;
        (A_2_cnt[3]==3) : trips = 4'd3;
        (A_2_cnt[2]==3) : trips = 4'd2;
        default : trips = 4'b0;
    endcase
end

always @ (*) begin
    case (1)
        (A_2_cnt[A]==2) : pairs = A;
        (A_2_cnt[K]==2) : pairs = K;
        (A_2_cnt[Q]==2) : pairs = Q;
        (A_2_cnt[J]==2) : pairs = J;
        (A_2_cnt[10]==2): pairs = 4'd10;
        (A_2_cnt[9]==2) : pairs = 4'd9;
        (A_2_cnt[8]==2) : pairs = 4'd8;
        (A_2_cnt[7]==2) : pairs = 4'd7;
        (A_2_cnt[6]==2) : pairs = 4'd6;
        (A_2_cnt[5]==2) : pairs = 4'd5;
        (A_2_cnt[4]==2) : pairs = 4'd4;
        (A_2_cnt[3]==2) : pairs = 4'd3;
        (A_2_cnt[2]==2) : pairs = 4'd2;
        default : pairs = 4'b0;
    endcase
end

reg [3:0] pair_2;
always @ (*) begin
    case (1)
        (A_2_cnt[A]==2 && pairs!=A) : pair_2 = A;
        (A_2_cnt[K]==2 && pairs!=K) : pair_2 = K;
        (A_2_cnt[Q]==2 && pairs!=Q) : pair_2 = Q;
        (A_2_cnt[J]==2 && pairs!=J) : pair_2 = J;
        (A_2_cnt[10]==2 && pairs!=10): pair_2 = 4'd10;
        (A_2_cnt[9]==2 && pairs!=9) : pair_2 = 4'd9;
        (A_2_cnt[8]==2 && pairs!=8) : pair_2 = 4'd8;
        (A_2_cnt[7]==2 && pairs!=7) : pair_2 = 4'd7;
        (A_2_cnt[6]==2 && pairs!=6) : pair_2 = 4'd6;
        (A_2_cnt[5]==2 && pairs!=5) : pair_2 = 4'd5;
        (A_2_cnt[4]==2 && pairs!=4) : pair_2 = 4'd4;
        (A_2_cnt[3]==2 && pairs!=3) : pair_2 = 4'd3;
        (A_2_cnt[2]==2 && pairs!=2) : pair_2 = 4'd2;
        default : pair_2 = 4'b0;
    endcase
end

// ===============================================================
// Suit
// ===============================================================
wire [1:0] suit [6:0];
assign suit[0] = hole_card_suit[1:0];
assign suit[1] = hole_card_suit[3:2];
assign suit[2] = pub_card_suit[1:0];
assign suit[3] = pub_card_suit[3:2];
assign suit[4] = pub_card_suit[5:4];
assign suit[5] = pub_card_suit[7:6];
assign suit[6] = pub_card_suit[9:8];

wire [3:0] club_cnt, diamond_cnt, heart_cnt, spade_cnt;
assign club_cnt    = (suit[0] == CLUB) + (suit[1] == CLUB) + (suit[2] == CLUB)  
                    +(suit[3] == CLUB) + (suit[4] == CLUB) + (suit[5] == CLUB)+ (suit[6] == CLUB);

assign diamond_cnt = (suit[0] == DIAMOND) + (suit[1] == DIAMOND) + (suit[2] == DIAMOND)  
                    +(suit[3] == DIAMOND) + (suit[4] == DIAMOND) + (suit[5] == DIAMOND)+ (suit[6] == DIAMOND);

assign heart_cnt   = (suit[0] == HEART) + (suit[1] == HEART) + (suit[2] == HEART)  
                    +(suit[3] == HEART) + (suit[4] == HEART) + (suit[5] == HEART)+ (suit[6] == HEART); 

assign spade_cnt   = (suit[0] == SPADE) + (suit[1] == SPADE) + (suit[2] == SPADE)  
                    +(suit[3] == SPADE) + (suit[4] == SPADE) + (suit[5] == SPADE)+ (suit[6] == SPADE);

wire has_flush;
wire [1:0] flush_suit;

assign has_flush = (club_cnt >= 5) || (diamond_cnt >= 5) || (heart_cnt >= 5) || (spade_cnt >= 5);
assign flush_suit = (club_cnt >= 5) ? CLUB :
                    (diamond_cnt >= 5) ? DIAMOND :
                    (heart_cnt >= 5) ? HEART : SPADE;

reg flush_mask [2:A]; // [2 3 4 5 6 7 8 9 10 J Q K A] suit is flushsuit?
genvar k;
generate
    for (k=2 ; k <= 14 ;k=k+1) begin :flush_mask_loop
        always @(*) begin
            if(has_flush)
                flush_mask[k] = ((card_num[0] == k) && (suit[0] == flush_suit)) ||
                                ((card_num[1] == k) && (suit[1] == flush_suit)) ||
                                ((card_num[2] == k) && (suit[2] == flush_suit)) ||
                                ((card_num[3] == k) && (suit[3] == flush_suit)) ||
                                ((card_num[4] == k) && (suit[4] == flush_suit)) ||
                                ((card_num[5] == k) && (suit[5] == flush_suit)) ||
                                ((card_num[6] == k) && (suit[6] == flush_suit)) ;
            else
                flush_mask[k] = 1'b0;
        end
    end
endgenerate

// reg [2:0] flush_mask [2:A]; // [2 3 4 5 6 7 8 9 10 J Q K A] suit is flushsuit?
// genvar s;
// generate
//     for (s=2 ; s <= A ;s=s+1) begin :flush_mask
//         always @(*) begin
//             if(has_flush)
//                 flush_mask[s] = ((card_num[0] == s) && (suit[0] == flush_suit)) +
//                                 ((card_num[1] == s) && (suit[1] == flush_suit)) +
//                                 ((card_num[2] == s) && (suit[2] == flush_suit)) +
//                                 ((card_num[3] == s) && (suit[3] == flush_suit)) +
//                                 ((card_num[4] == s) && (suit[4] == flush_suit)) +
//                                 ((card_num[5] == s) && (suit[5] == flush_suit)) +
//                                 ((card_num[6] == s) && (suit[6] == flush_suit)) ;
//             else
//                 flush_mask[s] = 1'b0;
//         end
//     end
// endgenerate

// ===============================================================
// Decision rank
// ===============================================================
//score = {rank(4), high card(4), 2nd high card(4), other1(4), other2(4), other3(4)}
reg [3:0] major,minor,other1, other2, other3;
integer m;
always @(*) begin
    case(1)
        (straight == A && flush_mask[A] && flush_mask[K] && flush_mask[Q] && flush_mask[J] && flush_mask[10]) : score = {4'd10, straight ,4'd0,4'd0,4'd0,4'd0}; // Royal Flush
        (straight >0 && flush_mask[straight] && flush_mask[straight-1] && flush_mask[straight-2] && flush_mask[straight-3] && flush_mask[straight-4]) : score = {4'd9, straight ,4'd0,4'd0,4'd0,4'd0}; // Straight Flush
        (quads >0) : begin
            case (1)
                (A_2_cnt[A]>0 && quads!=A) : other1 = A;
                (A_2_cnt[K]>0 && quads!=K) : other1 = K;
                (A_2_cnt[Q]>0 && quads!=Q) : other1 = Q;
                (A_2_cnt[J]>0 && quads!=J) : other1 =  J;
                (A_2_cnt[10]>0 && quads!=10) : other1 = 4'd10;
                (A_2_cnt[9]>0 && quads!=9) : other1 = 4'd9;
                (A_2_cnt[8]>0 && quads!=8) : other1 = 4'd8;
                (A_2_cnt[7]>0 && quads!=7) : other1 = 4'd7;
                (A_2_cnt[6]>0 && quads!=6) : other1 = 4'd6;
                (A_2_cnt[5]>0 && quads!=5) : other1 = 4'd5;
                (A_2_cnt[4]>0 && quads!=4) : other1 = 4'd4;
                (A_2_cnt[3]>0 && quads!=3) : other1 = 4'd3;
                (A_2_cnt[2]>0 && quads!=2) : other1 = 4'd2;
                default : other1 = 4'b0;
            endcase
            score = {4'd8, quads ,other1,4'd0,4'd0,4'd0};
        end 
        (trips >0 && pairs >0 && quads==0 ) : score = {4'd7, trips ,pairs ,4'd0,4'd0,4'd0}; // Full House
        (has_flush) : begin
            case(1)
                (flush_mask[A]) : major = A;
                (flush_mask[K]) : major = K;
                (flush_mask[Q]) : major = Q;
                (flush_mask[J]) : major = J;
                (flush_mask[10]) : major = 4'd10;
                (flush_mask[9]) : major = 4'd9;
                (flush_mask[8]) : major = 4'd8;
                (flush_mask[7]) : major = 4'd7;
                (flush_mask[6]) : major = 4'd6;
                (flush_mask[5]) : major = 4'd5;
                (flush_mask[4]) : major = 4'd4;
                (flush_mask[3]) : major = 4'd3;
                (flush_mask[2]) : major = 4'd2;
                default : major = 4'b0;
            endcase
            // minor
            case(1)
                (flush_mask[K] && major!=K) : minor = K;
                (flush_mask[Q] && major!=Q) : minor = Q;
                (flush_mask[J] && major!=J) : minor = J;
                (flush_mask[10] && major!=10) : minor = 4'd10;
                (flush_mask[9] && major!=9) : minor = 4'd9;
                (flush_mask[8] && major!=8) : minor = 4'd8;
                (flush_mask[7] && major!=7) : minor = 4'd7;
                (flush_mask[6] && major!=6) : minor = 4'd6;
                (flush_mask[5] && major!=5) : minor = 4'd5;
                (flush_mask[4] && major!=4) : minor = 4'd4;
                (flush_mask[3] && major!=3) : minor = 4'd3;
                (flush_mask[2] && major!=2) : minor = 4'd2;
                default : minor = 4'b0;
            endcase
            // other1
            case(1)
                (flush_mask[Q] && major!=Q && minor!=Q) : other1 = Q;
                (flush_mask[J] && major!=J && minor!=J) : other1 = J;
                (flush_mask[10] && major!=10 && minor!=10) : other1 = 4'd10;
                (flush_mask[9] && major!=9 && minor!=9) : other1 = 4'd9;
                (flush_mask[8] && major!=8 && minor!=8) : other1 = 4'd8;
                (flush_mask[7] && major!=7 && minor!=7) : other1 = 4'd7;
                (flush_mask[6] && major!=6 && minor!=6) : other1 = 4'd6;
                (flush_mask[5] && major!=5 && minor!=5) : other1 = 4'd5;
                (flush_mask[4] && major!=4 && minor!=4) : other1 = 4'd4;
                (flush_mask[3] && major!=3 && minor!=3) : other1 = 4'd3;
                (flush_mask[2] && major!=2 && minor!=2) : other1 = 4'd2;
                default : other1 = 4'b0;
            endcase

            // other2
            case(1)
                (flush_mask[J] && major!=J && minor!=J && other1!=J) : other2 = J;
                (flush_mask[10] && major!=10 && minor!=10 && other1!=10) : other2 = 4'd10;
                (flush_mask[9] && major!=9 && minor!=9 && other1!=9) : other2 = 4'd9;
                (flush_mask[8] && major!=8 && minor!=8 && other1!=8) : other2 = 4'd8;
                (flush_mask[7] && major!=7 && minor!=7 && other1!=7) : other2 = 4'd7;
                (flush_mask[6] && major!=6 && minor!=6 && other1!=6) : other2 = 4'd6;
                (flush_mask[5] && major!=5 && minor!=5 && other1!=5) : other2 = 4'd5;
                (flush_mask[4] && major!=4 && minor!=4 && other1!=4) : other2 = 4'd4;
                (flush_mask[3] && major!=3 && minor!=3 && other1!=3) : other2 = 4'd3;
                (flush_mask[2] && major!=2 && minor!=2 && other1!=2) : other2 = 4'd2;
                default : other2 = 4'b0;
            endcase

            //other3
            case(1)
                (flush_mask[10] && major!=10 && minor!=10 && other1!=10 && other2!=10) : other3 = 4'd10;
                (flush_mask[9] && major!=9 && minor!=9 && other1!=9 && other2!=9) : other3 = 4'd9;
                (flush_mask[8] && major!=8 && minor!=8 && other1!=8 && other2!=8) : other3 = 4'd8;
                (flush_mask[7] && major!=7 && minor!=7 && other1!=7 && other2!=7) : other3 = 4'd7;
                (flush_mask[6] && major!=6 && minor!=6 && other1!=6 && other2!=6) : other3 = 4'd6;
                (flush_mask[5] && major!=5 && minor!=5 && other1!=5 && other2!=5) : other3 = 4'd5;
                (flush_mask[4] && major!=4 && minor!=4 && other1!=4 && other2!=4) : other3 = 4'd4;
                (flush_mask[3] && major!=3 && minor!=3 && other1!=3 && other2!=3) : other3 = 4'd3;
                (flush_mask[2] && major!=2 && minor!=2 && other1!=2 && other2!=2) : other3 = 4'd2;
                default : other3 = 4'b0;
            endcase
            score = {4'd6, major ,minor ,other1 ,other2 ,other3};
        end
        (straight >0) : 
        score = (straight == 5) ? {4'd5, 4'd5,4'd0,4'd0,4'd0,4'd0} :{4'd5, straight ,4'd0,4'd0,4'd0,4'd0}; // Straight
            // case(straight)
            //     5 : score = {4'd5, 4'd5,4'd4,4'd3,4'd2,4'd14};
            //     6 : score = {4'd5, 4'd6,4'd5,4'd4,4'd3,4'd2};
            //     7 : score = {4'd5, 4'd7,4'd6,4'd5,4'd4,4'd3};
            //     8 : score = {4'd5, 4'd8,4'd7,4'd6,4'd5,4'd4};
            //     9 : score = {4'd5, 4'd9,4'd8,4'd7,4'd6,4'd5};
            //     10: score = {4'd5,4'd10,4'd9,4'd8,4'd7,4'd6};
            //     J : score = {4'd5, 4'd11,4'd10,4'd9,4'd8,4'd7};
            //     Q : score = {4'd5, 4'd12,4'd11,4'd10,4'd9,4'd8};
            //     K : score = {4'd5, 4'd13,4'd12,4'd11,4'd10,4'd9};
            //     A : score = {4'd5, 4'd14,4'd13,4'd12,4'd11,4'd10};
            //     default : score = 24'b0;
            // endcase
        ( trips>0 ) : begin
            // minor
            case (1)
                (A_2_cnt[A]>0 && trips!=A) : minor = A;
                (A_2_cnt[K]>0 && trips!=K) : minor = K;
                (A_2_cnt[Q]>0 && trips!=Q) : minor = Q;
                (A_2_cnt[J]>0 && trips!=J) : minor =  J;
                (A_2_cnt[10]>0 && trips!=10) : minor = 4'd10;
                (A_2_cnt[9]>0 && trips!=9) : minor = 4'd9;
                (A_2_cnt[8]>0 && trips!=8) : minor = 4'd8;
                (A_2_cnt[7]>0 && trips!=7) : minor = 4'd7;
                (A_2_cnt[6]>0 && trips!=6) : minor = 4'd6;
                (A_2_cnt[5]>0 && trips!=5) : minor = 4'd5;
                (A_2_cnt[4]>0 && trips!=4) : minor = 4'd4;   
                (A_2_cnt[3]>0 && trips!=3) : minor = 4'd3;
                (A_2_cnt[2]>0 && trips!=2) : minor = 4'd2;
                default : minor = 4'b0;
            endcase

            // other1
            case(1) //maybe
                (A_2_cnt[K]>0 && trips!=K && minor!=K) : other1 = K;
                (A_2_cnt[Q]>0 && trips!=Q && minor!=Q) : other1 = Q;
                (A_2_cnt[J]>0 && trips!=J && minor!=J) : other1 = J;
                (A_2_cnt[10]>0 && trips!=10 && minor!=10) : other1 = 4'd10;
                (A_2_cnt[9]>0 && trips!=9 && minor!=9) : other1 = 4'd9;
                (A_2_cnt[8]>0 && trips!=8 && minor!=8) : other1 = 4'd8;
                (A_2_cnt[7]>0 && trips!=7 && minor!=7) : other1 = 4'd7;
                (A_2_cnt[6]>0 && trips!=6 && minor!=6) : other1 = 4'd6;
                (A_2_cnt[5]>0 && trips!=5 && minor!=5) : other1 = 4'd5;
                (A_2_cnt[4]>0 && trips!=4 && minor!=4) : other1 = 4'd4;   
                (A_2_cnt[3]>0 && trips!=3 && minor!=3) : other1 = 4'd3;
                (A_2_cnt[2]>0 && trips!=2 && minor!=2) : other1 = 4'd2;
                default : other1 = 4'b0;
            endcase

            // other2
            // case(1)
            //     (A_2_cnt[Q]>0 && trips!=Q && minor!=Q && other1!=Q) : other2 = Q;
            //     (A_2_cnt[J]>0 && trips!=J && minor!=J && other1!=J) : other2 = J;
            //     (A_2_cnt[10]>0 && trips!=10 && minor!=10 && other1!=10) : other2 = 4'd10;
            //     (A_2_cnt[9]>0 && trips!=9 && minor!=9 && other1!=9) : other2 = 4'd9;
            //     (A_2_cnt[8]>0 && trips!=8 && minor!=8 && other1!=8) : other2 = 4'd8;
            //     (A_2_cnt[7]>0 && trips!=7 && minor!=7 && other1!=7) : other2 = 4'd7;
            //     (A_2_cnt[6]>0 && trips!=6 && minor!=6 && other1!=6) : other2 = 4'd6;
            //     (A_2_cnt[5]>0 && trips!=5 && minor!=5 && other1!=5) : other2 = 4'd5;
            //     (A_2_cnt[4]>0 && trips!=4 && minor!=4 && other1!=4) : other2 = 4'd4;   
            //     (A_2_cnt[3]>0 && trips!=3 && minor!=3 && other1!=3) : other2 = 4'd3;
            //     (A_2_cnt[2]>0 && trips!=2 && minor!=2 && other1!=2) : other2 = 4'd2;
            //     default : other2 = 4'b0;
            // endcase

            // case(1)
            //     (A_2_cnt[J]>0 && trips!=J && minor!=J && other1!=J && other2!=J) : other3 = J;
            //     (A_2_cnt[10]>0 && trips!=10 && minor!=10 && other1!=10 && other2!=10) : other3 = 4'd10;
            //     (A_2_cnt[9]>0 && trips!=9 && minor!=9 && other1!=9 && other2!=9) : other3 = 4'd9;
            //     (A_2_cnt[8]>0 && trips!=8 && minor!=8 && other1!=8 && other2!=8) : other3 = 4'd8;
            //     (A_2_cnt[7]>0 && trips!=7 && minor!=7 && other1!=7 && other2!=7) : other3 = 4'd7;
            //     (A_2_cnt[6]>0 && trips!=6 && minor!=6 && other1!=6 && other2!=6) : other3 = 4'd6;
            //     (A_2_cnt[5]>0 && trips!=5 && minor!=5 && other1!=5 && other2!=5) : other3 = 4'd5;
            //     (A_2_cnt[4]>0 && trips!=4 && minor!=4 && other1!=4 && other2!=4) : other3 = 4'd4;   
            //     (A_2_cnt[3]>0 && trips!=3 && minor!=3 && other1!=3 && other2!=3) : other3 = 4'd3;
            //     (A_2_cnt[2]>0 && trips!=2 && minor!=2 && other1!=2 && other2!=2) : other3 = 4'd2;
            //     default : other3 = 4'b0;
            // endcase
            score = {4'd4, trips ,minor ,other1 ,4'd0 ,4'd0};
            // score = {4'd4, trips ,minor ,other1 ,other2 ,other3};
        end
        (pairs>0 && pair_2 >0) : begin
            // other1
            case (1)
                (A_2_cnt[A]>0 && pairs!=A && pair_2!=A) : other1 = A;
                (A_2_cnt[K]>0 && pairs!=K && pair_2!=K) : other1 = K;
                (A_2_cnt[Q]>0 && pairs!=Q && pair_2!=Q) : other1 = Q;
                (A_2_cnt[J]>0 && pairs!=J && pair_2!=J) : other1 = J;
                (A_2_cnt[10]>0 && pairs!=10 && pair_2!=10) : other1 = 4'd10;
                (A_2_cnt[9]>0 && pairs!=9 && pair_2!=9) : other1 = 4'd9;
                (A_2_cnt[8]>0 && pairs!=8 && pair_2!=8) : other1 = 4'd8;
                (A_2_cnt[7]>0 && pairs!=7 && pair_2!=7) : other1 = 4'd7;
                (A_2_cnt[6]>0 && pairs!=6 && pair_2!=6) : other1 = 4'd6;
                (A_2_cnt[5]>0 && pairs!=5 && pair_2!=5) : other1 = 4'd5;
                (A_2_cnt[4]>0 && pairs!=4 && pair_2!=4) : other1 = 4'd4;
                (A_2_cnt[3]>0 && pairs!=3 && pair_2!=3) : other1 = 4'd3;
                (A_2_cnt[2]>0 && pairs!=2 && pair_2!=2) : other1 = 4'd2;
                default : other1 = 4'b0;
            endcase

            // case(1)
            //     (A_2_cnt[J]>0 && pairs!=J && pair_2!=J && other1!=J) : other2 = J;
            //     (A_2_cnt[10]>0 && pairs!=10 && pair_2!=10 && other1!=10) : other2 = 4'd10;
            //     (A_2_cnt[9]>0 && pairs!=9 && pair_2!=9 && other1!=9) : other2 = 4'd9;
            //     (A_2_cnt[8]>0 && pairs!=8 && pair_2!=8 && other1!=8) : other2 = 4'd8;
            //     (A_2_cnt[7]>0 && pairs!=7 && pair_2!=7 && other1!=7) : other2 = 4'd7;
            //     (A_2_cnt[6]>0 && pairs!=6 && pair_2!=6 && other1!=6) : other2 = 4'd6;
            //     (A_2_cnt[5]>0 && pairs!=5 && pair_2!=5 && other1!=5) : other2 = 4'd5;
            //     (A_2_cnt[4]>0 && pairs!=4 && pair_2!=4 && other1!=4) : other2 = 4'd4;
            //     (A_2_cnt[3]>0 && pairs!=3 && pair_2!=3 && other1!=3) : other2 = 4'd3;
            //     (A_2_cnt[2]>0 && pairs!=2 && pair_2!=2 && other1!=2) : other2 = 4'd2;
            //     default : other2 = 4'b0;
            // endcase

            // case(1)
            //     (A_2_cnt[10]>0 && pairs!=10 && pair_2!=10 && other1!=10 && other2!=10) : other3 = 4'd10;
            //     (A_2_cnt[9]>0 && pairs!=9 && pair_2!=9 && other1!=9 && other2!=9) : other3 = 4'd9;
            //     (A_2_cnt[8]>0 && pairs!=8 && pair_2!=8 && other1!=8 && other2!=8) : other3 = 4'd8;
            //     (A_2_cnt[7]>0 && pairs!=7 && pair_2!=7 && other1!=7 && other2!=7) : other3 = 4'd7;
            //     (A_2_cnt[6]>0 && pairs!=6 && pair_2!=6 && other1!=6 && other2!=6) : other3 = 4'd6;
            //     (A_2_cnt[5]>0 && pairs!=5 && pair_2!=5 && other1!=5 && other2!=5) : other3 = 4'd5;
            //     (A_2_cnt[4]>0 && pairs!=4 && pair_2!=4 && other1!=4 && other2!=4) : other3 = 4'd4;
            //     (A_2_cnt[3]>0 && pairs!=3 && pair_2!=3 && other1!=3 && other2!=3) : other3 = 4'd3;
            //     (A_2_cnt[2]>0 && pairs!=2 && pair_2!=2 && other1!=2 && other2!=2) : other3 = 4'd2;
            //     default : other3 = 4'b0;
            // endcase
            score = {4'd3, pairs ,pair_2 ,other1 ,4'd0 ,4'd0};
        end
        (pairs > 0) : begin
            // minor
            case(1)
                (A_2_cnt[A]>0 && pairs!=A) : minor = A;
                (A_2_cnt[K]>0 && pairs!=K) : minor = K;
                (A_2_cnt[Q]>0 && pairs!=Q) : minor = Q;
                (A_2_cnt[J]>0 && pairs!=J) : minor = J;
                (A_2_cnt[10]>0 && pairs!=10) : minor = 4'd10;
                (A_2_cnt[9]>0 && pairs!=9) : minor = 4'd9;
                (A_2_cnt[8]>0 && pairs!=8) : minor = 4'd8;
                (A_2_cnt[7]>0 && pairs!=7) : minor = 4'd7;
                (A_2_cnt[6]>0 && pairs!=6) : minor = 4'd6;
                (A_2_cnt[5]>0 && pairs!=5) : minor = 4'd5;
                (A_2_cnt[4]>0 && pairs!=4) : minor = 4'd4;
                (A_2_cnt[3]>0 && pairs!=3) : minor = 4'd3;
                (A_2_cnt[2]>0 && pairs!=2) : minor = 4'd2;
                default : minor = 4'b0;
            endcase

            // other1
            case(1) //maybe
                (A_2_cnt[K]>0 && pairs!=K && minor!=K) : other1 = K;
                (A_2_cnt[Q]>0 && pairs!=Q && minor!=Q) : other1 = Q;
                (A_2_cnt[J]>0 && pairs!=J && minor!=J) : other1 = J;
                (A_2_cnt[10]>0 && pairs!=10 && minor!=10) : other1 = 4'd10;
                (A_2_cnt[9]>0 && pairs!=9 && minor!=9) : other1 = 4'd9;
                (A_2_cnt[8]>0 && pairs!=8 && minor!=8) : other1 = 4'd8;
                (A_2_cnt[7]>0 && pairs!=7 && minor!=7) : other1 = 4'd7;
                (A_2_cnt[6]>0 && pairs!=6 && minor!=6) : other1 = 4'd6;
                (A_2_cnt[5]>0 && pairs!=5 && minor!=5) : other1 = 4'd5;
                (A_2_cnt[4]>0 && pairs!=4 && minor!=4) : other1 = 4'd4;
                (A_2_cnt[3]>0 && pairs!=3 && minor!=3) : other1 = 4'd3;
                (A_2_cnt[2]>0 && pairs!=2 && minor!=2) : other1 = 4'd2;
                default : other1 = 4'b0;
            endcase

            // other2
            case(1)
                (A_2_cnt[Q]>0 && pairs!=Q && minor!=Q && other1!=Q) : other2 = Q;
                (A_2_cnt[J]>0 && pairs!=J && minor!=J && other1!=J) : other2 = J;
                (A_2_cnt[10]>0 && pairs!=10 && minor!=10 && other1!=10) : other2 = 4'd10;
                (A_2_cnt[9]>0 && pairs!=9 && minor!=9 && other1!=9) : other2 = 4'd9;
                (A_2_cnt[8]>0 && pairs!=8 && minor!=8 && other1!=8) : other2 = 4'd8;
                (A_2_cnt[7]>0 && pairs!=7 && minor!=7 && other1!=7) : other2 = 4'd7;
                (A_2_cnt[6]>0 && pairs!=6 && minor!=6 && other1!=6) : other2 = 4'd6;
                (A_2_cnt[5]>0 && pairs!=5 && minor!=5 && other1!=5) : other2 = 4'd5;
                (A_2_cnt[4]>0 && pairs!=4 && minor!=4 && other1!=4) : other2 = 4'd4;
                (A_2_cnt[3]>0 && pairs!=3 && minor!=3 && other1!=3) : other2 = 4'd3;
                (A_2_cnt[2]>0 && pairs!=2 && minor!=2 && other1!=2) : other2 = 4'd2;
                default : other2 = 4'b0;
            endcase

            //other3
            // case(1)
            //     (A_2_cnt[10]>0 && pairs!=10 && minor!=10 && other1!=10 && other2!=10) : other3 = 4'd10;
            //     (A_2_cnt[9]>0 && pairs!=9 && minor!=9 && other1!=9 && other2!=9) : other3 = 4'd9;
            //     (A_2_cnt[8]>0 && pairs!=8 && minor!=8 && other1!=8 && other2!=8) : other3 = 4'd8;
            //     (A_2_cnt[7]>0 && pairs!=7 && minor!=7 && other1!=7 && other2!=7) : other3 = 4'd7;
            //     (A_2_cnt[6]>0 && pairs!=6 && minor!=6 && other1!=6 && other2!=6) : other3 = 4'd6;
            //     (A_2_cnt[5]>0 && pairs!=5 && minor!=5 && other1!=5 && other2!=5) : other3 = 4'd5;
            //     (A_2_cnt[4]>0 && pairs!=4 && minor!=4 && other1!=4 && other2!=4) : other3 = 4'd4;
            //     (A_2_cnt[3]>0 && pairs!=3 && minor!=3 && other1!=3 && other2!=3) : other3 = 4'd3;
            //     (A_2_cnt[2]>0 && pairs!=2 && minor!=2 && other1!=2 && other2!=2) : other3 = 4'd2;
            //     default : other3 = 4'b0;
            // endcase
            score = {4'd2, pairs ,minor ,other1 ,other2 ,4'd0};
        end
        default : begin
          //major
            case(1)
                (A_2_cnt[A]>0) : major = A;
                (A_2_cnt[K]>0) : major = K;
                (A_2_cnt[Q]>0) : major = Q;
                (A_2_cnt[J]>0) : major = J;
                (A_2_cnt[10]>0) : major = 4'd10;
                (A_2_cnt[9]>0) : major = 4'd9;
                (A_2_cnt[8]>0) : major = 4'd8;
                (A_2_cnt[7]>0) : major = 4'd7;
                (A_2_cnt[6]>0) : major = 4'd6;
                (A_2_cnt[5]>0) : major = 4'd5;
                (A_2_cnt[4]>0) : major = 4'd4;
                (A_2_cnt[3]>0) : major = 4'd3;
                (A_2_cnt[2]>0) : major = 4'd2;
                default : major = 4'b0;
            endcase

            // minor
            case(1)
                (A_2_cnt[K]>0 && major!=K) : minor = K;
                (A_2_cnt[Q]>0 && major!=Q) : minor = Q;
                (A_2_cnt[J]>0 && major!=J) : minor = J;
                (A_2_cnt[10]>0 && major!=10) : minor = 4'd10;
                (A_2_cnt[9]>0 && major!=9) : minor = 4'd9;
                (A_2_cnt[8]>0 && major!=8) : minor = 4'd8;
                (A_2_cnt[7]>0 && major!=7) : minor = 4'd7;
                (A_2_cnt[6]>0 && major!=6) : minor = 4'd6;
                (A_2_cnt[5]>0 && major!=5) : minor = 4'd5;
                (A_2_cnt[4]>0 && major!=4) : minor = 4'd4;
                (A_2_cnt[3]>0 && major!=3) : minor = 4'd3;
                (A_2_cnt[2]>0 && major!=2) : minor = 4'd2;
                default : minor = 4'b0;
            endcase

            // other1
            case(1)
                (A_2_cnt[Q]>0 && major!=Q && minor!=Q) : other1 = Q;
                (A_2_cnt[J]>0 && major!=J && minor!=J) : other1 = J;
                (A_2_cnt[10]>0 && major!=10 && minor!=10) : other1 = 4'd10;
                (A_2_cnt[9]>0 && major!=9 && minor!=9) : other1 = 4'd9;
                (A_2_cnt[8]>0 && major!=8 && minor!=8) : other1 = 4'd8;
                (A_2_cnt[7]>0 && major!=7 && minor!=7) : other1 = 4'd7;
                (A_2_cnt[6]>0 && major!=6 && minor!=6) : other1 = 4'd6;
                (A_2_cnt[5]>0 && major!=5 && minor!=5) : other1 = 4'd5;
                (A_2_cnt[4]>0 && major!=4 && minor!=4) : other1 = 4'd4;
                (A_2_cnt[3]>0 && major!=3 && minor!=3) : other1 = 4'd3;
                (A_2_cnt[2]>0 && major!=2 && minor!=2) : other1 = 4'd2;
                default : other1 = 4'b0;
            endcase

            // other2
            case(1)
                (A_2_cnt[J]>0 && major!=J && minor!=J && other1!=J) : other2 = J;
                (A_2_cnt[10]>0 && major!=10 && minor!=10 && other1!=10) : other2 = 4'd10;
                (A_2_cnt[9]>0 && major!=9 && minor!=9 && other1!=9) : other2 = 4'd9;
                (A_2_cnt[8]>0 && major!=8 && minor!=8 && other1!=8) : other2 = 4'd8;
                (A_2_cnt[7]>0 && major!=7 && minor!=7 && other1!=7) : other2 = 4'd7;
                (A_2_cnt[6]>0 && major!=6 && minor!=6 && other1!=6) : other2 = 4'd6;
                (A_2_cnt[5]>0 && major!=5 && minor!=5 && other1!=5) : other2 = 4'd5;
                (A_2_cnt[4]>0 && major!=4 && minor!=4 && other1!=4) : other2 = 4'd4;
                (A_2_cnt[3]>0 && major!=3 && minor!=3 && other1!=3) : other2 = 4'd3;
                (A_2_cnt[2]>0 && major!=2 && minor!=2 && other1!=2) : other2 = 4'd2;
                default : other2 = 4'b0;
            endcase

            //other3
            case(1)
                (A_2_cnt[10]>0 && major!=10 && minor!=10 && other1!=10 && other2!=10) : other3 = 4'd10;
                (A_2_cnt[9]>0 && major!=9 && minor!=9 && other1!=9 && other2!=9) : other3 = 4'd9;
                (A_2_cnt[8]>0 && major!=8 && minor!=8 && other1!=8 && other2!=8) : other3 = 4'd8;
                (A_2_cnt[7]>0 && major!=7 && minor!=7 && other1!=7 && other2!=7) : other3 = 4'd7;
                (A_2_cnt[6]>0 && major!=6 && minor!=6 && other1!=6 && other2!=6) : other3 = 4'd6;
                (A_2_cnt[5]>0 && major!=5 && minor!=5 && other1!=5 && other2!=5) : other3 = 4'd5;
                (A_2_cnt[4]>0 && major!=4 && minor!=4 && other1!=4 && other2!=4) : other3 = 4'd4;
                (A_2_cnt[3]>0 && major!=3 && minor!=3 && other1!=3 && other2!=3) : other3 = 4'd3;
                (A_2_cnt[2]>0 && major!=2 && minor!=2 && other1!=2 && other2!=2) : other3 = 4'd2;
                default : other3 = 4'b0;
            endcase
            score = {4'd1, major ,minor ,other1 ,other2 ,other3};
        end
    endcase
end

endmodule

module findmax9 (
    in1,in2,in3,in4,in5,in6,in7,in8,in9,maxvalue
);

input [23:0] in1,in2,in3,in4,in5,in6,in7,in8,in9;
output[23:0] maxvalue;

wire [23:0] max13,max57,max9;

findmax4 f1( .in1(in1)  , .in2(in2) ,  .in3(in3) , .in4(in4) , .maxvalue(max13) ); 
findmax4 f2( .in1(in5)  , .in2(in6) ,  .in3(in7) , .in4(in8) , .maxvalue(max57) );
compare c1 ( .in1(max13), .in2(max57), .max(max9));

compare c2( .in1(max9),.in2(in9),.max(maxvalue) );

endmodule

module findmax4(
    in1,in2,in3,in4,maxvalue
);
input [23:0] in1,in2,in3,in4;
output[23:0] maxvalue;

wire [23:0] max12,max34,max13;

compare c1(.in1 (in1),.in2(in2),.max(max12));
compare c2(.in1 (in3),.in2(in4),.max(max34));

compare c3(.in1 (max12),.in2(max34),.max(maxvalue));

endmodule

module compare(
    in1,in2,
    max
);
input [23:0] in1,in2;
output reg [23:0] max;

always @(*) begin
    if(in1 >= in2) max = in1;
    else max = in2;
end

endmodule


