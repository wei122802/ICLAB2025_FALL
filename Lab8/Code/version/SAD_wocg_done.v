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
reg [6:0] output_cnt;
reg [1:0] T_type;
reg input_finish_flag ;
reg start_output;

reg signed [7:0] x [0:7] [0:7] ;

reg signed [7:0] w_Q_matrix [0:7] [0:7];
reg signed [7:0] w_K_matrix [0:7] [0:7];
reg signed [7:0] w_V_matrix [0:7] [0:7];

//Q
reg signed [18:0] Q [0:7] [0:7];
wire signed [18:0]  KQV_row1_temp,KQV_row2_temp,KQV_row3_temp,KQV_row4_temp,
                    KQV_row5_temp,KQV_row6_temp,KQV_row7_temp,KQV_row8_temp;

wire calu_Q = (input_cnt >= 64) && (input_cnt < 72);
wire [2:0] calu_Q_index = (calu_Q)? input_cnt - 64 :0;

//K
reg signed [18:0] K [0:7] [0:7];

wire calu_K = (input_cnt >= 121) && (input_cnt < 129);
wire [2:0] calu_K_index = (calu_K)? input_cnt - 121 :0;

//V
reg signed [18:0] V [0:7] [0:7];

wire calu_V = (input_cnt >= 185) && (input_cnt < 193);
wire [2:0] calu_V_index = (calu_V)? input_cnt-185 :0;


reg signed [40:0] A [0:7] [0:7]; // /3
wire signed [40:0] A_temp;
wire calu_A = (input_cnt >= 129) && (input_cnt < 193);
wire [5:0] calu_A_index = (calu_A)? input_cnt - 129 :0;

// reg signed [39:0] Scale_A [0:7] [0:7];

reg signed [39:0] ReLU_A [0:7] [0:7];

//P
// reg signed [61:0] P [0:7] [0:7];
wire calu_P = input_finish_flag || start_output ;
reg [5:0] calu_P_index ;
wire signed [61:0] P_temp;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)      calu_P_index <= 6'd0;
    else if(calu_P) calu_P_index <= calu_P_index+1;
    else            calu_P_index <= 6'd0;
end

reg signed [5:0] Y [0:3] [0:3];
reg signed [30:0] Det_y;

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
    else if(input_cnt == 8'd190)  input_finish_flag <= 1'b1;
    else input_finish_flag <= 0;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)  start_output <= 1'b0;
    else 
        case(1)
            (input_finish_flag) : start_output <= 1'b1;
            ((output_cnt == 7'd7 )&& (T_type == 2'b00)) : start_output <= 1'b0;
            ((output_cnt == 7'd31) && (T_type == 2'b01)) : start_output <= 1'b0;
            ((output_cnt == 7'd63 )&& (T_type == 2'b10)) : start_output <= 1'b0;
            default : start_output <= start_output;
        endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  output_cnt <= 7'd0;
    else if(start_output) 
        output_cnt <= output_cnt + 7'd1;
    else output_cnt <= 7'd0;
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
                //reset x
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
//                 Calulate   KQV               //
//==============================================//

wire calu_invalid = calu_Q || calu_K || calu_V ;

reg signed [7:0] MAC_select [0:7];
// reg signed [39:0] MAC_in [0:7];

