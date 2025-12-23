module HLPTE(
    // input signals
    clk,
    rst_n,
    in_valid_data,
    in_valid_param,
    
    data,
	index,
	mode,
    QP,
	
    // output signals
    out_valid,
    out_value
);

input                     clk;
input                     rst_n;
input                     in_valid_data;
input                     in_valid_param;

input              [7:0]  data;
input              [3:0]  index;
input                     mode;
input              [4:0]  QP;

output reg                out_valid;
output reg signed [31:0]  out_value;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 0;
parameter INPUT_FRAME = 1;
parameter INPUT_PARAM = 2;
parameter WAIT_4X4    = 3;
parameter WAIT_16X16  = 4;
parameter PREDICT     = 5;
parameter UPDATE_SAD  = 6;

parameter UPDATE_EDGE = 10;

integer m,n;
//==================================================================
// reg & wire
//==================================================================
reg   [5:0]  state_c,state_n;
reg   [7:0]  frame_data;
reg   [7:0]  data_reg;
reg   [3:0]  block_mode;
reg   [3:0]  index_reg;

reg   [7:0] block_data [0:15] [0:15];
reg   [7:0] left_edge [0:15];
reg   [7:0] top_edge [0:31];
reg signed [7:0] residual_dc [0:15][0:15];
reg signed [7:0] residual_horizontal [0:15][0:15];
reg signed [7:0] residual_vertical [0:15][0:15];
reg   [7:0] prediction [0:15][0:15];

reg   [31:0] sad_dc,sad_horizontal,sad_vertical;
reg   [1:0]  prediction_state;
parameter DC     = 2'd0;
parameter DC_V   = 2'd1;
parameter DC_H   = 2'd2;
parameter DC_H_V = 2'd3;
//==================================================================
// Counter
//==================================================================
reg [13:0] frame_cnt;
reg [1:0] param_cnt;
reg [9:0] unit_cnt;
reg [9:0] addr_cnt;
reg [1:0] blank_cnt; //out_cnt is 256 512 768 plus here
reg [3:0] index_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) blank_cnt <= 2'd0;
    else if(state_c == INPUT_FRAME ) blank_cnt <= 2'd0;
    else if(unit_cnt==256 || unit_cnt==512 || unit_cnt == 768) blank_cnt <= blank_cnt + 2'd1;
    else blank_cnt <= 2'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_cnt <= 10'd0;
    else if(state_c == WAIT_16X16 || state_c == WAIT_4X4) addr_cnt <= addr_cnt + 10'd1;
    else addr_cnt <= 10'd0;
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) frame_cnt <= 14'd0;
    else if(in_valid_data) frame_cnt <= frame_cnt + 14'd1;
    else if (state_c == WAIT_4X4 || state_c == WAIT_16X16) 
        frame_cnt <= 1024 * index_reg
                    + ((addr_cnt % 16) % 4)
                    + (((addr_cnt % 16) / 4) * 32)
                    + (((addr_cnt / 16) % 4) * 4)
                    + ((addr_cnt / 64) * 128);
    else frame_cnt <= 14'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) param_cnt <= 3'd0;
    else if(in_valid_param) param_cnt <= param_cnt + 3'd1;
    else param_cnt <= 3'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) unit_cnt <= 10'd0;
    else if (state_c == INPUT_PARAM) unit_cnt <= 10'd0;
    else if((state_c == WAIT_4X4 || state_c == WAIT_16X16 ) && addr_cnt>1) unit_cnt <= unit_cnt + 10'd1;
    else unit_cnt <= unit_cnt;
end

//==================================================================
// FSM
//==================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state_c <= IDLE;
    else       state_c <= state_n;
end

