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
//=======================================================
//                   Design
//=======================================================

//=======================================================
//                   MARK:FSM
//=======================================================
reg calu_finish_flag;
wire SATD_finish_flag;
wire out_finish_flag;
reg [3:0] satd_cnt;
reg [5:0] calu_cnt;
reg [5:0] out_cnt;

assign out_finish_flag = (out_cnt == 55) ;
assign SATD_finish_flag = (satd_cnt == 8) ;

typedef enum reg [3:0] {IDLE, INPUT , GETMV ,VER_INT,HOR_INT,NO_INT ,HV_INT ,SATD ,OUTPUT} Main_FSM_state;
Main_FSM_state current_state, next_state;
wire start_calu = (current_state == VER_INT || current_state == HOR_INT || current_state == NO_INT || current_state == HV_INT);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_cnt <= 0;
    else if (current_state == OUTPUT)
        out_cnt <= out_cnt + 1 ;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        satd_cnt <= 0;
    else if (current_state == SATD)
        satd_cnt <= satd_cnt + 1 ;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        calu_cnt <= 0;
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
            case (point_L_cnt)
                0 : begin
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
                end
                1 : begin
                    case ({frac_x_L1_point1 , frac_y_L1_point1} )
                        2'b00 : next_state = NO_INT;
                        2'b01 : next_state = VER_INT;
                        2'b10 : next_state = HOR_INT;
                        2'b11 : next_state = HV_INT;
                        default: next_state = IDLE;
                    endcase
                end
                2 :begin
                    case ({frac_x_L0_point2 , frac_y_L0_point2} )
                        2'b00 : next_state = NO_INT;
                        2'b01 : next_state = VER_INT;
                        2'b10 : next_state = HOR_INT;
                        2'b11 : next_state = HV_INT;
                        default: next_state = IDLE;
                    endcase
                end
                3 :  begin
                    case ({frac_x_L1_point2 , frac_y_L1_point2} )
                        2'b00 : next_state = NO_INT;
                        2'b01 : next_state = VER_INT;
                        2'b10 : next_state = HOR_INT;
                        2'b11 : next_state = HV_INT;
                        default: next_state = IDLE;
                    endcase
                end
                default:  next_state = IDLE;
            endcase
        VER_INT: 
            if(calu_finish_flag)
                next_state = (point_L_cnt[0])? SATD : GETMV;
            else
                next_state = VER_INT;
        HOR_INT:
            if(calu_finish_flag)
                next_state = (point_L_cnt[0]) ? SATD : GETMV;
            else
                next_state = HOR_INT;
        NO_INT:
            if(calu_finish_flag)
                next_state = (point_L_cnt[0])? SATD : GETMV;
            else
                next_state = NO_INT;
        HV_INT: 
            if(calu_finish_flag)
                next_state = (point_L_cnt[0])? SATD : GETMV;
            else
                next_state = HV_INT;
        SATD:
            if(SATD_finish_flag)
                next_state = (&point_L_cnt) ? OUTPUT : GETMV;
            else
                next_state = SATD;
        OUTPUT: next_state = out_finish_flag ? IDLE : OUTPUT;
        default: 
            next_state = IDLE;
    endcase
end

always @(*) begin
    case (current_state)
        VER_INT : calu_finish_flag =  calu_cnt == 32 ;
        HOR_INT : calu_finish_flag =  calu_cnt == 14 ;
        NO_INT  : calu_finish_flag =  calu_cnt == 16 ;
        HV_INT  : calu_finish_flag =  calu_cnt == 48 ;
        default : calu_finish_flag = 0 ;
    endcase
end

//=======================================================
//                   MARK:MV IO
//=======================================================
reg out_valid_comb, out_sad_comb ;
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
    else if (next_state == GETMV)
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

