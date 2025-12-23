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
parameter IDLE              = 0;
parameter INPUT_FRAME       = 1;
parameter INPUT_PARAM       = 2;
parameter WAIT_16CYCLE      = 3; // Wait 18 cycles
parameter WAIT_256CYCLE     = 10; //Wait 258 cycles
parameter CALU_RESIDUAL     = 9;
parameter TRANSFORM         = 4;
parameter QUANTIZATION      = 5;
parameter DEQUANTIZATION    = 6;
parameter INVERSE_TRANSFORM = 7;
parameter UPDATE_EDGE       = 8;

integer m,n;
//==================================================================
// reg & wire
//==================================================================
reg   [5:0]  state_c,state_n;
reg   [7:0]  frame_data;
reg   [7:0]  data_reg;
reg   [3:0]  block_mode;
reg   [3:0]  index_reg;
reg   [4:0]  QP_reg;
reg   [14:0]  dc;
reg   [7:0]  block_data [0:15] [0:15];
reg signed [8:0]  left_edge [0:15];
reg signed [8:0]  top_edge [0:31];

reg signed [8:0] prediction_dc [0:3][0:3];
reg signed [8:0] prediction_horizontal [0:3][0:3];
reg signed [8:0] prediction_vertical [0:3][0:3];
reg signed [13:0] Residual [0:3][0:3];
reg signed [17:0] transform_temp [0:3][0:3];//maybe
reg signed [17:0] transform_data [0:3][0:3];
reg signed [31:0] quantization_temp [0:3][0:3];
reg signed [31:0] quantization_data [0:3][0:3];
reg signed [41:0] dequantization_temp [0:3][0:3];
reg signed [41:0] dequantization_data [0:3][0:3];
reg signed [45:0] inv_transform_temp [0:3][0:3];
reg signed [39:0] inv_transform_data [0:3][0:3];
reg signed [50:0] reconstructed_block [0:3][0:3];
reg   [7:0] reconstructed [0:3]  [0:3];
reg   [1:0] prediction_right; //DC0   V1    H2   X3

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
reg [10:0] addr_cnt; //maybe
reg [1:0] blank_cnt; //out_cnt is 256 512 768 plus here
reg [3:0] index_cnt;
reg [3:0] micro_cnt;
reg [9:0] out_cnt; //0~1024
reg [3:0] out_addr_cnt;
reg [8:0] waiting_cnt;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        index_cnt <=0;
    else if (state_c == INPUT_FRAME) index_cnt <=0;
    else if (unit_cnt == 1023) index_cnt <= index_cnt +1;
    else index_cnt <= index_cnt;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) waiting_cnt <= 0;
    else if (state_c == WAIT_16CYCLE && waiting_cnt<=17 ) waiting_cnt <= waiting_cnt + 1'b1;
    else if (state_c == WAIT_256CYCLE && waiting_cnt<=257 ) waiting_cnt <= waiting_cnt + 1'b1;
    else waiting_cnt <= 0;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) out_addr_cnt <= 4'd0;
    else if(state_c > QUANTIZATION && state_c<=UPDATE_EDGE && out_addr_cnt<15) out_addr_cnt <= out_addr_cnt + 4'd1;
    else out_addr_cnt <= 4'd0;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) out_cnt <= 10'd0;
    else if (state_c == IDLE) out_cnt <= 10'd0;
    else if(state_c > QUANTIZATION && state_c<=UPDATE_EDGE ) out_cnt <= out_cnt + 10'd1;
    else out_cnt <= out_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) micro_cnt <= 4'b0;
    // else if (state_c == WAIT_256CYCLE) begin
    //     if(unit_cnt % 16 ==0) micro_cnt <= micro_cnt + 4'b1;
    //     else micro_cnt <= micro_cnt;
    // end
    else if (out_addr_cnt==15) micro_cnt <= micro_cnt + 4'b1;
    else if (out_addr_cnt==15 && micro_cnt==15) micro_cnt <= 4'b0;
    else micro_cnt <= micro_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) blank_cnt <= 2'd0;
    else if(state_c == INPUT_FRAME && blank_cnt==3) blank_cnt <= 2'd0;
    // else if(unit_cnt==256) blank_cnt <= blank_cnt + 2'd1;
    else if (out_addr_cnt==15 && micro_cnt==15) blank_cnt <= blank_cnt + 2'd1;
    else blank_cnt <= blank_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_cnt <= 10'd0;
    else if((state_c == WAIT_16CYCLE )&& waiting_cnt<16) addr_cnt <= addr_cnt + 10'd1;
    else if ((state_c == WAIT_256CYCLE )&& waiting_cnt<256) addr_cnt <= addr_cnt + 10'd1;
    else addr_cnt <= addr_cnt;
end
reg [10:0] addr_cnt_delay1;
// reg [10:0] unit_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_cnt_delay1 <= 10'd0;
    else addr_cnt_delay1 <= addr_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) unit_cnt <= 10'd0;
    else unit_cnt <= addr_cnt_delay1;
end

reg [9:0] block_offset; //+16 +512 +528
always @(*) begin
    case (blank_cnt)
        0: block_offset = 10'd0;
        1: block_offset = 10'd16;  
        2: block_offset = 10'd512;
        3: block_offset = 10'd528;
    endcase
end

reg [9:0] micro_offset;
always @ (*) begin
    if(state_c ==WAIT_256CYCLE && waiting_cnt>0)
        case(waiting_cnt/16)
            0: micro_offset = 10'd0;
            1: micro_offset = 10'd4;
            2 : micro_offset = 10'd8;
            3 : micro_offset = 10'd12;
            4 : micro_offset = 10'd128;
            5 : micro_offset = 10'd132;
            6 : micro_offset = 10'd136;
            7 : micro_offset = 10'd140;
            8 : micro_offset = 10'd256;
            9 : micro_offset = 10'd260;
            10 : micro_offset = 10'd264;
            11 : micro_offset = 10'd268;
            12 : micro_offset = 10'd384;
            13 : micro_offset = 10'd388;
            14 : micro_offset = 10'd392;
            15 : micro_offset = 10'd396;
            default: micro_offset = 10'd0;    
        endcase
    else
        case(micro_cnt)
            0 : micro_offset = 10'd0;
            1 : micro_offset = 10'd4;
            2 : micro_offset = 10'd8;
            3 : micro_offset = 10'd12;
            4 : micro_offset = 10'd128;
            5 : micro_offset = 10'd132;
            6 : micro_offset = 10'd136;
            7 : micro_offset = 10'd140;
            8 : micro_offset = 10'd256;
            9 : micro_offset = 10'd260;
            10 : micro_offset = 10'd264;
            11 : micro_offset = 10'd268;
            12 : micro_offset = 10'd384;
            13 : micro_offset = 10'd388;
            14 : micro_offset = 10'd392;
            15 : micro_offset = 10'd396;
            default: micro_offset = 10'd0;
        endcase
end

//  block_offset = ({9'd0, blank_cnt[1]} << 9)   + ({9'd0, blank_cnt[0]} << 4);

//micro rowoffset
// reg [9:0] row_offset;

