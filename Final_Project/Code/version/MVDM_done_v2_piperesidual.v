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
reg [127:0]  S0_data_reg ,S1_data_reg;
reg [127:0]  S0_data,S1_data;
reg [9:0] S0_addr , S1_addr;
integer i,j;
reg [4:0] input_cnt;

reg [7:0] MV_x_L0_point1 ; reg frac_x_L0_point1 ;
reg [7:0] MV_y_L0_point1 ; reg frac_y_L0_point1 ;
reg [7:0] MV_x_L1_point1 ; reg frac_x_L1_point1 ;
reg [7:0] MV_y_L1_point1 ; reg frac_y_L1_point1 ;

reg [7:0] MV_x_L0_point2 ; reg frac_x_L0_point2 ;
reg [7:0] MV_y_L0_point2 ; reg frac_y_L0_point2 ;
reg [7:0] MV_x_L1_point2 ; reg frac_x_L1_point2 ;
reg [7:0] MV_y_L1_point2 ; reg frac_y_L1_point2 ;
reg [2:0] MV_cnt;
reg [1:0] point_L_cnt;
reg signed [14:0] bluex_L0 [0:59];
reg signed [14:0] bluex_L1 [0:59];
wire signed [14:0] bluex_temp [0:9];
reg signed [14:0] bluex_reg [0:9]; //pipe
//=======================================================
//                   Design
//=======================================================

//=======================================================
//                   MARK:FSM
//=======================================================
reg calu_finish_flag;
wire SATD_finish_flag;
wire out_finish_flag;
wire start_out_flag;
wire start_calu;
reg [5:0] satd_cnt;
reg [5:0] calu_cnt;
reg [5:0] out_cnt;
reg calu_early_out_flag;

typedef enum reg [3:0] {IDLE, INPUT , GETMV ,VER_INT,HOR_INT,NO_INT ,HV_INT ,SATD ,OUTPUT} Main_FSM_state;
Main_FSM_state current_state, next_state;

//MARK:flag
always @(*) begin
    case (current_state)
        VER_INT : calu_finish_flag =  calu_cnt == 20 ;
        HOR_INT : calu_finish_flag =  calu_cnt == 15 ;
        NO_INT  : calu_finish_flag =  calu_cnt == 14 ;
        HV_INT  : calu_finish_flag =  calu_cnt == 20 ;
        default : calu_finish_flag = 0 ;
    endcase
end

always @(*) begin
    case (current_state)
        VER_INT : calu_early_out_flag =  (point_L_cnt == 3) && (calu_cnt >= 6) ;
        HOR_INT : calu_early_out_flag =  (point_L_cnt == 3) && (calu_cnt >= 1);
        NO_INT  : calu_early_out_flag =  (point_L_cnt == 3) ;
        HV_INT  : calu_early_out_flag =  (point_L_cnt == 3) && (calu_cnt >= 6) ;
        default : calu_early_out_flag =  0 ;
    endcase
end

assign start_out_flag = (current_state == OUTPUT) || ((point_L_cnt == 3) && (current_state == SATD)) || calu_early_out_flag ;

assign out_finish_flag = (out_cnt == 55) ;
assign SATD_finish_flag = (satd_cnt == 13) ;

assign start_calu = (current_state == VER_INT || current_state == HOR_INT || current_state == NO_INT || current_state == HV_INT);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_cnt <= 0;
    else if (start_out_flag)
        out_cnt <= out_cnt + 1 ;
    else
        out_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        satd_cnt <= 0;
    else if (current_state == SATD)
        satd_cnt <= satd_cnt + 1 ;
    else if (start_calu)
        satd_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        calu_cnt <= 0;
    else if (calu_finish_flag) 
        calu_cnt <= 0 ;
    else if (start_calu)
        calu_cnt <= calu_cnt + 1 ;
    else
        calu_cnt <= 0;
