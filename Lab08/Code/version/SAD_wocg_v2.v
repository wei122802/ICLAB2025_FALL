//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2025 ICLAB FALL Course
//   Lab08       : SAD
//   Author      : Ying-Yu (Inyi) Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SAD_wocg.v
//   Module Name : SAD
//   Release version : v1.0
//   Note : Design w/o CG
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SAD(
    //Input signals
    clk,
    rst_n,
    in_valid,
	in_data1,
    T,
    in_data2,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input signed [5:0] in_data1;
input [3:0] T;
input signed [7:0] in_data2;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [91:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter d_model = 'd8;
integer i, j;
//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [7:0] input_cnt;
reg [3:0] cal_cnt;
reg [6:0] output_cnt;
reg [1:0] T_type;
reg input_finish_flag ;

reg signed [7:0] x [0:7] [0:7] ;

reg signed [7:0] w_Q_matrix [0:7] [0:7];
reg signed [7:0] w_K_matrix [0:7] [0:7];
reg signed [7:0] w_V_matrix [0:7] [0:7];


//Q
reg signed [18:0] Q [0:7] [0:7];
wire signed [18:0]  Q_row1_temp,Q_row2_temp,Q_row3_temp,Q_row4_temp,
                    Q_row5_temp,Q_row6_temp,Q_row7_temp,Q_row8_temp;
wire calu_Q = (input_cnt >= 64) && (input_cnt < 72);
wire [2:0] calu_Q_index = input_cnt - 64;

//K
reg signed [18:0] K [0:7] [0:7];
wire signed [18:0] K_row1_temp,K_row2_temp,K_row3_temp,K_row4_temp,
                    K_row5_temp,K_row6_temp,K_row7_temp,K_row8_temp;
wire calu_K = (input_cnt >= 128) && (input_cnt < 136);
wire [2:0] calu_K_index = input_cnt - 128;

//V

reg signed [18:0] V [0:7] [0:7];
wire signed [18:0] V_row1_temp,V_row2_temp,V_row3_temp,V_row4_temp,
                   V_row5_temp,V_row6_temp,V_row7_temp,V_row8_temp;
wire calu_V = input_finish_flag && (cal_cnt < 8);
wire [2:0] calu_V_index = cal_cnt;

wire signed [40:0] A [0:7] [0:7];
reg  signed [40:0] A_reg [0:7] [0:7];

reg signed [39:0] Scale_A [0:7] [0:7];

reg signed [39:0] ReLU_A [0:7] [0:7];

wire signed [61:0] P [0:7] [0:7];
reg  signed [61:0] P_reg [0:7] [0:7];

reg signed [5:0] Y [0:3] [0:3];
reg signed [25:0] Det_y;

reg start_output;

//==============================================//
//                  Counter                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  input_cnt <= 8'd0;
    else if(in_valid)  input_cnt <= input_cnt + 8'd1;
    else input_cnt <= 8'd0;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)  input_finish_flag <= 1'b0;
    else if(input_cnt == 8'd192)  input_finish_flag <= 1'b1;
    else input_finish_flag <= input_finish_flag;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  cal_cnt <= 4'd0;
    else if(input_finish_flag)  cal_cnt <= cal_cnt + 4'd1;
    else cal_cnt <= 4'd0;
end

//==============================================//
//                  input                       //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        T_type <= 2'd0;
    end
    else if(in_valid && (input_cnt == 6'd0)) begin
        case(T)
            4'b0001 : T_type <= 2'b00;
            4'b0100 : T_type <= 2'b01;
            default : T_type <= 2'b10;
        endcase
    end
    else begin
        T_type <= T_type;
    end
end

genvar gen_i, gen_j;
generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    x[gen_i][gen_j] <= 8'd0;
                end
                else if (in_valid) begin
                    case (T_type)
                        2'b00 : 
                            if (input_cnt == gen_i * 8 + gen_j) begin
                                if (input_cnt < 8)
                                    x[gen_i][gen_j] <= in_data2;
                                else
                                    x[gen_i][gen_j] <= 0;
                            end
                        2'b01 : 
                            if (input_cnt == gen_i * 8 + gen_j) begin
                                if (input_cnt < 32)
                                    x[gen_i][gen_j] <= in_data2;
                                else
                                    x[gen_i][gen_j] <= 0;
                            end
                        2'b10 :
                            if (input_cnt == gen_i * 8 + gen_j)
                                x[gen_i][gen_j] <= in_data2;
                    endcase
                end
            end
        end
    end
endgenerate

generate
    //Y
    for (gen_i = 0; gen_i < 4; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 4; gen_j = gen_j + 1) begin 
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    Y[gen_i][gen_j] <= 6'd0;
                end
                else if(in_valid && (input_cnt < 16) && (input_cnt/4 == gen_i) && (input_cnt%4 == gen_j)) begin
                    Y[gen_i][gen_j] <= in_data1;
                end
            end
        end
    end
endgenerate

generate
    //w_Q_matrix
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    w_Q_matrix[gen_i][gen_j] <= 8'd0;
                end
                else if(in_valid && (input_cnt < 64) && (input_cnt/8 == gen_i) && (input_cnt%8 == gen_j)) begin
                    w_Q_matrix[gen_i][gen_j] <= w_Q;
                end
            end
        end
    end
endgenerate
    //w_K_matrix
generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    w_K_matrix[gen_i][gen_j] <= 8'd0;
                end
                else if(in_valid && (input_cnt >= 64) && (input_cnt < 128) && ((input_cnt-64)/8 == gen_i) && ((input_cnt-64)%8 == gen_j)) begin
                    w_K_matrix[gen_i][gen_j] <= w_K;
                end
            end
        end
    end
endgenerate
    //w_V_matrix
generate
    for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    w_V_matrix[gen_i][gen_j] <= 8'd0;
                end
                else if(in_valid && (input_cnt >= 128) && (input_cnt < 192) && ((input_cnt-128)/8 == gen_i) && ((input_cnt-128)%8 == gen_j)) begin
                    w_V_matrix[gen_i][gen_j] <= w_V;
                end
            end
        end
    end
endgenerate
//==============================================//
//                  Calulate   Q                //
//==============================================//

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row1 (
    .in_valid(calu_Q),
    .in1(x[0][0]),
    .in2(x[0][1]),
    .in3(x[0][2]),
    .in4(x[0][3]),
    .in5(x[0][4]),
    .in6(x[0][5]),
    .in7(x[0][6]),
    .in8(x[0][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row1_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row2 (
    .in_valid(calu_Q),
    .in1(x[1][0]),
    .in2(x[1][1]),
    .in3(x[1][2]),
    .in4(x[1][3]),
    .in5(x[1][4]),
    .in6(x[1][5]),
    .in7(x[1][6]),
    .in8(x[1][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row2_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row3 (
    .in_valid(calu_Q),
    .in1(x[2][0]),
    .in2(x[2][1]),
    .in3(x[2][2]),
    .in4(x[2][3]),
    .in5(x[2][4]),
    .in6(x[2][5]),
    .in7(x[2][6]),
    .in8(x[2][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row3_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row4 (
    .in_valid(calu_Q),
    .in1(x[3][0]),
    .in2(x[3][1]),
    .in3(x[3][2]),
    .in4(x[3][3]),
    .in5(x[3][4]),
    .in6(x[3][5]),
    .in7(x[3][6]),
    .in8(x[3][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row4_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row5 (
    .in_valid(calu_Q),
    .in1(x[4][0]),
    .in2(x[4][1]),
    .in3(x[4][2]),
    .in4(x[4][3]),
    .in5(x[4][4]),
    .in6(x[4][5]),
    .in7(x[4][6]),
    .in8(x[4][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row5_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row6 (
    .in_valid(calu_Q),
    .in1(x[5][0]),
    .in2(x[5][1]),
    .in3(x[5][2]),
    .in4(x[5][3]),
    .in5(x[5][4]),
    .in6(x[5][5]),
    .in7(x[5][6]),
    .in8(x[5][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row6_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row7 (
    .in_valid(calu_Q),
    .in1(x[6][0]),
    .in2(x[6][1]),
    .in3(x[6][2]),
    .in4(x[6][3]),
    .in5(x[6][4]),
    .in6(x[6][5]),
    .in7(x[6][6]),
    .in8(x[6][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row7_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q_row8 (
    .in_valid(calu_Q),
    .in1(x[7][0]),
    .in2(x[7][1]),
    .in3(x[7][2]),
    .in4(x[7][3]),
    .in5(x[7][4]),
    .in6(x[7][5]),
    .in7(x[7][6]),
    .in8(x[7][7]),
    .w1(w_Q_matrix[0][calu_Q_index]),
    .w2(w_Q_matrix[1][calu_Q_index]),
    .w3(w_Q_matrix[2][calu_Q_index]),
    .w4(w_Q_matrix[3][calu_Q_index]),
    .w5(w_Q_matrix[4][calu_Q_index]),
    .w6(w_Q_matrix[5][calu_Q_index]),
    .w7(w_Q_matrix[6][calu_Q_index]),
    .w8(w_Q_matrix[7][calu_Q_index]),
    .out(Q_row8_temp)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                Q[i][j] <= 19'd0;
            end
        end
    end
    else if(calu_Q)begin
        case(calu_Q_index)
            3'd0: begin 
                Q[0][0] <= Q_row1_temp;
                Q[1][0] <= Q_row2_temp;
                Q[2][0] <= Q_row3_temp;
                Q[3][0] <= Q_row4_temp;
                Q[4][0] <= Q_row5_temp;
                Q[5][0] <= Q_row6_temp;
                Q[6][0] <= Q_row7_temp;
                Q[7][0] <= Q_row8_temp;
            end
            3'd1: begin
                Q[0][1] <= Q_row1_temp;
                Q[1][1] <= Q_row2_temp;
                Q[2][1] <= Q_row3_temp;
                Q[3][1] <= Q_row4_temp;
                Q[4][1] <= Q_row5_temp;
                Q[5][1] <= Q_row6_temp;
                Q[6][1] <= Q_row7_temp;
                Q[7][1] <= Q_row8_temp;
            end
            3'd2: begin
                Q[0][2] <= Q_row1_temp;
                Q[1][2] <= Q_row2_temp;
                Q[2][2] <= Q_row3_temp;
                Q[3][2] <= Q_row4_temp;
                Q[4][2] <= Q_row5_temp;
                Q[5][2] <= Q_row6_temp;
                Q[6][2] <= Q_row7_temp;
                Q[7][2] <= Q_row8_temp;
            end
            3'd3: begin
                Q[0][3] <= Q_row1_temp;
                Q[1][3] <= Q_row2_temp;
                Q[2][3] <= Q_row3_temp;
                Q[3][3] <= Q_row4_temp;
                Q[4][3] <= Q_row5_temp;
                Q[5][3] <= Q_row6_temp;
                Q[6][3] <= Q_row7_temp;
                Q[7][3] <= Q_row8_temp;
            end
            3'd4: begin
                Q[0][4] <= Q_row1_temp;
                Q[1][4] <= Q_row2_temp;
                Q[2][4] <= Q_row3_temp;
                Q[3][4] <= Q_row4_temp;
                Q[4][4] <= Q_row5_temp;
                Q[5][4] <= Q_row6_temp;
                Q[6][4] <= Q_row7_temp;
                Q[7][4] <= Q_row8_temp;
            end
            3'd5: begin
                Q[0][5] <= Q_row1_temp;
                Q[1][5] <= Q_row2_temp;
                Q[2][5] <= Q_row3_temp;
                Q[3][5] <= Q_row4_temp;
                Q[4][5] <= Q_row5_temp;
                Q[5][5] <= Q_row6_temp;
                Q[6][5] <= Q_row7_temp;
                Q[7][5] <= Q_row8_temp;
            end
            3'd6: begin
                Q[0][6] <= Q_row1_temp;
                Q[1][6] <= Q_row2_temp;
                Q[2][6] <= Q_row3_temp;
                Q[3][6] <= Q_row4_temp;
                Q[4][6] <= Q_row5_temp;
                Q[5][6] <= Q_row6_temp;
                Q[6][6] <= Q_row7_temp;
                Q[7][6] <= Q_row8_temp;
            end
            3'd7: begin
                Q[0][7] <= Q_row1_temp;
                Q[1][7] <= Q_row2_temp;
                Q[2][7] <= Q_row3_temp;
                Q[3][7] <= Q_row4_temp;
                Q[4][7] <= Q_row5_temp;
                Q[5][7] <= Q_row6_temp;
                Q[6][7] <= Q_row7_temp;
                Q[7][7] <= Q_row8_temp;
            end
        endcase
    end
end

//==============================================//
//                  Calulate   K                //
//==============================================//

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row1 (
    .in_valid(calu_K),
    .in1(x[0][0]),
    .in2(x[0][1]),
    .in3(x[0][2]),
    .in4(x[0][3]),
    .in5(x[0][4]),
    .in6(x[0][5]),
    .in7(x[0][6]),
    .in8(x[0][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row1_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row2 (
    .in_valid(calu_K),
    .in1(x[1][0]),
    .in2(x[1][1]),
    .in3(x[1][2]),
    .in4(x[1][3]),
    .in5(x[1][4]),
    .in6(x[1][5]),
    .in7(x[1][6]),
    .in8(x[1][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row2_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row3 (
    .in_valid(calu_K),
    .in1(x[2][0]),
    .in2(x[2][1]),
    .in3(x[2][2]),
    .in4(x[2][3]),
    .in5(x[2][4]),
    .in6(x[2][5]),
    .in7(x[2][6]),
    .in8(x[2][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row3_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row4 (
    .in_valid(calu_K),
    .in1(x[3][0]),
    .in2(x[3][1]),
    .in3(x[3][2]),
    .in4(x[3][3]),
    .in5(x[3][4]),
    .in6(x[3][5]),
    .in7(x[3][6]),
    .in8(x[3][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row4_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row5 (
    .in_valid(calu_K),
    .in1(x[4][0]),
    .in2(x[4][1]),
    .in3(x[4][2]),
    .in4(x[4][3]),
    .in5(x[4][4]),
    .in6(x[4][5]),
    .in7(x[4][6]),
    .in8(x[4][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row5_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row6 (
    .in_valid(calu_K),
    .in1(x[5][0]),
    .in2(x[5][1]),
    .in3(x[5][2]),
    .in4(x[5][3]),
    .in5(x[5][4]),
    .in6(x[5][5]),
    .in7(x[5][6]),
    .in8(x[5][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row6_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row7 (
    .in_valid(calu_K),
    .in1(x[6][0]),
    .in2(x[6][1]),
    .in3(x[6][2]),
    .in4(x[6][3]),
    .in5(x[6][4]),
    .in6(x[6][5]),
    .in7(x[6][6]),
    .in8(x[6][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row7_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_K_row8 (
    .in_valid(calu_K),
    .in1(x[7][0]),
    .in2(x[7][1]),
    .in3(x[7][2]),
    .in4(x[7][3]),
    .in5(x[7][4]),
    .in6(x[7][5]),
    .in7(x[7][6]),
    .in8(x[7][7]),
    .w1(w_K_matrix[0][calu_K_index]),
    .w2(w_K_matrix[1][calu_K_index]),
    .w3(w_K_matrix[2][calu_K_index]),
    .w4(w_K_matrix[3][calu_K_index]),
    .w5(w_K_matrix[4][calu_K_index]),
    .w6(w_K_matrix[5][calu_K_index]),
    .w7(w_K_matrix[6][calu_K_index]),
    .w8(w_K_matrix[7][calu_K_index]),
    .out(K_row8_temp)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                K[i][j] <= 19'd0;
            end
        end
    end
    else if(calu_K)begin
        case(calu_K_index)
            3'd0: begin 
                K[0][0] <= K_row1_temp;
                K[1][0] <= K_row2_temp;
                K[2][0] <= K_row3_temp;
                K[3][0] <= K_row4_temp;
                K[4][0] <= K_row5_temp;
                K[5][0] <= K_row6_temp;
                K[6][0] <= K_row7_temp;
                K[7][0] <= K_row8_temp;
            end
            3'd1: begin
                K[0][1] <= K_row1_temp;
                K[1][1] <= K_row2_temp;
                K[2][1] <= K_row3_temp;
                K[3][1] <= K_row4_temp;
                K[4][1] <= K_row5_temp;
                K[5][1] <= K_row6_temp;
                K[6][1] <= K_row7_temp;
                K[7][1] <= K_row8_temp;
            end
            3'd2: begin
                K[0][2] <= K_row1_temp;
                K[1][2] <= K_row2_temp;
                K[2][2] <= K_row3_temp;
                K[3][2] <= K_row4_temp;
                K[4][2] <= K_row5_temp;
                K[5][2] <= K_row6_temp;
                K[6][2] <= K_row7_temp;
                K[7][2] <= K_row8_temp;
            end
            3'd3: begin
                K[0][3] <= K_row1_temp;
                K[1][3] <= K_row2_temp;
                K[2][3] <= K_row3_temp;
                K[3][3] <= K_row4_temp;
                K[4][3] <= K_row5_temp;
                K[5][3] <= K_row6_temp;
                K[6][3] <= K_row7_temp;
                K[7][3] <= K_row8_temp;
            end
            3'd4: begin
                K[0][4] <= K_row1_temp;
                K[1][4] <= K_row2_temp;
                K[2][4] <= K_row3_temp;
                K[3][4] <= K_row4_temp;
                K[4][4] <= K_row5_temp;
                K[5][4] <= K_row6_temp;
                K[6][4] <= K_row7_temp;
                K[7][4] <= K_row8_temp;
            end
            3'd5: begin
                K[0][5] <= K_row1_temp;
                K[1][5] <= K_row2_temp;
                K[2][5] <= K_row3_temp;
                K[3][5] <= K_row4_temp;
                K[4][5] <= K_row5_temp;
                K[5][5] <= K_row6_temp;
                K[6][5] <= K_row7_temp;
                K[7][5] <= K_row8_temp;
            end
            3'd6: begin
                K[0][6] <= K_row1_temp;
                K[1][6] <= K_row2_temp;
                K[2][6] <= K_row3_temp;
                K[3][6] <= K_row4_temp;
                K[4][6] <= K_row5_temp;
                K[5][6] <= K_row6_temp;
                K[6][6] <= K_row7_temp;
                K[7][6] <= K_row8_temp;
            end
            3'd7: begin
                K[0][7] <= K_row1_temp;
                K[1][7] <= K_row2_temp;
                K[2][7] <= K_row3_temp;
                K[3][7] <= K_row4_temp;
                K[4][7] <= K_row5_temp;
                K[5][7] <= K_row6_temp;
                K[6][7] <= K_row7_temp;
                K[7][7] <= K_row8_temp;
            end
        endcase
    end
end

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row1 (
    .in_valid(calu_V),
    .in1(x[0][0]),
    .in2(x[0][1]),
    .in3(x[0][2]),
    .in4(x[0][3]),
    .in5(x[0][4]),
    .in6(x[0][5]),
    .in7(x[0][6]),
    .in8(x[0][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row1_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row2 (
    .in_valid(calu_V),
    .in1(x[1][0]),
    .in2(x[1][1]),
    .in3(x[1][2]),
    .in4(x[1][3]),
    .in5(x[1][4]),
    .in6(x[1][5]),
    .in7(x[1][6]),
    .in8(x[1][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row2_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row3 (
    .in_valid(calu_V),
    .in1(x[2][0]),
    .in2(x[2][1]),
    .in3(x[2][2]),
    .in4(x[2][3]),
    .in5(x[2][4]),
    .in6(x[2][5]),
    .in7(x[2][6]),
    .in8(x[2][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row3_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row4 (
    .in_valid(calu_V),
    .in1(x[3][0]),
    .in2(x[3][1]),
    .in3(x[3][2]),
    .in4(x[3][3]),
    .in5(x[3][4]),
    .in6(x[3][5]),
    .in7(x[3][6]),
    .in8(x[3][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row4_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row5 (
    .in_valid(calu_V),
    .in1(x[4][0]),
    .in2(x[4][1]),
    .in3(x[4][2]),
    .in4(x[4][3]),
    .in5(x[4][4]),
    .in6(x[4][5]),
    .in7(x[4][6]),
    .in8(x[4][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row5_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row6 (
    .in_valid(calu_V),
    .in1(x[5][0]),
    .in2(x[5][1]),
    .in3(x[5][2]),
    .in4(x[5][3]),
    .in5(x[5][4]),
    .in6(x[5][5]),
    .in7(x[5][6]),
    .in8(x[5][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row6_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row7 (
    .in_valid(calu_V),
    .in1(x[6][0]),
    .in2(x[6][1]),
    .in3(x[6][2]),
    .in4(x[6][3]),
    .in5(x[6][4]),
    .in6(x[6][5]),
    .in7(x[6][6]),
    .in8(x[6][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row7_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_V_row8 (
    .in_valid(calu_V),
    .in1(x[7][0]),
    .in2(x[7][1]),
    .in3(x[7][2]),
    .in4(x[7][3]),
    .in5(x[7][4]),
    .in6(x[7][5]),
    .in7(x[7][6]),
    .in8(x[7][7]),
    .w1(w_V_matrix[0][calu_V_index]),
    .w2(w_V_matrix[1][calu_V_index]),
    .w3(w_V_matrix[2][calu_V_index]),
    .w4(w_V_matrix[3][calu_V_index]),
    .w5(w_V_matrix[4][calu_V_index]),
    .w6(w_V_matrix[5][calu_V_index]),
    .w7(w_V_matrix[6][calu_V_index]),
    .w8(w_V_matrix[7][calu_V_index]),
    .out(V_row8_temp)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                V[i][j] <= 19'd0;
            end
        end
    end
    else if(calu_V)begin
        case(calu_V_index)
            3'd0: begin 
                V[0][0] <= V_row1_temp;
                V[1][0] <= V_row2_temp;
                V[2][0] <= V_row3_temp;
                V[3][0] <= V_row4_temp;
                V[4][0] <= V_row5_temp;
                V[5][0] <= V_row6_temp;
                V[6][0] <= V_row7_temp;
                V[7][0] <= V_row8_temp;
            end
            3'd1: begin
                V[0][1] <= V_row1_temp;
                V[1][1] <= V_row2_temp;
                V[2][1] <= V_row3_temp;
                V[3][1] <= V_row4_temp;
                V[4][1] <= V_row5_temp;
                V[5][1] <= V_row6_temp;
                V[6][1] <= V_row7_temp;
                V[7][1] <= V_row8_temp;
            end
            3'd2: begin
                V[0][2] <= V_row1_temp;
                V[1][2] <= V_row2_temp;
                V[2][2] <= V_row3_temp;
                V[3][2] <= V_row4_temp;
                V[4][2] <= V_row5_temp;
                V[5][2] <= V_row6_temp;
                V[6][2] <= V_row7_temp;
                V[7][2] <= V_row8_temp;
            end
            3'd3: begin
                V[0][3] <= V_row1_temp;
                V[1][3] <= V_row2_temp;
                V[2][3] <= V_row3_temp;
                V[3][3] <= V_row4_temp;
                V[4][3] <= V_row5_temp;
                V[5][3] <= V_row6_temp;
                V[6][3] <= V_row7_temp;
                V[7][3] <= V_row8_temp;
            end
            3'd4: begin
                V[0][4] <= V_row1_temp;
                V[1][4] <= V_row2_temp;
                V[2][4] <= V_row3_temp;
                V[3][4] <= V_row4_temp;
                V[4][4] <= V_row5_temp;
                V[5][4] <= V_row6_temp;
                V[6][4] <= V_row7_temp;
                V[7][4] <= V_row8_temp;
            end
            3'd5: begin
                V[0][5] <= V_row1_temp;
                V[1][5] <= V_row2_temp;
                V[2][5] <= V_row3_temp;
                V[3][5] <= V_row4_temp;
                V[4][5] <= V_row5_temp;
                V[5][5] <= V_row6_temp;
                V[6][5] <= V_row7_temp;
                V[7][5] <= V_row8_temp;
            end
            3'd6: begin
                V[0][6] <= V_row1_temp;
                V[1][6] <= V_row2_temp;
                V[2][6] <= V_row3_temp;
                V[3][6] <= V_row4_temp;
                V[4][6] <= V_row5_temp;
                V[5][6] <= V_row6_temp;
                V[6][6] <= V_row7_temp;
                V[7][6] <= V_row8_temp;
            end
            3'd7: begin
                V[0][7] <= V_row1_temp;
                V[1][7] <= V_row2_temp;
                V[2][7] <= V_row3_temp;
                V[3][7] <= V_row4_temp;
                V[4][7] <= V_row5_temp;
                V[5][7] <= V_row6_temp;
                V[6][7] <= V_row7_temp;
                V[7][7] <= V_row8_temp;
            end
        endcase
    end
end
//==============================================//
//                  Output                      //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
    end
    else if(start_output && (output_cnt>0)) begin
        out_valid <= 1'b1;
    end
    else begin
        out_valid <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data <= 92'd0;
    end
    else if(start_output && (output_cnt>0)) begin
        out_data <= P_reg[(output_cnt-1)/8][(output_cnt-1)%8] * Det_y;
    end
    else begin
        out_data <= 92'd0;
    end
end

endmodule

module MAC_8 #(
    parameter WIDTH_1 = 8 ,
    parameter WIDTH_2 = 8
)
(
    in_valid,
    in1,in2,in3,in4,
    in5,in6,in7,in8,
    w1, w2, w3, w4,
    w5, w6, w7, w8,
    out
);
input in_valid;
input  signed [WIDTH_1-1:0]  in1,in2,in3,in4,
                           in5,in6,in7,in8;
input  signed [WIDTH_2-1:0]  w1, w2, w3, w4,
                           w5, w6, w7, w8;
output signed [(WIDTH_1+WIDTH_2+3)-1:0] out;

assign out = (in_valid)?in1*w1 + in2*w2 + in3*w3 + in4*w4 + in5*w5 + in6*w6 + in7*w7 + in8*w8 :0;

endmodule


module Det3X3
(
    in_valid,
    in1,in2,in3,in4,in5,in6,in7,in8,in9,
    out
);
input signed [5:0] in1,in2,in3,in4,in5,in6,in7,in8,in9;
input in_valid;
output signed [19:0] out;

assign out = (in_valid)? in1*in5*in9 + in2*in6*in7 + in3*in4*in8 - in3*in5*in7 - in2*in4*in9 - in1*in6*in8 : 20'd0;

endmodule