/**************************************************************************
 * Copyright (c) 2025, OASIS Lab
 * MODULE: CLK_1_MODULE, CLK_2_MODULE, CLK_3_MODULE
 * FILE NAME: DESIGN_module.v
 * VERSRION: 1.0
 * DATE: Oct 29, 2025
 * AUTHOR: Chao-En Kuo, NYCU IAIS
 * DESCRIPTION: ICLAB2025FALL / LAB7 / DESIGN_module
 * MODIFICATION HISTORY:
 * Date                 Description
 * 
 *************************************************************************/
module CLK_1_MODULE ( //input
    clk,
    rst_n,
    in_valid,
    in_data,
    out_idle,
    out_valid,
    out_data,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input             clk;
input             rst_n;
input             in_valid;
input      [31:0] in_data;
input             out_idle;
output reg        out_valid;
output reg [31:0] out_data;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;
reg [4:0] cnt;
parameter IDLE = 0;
parameter INPUT = 1;
parameter OUTPUT = 2;
parameter WAIT = 3;

reg [1:0] current_state, next_state;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt  <= 0;
    end
    else if (current_state == OUTPUT) begin
        cnt <= cnt + 1 ;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state  <= IDLE;
    end
    else begin
        current_state <= next_state ;
    end
end

always @ (*) begin
    case (current_state)
        IDLE: begin
            if (in_valid)
                next_state = INPUT;
            else
                next_state = IDLE;
        end
        INPUT: begin
            if (~in_valid)
                next_state = OUTPUT;
            else
                next_state = INPUT;
        end
        OUTPUT: begin
            next_state = WAIT;
        end
        WAIT: begin
            if(cnt == 16)  next_state = IDLE;
            else if (out_idle)
                next_state = OUTPUT;
            else
                next_state = WAIT;
        end

        default: next_state = IDLE;
    endcase
end

reg [31:0] indata_reg [0:15];
genvar i ; 
integer k;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(k = 0 ; k<16 ;k=k+1) indata_reg[k]  <= 0;
    end
    else if (in_valid) begin
        indata_reg[15] <= in_data;        indata_reg[14] <= indata_reg[15]; indata_reg[13] <= indata_reg[14];
        indata_reg[12] <= indata_reg[13]; indata_reg[11] <= indata_reg[12]; indata_reg[10] <= indata_reg[11];
        indata_reg[9]  <= indata_reg[10]; indata_reg[8] <= indata_reg[9];   indata_reg[7] <= indata_reg[8];
        indata_reg[6]  <= indata_reg[7];  indata_reg[5] <= indata_reg[6];   indata_reg[4] <= indata_reg[5];
        indata_reg[3]  <= indata_reg[4];  indata_reg[2] <= indata_reg[3];   indata_reg[1] <= indata_reg[2];
        indata_reg[0]  <= indata_reg[1];
    end
    else if (current_state == OUTPUT) begin
        indata_reg[15] <=0;               indata_reg[14] <= indata_reg[15]; indata_reg[13] <= indata_reg[14];
        indata_reg[12] <= indata_reg[13]; indata_reg[11] <= indata_reg[12]; indata_reg[10] <= indata_reg[11];
        indata_reg[9]  <= indata_reg[10]; indata_reg[8] <= indata_reg[9];   indata_reg[7] <= indata_reg[8];
        indata_reg[6]  <= indata_reg[7];  indata_reg[5] <= indata_reg[6];   indata_reg[4] <= indata_reg[5];
        indata_reg[3]  <= indata_reg[4];  indata_reg[2] <= indata_reg[3];   indata_reg[1] <= indata_reg[2];
        indata_reg[0]  <= indata_reg[1];
    end
end


// generate
//     for (i=0; i<16; i=i+1) begin : IN_DATA_ASSIGN
//         always @ (posedge clk or negedge rst_n) begin
//             if (!rst_n) begin
//                 indata_reg[i]  <= 0;
//             end
//             else if (in_valid)begin
//                     indata_reg[i] <= in_data ;
//                 else if (in_valid)
//                     indata_reg[i] <= indata_reg[i+1];
//             end
//             else if (current_state == OUTPUT) begin
//                if(i==15)  indata_reg[i] <= 0;
//                else indata_reg[i] <= indata_reg[i+1];
//             end
//         end
//     end
// endgenerate

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid  <= 0;
    end
    else if (current_state == OUTPUT ) begin
        out_valid <= 1 ;
    end
    else if (current_state == WAIT ) begin
        out_valid <= 0 ;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data  <= 0;
    end
    else if (current_state == OUTPUT ) begin
        out_data <= indata_reg[0] ;
    end
end

endmodule

module CLK_2_MODULE ( //NTT
    clk,
    rst_n,
    in_valid,
    in_data,
    fifo_full,
    out_valid,
    out_data,
    busy,
    
    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input             clk;
input             rst_n;
input             in_valid;
input             fifo_full;
input      [31:0] in_data;
output reg        out_valid;
output reg [15:0] out_data;
output            busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;
wire [13:0] GMb [0:127] ;
    assign GMb[0]=14'd4091;   assign GMb[1]=14'd7888;   assign GMb[2]=14'd11060;  assign GMb[3]=14'd11208;   assign GMb[4]=14'd6960;    assign GMb[5]=14'd4342;   assign GMb[6]=14'd6275;
    assign GMb[7]=14'd9759;   assign GMb[8]=14'd1591;   assign GMb[9]=14'd6399;   assign GMb[10]=14'd9477;   assign GMb[11]=14'd5266;   assign GMb[12]=14'd586;   assign GMb[13]=14'd5825;
    assign GMb[14]=14'd7538;  assign GMb[15]=14'd9710;  assign GMb[16]=14'd1134;  assign GMb[17]=14'd6407;   assign GMb[18]=14'd1711;   assign GMb[19]=14'd965;   assign GMb[20]=14'd7099;
    assign GMb[21]=14'd7674;  assign GMb[22]=14'd3743;  assign GMb[23]=14'd6442;  assign GMb[24]=14'd10414;  assign GMb[25]=14'd8100;   assign GMb[26]=14'd1885;  assign GMb[27]=14'd1688;
    assign GMb[28]=14'd1364;  assign GMb[29]=14'd10329; assign GMb[30]=14'd10164; assign GMb[31]=14'd9180;   assign GMb[32]=14'd12210;  assign GMb[33]=14'd6240;  assign GMb[34]=14'd997;
    assign GMb[35]=14'd117;   assign GMb[36]=14'd4783;  assign GMb[37]=14'd4407;  assign GMb[38]=14'd1549;   assign GMb[39]=14'd7072;   assign GMb[40]=14'd2829;  assign GMb[41]=14'd6458;
    assign GMb[42]=14'd4431;  assign GMb[43]=14'd8877;  assign GMb[44]=14'd7144;  assign GMb[45]=14'd2564;   assign GMb[46]=14'd5664;   assign GMb[47]=14'd4042;  assign GMb[48]=14'd12189;
    assign GMb[49]=14'd432;   assign GMb[50]=14'd10751; assign GMb[51]=14'd1237;  assign GMb[52]=14'd7610;   assign GMb[53]=14'd1534;   assign GMb[54]=14'd3983;  assign GMb[55]=14'd7863;
    assign GMb[56]=14'd2181;  assign GMb[57]=14'd6308;  assign GMb[58]=14'd8720;  assign GMb[59]=14'd6570;   assign GMb[60]=14'd4843;   assign GMb[61]=14'd1690;  assign GMb[62]=14'd14;
    assign GMb[63]=14'd3872;  assign GMb[64]=14'd5569;  assign GMb[65]=14'd9368;  assign GMb[66]=14'd12163;  assign GMb[67]=14'd2019;   assign GMb[68]=14'd7543;  assign GMb[69]=14'd2315;
    assign GMb[70]=14'd4673;  assign GMb[71]=14'd7340;  assign GMb[72]=14'd1553;  assign GMb[73]=14'd1156;   assign GMb[74]=14'd8401;   assign GMb[75]=14'd11389; assign GMb[76]=14'd1020;
    assign GMb[77]=14'd2967;  assign GMb[78]=14'd10772; assign GMb[79]=14'd7045;  assign GMb[80]=14'd3316;   assign GMb[81]=14'd11236;  assign GMb[82]=14'd5285;  assign GMb[83]=14'd11578;
    assign GMb[84]=14'd10637; assign GMb[85]=14'd10086; assign GMb[86]=14'd9493;  assign GMb[87]=14'd6180;   assign GMb[88]=14'd9277;   assign GMb[89]=14'd6130;  assign GMb[90]=14'd3323;
    assign GMb[91]=14'd883;   assign GMb[92]=14'd10469; assign GMb[93]=14'd489;   assign GMb[94]=14'd1502;   assign GMb[95]=14'd2851;   assign GMb[96]=14'd11061; assign GMb[97]=14'd9729;
    assign GMb[98]=14'd2742;  assign GMb[99]=14'd12241; assign GMb[100]=14'd4970; assign GMb[101]=14'd10481; assign GMb[102]=14'd10078; assign GMb[103]=14'd1195; assign GMb[104]=14'd730;
    assign GMb[105]=14'd1762; assign GMb[106]=14'd3854; assign GMb[107]=14'd2030; assign GMb[108]=14'd5892;  assign GMb[109]=14'd10922; assign GMb[110]=14'd9020; assign GMb[111]=14'd5274;
    assign GMb[112]=14'd9179; assign GMb[113]=14'd3604; assign GMb[114]=14'd3782; assign GMb[115]=14'd10206; assign GMb[116]=14'd3180;  assign GMb[117]=14'd3467; assign GMb[118]=14'd4668;
    assign GMb[119]=14'd2446; assign GMb[120]=14'd7613; assign GMb[121]=14'd9386; assign GMb[122]=14'd834;   assign GMb[123]=14'd7703;  assign GMb[124]=14'd6836; assign GMb[125]=14'd3403;
    assign GMb[126]=14'd5351; assign GMb[127]=14'd12276;

reg [3:0] x [0:127];
reg [7:0] cnt; //256
reg [15:0] out_data_reg [0:127] ; 
assign busy = 0 ;
reg [4:0] input_cnt;
reg [6:0] output_cnt;
wire [15:0] x_output_stage7;
genvar i;
//---------------------------------------------------------------------
//   FSM    
//---------------------------------------------------------------------
parameter IDLE = 0 ; 
parameter INPUT = 1 ;
parameter COMPUTE = 2 ;
parameter OUTPUT = 3 ;
parameter WAIT = 4 ;
reg [2:0] current_state, next_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state  <= IDLE;
    end
    else begin
        current_state <= next_state ;
    end
end

always @ (*) begin
    case(current_state)
        IDLE: begin
            if (in_valid)
                next_state = INPUT;
            else
                next_state = IDLE;
        end
        INPUT: begin
            if (input_cnt <= 15)
                next_state = INPUT;
            else
                next_state = COMPUTE;
        end
        COMPUTE: begin
            if (cnt == 255)
                next_state = OUTPUT;
            else
                next_state = COMPUTE;
        end
        OUTPUT: begin
            if (fifo_full) next_state = WAIT;
            else if (output_cnt < 128)
                next_state = OUTPUT;
            else
                next_state = IDLE;
        end
        WAIT : begin
            if (~fifo_full)
                next_state = OUTPUT;
            else
                next_state = WAIT;
        end

        default: next_state = IDLE;

    endcase
end
//---------------------------------------------------------------------
//  counter
//---------------------------------------------------------------------


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) output_cnt  <= 0;
    else if(current_state == OUTPUT && (output_cnt <= 127) && !fifo_full)begin
        output_cnt <= output_cnt + 1 ;
    end
    else if (current_state == IDLE) begin
        output_cnt <= 0 ;
    end
    else
        output_cnt <= output_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) input_cnt  <= 0;
    else if(in_valid)begin
        input_cnt <= input_cnt + 1 ;
    end
    else if (current_state == IDLE) begin
        input_cnt <= 0 ;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) cnt  <= 0;
    else if(current_state == COMPUTE)begin
        cnt <= cnt + 1 ;
    end
    else if (current_state == IDLE) begin
        cnt <= 0 ;
    end
