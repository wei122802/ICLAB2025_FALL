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
parameter WAIT_16CYCLE      = 3;
parameter WAIT_256CYCLE     = 10;
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
reg   [7:0]  dc;
reg   [7:0]  block_data [0:3] [0:3];
reg   [7:0]  left_edge [0:15];
reg   [7:0]  top_edge [0:31];

reg   [7:0] prediction_dc [0:3][0:3];
reg   [7:0] prediction_horizontal [0:3][0:3];
reg   [7:0] prediction_vertical [0:3][0:3];
reg signed [13:0] Residual [0:3][0:3];
reg signed [13:0] transform_temp [0:3][0:3];//maybe

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
reg [3:0] micro_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) micro_cnt <= 4'b0;
    else if (state_c == WAIT_16CYCLE) micro_cnt <= 4'b0;
    else if (state_c == UPDATE_EDGE) micro_cnt <= micro_cnt + 4'b1;
    else micro_cnt <= micro_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) blank_cnt <= 2'd0;
    else if(state_c == INPUT_FRAME ) blank_cnt <= 2'd0;
    else if(unit_cnt==256 || unit_cnt==512 || unit_cnt == 768) blank_cnt <= blank_cnt + 2'd1;
    else blank_cnt <= 2'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_cnt <= 10'd0;
    else if(state_c == WAIT_16CYCLE || state_c ==WAIT_256CYCLE) addr_cnt <= addr_cnt + 10'd1;
    else addr_cnt <= 10'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) frame_cnt <= 14'd0;
    else if(in_valid_data) frame_cnt <= frame_cnt + 14'd1;
    else if (state_c == WAIT_16CYCLE || state_c ==WAIT_256CYCLE)
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
    else if((state_c == WAIT_16CYCLE || state_c ==WAIT_256CYCLE) && addr_cnt>1) unit_cnt <= unit_cnt + 10'd1;
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
            else if(block_mode[0] == 1'b1) state_n = WAIT_256CYCLE;
            else state_n = WAIT_16CYCLE;
        end
        WAIT_256CYCLE : begin
            if(unit_cnt >= 10'd255) state_n = CALU_RESIDUAL;
            else state_n = WAIT_256CYCLE;
        end

        WAIT_16CYCLE : begin
            if(unit_cnt >= 10'd15) state_n = CALU_RESIDUAL;
            else state_n = WAIT_16CYCLE;
        end
        CALU_RESIDUAL : 
            state_n = TRANSFORM;

        TRANSFORM :
            state_n = TRANSFORM;
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
    else if(state_c == INPUT_PARAM) begin
        for(m=0; m<32; m=m+1) begin
            top_edge[m] <= m*2;
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
            left_edge[m] <= 8'd128;
        end
    end
    else if (state_c ==UPDATE_EDGE)begin
        for(m=0; m<16; m=m+1) begin
            left_edge[m] <= left_edge[m]; //deal with edge 
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) dc <= 8'd0;
    else if(state_c == WAIT_16CYCLE) dc <= dc;
    else if(block_mode[blank_cnt] == 1)
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
    else if(block_mode[blank_cnt] == 0)
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

                            12: dc <= (top_edge[20] + top_edge[21] + top_edge[22] + top_edge[23] +
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

                            9: dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            10: dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            11: dc <= (top_edge[12] + top_edge[13] + top_edge[14] + top_edge[15] +
                                       left_edge[8] + left_edge[9] + left_edge[10] + left_edge[11]) >> 3 ;
                            13: dc <= (top_edge[4] + top_edge[5] + top_edge[6] + top_edge[7] +
                                       left_edge[12] + left_edge[13] + left_edge[14] + left_edge[15]) >> 3 ;
                            14:dc <= (top_edge[8] + top_edge[9] + top_edge[10] + top_edge[11] +
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
// reg signed [7:0] prediction_dc [0:3][0:3];
// reg signed [7:0] prediction_horizontal [0:3][0:3];
// reg signed [7:0] prediction_vertical [0:3][0:3];
// reg   [7:0] Residual [0:3][0:3];

// reg   [31:0] sad_dc,sad_horizontal,sad_vertical;
always @ (posedge clk) begin
    if(unit_cnt == 256 || unit_cnt == 512 || unit_cnt ==712 || unit_cnt ==1024) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                prediction_dc[m][n] <= 8'd0;
            end
        end
    end
    else if( unit_cnt>0)
        prediction_dc[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] <=  dc ;
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_dc <= 32'd0;
    else if(state_c == WAIT_16CYCLE && unit_cnt>0) begin
        if(block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] > dc)
            sad_dc <= sad_dc + block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] - dc;
        else 
            sad_dc <= sad_dc - block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] + dc;
    end
    else sad_dc <= 0;
end

always @ (posedge clk) begin
    if(unit_cnt == 256 || unit_cnt == 512 || unit_cnt ==712 || unit_cnt ==1024) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                prediction_horizontal[m][n] <= 8'd0;
            end
        end
    end
    else begin //no
        prediction_horizontal[((unit_cnt)%16)/4][((unit_cnt)%16)%4] <= left_edge[((unit_cnt)%16)/4];
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_horizontal <= 32'd0;
    else if(state_c == WAIT_16CYCLE && unit_cnt>0) begin
        if(block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] > prediction_horizontal[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4])
            sad_horizontal <= sad_horizontal + block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] - prediction_horizontal[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4];
        else 
            sad_horizontal <= sad_horizontal - block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] + prediction_horizontal[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4];
    end
    else sad_horizontal <= 0;