// always @ (*) begin
//     case (micro_cnt/4)
//         0: row_offset = 10'd0;
//         1: row_offset = 10'd128;
//         2: row_offset = 10'd256;
//         3: row_offset = 10'd384;
//     default: row_offset = 10'd0;
// end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) frame_cnt <= 14'd0;
    else if (index_cnt==15 && unit_cnt==1023) frame_cnt <= 14'd0;
    else if(in_valid_data) frame_cnt <= frame_cnt + 14'd1;
    else if ((state_c == WAIT_16CYCLE)&& waiting_cnt<17)
        case (addr_cnt%16)
            0,1,2,3:  frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16);
            4,5,6,7:  frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16)+ 28 ;
            8,9,10,11: frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16)+ 56 ;
            12,13,14,15: frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16)+ 84 ;
            default : frame_cnt <= frame_cnt;
        endcase
        // frame_cnt <= 1024 * index_reg 
        //                     + ((addr_cnt % 16) % 4)
        //                     + (((addr_cnt % 16) / 4) * 32)
        //                     + (((addr_cnt / 16) % 4) * 4)
        //                     + ((addr_cnt / 64) * 128);

        // case (addr_cnt)
        //     // blank 0  micro 0 1 2 3
        //     0,1,2,3 : frame_cnt <= 1024 * index_reg + offset + addr_cnt;
        //     4,5,6,7 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 28 ;
        //     8,9,10,11 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 56 ;
        //     12,13,14,15 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 84 ;

        //     16,17,18,19 : frame_cnt <= 1024 * index_reg + offset + addr_cnt -12 ;
        //     20,21,22,23 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 16 ;
        //     24,25,26,27 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 44 ;
        //     28,29,30,31 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 72 ;

        //     32,33,34,35 : frame_cnt <= 1024 * index_reg + offset + addr_cnt -24 ;
        //     36,37,38,39 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 4 ;
        //     40,41,42,43 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 32 ;
        //     44,45,46,47 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 60 ;

        //     48,49,50,51 : frame_cnt <= 1024 * index_reg + offset + addr_cnt -36 ;
        //     52,53,54,55 : frame_cnt <= 1024 * index_reg + offset + addr_cnt -8 ;
        //     56,57,58,59 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 20 ;
        //     60,61,62,63 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 48 ;
        //     //micro 4 5 6 7
        //     64,65,66,67 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +64 ;
        //     68,69,70,71 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +92 ;
        //     72,73,74,75 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +120 ;
        //     76,77,78,79 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +148 ;

        //     80,81,82,83 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +52 ;
        //     84,85,86,87 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +80 ;
        //     88,89,90,91 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +108 ;
        //     92,93,94,95 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +136 ;

        //     96,97,98,99 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +40 ;
        //     100,101,102,103 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +68 ;
        //     104,105,106,107 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +96 ;
        //     108,109,110,111 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +124 ;

        //     112,113,114,115 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +28 ;
        //     116,117,118,119 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +56 ;
        //     120,121,122,123 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +84 ;
        //     124,125,126,127 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +112 ;
        //     //  micro 8 9 10 11
        //     128,129,130,131 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +128;
        //     132,133,134,135 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +156 ;
        //     136,137,138,139 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +184 ;
        //     140,141,142,143 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +212 ;

        //     144,145,146,147 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +116 ;
        //     148,149,150,151 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +144 ;
        //     152,153,154,155 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +172 ;
        //     156,157,158,159 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +200 ;

        //     160,161,162,163 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +104 ;
        //     164,165,166,167 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +132 ;
        //     168,169,170,171 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +160 ;
        //     172,173,174,175 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +188 ;

        //     176,177,178,179 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +92 ;
        //     180,181,182,183 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +120 ;
        //     184,185,186,187 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +148 ;
        //     188,189,190,191 : frame_cnt <= 1024 * index_reg + offset + addr_cnt +176 ;
        //     //blank 0 micro 12 13 14 15
        //     192,193,194,195 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 192;
        //     196,197,198,199 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 220 ;
        //     200,201,202,203 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 248 ;
        //     204,205,206,207 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 276 ;

        //     208,209,210,211 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 180 ;
        //     212,213,214,215 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 208 ;
        //     216,217,218,219 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 236 ;
        //     220,221,222,223 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 264 ;

        //     224,225,226,227 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 168 ;
        //     228,229,230,231 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 196 ;
        //     232,233,234,235 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 224 ;
        //     236,237,238,239 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 252 ;

        //     240,241,242,243 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 156 ;
        //     244,245,246,247 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 184 ;
        //     248,249,250,251 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 212 ;
        //     252,253,254,255 : frame_cnt <= 1024 * index_reg + offset + addr_cnt + 240 ;
        //     //blank 1 micro 0 1 2 3
        //     256,257,258,259 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 240 ;
        //     260,261,262,263 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 212 ;
        //     264,265,266,267 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 184 ;
        //     268,269,270,271 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 156 ;

        //     272,273,274,275 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 252 ;
        //     276,277,278,279 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 224 ;
        //     280,281,282,283 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 196 ;
        //     284,285,286,287 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 168 ;

        //     288,289,290,291 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 264 ;
        //     292,293,294,295 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 236 ;
        //     296,297,298,299 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 208 ;
        //     300,301,302,303 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 180 ;

        //     304,305,306,307 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 276 ;
        //     308,309,310,311 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 248 ;
        //     312,313,314,315 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 220 ;
        //     316,317,318,319 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 192 ;
        //     //blank 1 micro 4 5 6 7
        //     320,321,322,323 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 176 ;
        //     324,325,326,327 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 148 ;
        //     328,329,330,331 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 120 ;
        //     332,333,334,335 : frame_cnt <= 1024 * index_reg + offset + addr_cnt - 92 ;
        // endcase
        // case (blank_cnt)
        //     0:  frame_cnt <= 1024 * index_reg + offset
        //                     + ((addr_cnt % 16) % 4)
        //                     + (((addr_cnt % 16) / 4) * 32)
        //                     + (((addr_cnt / 16) % 4) * 4)
        //                     + ((addr_cnt / 64) * 128);
        //     1 : frame_cnt <= 1024 * index_reg + offset
        //                     + ((addr_cnt % 16) % 4)
        //                     + (((addr_cnt % 16) / 4) * 32)
        //                     + (((addr_cnt / 16) % 4) * 4)
        //                     + ((addr_cnt / 64) * 128)
        //                     - 512;
        // endcase
    else if ((state_c == WAIT_256CYCLE)&& waiting_cnt<257)
        case (addr_cnt%16)
            0,1,2,3:  frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16);
            4,5,6,7:  frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16)+ 28 ;
            8,9,10,11: frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16)+ 56 ;
            12,13,14,15: frame_cnt <= 1024 * index_reg + block_offset + micro_offset+ (addr_cnt%16)+ 84 ;
            default : frame_cnt <= frame_cnt;
        endcase
        // case (blank_cnt)
        //     0:  frame_cnt <= 1024 * index_reg + offset
        //                     + ((addr_cnt % 16) % 4)
        //                     + (((addr_cnt % 16) / 4) * 32)
        //                     + (((addr_cnt / 16) % 4) * 4)
        //                     + ((addr_cnt / 64) * 128);
        //     1 : frame_cnt <= 1024 * index_reg + offset
        //                     + ((addr_cnt % 16) % 4)
        //                     + (((addr_cnt % 16) / 4) * 32)
        //                     + (((addr_cnt / 16) % 4) * 4)
        //                     + ((addr_cnt / 64) * 128)
        //                     - 512;
        // endcase
        // frame_cnt <= 1024 * index_reg + offset
        //             + ((addr_cnt % 16) % 4)
        //             + (((addr_cnt % 16) / 4) * 32)
        //             + (((addr_cnt / 16) % 4) * 4)
        //             + ((addr_cnt / 64) * 128);
    else frame_cnt <= frame_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) param_cnt <= 3'd0;
    else if(in_valid_param) param_cnt <= param_cnt + 3'd1;
    else param_cnt <= 3'd0;
