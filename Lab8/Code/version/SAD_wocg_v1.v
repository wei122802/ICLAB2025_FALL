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
reg [1:0] cal_cnt;
reg [6:0] output_cnt;
reg [1:0] T_type;

reg signed [7:0] x [0:7] [0:7] ;

reg signed [7:0] w_Q_matrix [0:7] [0:7];
reg signed [7:0] w_K_matrix [0:7] [0:7];
reg signed [7:0] w_V_matrix [0:7] [0:7];

wire signed [18:0] K [0:7] [0:7];
reg  signed [18:0] K_reg [0:7] [0:7];

wire signed [18:0] Q [0:7] [0:7];
reg  signed [18:0] Q_reg [0:7] [0:7];

wire signed [18:0] V [0:7] [0:7];
reg  signed [18:0] V_reg [0:7] [0:7];

wire signed [40:0] A [0:7] [0:7];
reg  signed [40:0] A_reg [0:7] [0:7];

reg signed [39:0] Scale_A [0:7] [0:7];

reg signed [39:0] ReLU_A [0:7] [0:7];

wire signed [61:0] P [0:7] [0:7];
reg  signed [61:0] P_reg [0:7] [0:7];

reg signed [5:0] Y [0:3] [0:3];
reg signed [25:0] Det_y;

reg input_finish_flag;
reg start_output;

//==============================================//
//                  Counter                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  input_cnt <= 8'd0;
    else if(in_valid)  input_cnt <= input_cnt + 8'd1;
    else input_cnt <= 8'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  cal_cnt <= 2'd0;
    else if(input_finish_flag)  cal_cnt <= cal_cnt + 2'd1;
    else cal_cnt <= 2'd0;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)  input_finish_flag <= 1'b0;
    else if(input_cnt == 8'd192)  input_finish_flag <= 1'b1;
    else if(cal_cnt == 2'd3)  input_finish_flag <= 1'b0;
    else input_finish_flag <= input_finish_flag;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)  start_output <= 1'b0;
    else 
        case(1)
            (cal_cnt > 2'd2) : start_output <= 1'b1;
            ((output_cnt == 7'd8 )&& (T_type == 2'b00)) : start_output <= 1'b0;
            ((output_cnt == 7'd32) && (T_type == 2'b01)) : start_output <= 1'b0;
            ((output_cnt == 7'd64 )&& (T_type == 2'b10)) : start_output <= 1'b0;
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
//                 Calulate                     //
//==============================================//
generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8))  MAC_Q (
                .in_valid(input_finish_flag),
                .in1(x[gen_i][0]),
                .in2(x[gen_i][1]),
                .in3(x[gen_i][2]),
                .in4(x[gen_i][3]),
                .in5(x[gen_i][4]),
                .in6(x[gen_i][5]),
                .in7(x[gen_i][6]),
                .in8(x[gen_i][7]),
                .w1(w_Q_matrix[0][gen_j]),
                .w2(w_Q_matrix[1][gen_j]),
                .w3(w_Q_matrix[2][gen_j]),
                .w4(w_Q_matrix[3][gen_j]),
                .w5(w_Q_matrix[4][gen_j]),
                .w6(w_Q_matrix[5][gen_j]),
                .w7(w_Q_matrix[6][gen_j]),
                .w8(w_Q_matrix[7][gen_j]),
                .out(Q[gen_i][gen_j])
            );  
        end
    end
endgenerate



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                Q_reg[i][j] <= 19'd0;
            end
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                Q_reg[i][j] <= Q[i][j];
            end
        end
    end
end

generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            MAC_8#(.WIDTH_1(8) , .WIDTH_2(8)) MAC_K (
                .in_valid(input_finish_flag),
                .in1(x[gen_i][0]),
                .in2(x[gen_i][1]),
                .in3(x[gen_i][2]),
                .in4(x[gen_i][3]),
                .in5(x[gen_i][4]),
                .in6(x[gen_i][5]),
                .in7(x[gen_i][6]),
                .in8(x[gen_i][7]),
                .w1(w_K_matrix[0][gen_j]),
                .w2(w_K_matrix[1][gen_j]),
                .w3(w_K_matrix[2][gen_j]),
                .w4(w_K_matrix[3][gen_j]),
                .w5(w_K_matrix[4][gen_j]),
                .w6(w_K_matrix[5][gen_j]),
                .w7(w_K_matrix[6][gen_j]),
                .w8(w_K_matrix[7][gen_j]),
                .out(K[gen_i][gen_j])
            );  
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                K_reg[i][j] <= 19'd0;
            end
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                K_reg[i][j] <= K[i][j];
            end
        end
    end
end

generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            MAC_8 #(.WIDTH_1(8) , .WIDTH_2(8)) MAC_V (
                .in_valid(input_finish_flag),
                .in1(x[gen_i][0]),
                .in2(x[gen_i][1]),
                .in3(x[gen_i][2]),
                .in4(x[gen_i][3]),
                .in5(x[gen_i][4]),
                .in6(x[gen_i][5]),
                .in7(x[gen_i][6]),
                .in8(x[gen_i][7]),
                .w1(w_V_matrix[0][gen_j]),
                .w2(w_V_matrix[1][gen_j]),
                .w3(w_V_matrix[2][gen_j]),
                .w4(w_V_matrix[3][gen_j]),
                .w5(w_V_matrix[4][gen_j]),
                .w6(w_V_matrix[5][gen_j]),
                .w7(w_V_matrix[6][gen_j]),
                .w8(w_V_matrix[7][gen_j]),
                .out(V[gen_i][gen_j])
            );  
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                V_reg[i][j] <= 19'd0;
            end
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                V_reg[i][j] <= V[i][j];
            end
        end
    end