always @(*) begin
    for(i=0;i<8;i=i+1) begin
        MAC_select[i] = 8'd0;
    end
    case(1)
        calu_Q : begin
            MAC_select[0] = w_Q_matrix[0][calu_Q_index];
            MAC_select[1] = w_Q_matrix[1][calu_Q_index];
            MAC_select[2] = w_Q_matrix[2][calu_Q_index];
            MAC_select[3] = w_Q_matrix[3][calu_Q_index];
            MAC_select[4] = w_Q_matrix[4][calu_Q_index];
            MAC_select[5] = w_Q_matrix[5][calu_Q_index];
            MAC_select[6] = w_Q_matrix[6][calu_Q_index];
            MAC_select[7] = w_Q_matrix[7][calu_Q_index];
        end
        calu_K : begin
            MAC_select[0] = w_K_matrix[0][calu_K_index];
            MAC_select[1] = w_K_matrix[1][calu_K_index];
            MAC_select[2] = w_K_matrix[2][calu_K_index];
            MAC_select[3] = w_K_matrix[3][calu_K_index];
            MAC_select[4] = w_K_matrix[4][calu_K_index];
            MAC_select[5] = w_K_matrix[5][calu_K_index];
            MAC_select[6] = w_K_matrix[6][calu_K_index];
            MAC_select[7] = w_K_matrix[7][calu_K_index];
        end
        calu_V : begin
            MAC_select[0] = w_V_matrix[0][calu_V_index];
            MAC_select[1] = w_V_matrix[1][calu_V_index];
            MAC_select[2] = w_V_matrix[2][calu_V_index];
            MAC_select[3] = w_V_matrix[3][calu_V_index];
            MAC_select[4] = w_V_matrix[4][calu_V_index];
            MAC_select[5] = w_V_matrix[5][calu_V_index];
            MAC_select[6] = w_V_matrix[6][calu_V_index];
            MAC_select[7] = w_V_matrix[7][calu_V_index];
        end
        // calu_A : begin
        //     MAC_select[0] = K[0][calu_A_index];
        //     MAC_select[1] = K[1][calu_A_index];
        //     MAC_select[2] = K[2][calu_A_index];
        //     MAC_select[3] = K[3][calu_A_index];
        //     MAC_select[4] = K[4][calu_A_index];
        //     MAC_select[5] = K[5][calu_A_index];
        //     MAC_select[6] = K[6][calu_A_index];
        //     MAC_select[7] = K[7][calu_A_index];
        // end
        // calu_P : begin
        //     MAC_select[0] = V[0][calu_P_index];
        //     MAC_select[1] = V[1][calu_P_index];
        //     MAC_select[2] = V[2][calu_P_index];
        //     MAC_select[3] = V[3][calu_P_index];
        //     MAC_select[4] = V[4][calu_P_index];
        //     MAC_select[5] = V[5][calu_P_index];
        //     MAC_select[6] = V[6][calu_P_index];
        //     MAC_select[7] = V[7][calu_P_index];
        // end
    endcase