end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) unit_cnt <= 10'd0;
//     else if (state_c == INPUT_PARAM || unit_cnt ==256) unit_cnt <= 10'd0;
//     else if((state_c == WAIT_16CYCLE || state_c ==WAIT_256CYCLE) && addr_cnt>1) unit_cnt <= unit_cnt + 10'd1;
//     else unit_cnt <= unit_cnt;
// end


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
            else if(block_mode[0] == 1'b0) state_n = WAIT_256CYCLE;
            else state_n = WAIT_16CYCLE;
        end
        WAIT_256CYCLE : begin
            if(waiting_cnt >= 10'd258) state_n = CALU_RESIDUAL;
            else state_n = WAIT_256CYCLE;
        end

        WAIT_16CYCLE : begin
            if(waiting_cnt >= 10'd17) state_n = CALU_RESIDUAL;
            else state_n = WAIT_16CYCLE;
        end
        CALU_RESIDUAL : 
            state_n = TRANSFORM;
        TRANSFORM :
            state_n = QUANTIZATION;
        QUANTIZATION :
            state_n = DEQUANTIZATION;
        DEQUANTIZATION :
            state_n = INVERSE_TRANSFORM;
        INVERSE_TRANSFORM :
            state_n = UPDATE_EDGE;
        UPDATE_EDGE : begin
            if (out_cnt ==1023 && index_cnt <= 4'd15) state_n = IDLE;
            else if (micro_cnt==15 && out_addr_cnt==15 && blank_cnt<3 )
                if(block_mode[blank_cnt+1] == 0) state_n = WAIT_256CYCLE;
                else state_n = WAIT_16CYCLE;
            else if (block_mode[blank_cnt] == 1 && out_addr_cnt==15) state_n = WAIT_16CYCLE;
            // else if (block_mode[blank_cnt] == 0 && out_cnt%256!=0 && out_cnt>0) state_n = CALU_RESIDUAL; //no
            else if (block_mode[blank_cnt] == 0) begin
                if(out_addr_cnt==15) state_n = CALU_RESIDUAL;
                else state_n = UPDATE_EDGE;
            end
            else state_n = UPDATE_EDGE; //no

            // if(out == 10'd255) state_n = IDLE;
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
    if(!rst_n) QP_reg <= 4'd0;
    else if(in_valid_param  && param_cnt == 0 ) QP_reg <= QP;
    else QP_reg <= QP_reg;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) block_mode <= 4'd0;
    else if(in_valid_param)
        block_mode[param_cnt] <= mode;
    else block_mode <= block_mode;
end

//==================================================================
// Edge and dc 
//==================================================================
// reg [7:0] top_edge [0:31];
// reg [7:0] left_edge [0:15];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= 8'd0;
        end
    end
    else if (state_c == IDLE) begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= 8'd0;
        end
    end
    else if(state_c == INPUT_PARAM) begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= 8'd128;
        end
    end
    else if (state_c ==UPDATE_EDGE)begin
        if(block_mode[blank_cnt]==0) begin
            case(micro_cnt)
                12: begin
                    if(blank_cnt==0 || blank_cnt==2) begin
                        top_edge[0] <= reconstructed[3][0];
                        top_edge[1] <= reconstructed[3][1];
                        top_edge[2] <= reconstructed[3][2];
                        top_edge[3] <= reconstructed[3][3];
                    end
                    else begin
                        top_edge[16] <= reconstructed[3][0];
                        top_edge[17] <= reconstructed[3][1];
                        top_edge[18] <= reconstructed[3][2];
                        top_edge[19] <= reconstructed[3][3];
                    end
                end
                13: begin
                    if(blank_cnt==0 || blank_cnt==2) begin
                        top_edge[4] <= reconstructed[3][0];
                        top_edge[5] <= reconstructed[3][1];
                        top_edge[6] <= reconstructed[3][2];
                        top_edge[7] <= reconstructed[3][3];
                    end
                    else begin
                        top_edge[20] <= reconstructed[3][0];
                        top_edge[21] <= reconstructed[3][1];
                        top_edge[22] <= reconstructed[3][2];
                        top_edge[23] <= reconstructed[3][3];
                    end
                end
                14: begin
                    if(blank_cnt==0 || blank_cnt==2) begin
                        top_edge[8] <= reconstructed[3][0];
                        top_edge[9] <= reconstructed[3][1];
                        top_edge[10] <= reconstructed[3][2];
                        top_edge[11] <= reconstructed[3][3];
                    end
                    else begin
                        top_edge[24] <= reconstructed[3][0];
                        top_edge[25] <= reconstructed[3][1];
                        top_edge[26] <= reconstructed[3][2];
                        top_edge[27] <= reconstructed[3][3];
                    end
                end
                15: begin
                    if(blank_cnt==0 || blank_cnt==2) begin
                        top_edge[12] <= reconstructed[3][0];
                        top_edge[13] <= reconstructed[3][1];
                        top_edge[14] <= reconstructed[3][2];
                        top_edge[15] <= reconstructed[3][3];
                    end
                    else begin
                        top_edge[28] <= reconstructed[3][0];
                        top_edge[29] <= reconstructed[3][1];
                        top_edge[30] <= reconstructed[3][2];
                        top_edge[31] <= reconstructed[3][3];
                    end
                end
                default: for(m=0; m<32; m=m+1) begin
                    top_edge[m] <= top_edge[m];
                end
            endcase
        end
        else begin
            if(blank_cnt ==0 || blank_cnt==2) begin
                case (micro_cnt%4)
                    0: begin
                        top_edge[0] <= reconstructed[3][0];
                        top_edge[1] <= reconstructed[3][1];
                        top_edge[2] <= reconstructed[3][2];
                        top_edge[3] <= reconstructed[3][3];
                    end
                    1: begin
                        top_edge[4] <= reconstructed[3][0];
                        top_edge[5] <= reconstructed[3][1];
                        top_edge[6] <= reconstructed[3][2];
                        top_edge[7] <= reconstructed[3][3];
                    end
                    2: begin
                        top_edge[8] <= reconstructed[3][0];
                        top_edge[9] <= reconstructed[3][1];
                        top_edge[10] <= reconstructed[3][2];
                        top_edge[11] <= reconstructed[3][3];
                    end
                    3: begin
                        top_edge[12] <= reconstructed[3][0];
                        top_edge[13] <= reconstructed[3][1];
                        top_edge[14] <= reconstructed[3][2];
                        top_edge[15] <= reconstructed[3][3];
                    end
                    default : begin
                        for(m=0; m<32; m=m+1) 
                            top_edge[m] <= top_edge[m];
                    end
                endcase
            end
            else begin
                case (micro_cnt%4)
                    0: begin
                        top_edge[16] <= reconstructed[3][0];
                        top_edge[17] <= reconstructed[3][1];
                        top_edge[18] <= reconstructed[3][2];
                        top_edge[19] <= reconstructed[3][3];
                    end
                    1: begin
                        top_edge[20] <= reconstructed[3][0];
                        top_edge[21] <= reconstructed[3][1];
                        top_edge[22] <= reconstructed[3][2];
                        top_edge[23] <= reconstructed[3][3];
                    end
                    2: begin
                        top_edge[24] <= reconstructed[3][0];
                        top_edge[25] <= reconstructed[3][1];
                        top_edge[26] <= reconstructed[3][2];
                        top_edge[27] <= reconstructed[3][3];
                    end
                    3: begin
                        top_edge[28] <= reconstructed[3][0];
                        top_edge[29] <= reconstructed[3][1];
                        top_edge[30] <= reconstructed[3][2];
                        top_edge[31] <= reconstructed[3][3];
                    end
                    default: for(m=0; m<32; m=m+1) begin
                        top_edge[m] <= top_edge[m];
                    end
                endcase
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= 8'd0;
        end
    end
    else if (!rst_n) begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= 8'd0;
        end
    end
    else if(state_c == INPUT_PARAM) begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= 8'd128;
        end
    end
    else if (state_c ==UPDATE_EDGE)begin
        if(block_mode[blank_cnt]==0) begin
            case(micro_cnt)
                3: begin
                    left_edge[0] <= reconstructed[0][3];
                    left_edge[1] <= reconstructed[1][3];
                    left_edge[2] <= reconstructed[2][3];
                    left_edge[3] <= reconstructed[3][3];
                end
                7: begin
                    left_edge[4] <= reconstructed[0][3];
                    left_edge[5] <= reconstructed[1][3];
                    left_edge[6] <= reconstructed[2][3];
                    left_edge[7] <= reconstructed[3][3];
                end
                11: begin
                    left_edge[8] <= reconstructed[0][3];
                    left_edge[9] <= reconstructed[1][3];
                    left_edge[10] <= reconstructed[2][3];
                    left_edge[11] <= reconstructed[3][3];
                end
                15: begin
                    left_edge[12] <= reconstructed[0][3];
                    left_edge[13] <= reconstructed[1][3];
                    left_edge[14] <= reconstructed[2][3];
                    left_edge[15] <= reconstructed[3][3];
                end
                default: for(m=0; m<16; m=m+1) begin
                    left_edge[m] <= left_edge[m];
                end
            endcase
        end
        else begin
            case (micro_cnt/4)
                0: begin
                    left_edge[0] <= reconstructed[0][3];
                    left_edge[1] <= reconstructed[1][3];
                    left_edge[2] <= reconstructed[2][3];
                    left_edge[3] <= reconstructed[3][3];
                end
                1: begin
                    left_edge[4] <= reconstructed[0][3];
                    left_edge[5] <= reconstructed[1][3];
                    left_edge[6] <= reconstructed[2][3];
                    left_edge[7] <= reconstructed[3][3];
                end
                2: begin
                    left_edge[8] <= reconstructed[0][3];
                    left_edge[9] <= reconstructed[1][3];
                    left_edge[10] <= reconstructed[2][3];
                    left_edge[11] <= reconstructed[3][3];
                end
                3: begin
                    left_edge[12] <= reconstructed[0][3];
                    left_edge[13] <= reconstructed[1][3];
                    left_edge[14] <= reconstructed[2][3];
                    left_edge[15] <= reconstructed[3][3];
                end
                default: for(m=0; m<16; m=m+1) begin
                    left_edge[m] <= left_edge[m];
                end
            endcase
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) dc <= 15'd0;
    // else if(state_c == WAIT_16CYCLE) dc <= dc;
    else if(block_mode[blank_cnt] == 0)
    if(out_cnt != 256* blank_cnt) dc <=dc;
    else
        case (blank_cnt)
            0 : dc <= 128;

            1 : dc <= (left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3] + left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7] +
                left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11] + left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 4 ;
            
            2 : dc <= (top_edge[0] + top_edge[1] + top_edge[2] + top_edge[3] + top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] + top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15]) >> 4 ;

            3 : dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] + top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] + top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3] + left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7] +
                left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11] + left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15] )>> 5 ;
            default : dc <= 8'd0;
        endcase
    else if(block_mode[blank_cnt] == 1)
        case (prediction_state)
            DC     :  dc <= 128;
            DC_V   :  dc <= (top_edge[0] + top_edge[1] + top_edge[2] + top_edge[3] ) >> 2 ;  
            DC_H   :  dc <= (left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3] ) >> 2 ;
            DC_H_V :  begin
                case(blank_cnt)  
                    0 : begin
                        case(micro_cnt)
                            5 : dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            6 : dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            7 : dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            9 : dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            10: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            11: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            13: dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            14: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            15: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            default : dc <= 8'd0;
                        endcase
                    end
                    1 : begin
                        case(micro_cnt)
                            4 : dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            5 : dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            6 : dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            7 : dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;

                            8 : dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            9 : dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            10: dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            11: dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;

                            12: dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            13: dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            14: dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            15: dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            default : dc <= 8'd0;
                        endcase
                    end
                    2 : begin
                        case(micro_cnt)
                            1: dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;
                            2: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;
                            3: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;
                            5: dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            6: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            7: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;

                            9:  dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            10: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            11: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            13: dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            14: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            15: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            default : dc <= 8'd0;
                        endcase 
                    end
                    3 : begin
                        case(micro_cnt)
                            0: dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;
                            1: dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;
                            2: dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;
                            3: dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                                       left_edge[0] + left_edge[1] + left_edge[2] + left_edge[3]) >> 3 ;  
                            4: dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;  
                            5: dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            6: dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            7: dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                                       left_edge[4] + left_edge[5] + left_edge[6] + left_edge[7]) >> 3 ;
                            8: dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                        left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            9: dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] + 
                                        left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            10: dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +
                                        left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            11: dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +
                                        left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            12: dc <= (top_edge[16] + top_edge[17] + top_edge[18] + top_edge[19] +
                                        left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            13: dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
                                        left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;   
                            14: dc <= (top_edge[24] + top_edge[25] + top_edge[26] + top_edge[27] +      
                                        left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            15: dc <= (top_edge[28] + top_edge[29] + top_edge[30] + top_edge[31] +    
                                        left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            default : dc <= 8'd0;
                        endcase
                    end
                    default : dc <= 8'd0;
                endcase
            end
            default : dc <= 8'd0;
        endcase

    else dc <= dc;
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
        if(block_mode[0]==0) prediction_state = DC;
        else begin
            case(1)
                (micro_cnt ==0) : prediction_state = DC;
                (micro_cnt ==1 || micro_cnt ==2 || micro_cnt ==3) : prediction_state = DC_H;
                (micro_cnt ==4 || micro_cnt ==8 || micro_cnt ==12) : prediction_state = DC_V;
                default : prediction_state = DC_H_V;
                // (unit_cnt<16) : prediction_state = DC;
                // (unit_cnt<=63 && unit_cnt>=16) : prediction_state = DC_H;
                // (unit_cnt<=79 && unit_cnt>=64) : prediction_state = DC_V;
                // (unit_cnt<=143 && unit_cnt>=128) : prediction_state = DC_V;
                // (unit_cnt<=207 && unit_cnt>=192) : prediction_state = DC_V;
                // default : prediction_state = DC_H_V;
            endcase
        end
    end
    else if (blank_cnt == 1) begin
        if(block_mode[1]==0) prediction_state = DC_H;
        else begin
            case(1)
                (micro_cnt==0 || micro_cnt ==1 || micro_cnt ==2 || micro_cnt ==3 ) : prediction_state = DC_H;
                default : prediction_state = DC_H_V;
            endcase
        end
    end
    else if (blank_cnt ==2 ) begin
        if(block_mode[2]==0) prediction_state = DC_V;
        else begin
            case(1)
                (micro_cnt==0 || micro_cnt ==4 || micro_cnt ==8 || micro_cnt ==12 ) : prediction_state = DC_V;
                default : prediction_state = DC_H_V;
                // (unit_cnt<=15 && unit_cnt>=0) : prediction_state = DC_V;
                // (unit_cnt<=79 && unit_cnt>=64) : prediction_state = DC_V;
                // (unit_cnt<=143 && unit_cnt>=128) : prediction_state = DC_V;
                // (unit_cnt<=207 && unit_cnt>=192) : prediction_state = DC_V;
                // default : prediction_state = DC_H_V;
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
// reg   [7:0] prediction_dc [0:3][0:3];
// reg   [7:0] prediction_horizontal [0:3][0:3];
// reg   [7:0] prediction_vertical [0:3][0:3];
// reg signed [13:0] Residual [0:3][0:3];
// reg signed [13:0] transform_temp [0:3][0:3];//maybe

// reg   [31:0] sad_dc,sad_horizontal,sad_vertical;
// reg   [1:0]  prediction_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                prediction_dc[m][n] <= 8'd0;
    else if (state_c == IDLE) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                prediction_dc[m][n] <= 8'd0;
    else if(state_c == WAIT_16CYCLE || state_c==WAIT_256CYCLE) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                prediction_dc[m][n] <= dc;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_dc <= 32'd0;
    else if (state_c == IDLE) sad_dc <= 32'd0;

    else if (state_c ==WAIT_256CYCLE && waiting_cnt>1 ) begin
        if(frame_data>dc)
            sad_dc <= sad_dc + frame_data - dc;
        else 
            sad_dc <= sad_dc - frame_data + dc;
    end
    else if(state_c == WAIT_16CYCLE && waiting_cnt>1) begin
        if(frame_data > dc)
            sad_dc <= sad_dc + frame_data - dc;
        else 
            sad_dc <= sad_dc - frame_data + dc;
    end
    else sad_dc <= 0;
end

always @ (posedge clk or negedge rst_n) begin //maybe combination
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                prediction_horizontal[m][n] <= 8'd0;
    else if (state_c == IDLE) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                prediction_horizontal[m][n] <= 8'd0;
    else if(state_c == WAIT_16CYCLE || state_c==WAIT_256CYCLE) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                prediction_horizontal[m][n] <= left_edge[( micro_cnt/4 )*4+ m];
    end
end

wire [10:0] left_index;

assign left_index =( ( (waiting_cnt-2)/4 ) % 4 ) + ( (waiting_cnt-2) / 64 )*4 ;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_horizontal <= 32'd0;
    else if (state_c == IDLE) sad_horizontal <= 32'd0;
    else if ((state_c ==WAIT_256CYCLE) && waiting_cnt>1 ) begin
        if (frame_data > left_edge[left_index])
            sad_horizontal <= sad_horizontal + frame_data - left_edge[left_index];
        else 
            sad_horizontal <= sad_horizontal - frame_data + left_edge[left_index];
        // if(frame_data > prediction_horizontal[((waiting_cnt-2)%16)/4] [((waiting_cnt-2)%16)%4])
        //     sad_horizontal <= sad_horizontal + frame_data - prediction_horizontal[((waiting_cnt-2)%16)/4] [((waiting_cnt-2)%16)%4];
        // else 
        //     sad_horizontal <= sad_horizontal - frame_data + prediction_horizontal[((waiting_cnt-2)%16)/4] [((waiting_cnt-2)%16)%4];
    end

    else if((state_c == WAIT_16CYCLE) && waiting_cnt>1) begin
        if(frame_data > prediction_horizontal[(waiting_cnt-2)/4] [(waiting_cnt-2)%4])
            sad_horizontal <= sad_horizontal + frame_data - prediction_horizontal[(waiting_cnt-2)/4] [(waiting_cnt-2)%4];
        else 
            sad_horizontal <= sad_horizontal - frame_data + prediction_horizontal[(waiting_cnt-2)/4] [(waiting_cnt-2)%4];
    end
    else sad_horizontal <= 0;
end

always @ (posedge clk or negedge rst_n) begin //maybe combination
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                prediction_vertical[m][n] <= 8'd0;
    else if (state_c == IDLE) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                prediction_vertical[m][n] <= 8'd0;
    else if(state_c == WAIT_16CYCLE || state_c==WAIT_256CYCLE) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                prediction_vertical[n][m] <= top_edge[( micro_cnt%4 )*4 + m + 16*blank_cnt[0] ];
    end
end
reg [3:0] top_index;
wire [4:0] top_index_offset;
always @ (*) begin
    case (waiting_cnt-2)
        0,4,8,12,    64,68,72,76 ,    128,132,136,140,    192,196,200,204 : top_index = 0;
        1,5,9,13,    65,69,73,77 ,    129,133,137,141,    193,197,201,205 : top_index = 1;
        2,6,10,14,   66,70,74,78 ,    130,134,138,142,    194,198,202,206 : top_index = 2;
        3,7,11,15,   67,71,75,79 ,    131,135,139,143,    195,199,203,207 : top_index = 3;
        16,20,24,28, 80,84,88,92 ,    144,148,152,156,    208,212,216,220 : top_index = 4;
        17,21,25,29, 81,85,89,93 ,    145,149,153,157,    209,213,217,221 : top_index = 5;
        18,22,26,30, 82,86,90,94 ,    146,150,154,158,    210,214,218,222 : top_index = 6;
        19,23,27,31, 83,87,91,95 ,    147,151,155,159,    211,215,219,223 : top_index = 7;
        32,36,40,44, 96,100,104,108,  160,164,168,172,    224,228,232,236 : top_index = 8;
        33,37,41,45, 97,101,105,109,  161,165,169,173,    225,229,233,237 : top_index = 9;
        34,38,42,46, 98,102,106,110,  162,166,170,174,    226,230,234,238 : top_index = 10;
        35,39,43,47, 99,103,107,111,  163,167,171,175,    227,231,235,239 : top_index = 11;
        48,52,56,60, 112,116,120,124,  176,180,184,188,    240,244,248,252 : top_index = 12;
        49,53,57,61, 113,117,121,125,  177,181,185,189,    241,245,249,253 : top_index = 13 ;
        50,54,58,62, 114,118,122,126,  178,182,186,190,    242,246,250,254 : top_index = 14 ;
        51,55,59,63, 115,119,123,127,  179,183,187,191,    243,247,251,255 : top_index = 15 ;
        default : top_index = 0;
    endcase
end

assign top_index_offset = (blank_cnt == 1 || blank_cnt==3 ) ? 16 : 0 ;
// assign top_index = (  (waiting_cnt-2) % 4 ) + (( (waiting_cnt-2) / 16 )%16)*4 + top_index_offset;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_vertical <= 32'd0;
    else if (state_c == IDLE) sad_vertical <= 32'd0;
    else if (state_c ==WAIT_256CYCLE && waiting_cnt>1 ) begin
        if (frame_data > top_edge[top_index+top_index_offset])
            sad_vertical <= sad_vertical + frame_data - top_edge[top_index+top_index_offset];
        else 
            sad_vertical <= sad_vertical - frame_data + top_edge[top_index+top_index_offset];
        // if(frame_data > prediction_vertical[((waiting_cnt-2)%16)/4] [((waiting_cnt-2)%16)%4])
        //     sad_vertical <= sad_vertical + frame_data - prediction_vertical[((waiting_cnt-2)%16)/4] [((waiting_cnt-2)%16)%4];
        // else 
        //     sad_vertical <= sad_vertical - frame_data + prediction_vertical[((waiting_cnt-2)%16)/4] [((waiting_cnt-2)%16)%4];
    end

    else if((state_c == WAIT_16CYCLE) && waiting_cnt>1) begin
        if(frame_data >  prediction_vertical[(waiting_cnt-2)/4] [(waiting_cnt-2)%4])
            sad_vertical <= sad_vertical + frame_data - prediction_vertical[(waiting_cnt-2)/4] [(waiting_cnt-2)%4];
        else 
            sad_vertical <= sad_vertical - frame_data + prediction_vertical[(waiting_cnt-2)/4] [(waiting_cnt-2)%4];
    end
    else sad_vertical <= 0;
end

// always @ (posedge clk or negedge rst_n) begin
//     if(!rst_n) sad_vertical <= 32'd0;
//     else if((state_c == WAIT_16CYCLE || state_c==WAIT_256CYCLE) && waiting_cnt>1) begin
//         if(frame_data > top_edge[( micro_cnt/4 )*4 + ((unit_cnt)/4)])
//             sad_vertical <= sad_vertical + frame_data - top_edge[( micro_cnt/4 )*4 + ((unit_cnt)/4)];
//         else 
//             sad_vertical <= sad_vertical - frame_data + top_edge[( micro_cnt/4 )*4 + ((unit_cnt)/4)];
//     end
//     else sad_vertical <= 0;
// end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) prediction_right <= 2'd0;
    // else if(state_c == WAIT_16CYCLE || state_c == WAIT_256CYCLE) begin
    else if(waiting_cnt>17) begin
        case(prediction_state)
            DC     : prediction_right <= 0;
            DC_V   : begin
                if (sad_dc <= sad_vertical) prediction_right <= 0;
                else prediction_right <= 1;
            end
            DC_H   : begin
                if (sad_dc <= sad_horizontal) prediction_right <= 0;
                else prediction_right <= 2;
            end
            DC_H_V : begin
                if (sad_dc <= sad_horizontal && sad_dc <= sad_vertical) prediction_right <= 0;
                else if (sad_horizontal < sad_dc && sad_horizontal <= sad_vertical) prediction_right <= 2;
                else prediction_right <= 1;
            end
            default : prediction_right <= 3;
        endcase
    end
    else prediction_right <= prediction_right;
end

// always @(*) begin
//     if(state_c == UPDATE_EDGE)
//         if(sad_dc <= sad_vertical && sad_dc <= sad_horizontal) 
//             prediction_right = 0;
//         else if(sad_horizontal < sad_dc && sad_horizontal <= sad_vertical) 
//             prediction_right = 2;
//         else if(sad_vertical < sad_dc && sad_vertical < sad_horizontal) 
//             prediction_right = 1;
//         else
//             prediction_right = 3;
//     else 
//         prediction_right = 3;
// end

always @ (posedge clk ) begin
    if( state_c == WAIT_16CYCLE || state_c == WAIT_256CYCLE) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                Residual[m][n] <= 8'd0;
            end
        end
    end
    else if(state_c == CALU_RESIDUAL) begin
        if (block_mode[blank_cnt] == 1)
            case(prediction_state)
                DC     : 
                for(m=0; m<4; m=m+1) begin
                    for(n=0; n<4; n=n+1) begin
                        // Residual[m][n] <= block_data[m][n] - dc ;
                        Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_dc[m][n] ;
                    end
                end
                DC_V   : begin
                    if (sad_dc <= sad_vertical) 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                // Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - dc ;
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_dc[m][n] ;
                            end
                        end
                    else 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_vertical[m][n] ;
                            end
                        end
                end
                DC_H   : begin
                    if (sad_dc <= sad_horizontal) 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - dc ;
                            end
                        end
                    else 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4]- prediction_horizontal[m][n] ;
                            end
                        end
                end
                DC_H_V :  begin
                    if (sad_dc <= sad_horizontal && sad_dc <= sad_vertical) 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - dc ;
                            end
                        end
                    else if (sad_horizontal < sad_dc && sad_horizontal <= sad_vertical) 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_horizontal[m][n] ;
                            end
                        end
                    else 
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_vertical[m][n] ;
                            end
                        end
                end
                default : Residual[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] <= 8'd0;
            endcase
        else 
            case(prediction_right)
                0     : 
                for(m=0; m<4; m=m+1) begin
                    for(n=0; n<4; n=n+1) begin
                        Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_dc[m][n] ;
                    end
                end
                1   : begin // top_edge[( micro_cnt%4 )*4 + m + 16*blank_cnt[0] ]
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - top_edge[( micro_cnt%4 )*4 + n + 16*blank_cnt[0] ] ;
                            end
                        end
                end
                2   : begin
                        for(m=0; m<4; m=m+1) begin
                            for(n=0; n<4; n=n+1) begin
                                Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - left_edge[ (micro_cnt/4)*4 +m] ;
                            end
                        end
                end
                default : Residual[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] <= 8'd0;
            endcase
            // case(prediction_state)
            //     DC     : 
            //     for(m=0; m<4; m=m+1) begin
            //         for(n=0; n<4; n=n+1) begin
            //             // Residual[m][n] <= block_data[m][n] - dc ;
            //             Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_dc[m][n] ;
            //         end
            //     end
            //     DC_V   : begin
            //         if (sad_dc <= sad_vertical) 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     // Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - dc ;
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_dc[m][n] ;
            //                 end
            //             end
            //         else 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_vertical[m][n] ;
            //                 end
            //             end
            //     end
            //     DC_H   : begin
            //         if (sad_dc <= sad_horizontal) 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - dc ;
            //                 end
            //             end
            //         else 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4]- prediction_horizontal[m][n] ;
            //                 end
            //             end
            //     end
            //     DC_H_V :  begin
            //         if (sad_dc <= sad_horizontal && sad_dc <= sad_vertical) 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - dc ;
            //                 end
            //             end
            //         else if (sad_horizontal < sad_dc && sad_horizontal <= sad_vertical) 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_horizontal[m][n] ;
            //                 end
            //             end
            //         else 
            //             for(m=0; m<4; m=m+1) begin
            //                 for(n=0; n<4; n=n+1) begin
            //                     Residual[m][n] <= block_data[m+(micro_cnt/4)*4][n+(micro_cnt%4)*4] - prediction_vertical[m][n] ;
            //                 end
            //             end
            //     end
            //     default : Residual[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] <= 8'd0;
            // endcase
    end
    else begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                Residual[m][n] <= Residual[m][n];
            end
        end
    end
end

//==================================================================
// Transform
//==================================================================

transform Transform_inst (
    .X00(Residual[0][0]), .X01(Residual[0][1]), .X02(Residual[0][2]), .X03(Residual[0][3]),
    .X10(Residual[1][0]), .X11(Residual[1][1]), .X12(Residual[1][2]), .X13(Residual[1][3]),
    .X20(Residual[2][0]), .X21(Residual[2][1]), .X22(Residual[2][2]), .X23(Residual[2][3]),
    .X30(Residual[3][0]), .X31(Residual[3][1]), .X32(Residual[3][2]), .X33(Residual[3][3]),
    .W00(transform_temp[0][0]), .W01(transform_temp[0][1]), .W02(transform_temp[0][2]), .W03(transform_temp[0][3]),
    .W10(transform_temp[1][0]), .W11(transform_temp[1][1]), .W12(transform_temp[1][2]), .W13(transform_temp[1][3]),
    .W20(transform_temp[2][0]), .W21(transform_temp[2][1]), .W22(transform_temp[2][2]), .W23(transform_temp[2][3]),
    .W30(transform_temp[3][0]), .W31(transform_temp[3][1]), .W32(transform_temp[3][2]), .W33(transform_temp[3][3])
);

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                transform_data[m][n] <= 14'd0;
    else if(state_c == TRANSFORM) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                transform_data[m][n] <= transform_temp[m][n];
    end
end

//==================================================================
// Quantization
//==================================================================
Quantization Quantization_inst (
    .QP(QP_reg),
    .W00(transform_data[0][0]), .W01(transform_data[0][1]), .W02(transform_data[0][2]), .W03(transform_data[0][3]),
    .W10(transform_data[1][0]), .W11(transform_data[1][1]), .W12(transform_data[1][2]), .W13(transform_data[1][3]),
    .W20(transform_data[2][0]), .W21(transform_data[2][1]), .W22(transform_data[2][2]), .W23(transform_data[2][3]),
    .W30(transform_data[3][0]), .W31(transform_data[3][1]), .W32(transform_data[3][2]), .W33(transform_data[3][3]),
    .Z00(quantization_temp[0][0]), .Z01(quantization_temp[0][1]), .Z02(quantization_temp[0][2]), .Z03(quantization_temp[0][3]),
    .Z10(quantization_temp[1][0]), .Z11(quantization_temp[1][1]), .Z12(quantization_temp[1][2]), .Z13(quantization_temp[1][3]),
    .Z20(quantization_temp[2][0]), .Z21(quantization_temp[2][1]), .Z22(quantization_temp[2][2]), .Z23(quantization_temp[2][3]),
    .Z30(quantization_temp[3][0]), .Z31(quantization_temp[3][1]), .Z32(quantization_temp[3][2]), .Z33(quantization_temp[3][3])
);

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                quantization_data[m][n] <= 14'd0;
    else if(state_c == QUANTIZATION) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                quantization_data[m][n] <= quantization_temp[m][n];
    end
end

//==================================================================
// DeQuantization
//==================================================================
DeQuantization DeQuantization_inst (
    .QP(QP_reg),
    .Z00(quantization_data[0][0]), .Z01(quantization_data[0][1]), .Z02(quantization_data[0][2]), .Z03(quantization_data[0][3]),
    .Z10(quantization_data[1][0]), .Z11(quantization_data[1][1]), .Z12(quantization_data[1][2]), .Z13(quantization_data[1][3]),
    .Z20(quantization_data[2][0]), .Z21(quantization_data[2][1]), .Z22(quantization_data[2][2]), .Z23(quantization_data[2][3]),
    .Z30(quantization_data[3][0]), .Z31(quantization_data[3][1]), .Z32(quantization_data[3][2]), .Z33(quantization_data[3][3]),
    .W_00(dequantization_temp[0][0]), .W_01(dequantization_temp[0][1]), .W_02(dequantization_temp[0][2]), .W_03(dequantization_temp[0][3]),
    .W_10(dequantization_temp[1][0]), .W_11(dequantization_temp[1][1]), .W_12(dequantization_temp[1][2]), .W_13(dequantization_temp[1][3]),
    .W_20(dequantization_temp[2][0]), .W_21(dequantization_temp[2][1]), .W_22(dequantization_temp[2][2]), .W_23(dequantization_temp[2][3]),
    .W_30(dequantization_temp[3][0]), .W_31(dequantization_temp[3][1]), .W_32(dequantization_temp[3][2]), .W_33(dequantization_temp[3][3])
);

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                dequantization_data[m][n] <= 41'd0;
    else if(state_c == DEQUANTIZATION) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                dequantization_data[m][n] <= dequantization_temp[m][n];
    end
end

//==================================================================
// Inverse Transform
//==================================================================
transform #(42) InverseTransform_inst  (
    .X00(dequantization_data[0][0]), .X01(dequantization_data[0][1]), .X02(dequantization_data[0][2]), .X03(dequantization_data[0][3]),
    .X10(dequantization_data[1][0]), .X11(dequantization_data[1][1]), .X12(dequantization_data[1][2]), .X13(dequantization_data[1][3]),
    .X20(dequantization_data[2][0]), .X21(dequantization_data[2][1]), .X22(dequantization_data[2][2]), .X23(dequantization_data[2][3]),
    .X30(dequantization_data[3][0]), .X31(dequantization_data[3][1]), .X32(dequantization_data[3][2]), .X33(dequantization_data[3][3]),
    .W00(inv_transform_temp[0][0]), .W01(inv_transform_temp[0][1]), .W02(inv_transform_temp[0][2]), .W03(inv_transform_temp[0][3]),
    .W10(inv_transform_temp[1][0]), .W11(inv_transform_temp[1][1]), .W12(inv_transform_temp[1][2]), .W13(inv_transform_temp[1][3]),
    .W20(inv_transform_temp[2][0]), .W21(inv_transform_temp[2][1]), .W22(inv_transform_temp[2][2]), .W23(inv_transform_temp[2][3]),
    .W30(inv_transform_temp[3][0]), .W31(inv_transform_temp[3][1]), .W32(inv_transform_temp[3][2]), .W33(inv_transform_temp[3][3])
);

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                inv_transform_data[m][n] <= 14'd0;
    else if(state_c == INVERSE_TRANSFORM) begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1)
                inv_transform_data[m][n] <= (inv_transform_temp[m][n])>>>6 ;
    end
