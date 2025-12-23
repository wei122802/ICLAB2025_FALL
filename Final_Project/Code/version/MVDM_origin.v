module MVDM(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    in_data,
    // output signals
    out_valid,
    out_sad
    );

input clk;
input rst_n;
input in_valid;
input in_valid2;
input [8:0] in_data;

output reg out_valid;
output reg out_sad;

//=======================================================
//                   Reg/Wire
//=======================================================
reg [13:0] L0_addr , L1_addr;
reg [7:0]  L0_data,L1_data;
reg [7:0]  L0_data_reg , L1_data_reg ;
reg [8:0]  calu_cnt;

reg [14:0] bluex_L0 [0:59];
reg [14:0] bluex_L1 [0:59];
reg [14:0] bluex_temp_L1 , bluex_temp_L0 ;
reg [14:0] bluex_temp_L1_clip , bluex_temp_L0_clip ;
integer i,j;
//=======================================================
//                   Design
//=======================================================

//=======================================================
//                   MARK:FSM
//=======================================================
reg calu_finish_flag;
wire waiting5cycle, waiting10cycle ; 
typedef enum reg [2:0] {IDLE , INPUT_L0 , INPUT_L1 , GETMV , CALU} Main_FSM_state;
Main_FSM_state current_state, next_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    case (current_state)
        IDLE:
            if(in_valid)
                next_state = INPUT_L0;
            else if (in_valid2)
                next_state = GETMV;
            else
                next_state = IDLE;
        INPUT_L0:
            if(in_valid)
                next_state = (&L0_addr) ? INPUT_L1 : INPUT_L0;
            else
                next_state = IDLE;
        INPUT_L1:
            if(in_valid)
                next_state = INPUT_L1;
            else
                next_state = IDLE;
        GETMV:
            if(in_valid2)
                next_state = GETMV;
            else
                next_state = CALU;
        CALU: 
            if(calu_finish_flag)
                next_state = IDLE;
            else
                next_state = CALU;
        default:  
            next_state = IDLE;
    endcase
end


typedef enum reg [1:0] {WAIT , GET_INTER} Calu_FSM_state;
Calu_FSM_state c_state_calu, n_state_calu;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        c_state_calu <= WAIT;
    else
        c_state_calu <= n_state_calu;
end

always @(*) begin
    if(current_state == CALU)
        case (c_state_calu)
            WAIT:
                n_state_calu = (waiting5cycle) ? GET_INTER : WAIT;
            GET_INTER:
                n_state_calu = (waiting10cycle) ? WAIT : GET_INTER;
            default:
                n_state_calu = WAIT;
        endcase
    else
        n_state_calu = WAIT;
end

reg [3:0] waiting_cnt;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        waiting_cnt <= 4'b0;
    else if (current_state == CALU && calu_cnt>3)
        waiting_cnt <= waiting_cnt + 1'b1;
    else 
        waiting_cnt <= 4'b0;