end

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
                next_state = INPUT;
            else if (in_valid2)
                next_state = GETMV;
            else
                next_state = IDLE;
        INPUT:
            if(in_valid)
                next_state = INPUT;
            else
                next_state = IDLE;
        GETMV:
            if(MV_cnt == 2)
                case ({frac_x_L0_point1 , frac_y_L0_point1} )
                    2'b00 : next_state = NO_INT;
                    2'b01 : next_state = VER_INT;
                    2'b10 : next_state = HOR_INT;
                    2'b11 : next_state = HV_INT;
                    default: next_state = IDLE;
                endcase
            else
                next_state = GETMV;
        VER_INT: 
            if(calu_finish_flag)
                case (point_L_cnt)
                    0 : begin
                        case ({frac_x_L1_point1 , frac_y_L1_point1} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    1 : begin
                        next_state = SATD;
                    end
                    2 :begin
                        case ({frac_x_L1_point2 , frac_y_L1_point2} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    3 :  begin
                        next_state = SATD;
                    end
                    default:  next_state = IDLE;
                endcase
            else
                next_state = VER_INT;
        HOR_INT:
            if(calu_finish_flag)
                case (point_L_cnt)
                    0 : begin
                        case ({frac_x_L1_point1 , frac_y_L1_point1} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    1 : begin
                        next_state = SATD;
                    end
                    2 :begin
                        case ({frac_x_L1_point2 , frac_y_L1_point2} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    3 :  begin
                        next_state = SATD;
                    end
                    default:  next_state = IDLE;
                endcase
            else
                next_state = HOR_INT;
        NO_INT:
            if(calu_finish_flag)
                case (point_L_cnt)
                    0 : begin
                        case ({frac_x_L1_point1 , frac_y_L1_point1} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    1 : begin
                        next_state = SATD;
                    end
                    2 :begin
                        case ({frac_x_L1_point2 , frac_y_L1_point2} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    3 :  begin
                        next_state = SATD;
                    end
                    default:  next_state = IDLE;
                endcase
            else
                next_state = NO_INT;
        HV_INT: 
            if(calu_finish_flag)
                case (point_L_cnt)
                    0 : begin
                        case ({frac_x_L1_point1 , frac_y_L1_point1} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    1 : begin
                        next_state = SATD;
                    end
                    2 :begin
                        case ({frac_x_L1_point2 , frac_y_L1_point2} )
                            2'b00 : next_state = NO_INT;
                            2'b01 : next_state = VER_INT;
                            2'b10 : next_state = HOR_INT;
                            2'b11 : next_state = HV_INT;
                            default: next_state = IDLE;
                        endcase
                    end
                    3 :  begin
                        next_state = SATD;
                    end
                    default:  next_state = IDLE;
                endcase
            else
                next_state = HV_INT;
        SATD:
            if(SATD_finish_flag)
                if(&point_L_cnt) next_state = OUTPUT ;
                else
                    case ({frac_x_L0_point2 , frac_y_L0_point2} )
                        2'b00 : next_state = NO_INT;
                        2'b01 : next_state = VER_INT;
                        2'b10 : next_state = HOR_INT;
                        2'b11 : next_state = HV_INT;
                        default: next_state = IDLE;
                    endcase
            else
                next_state = SATD;
        OUTPUT: next_state = out_finish_flag ? IDLE : OUTPUT;
        default: 
            next_state = IDLE;
    endcase
end



//=======================================================
//                   MARK:MV IO
//=======================================================
reg out_valid_comb ;
reg [55:0] out_sad_comb ;
//test

reg [127:0] in_data_image;
reg [8:0] MV_data;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        in_data_image <= 'b0;
    else if (in_valid) begin
        in_data_image[7:0] <= in_data[8:1];
        in_data_image[127:8] <= in_data_image[120:0] ;
    end
end

always @(*) begin
    MV_data = in_data;
end

// reg [7:0] MV_x_L0_point1 ; reg frac_x_L0_point1 ;
// reg [7:0] MV_y_L0_point1 ; reg frac_y_L0_point1 ;
// reg [7:0] MV_x_L1_point1 ; reg frac_x_L1_point1 ;
// reg [7:0] MV_y_L1_point1 ; reg frac_y_L1_point1 ;

// reg [7:0] MV_x_L0_point2 ; reg frac_x_L0_point2 ;
// reg [7:0] MV_y_L0_point2 ; reg frac_y_L0_point2 ;
// reg [7:0] MV_x_L1_point2 ; reg frac_x_L1_point2 ;
// reg [7:0] MV_y_L1_point2 ; reg frac_y_L1_point2 ;
// reg [2:0] MV_cnt;
// reg [1:0] point_L_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) point_L_cnt <= 2'b0;
    else if (in_valid2)
        point_L_cnt <= 0;
    else if (calu_finish_flag && point_L_cnt <3)
        point_L_cnt <= point_L_cnt + 1 ;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        MV_cnt <= 3'b0;
    else if (in_valid2)
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
    else if (MV_cnt==1)
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
// Get Orange Points MARK:Get32
//==================================================================
reg [6:0] x_point , y_point;

always @(*) begin
    case(current_state)
        // GETMV : 
        //     if(point_L_cnt ==2)  begin
        //         case ({frac_x_L0_point2 , frac_y_L0_point2} )
        //             2'b00 : begin x_point = MV_x_L0_point2[6:0];     y_point = MV_y_L0_point2[6:0];   end
        //             2'b01 : begin x_point = MV_x_L0_point2[6:0];     y_point = MV_y_L0_point2[6:0]-2; end
        //             2'b10 : begin x_point = MV_x_L0_point2[6:0]-2;   y_point = MV_y_L0_point2[6:0];   end
        //             2'b11 : begin x_point = MV_x_L0_point2[6:0]-2;   y_point = MV_y_L0_point2[6:0]-2; end
        //             default:begin x_point = 0;                       y_point = 0;                     end
        //         endcase
        //     end
        //     else begin
        //         x_point = 7'b0 ;
        //         y_point = 7'b0 ;
        //     end
        // SATD : 
        //     if(satd_cnt > 5)  begin
        //         case ({frac_x_L0_point2 , frac_y_L0_point2} )
        //             2'b00 : begin x_point = MV_x_L0_point2[6:0];     y_point = MV_y_L0_point2[6:0];   end
        //             2'b01 : begin x_point = MV_x_L0_point2[6:0];     y_point = MV_y_L0_point2[6:0]-2; end
        //             2'b10 : begin x_point = MV_x_L0_point2[6:0]-2;   y_point = MV_y_L0_point2[6:0];   end
        //             2'b11 : begin x_point = MV_x_L0_point2[6:0]-2;   y_point = MV_y_L0_point2[6:0]-2; end
        //             default:begin x_point = 0;                       y_point = 0;                     end
        //         endcase
        //     end
        //     else begin
        //         x_point = 7'b0 ;
        //         y_point = 7'b0 ;
        //     end
        NO_INT :
            case (point_L_cnt)
                0: begin
                    x_point = MV_x_L0_point1[6:0];
                    y_point = MV_y_L0_point1[6:0];
                end
                1: begin
                    x_point = MV_x_L1_point1[6:0] ;
                    y_point = MV_y_L1_point1[6:0];
                end
                2: begin
                    x_point = MV_x_L0_point2[6:0] ;
                    y_point = MV_y_L0_point2[6:0] ;
                end
                3: begin
                    x_point = MV_x_L1_point2[6:0] ;
                    y_point = MV_y_L1_point2[6:0] ;
                end
                default: begin
                    x_point = 7'b0 ;
                    y_point = 7'b0 ;
                end
            endcase
        VER_INT :
            case (point_L_cnt)
                0: begin
                    x_point = MV_x_L0_point1[6:0];
                    y_point = MV_y_L0_point1[6:0]-2 ;
                end
                1: begin
                    x_point = MV_x_L1_point1[6:0] ;
                    y_point = MV_y_L1_point1[6:0]-2 ;
                end
                2: begin
                    x_point = MV_x_L0_point2[6:0] ;
                    y_point = MV_y_L0_point2[6:0]-2 ;
                end
                3: begin
                    x_point = MV_x_L1_point2[6:0] ;
                    y_point = MV_y_L1_point2[6:0]-2 ;
                end
                default: begin
                    x_point = 7'b0 ;
                    y_point = 7'b0 ;
                end
            endcase
        HOR_INT :
            case (point_L_cnt)
                0: begin
                    x_point = MV_x_L0_point1[6:0]-2 ;
                    y_point = MV_y_L0_point1[6:0];
                end
                1: begin
                    x_point = MV_x_L1_point1[6:0] -2 ;
                    y_point = MV_y_L1_point1[6:0];
                end
                2: begin
                    x_point = MV_x_L0_point2[6:0] -2 ;
                    y_point = MV_y_L0_point2[6:0] ;
                end
                3: begin
                    x_point = MV_x_L1_point2[6:0] -2 ;
                    y_point = MV_y_L1_point2[6:0] ;
                end
                default: begin
                    x_point = 7'b0 ;
                    y_point = 7'b0 ;
                end
            endcase
        HV_INT :
            case (point_L_cnt)
                0: begin
                    x_point = MV_x_L0_point1[6:0]-2 ;
                    y_point = MV_y_L0_point1[6:0]-2 ;
                end
                1: begin
                    x_point = MV_x_L1_point1[6:0] -2 ;
                    y_point = MV_y_L1_point1[6:0]-2 ;
                end
                2: begin
                    x_point = MV_x_L0_point2[6:0] -2 ;
                    y_point = MV_y_L0_point2[6:0] -2 ;
                end
                3: begin
                    x_point = MV_x_L1_point2[6:0] -2 ;
                    y_point = MV_y_L1_point2[6:0] -2 ;
                end
                default: begin
                    x_point = 7'b0 ;
                    y_point = 7'b0 ;
                end
            endcase
        default :
            begin
                x_point = 7'b0 ;
                y_point = 7'b0 ;
            end
    endcase
end

reg [255:0] get_32point; 
reg [119:0] get_15_point;

reg [9:0] left_addr , right_addr;
reg [9:0] final_left_addr , final_right_addr;

always @(*) begin
    if(point_L_cnt[0] == 0)
        final_left_addr = left_addr ;
    else
        final_left_addr = left_addr + 512 ;
end

always @(*) begin
    if(point_L_cnt[0] == 0)
        final_right_addr = right_addr ;
    else
        final_right_addr = right_addr + 512 ;
end

wire [6:0] y_calu ;
assign y_calu = (calu_cnt < 3) ? y_point : (y_point + (calu_cnt-2)) ;
reg [6:0] y_calu_1;

always @(*) begin
    case (y_point)
        114 : y_calu_1 = ((y_calu==0) || (y_calu==1)) ? 127 : y_calu ;
        126 : y_calu_1 = ((y_calu==126) ||(y_calu==127)) ? 0 : y_calu ;
        127 : y_calu_1 = (y_calu==127) ? 0 : y_calu ;
        default: y_calu_1 = y_calu;
    endcase
end

// assign y_calu_1 = ((y_calu==126) || (y_calu==127)) ? (y_point==114) ? 127 : 0 : y_calu ;
always @(*) begin
    // if(&y_point[6:4]) // over edge
    // else
        // if(calu_cnt < 3)
            if (&x_point[6:1]) // 0 1 edge
                left_addr = (y_calu_1) * 4 ; //opt
            else
                left_addr = x_point[6:5] + (y_calu_1) * 4 ; //opt
        // else 
        //     if (&x_point[6:1]) // 0 1 edge
        //         left_addr = (y_point + (calu_cnt-2)) * 4 ; //opt
        //     else
        //         left_addr = x_point[6:5] + (y_point+ (calu_cnt-2)) * 4 ; //opt
end

always @(*) begin
    if(&x_point[6:4])
        right_addr = left_addr ;
    else
        if(x_point[4] == 1 ) //S1 right S2 left
            right_addr = left_addr + 1 ;
        else
            right_addr = left_addr ;
end

always @(*) begin
    if (&x_point[6:4])
        if(x_point[3] == 1)
            get_32point = { { 16{S0_data_reg[127:120]} }, S0_data_reg};
        else
            get_32point = {S1_data_reg , { 16{S1_data_reg[7:0]} } };
    else
        if(x_point[4] == 1 ) //S1 right S2 left
            get_32point = { S1_data_reg , S0_data_reg };
        else
            get_32point = { S0_data_reg , S1_data_reg };
end

always @(*) begin //opt
    case (x_point [3:0])
        0 : get_15_point = get_32point[255:136];
        1 : get_15_point = get_32point[247:128];
        2 : get_15_point = get_32point[239:120];
        3 : get_15_point = get_32point[231:112];
        4 : get_15_point = get_32point[223:104];
        5 : get_15_point = get_32point[215:96];
        6 : get_15_point = get_32point[207:88];
        7 : get_15_point = get_32point[199:80];
        8 : get_15_point = get_32point[191:72];
        9 : get_15_point = get_32point[183:64];
        10: get_15_point = get_32point[175:56];
        11: get_15_point = get_32point[167:48];
        12: get_15_point = get_32point[159:40];
        13: get_15_point = get_32point[151:32];
        14: get_15_point = get_32point[143:24];
        15: get_15_point = get_32point[135:16];
        default: get_15_point = 0;
    endcase
end


//==================================================================
// MARK:Green
//==================================================================
reg [7:0] Green_L0 [0:99];
reg [7:0] Green_L1 [0:99];
wire [7:0] get10 [0:9];
reg signed [19:0] green_temp [0:9];
assign {get10[0], get10[1], get10[2], get10[3], get10[4],
       get10[5], get10[6], get10[7], get10[8], get10[9]} = get_15_point[119:40];

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for (i=0; i<100; i=i+1) begin
            Green_L0[i] <= 'b0;
            Green_L1[i] <= 'b0;
        end
    end
    else 
        case (current_state)
            NO_INT : begin
                if (point_L_cnt[0] == 0) begin
                    for (i=0; i<90; i=i+1)
                        Green_L0[i] <= Green_L0[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        Green_L0[i] <= get10[i-90]; //maybe
                end
                else begin
                    for (i=0; i<90; i=i+1)
                        Green_L1[i] <= Green_L1[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        Green_L1[i] <= get10[i-90]; //maybe
                end
            end
            HOR_INT : begin
                if (point_L_cnt[0] == 0) begin
                    for (i=0; i<90; i=i+1)
                        Green_L0[i] <= Green_L0[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        // Green_L0[i] <= bluex_reg[i-90] > 8144 ? 255 : (bluex_reg[i-90]+16)>>>5; //maybe
                        // Green_L0[i] <= bluex_reg[i-90] > 8144 ? 255 : bluex_reg[i-90][14:5] + bluex_reg[i-90][4]; //maybe
                        if (bluex_reg[i-90] < 0 ) 
                            Green_L0[i] <= 0 ;
                        else if (bluex_reg[i-90] > 8144)
                            Green_L0[i] <= 255 ;
                        else
                            Green_L0[i] <= bluex_reg[i-90][14:5] + bluex_reg[i-90][4];

                end
                else begin
                    for (i=0; i<90; i=i+1)
                        Green_L1[i] <= Green_L1[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        // Green_L1[i] <= bluex_reg[i-90] > 8144 ? 255 : (bluex_reg[i-90]+16)>>>5; //maybe
                        // Green_L1[i] <= bluex_reg[i-90] > 8144 ? 255 : bluex_reg[i-90][14:5] + bluex_reg[i-90][4]; //maybe
                        if (bluex_reg[i-90] < 0 ) 
                            Green_L1[i] <= 0 ;
                        else if (bluex_reg[i-90] > 8144)
                            Green_L1[i] <= 255 ;
                        else
                            Green_L1[i] <= bluex_reg[i-90][14:5] + bluex_reg[i-90][4];

                end
            end 
            VER_INT : begin
                if (point_L_cnt[0] == 0) begin
                    for (i=0; i<90; i=i+1)
                        Green_L0[i] <= Green_L0[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        // Green_L0[i] <= green_temp[i-90] > 8144 ? 255 : (green_temp[i-90]+16)>>>5; //maybe
                        // Green_L0[i] <= green_temp[i-90] > 8144 ? 255 : (green_temp[i-90][14:5]+green_temp[i-90][4]); //maybe
                        if(green_temp[i-90] < 0 )
                            Green_L0[i] <= 0 ;
                        else if (green_temp[i-90] > 8144)
                            Green_L0[i] <= 255 ;
                        else
                            Green_L0[i] <= green_temp[i-90][14:5] + green_temp[i-90][4];
                end
                else begin
                    for (i=0; i<90; i=i+1)
                        Green_L1[i] <= Green_L1[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        // Green_L1[i] <= green_temp[i-90] > 8144 ? 255 : (green_temp[i-90]+16)>>>5; //maybe
                        // Green_L1[i] <= green_temp[i-90] > 8144 ? 255 : (green_temp[i-90][14:5]+green_temp[i-90][4]); //maybe
                        if(green_temp[i-90] < 0 )
                            Green_L1[i] <= 0 ;
                        else if (green_temp[i-90] > 8144)
                            Green_L1[i] <= 255 ;
                        else
                            Green_L1[i] <= green_temp[i-90][14:5] + green_temp[i-90][4];
                end
            end
            HV_INT : begin
                if (point_L_cnt[0] == 0) begin
                    for (i=0; i<90; i=i+1)
                        Green_L0[i] <= Green_L0[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        if(green_temp[i-90] < 0 )
                            Green_L0[i] <= 0 ;
                        else if (green_temp[i-90] > 260608)
                            Green_L0[i] <= 255 ;
                        else
                            Green_L0[i] <= green_temp[i-90][19:10] + green_temp[i-90][9];
                end
                else begin
                    for (i=0; i<90; i=i+1)
                        Green_L1[i] <= Green_L1[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        if (green_temp[i-90] < 0 )
                            Green_L1[i] <= 0 ;
                        else if (green_temp[i-90] > 260608)
                            Green_L1[i] <= 255 ;
                        else
                            Green_L1[i] <= green_temp[i-90][19:10] + green_temp[i-90][9];
                end
            end
            // default: 
        endcase
end
interpolation_green green_interpolation_point1 (
    .Pmin2 (bluex_L0[0]),     .Pmin1 (bluex_L0[10]),
    .P0    (bluex_L0[20]),    .P1    (bluex_L0[30]),
    .P2    (bluex_L0[40]),    .P3    (bluex_L0[50]),
    .out_data(green_temp[0]) //maybe pipe
);
interpolation_green green_interpolation_point2 (
    .Pmin2 (bluex_L0[1]),     .Pmin1 (bluex_L0[11]),
    .P0    (bluex_L0[21]),    .P1    (bluex_L0[31]),
    .P2    (bluex_L0[41]),    .P3    (bluex_L0[51]),
    .out_data(green_temp[1])
);

interpolation_green green_interpolation_point3 (
    .Pmin2 (bluex_L0[2]),     .Pmin1 (bluex_L0[12]),
    .P0    (bluex_L0[22]),    .P1    (bluex_L0[32]),
    .P2    (bluex_L0[42]),    .P3    (bluex_L0[52]),
    .out_data(green_temp[2])
);

interpolation_green green_interpolation_point4 (
    .Pmin2 (bluex_L0[3]),     .Pmin1 (bluex_L0[13]),
    .P0    (bluex_L0[23]),    .P1    (bluex_L0[33]),
    .P2    (bluex_L0[43]),    .P3    (bluex_L0[53]),
    .out_data(green_temp[3])
);

interpolation_green green_interpolation_point5 (
    .Pmin2 (bluex_L0[4]),     .Pmin1 (bluex_L0[14]),
    .P0    (bluex_L0[24]),    .P1    (bluex_L0[34]),
    .P2    (bluex_L0[44]),    .P3    (bluex_L0[54]),
    .out_data(green_temp[4])
);

interpolation_green green_interpolation_point6 (
    .Pmin2 (bluex_L0[5]),     .Pmin1 (bluex_L0[15]),
    .P0    (bluex_L0[25]),    .P1    (bluex_L0[35]),
    .P2    (bluex_L0[45]),    .P3    (bluex_L0[55]),
    .out_data(green_temp[5])
);

interpolation_green green_interpolation_point7 (
    .Pmin2 (bluex_L0[6]),     .Pmin1 (bluex_L0[16]),
    .P0    (bluex_L0[26]),    .P1    (bluex_L0[36]),
    .P2    (bluex_L0[46]),    .P3    (bluex_L0[56]),
    .out_data(green_temp[6])
);

interpolation_green green_interpolation_point8 (
    .Pmin2 (bluex_L0[7]),     .Pmin1 (bluex_L0[17]),
    .P0    (bluex_L0[27]),    .P1    (bluex_L0[37]),
    .P2    (bluex_L0[47]),    .P3    (bluex_L0[57]),
    .out_data(green_temp[7])
);

interpolation_green green_interpolation_point9 (
    .Pmin2 (bluex_L0[8]),     .Pmin1 (bluex_L0[18]),
    .P0    (bluex_L0[28]),    .P1    (bluex_L0[38]),
    .P2    (bluex_L0[48]),    .P3    (bluex_L0[58]),
    .out_data(green_temp[8])
);

interpolation_green green_interpolation_point10 (
    .Pmin2 (bluex_L0[9]),     .Pmin1 (bluex_L0[19]),
    .P0    (bluex_L0[29]),    .P1    (bluex_L0[39]),
    .P2    (bluex_L0[49]),    .P3    (bluex_L0[59]),
    .out_data(green_temp[9])
);

//==================================================================
// MARK:Blue
//==================================================================
// reg signed [14:0] bluex_L0 [0:59];
// reg signed [14:0] bluex_L1 [0:59];
// wire signed [14:0] bluex_temp [0:9];
// reg signed [14:0] bluex_reg [0:9]; //pipe


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (j=0; j<10; j=j+1)
            bluex_reg[j] <= 15'b0;
    end
    else begin
        for (j=0; j<10; j=j+1)
            bluex_reg[j] <= bluex_temp[j];
    end
end

always @ (posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for (j=0; j<60; j=j+1) begin
            bluex_L0[j] <= 15'b0;
        end
    end
    else 
        case (current_state)
            VER_INT: begin
                for (j=50; j<60; j=j+1)
                    bluex_L0[j] <= get10[j-50] ;
                for (j=0; j<50; j=j+1)
                    bluex_L0[j] <= bluex_L0[j+10] ; 
            end
            HV_INT : begin
                for (j=50; j<60; j=j+1)
                    bluex_L0[j] <= bluex_temp[j-50] ;
                for (j=0; j<50; j=j+1)
                    bluex_L0[j] <= bluex_L0[j+10] ; 
            end 
        endcase
end

interpolation_blue blue_interpolation_point1 (
    .Pmin2(get_15_point[119:112]),
    .Pmin1(get_15_point[111:104]),
    .P0   (get_15_point[103:96]),
    .P1   (get_15_point[95:88]),
    .P2   (get_15_point[87:80]),
    .P3   (get_15_point[79:72]),
    .out_data(bluex_temp[0])
);

interpolation_blue blue_interpolation_point2 (
    .Pmin2(get_15_point[111:104]),
    .Pmin1(get_15_point[103:96]),
    .P0   (get_15_point[95:88]),
    .P1   (get_15_point[87:80]),
    .P2   (get_15_point[79:72]),
    .P3   (get_15_point[71:64]),
    .out_data(bluex_temp[1])
);

interpolation_blue blue_interpolation_point3 (
    .Pmin2(get_15_point[103:96]),
    .Pmin1(get_15_point[95:88]),
    .P0   (get_15_point[87:80]),
    .P1   (get_15_point[79:72]),
    .P2   (get_15_point[71:64]),
    .P3   (get_15_point[63:56]),
    .out_data(bluex_temp[2])
);

interpolation_blue blue_interpolation_point4 (
    .Pmin2(get_15_point[95:88]),
    .Pmin1(get_15_point[87:80]),
    .P0   (get_15_point[79:72]),
    .P1   (get_15_point[71:64]),
    .P2   (get_15_point[63:56]),
    .P3   (get_15_point[55:48]),
    .out_data(bluex_temp[3])
);

interpolation_blue blue_interpolation_point5 (
    .Pmin2(get_15_point[87:80]),
    .Pmin1(get_15_point[79:72]),
    .P0   (get_15_point[71:64]),
    .P1   (get_15_point[63:56]),
    .P2   (get_15_point[55:48]),
    .P3   (get_15_point[47:40]),
    .out_data(bluex_temp[4])
);

interpolation_blue blue_interpolation_point6 (
    .Pmin2(get_15_point[79:72]),
    .Pmin1(get_15_point[71:64]),
    .P0   (get_15_point[63:56]),
    .P1   (get_15_point[55:48]),
    .P2   (get_15_point[47:40]),
    .P3   (get_15_point[39:32]),
    .out_data(bluex_temp[5])
); 

interpolation_blue blue_interpolation_point7 (
    .Pmin2(get_15_point[71:64]),
    .Pmin1(get_15_point[63:56]),
    .P0   (get_15_point[55:48]),
    .P1   (get_15_point[47:40]),
    .P2   (get_15_point[39:32]),
    .P3   (get_15_point[31:24]),
    .out_data(bluex_temp[6])
);

interpolation_blue blue_interpolation_point8 (
    .Pmin2(get_15_point[63:56]),
    .Pmin1(get_15_point[55:48]),
    .P0   (get_15_point[47:40]),
    .P1   (get_15_point[39:32]),
    .P2   (get_15_point[31:24]),
    .P3   (get_15_point[23:16]),
    .out_data(bluex_temp[7])
);

interpolation_blue blue_interpolation_point9 (
    .Pmin2(get_15_point[55:48]),
    .Pmin1(get_15_point[47:40]),
    .P0   (get_15_point[39:32]),
    .P1   (get_15_point[31:24]),
    .P2   (get_15_point[23:16]),
    .P3   (get_15_point[15:8]),
    .out_data(bluex_temp[8])
);

interpolation_blue blue_interpolation_point10 (
    .Pmin2(get_15_point[47:40]),
    .Pmin1(get_15_point[39:32]),
    .P0   (get_15_point[31:24]),
    .P1   (get_15_point[23:16]),
    .P2   (get_15_point[15:8]),
    .P3   (get_15_point[7:0]),
    .out_data(bluex_temp[9])
);

//MARK:Residual
reg signed [9:0]  residual_8X8 [0:7][0:7]; //maybe pipe
reg [7:0]  select_L0 [0:7][0:7];
reg [7:0]  select_L1 [0:7][0:7];
reg [4:0] start_point_L0 , start_point_L1 ;
always @(*) begin
    case(satd_cnt)
        0: begin start_point_L0 = 0  ; start_point_L1 = 22 ; end
        1: begin start_point_L0 = 10 ; start_point_L1 = 12 ; end
        2: begin start_point_L0 = 20 ; start_point_L1 = 2 ; end
        3: begin start_point_L0 = 1  ; start_point_L1 = 21 ; end
        4: begin start_point_L0 = 11 ; start_point_L1 = 11 ; end
        5: begin start_point_L0 = 21 ; start_point_L1 = 1 ; end
        6: begin start_point_L0 = 2  ; start_point_L1 = 20 ; end
        7: begin start_point_L0 = 12 ; start_point_L1 = 10 ; end
        8: begin start_point_L0 = 22 ; start_point_L1 = 0 ; end
        default: begin
            start_point_L0 = 0 ;
            start_point_L1 = 0 ;
        end
    endcase
end

always @(*) begin
    for (i = 0 ; i < 8 ; i = i + 1) begin
        for (j = 0 ; j < 8 ; j = j + 1) begin
            select_L0 [i][j] = Green_L0 [start_point_L0 + i*10 + j] ;
            select_L1 [i][j] = Green_L1 [start_point_L1 + i*10 + j] ;
        end
    end
end

always @(posedge clk) begin
    for (i = 0 ; i < 8 ; i = i + 1) begin
        for (j = 0 ; j < 8 ; j = j + 1) begin
            residual_8X8[i][j] <= select_L0[i][j] - select_L1[i][j]; //maybe pipe
        end
    end
end
wire [17:0] satd_4X4 [0:3];
reg [19:0] satd_total;

reg [3:0] minpoint ;
reg [19:0] min_satd;

// wire new_flag =   (satd_cnt == 6) || (satd_cnt == 10) || (satd_cnt == 14) || (satd_cnt == 18) || 
//                   (satd_cnt == 22) || (satd_cnt == 26) || (satd_cnt == 30) || (satd_cnt == 34) ||(satd_cnt == 38) ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) min_satd <=20'b11111111111111111111;
    else if((satd_cnt>3) && (min_satd > satd_total))  min_satd <= satd_total;
    else if(start_calu) min_satd <= 20'b11111111111111111111;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        minpoint <='b0;
    end
    else if((satd_cnt>3) && (min_satd > satd_total)) begin
        minpoint <= satd_cnt-4;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) satd_total <=0;
    else if (current_state == SATD) satd_total <= satd_4X4[0] + satd_4X4[1] + satd_4X4[2] + satd_4X4[3];
    else satd_total <= 0 ;
end


SATD_calculation satd_inst_00 (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(current_state == SATD),
    .in_0(residual_8X8[0][0]), .in_1(residual_8X8[0][1]), .in_2(residual_8X8[0][2]), .in_3(residual_8X8[0][3]),
    .in_4(residual_8X8[1][0]), .in_5(residual_8X8[1][1]), .in_6(residual_8X8[1][2]), .in_7(residual_8X8[1][3]),
    .in_8(residual_8X8[2][0]), .in_9(residual_8X8[2][1]), .in_10(residual_8X8[2][2]), .in_11(residual_8X8[2][3]),
    .in_12(residual_8X8[3][0]), .in_13(residual_8X8[3][1]), .in_14(residual_8X8[3][2]), .in_15(residual_8X8[3][3]),
    .SATD_out(satd_4X4[0])
);

SATD_calculation satd_inst_01 (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(current_state == SATD),
    .in_0 (residual_8X8[0][4]), .in_1 (residual_8X8[0][5]), .in_2 (residual_8X8[0][6]), .in_3 (residual_8X8[0][7]),
    .in_4 (residual_8X8[1][4]), .in_5 (residual_8X8[1][5]), .in_6 (residual_8X8[1][6]), .in_7 (residual_8X8[1][7]),
    .in_8 (residual_8X8[2][4]), .in_9 (residual_8X8[2][5]), .in_10(residual_8X8[2][6]), .in_11(residual_8X8[2][7]),
    .in_12(residual_8X8[3][4]), .in_13(residual_8X8[3][5]), .in_14(residual_8X8[3][6]), .in_15(residual_8X8[3][7]),
    .SATD_out(satd_4X4[1])
);

SATD_calculation satd_inst_10 (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(current_state == SATD),
    .in_0(residual_8X8[4][0]), .in_1(residual_8X8[4][1]), .in_2(residual_8X8[4][2]), .in_3(residual_8X8[4][3]),
    .in_4(residual_8X8[5][0]), .in_5(residual_8X8[5][1]), .in_6(residual_8X8[5][2]), .in_7(residual_8X8[5][3]),
    .in_8(residual_8X8[6][0]), .in_9(residual_8X8[6][1]), .in_10(residual_8X8[6][2]), .in_11(residual_8X8[6][3]),
    .in_12(residual_8X8[7][0]), .in_13(residual_8X8[7][1]), .in_14(residual_8X8[7][2]), .in_15(residual_8X8[7][3]),
    .SATD_out(satd_4X4[2])
);

SATD_calculation satd_inst_11 (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(current_state == SATD),
    .in_0(residual_8X8[4][4]), .in_1(residual_8X8[4][5]), .in_2(residual_8X8[4][6]), .in_3(residual_8X8[4][7]),
    .in_4(residual_8X8[5][4]), .in_5(residual_8X8[5][5]), .in_6(residual_8X8[5][6]), .in_7(residual_8X8[5][7]),
    .in_8(residual_8X8[6][4]), .in_9(residual_8X8[6][5]), .in_10(residual_8X8[6][6]), .in_11(residual_8X8[6][7]),
    .in_12(residual_8X8[7][4]), .in_13(residual_8X8[7][5]), .in_14(residual_8X8[7][6]), .in_15(residual_8X8[7][7]),
    .SATD_out(satd_4X4[3])  
);

//==================================================================
// MARK:Debug
//==================================================================
// reg [7:0] debug_image;
// always @(*) begin
//     debug_image = in_data[8:1];
// end

// reg [20:0] debug15X15 [0:14] [0:14] ;
// reg signed [8:0] debug10X10_L0 [0:9] [0:9] ;
// reg signed [8:0] debug10X10_L1 [0:9] [0:9] ;

// always @(*) begin
//     for(i = 0 ; i < 10 ; i = i +1 ) begin
//         for(j = 0 ; j < 10 ; j = j +1 ) begin
//             debug10X10_L0[i][j] = Green_L0[i*10 + j];
//             debug10X10_L1[i][j] = Green_L1[i*10 + j];
//         end       
//     end
// end


// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) 
//          for(i = 0 ; i <15 ; i = i +1) begin
//             for(j =0 ; j<15 ; j = j +1) begin
//                 debug15X15[i][j] <= 0;
//             end
//         end
//     else begin
//         debug15X15[14][14] <=  get_15_point[7:0] ;  debug15X15[14][13] <=  get_15_point[15:8] ;
//         debug15X15[14][12] <=  get_15_point[23:16]; debug15X15[14][11] <=  get_15_point[31:24];
//         debug15X15[14][10] <=  get_15_point[39:32]; debug15X15[14][9] <=  get_15_point[47:40];
//         debug15X15[14][8]  <=  get_15_point[55:48]; debug15X15[14][7]  <=  get_15_point[63:56];
//         debug15X15[14][6]  <=  get_15_point[71:64]; debug15X15[14][5]  <=  get_15_point[79:72];
//         debug15X15[14][4]  <=  get_15_point[87:80]; debug15X15[14][3]  <=  get_15_point[95:88];
//         debug15X15[14][2]  <=  get_15_point[103:96]; debug15X15[14][1]  <=  get_15_point[111:104];
//         debug15X15[14][0]  <=  get_15_point[119:112];

//         for(i = 0 ; i <14 ; i = i +1) begin
//             for(j =0 ; j<15 ; j = j +1) begin
//                 debug15X15[i][j] <= debug15X15[i+1][j];
//             end
//         end
//     end

// end

//==================================================================
// MARK:SRAM
//==================================================================
// reg [127:0]  S0_data_reg ,S1_data_reg;
// reg [127:0]  S0_data,S1_data;
// reg [9:0] S0_addr , S1_addr;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   input_cnt <= 'b0;
    else if ((input_cnt==15 && S0_addr==0)) input_cnt <=0;
    else if (current_state == INPUT) input_cnt <= input_cnt + 1'b1;
    else         input_cnt <= input_cnt;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   S0_data_reg <= 'b0;
    else         S0_data_reg <= S0_data;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)   S1_data_reg <= 'b0;
    else         S1_data_reg <= S1_data;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  S0_addr <= 'b0;
    else if (current_state == IDLE) S0_addr <= 'b0;
    else if (current_state == INPUT && (input_cnt==15 && S0_addr==0) || (input_cnt==31))
        S0_addr <= S0_addr + 1'b1;
    else if(start_calu) S0_addr <= (x_point[4] == 1 ) ?final_right_addr : final_left_addr ;
    else S0_addr <= S0_addr ;
    // else        
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  S1_addr <= 'b0;
    else if (current_state == IDLE) S1_addr <= 'b0;
    else if (current_state == INPUT && (input_cnt==15 && S0_addr!=0))
        S1_addr <= S1_addr + 1'b1;
    else if(start_calu) S1_addr <= (x_point[4] == 0 ) ? final_right_addr : final_left_addr ;
    else S1_addr <= S1_addr ;
end

reg early;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) early<=0;
    else if ( (current_state == INPUT) && (input_cnt==31) && (&S0_addr) ) early<=1;
    else if (current_state == IDLE) early<=0;
    else early<=early;
end


SRAM_1024X128 S0 (
    .CK(clk),
    .WEB(~(current_state == INPUT) || early ),
    .OE(1'b1),
    .CS(1'b1),
    .A(S0_addr),
    .DI(in_data_image),
    .DO(S0_data)
);

SRAM_1024X128 S1 (
    .CK(clk),
    .WEB(~(current_state == INPUT)),
    .OE(1'b1),
    .CS(1'b1),
    .A(S1_addr),
    .DI(in_data_image),
    .DO(S1_data)
);
//=======================================================
//                   MARK:Output
//=======================================================
reg [23:0] out_point1_satd , out_point2_satd ;
reg [3:0]  out_point1_search, out_point2_search ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_point1_satd <= 0;
        out_point1_search <= 0;
    end
    else if(SATD_finish_flag && (point_L_cnt == 2)) begin
        out_point1_satd <= min_satd;
        out_point1_search <= minpoint;
    end
    else begin
        out_point1_satd <= out_point1_satd;
        out_point1_search <= out_point1_search;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_point2_satd <= 0;
        out_point2_search <= 0;
    end
    else if(SATD_finish_flag && (point_L_cnt == 3)) begin
        out_point2_satd <= min_satd;
        out_point2_search <= minpoint;
    end
    else begin
        out_point2_satd <= out_point2_satd;
        out_point2_search <= out_point2_search;
    end
end

always @(*) begin
    out_sad_comb = {out_point2_search,out_point2_satd, out_point1_search, out_point1_satd};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0;
    else if (start_out_flag)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_sad <= 1'b0;
    else if (start_out_flag)
        out_sad <= out_sad_comb [out_cnt] ; //maybe shifting
    else
        out_sad <= 0;
end




endmodule


//MARK:inter
module interpolation_blue ( //Opt: pipeline 
    input [7:0] Pmin2,Pmin1, P0 , P1 , P2 , P3 ,
    output signed [14:0] out_data
);

// wire [8:0] A , B , C ;
// assign A = Pmin2 + P3 ;
// assign B = Pmin1 + P2 ;
// assign C = P0 + P1 ;
// assign out_data = (A - B) + ((C-B) <<< 2) + ( C << 4 );

assign out_data = Pmin2 - 5 * Pmin1 + 20 * P0 + 20 * P1 - 5 * P2 + P3;

endmodule

module interpolation_green ( //Opt: pipeline 
    input  signed [14:0] Pmin2,Pmin1, P0 , P1 , P2 , P3 ,
    output signed [19:0] out_data
);

assign out_data = Pmin2 - 5 * Pmin1 + 20 * P0 + 20 * P1 - 5 * P2 + P3;

endmodule


//=======================================================
//                   MARK:SATD
//=======================================================
module SATD_calculation (
    input clk,
    input rst_n,
    input in_valid,
    input signed [9:0]  in_0 , in_1 , in_2 , in_3 ,
                        in_4 , in_5 , in_6 , in_7 ,
                        in_8 , in_9 , in_10, in_11,
                        in_12, in_13, in_14, in_15,
    output reg [17:0] SATD_out //maybe
);

wire [13:0] Y [0:3][0:3]; 
reg [13:0] Y_pipe [0:3][0:3]; 

Hadamard #(.WIDTH(10)) hadamard_inst (
    .D00(in_0),   .D01(in_1),   .D02(in_2),   .D03(in_3),
    .D10(in_4),   .D11(in_5),   .D12(in_6),   .D13(in_7),
    .D20(in_8),   .D21(in_9),   .D22(in_10),  .D23(in_11),
    .D30(in_12),  .D31(in_13),  .D32(in_14),  .D33(in_15),
    .Y00(Y[0][0]),   .Y01(Y[0][1]),   .Y02(Y[0][2]),   .Y03(Y[0][3]),
    .Y10(Y[1][0]),   .Y11(Y[1][1]),   .Y12(Y[1][2]),   .Y13(Y[1][3]),
    .Y20(Y[2][0]),   .Y21(Y[2][1]),   .Y22(Y[2][2]),   .Y23(Y[2][3]),
    .Y30(Y[3][0]),   .Y31(Y[3][1]),   .Y32(Y[3][2]),   .Y33(Y[3][3])
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Y_pipe[0][0] <= 14'b0; Y_pipe[0][1] <= 14'b0; Y_pipe[0][2] <= 14'b0; Y_pipe[0][3] <= 14'b0;
        Y_pipe[1][0] <= 14'b0; Y_pipe[1][1] <= 14'b0; Y_pipe[1][2] <= 14'b0; Y_pipe[1][3] <= 14'b0;
        Y_pipe[2][0] <= 14'b0; Y_pipe[2][1] <= 14'b0; Y_pipe[2][2] <= 14'b0; Y_pipe[2][3] <= 14'b0;
        Y_pipe[3][0] <= 14'b0; Y_pipe[3][1] <= 14'b0; Y_pipe[3][2] <= 14'b0; Y_pipe[3][3] <= 14'b0;
    end
    else begin
        Y_pipe[0][0] <= Y[0][0]; Y_pipe[0][1] <= Y[0][1]; Y_pipe[0][2] <= Y[0][2]; Y_pipe[0][3] <= Y[0][3];
        Y_pipe[1][0] <= Y[1][0]; Y_pipe[1][1] <= Y[1][1]; Y_pipe[1][2] <= Y[1][2]; Y_pipe[1][3] <= Y[1][3];
        Y_pipe[2][0] <= Y[2][0]; Y_pipe[2][1] <= Y[2][1]; Y_pipe[2][2] <= Y[2][2]; Y_pipe[2][3] <= Y[2][3];
        Y_pipe[3][0] <= Y[3][0]; Y_pipe[3][1] <= Y[3][1]; Y_pipe[3][2] <= Y[3][2]; Y_pipe[3][3] <= Y[3][3];
    end
end

reg [12:0]Y_abs [0:3][0:3];

always @(*) begin
    Y_abs[0][0] = Y_pipe[0][0][13] ? (-Y_pipe[0][0]) : Y_pipe[0][0];
    Y_abs[0][1] = Y_pipe[0][1][13] ? (-Y_pipe[0][1]) : Y_pipe[0][1];
    Y_abs[0][2] = Y_pipe[0][2][13] ? (-Y_pipe[0][2]) : Y_pipe[0][2];
    Y_abs[0][3] = Y_pipe[0][3][13] ? (-Y_pipe[0][3]) : Y_pipe[0][3];
    Y_abs[1][0] = Y_pipe[1][0][13] ? (-Y_pipe[1][0]) : Y_pipe[1][0];
    Y_abs[1][1] = Y_pipe[1][1][13] ? (-Y_pipe[1][1]) : Y_pipe[1][1];
    Y_abs[1][2] = Y_pipe[1][2][13] ? (-Y_pipe[1][2]) : Y_pipe[1][2];
    Y_abs[1][3] = Y_pipe[1][3][13] ? (-Y_pipe[1][3]) : Y_pipe[1][3];
    Y_abs[2][0] = Y_pipe[2][0][13] ? (-Y_pipe[2][0]) : Y_pipe[2][0];
    Y_abs[2][1] = Y_pipe[2][1][13] ? (-Y_pipe[2][1]) : Y_pipe[2][1];
    Y_abs[2][2] = Y_pipe[2][2][13] ? (-Y_pipe[2][2]) : Y_pipe[2][2];
    Y_abs[2][3] = Y_pipe[2][3][13] ? (-Y_pipe[2][3]) : Y_pipe[2][3];
    Y_abs[3][0] = Y_pipe[3][0][13] ? (-Y_pipe[3][0]) : Y_pipe[3][0];
    Y_abs[3][1] = Y_pipe[3][1][13] ? (-Y_pipe[3][1]) : Y_pipe[3][1];
    Y_abs[3][2] = Y_pipe[3][2][13] ? (-Y_pipe[3][2]) : Y_pipe[3][2];
    Y_abs[3][3] = Y_pipe[3][3][13] ? (-Y_pipe[3][3]) : Y_pipe[3][3];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) SATD_out <=0;
    else SATD_out <= Y_abs[0][0] + Y_abs[0][1] + Y_abs[0][2] + Y_abs[0][3] +
                     Y_abs[1][0] + Y_abs[1][1] + Y_abs[1][2] + Y_abs[1][3] +
                     Y_abs[2][0] + Y_abs[2][1] + Y_abs[2][2] + Y_abs[2][3] +
                     Y_abs[3][0] + Y_abs[3][1] + Y_abs[3][2] + Y_abs[3][3];
end

endmodule
//MARK:Hadamard
module Hadamard #( 
    parameter WIDTH = 10,
    localparam MID_W = WIDTH + 2, 
    localparam OUT_W = WIDTH + 4  
)(
    input  signed [WIDTH-1:0] D00, D01, D02, D03,
    input  signed [WIDTH-1:0] D10, D11, D12, D13,
    input  signed [WIDTH-1:0] D20, D21, D22, D23,
    input  signed [WIDTH-1:0] D30, D31, D32, D33,

    output signed [OUT_W-1:0] Y00, Y01, Y02, Y03,
    output signed [OUT_W-1:0] Y10, Y11, Y12, Y13,
    output signed [OUT_W-1:0] Y20, Y21, Y22, Y23,
    output signed [OUT_W-1:0] Y30, Y31, Y32, Y33
);

    wire signed [MID_W-1:0] T00, T01, T02, T03;
    wire signed [MID_W-1:0] T10, T11, T12, T13;
    wire signed [MID_W-1:0] T20, T21, T22, T23; 
    wire signed [MID_W-1:0] T30, T31, T32, T33; 

    addsub#(.BW(WIDTH)) u_col0 (
        .I0(D00), .I1(D10), .I2(D20), .I3(D30), // Column 0
        .O0(T00), .O1(T10), .O2(T20), .O3(T30)
    );

    addsub#(.BW(WIDTH)) u_col1 (
        .I0(D01), .I1(D11), .I2(D21), .I3(D31), // Column 1
        .O0(T01), .O1(T11), .O2(T21), .O3(T31)
    );

    addsub#(.BW(WIDTH)) u_col2 (
        .I0(D02), .I1(D12), .I2(D22), .I3(D32), // Column 2
        .O0(T02), .O1(T12), .O2(T22), .O3(T32)
    );

    addsub#(.BW(WIDTH)) u_col3 (
        .I0(D03), .I1(D13), .I2(D23), .I3(D33), // Column 3
        .O0(T03), .O1(T13), .O2(T23), .O3(T33)
    );
    // Row 0
    addsub#(.BW(MID_W)) u_row0 (
        .I0(T00), .I1(T01), .I2(T02), .I3(T03), // Row 0 of T
        .O0(Y00), .O1(Y01), .O2(Y02), .O3(Y03)
    );

    // Row 1
    addsub#(.BW(MID_W)) u_row1 (
        .I0(T10), .I1(T11), .I2(T12), .I3(T13), // Row 1 of T
        .O0(Y10), .O1(Y11), .O2(Y12), .O3(Y13)
    );

    // Row 2
    addsub#(.BW(MID_W)) u_row2 (
        .I0(T20), .I1(T21), .I2(T22), .I3(T23), // Row 2 of T
        .O0(Y20), .O1(Y21), .O2(Y22), .O3(Y23)
    );

    // Row 3
    addsub#(.BW(MID_W)) u_row3 (
        .I0(T30), .I1(T31), .I2(T32), .I3(T33), // Row 3 of T
        .O0(Y30), .O1(Y31), .O2(Y32), .O3(Y33)
    );
    // reg signed [OUT_W-1:0] debug_stage1 [0:3] [0:3] ; 
    // always @(*) begin
    //     debug_stage1[0][0] = T00; debug_stage1[0][1] = T01; debug_stage1[0][2] = T02; debug_stage1[0][3] = T03;
    //     debug_stage1[1][0] = T10; debug_stage1[1][1] = T11; debug_stage1[1][2] = T12; debug_stage1[1][3] = T13;
    //     debug_stage1[2][0] = T20; debug_stage1[2][1] = T21; debug_stage1[2][2] = T22; debug_stage1[2][3] = T23;
    //     debug_stage1[3][0] = T30; debug_stage1[3][1] = T31; debug_stage1[3][2] = T32; debug_stage1[3][3] = T33;
    // end

    // reg signed [OUT_W-1:0] debug [0:3] [0:3] ; 

    // always @(*) begin
    //     debug[0][0] = Y00; debug[0][1] = Y01; debug[0][2] = Y02; debug[0][3] = Y03;
    //     debug[1][0] = Y10; debug[1][1] = Y11; debug[1][2] = Y12; debug[1][3] = Y13;
    //     debug[2][0] = Y20; debug[2][1] = Y21; debug[2][2] = Y22; debug[2][3] = Y23;
    //     debug[3][0] = Y30; debug[3][1] = Y31; debug[3][2] = Y32; debug[3][3] = Y33;
    // end

endmodule

module addsub #(parameter BW=12)(
    input signed [BW-1:0] I0, I1, I2, I3,
    output signed [BW+1:0] O0, O1, O2, O3
);
    wire signed [BW:0] s01 = I0 + I1;
    wire signed [BW:0] d01 = I0 - I1;
    wire signed [BW:0] s23 = I2 + I3;
    wire signed [BW:0] d23 = I2 - I3;
    
    assign O0 = s01 + s23;
    assign O1 = s01 - s23;
    assign O2 = d01 - d23;
    assign O3 = d01 + d23;
endmodule

//=======================================================
//                   MARK:MEM
//=======================================================
module SRAM_1024X128 (
    input CK,WEB,OE,CS,
    input [9:0] A,
    input [127:0] DI,
    output [127:0] DO
);

SRAM_1024_128 SRAM_1024_128_inst(
    .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]),
    .A5(A[5]), .A6(A[6]), .A7(A[7]), .A8(A[8]), .A9(A[9]),
    .DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]), .DO4(DO[4]),
    .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]), .DO8(DO[8]), .DO9(DO[9]),
    .DO10(DO[10]), .DO11(DO[11]), .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]),
    .DO15(DO[15]), .DO16(DO[16]), .DO17(DO[17]), .DO18(DO[18]), .DO19(DO[19]),
    .DO20(DO[20]), .DO21(DO[21]), .DO22(DO[22]), .DO23(DO[23]), .DO24(DO[24]),
    .DO25(DO[25]), .DO26(DO[26]), .DO27(DO[27]), .DO28(DO[28]), .DO29(DO[29]),
    .DO30(DO[30]), .DO31(DO[31]), .DO32(DO[32]), .DO33(DO[33]), .DO34(DO[34]),
    .DO35(DO[35]), .DO36(DO[36]), .DO37(DO[37]), .DO38(DO[38]), .DO39(DO[39]),
    .DO40(DO[40]), .DO41(DO[41]), .DO42(DO[42]), .DO43(DO[43]), .DO44(DO[44]),
    .DO45(DO[45]), .DO46(DO[46]), .DO47(DO[47]), .DO48(DO[48]), .DO49(DO[49]),
    .DO50(DO[50]), .DO51(DO[51]), .DO52(DO[52]), .DO53(DO[53]), .DO54(DO[54]),
    .DO55(DO[55]), .DO56(DO[56]), .DO57(DO[57]), .DO58(DO[58]), .DO59(DO[59]),
    .DO60(DO[60]), .DO61(DO[61]), .DO62(DO[62]), .DO63(DO[63]), .DO64(DO[64]),
    .DO65(DO[65]), .DO66(DO[66]), .DO67(DO[67]), .DO68(DO[68]), .DO69(DO[69]),
    .DO70(DO[70]), .DO71(DO[71]), .DO72(DO[72]), .DO73(DO[73]), .DO74(DO[74]),
    .DO75(DO[75]), .DO76(DO[76]), .DO77(DO[77]), .DO78(DO[78]), .DO79(DO[79]),
    .DO80(DO[80]), .DO81(DO[81]), .DO82(DO[82]), .DO83(DO[83]), .DO84(DO[84]),
    .DO85(DO[85]), .DO86(DO[86]), .DO87(DO[87]), .DO88(DO[88]), .DO89(DO[89]),
    .DO90(DO[90]), .DO91(DO[91]), .DO92(DO[92]), .DO93(DO[93]), .DO94(DO[94]),
    .DO95(DO[95]), .DO96(DO[96]), .DO97(DO[97]), .DO98(DO[98]), .DO99(DO[99]),
    .DO100(DO[100]), .DO101(DO[101]), .DO102(DO[102]), .DO103(DO[103]), .DO104(DO[104]),
    .DO105(DO[105]), .DO106(DO[106]), .DO107(DO[107]), .DO108(DO[108]), .DO109(DO[109]),
    .DO110(DO[110]), .DO111(DO[111]), .DO112(DO[112]), .DO113(DO[113]), .DO114(DO[114]),
    .DO115(DO[115]), .DO116(DO[116]), .DO117(DO[117]), .DO118(DO[118]), .DO119(DO[119]),
    .DO120(DO[120]), .DO121(DO[121]), .DO122(DO[122]), .DO123(DO[123]), .DO124(DO[124]),
    .DO125(DO[125]), .DO126(DO[126]), .DO127(DO[127]),
    .DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]), .DI4(DI[4]),
    .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]), .DI8(DI[8]), .DI9(DI[9]),
    .DI10(DI[10]), .DI11(DI[11]), .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]),
    .DI15(DI[15]), .DI16(DI[16]), .DI17(DI[17]), .DI18(DI[18]), .DI19(DI[19]),
    .DI20(DI[20]), .DI21(DI[21]), .DI22(DI[22]), .DI23(DI[23]), .DI24(DI[24]),
    .DI25(DI[25]), .DI26(DI[26]), .DI27(DI[27]), .DI28(DI[28]), .DI29(DI[29]),
    .DI30(DI[30]), .DI31(DI[31]), .DI32(DI[32]), .DI33(DI[33]), .DI34(DI[34]),
    .DI35(DI[35]), .DI36(DI[36]), .DI37(DI[37]), .DI38(DI[38]), .DI39(DI[39]),
    .DI40(DI[40]), .DI41(DI[41]), .DI42(DI[42]), .DI43(DI[43]), .DI44(DI[44]),
    .DI45(DI[45]), .DI46(DI[46]), .DI47(DI[47]), .DI48(DI[48]), .DI49(DI[49]),
    .DI50(DI[50]), .DI51(DI[51]), .DI52(DI[52]), .DI53(DI[53]), .DI54(DI[54]),
    .DI55(DI[55]), .DI56(DI[56]), .DI57(DI[57]), .DI58(DI[58]), .DI59(DI[59]),
    .DI60(DI[60]), .DI61(DI[61]), .DI62(DI[62]), .DI63(DI[63]), .DI64(DI[64]),
    .DI65(DI[65]), .DI66(DI[66]), .DI67(DI[67]), .DI68(DI[68]), .DI69(DI[69]),
    .DI70(DI[70]), .DI71(DI[71]), .DI72(DI[72]), .DI73(DI[73]), .DI74(DI[74]),
    .DI75(DI[75]), .DI76(DI[76]), .DI77(DI[77]), .DI78(DI[78]), .DI79(DI[79]),
    .DI80(DI[80]), .DI81(DI[81]), .DI82(DI[82]), .DI83(DI[83]), .DI84(DI[84]),
    .DI85(DI[85]), .DI86(DI[86]), .DI87(DI[87]), .DI88(DI[88]), .DI89(DI[89]),
    .DI90(DI[90]), .DI91(DI[91]), .DI92(DI[92]), .DI93(DI[93]), .DI94(DI[94]),
    .DI95(DI[95]), .DI96(DI[96]), .DI97(DI[97]), .DI98(DI[98]), .DI99(DI[99]),
    .DI100(DI[100]), .DI101(DI[101]), .DI102(DI[102]), .DI103(DI[103]), .DI104(DI[104]),
    .DI105(DI[105]), .DI106(DI[106]), .DI107(DI[107]), .DI108(DI[108]), .DI109(DI[109]),
    .DI110(DI[110]), .DI111(DI[111]), .DI112(DI[112]), .DI113(DI[113]), .DI114(DI[114]),
    .DI115(DI[115]), .DI116(DI[116]), .DI117(DI[117]), .DI118(DI[118]), .DI119(DI[119]),
    .DI120(DI[120]), .DI121(DI[121]), .DI122(DI[122]), .DI123(DI[123]), .DI124(DI[124]),
    .DI125(DI[125]), .DI126(DI[126]), .DI127(DI[127]),
    .CK(CK), .WEB(WEB), .OE(OE), .CS(CS)
);