always @(*) begin
    if(calu_cnt < 3)
        if (&x_point[6:1]) // 0 1 edge
            left_addr = (y_point) * 4 ; //opt
        else
            left_addr = x_point[6:5] + (y_point) * 4 ; //opt
    else 
        if (&x_point[6:1]) // 0 1 edge
            left_addr = (y_point + (calu_cnt-2)) * 4 ; //opt
        else
            left_addr = x_point[6:5] + (y_point+ (calu_cnt-2)) * 4 ; //opt
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
reg signed [9:0] Green_L0 [0:99];
reg signed [9:0] Green_L1 [0:99];

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for (i=0; i<100; i=i+1) begin
            Green_L0[i] <= 'b0;
            Green_L1[i] <= 'b0;
        end
    end
    else 
        case (current_state)
            HOR_INT : begin
                if (point_L_cnt[0] == 0) begin
                    for (i=0; i<90; i=i+1)
                        Green_L0[i] <= Green_L0[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        Green_L0[i] <= (bluex_L0[i-40]+16)>>>5; //maybe
                end
                else begin
                    for (i=0; i<90; i=i+1)
                        Green_L1[i] <= Green_L1[i+10] ; 
                    for (i=90; i<100; i=i+1)
                        Green_L1[i] <= (bluex_L1[i-40]+16)>>>5; //maybe
                end
            end 
            // default: 
        endcase
    

end

//==================================================================
// MARK:Blue
//==================================================================
// reg signed [14:0] bluex_L0 [0:59];
// reg signed [14:0] bluex_L1 [0:59];

always @ (posedge clk or negedge rst_n)begin
    if(!rst_n) begin
        for (j=0; j<50; j=j+1) begin
            bluex_L0[j] <= 15'b0;
            bluex_L1[j] <= 15'b0;
        end
    end
    else 
        case (current_state)
            HOR_INT : begin
                if (point_L_cnt[0] == 0) begin
                    for (j=0; j<50; j=j+1)
                        bluex_L0[j] <= bluex_L0[j+10] ; 
                end
                else begin
                    for (j=0; j<50; j=j+1)
                        bluex_L1[j] <= bluex_L1[j+10] ; 
                end
            end 
            // default: 
        endcase
end

interpolation_blue blue_interpolation_point1 (
    .Pmin2(get_15_point[119:112]),
    .Pmin1(get_15_point[111:104]),
    .P0   (get_15_point[103:96]),
    .P1   (get_15_point[95:88]),
    .P2   (get_15_point[87:80]),
    .P3   (get_15_point[79:72]),
    .out_data(bluex_L0[50])
);

interpolation_blue blue_interpolation_point2 (
    .Pmin2(get_15_point[111:104]),
    .Pmin1(get_15_point[103:96]),
    .P0   (get_15_point[95:88]),
    .P1   (get_15_point[87:80]),
    .P2   (get_15_point[79:72]),
    .P3   (get_15_point[71:64]),
    .out_data(bluex_L0[51])
);

interpolation_blue blue_interpolation_point3 (
    .Pmin2(get_15_point[103:96]),
    .Pmin1(get_15_point[95:88]),
    .P0   (get_15_point[87:80]),
    .P1   (get_15_point[79:72]),
    .P2   (get_15_point[71:64]),
    .P3   (get_15_point[63:56]),
    .out_data(bluex_L0[52])
);

interpolation_blue blue_interpolation_point4 (
    .Pmin2(get_15_point[95:88]),
    .Pmin1(get_15_point[87:80]),
    .P0   (get_15_point[79:72]),
    .P1   (get_15_point[71:64]),
    .P2   (get_15_point[63:56]),
    .P3   (get_15_point[55:48]),
    .out_data(bluex_L0[53])
);

interpolation_blue blue_interpolation_point5 (
    .Pmin2(get_15_point[87:80]),
    .Pmin1(get_15_point[79:72]),
    .P0   (get_15_point[71:64]),
    .P1   (get_15_point[63:56]),
    .P2   (get_15_point[55:48]),
    .P3   (get_15_point[47:40]),
    .out_data(bluex_L0[54])
);

interpolation_blue blue_interpolation_point6 (
    .Pmin2(get_15_point[79:72]),
    .Pmin1(get_15_point[71:64]),
    .P0   (get_15_point[63:56]),
    .P1   (get_15_point[55:48]),
    .P2   (get_15_point[47:40]),
    .P3   (get_15_point[39:32]),
    .out_data(bluex_L0[55])
); 

interpolation_blue blue_interpolation_point7 (
    .Pmin2(get_15_point[71:64]),
    .Pmin1(get_15_point[63:56]),
    .P0   (get_15_point[55:48]),
    .P1   (get_15_point[47:40]),
    .P2   (get_15_point[39:32]),
    .P3   (get_15_point[31:24]),
    .out_data(bluex_L0[56])
);

interpolation_blue blue_interpolation_point8 (
    .Pmin2(get_15_point[63:56]),
    .Pmin1(get_15_point[55:48]),
    .P0   (get_15_point[47:40]),
    .P1   (get_15_point[39:32]),
    .P2   (get_15_point[31:24]),
    .P3   (get_15_point[23:16]),
    .out_data(bluex_L0[57])
);

interpolation_blue blue_interpolation_point9 (
    .Pmin2(get_15_point[55:48]),
    .Pmin1(get_15_point[47:40]),
    .P0   (get_15_point[39:32]),
    .P1   (get_15_point[31:24]),
    .P2   (get_15_point[23:16]),
    .P3   (get_15_point[15:8]),
    .out_data(bluex_L0[58])
);

interpolation_blue blue_interpolation_point10 (
    .Pmin2(get_15_point[47:40]),
    .Pmin1(get_15_point[39:32]),
    .P0   (get_15_point[31:24]),
    .P1   (get_15_point[23:16]),
    .P2   (get_15_point[15:8]),
    .P3   (get_15_point[7:0]),
    .out_data(bluex_L0[59])
);

//==================================================================
// MARK:Debug
//==================================================================
reg [7:0] debug_image;
always @(*) begin
    debug_image = in_data[8:1];
end

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
    else if (current_state == INPUT && (input_cnt==15 && S0_addr==0) || (input_cnt==31))
        S0_addr <= S0_addr + 1'b1;
    else if(start_calu) S0_addr <= (x_point[4] == 1 ) ?right_addr : left_addr ;
    else S0_addr <= S0_addr ;
    // else        
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  S1_addr <= 'b0;
    else if (current_state == INPUT && (input_cnt==15 && S0_addr!=0))
        S1_addr <= S1_addr + 1'b1;
    else if(start_calu) S1_addr <= (x_point[4] == 0 ) ? right_addr : left_addr ;
    else S1_addr <= S1_addr ;
    
end

SRAM_1024X128 S0 (
    .CK(clk),
    .WEB(~(current_state == INPUT)),
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
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0;
    else if (current_state == OUTPUT)
        out_valid <= 1;
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