end

//==================================================================
// Reconstruction
//==================================================================
always @(*) begin
    if(block_mode[blank_cnt] == 1) //intra
        case(prediction_right)
            0 : for (m=0; m<4; m=m+1)  //dc
                    for (n=0; n<4; n=n+1)
                        reconstructed_block[m][n] = inv_transform_data[m][n] + prediction_dc[m][n];
            1 : for (m=0; m<4; m=m+1)  //vertical // top_edge[( micro_cnt%4 )*4 + n + 16*blank_cnt[0] ] 
                    for (n=0; n<4; n=n+1)
                        reconstructed_block[m][n] = inv_transform_data[m][n] + prediction_vertical[m][n];
            2 : for (m=0; m<4; m=m+1) //horizontal //left_edge[ (micro_cnt/4)*4 +m] 
                    for (n=0; n<4; n=n+1)
                        reconstructed_block[m][n] = inv_transform_data[m][n] + prediction_horizontal[m][n];
            default : for (m=0; m<4; m=m+1) 
                        for (n=0; n<4; n=n+1)
                            reconstructed_block[m][n] = 47'd0;
        endcase
    else 
        case(prediction_right)
            0 : for (m=0; m<4; m=m+1)  //dc
                    for (n=0; n<4; n=n+1)
                        reconstructed_block[m][n] = inv_transform_data[m][n] + prediction_dc[m][n];
            1 : for (m=0; m<4; m=m+1)  //vertical // top_edge[( micro_cnt%4 )*4 + n + 16*blank_cnt[0] ] 
                    for (n=0; n<4; n=n+1)
                        reconstructed_block[m][n] = inv_transform_data[m][n] + top_edge[( micro_cnt%4 )*4 + n + 16*blank_cnt[0] ] ;
            2 : for (m=0; m<4; m=m+1) //horizontal //left_edge[ (micro_cnt/4)*4 +m] 
                    for (n=0; n<4; n=n+1)
                        reconstructed_block[m][n] = inv_transform_data[m][n] + left_edge[ (micro_cnt/4)*4 +m];
            default : for (m=0; m<4; m=m+1) 
                        for (n=0; n<4; n=n+1)
                            reconstructed_block[m][n] = 47'd0;
        endcase
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) 
        for ( m=0; m<4; m=m+1) 
            for (n=0; n<4; n=n+1)
                reconstructed[m][n] <= 8'd0;
    else begin
        for ( m=0; m<4; m=m+1)
            for (n=0; n<4; n=n+1) begin
                if(reconstructed_block[m][n] > 255) 
                    reconstructed[m][n] <= 8'd255;
                else if(reconstructed_block[m][n] < 0) 
                    reconstructed[m][n] <= 8'd0;
                else 
                    reconstructed[m][n] <= reconstructed_block[m][n];
            end
    end
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
    else if(micro_cnt == 15 && state_c ==UPDATE_EDGE) begin
        for(m=0; m<16; m=m+1) begin
            for(n=0; n<16; n=n+1) begin
                block_data[m][n] <= 0;
            end
        end
    end
    else if(state_c == WAIT_16CYCLE || state_c==WAIT_256CYCLE) begin
       case (unit_cnt%256) //maybe
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
                for(m=0; m<4; m=m+1) begin
                    for(n=0; n<4; n=n+1) begin
                        block_data[m][n] <= block_data[m][n];
                    end
                end
            end
       endcase
    end
    else begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
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
//==================================================================
// output
//==================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(state_c > QUANTIZATION && state_c<=UPDATE_EDGE ) out_valid <= 1;
    else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) out_value  <= 0;
    else if(state_c > QUANTIZATION && state_c<=UPDATE_EDGE ) out_value <= quantization_data[out_addr_cnt/4][out_addr_cnt%4];
    else out_value <= 0;