endmodule

//MVDM_done.v
// Area: 2347985.253265
// Average Execution Latency: 152.115625 cycles
// Performance :   837,981,281,931,585

//MVDM_8X8done.v
// Area: 2637366.732487    681,658,921,599,657
// Average Execution Latency: 98.115625 cycles
// Performance :   681,658,921,599,657

// Startpoint: point_L_cnt_reg_0_
//               (rising edge-triggered flip-flop clocked by clk)
// Endpoint: bluex_reg_reg_1__11_
//             (rising edge-triggered flip-flop clocked by clk)


// Cycle: 7.00 but 02 slack negative
// Area: 3619094.526048
// Performance: 91684916319294.18425348812800

// Cycle: 8.00
// Area: 3161836.297243
// Performance: 79977670164506.59719520839200

//optimize 1 : only reduce Clip((Val+16)>>>5) 
// Cycle: 8.00
// Area: 3163295.577848
// Performance: 80051511302661.69782648883200

//optimize 2 : only reduce Clip((Val+512)>>>10)
// Cycle: 8.00
// Area: 3158430.265419
// Performance: 79805453932117.87829796448800

//optimize 3 : reduce Clip((Val+16)>>>5) and Clip((Val+512)>>>10) 
// Cycle: 8.00
// Area: 3158402.142064
// Performance: 79804032727955.70910544076800