end

always @ (posedge clk) begin
    if(unit_cnt == 256 || unit_cnt == 512 || unit_cnt ==712 || unit_cnt ==1024) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                prediction_vertical[m][n] <= 8'd0;
            end
        end
    end
    else begin //no
        if(blank_cnt == 1 || blank_cnt == 3)
            prediction_vertical[((unit_cnt)%16)/4][((unit_cnt)%16)%4] <= top_edge[((unit_cnt)%16)%4 + 16];
        else
            prediction_vertical[((unit_cnt)%16)/4][((unit_cnt)%16)%4] <= top_edge[((unit_cnt)%16)%4];
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) sad_vertical <= 32'd0;
    else if(state_c == WAIT_16CYCLE && unit_cnt>0) begin
        if(block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] > prediction_vertical[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4])
            sad_vertical <= sad_vertical + block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] - prediction_vertical[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4];
        else 
            sad_vertical <= sad_vertical - block_data[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] + prediction_vertical[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4];
    end
    else sad_vertical <= 0;
end

always @ (posedge clk ) begin
    if( state_c == WAIT_16CYCLE ) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                Residual[m][n] <= 8'd0;
            end
        end
    end
    else if(state_c == CALU_RESIDUAL) begin
        case(prediction_state)
            DC     : 
            for(m=0; m<4; m=m+1) begin
                for(n=0; n<4; n=n+1) begin
                    Residual[m][n] <= block_data[m][n] - dc ;
                end
            end
            DC_V   : begin
                if (sad_dc <= sad_vertical) 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - dc ;
                        end
                    end
                else 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - prediction_vertical[m][n] ;
                        end
                    end
            end
            DC_H   : begin
                if (sad_dc <= sad_horizontal) 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - dc ;
                        end
                    end
                else 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - prediction_horizontal[m][n] ;
                        end
                    end
            end
            DC_H_V :  begin
                if (sad_dc <= sad_horizontal && sad_dc <= sad_vertical) 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - dc ;
                        end
                    end
                else if (sad_horizontal < sad_dc && sad_horizontal <= sad_vertical) 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - prediction_horizontal[m][n] ;
                        end
                    end
                else 
                    for(m=0; m<4; m=m+1) begin
                        for(n=0; n<4; n=n+1) begin
                            Residual[m][n] <= block_data[m][n] - prediction_vertical[m][n] ;
                        end
                    end
            end
            default : Residual[((unit_cnt-1)%16)/4][((unit_cnt-1)%16)%4] <= 8'd0;
        endcase
    end
    else if(state_c == TRANSFORM) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                Residual[m][n] <= transform_temp[m][n];
            end
        end
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


//==================================================================
// Get Date From SRAM
//==================================================================

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(m=0; m<4; m=m+1) begin
            for(n=0; n<4; n=n+1) begin
                block_data[m][n] <= 8'd0;
            end
        end
    end
    else if(state_c == WAIT_16CYCLE) begin
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



module transform #( //no
    parameter WIDTH = 9,
    localparam OUTW = WIDTH + 5
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

    assign W00 = X00 + X10 + X20 + X30;
    assign W01 = X01 + X11 + X21 + X31;
    assign W02 = X02 + X12 + X22 + X32;
    assign W03 = X03 + X13 + X23 + X33;

    assign W10 = X00 + X10 - X20 - X30;
    assign W11 = X01 + X11 - X21 - X31;
    assign W12 = X02 + X12 - X22 - X32;
    assign W13 = X03 + X13 - X23 - X33;

    assign W20 = X00 - X10 - X20 + X30;
    assign W21 = X01 - X11 - X21 + X31;
    assign W22 = X02 - X12 - X22 + X32;
    assign W23 = X03 - X13 - X23 + X33;

    assign W30 = X00 - X10 + X20 - X30;
    assign W31 = X01 - X11 + X21 - X31;
    assign W32 = X02 - X12 + X22 - X32;
    assign W33 = X03 - X13 + X23 - X33;

endmodule