end


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
    parameter WIDTH = 18,
    localparam OUTZ = 32
)(
    input  [4:0] QP,
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
reg [4:0] qbits;
wire 
    signZ00, signZ01, signZ02, signZ03,
    signZ10, signZ11, signZ12, signZ13,
    signZ20, signZ21, signZ22, signZ23,
    signZ30, signZ31, signZ32, signZ33;

wire signed [WIDTH-1:0]
    absW00, absW01, absW02, absW03,
    absW10, absW11, absW12, absW13,
    absW20, absW21, absW22, absW23,
    absW30, absW31, absW32, absW33;

assign absW00 = (W00<0) ? -W00 : W00 ;
assign absW01 = (W01<0) ? -W01 : W01 ;
assign absW02 = (W02<0) ? -W02 : W02 ;
assign absW03 = (W03<0) ? -W03 : W03 ;
assign absW10 = (W10<0) ? -W10 : W10 ;
assign absW11 = (W11<0) ? -W11 : W11 ;
assign absW12 = (W12<0) ? -W12 : W12 ;
assign absW13 = (W13<0) ? -W13 : W13 ;
assign absW20 = (W20<0) ? -W20 : W20 ;
assign absW21 = (W21<0) ? -W21 : W21 ;
assign absW22 = (W22<0) ? -W22 : W22 ;
assign absW23 = (W23<0) ? -W23 : W23 ;
assign absW30 = (W30<0) ? -W30 : W30 ;
assign absW31 = (W31<0) ? -W31 : W31 ;
assign absW32 = (W32<0) ? -W32 : W32 ;
assign absW33 = (W33<0) ? -W33 : W33 ;

//LUT
always @ (*) begin
    case(QP)
        0,1,2,3,4,5 : qbits = 5'd15 ;
        6,7,8,9,10,11 : qbits = 5'd16 ;
        12,13,14,15,16,17 : qbits = 5'd17 ;
        18,19,20,21,22,23 : qbits = 5'd18 ;
        24,25,26,27,28,29 : qbits = 5'd19 ;
        default : qbits = 5'd0 ;
    endcase
end

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
            c = 13'd7490 ;
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

assign Z00 = (W00 > 0) ? (( absW00 * a ) + f ) >> qbits : -( (( absW00 * a ) + f ) >> qbits ) ;
assign Z01 = (W01 > 0) ? (( absW01 * c ) + f ) >> qbits : -( (( absW01 * c ) + f ) >> qbits ) ;
assign Z02 = (W02 > 0) ? (( absW02 * a ) + f ) >> qbits : -( (( absW02 * a ) + f ) >> qbits ) ;
assign Z03 = (W03 > 0) ? (( absW03 * c ) + f ) >> qbits : -( (( absW03 * c ) + f ) >> qbits ) ;

assign Z10 = (W10 > 0) ? (( absW10 * c ) + f ) >> qbits : -( (( absW10 * c ) + f ) >> qbits ) ;
assign Z11 = (W11 > 0) ? (( absW11 * b ) + f ) >> qbits : -( (( absW11 * b ) + f ) >> qbits ) ;
assign Z12 = (W12 > 0) ? (( absW12 * c ) + f ) >> qbits : -( (( absW12 * c ) + f ) >> qbits ) ;
assign Z13 = (W13 > 0) ? (( absW13 * b ) + f ) >> qbits : -( (( absW13 * b ) + f ) >> qbits ) ;

assign Z20 = (W20 > 0) ? (( absW20 * a ) + f ) >> qbits : -( (( absW20 * a ) + f ) >> qbits ) ;
assign Z21 = (W21 > 0) ? (( absW21 * c ) + f ) >> qbits : -( (( absW21 * c ) + f ) >> qbits ) ;
assign Z22 = (W22 > 0) ? (( absW22 * a ) + f ) >> qbits : -( (( absW22 * a ) + f ) >> qbits ) ;
assign Z23 = (W23 > 0) ? (( absW23 * c ) + f ) >> qbits : -( (( absW23 * c ) + f ) >> qbits ) ;

assign Z30 = (W30 > 0) ? (( absW30 * c ) + f ) >> qbits : -( (( absW30 * c ) + f ) >> qbits ) ;
assign Z31 = (W31 > 0) ? (( absW31 * b ) + f ) >> qbits : -( (( absW31 * b ) + f ) >> qbits ) ;
assign Z32 = (W32 > 0) ? (( absW32 * c ) + f ) >> qbits : -( (( absW32 * c ) + f ) >> qbits ) ;
assign Z33 = (W33 > 0) ? (( absW33 * b ) + f ) >> qbits : -( (( absW33 * b ) + f ) >> qbits ) ;

endmodule

module DeQuantization #(
    parameter WIDTH = 32,
    localparam OUTZ = 42
)(
    input  [4:0] QP,
    input  signed [WIDTH-1:0] Z00, input  signed [WIDTH-1:0] Z01, input  signed [WIDTH-1:0] Z02, input  signed [WIDTH-1:0] Z03,
    input  signed [WIDTH-1:0] Z10, input  signed [WIDTH-1:0] Z11, input  signed [WIDTH-1:0] Z12, input  signed [WIDTH-1:0] Z13,
    input  signed [WIDTH-1:0] Z20, input  signed [WIDTH-1:0] Z21, input  signed [WIDTH-1:0] Z22, input  signed [WIDTH-1:0] Z23,
    input  signed [WIDTH-1:0] Z30, input  signed [WIDTH-1:0] Z31, input  signed [WIDTH-1:0] Z32, input  signed [WIDTH-1:0] Z33,

    output signed [OUTZ-1:0] W_00, output signed [OUTZ-1:0] W_01, output signed [OUTZ-1:0] W_02, output signed [OUTZ-1:0] W_03,
    output signed [OUTZ-1:0] W_10, output signed [OUTZ-1:0] W_11, output signed [OUTZ-1:0] W_12, output signed [OUTZ-1:0] W_13,
    output signed [OUTZ-1:0] W_20, output signed [OUTZ-1:0] W_21, output signed [OUTZ-1:0] W_22, output signed [OUTZ-1:0] W_23,
    output signed [OUTZ-1:0] W_30, output signed [OUTZ-1:0] W_31, output signed [OUTZ-1:0] W_32, output signed [OUTZ-1:0] W_33
);
reg signed [5:0] a,b,c;
reg [2:0] qbits;