end
assign waiting5cycle = (waiting_cnt == 4'd5) ? 1'b1 : 1'b0 ;
assign waiting10cycle = (waiting_cnt == 4'd15) ? 1'b1 : 1'b0 ;
//=======================================================
//                   MARK:IO
//=======================================================
reg out_valid_comb, out_sad_comb ;
//test

reg [7:0] in_data_image;
reg [8:0] MV_data;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        in_data_image <= 8'b0;
    else if (in_valid)
        in_data_image <= in_data[8:1];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        MV_data <= 9'b0;
    else if (in_valid2)
        MV_data <= in_data;
end

reg [7:0] MV_x_L0_point1 ; reg frac_x_L0_point1 ;
reg [7:0] MV_y_L0_point1 ; reg frac_y_L0_point1 ;
reg [7:0] MV_x_L1_point1 ; reg frac_x_L1_point1 ;
reg [7:0] MV_y_L1_point1 ; reg frac_y_L1_point1 ;

reg [7:0] MV_x_L0_point2 ; reg frac_x_L0_point2 ;
reg [7:0] MV_y_L0_point2 ; reg frac_y_L0_point2 ;
reg [7:0] MV_x_L1_point2 ; reg frac_x_L1_point2 ;
reg [7:0] MV_y_L1_point2 ; reg frac_y_L1_point2 ;
reg [2:0] MV_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        MV_cnt <= 3'b0;
    else if (current_state == GETMV)
        MV_cnt <= MV_cnt + 1'b1;
    else
        MV_cnt <= 3'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_x_L0_point1,frac_x_L0_point1} <= 9'b0;
    else if (in_valid2 && MV_cnt==0)
        {MV_x_L0_point1,frac_x_L0_point1} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_y_L0_point1,frac_y_L0_point1} <= 9'b0;
    else if ( MV_cnt==1)
        {MV_y_L0_point1,frac_y_L0_point1} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_x_L1_point1,frac_x_L1_point1} <= 9'b0;
    else if (MV_cnt==2)
        {MV_x_L1_point1,frac_x_L1_point1} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_y_L1_point1,frac_y_L1_point1} <= 9'b0;
    else if (MV_cnt==3)
        {MV_y_L1_point1,frac_y_L1_point1} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_x_L0_point2,frac_x_L0_point2} <= 9'b0;
    else if ( MV_cnt==4)
        {MV_x_L0_point2,frac_x_L0_point2} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_y_L0_point2,frac_y_L0_point2} <= 9'b0;
    else if (MV_cnt==5)
        {MV_y_L0_point2,frac_y_L0_point2} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_x_L1_point2,frac_x_L1_point2} <= 9'b0;
    else if (MV_cnt==6)
        {MV_x_L1_point2,frac_x_L1_point2} <= MV_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        {MV_y_L1_point2,frac_y_L1_point2} <= 9'b0;
    else if (MV_cnt==7)
        {MV_y_L1_point2,frac_y_L1_point2} <= MV_data;
end

//==================================================================
// Get Orange Points MARK:Orange
//==================================================================
// reg [8:0] calu_cnt;
reg [7:0] orange_point_L0 [0:5] ; 
reg [7:0] orange_point_L1 [0:5] ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        orange_point_L0[0] <= 8'b0; orange_point_L0[1] <= 8'b0; orange_point_L0[2] <= 8'b0;
        orange_point_L0[3] <= 8'b0; orange_point_L0[4] <= 8'b0; orange_point_L0[5] <= 8'b0;
    end
    else if (current_state == CALU) begin
        orange_point_L0[0] <= orange_point_L0[1];
        orange_point_L0[1] <= orange_point_L0[2];
        orange_point_L0[2] <= orange_point_L0[3];
        orange_point_L0[3] <= orange_point_L0[4];
        orange_point_L0[4] <= orange_point_L0[5];
        orange_point_L0[5] <= L0_data_reg;
    end
end


always @( posedge clk or negedge rst_n ) begin
    if ( !rst_n )
        calu_cnt <= 9'b0;
    else if ( current_state == CALU )
        calu_cnt <= calu_cnt + 1'b1;
    else
        calu_cnt <= 9'b0;
end

reg [3:0] calu_x , calu_y; // 15X15
reg [3:0] calu_x_L1 , calu_y_L1; // 15X15