end

generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            MAC_8 #(.WIDTH_1(19) , .WIDTH_2(19)) MAC_A (
                .in_valid(input_finish_flag),
                .in1(Q_reg[gen_i][0]),
                .in2(Q_reg[gen_i][1]),
                .in3(Q_reg[gen_i][2]),
                .in4(Q_reg[gen_i][3]),
                .in5(Q_reg[gen_i][4]),
                .in6(Q_reg[gen_i][5]),
                .in7(Q_reg[gen_i][6]),
                .in8(Q_reg[gen_i][7]),
                .w1(K_reg[gen_j][0]),
                .w2(K_reg[gen_j][1]),
                .w3(K_reg[gen_j][2]),
                .w4(K_reg[gen_j][3]),
                .w5(K_reg[gen_j][4]),
                .w6(K_reg[gen_j][5]),
                .w7(K_reg[gen_j][6]),
                .w8(K_reg[gen_j][7]),
                .out(A[gen_i][gen_j])
            );  
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                A_reg[i][j] <= 40'd0;
            end
        end
    end
    else begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                A_reg[i][j] <= A[i][j];
            end
        end
    end
end

// Scale_A
// generate
//     for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
//         for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
//             always @(posedge clk or negedge rst_n) begin
//                 if(!rst_n) begin
//                     Scale_A[gen_i][gen_j] <= 40'd0;
//                 end
//                 else if(input_finish_flag) begin
//                     Scale_A[gen_i][gen_j] <= A[gen_i][gen_j] /3;
//                 end
//             end
//         end
//     end
// endgenerate
generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            always @(*) begin
                Scale_A[gen_i][gen_j] = A_reg[gen_i][gen_j]/ 3;
            end
        end
    end
endgenerate

// ReLU_A
generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            always @(*) begin
                ReLU_A[gen_i][gen_j] = (Scale_A[gen_i][gen_j] < 0) ? 40'd0 : Scale_A[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for(gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin 
        for (gen_j = 0; gen_j < 8; gen_j = gen_j + 1) begin 
            MAC_8 #(.WIDTH_1(40) , .WIDTH_2(19) ) MAC_P (
                .in_valid(input_finish_flag),
                .in1(ReLU_A[gen_i][0]),
                .in2(ReLU_A[gen_i][1]),
                .in3(ReLU_A[gen_i][2]),
                .in4(ReLU_A[gen_i][3]),
                .in5(ReLU_A[gen_i][4]),
                .in6(ReLU_A[gen_i][5]),
                .in7(ReLU_A[gen_i][6]),
                .in8(ReLU_A[gen_i][7]),
                .w1(V_reg[0][gen_j]),
                .w2(V_reg[1][gen_j]),
                .w3(V_reg[2][gen_j]),
                .w4(V_reg[3][gen_j]),
                .w5(V_reg[4][gen_j]),
                .w6(V_reg[5][gen_j]),
                .w7(V_reg[6][gen_j]),
                .w8(V_reg[7][gen_j]),
                .out(P[gen_i][gen_j])
            );
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                P_reg[i][j] <= 62'd0;
            end
        end
    end
    else if (cal_cnt==3) begin
        for(i=0;i<8;i=i+1) begin
            for(j=0;j<8;j=j+1) begin
                P_reg[i][j] <= P[i][j];
            end
        end
    end
end

wire [19:0] Det3X3 [0:3];
Det3X3 Det3X3_0 (
    .in_valid(input_finish_flag),
    .in1(Y[1][1]),.in2(Y[1][2]),.in3(Y[1][3]),
    .in4(Y[2][1]),.in5(Y[2][2]),.in6(Y[2][3]),
    .in7(Y[3][1]),.in8(Y[3][2]),.in9(Y[3][3]),
    .out(Det3X3[0])
);

Det3X3 Det3X3_1 (
    .in_valid(input_finish_flag),
    .in1(Y[0][1]),.in2(Y[0][2]),.in3(Y[0][3]),
    .in4(Y[2][1]),.in5(Y[2][2]),.in6(Y[2][3]),
    .in7(Y[3][1]),.in8(Y[3][2]),.in9(Y[3][3]),
    .out(Det3X3[1])
);

Det3X3 Det3X3_2 (
    .in_valid(input_finish_flag),
    .in1(Y[0][1]),.in2(Y[0][2]),.in3(Y[0][3]),
    .in4(Y[1][1]),.in5(Y[1][2]),.in6(Y[1][3]),
    .in7(Y[3][1]),.in8(Y[3][2]),.in9(Y[3][3]),
    .out(Det3X3[2])
);

Det3X3 Det3X3_3 (
    .in_valid(input_finish_flag),
    .in1(Y[0][1]),.in2(Y[0][2]),.in3(Y[0][3]),
    .in4(Y[1][1]),.in5(Y[1][2]),.in6(Y[1][3]),
    .in7(Y[2][1]),.in8(Y[2][2]),.in9(Y[2][3]),
    .out(Det3X3[3])
);



always @(*) begin
    if(input_finish_flag)
        Det_y = Y[0][0]*Det3X3[0] - Y[1][0]*Det3X3[1] + Y[2][0]*Det3X3[2] - Y[3][0]*Det3X3[3];
    else
        Det_y = 26'd0;
end

reg signed [25:0] Det_y_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Det_y_reg <= 26'd0;
    end
    else if(cal_cnt==3)begin
        Det_y_reg <= Det_y;
    end
    else
        Det_y_reg <= Det_y_reg;
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
        out_data <= P_reg[(output_cnt-1)/8][(output_cnt-1)%8] * Det_y_reg;
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