//LUT
always @ (*) begin
    case(QP)
        0,1,2,3,4,5 : qbits = 3'd0 ;
        6,7,8,9,10,11 : qbits = 3'd1 ;
        12,13,14,15,16,17 : qbits = 3'd2 ;
        18,19,20,21,22,23 : qbits = 3'd3 ;
        24,25,26,27,28,29 : qbits = 3'd4 ;
        default : qbits = 3'd0 ;
    endcase
end

always @(*) begin
    case(QP)
        0,6,12,18,24 : begin
            a = 6'd10 ; b = 6'd16 ; c = 6'd13 ;
        end
        1,7,13,19,25 : begin
            a = 6'd11 ; b = 6'd18 ; c = 6'd14 ;
        end
        2,8,14,20,26 : begin
            a = 6'd13 ; b = 6'd20 ; c = 6'd16 ;
        end
        3,9,15,21,27 : begin
            a = 6'd14 ; b = 6'd23 ; c = 6'd18 ;
        end
        4,10,16,22,28 : begin
            a = 6'd16 ; b = 6'd25 ; c = 6'd20 ;
        end
        5,11,17,23,29 : begin
            a = 6'd18 ; b = 6'd29 ; c = 6'd23 ;
        end
        default : begin
            a = 6'd0 ; b = 6'd0 ; c = 6'd0 ;
        end
    endcase