//optimize 4 : interpolation blue module not good 
// Cycle: 8.00
// Area: 3170432.622323
// Performance: 80413144101519.15486333063200

//optimize 5 : early output 
// ****************************************
// Average Execution Latency: 69.379688 cycles
// Cycle: 8.00
// Area: 3158592.754574
// Performance: 79813665513978.95198337180800

// SPEC : 0~255 opt_v2
// Cycle: 8.00
// Area: 3537265.402451
// Performance: 100097972219014.67997445920800

//reduce bits
// Cycle: 8.00
// Area: 3376113.215533
// Performance: 91185123552772.58329979271200

//retime
// Cycle: 8.00
// Area: 3336878.221060
// Performance: 89078050097476.40182018880000

//reduce GetMV state

//  Average Execution Latency: 66.243750 cycles
// Cycle: 8.00
// Area: 3420335.382329
// Performance: 93589553020893.33284371392800

// pipeline residual8X8 reg

// Average Execution Latency: 68.010937 cycles 
// Cycle: 8.00
// Area: 2831373.068493
// Performance: 64133387623899.73175432839200

// ****************************************
// Cycle: 6.00
// Area: 3107761.626993
// Performance: 57949093981261.07079733229400


//register together
//==================================
// retiming
// Cycle: 8.00
// Area: 3123373.129231
// Performance: 78043677635217.99221321088800

// Cycle: 7.00
// Area: 3225797.824308
// Performance: 72840401223171.58504975204800