always @(*) begin
    if({frac_x_L0_point1, frac_y_L0_point1} == 2'b10 ) begin
            calu_x = calu_cnt % 15 ;
            calu_y = ( calu_cnt / 15 ) % 15 ;
    end
    else begin
        
    end 

    case ({frac_x_L0_point1, frac_y_L0_point1})
        2'b00 : begin

        end
        2'b01 :
        2'b10 :
        2'b11 : 
        default: 
    endcase
end

// assign calu_x = calu_cnt % 15 ;
// assign calu_y = ( calu_cnt / 15 ) % 15 ;

reg [13:0] addr_L0_point, addr_L1_point ;

reg [7:0] sum_L0_x ,sum_L0_y , sum_L1_x ,sum_L1_y ;
reg [6:0] final_L0_x , final_L0_y , final_L1_x , final_L1_y ;
//L0
always @(*) begin
    if(calu_cnt < 225) begin
        sum_L0_x = MV_x_L0_point1 + calu_x ;
        sum_L0_y = MV_y_L0_point1 + calu_y ;
    end
    else begin
        sum_L0_x = MV_x_L0_point2 + calu_x ;
        sum_L0_y = MV_y_L0_point2 + calu_y ;
    end
end

always @(*) begin
    if(sum_L0_x < 2 )          final_L0_x = 0 ;
    else if (sum_L0_x > 129 )  final_L0_x = 127 ;//maybe
    else                       final_L0_x = sum_L0_x - 2 ;
end

always @(*) begin
    if(sum_L0_y < 2 )         final_L0_y = 0 ;
    else if (sum_L0_y > 129 ) final_L0_y = 127 ; //maybe
    else                      final_L0_y = sum_L0_y - 2 ;
end

//L1
always @(*) begin
    if(calu_cnt < 225) begin
        sum_L1_x = MV_x_L1_point1 + calu_x ;
        sum_L1_y = MV_y_L1_point1 + calu_y ;
    end
    else begin
        sum_L1_x = MV_x_L1_point2 + calu_x ;
        sum_L1_y = MV_y_L1_point2 + calu_y ;
    end
end

always @(*) begin
    if(sum_L1_x < 2 )          final_L1_x = 0 ;
    else if (sum_L1_x > 129 )  final_L1_x = 127 ;//maybe
    else                       final_L1_x = sum_L1_x - 2 ;
end

always @(*) begin
    if(sum_L1_y < 2 )         final_L1_y = 0 ;
    else if (sum_L1_y > 129 ) final_L1_y = 127 ; //maybe
    else                      final_L1_y = sum_L1_y - 2 ;
end

always @(*) begin
    addr_L0_point = (final_L0_y * 128) + final_L0_x ;
    addr_L1_point = (final_L1_y * 128) + final_L1_x ;
end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         addr_L0_point <= 14'b0;
//         addr_L1_point <= 14'b0;
//     end
//     else if (current_state == CALU) begin
//         addr_L0_point <= (final_L0_y * 128) + final_L0_x ;
//         addr_L1_point <= (final_L1_y * 128) + final_L1_x ;
//     end
// end
//==================================================================
// MARK:Blue
//==================================================================
interpolation_blue blue_interpolation_L0 (
    .Pmin2(orange_point_L0[0]),
    .Pmin1(orange_point_L0[1]),
    .P0   (orange_point_L0[2]),
    .P1   (orange_point_L0[3]),
    .P2   (orange_point_L0[4]),
    .P3   (orange_point_L0[5]),
    .out_data(bluex_temp_L0) 
);
always @(*) begin
    case ({frac_x_L0_point1, frac_y_L0_point1})
        2'b00: bluex_temp_L0_clip = orange_point_L0[5] ;
        2'b01: bluex_temp_L0_clip = (bluex_temp_L0 * 3) >> 5 ;
        2'b10: bluex_temp_L0_clip = (bluex_temp_L0 * 3) >> 5 ;
        2'b11: bluex_temp_L0_clip = (bluex_temp_L0 * 9) >> 6 ;
        default:  bluex_temp_L0_clip = 0 ;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        for(int i=0 ; i<60 ; i=i+1 )
            bluex_L0[i] <= 15'b0;
    else if (c_state_calu == GET_INTER)  begin
        bluex_L0[59] <= bluex_temp_L0;
        for(i=0 ; i<59 ; i=i+1 )  bluex_L0[i] <= bluex_L0[i+1];
    end
end


//==================================================================
// MARK:Debug
//==================================================================
reg [14:0] debug_bluex_L0 [0:9] [0:5] ;
reg [14:0] debug_bluex_L1 [0:9] [0:5] ;

always @(*) begin
    for(i=0 ; i<10 ; i=i+1 ) begin
        for(j=0 ; j<6 ; j=j+1 ) begin
            debug_bluex_L0[i][j] = bluex_L0[i*15 + j];
            debug_bluex_L1[i][j] = bluex_L1[i*15 + j];
        end
    end
end

//==================================================================
// MARK:SRAM
//==================================================================
// reg [13:0] L_addr;
// reg [7:0] L0_data,L1_data;
// reg [7:0] L0_data_reg , L1_data_reg ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   L0_data_reg <= 8'b0;
    else         L0_data_reg <= L0_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   L1_data_reg <= 8'b0;
    else         L1_data_reg <= L1_data;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        L0_addr <= 14'b0;
    else if (current_state == INPUT_L0) //opt
        L0_addr <= L0_addr + 1'b1;
    else
        L0_addr <= addr_L0_point;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        L1_addr <= 14'b0;
    else if (current_state == INPUT_L1) //opt
        L1_addr <= L1_addr + 1'b1;
    else
        L1_addr <= addr_L1_point;
end

SRAM_16384 L0 (
    .CK(clk),
    .WEB(~(current_state == INPUT_L0)),
    .OE(1'b1),
    .CS(1'b1),
    .A(L0_addr),
    .DI(in_data_image),
    .DO(L0_data)
);

SRAM_16384 L1 (
    .CK(clk),
    .WEB(~(current_state == INPUT_L1)),
    .OE(1'b1),
    .CS(1'b1),
    .A(L1_addr),
    .DI(in_data_image),
    .DO(L1_data)
);

//=======================================================
//                   MARK:Output
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_sad <= 1'b0;
    else
        out_sad <= 0;
end




endmodule



module interpolation_blue ( //Opt: pipeline 
    input [7:0] Pmin2,Pmin1, P0 , P1 , P2 , P3 ,
    output signed [14:0] out_data
);

assign out_data = Pmin2 - 5 * Pmin1 + 20 * P0 + 20 * P1 - 5 * P2 + P3;

endmodule

module interpolation_green ( //Opt: pipeline 
    input  signed [14:0] Pmin2,Pmin1, P0 , P1 , P2 , P3 ,
    output signed [19:0] out_data
);

assign out_data = Pmin2 - 5 * Pmin1 + 20 * P0 + 20 * P1 - 5 * P2 + P3;

endmodule

//=======================================================
//                   MEM
//=======================================================
module SRAM_16384 (
    input CK,WEB,OE,CS,
    input [13:0] A,
    input [7:0] DI,
    output [7:0] DO
);

L0  SRAM_16384X8_inst (
    .A0(A[0]) , .A1(A[1]) , .A2(A[2]) , .A3(A[3]) ,
    .A4(A[4]) , .A5(A[5]) , .A6(A[6]) , .A7(A[7]) ,
    .A8(A[8]) , .A9(A[9]) , .A10(A[10]) , .A11(A[11]) ,
    .A12(A[12]) , .A13(A[13]) ,
    .DI0(DI[0]) , .DI1(DI[1]) , .DI2(DI[2]) , .DI3(DI[3]) ,
    .DI4(DI[4]) , .DI5(DI[5]) , .DI6(DI[6]) , .DI7(DI[7]) ,
    .DO0(DO[0]) , .DO1(DO[1]) , .DO2(DO[2]) , .DO3(DO[3]) ,
    .DO4(DO[4]) , .DO5(DO[5]) , .DO6(DO[6]) , .DO7(DO[7]) ,
    .CK(CK) , .WEB(WEB) , .OE(OE) , .CS(CS)
);
endmodule