end

//---------------------------------------------------------------------
//  input to x
//---------------------------------------------------------------------
wire [3:0] x_data [0:7];
assign x_data[0] = in_data[3:0];
assign x_data[1] = in_data[7:4];
assign x_data[2] = in_data[11:8];
assign x_data[3] = in_data[15:12];
assign x_data[4] = in_data[19:16];
assign x_data[5] = in_data[23:20];
assign x_data[6] = in_data[27:24];
assign x_data[7] = in_data[31:28];

integer j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j=0; j<128; j=j+1) begin
            x[j] <= 0;
        end
    end
    else if (in_valid) begin
        case(input_cnt)
            0 : {x[7] ,x[6],x[5] ,x[4],x[3],x[2],x[1],x[0]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            1 : {x[15],x[14],x[13],x[12],x[11],x[10],x[9],x[8]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            2 : {x[23],x[22],x[21],x[20],x[19],x[18],x[17],x[16]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            3 : {x[31],x[30],x[29],x[28],x[27],x[26],x[25],x[24]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            4 : {x[39],x[38],x[37],x[36],x[35],x[34],x[33],x[32]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            5 : {x[47],x[46],x[45],x[44],x[43],x[42],x[41],x[40]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            6 : {x[55],x[54],x[53],x[52],x[51],x[50],x[49],x[48]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            7 : {x[63],x[62],x[61],x[60],x[59],x[58],x[57],x[56]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            8 : {x[71],x[70],x[69],x[68],x[67],x[66],x[65],x[64]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            9 : {x[79],x[78],x[77],x[76],x[75],x[74],x[73],x[72]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            10: {x[87],x[86],x[85],x[84],x[83],x[82],x[81],x[80]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            11: {x[95],x[94],x[93],x[92],x[91],x[90],x[89],x[88]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            12: {x[103],x[102],x[101],x[100],x[99],x[98],x[97],x[96]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            13: {x[111],x[110],x[109],x[108],x[107],x[106],x[105],x[104]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            14: {x[119],x[118],x[117],x[116],x[115],x[114],x[113],x[112]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            15: {x[127],x[126],x[125],x[124],x[123],x[122],x[121],x[120]} <= {x_data[7],x_data[6],x_data[5],x_data[4],x_data[3],x_data[2],x_data[1],x_data[0]} ;
            default: ;
        endcase
    end
end

// generate
//     for (i=0; i<8; i=i+1) begin : IN_DATA_ASSIGN
//         always @ (posedge clk or negedge rst_n) begin
//             if (!rst_n) begin
//                 x[i]  <= 0;
//             end
//             else if (in_valid)begin
//                 if(input_cnt<16)
//                     x[i+input_cnt*8] <= x_data[i] ;
//             end
//         end
//     end
// endgenerate

reg [3:0] x_input_seq;

always @ (*) begin
    if (cnt<128)
        x_input_seq = x[cnt];
    else
        x_input_seq = 0;
end
//---------------------------------------------------------------------
//  NTT COMPUTE
//---------------------------------------------------------------------
NTT #( .buffernum(64) , .stage(7) ) NTT_stage7(
    .clk (clk),
    .rst_n (rst_n),
    .in_data ({12'd0,x_input_seq}),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb[0]),
    .out_control (cnt[6]) ,
    .buf_control (cnt[6]) ,
    .out_data (x_output_stage7)
);
reg [13:0] GMb_stage6;

always @(*) begin
    if (cnt>=96 && cnt<=127)
        GMb_stage6 = GMb[1];
    else if (cnt>=160 && cnt<=191)
        GMb_stage6 = GMb[2];
    else 
        GMb_stage6 = 0;
end

wire [15:0] x_output_stage6;
NTT #( .buffernum(32) , .stage(6) ) NTT_stage6( //64input
    .clk (clk),
    .rst_n (rst_n),
    .in_data (x_output_stage7),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb_stage6),
    .out_control (cnt[5]) ,
    .buf_control (cnt[5]) ,
    .out_data (x_output_stage6)
);

reg [13:0] GMb_stage5;

always @(*) begin
    case(1)
        (cnt>=112 && cnt <=127): GMb_stage5 = GMb[3];
        (cnt>=144 && cnt <=159): GMb_stage5 = GMb[4];
        (cnt>=176 && cnt <=191): GMb_stage5 = GMb[5];
        (cnt>=207 && cnt <=223): GMb_stage5 = GMb[6];
        default : GMb_stage5 = 0;
    endcase
end
wire [15:0] x_output_stage5;
NTT #( .buffernum(16) , .stage(5) ) NTT_stage5( //32input
    .clk (clk),
    .rst_n (rst_n),
    .in_data (x_output_stage6),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb_stage5),
    .out_control (cnt[4]) ,
    .buf_control (cnt[4]) ,
    .out_data (x_output_stage5)
);

reg [13:0] GMb_stage4;

always @(*) begin
    case(1)
        (cnt>=120 && cnt <=127): GMb_stage4 = GMb[7];
        (cnt>=136 && cnt <=143): GMb_stage4 = GMb[8];
        (cnt>=152 && cnt <=159): GMb_stage4 = GMb[9];
        (cnt>=168 && cnt <=175): GMb_stage4 = GMb[10];
        (cnt>=184 && cnt <=191): GMb_stage4 = GMb[11];
        (cnt>=200 && cnt <=207): GMb_stage4 = GMb[12];
        (cnt>=216 && cnt <=223): GMb_stage4 = GMb[13];
        (cnt>=232 && cnt <=239): GMb_stage4 = GMb[14];
        default : GMb_stage4 = 0;
    endcase
end

wire [15:0] x_output_stage4;
NTT #( .buffernum(8) , .stage(4) ) NTT_stage4( 
    .clk (clk),
    .rst_n (rst_n),
    .in_data (x_output_stage5),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb_stage4),
    .out_control (cnt[3]) ,
    .buf_control (cnt[3]) ,
    .out_data (x_output_stage4)
);

reg [13:0] GMb_stage3;

always @(*) begin
    case(1)
        (cnt>=124 && cnt <=127): GMb_stage3 = GMb[15];
        (cnt>=132 && cnt <=135): GMb_stage3 = GMb[16];
        (cnt>=140 && cnt <=143): GMb_stage3 = GMb[17];
        (cnt>=148 && cnt <=151): GMb_stage3 = GMb[18];
        (cnt>=156 && cnt <=159): GMb_stage3 = GMb[19];
        (cnt>=164 && cnt <=167): GMb_stage3 = GMb[20];
        (cnt>=172 && cnt <=175): GMb_stage3 = GMb[21];
        (cnt>=180 && cnt <=183): GMb_stage3 = GMb[22];
        (cnt>=188 && cnt <=191): GMb_stage3 = GMb[23];
        (cnt>=196 && cnt <=199): GMb_stage3 = GMb[24];
        (cnt>=204 && cnt <=207): GMb_stage3 = GMb[25];
        (cnt>=212 && cnt <=215): GMb_stage3 = GMb[26];
        (cnt>=220 && cnt <=223): GMb_stage3 = GMb[27];
        (cnt>=228 && cnt <=231): GMb_stage3 = GMb[28];
        (cnt>=236 && cnt <=239): GMb_stage3 = GMb[29];
        (cnt>=244 && cnt <=247): GMb_stage3 = GMb[30];
        default : GMb_stage3 = 0;
    endcase
end

wire [15:0] x_output_stage3;
NTT #( .buffernum(4) , .stage(3) ) NTT_stage3( 
    .clk (clk),
    .rst_n (rst_n),
    .in_data (x_output_stage4),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb_stage3),
    .out_control (cnt[2]) ,
    .buf_control (cnt[2]) ,
    .out_data (x_output_stage3)
);

reg [13:0] GMb_stage2;

always @(*) begin
    case(1)
        (cnt==126 || cnt ==127): GMb_stage2 = GMb[31];
        (cnt==130 || cnt ==131): GMb_stage2 = GMb[32];
        (cnt==134 || cnt ==135): GMb_stage2 = GMb[33];
        (cnt==138 || cnt ==139): GMb_stage2 = GMb[34];
        (cnt==142 || cnt ==143): GMb_stage2 = GMb[35];
        (cnt==146 || cnt ==147): GMb_stage2 = GMb[36];
        (cnt==150 || cnt ==151): GMb_stage2 = GMb[37];
        (cnt==154 || cnt ==155): GMb_stage2 = GMb[38];
        (cnt==158 || cnt ==159): GMb_stage2 = GMb[39];  
        (cnt==162 || cnt ==163): GMb_stage2 = GMb[40];  
        (cnt==166 || cnt ==167): GMb_stage2 = GMb[41];
        (cnt==170 || cnt ==171): GMb_stage2 = GMb[42];
        (cnt==174 || cnt ==175): GMb_stage2 = GMb[43];
        (cnt==178 || cnt ==179): GMb_stage2 = GMb[44];
        (cnt==182 || cnt ==183): GMb_stage2 = GMb[45];
        (cnt==186 || cnt ==187): GMb_stage2 = GMb[46];
        (cnt==190 || cnt ==191): GMb_stage2 = GMb[47];
        (cnt==194 || cnt ==195): GMb_stage2 = GMb[48];
        (cnt==198 || cnt ==199): GMb_stage2 = GMb[49];
        (cnt==202 || cnt ==203): GMb_stage2 = GMb[50];
        (cnt==206 || cnt ==207): GMb_stage2 = GMb[51];
        (cnt==210 || cnt ==211): GMb_stage2 = GMb[52];
        (cnt==214 || cnt ==215): GMb_stage2 = GMb[53];
        (cnt==218 || cnt ==219): GMb_stage2 = GMb[54];
        (cnt==222 || cnt ==223): GMb_stage2 = GMb[55];
        (cnt==226 || cnt ==227): GMb_stage2 = GMb[56];
        (cnt==230 || cnt ==231): GMb_stage2 = GMb[57];
        (cnt==234 || cnt ==235): GMb_stage2 = GMb[58];
        (cnt==238 || cnt ==239): GMb_stage2 = GMb[59];
        (cnt==242 || cnt ==243): GMb_stage2 = GMb[60];
        (cnt==246 || cnt ==247): GMb_stage2 = GMb[61];
        (cnt==250 || cnt ==251): GMb_stage2 = GMb[62];
        default : GMb_stage2 = 0;
    endcase
end

wire [15:0] x_output_stage2;
NTT #( .buffernum(2) , .stage(2) ) NTT_stage2( 
    .clk (clk),
    .rst_n (rst_n),
    .in_data (x_output_stage3),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb_stage3),
    .out_control (cnt[1]) ,
    .buf_control (cnt[1]) ,
    .out_data (x_output_stage2)
);

reg [13:0] GMb_stage1;

always @(*) begin
    if(cnt>=127 && cnt<=254)
        if(cnt%2 == 1) GMb_stage1 = GMb[(cnt-127)/2 +63];
        else GMb_stage1 = 0;
    else
        GMb_stage1 = 0;
end

wire [15:0] x_output_stage1;
NTT #( .buffernum(1) , .stage(1) ) NTT_stage1( 
    .clk (clk),
    .rst_n (rst_n),
    .in_data (x_output_stage2),
    .work_flag (current_state == COMPUTE),
    .GMb (GMb_stage3),
    .out_control (cnt[0]) ,
    .buf_control (cnt[0]) ,
    .out_data (x_output_stage1)
);
//---------------------------------------------------------------------
//  output store
//---------------------------------------------------------------------
generate
    for (i=0; i<128; i=i+1) begin : OUT_DATA_ASSIGN
        always @ (posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                out_data_reg[i]  <= 0;
            end
            else if ((current_state == COMPUTE) && (cnt >=127) && (cnt<=254))begin
                if(i==127)
                    out_data_reg[i] <= x_output_stage1 ;
                else 
                    out_data_reg[i] <= out_data_reg[i+1];
            end
        end
    end
endgenerate

//---------------------------------------------------------------------
//  output
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid  <= 0;
    end
    else if ((current_state == OUTPUT) && !fifo_full) begin
        out_valid <= 1 ;
    end
    else begin
        out_valid <= 0 ;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data  <= 0;
    end
    else if ((current_state == OUTPUT) && !fifo_full) begin
        out_data <= out_data_reg[output_cnt] ; //change 
    end
end

endmodule

module CLK_3_MODULE ( //output
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_fifo_to_clk3,
    flag_clk3_to_fifo
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input             clk;
input             rst_n;
input             fifo_empty;
input      [15:0] fifo_rdata;
output reg        fifo_rinc;
output reg        out_valid;
output reg [15:0] out_data;

// You can change the input / output of the custom flag ports
input  flag_fifo_to_clk3;
output flag_clk3_to_fifo;
reg [15:0] fifo_rdata_reg;
parameter IDLE = 0;
// parameter WAIT_SRAM = 1;
parameter OUTPUT = 2;
parameter WAIT = 3 ;
reg [1:0] current_state, next_state;  
//fsm
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state  <= IDLE;
    end
    else begin
        current_state <= next_state ;
    end
end

always @ (*) begin
    case(current_state)
        IDLE: begin
            if (!fifo_empty)
                next_state = OUTPUT;
            else
                next_state = IDLE;
        end
        // WAIT_SRAM : next_state = OUTPUT ;
        OUTPUT: begin
            if(!fifo_empty)
                next_state = OUTPUT;
            else
                next_state = WAIT;
        end
        WAIT: begin
            if (fifo_empty)
                next_state = WAIT;
            else
                next_state = OUTPUT;
        end
        default: next_state = IDLE;
    endcase
end

reg [7:0] out_cnt;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_cnt  <= 0;
    end
    else if (current_state == OUTPUT) begin
        out_cnt <= out_cnt + 1 ;
    end
    else if (current_state == IDLE) begin
        out_cnt <= 0 ;
    end
    else
        out_cnt <= out_cnt;
end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         fifo_rdata_reg  <= 0;
//     end
//     else begin
//         fifo_rdata_reg <= fifo_rdata ;
//     end
// end


always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data  <= 0;
    end
    else if(current_state == OUTPUT) begin
        out_data <= fifo_rdata ;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid  <= 0;
    end
    else if(current_state == OUTPUT) begin
        out_valid <= 1 ;
    end
end

always @(*) fifo_rinc = (!fifo_empty);
// always @ (posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         fifo_rinc  <= 0;
//     end
//     else if(current_state == IDLE) begin
//         fifo_rinc <= 1 ;
//     end
// end

endmodule


module butterfly_unit (
    x_i, 
    x_j,
    x_i_out,    
    x_j_out    
);

input  [15:0]   x_i;      // u
input  [15:0]   x_j;      // v
output [15:0]   x_i_out;  // (u + v) mod Q
output [15:0]   x_j_out;  // (u - v) mod Q

parameter Q  = 16'd12289; 

assign x_i_out = (x_i + x_j) % Q;
assign x_j_out = (x_i>=x_j) ? (x_i - x_j) : (x_i - x_j+ Q);

endmodule

module modq_mul (
    a,
    b, //GMb
    result
);
input  [15:0] a; //maybe 4bits?
input  [13:0] b;
output [15:0] result;

parameter  Q   = 14'd12289;
parameter  QOI = 14'd12287; 

wire [31:0] x = a * b;

wire [45:0] y_temp = x * QOI;

wire [15:0] y = y_temp[15:0];

wire [29:0] y_Q = y * Q;

wire [32:0] z_temp = x + y_Q;

wire [16:0] z = z_temp[32:16];

assign result = (z >= Q) ? (z - Q) : z;

endmodule

module NTT # (
    parameter buffernum = 64 ,
    parameter stage = 7 
) (
    clk,
    rst_n,
    in_data,
    work_flag,
    GMb,
    out_control,
    buf_control,
    out_data
);
input             clk;
input             rst_n;
input      [15:0]  in_data;
input      [13:0] GMb;
input             work_flag;
input             out_control;
input             buf_control;
output reg [15:0] out_data;

reg [15:0] buffer [0: buffernum-1];
wire [15:0] GMb_temp;
wire [15:0] buf_temp;
wire [15:0] out_butterfly;
wire [15:0] buf_butterfly;
reg [15:0] buf_in;
assign buf_temp = buffer[0];

modq_mul multGMb (.a(in_data) , .b(GMb) , .result(GMb_temp) ) ;

butterfly_unit BUU (
    .x_i ( buf_temp ),   .x_j ( GMb_temp ),
    .x_i_out ( out_butterfly ),  .x_j_out ( buf_butterfly )
);

always @(*) begin
    if(out_control)
        out_data = out_butterfly ;
    else
        out_data = buf_temp ;
end

always @(*) begin
    if(buf_control)
        buf_in = buf_butterfly ;
    else
        buf_in = in_data ;
end
genvar i ; 

generate 
    for (i=0; i<buffernum; i=i+1) begin : BUFFER_ASSIGN
        always @ (posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                buffer[i]  <= 0;
            end
            else if (!work_flag) buffer[i]  <= 0;
            else begin
                if(i == buffernum-1)
                    buffer[i] <= buf_in ;
                else
                    buffer[i] <= buffer[i+1] ;
            end
        end
    end
endgenerate


endmodule