end

assign W_00 = (Z00 * a )<< qbits ;
assign W_01 = (Z01 * c )<< qbits ;
assign W_02 = (Z02 * a )<< qbits ;
assign W_03 = (Z03 * c )<< qbits ;

assign W_10 = (Z10 * c )<< qbits ;
assign W_11 = (Z11 * b )<< qbits ; // 
assign W_12 = (Z12 * c )<< qbits ;
assign W_13 = (Z13 * b )<< qbits ;

assign W_20 = (Z20 * a )<< qbits ;
assign W_21 = (Z21 * c )<< qbits ;
assign W_22 = (Z22 * a )<< qbits ;
assign W_23 = (Z23 * c )<< qbits ;

assign W_30 = (Z30 * c )<< qbits ;
assign W_31 = (Z31 * b )<< qbits ;
assign W_32 = (Z32 * c )<< qbits ;
assign W_33 = (Z33 * b )<< qbits ;

endmodule

module transform #( //no
    parameter WIDTH = 14,
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
wire signed [OUTW-1:0] T00, T01, T02, T03,
                        T10, T11, T12, T13,
                        T20, T21, T22, T23,
                        T30, T31, T32, T33;         
// first stage
    assign T00 = X00 + X10 + X20 + X30;
    assign T01 = X01 + X11 + X21 + X31;
    assign T02 = X02 + X12 + X22 + X32;
    assign T03 = X03 + X13 + X23 + X33;

    assign T10 = X00 + X10 - X20 - X30;
    assign T11 = X01 + X11 - X21 - X31;
    assign T12 = X02 + X12 - X22 - X32;
    assign T13 = X03 + X13 - X23 - X33;

    assign T20 = X00 - X10 - X20 + X30;
    assign T21 = X01 - X11 - X21 + X31;
    assign T22 = X02 - X12 - X22 + X32;
    assign T23 = X03 - X13 - X23 + X33;

    assign T30 = X00 - X10 + X20 - X30;
    assign T31 = X01 - X11 + X21 - X31;
    assign T32 = X02 - X12 + X22 - X32;
    assign T33 = X03 - X13 + X23 - X33;
// second stage
    assign W00 = T00 + T01 + T02 + T03 ;
    assign W01 = T00 + T01 - T02 - T03 ;
    assign W02 = T00 - T01 - T02 + T03 ;
    assign W03 = T00 - T01 + T02 - T03 ;

    assign W10 = T10 + T11 + T12 + T13 ;
    assign W11 = T10 + T11 - T12 - T13 ;
    assign W12 = T10 - T11 - T12 + T13 ;
    assign W13 = T10 - T11 + T12 - T13 ;

    assign W20 = T20 + T21 + T22 + T23 ;
    assign W21 = T20 + T21 - T22 - T23 ;
    assign W22 = T20 - T21 - T22 + T23 ;
    assign W23 = T20 - T21 + T22 - T23 ;

    assign W30 = T30 + T31 + T32 + T33 ;
    assign W31 = T30 + T31 - T32 - T33 ;
    assign W32 = T30 - T31 - T32 + T33 ;
    assign W33 = T30 - T31 + T32 - T33 ;

endmodule

//==================================================================
// Cycle: 20.00
// Area: 2157322.747542
// Performance: 93080828741243.27734083528000

// Cycle: 15.00
// Area: 2292704.709615
// Performance: 78847423282362.02210172337500