always @(*) begin
    case(state_c)
        IDLE: begin
            if(in_valid_data) state_n = INPUT_FRAME;
            else if(in_valid_param) state_n = INPUT_PARAM;
            else state_n = IDLE;
        end
        INPUT_FRAME: begin
            if(frame_cnt == 14'd16383 ) state_n = IDLE;
            else state_n = INPUT_FRAME;
        end
        INPUT_PARAM: begin
            if(in_valid_param) state_n = INPUT_PARAM;
            else if(block_mode[0] == 1'b1) state_n = WAIT_16X16;
            else state_n = WAIT_4X4;
        end
        WAIT_4X4 : begin
            if(unit_cnt == 10'd15) state_n = PREDICT;
            else state_n = WAIT_4X4;
        end
        WAIT_16X16 : begin
            if(unit_cnt == 10'd255) state_n = UPDATE_SAD;
            else state_n = WAIT_16X16;
        end
        default: state_n = IDLE;
    endcase
end

//==================================================================
// Parameter : Block mode  index_reg
//==================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) index_reg <= 4'd0;
    else if(in_valid_param  && param_cnt == 0 ) index_reg <= index;
    else index_reg <= index_reg;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) block_mode <= 4'd0;
    else if(in_valid_param)
        block_mode[param_cnt] <= mode;
    else block_mode <= block_mode;
end

//==================================================================
// Edge
//==================================================================
// reg [7:0] top_edge [0:31];
// reg [7:0] left_edge [0:15];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= 8'd0;
        end
    end
    else if(state_c == INPUT_PARAM) begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= 0;
        end
    end
    else if (state_c ==UPDATE_EDGE)begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= top_edge[m]; //deal with edge 
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= 8'd0;
        end
    end
    else if(state_c == INPUT_PARAM) begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= 0;
        end
    end
    else if (state_c ==UPDATE_EDGE)begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= left_edge[m]; //deal with edge 
        end
    end
end

//==================================================================
// Prediction
//==================================================================
// reg   [1:0]  prediction_state;
// parameter DC     = 2'd0;
// parameter DC_V   = 2'd1;
// parameter DC_H   = 2'd2;
// parameter DC_H_V = 2'd3;

always @ (*) begin
    if(blank_cnt == 0) begin
        if(block_mode[0]==1) prediction_state = DC;
        else begin
            case(1)
                (unit_cnt<16) : prediction_state = DC;
                (unit_cnt<=63 && unit_cnt<=16) : prediction_state = DC_H;
                (unit_cnt<=79 && unit_cnt<=64) : prediction_state = DC_V;
                (unit_cnt<=143 && unit_cnt<=128) : prediction_state = DC_V;
                (unit_cnt<=207 && unit_cnt<=192) : prediction_state = DC_V;
                default : prediction_state = DC_H_V;
            endcase
        end
    end
    else if (blank_cnt == 1) begin
        if(block_mode[1]==1) prediction_state = DC_H;
        else begin
            case(1)
                (unit_cnt<=319 && unit_cnt<=256) : prediction_state = DC_H;
                default : prediction_state = DC_H_V;
            endcase
        end
    end
    else if (blank_cnt ==2 ) begin
        if(block_mode[2]==1) prediction_state = DC_V;
        else begin
            case(1)
                (unit_cnt<=528 && unit_cnt<=512) : prediction_state = DC_V;
                (unit_cnt<=592 && unit_cnt<=576) : prediction_state = DC_V;
                (unit_cnt<=656 && unit_cnt<=640) : prediction_state = DC_V;
                (unit_cnt<=720 && unit_cnt<=704) : prediction_state = DC_V;
                default : prediction_state = DC_H_V;
            endcase
        end
    end
    else begin
        prediction_state = DC_H_V;
    end
end

//==================================================================
// SAD and Residual
//==================================================================
// reg  signed  [7:0] residual_dc [0:15][0:15];
// reg  signed [7:0] residual_horizontal [0:15][0:15];
// reg  signed [7:0] residual_vertical [0:15][0:15];
// reg   [7:0] prediction [0:15][0:15];
// reg   [31:0] sad_dc,sad_horizontal,sad_vertical;
always @ (posedge clk) begin
    if(unit_cnt == 256 || unit_cnt == 512 || unit_cnt ==712 || unit_cnt ==1024) begin
        for(m=0; m<16; m=m+1) begin
            for(n=0; n<16; n=n+1) begin
                residual_dc[m][n] <= 8'd0;
            end
        end
    end
    else if(prediction_state == DC && unit_cnt>0)
        residual_dc[(unit_cnt-1)/16][(unit_cnt-1)%16] <= block_data[(unit_cnt-1)/16][(unit_cnt-1)%16] - 128 ;
    // else if(prediction_state == DC_H) begin
      


    // end
    // else if(prediction_state == DC_V) begin
      
    // end  
    // else begin
      


    // end 
    else begin
        for(m=0; m<16; m=m+1) begin
            for(n=0; n<16; n=n+1) begin
                residual_dc[m][n] <= residual_dc[m][n];
            end
        end
    end

end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_dc <= 32'd0;
    else if(state_c == WAIT_16X16 || state_c == WAIT_4X4) begin
        if(residual_dc[unit_cnt/16][unit_cnt%16] >0 )
            sad_dc <= sad_dc + residual_dc[unit_cnt/16][unit_cnt%16];
        else 
            sad_dc <= sad_dc - residual_dc[unit_cnt/16][unit_cnt%16];
    end
    else sad_dc <= sad_dc;
end
//==================================================================
// Get Date From SRAM
//==================================================================

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0; m<16; m=m+1) begin
            for(n=0; n<16; n=n+1) begin
                block_data[m][n] <= 8'd0;
            end
        end
    end
    else if(state_c == WAIT_4X4 || state_c == WAIT_16X16) begin
       case (unit_cnt)
            0   : block_data[0][0] <= frame_data;
            1   : block_data[0][1] <= frame_data;
            2   : block_data[0][2] <= frame_data;
            3   : block_data[0][3] <= frame_data;
            4   : block_data[1][0] <= frame_data;
            5   : block_data[1][1] <= frame_data;
            6   : block_data[1][2] <= frame_data;
            7   : block_data[1][3] <= frame_data;
            8   : block_data[2][0] <= frame_data;
            9   : block_data[2][1] <= frame_data;
            10  : block_data[2][2] <= frame_data;
            11  : block_data[2][3] <= frame_data;
            12  : block_data[3][0] <= frame_data;
            13  : block_data[3][1] <= frame_data;
            14  : block_data[3][2] <= frame_data;
            15  : block_data[3][3] <= frame_data;
            16  : block_data[0][4] <= frame_data;
            17  : block_data[0][5] <= frame_data;
            18  : block_data[0][6] <= frame_data;
            19  : block_data[0][7] <= frame_data;
            20  : block_data[1][4] <= frame_data;
            21  : block_data[1][5] <= frame_data;
            22  : block_data[1][6] <= frame_data;
            23  : block_data[1][7] <= frame_data;
            24  : block_data[2][4] <= frame_data;
            25  : block_data[2][5] <= frame_data;
            26  : block_data[2][6] <= frame_data;
            27  : block_data[2][7] <= frame_data;
            28  : block_data[3][4] <= frame_data;
            29  : block_data[3][5] <= frame_data;
            30  : block_data[3][6] <= frame_data;
            31  : block_data[3][7] <= frame_data;
            32  : block_data[0][8] <= frame_data;
            33  : block_data[0][9] <= frame_data;
            34  : block_data[0][10] <= frame_data;
            35  : block_data[0][11] <= frame_data;
            36  : block_data[1][8] <= frame_data;
            37  : block_data[1][9] <= frame_data;
            38  : block_data[1][10] <= frame_data;
            39  : block_data[1][11] <= frame_data;
            40  : block_data[2][8] <= frame_data;
            41  : block_data[2][9] <= frame_data;
            42  : block_data[2][10] <= frame_data;
            43  : block_data[2][11] <= frame_data;
            44  : block_data[3][8] <= frame_data;
            45  : block_data[3][9] <= frame_data;
            46  : block_data[3][10] <= frame_data;
            47  : block_data[3][11] <= frame_data;
            48  : block_data[0][12] <= frame_data;
            49  : block_data[0][13] <= frame_data;
            50  : block_data[0][14] <= frame_data;
            51  : block_data[0][15] <= frame_data;
            52  : block_data[1][12] <= frame_data;
            53  : block_data[1][13] <= frame_data;
            54  : block_data[1][14] <= frame_data;
            55  : block_data[1][15] <= frame_data;
            56  : block_data[2][12] <= frame_data;
            57  : block_data[2][13] <= frame_data;
            58  : block_data[2][14] <= frame_data;
            59  : block_data[2][15] <= frame_data;
            60  : block_data[3][12] <= frame_data;
            61  : block_data[3][13] <= frame_data;
            62  : block_data[3][14] <= frame_data;
            63  : block_data[3][15] <= frame_data;
            64  : block_data[4][0] <= frame_data;
            65  : block_data[4][1] <= frame_data;
            66  : block_data[4][2] <= frame_data;
            67  : block_data[4][3] <= frame_data;
            68  : block_data[5][0] <= frame_data;
            69  : block_data[5][1] <= frame_data;
            70  : block_data[5][2] <= frame_data;
            71  : block_data[5][3] <= frame_data;
            72  : block_data[6][0] <= frame_data;
            73  : block_data[6][1] <= frame_data;
            74  : block_data[6][2] <= frame_data;
            75  : block_data[6][3] <= frame_data;
            76  : block_data[7][0] <= frame_data;
            77  : block_data[7][1] <= frame_data;
            78  : block_data[7][2] <= frame_data;
            79  : block_data[7][3] <= frame_data;
            80  : block_data[4][4] <= frame_data;
            81  : block_data[4][5] <= frame_data;
            82  : block_data[4][6] <= frame_data;
            83  : block_data[4][7] <= frame_data;
            84  : block_data[5][4] <= frame_data;
            85  : block_data[5][5] <= frame_data;
            86  : block_data[5][6] <= frame_data;
            87  : block_data[5][7] <= frame_data;
            88  : block_data[6][4] <= frame_data;
            89  : block_data[6][5] <= frame_data;
            90  : block_data[6][6] <= frame_data;
            91  : block_data[6][7] <= frame_data;
            92  : block_data[7][4] <= frame_data;
            93  : block_data[7][5] <= frame_data;
            94  : block_data[7][6] <= frame_data;
            95  : block_data[7][7] <= frame_data;
            96  : block_data[4][8] <= frame_data;
            97  : block_data[4][9] <= frame_data;
            98  : block_data[4][10] <= frame_data;
            99  : block_data[4][11] <= frame_data;
            100 : block_data[5][8] <= frame_data;
            101 : block_data[5][9] <= frame_data;
            102 : block_data[5][10] <= frame_data;
            103 : block_data[5][11] <= frame_data;
            104 : block_data[6][8] <= frame_data;
            105 : block_data[6][9] <= frame_data;
            106 : block_data[6][10] <= frame_data;
            107 : block_data[6][11] <= frame_data;
            108 : block_data[7][8] <= frame_data;
            109 : block_data[7][9] <= frame_data;
            110 : block_data[7][10] <= frame_data;
            111 : block_data[7][11] <= frame_data;
            112 : block_data[4][12] <= frame_data;
            113 : block_data[4][13] <= frame_data;
            114 : block_data[4][14] <= frame_data;
            115 : block_data[4][15] <= frame_data;
            116 : block_data[5][12] <= frame_data;
            117 : block_data[5][13] <= frame_data;
            118 : block_data[5][14] <= frame_data;
            119 : block_data[5][15] <= frame_data;
            120 : block_data[6][12] <= frame_data;
            121 : block_data[6][13] <= frame_data;
            122 : block_data[6][14] <= frame_data;
            123 : block_data[6][15] <= frame_data;
            124 : block_data[7][12] <= frame_data;
            125 : block_data[7][13] <= frame_data;
            126 : block_data[7][14] <= frame_data;
            127 : block_data[7][15] <= frame_data;
            128 : block_data[8][0] <= frame_data;
            129 : block_data[8][1] <= frame_data;
            130 : block_data[8][2] <= frame_data;
            131 : block_data[8][3] <= frame_data;
            132 : block_data[9][0] <= frame_data;
            133 : block_data[9][1] <= frame_data;
            134 : block_data[9][2] <= frame_data;
            135 : block_data[9][3] <= frame_data;
            136 : block_data[10][0] <= frame_data;
            137 : block_data[10][1] <= frame_data;
            138 : block_data[10][2] <= frame_data;
            139 : block_data[10][3] <= frame_data;
            140 : block_data[11][0] <= frame_data;
            141 : block_data[11][1] <= frame_data;
            142 : block_data[11][2] <= frame_data;
            143 : block_data[11][3] <= frame_data;
            144 : block_data[8][4] <= frame_data;
            145 : block_data[8][5] <= frame_data;
            146 : block_data[8][6] <= frame_data;
            147 : block_data[8][7] <= frame_data;
            148 : block_data[9][4] <= frame_data;
            149 : block_data[9][5] <= frame_data;
            150 : block_data[9][6] <= frame_data;
            151 : block_data[9][7] <= frame_data;
            152 : block_data[10][4] <= frame_data;
            153 : block_data[10][5] <= frame_data;
            154 : block_data[10][6] <= frame_data;
            155 : block_data[10][7] <= frame_data;
            156 : block_data[11][4] <= frame_data;
            157 : block_data[11][5] <= frame_data;
            158 : block_data[11][6] <= frame_data;
            159 : block_data[11][7] <= frame_data;
            160 : block_data[8][8] <= frame_data;
            161 : block_data[8][9] <= frame_data;
            162 : block_data[8][10] <= frame_data;
            163 : block_data[8][11] <= frame_data;
            164 : block_data[9][8] <= frame_data;
            165 : block_data[9][9] <= frame_data;
            166 : block_data[9][10] <= frame_data;
            167 : block_data[9][11] <= frame_data;
            168 : block_data[10][8] <= frame_data;
            169 : block_data[10][9] <= frame_data;
            170 : block_data[10][10] <= frame_data;
            171 : block_data[10][11] <= frame_data;
            172 : block_data[11][8] <= frame_data;
            173 : block_data[11][9] <= frame_data;
            174 : block_data[11][10] <= frame_data;
            175 : block_data[11][11] <= frame_data;
            176 : block_data[8][12] <= frame_data;
            177 : block_data[8][13] <= frame_data;
            178 : block_data[8][14] <= frame_data;
            179 : block_data[8][15] <= frame_data;
            180 : block_data[9][12] <= frame_data;
            181 : block_data[9][13] <= frame_data;
            182 : block_data[9][14] <= frame_data;
            183 : block_data[9][15] <= frame_data;
            184 : block_data[10][12] <= frame_data;
            185 : block_data[10][13] <= frame_data;
            186 : block_data[10][14] <= frame_data;
            187 : block_data[10][15] <= frame_data;
            188 : block_data[11][12] <= frame_data;
            189 : block_data[11][13] <= frame_data;
            190 : block_data[11][14] <= frame_data;
            191 : block_data[11][15] <= frame_data;
            192 : block_data[12][0] <= frame_data;
            193 : block_data[12][1] <= frame_data;
            194 : block_data[12][2] <= frame_data;
            195 : block_data[12][3] <= frame_data;
            196 : block_data[13][0] <= frame_data;
            197 : block_data[13][1] <= frame_data;
            198 : block_data[13][2] <= frame_data;
            199 : block_data[13][3] <= frame_data;
            200 : block_data[14][0] <= frame_data;
            201 : block_data[14][1] <= frame_data;
            202 : block_data[14][2] <= frame_data;
            203 : block_data[14][3] <= frame_data;
            204 : block_data[15][0] <= frame_data;
            205 : block_data[15][1] <= frame_data;
            206 : block_data[15][2] <= frame_data;
            207 : block_data[15][3] <= frame_data;
            208 : block_data[12][4] <= frame_data;
            209 : block_data[12][5] <= frame_data;
            210 : block_data[12][6] <= frame_data;
            211 : block_data[12][7] <= frame_data;
            212 : block_data[13][4] <= frame_data;
            213 : block_data[13][5] <= frame_data;
            214 : block_data[13][6] <= frame_data;
            215 : block_data[13][7] <= frame_data;
            216 : block_data[14][4] <= frame_data;
            217 : block_data[14][5] <= frame_data;
            218 : block_data[14][6] <= frame_data;
            219 : block_data[14][7] <= frame_data;
            220 : block_data[15][4] <= frame_data;
            221 : block_data[15][5] <= frame_data;
            222 : block_data[15][6] <= frame_data;
            223 : block_data[15][7] <= frame_data;
            224 : block_data[12][8] <= frame_data;
            225 : block_data[12][9] <= frame_data;
            226 : block_data[12][10] <= frame_data;
            227 : block_data[12][11] <= frame_data;
            228 : block_data[13][8] <= frame_data;
            229 : block_data[13][9] <= frame_data;
            230 : block_data[13][10] <= frame_data;
            231 : block_data[13][11] <= frame_data;
            232 : block_data[14][8] <= frame_data;
            233 : block_data[14][9] <= frame_data;
            234 : block_data[14][10] <= frame_data;
            235 : block_data[14][11] <= frame_data;
            236 : block_data[15][8] <= frame_data;
            237 : block_data[15][9] <= frame_data;
            238 : block_data[15][10] <= frame_data;
            239 : block_data[15][11] <= frame_data;
            240 : block_data[12][12] <= frame_data;
            241 : block_data[12][13] <= frame_data;
            242 : block_data[12][14] <= frame_data;
            243 : block_data[12][15] <= frame_data;
            244 : block_data[13][12] <= frame_data;
            245 : block_data[13][13] <= frame_data;
            246 : block_data[13][14] <= frame_data;
            247 : block_data[13][15] <= frame_data;
            248 : block_data[14][12] <= frame_data;
            249 : block_data[14][13] <= frame_data;
            250 : block_data[14][14] <= frame_data;
            251 : block_data[14][15] <= frame_data;
            252 : block_data[15][12] <= frame_data;
            253 : block_data[15][13] <= frame_data;
            254 : block_data[15][14] <= frame_data;
            255 : block_data[15][15] <= frame_data;
            default : begin
                for(m=0; m<16; m=m+1) begin
                    for(n=0; n<16; n=n+1) begin
                        block_data[m][n] <= block_data[m][n];
                    end
                end
            end
       endcase
    end
    else begin
        for(m=0; m<16; m=m+1) begin
            for(n=0; n<16; n=n+1) begin
                block_data[m][n] <= block_data[m][n];
            end
        end
    end
end


//==================================================================
// SRAM
//==================================================================
SRAM_16384 SRAM_inst (
    .CK(clk),
    .WEB(~in_valid_data),
    .OE(1'b1),
    .CS(1'b1),
    .A(frame_cnt),
    .DI(data),
    .DO(frame_data)
);

//==================================================================
// input buffer
//==================================================================
// reg [7:0] data_reg;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) data_reg <= 8'd0;
//     else if(in_valid_data) data_reg <= data;
//     else data_reg <= data_reg;
// end




endmodule

module SRAM_16384 (
    input CK,WEB,OE,CS,
    input [13:0] A,
    input [7:0] DI,
    output [7:0] DO
);

SRAM_16384X8  SRAM_16384X8_inst (
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

module Quantization #(
    parameter WIDTH = 32,
    localparam OUTZ = 32
)(
    input QP,
    input  signed [WIDTH-1:0] W00, input  signed [WIDTH-1:0] W01, input  signed [WIDTH-1:0] W02, input  signed [WIDTH-1:0] W03,
    input  signed [WIDTH-1:0] W10, input  signed [WIDTH-1:0] W11, input  signed [WIDTH-1:0] W12, input  signed [WIDTH-1:0] W13,
    input  signed [WIDTH-1:0] W20, input  signed [WIDTH-1:0] W21, input  signed [WIDTH-1:0] W22, input  signed [WIDTH-1:0] W23,
    input  signed [WIDTH-1:0] W30, input  signed [WIDTH-1:0] W31, input  signed [WIDTH-1:0] W32, input  signed [WIDTH-1:0] W33,

    output signed [OUTZ-1:0] Z00, output signed [OUTZ-1:0] Z01, output signed [OUTZ-1:0] Z02, output signed [OUTZ-1:0] Z03,
    output signed [OUTZ-1:0] Z10, output signed [OUTZ-1:0] Z11, output signed [OUTZ-1:0] Z12, output signed [OUTZ-1:0] Z13,
    output signed [OUTZ-1:0] Z20, output signed [OUTZ-1:0] Z21, output signed [OUTZ-1:0] Z22, output signed [OUTZ-1:0] Z23,
    output signed [OUTZ-1:0] Z30, output signed [OUTZ-1:0] Z31, output signed [OUTZ-1:0] Z32, output signed [OUTZ-1:0] Z33
);
reg [13:0] a ;
reg [12:0] b ,c;
reg [18:0] f;

//LUT
always @(*) begin
    case(QP)
        0,6,12,18,24 : begin
            a = 14'd13107 ;
            b = 13'd5243 ;
            c = 13'd8066 ;
        end
        1,7,13,19,25 : begin
            a = 14'd11916 ;
            b = 13'd4660 ;
            c = 13'd7282 ;
        end
        2,8,14,20,26 : begin
            a = 14'd10082 ;
            b = 13'd4194 ;
            c = 13'd6554 ;
        end
        3,9,15,21,27 : begin
            a = 14'd9362 ;
            b = 13'd3647 ;
            c = 13'd5825 ;
        end
        4,10,16,22,28 : begin
            a = 14'd8192 ;
            b = 13'd3355 ;
            c = 13'd5243 ;
        end
        5,11,17,23,29 : begin
            a = 14'd7282 ;
            b = 13'd2893 ;
            c = 13'd4559 ;
        end
        default : begin
            a = 14'd0 ;
            b = 13'd0 ;
            c = 13'd0 ;
        end
    endcase
end

always @(*) begin
    case(QP)
        0,1,2,3,4,5 : f = 19'd10922 ;
        6,7,8,9,10,11 : f = 19'd21845 ;
        12,13,14,15,16,17 : f = 19'd43690 ;
        18,19,20,21,22,23 : f = 19'd87381 ;
        24,25,26,27,28,29 : f = 19'd174762 ;
        default : f = 19'd0 ;
    endcase
end
endmodule



module transform #(
    parameter WIDTH = 9,
    localparam OUTW = WIDTH + 4
)(
    input  signed [WIDTH-1:0] X00, input  signed [WIDTH-1:0] X01, input  signed [WIDTH-1:0] X02, input  signed [WIDTH-1:0] X03,
    input  signed [WIDTH-1:0] X10, input  signed [WIDTH-1:0] X11, input  signed [WIDTH-1:0] X12, input  signed [WIDTH-1:0] X13,
    input  signed [WIDTH-1:0] X20, input  signed [WIDTH-1:0] X21, input  signed [WIDTH-1:0] X22, input  signed [WIDTH-1:0] X23,
    input  signed [WIDTH-1:0] X30, input  signed [WIDTH-1:0] X31, input  signed [WIDTH-1:0] X32, input  signed [WIDTH-1:0] X33,

    output signed [OUTW-1:0] W00, output signed [OUTW-1:0] W01, output signed [OUTW-1:0] W02, output signed [OUTW-1:0] W03,
    output signed [OUTW-1:0] W10, output signed [OUTW-1:0] W11, output signed [OUTW-1:0] W12, output signed [OUTW-1:0] W13,
    output signed [OUTW-1:0] W20, output signed [OUTW-1:0] W21, output signed [OUTW-1:0] W22, output signed [OUTW-1:0] W23,
    output signed [OUTW-1:0] W30, output signed [OUTW-1:0] W31, output signed [OUTW-1:0] W32, output signed [OUTW-1:0] W33
);

    // Step 1: T = X * Cf(T)
    wire signed [OUTW-1:0] T00 = X00 + X01 + X02 + X03;
    wire signed [OUTW-1:0] T01 = X00 + X01 - X02 - X03;
    wire signed [OUTW-1:0] T02 = X00 - X01 - X02 + X03;
    wire signed [OUTW-1:0] T03 = X00 - X01 + X02 - X03;

    wire signed [OUTW-1:0] T10 = X10 + X11 + X12 + X13;
    wire signed [OUTW-1:0] T11 = X10 - X11 - X12 + X13;
    wire signed [OUTW-1:0] T12 = -X10 - X11 + X12 + X13;
    wire signed [OUTW-1:0] T13 = -X10 + X11 - X12 + X13;

    wire signed [OUTW-1:0] T20 = X20 + X21 + X22 + X23;
    wire signed [OUTW-1:0] T21 = X20 - X21 - X22 + X23;
    wire signed [OUTW-1:0] T22 = -X20 - X21 + X22 + X23;
    wire signed [OUTW-1:0] T23 = -X20 + X21 - X22 + X23;

    wire signed [OUTW-1:0] T30 = X30 + X31 + X32 + X33;
    wire signed [OUTW-1:0] T31 = X30 + X31 - X32 - X33;
    wire signed [OUTW-1:0] T32 = X30 - X31 - X32 + X33;
    wire signed [OUTW-1:0] T33 = X30 - X31 + X32 - X33;

    assign W00 = T00 + T10 + T20 + T30;
    assign W01 = T01 + T11 + T21 + T31;
    assign W02 = T02 + T12 + T22 + T32;
    assign W03 = T03 + T13 + T23 + T33;

    assign W10 = T00 + T10 - T20 - T30;
    assign W11 = T01 + T11 - T21 - T31;
    assign W12 = T02 + T12 - T22 - T32;
    assign W13 = T03 + T13 - T23 - T33;

    assign W20 = T00 - T10 - T20 + T30;
    assign W21 = T01 - T11 - T21 + T31;
    assign W22 = T02 - T12 - T22 + T32;
    assign W23 = T03 - T13 - T23 + T33;

    assign W30 = T00 - T10 + T20 - T30;
    assign W31 = T01 - T11 + T21 - T31;
    assign W32 = T02 - T12 + T22 - T32;
    assign W33 = T03 - T13 + T23 - T33;

endmodule