end

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row1 (
    .in_valid(calu_invalid),
    .in1(x[0][0]),
    .in2(x[0][1]),
    .in3(x[0][2]),
    .in4(x[0][3]),
    .in5(x[0][4]),
    .in6(x[0][5]),
    .in7(x[0][6]),
    .in8(x[0][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row1_temp)
);  

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row2 (
    .in_valid(calu_invalid),
    .in1(x[1][0]),
    .in2(x[1][1]),
    .in3(x[1][2]),
    .in4(x[1][3]),
    .in5(x[1][4]),
    .in6(x[1][5]),
    .in7(x[1][6]),
    .in8(x[1][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row2_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row3 (
    .in_valid(calu_invalid),
    .in1(x[2][0]),
    .in2(x[2][1]),
    .in3(x[2][2]),
    .in4(x[2][3]),
    .in5(x[2][4]),
    .in6(x[2][5]),
    .in7(x[2][6]),
    .in8(x[2][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row3_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row4 (
    .in_valid(calu_invalid),
    .in1(x[3][0]),
    .in2(x[3][1]),
    .in3(x[3][2]),
    .in4(x[3][3]),
    .in5(x[3][4]),
    .in6(x[3][5]),
    .in7(x[3][6]),
    .in8(x[3][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row4_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row5 (
    .in_valid(calu_invalid),
    .in1(x[4][0]),
    .in2(x[4][1]),
    .in3(x[4][2]),
    .in4(x[4][3]),
    .in5(x[4][4]),
    .in6(x[4][5]),
    .in7(x[4][6]),
    .in8(x[4][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row5_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row6 (
    .in_valid(calu_invalid),
    .in1(x[5][0]),
    .in2(x[5][1]),
    .in3(x[5][2]),
    .in4(x[5][3]),
    .in5(x[5][4]),
    .in6(x[5][5]),
    .in7(x[5][6]),
    .in8(x[5][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row6_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row7 (
    .in_valid(calu_invalid),
    .in1(x[6][0]),
    .in2(x[6][1]),
    .in3(x[6][2]),
    .in4(x[6][3]),
    .in5(x[6][4]),
    .in6(x[6][5]),
    .in7(x[6][6]),
    .in8(x[6][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row7_temp)
);

MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_KQV_row8 (
    .in_valid(calu_invalid),
    .in1(x[7][0]),
    .in2(x[7][1]),
    .in3(x[7][2]),
    .in4(x[7][3]),
    .in5(x[7][4]),
    .in6(x[7][5]),
    .in7(x[7][6]),
    .in8(x[7][7]),
    .w1(MAC_select[0]),
    .w2(MAC_select[1]),
    .w3(MAC_select[2]),
    .w4(MAC_select[3]),
    .w5(MAC_select[4]),
    .w6(MAC_select[5]),
    .w7(MAC_select[6]),
    .w8(MAC_select[7]),
    .out(KQV_row8_temp)
);
//Q
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
                Q[0][0] <= KQV_row1_temp;
                Q[1][0] <= KQV_row2_temp;
                Q[2][0] <= KQV_row3_temp;
                Q[3][0] <= KQV_row4_temp;
                Q[4][0] <= KQV_row5_temp;
                Q[5][0] <= KQV_row6_temp;
                Q[6][0] <= KQV_row7_temp;
                Q[7][0] <= KQV_row8_temp;
            end
            3'd1: begin
                Q[0][1] <= KQV_row1_temp;
                Q[1][1] <= KQV_row2_temp;
                Q[2][1] <= KQV_row3_temp;
                Q[3][1] <= KQV_row4_temp;
                Q[4][1] <= KQV_row5_temp;
                Q[5][1] <= KQV_row6_temp;
                Q[6][1] <= KQV_row7_temp;
                Q[7][1] <= KQV_row8_temp;
            end
            3'd2: begin
                Q[0][2] <= KQV_row1_temp;
                Q[1][2] <= KQV_row2_temp;
                Q[2][2] <= KQV_row3_temp;
                Q[3][2] <= KQV_row4_temp;
                Q[4][2] <= KQV_row5_temp;
                Q[5][2] <= KQV_row6_temp;
                Q[6][2] <= KQV_row7_temp;
                Q[7][2] <= KQV_row8_temp;
            end
            3'd3: begin
                Q[0][3] <= KQV_row1_temp;
                Q[1][3] <= KQV_row2_temp;
                Q[2][3] <= KQV_row3_temp;
                Q[3][3] <= KQV_row4_temp;
                Q[4][3] <= KQV_row5_temp;
                Q[5][3] <= KQV_row6_temp;
                Q[6][3] <= KQV_row7_temp;
                Q[7][3] <= KQV_row8_temp;
            end
            3'd4: begin
                Q[0][4] <= KQV_row1_temp;
                Q[1][4] <= KQV_row2_temp;
                Q[2][4] <= KQV_row3_temp;
                Q[3][4] <= KQV_row4_temp;
                Q[4][4] <= KQV_row5_temp;
                Q[5][4] <= KQV_row6_temp;
                Q[6][4] <= KQV_row7_temp;
                Q[7][4] <= KQV_row8_temp;
            end
            3'd5: begin
                Q[0][5] <= KQV_row1_temp;
                Q[1][5] <= KQV_row2_temp;
                Q[2][5] <= KQV_row3_temp;
                Q[3][5] <= KQV_row4_temp;
                Q[4][5] <= KQV_row5_temp;
                Q[5][5] <= KQV_row6_temp;
                Q[6][5] <= KQV_row7_temp;
                Q[7][5] <= KQV_row8_temp;
            end
            3'd6: begin
                Q[0][6] <= KQV_row1_temp;
                Q[1][6] <= KQV_row2_temp;
                Q[2][6] <= KQV_row3_temp;
                Q[3][6] <= KQV_row4_temp;
                Q[4][6] <= KQV_row5_temp;
                Q[5][6] <= KQV_row6_temp;
                Q[6][6] <= KQV_row7_temp;
                Q[7][6] <= KQV_row8_temp;
            end
            3'd7: begin
                Q[0][7] <= KQV_row1_temp;
                Q[1][7] <= KQV_row2_temp;
                Q[2][7] <= KQV_row3_temp;
                Q[3][7] <= KQV_row4_temp;
                Q[4][7] <= KQV_row5_temp;
                Q[5][7] <= KQV_row6_temp;
                Q[6][7] <= KQV_row7_temp;
                Q[7][7] <= KQV_row8_temp;
            end
        endcase
    end
end
//K
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
                K[0][0] <= KQV_row1_temp;
                K[1][0] <= KQV_row2_temp;
                K[2][0] <= KQV_row3_temp;
                K[3][0] <= KQV_row4_temp;
                K[4][0] <= KQV_row5_temp;
                K[5][0] <= KQV_row6_temp;
                K[6][0] <= KQV_row7_temp;
                K[7][0] <= KQV_row8_temp;
            end
            3'd1: begin
                K[0][1] <= KQV_row1_temp;
                K[1][1] <= KQV_row2_temp;
                K[2][1] <= KQV_row3_temp;
                K[3][1] <= KQV_row4_temp;
                K[4][1] <= KQV_row5_temp;
                K[5][1] <= KQV_row6_temp;
                K[6][1] <= KQV_row7_temp;
                K[7][1] <= KQV_row8_temp;
            end
            3'd2: begin
                K[0][2] <= KQV_row1_temp;
                K[1][2] <= KQV_row2_temp;
                K[2][2] <= KQV_row3_temp;
                K[3][2] <= KQV_row4_temp;
                K[4][2] <= KQV_row5_temp;
                K[5][2] <= KQV_row6_temp;
                K[6][2] <= KQV_row7_temp;
                K[7][2] <= KQV_row8_temp;
            end
            3'd3: begin
                K[0][3] <= KQV_row1_temp;
                K[1][3] <= KQV_row2_temp;
                K[2][3] <= KQV_row3_temp;
                K[3][3] <= KQV_row4_temp;
                K[4][3] <= KQV_row5_temp;
                K[5][3] <= KQV_row6_temp;
                K[6][3] <= KQV_row7_temp;
                K[7][3] <= KQV_row8_temp;
            end
            3'd4: begin
                K[0][4] <= KQV_row1_temp;
                K[1][4] <= KQV_row2_temp;
                K[2][4] <= KQV_row3_temp;
                K[3][4] <= KQV_row4_temp;
                K[4][4] <= KQV_row5_temp;
                K[5][4] <= KQV_row6_temp;
                K[6][4] <= KQV_row7_temp;
                K[7][4] <= KQV_row8_temp;
            end
            3'd5: begin
                K[0][5] <= KQV_row1_temp;
                K[1][5] <= KQV_row2_temp;
                K[2][5] <= KQV_row3_temp;
                K[3][5] <= KQV_row4_temp;
                K[4][5] <= KQV_row5_temp;
                K[5][5] <= KQV_row6_temp;
                K[6][5] <= KQV_row7_temp;
                K[7][5] <= KQV_row8_temp;
            end
            3'd6: begin
                K[0][6] <= KQV_row1_temp;
                K[1][6] <= KQV_row2_temp;
                K[2][6] <= KQV_row3_temp;
                K[3][6] <= KQV_row4_temp;
                K[4][6] <= KQV_row5_temp;
                K[5][6] <= KQV_row6_temp;
                K[6][6] <= KQV_row7_temp;
                K[7][6] <= KQV_row8_temp;
            end
            3'd7: begin
                K[0][7] <= KQV_row1_temp;
                K[1][7] <= KQV_row2_temp;
                K[2][7] <= KQV_row3_temp;
                K[3][7] <= KQV_row4_temp;
                K[4][7] <= KQV_row5_temp;
                K[5][7] <= KQV_row6_temp;
                K[6][7] <= KQV_row7_temp;
                K[7][7] <= KQV_row8_temp;
            end
        endcase
    end
end
//V
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
                V[0][0] <= KQV_row1_temp;
                V[1][0] <= KQV_row2_temp;
                V[2][0] <= KQV_row3_temp;
                V[3][0] <= KQV_row4_temp;
                V[4][0] <= KQV_row5_temp;
                V[5][0] <= KQV_row6_temp;
                V[6][0] <= KQV_row7_temp;
                V[7][0] <= KQV_row8_temp;
            end
            3'd1: begin
                V[0][1] <= KQV_row1_temp;
                V[1][1] <= KQV_row2_temp;
                V[2][1] <= KQV_row3_temp;
                V[3][1] <= KQV_row4_temp;
                V[4][1] <= KQV_row5_temp;
                V[5][1] <= KQV_row6_temp;
                V[6][1] <= KQV_row7_temp;
                V[7][1] <= KQV_row8_temp;
            end
            3'd2: begin
                V[0][2] <= KQV_row1_temp;
                V[1][2] <= KQV_row2_temp;
                V[2][2] <= KQV_row3_temp;
                V[3][2] <= KQV_row4_temp;
                V[4][2] <= KQV_row5_temp;
                V[5][2] <= KQV_row6_temp;
                V[6][2] <= KQV_row7_temp;
                V[7][2] <= KQV_row8_temp;
            end
            3'd3: begin
                V[0][3] <= KQV_row1_temp;
                V[1][3] <= KQV_row2_temp;
                V[2][3] <= KQV_row3_temp;
                V[3][3] <= KQV_row4_temp;
                V[4][3] <= KQV_row5_temp;
                V[5][3] <= KQV_row6_temp;
                V[6][3] <= KQV_row7_temp;
                V[7][3] <= KQV_row8_temp;
            end
            3'd4: begin
                V[0][4] <= KQV_row1_temp;
                V[1][4] <= KQV_row2_temp;
                V[2][4] <= KQV_row3_temp;
                V[3][4] <= KQV_row4_temp;
                V[4][4] <= KQV_row5_temp;
                V[5][4] <= KQV_row6_temp;
                V[6][4] <= KQV_row7_temp;
                V[7][4] <= KQV_row8_temp;
            end
            3'd5: begin
                V[0][5] <= KQV_row1_temp;
                V[1][5] <= KQV_row2_temp;
                V[2][5] <= KQV_row3_temp;
                V[3][5] <= KQV_row4_temp;
                V[4][5] <= KQV_row5_temp;
                V[5][5] <= KQV_row6_temp;
                V[6][5] <= KQV_row7_temp;
                V[7][5] <= KQV_row8_temp;
            end
            3'd6: begin
                V[0][6] <= KQV_row1_temp;
                V[1][6] <= KQV_row2_temp;
                V[2][6] <= KQV_row3_temp;
                V[3][6] <= KQV_row4_temp;
                V[4][6] <= KQV_row5_temp;
                V[5][6] <= KQV_row6_temp;
                V[6][6] <= KQV_row7_temp;
                V[7][6] <= KQV_row8_temp;
            end
            3'd7: begin
                V[0][7] <= KQV_row1_temp;
                V[1][7] <= KQV_row2_temp;
                V[2][7] <= KQV_row3_temp;
                V[3][7] <= KQV_row4_temp;
                V[4][7] <= KQV_row5_temp;
                V[5][7] <= KQV_row6_temp;
                V[6][7] <= KQV_row7_temp;
                V[7][7] <= KQV_row8_temp;
            end
        endcase
    end
end


//==============================================//
//                  Calulate   A                //
//==============================================//
//A

MAC_8 #(.WIDTH_1(19) , .WIDTH_2(19))  MAC_A (
    .in_valid(calu_A),
    .in1(Q[calu_A_index/8][0]),
    .in2(Q[calu_A_index/8][1]),
    .in3(Q[calu_A_index/8][2]),
    .in4(Q[calu_A_index/8][3]),
    .in5(Q[calu_A_index/8][4]),
    .in6(Q[calu_A_index/8][5]),
    .in7(Q[calu_A_index/8][6]),
    .in8(Q[calu_A_index/8][7]),
    .w1 (K[calu_A_index%8][0]),
    .w2 (K[calu_A_index%8][1]),
    .w3 (K[calu_A_index%8][2]),
    .w4 (K[calu_A_index%8][3]),
    .w5 (K[calu_A_index%8][4]),
    .w6 (K[calu_A_index%8][5]),
    .w7 (K[calu_A_index%8][6]),
    .w8 (K[calu_A_index%8][7]),
    .out(A_temp)
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                A[i][j] <= 19'd0;
            end
        end
    end
    else if(calu_A)begin
        A[calu_A_index/8][calu_A_index%8] <= A_temp / 3;
    end
end

always @(*) begin
    for(i=0;i<8;i=i+1) begin
        for(j=0;j<8;j=j+1) begin
            ReLU_A[i][j] = (A[i][j]>0) ? A[i][j] : 40'd0 ;
        end
    end
end

//ReLU
//==============================================//
//                  Calulate   P                //
//==============================================//
//P

MAC_8 #(.WIDTH_1(40) , .WIDTH_2(19))  MAC_P (
    .in_valid(calu_P),
    .in1(ReLU_A[calu_P_index/8][0]),
    .in2(ReLU_A[calu_P_index/8][1]),
    .in3(ReLU_A[calu_P_index/8][2]),
    .in4(ReLU_A[calu_P_index/8][3]),
    .in5(ReLU_A[calu_P_index/8][4]),
    .in6(ReLU_A[calu_P_index/8][5]),
    .in7(ReLU_A[calu_P_index/8][6]),
    .in8(ReLU_A[calu_P_index/8][7]),
    .w1 (V[0][calu_P_index%8]),
    .w2 (V[1][calu_P_index%8]),
    .w3 (V[2][calu_P_index%8]),
    .w4 (V[3][calu_P_index%8]),
    .w5 (V[4][calu_P_index%8]),
    .w6 (V[5][calu_P_index%8]),
    .w7 (V[6][calu_P_index%8]),
    .w8 (V[7][calu_P_index%8]),
    .out(P_temp)
);

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i=0;i<8;i=i+1) begin
//             for(j=0;j<8;j=j+1) begin
//                 P[i][j] <= 62'd0;
//             end
//         end
//     end
//     else if(calu_P)begin
//         P[calu_P_index/8][calu_P_index%8] <= P_temp ;
//     end
// end

reg signed [61:0] P_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        P_reg <= 62'd0;
    end
    else if(calu_P) begin
        P_reg <= P_temp;
    end
end


//==============================================//
//                    Det                       //
//==============================================//
wire signed [19:0]  Det3X3_temp;
wire Det3X3_valid = (input_cnt > 185)&&(input_cnt < 190);
wire [1:0] Det_cnt = (Det3X3_valid) ? input_cnt - 186 :0;

reg signed [5:0] Det_in_select [0:8];

always @(*) begin
    case(Det_cnt)
        0: begin
            Det_in_select[0] = Y[1][1];
            Det_in_select[1] = Y[1][2];
            Det_in_select[2] = Y[1][3];
            Det_in_select[3] = Y[2][1];
            Det_in_select[4] = Y[2][2];
            Det_in_select[5] = Y[2][3];
            Det_in_select[6] = Y[3][1];
            Det_in_select[7] = Y[3][2];
            Det_in_select[8] = Y[3][3];
        end
        1: begin
            Det_in_select[0] = Y[0][1];
            Det_in_select[1] = Y[0][2];
            Det_in_select[2] = Y[0][3];
            Det_in_select[3] = Y[2][1];
            Det_in_select[4] = Y[2][2];
            Det_in_select[5] = Y[2][3];
            Det_in_select[6] = Y[3][1];
            Det_in_select[7] = Y[3][2];
            Det_in_select[8] = Y[3][3];
        end
        2: begin
            Det_in_select[0] = Y[0][1];
            Det_in_select[1] = Y[0][2];
            Det_in_select[2] = Y[0][3];
            Det_in_select[3] = Y[1][1];
            Det_in_select[4] = Y[1][2];
            Det_in_select[5] = Y[1][3];
            Det_in_select[6] = Y[3][1];
            Det_in_select[7] = Y[3][2];
            Det_in_select[8] = Y[3][3];
        end
        3: begin
            Det_in_select[0] = Y[0][1];
            Det_in_select[1] = Y[0][2];
            Det_in_select[2] = Y[0][3];
            Det_in_select[3] = Y[1][1];
            Det_in_select[4] = Y[1][2];
            Det_in_select[5] = Y[1][3];
            Det_in_select[6] = Y[2][1];
            Det_in_select[7] = Y[2][2];
            Det_in_select[8] = Y[2][3];
        end
    endcase
end

Det3X3 Det3X3_0 (
    .in_valid(Det3X3_valid),
    .in1(Det_in_select[0]),.in2(Det_in_select[1]),.in3(Det_in_select[2]),
    .in4(Det_in_select[3]),.in5(Det_in_select[4]),.in6(Det_in_select[5]),
    .in7(Det_in_select[6]),.in8(Det_in_select[7]),.in9(Det_in_select[8]),
    .out(Det3X3_temp)
);

reg signed [19:0] Det3X3 [0:3];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Det3X3[0] <= 0;
        Det3X3[1] <= 0;
        Det3X3[2] <= 0;
        Det3X3[3] <= 0;
    end
    else begin
        case(Det_cnt)
            2'd0: Det3X3[0] <= Det3X3_temp;
            2'd1: Det3X3[1] <= Det3X3_temp;
            2'd2: Det3X3[2] <= Det3X3_temp;
            2'd3: Det3X3[3] <= Det3X3_temp;
        endcase
    end
end

reg calu_Det ;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) calu_Det <= 1'b0;
    else if(Det_cnt==3) calu_Det <= 1'b1;
    else calu_Det <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) Det_y <= 31'd0;
    else if(calu_Det)
        Det_y <= Y[0][0]*Det3X3[0] - Y[1][0]*Det3X3[1] + Y[2][0]*Det3X3[2] - Y[3][0]*Det3X3[3];
    else
        Det_y <= Det_y;
end
//==============================================//
//                  Output                      //
//==============================================//

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 1'b0;
    end
    else if(start_output ) begin
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
    else if(start_output) begin
        out_data <= P_reg * Det_y;
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
output reg  signed [19:0] out;

always @(*) begin
    if(!in_valid)
        out = 20'd0;
    else
        out = in1*in5*in9 + in2*in6*in7 + in3*in4*in8 - in3*in5*in7 - in2*in4*in9 - in1*in6*in8 ;
end

endmodule

//Area: 2211508.472011 Det3X3 *4
//Area: 2124045.319248 Det3X3 *4

//remove P reg but have lat problem(Det_3X3)
// Area: 1782729.662804
// Power:6.9791 mW

//fix lat problem
// Area: 1784782.656569
// 7.0584 mW

//let Det_cnt reset
// Area: 1781760.972696
// 7.0302 mW

// let index_cnt reset
// Area: 1792816.517595
// 6.9863 mW