module MPCA(
    // Input signals
    input [127:0] packets,
    input  [11:0] channel_load,
    input   [8:0] channel_capacity,
    input  [63:0] KEY,
    // Output signals
    output reg [15:0] grant_channel
);

//================================================================
//    Wire & Registers 
//================================================================
wire [15:0] o_pack [0:7];

wire req_valid [0:7];
wire mode [0:7];
wire [1:0] qos [0:7];
wire [3:0] pkt_len [0:7];
wire [1:0] congestion [0:7];
wire [1:0] prefer_ch [0:7];
wire [2:0] src_hint [0:7];
wire signed [7:0] priority_score[0:7];
wire mask_success [0:7];

wire signed [13:0] packet_after_sorting[0:7];//maybe
wire signed [8:0] packet_before_sorting[0:7];//maybe
wire [3:0] ch_load [0:2];
wire [2:0] ch_cap [0:2];
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

//================================================================
//    DESIGN
//================================================================

assign {ch_load[2] , ch_load[1] ,ch_load[0] } = channel_load;
assign {ch_cap[2] , ch_cap[1] , ch_cap[0] } = channel_capacity;

Decrypt D76 (.x4(packets[111:96])  , .y4(packets[127:112]), .l0(KEY[31:16]) , .l1(KEY[47:32]) ,
            .l2(KEY[63:48]) , .k0(KEY[15:0])   , .x0(o_pack[6])  , .y0(o_pack[7]) );
Decrypt D54 (.x4(packets[79:64])  ,  .y4(packets[95:80])  , .l0(KEY[31:16]) , .l1(KEY[47:32]) ,
            .l2(KEY[63:48]) , .k0(KEY[15:0])   , .x0(o_pack[4])  , .y0(o_pack[5]) );
Decrypt D32 (.x4(packets[47:32])  ,  .y4(packets[63:48])  , .l0(KEY[31:16]) , .l1(KEY[47:32]) ,
            .l2(KEY[63:48]) , .k0(KEY[15:0])   , .x0(o_pack[2])  , .y0(o_pack[3]) );
Decrypt D10 (.x4(packets[15:0])   ,  .y4(packets[31:16])  , .l0(KEY[31:16]) , .l1(KEY[47:32]) ,
            .l2(KEY[63:48]) , .k0(KEY[15:0])   , .x0(o_pack[0])  , .y0(o_pack[1]) );

assign {req_valid[0] , qos[0], pkt_len[0] , congestion[0] , prefer_ch[0] ,src_hint[0] ,mode[0]} = o_pack[0][15:1];
assign {req_valid[1] , qos[1], pkt_len[1] , congestion[1] , prefer_ch[1] ,src_hint[1] ,mode[1]} = o_pack[1][15:1];
assign {req_valid[2] , qos[2], pkt_len[2] , congestion[2] , prefer_ch[2] ,src_hint[2] ,mode[2]} = o_pack[2][15:1];
assign {req_valid[3] , qos[3], pkt_len[3] , congestion[3] , prefer_ch[3] ,src_hint[3] ,mode[3]} = o_pack[3][15:1];
assign {req_valid[4] , qos[4], pkt_len[4] , congestion[4] , prefer_ch[4] ,src_hint[4] ,mode[4]} = o_pack[4][15:1];
assign {req_valid[5] , qos[5], pkt_len[5] , congestion[5] , prefer_ch[5] ,src_hint[5] ,mode[5]} = o_pack[5][15:1];
assign {req_valid[6] , qos[6], pkt_len[6] , congestion[6] , prefer_ch[6] ,src_hint[6] ,mode[6]} = o_pack[6][15:1];
assign {req_valid[7] , qos[7], pkt_len[7] , congestion[7] , prefer_ch[7] ,src_hint[7] ,mode[7]} = o_pack[7][15:1];

Priority_LUT pack7 (.mode(mode[7]), .qos(qos[7]) , .congestion(congestion[7]) , .src_hint(src_hint[7]) , .pkt_len(pkt_len[7]) , .priority_score(priority_score[7]));
Priority_LUT pack6 (.mode(mode[6]), .qos(qos[6]) , .congestion(congestion[6]) , .src_hint(src_hint[6]) , .pkt_len(pkt_len[6]) , .priority_score(priority_score[6]));
Priority_LUT pack5 (.mode(mode[5]), .qos(qos[5]) , .congestion(congestion[5]) , .src_hint(src_hint[5]) , .pkt_len(pkt_len[5]) , .priority_score(priority_score[5]));
Priority_LUT pack4 (.mode(mode[4]), .qos(qos[4]) , .congestion(congestion[4]) , .src_hint(src_hint[4]) , .pkt_len(pkt_len[4]) , .priority_score(priority_score[4]));
Priority_LUT pack3 (.mode(mode[3]), .qos(qos[3]) , .congestion(congestion[3]) , .src_hint(src_hint[3]) , .pkt_len(pkt_len[3]) , .priority_score(priority_score[3]));
Priority_LUT pack2 (.mode(mode[2]), .qos(qos[2]) , .congestion(congestion[2]) , .src_hint(src_hint[2]) , .pkt_len(pkt_len[2]) , .priority_score(priority_score[2]));
Priority_LUT pack1 (.mode(mode[1]), .qos(qos[1]) , .congestion(congestion[1]) , .src_hint(src_hint[1]) , .pkt_len(pkt_len[1]) , .priority_score(priority_score[1]));
Priority_LUT pack0 (.mode(mode[0]), .qos(qos[0]) , .congestion(congestion[0]) , .src_hint(src_hint[0]) , .pkt_len(pkt_len[0]) , .priority_score(priority_score[0]));

assign packet_after_sorting[0] = {priority_score[0] ,3'd0, req_valid[0] , prefer_ch[0] };
assign packet_after_sorting[1] = {priority_score[1] ,3'd1, req_valid[1] , prefer_ch[1] };
assign packet_after_sorting[2] = {priority_score[2] ,3'd2, req_valid[2] , prefer_ch[2] };
assign packet_after_sorting[3] = {priority_score[3] ,3'd3, req_valid[3] , prefer_ch[3] };
assign packet_after_sorting[4] = {priority_score[4] ,3'd4, req_valid[4] , prefer_ch[4] };
assign packet_after_sorting[5] = {priority_score[5] ,3'd5, req_valid[5] , prefer_ch[5] };
assign packet_after_sorting[6] = {priority_score[6] ,3'd6, req_valid[6] , prefer_ch[6] };
assign packet_after_sorting[7] = {priority_score[7] ,3'd7, req_valid[7] , prefer_ch[7] };

MergeSort_8 packetsort(
    .in1(packet_after_sorting[0]) ,.in2(packet_after_sorting[1]) , .in3(packet_after_sorting[2]) ,
    .in4(packet_after_sorting[3]) ,.in5(packet_after_sorting[4]) , .in6(packet_after_sorting[5]) ,
    .in7(packet_after_sorting[6]), .in8(packet_after_sorting[7]),
    .out1(packet_before_sorting[0]),.out2(packet_before_sorting[1]),.out3(packet_before_sorting[2]),
    .out4(packet_before_sorting[3]),.out5(packet_before_sorting[4]),.out6(packet_before_sorting[5]),
    .out7(packet_before_sorting[6]),.out8(packet_before_sorting[7])
);
wire [2:0] packetnum[0:7];
wire [1:0] pivot_state [1:8];
wire [15:0] allocations;

wire [2:0] ch0_usage [1:8]; 
wire [2:0] ch1_usage [1:8];
wire [2:0] ch2_usage [1:8];
wire       pivot_init [1:8];

assign packetnum[0] = packet_before_sorting[0][5:3];
assign packetnum[1] = packet_before_sorting[1][5:3];
assign packetnum[2] = packet_before_sorting[2][5:3];
assign packetnum[3] = packet_before_sorting[3][5:3];
assign packetnum[4] = packet_before_sorting[4][5:3];
assign packetnum[5] = packet_before_sorting[5][5:3];
assign packetnum[6] = packet_before_sorting[6][5:3];
assign packetnum[7] = packet_before_sorting[7][5:3];

Mask maskpack0 (
    .priority_score({packet_before_sorting[0][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[0][1:0]),
    .channel(allocations[1:0]),
    .src_hint(src_hint[packetnum[0]]),
    .channel_load(channel_load),
    .mask_success(mask_success[0])
);

Mask maskpack1 (
    .priority_score({packet_before_sorting[1][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[1][1:0]),
    .channel(allocations[3:2]),
    .src_hint(src_hint[packetnum[1]]),
    .channel_load(channel_load),
    .mask_success(mask_success[1])
);

Mask maskpack2 (
    .priority_score({packet_before_sorting[2][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[2][1:0]),
    .channel(allocations[5:4]),
    .src_hint(src_hint[packetnum[2]]),
    .channel_load(channel_load),
    .mask_success(mask_success[2])
);

Mask maskpack3 (
    .priority_score({packet_before_sorting[3][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[3][1:0]),
    .channel(allocations[7:6]),
    .src_hint(src_hint[packetnum[3]]),
    .channel_load(channel_load),
    .mask_success(mask_success[3])
);

Mask maskpack4 (
    .priority_score({packet_before_sorting[4][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[4][1:0]),
    .channel(allocations[9:8]),
    .src_hint(src_hint[packetnum[4]]),
    .channel_load(channel_load),
    .mask_success(mask_success[4])
);

Mask maskpack5 (
    .priority_score({packet_before_sorting[5][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[5][1:0]),
    .channel(allocations[11:10]),
    .src_hint(src_hint[packetnum[5]]),
    .channel_load(channel_load),
    .mask_success(mask_success[5])
);

Mask maskpack6 (
    .priority_score({packet_before_sorting[6][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[6][1:0]),
    .channel(allocations[13:12]),
    .src_hint(src_hint[packetnum[6]]),
    .channel_load(channel_load),
    .mask_success(mask_success[6])
);

Mask maskpack7 (
    .priority_score({packet_before_sorting[7][8:7],1'b0}),
    .prefer_ch(packet_before_sorting[7][1:0]),
    .channel(allocations[15:14]),
    .src_hint(src_hint[packetnum[7]]),
    .channel_load(channel_load),
    .mask_success(mask_success[7])
);
wire [2:0] capacity_full [0:7];

Packet_allocator alloc0 (
    .packet_in(packet_before_sorting[0][2:0]),
    .ch0_used(3'd0), .ch1_used(3'd0), .ch2_used(3'd0),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(2'd0), .pivot_initialized(1'b0), .capacity_full(3'b000),
    .allocation(allocations[1:0]),
    .ch0_used_next(ch0_usage[1]), .ch1_used_next(ch1_usage[1]), .ch2_used_next(ch2_usage[1]),
    .next_pivot(pivot_state[1]), .pivot_init_next(pivot_init[1]) ,.capacity_full_next(capacity_full[0])
);
Packet_allocator alloc1 (
    .packet_in(packet_before_sorting[1][2:0]),
    .ch0_used(ch0_usage[1]), .ch1_used(ch1_usage[1]), .ch2_used(ch2_usage[1]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[1]), .pivot_initialized(pivot_init[1]), .capacity_full(capacity_full[0]),
    .allocation(allocations[3:2]),
    .ch0_used_next(ch0_usage[2]), .ch1_used_next(ch1_usage[2]), .ch2_used_next(ch2_usage[2]),
    .next_pivot(pivot_state[2]), .pivot_init_next(pivot_init[2]) ,.capacity_full_next(capacity_full[1])
);

Packet_allocator alloc2 (
    .packet_in(packet_before_sorting[2][2:0]),
    .ch0_used(ch0_usage[2]), .ch1_used(ch1_usage[2]), .ch2_used(ch2_usage[2]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[2]), .pivot_initialized(pivot_init[2]), .capacity_full(capacity_full[1]),
    .allocation(allocations[5:4]),
    .ch0_used_next(ch0_usage[3]), .ch1_used_next(ch1_usage[3]), .ch2_used_next(ch2_usage[3]),
    .next_pivot(pivot_state[3]), .pivot_init_next(pivot_init[3]) ,.capacity_full_next(capacity_full[2])
); 

Packet_allocator alloc3 (
    .packet_in(packet_before_sorting[3][2:0]),
    .ch0_used(ch0_usage[3]), .ch1_used(ch1_usage[3]), .ch2_used(ch2_usage[3]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[3]), .pivot_initialized(pivot_init[3]), .capacity_full(capacity_full[2]),
    .allocation(allocations[7:6]),
    .ch0_used_next(ch0_usage[4]), .ch1_used_next(ch1_usage[4]), .ch2_used_next(ch2_usage[4]),
    .next_pivot(pivot_state[4]), .pivot_init_next(pivot_init[4]) ,.capacity_full_next(capacity_full[3])
);

Packet_allocator alloc4 (
    .packet_in(packet_before_sorting[4][2:0]),
    .ch0_used(ch0_usage[4]), .ch1_used(ch1_usage[4]), .ch2_used(ch2_usage[4]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[4]), .pivot_initialized(pivot_init[4]), .capacity_full(capacity_full[3]),
    .allocation(allocations[9:8]),
    .ch0_used_next(ch0_usage[5]), .ch1_used_next(ch1_usage[5]), .ch2_used_next(ch2_usage[5]),
    .next_pivot(pivot_state[5]), .pivot_init_next(pivot_init[5]) ,.capacity_full_next(capacity_full[4])
);

Packet_allocator alloc5 (
    .packet_in(packet_before_sorting[5][2:0]),
    .ch0_used(ch0_usage[5]), .ch1_used(ch1_usage[5]), .ch2_used(ch2_usage[5]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[5]), .pivot_initialized(pivot_init[5]), .capacity_full(capacity_full[4]),
    .allocation(allocations[11:10]),
    .ch0_used_next(ch0_usage[6]), .ch1_used_next(ch1_usage[6]), .ch2_used_next(ch2_usage[6]),
    .next_pivot(pivot_state[6]), .pivot_init_next(pivot_init[6]) ,.capacity_full_next(capacity_full[5])
);

Packet_allocator alloc6 (
    .packet_in(packet_before_sorting[6][2:0]),
    .ch0_used(ch0_usage[6]), .ch1_used(ch1_usage[6]), .ch2_used(ch2_usage[6]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[6]), .pivot_initialized(pivot_init[6]), .capacity_full(capacity_full[5]),
    .allocation(allocations[13:12]),
    .ch0_used_next(ch0_usage[7]), .ch1_used_next(ch1_usage[7]), .ch2_used_next(ch2_usage[7]),
    .next_pivot(pivot_state[7]), .pivot_init_next(pivot_init[7]) ,.capacity_full_next(capacity_full[6])
);

Packet_allocator alloc7 (
    .packet_in(packet_before_sorting[7][2:0]),
    .ch0_used(ch0_usage[7]), .ch1_used(ch1_usage[7]), .ch2_used(ch2_usage[7]),
    .ch0_capacity(ch_cap[0]), .ch1_capacity(ch_cap[1]), .ch2_capacity(ch_cap[2]),
    .current_pivot(pivot_state[7]), .pivot_initialized(pivot_init[7]), .capacity_full(capacity_full[6]),
    .allocation(allocations[15:14]),
    .ch0_used_next(ch0_usage[8]), .ch1_used_next(ch1_usage[8]), .ch2_used_next(ch2_usage[8]),
    .next_pivot(pivot_state[8]), .pivot_init_next(pivot_init[8]) , .capacity_full_next(capacity_full[7])
);

wire [4:0] channel_load_0 , channel_load_1 , channel_load_2 ;
reg  [4:0] other_avg;
reg  [4:0] largest_load;
reg  [1:0] largest_load_ch;

// assign capacity_full = { (ch0_usage[8] >= ch_cap[0]) , (ch1_usage[8]>= ch_cap[1]) ,(ch2_usage[8]>= ch_cap[2]) } ;

wire rebalance;
assign channel_load_0 = ch_load[0] + ch0_usage[8] ;
assign channel_load_1 = ch_load[1] + ch1_usage[8] ;
assign channel_load_2 = ch_load[2] + ch2_usage[8] ;

always @(*) begin
    if(channel_load_0 >= channel_load_1)
        if(channel_load_0 >= channel_load_2 ) begin
            largest_load_ch = 0;
        end
        else begin
            largest_load_ch = 2;
        end
    else
        if(channel_load_1 >= channel_load_2 ) begin
            largest_load_ch = 1;
        end
        else begin
            largest_load_ch = 2;
        end
end

assign rebalance = !(channel_load_1==channel_load_0 && channel_load_0 == channel_load_2) ;
//packet_before_sorting[0] has highest priority
reg [15:0] packetchannel ;

reg find;
reg [3:0] rebalance_channal_position;
always @(*) begin
    if(rebalance) begin
        case (1)
            ((allocations[15:14] == largest_load_ch)&& mask_success[7]) : begin rebalance_channal_position = 4'b0000; find=1; end
            ((allocations[13:12] == largest_load_ch)&& mask_success[6]) : begin rebalance_channal_position = 4'b0001; find=1; end
            ((allocations[11:10] == largest_load_ch)&& mask_success[5]) : begin rebalance_channal_position = 4'b0010; find=1; end
            ((allocations[9:8]   == largest_load_ch)&& mask_success[4]) : begin rebalance_channal_position = 4'b0011; find=1; end
            ((allocations[7:6]   == largest_load_ch)&& mask_success[3]) : begin rebalance_channal_position = 4'b0100; find=1; end
            ((allocations[5:4]   == largest_load_ch)&& mask_success[2]) : begin rebalance_channal_position = 4'b0101; find=1; end
            ((allocations[3:2]   == largest_load_ch)&& mask_success[1]) : begin rebalance_channal_position = 4'b0110; find=1; end
            ((allocations[1:0]   == largest_load_ch)&& mask_success[0]) : begin rebalance_channal_position = 4'b0111; find=1; end   
            default:  begin rebalance_channal_position = 4'b1000; find=0; end //need rebalance but can't find
        endcase
    end else begin
        find=0;
        rebalance_channal_position=4'b1000; 
    end
end

wire [1:0] rebalance_ch1 =  (channel_load_1>14 || capacity_full[7][1] || ch_cap[1]==0)? (channel_load_2>14 || capacity_full[7][2]|| ch_cap[2]==0)?2'b11 : 2'b10 : 2'b01; 
wire [1:0] rebalance_ch2 =  (channel_load_2>14 || capacity_full[7][2] || ch_cap[2]==0)? (channel_load_0>14 || capacity_full[7][0]|| ch_cap[0]==0)?2'b11 : 2'b00 : 2'b10;
wire [1:0] rebalance_ch0 =  (channel_load_0>14 || capacity_full[7][0] || ch_cap[0]==0)? (channel_load_1>14 || capacity_full[7][1]|| ch_cap[1]==0)?2'b11 : 2'b01 : 2'b00;


always @(*) begin
    if(find && ~rebalance_channal_position[3]) begin
        packetchannel = allocations;
        case (rebalance_channal_position)
            4'b0000: begin
                case (allocations[15:14])
                    2'b00:  packetchannel[15:14] = rebalance_ch1;
                    2'b01:  packetchannel[15:14] = rebalance_ch2;
                    2'b10:  packetchannel[15:14] = rebalance_ch0; 
                    default:  packetchannel[15:14]= 2'b11;
                endcase
            end
            4'b0001 : begin
                case (allocations[13:12])
                    2'b00:  packetchannel[13:12] = rebalance_ch1;
                    2'b01:  packetchannel[13:12] = rebalance_ch2;
                    2'b10:  packetchannel[13:12] = rebalance_ch0;
                    default:  packetchannel[13:12]= 2'b11;
                endcase
            end
            4'b0010 : begin
                case (allocations[11:10])
                    2'b00:  packetchannel[11:10] = rebalance_ch1; 
                    2'b01:  packetchannel[11:10] = rebalance_ch2;
                    2'b10:  packetchannel[11:10] = rebalance_ch0;
                    default:  packetchannel[11:10]= 2'b11;
                endcase
            end
            4'b0011 : begin
                case (allocations[9:8])
                    2'b00:  packetchannel[9:8] = rebalance_ch1;
                    2'b01:  packetchannel[9:8] = rebalance_ch2;
                    2'b10:  packetchannel[9:8] = rebalance_ch0;
                    default:  packetchannel[9:8]= 2'b11;
                endcase
            end
            4'b0100 : begin
                case (allocations[7:6])
                    2'b00:  packetchannel[7:6] = rebalance_ch1;
                    2'b01:  packetchannel[7:6] = rebalance_ch2;
                    2'b10:  packetchannel[7:6] = rebalance_ch0;
                    default:  packetchannel[7:6]= 2'b11;
                endcase
            end
            4'b0101 : begin
                case (allocations[5:4])
                    2'b00:  packetchannel[5:4] = rebalance_ch1;
                    2'b01:  packetchannel[5:4] = rebalance_ch2; 
                    2'b10:  packetchannel[5:4] = rebalance_ch0; 
                    default:  packetchannel[5:4]= 2'b11;
                endcase
            end
            4'b0110 : begin
                case (allocations[3:2])
                    2'b00:  packetchannel[3:2] = rebalance_ch1;
                    2'b01:  packetchannel[3:2] = rebalance_ch2; 
                    2'b10:  packetchannel[3:2] = rebalance_ch0; 
                    default:  packetchannel[3:2]= 2'b11;
                endcase
            end
            4'b0111 : begin
                case (allocations[1:0])
                    2'b00:  packetchannel[1:0] = rebalance_ch1;
                    2'b01:  packetchannel[1:0] = rebalance_ch2; 
                    2'b10:  packetchannel[1:0] = rebalance_ch0;
                    default:  packetchannel[1:0]= 2'b11;
                endcase
            end
            default: packetchannel = allocations;
        endcase
    end
    else begin
        packetchannel = allocations;
    end
end

always @(*) begin
    grant_channel = 16'b0;
    
    case (packetnum[0])
        3'd0 : grant_channel[1:0] = packetchannel[1:0];
        3'd1 : grant_channel[3:2] = packetchannel[1:0];
        3'd2 : grant_channel[5:4] = packetchannel[1:0];
        3'd3 : grant_channel[7:6] = packetchannel[1:0];
        3'd4 : grant_channel[9:8] = packetchannel[1:0];
        3'd5 : grant_channel[11:10] = packetchannel[1:0];
        3'd6 : grant_channel[13:12] = packetchannel[1:0];
        3'd7 : grant_channel[15:14] = packetchannel[1:0];
        default: ;
    endcase
    
    case (packetnum[1])
        3'd0 : grant_channel[1:0] = packetchannel[3:2];
        3'd1 : grant_channel[3:2] = packetchannel[3:2];
        3'd2 : grant_channel[5:4] = packetchannel[3:2];
        3'd3 : grant_channel[7:6] = packetchannel[3:2];
        3'd4 : grant_channel[9:8] = packetchannel[3:2];
        3'd5 : grant_channel[11:10] = packetchannel[3:2];
        3'd6 : grant_channel[13:12] = packetchannel[3:2];
        3'd7 : grant_channel[15:14] = packetchannel[3:2];
        default: ;
    endcase
    
    case (packetnum[2])
        3'd0 : grant_channel[1:0] = packetchannel[5:4];
        3'd1 : grant_channel[3:2] = packetchannel[5:4];
        3'd2 : grant_channel[5:4] = packetchannel[5:4];
        3'd3 : grant_channel[7:6] = packetchannel[5:4];
        3'd4 : grant_channel[9:8] = packetchannel[5:4];
        3'd5 : grant_channel[11:10] = packetchannel[5:4];
        3'd6 : grant_channel[13:12] = packetchannel[5:4];
        3'd7 : grant_channel[15:14] = packetchannel[5:4];
        default: ;
    endcase
    
    case (packetnum[3])
        3'd0 : grant_channel[1:0] = packetchannel[7:6];
        3'd1 : grant_channel[3:2] = packetchannel[7:6];
        3'd2 : grant_channel[5:4] = packetchannel[7:6];
        3'd3 : grant_channel[7:6] = packetchannel[7:6];
        3'd4 : grant_channel[9:8] = packetchannel[7:6];
        3'd5 : grant_channel[11:10] = packetchannel[7:6];
        3'd6 : grant_channel[13:12] = packetchannel[7:6];
        3'd7 : grant_channel[15:14] = packetchannel[7:6];
        default: ;
    endcase
    
    case (packetnum[4])
        3'd0 : grant_channel[1:0] = packetchannel[9:8];
        3'd1 : grant_channel[3:2] = packetchannel[9:8];
        3'd2 : grant_channel[5:4] = packetchannel[9:8];
        3'd3 : grant_channel[7:6] = packetchannel[9:8];
        3'd4 : grant_channel[9:8] = packetchannel[9:8];
        3'd5 : grant_channel[11:10] = packetchannel[9:8];
        3'd6 : grant_channel[13:12] = packetchannel[9:8];
        3'd7 : grant_channel[15:14] = packetchannel[9:8];
        default: ;
    endcase
    
    case (packetnum[5])
        3'd0 : grant_channel[1:0] = packetchannel[11:10];
        3'd1 : grant_channel[3:2] = packetchannel[11:10];
        3'd2 : grant_channel[5:4] = packetchannel[11:10];
        3'd3 : grant_channel[7:6] = packetchannel[11:10];
        3'd4 : grant_channel[9:8] = packetchannel[11:10];
        3'd5 : grant_channel[11:10] = packetchannel[11:10];
        3'd6 : grant_channel[13:12] = packetchannel[11:10];
        3'd7 : grant_channel[15:14] = packetchannel[11:10];
        default: ;
    endcase

    case (packetnum[6])
        3'd0 : grant_channel[1:0] = packetchannel[13:12];
        3'd1 : grant_channel[3:2] = packetchannel[13:12];
        3'd2 : grant_channel[5:4] = packetchannel[13:12];
        3'd3 : grant_channel[7:6] = packetchannel[13:12];
        3'd4 : grant_channel[9:8] = packetchannel[13:12];
        3'd5 : grant_channel[11:10] = packetchannel[13:12];
        3'd6 : grant_channel[13:12] = packetchannel[13:12];
        3'd7 : grant_channel[15:14] = packetchannel[13:12];
        default: ;
    endcase
    
    case (packetnum[7])
        3'd0 : grant_channel[1:0] = packetchannel[15:14];
        3'd1 : grant_channel[3:2] = packetchannel[15:14];
        3'd2 : grant_channel[5:4] = packetchannel[15:14];
        3'd3 : grant_channel[7:6] = packetchannel[15:14];
        3'd4 : grant_channel[9:8] = packetchannel[15:14];
        3'd5 : grant_channel[11:10] = packetchannel[15:14];
        3'd6 : grant_channel[13:12] = packetchannel[15:14];
        3'd7 : grant_channel[15:14] = packetchannel[15:14];
        default: ;
    endcase
end
endmodule

//================================================================
//    Decrypt module
//================================================================
module Decrypt(
    input [15:0] x4,y4,l0,l1,l2,k0,
    output wire [15:0] x0,y0
);
//calu K1 ~ K3
wire [15:0] k1,k2,k3;
wire [15:0] x3, x2, x1;
wire [15:0] x3_calu, x2_calu, x1_calu , x0_calu;
wire [15:0] y3, y2, y1;
wire [15:0] y3_xor, y2_xor, y1_xor , y0_xor;

assign k1 = { k0[6:0], k0[15:7]} + l0 ; 
assign k2 = ( { k1[6:0], k1[15:7]} + l1 ) ^ 1'h1;
assign k3 = ( { k2[6:0], k2[15:7]} + l2 ) ^ 2'h2;

assign x3 = { x3_calu[8:0] , x3_calu[15:9] } ;
assign x2 = { x2_calu[8:0] , x2_calu[15:9] } ;
assign x1 = { x1_calu[8:0] , x1_calu[15:9] } ;
assign x0 = { x0_calu[8:0] , x0_calu[15:9] } ;

//calu y3 ~ y0 
assign y3_xor =  y4 ^ x4 ;
assign y2_xor =  y3 ^ x3 ;
assign y1_xor =  y2 ^ x2 ;
assign y0_xor =  y1 ^ x1 ;

assign y3 = { y3_xor[1:0] , y3_xor[15:2]  } ; 
assign y2 = { y2_xor[1:0] , y2_xor[15:2]  } ; 
assign y1 = { y1_xor[1:0] , y1_xor[15:2]  } ; 
assign y0 = { y0_xor[1:0] , y0_xor[15:2]  } ; 

//calu x3~x1

assign x3_calu = ( x4 ^ k3 ) + ( (~y3) + 1'b1 ) ;
assign x2_calu = ( x3 ^ k2 ) + ( (~y2) + 1'b1 ) ;
assign x1_calu = ( x2 ^ k1 ) + ( (~y1) + 1'b1 ) ;
assign x0_calu = ( x1 ^ k0 ) + ( (~y0) + 1'b1 ) ;

endmodule
//================================================================
//    Priority module
//================================================================
module Priority_LUT (
    input mode,
    input [1:0] qos ,congestion,
    input [2:0] src_hint,
    input [3:0] pkt_len,
    output wire signed [7:0] priority_score //7bits
);

reg signed [4:0] qos_lut , congestion_lut;
reg signed [6:0] pkt_len_lut; //maybe
reg signed [4:0] src_hint_lut;
always @ (*) begin
    if(mode) begin
        case (qos)
            0 : qos_lut = -5'h8;
            1 : qos_lut = -5'h4;
            2 : qos_lut = -5'd16;
            default: qos_lut = -5'd12;
        endcase
    end
    else begin
      case (qos)
            0 : qos_lut = -5'h8;
            1 : qos_lut = -5'h4;
            2 : qos_lut = -5'd0;
            default: qos_lut = 5'h4;
        endcase
    end
end

always @(*) begin //maybe
    if(mode) begin
        case(pkt_len)
            4'd0  : pkt_len_lut = 7'd16;
            4'd1  : pkt_len_lut = 7'd14;
            4'd2  : pkt_len_lut = 7'd12;
            4'd3  : pkt_len_lut = 7'd10;
            4'd4  : pkt_len_lut = 7'd8;
            4'd5  : pkt_len_lut = 7'd6;
            4'd6  : pkt_len_lut = 7'd4;
            4'd7  : pkt_len_lut = 7'd2;
            4'd8  : pkt_len_lut = 7'd32;
            4'd9  : pkt_len_lut = 7'd30;
            4'd10 : pkt_len_lut = 7'd28;
            4'd11 : pkt_len_lut = 7'd26;
            4'd12 : pkt_len_lut = 7'd24;
            4'd13 : pkt_len_lut = 7'd22;
            4'd14 : pkt_len_lut = 7'd20;
            4'd15 : pkt_len_lut = 7'd18;
            default: pkt_len_lut = 0;
        endcase
    end
    else begin
        case(pkt_len)
            4'd0  : pkt_len_lut = 7'd16;
            4'd1  : pkt_len_lut = 7'd14;
            4'd2  : pkt_len_lut = 7'd12;
            4'd3  : pkt_len_lut = 7'd10;
            4'd4  : pkt_len_lut = 7'd8;
            4'd5  : pkt_len_lut = 7'd6;
            4'd6  : pkt_len_lut = 7'd4;
            4'd7  : pkt_len_lut = 7'd2;
            4'd8  : pkt_len_lut = 7'd0;
            4'd9  : pkt_len_lut = -7'd2;
            4'd10 : pkt_len_lut = -7'd4;
            4'd11 : pkt_len_lut = -7'd6;
            4'd12 : pkt_len_lut = -7'd8;
            4'd13 : pkt_len_lut = -7'd10;
            4'd14 : pkt_len_lut = -7'd12;
            4'd15 : pkt_len_lut = -7'd14;
            default: pkt_len_lut = 0;
        endcase
    end
end

always @(*) begin
    if (mode) begin
        case (congestion)
            2'd0: congestion_lut = 5'd3; 
            2'd1: congestion_lut = 5'd0;
            2'd2: congestion_lut = 5'd9;
            2'd3: congestion_lut = 5'd6;
            default: congestion_lut = 5'd0;
        endcase
    end
    else begin
        case (congestion)
            2'd0: congestion_lut = 5'd3;
            2'd1: congestion_lut = 5'd0;
            2'd2: congestion_lut = -5'd3; 
            2'd3: congestion_lut = -5'd6; 
            default: congestion_lut = 5'd0;
        endcase
    end
end

always @(*) begin
    if (~mode) begin
        case (src_hint)
            3'd0: src_hint_lut = -5'd4; 
            3'd1: src_hint_lut = -5'd3;
            3'd2: src_hint_lut = -5'd2; 
            3'd3: src_hint_lut = -5'd1; 
            3'd4: src_hint_lut =  5'd0; 
            3'd5: src_hint_lut =  5'd1;
            3'd6: src_hint_lut =  5'd2; 
            3'd7: src_hint_lut =  5'd3;
            default: src_hint_lut = 5'd0;
        endcase
    end
    else begin
        case (src_hint)
            3'd0: src_hint_lut = -5'd4; 
            3'd1: src_hint_lut = -5'd3; 
            3'd2: src_hint_lut = -5'd2; 
            3'd3: src_hint_lut = -5'd1; 
            3'd4: src_hint_lut = -5'd8; 
            3'd5: src_hint_lut = -5'd7; 
            3'd6: src_hint_lut = -5'd6; 
            3'd7: src_hint_lut = -5'd5; 
            default: src_hint_lut = 5'd0;
        endcase
    end
end
assign priority_score = qos_lut + congestion_lut + pkt_len_lut + src_hint_lut ;
endmodule
//================================================================
//   Mask  & Threshold compare 
//================================================================
module Mask(
    input [2:0] priority_score,
    input [1:0] prefer_ch ,
    input [1:0] channel,
    input [2:0] src_hint,
    input [11:0] channel_load,
    output mask_success
);
reg  [3:0] mask_score;
reg  [3:0] Threshold ;
wire [2:0] src_hint_lut;
reg  [3:0] channel_load_selection;
wire  [4:0] mask;

assign src_hint_lut = { src_hint[2] , ~src_hint[1:0]} ; 
always @(*) begin
    case (channel)
        0:channel_load_selection = channel_load[3 :0];
        1:channel_load_selection = channel_load[7 :4];
        2:channel_load_selection = channel_load[11:8];
        default: channel_load_selection = 0;
    endcase
end

assign mask = priority_score + prefer_ch + src_hint_lut + channel_load_selection ;

always @(*) begin
    case (mask)
        10,20,30:  mask_score = 4'h0;
        11,21,31:  mask_score = 4'h1;
        12,22   :  mask_score = 4'h2;
        13,23   :  mask_score = 4'h3;
        14,24   :  mask_score = 4'h4;
        15,25   :  mask_score = 4'h5;
        16,26   :  mask_score = 4'h6;
        17,27   :  mask_score = 4'h7;
        18,28   :  mask_score = 4'h8;
        19,29   :  mask_score = 4'h9;
        default : mask_score = mask;
    endcase
end

always @(*) begin
    case (channel_load_selection)
        4'd0  , 4'd1  , 4'd2  : Threshold = 4'd7 ;
        4'd3  , 4'd4  , 4'd5  : Threshold = 4'd8 ;
        4'd6  , 4'd7  , 4'd8  : Threshold = 4'd9 ;
        4'd9  , 4'd10 , 4'd11 : Threshold = 4'd10;
        4'd12 , 4'd13 , 4'd14 : Threshold = 4'd11;
        4'd15                 : Threshold = 4'd12;
        default               : Threshold = 4'd0 ;
    endcase
end

assign mask_success = (Threshold > mask_score);

endmodule
//================================================================
//   Allocator
//================================================================
module Packet_allocator (
    input  [2:0] packet_in,
    input  [2:0] ch0_used, ch1_used, ch2_used,
    input  [2:0] ch0_capacity, ch1_capacity, ch2_capacity,
    input  [2:0] capacity_full,
    input  [1:0] current_pivot,
    input        pivot_initialized,

    output reg  [1:0] allocation,
    output reg  [2:0] capacity_full_next,
    output reg  [2:0] ch0_used_next,
    output reg  [2:0] ch1_used_next,
    output reg  [2:0] ch2_used_next,
    output reg  [1:0] next_pivot,
    output reg        pivot_init_next
);

    wire req_valid = packet_in[2];
    wire [1:0] prefer_ch = packet_in[1:0];

    // Pre-compute
    wire ch0_not_full = ~(capacity_full[0] || ch0_capacity == 0);
    wire ch1_not_full = ~(capacity_full[1] || ch1_capacity == 0);
    wire ch2_not_full = ~(capacity_full[2] || ch2_capacity == 0);
    wire [2:0] ch_available = {ch2_not_full, ch1_not_full, ch0_not_full};

    wire prefer_available = (prefer_ch == 2'b00) ? ch0_not_full :
                            (prefer_ch == 2'b01) ? ch1_not_full : 
                            (prefer_ch == 2'b10) ? ch2_not_full : 1'b0;

    wire [2:0] ch0_used_inc = ch0_used + 1'b1;
    wire [2:0] ch1_used_inc = ch1_used + 1'b1;
    wire [2:0] ch2_used_inc = ch2_used + 1'b1;

    wire [1:0] fallback_pivot = pivot_initialized ? current_pivot : prefer_ch;
    
    wire [5:0] expanded_avail = {ch_available, ch_available}; //{ch2, ch1, ch0, ch2, ch1, ch0} // 6-bit for easy rotation
    wire [2:0] rotated_avail = (fallback_pivot == 2'b00) ? expanded_avail[2:0] :
                               (fallback_pivot == 2'b01) ? expanded_avail[3:1] :
                                                           expanded_avail[4:2] ;
     
    // Priority encode
    wire [1:0] rotated_alloc = rotated_avail[0] ? 2'b00 :
                               rotated_avail[1] ? 2'b01 :
                               rotated_avail[2] ? 2'b10 : 2'b11;
    
    // Rotate back to get actual channel
    wire [1:0] fallback_alloc = (fallback_pivot == 2'b00) ? rotated_alloc :
                                (fallback_pivot == 2'b01) ? ((rotated_alloc == 2'b00) ? 2'b01 :
                                                             (rotated_alloc == 2'b01) ? 2'b10 :
                                                             (rotated_alloc == 2'b10) ? 2'b00 : 2'b11) :
                                                            ((rotated_alloc == 2'b00) ? 2'b10 :
                                                             (rotated_alloc == 2'b01) ? 2'b00 :
                                                             (rotated_alloc == 2'b10) ? 2'b01 : 2'b11);

    wire fallback_success = (fallback_alloc != 2'b11);
    wire [1:0] pivot_for_update = pivot_initialized ? current_pivot : prefer_ch;
    wire [1:0] pivot_updated = fallback_success ? 
                               ((pivot_for_update == 2'b10) ? 2'b00 : pivot_for_update + 1'b1) :
                               ((pivot_for_update == 2'b00) ? 2'b10 :
                                (pivot_for_update == 2'b01) ? 2'b00 : 2'b01);

    wire use_fallback = ~prefer_available;
    wire [1:0] final_alloc = use_fallback ? fallback_alloc : prefer_ch;

    always @(*) begin
        // Default
        allocation = 2'b11;
        ch0_used_next = ch0_used;
        ch1_used_next = ch1_used;  
        ch2_used_next = ch2_used;
        capacity_full_next = capacity_full;
        next_pivot = current_pivot;
        pivot_init_next = pivot_initialized;

        if (req_valid && prefer_ch <= 2'b10) begin
            allocation = final_alloc;
            if (use_fallback) begin
                pivot_init_next = 1'b1;
                next_pivot = pivot_updated;
                capacity_full_next[prefer_ch] = 1'b1;
            end
            
            if (final_alloc != 2'b11) begin
                case (final_alloc)
                    2'b00: begin
                        ch0_used_next = ch0_used_inc;
                        capacity_full_next[0] = (use_fallback) ? (ch0_capacity <= ch0_used_inc) :
                                                                 (ch0_capacity == ch0_used_inc);
                    end
                    2'b01: begin
                        ch1_used_next = ch1_used_inc;
                        capacity_full_next[1] = (use_fallback) ? (ch1_capacity <= ch1_used_inc) :
                                                                 (ch1_capacity == ch1_used_inc);
                    end
                    2'b10: begin
                        ch2_used_next = ch2_used_inc;
                        capacity_full_next[2] = (use_fallback) ? (ch2_capacity <= ch2_used_inc) :
                                                                 (ch2_capacity == ch2_used_inc);
                    end
                endcase
            end
        end
    end
endmodule
//================================================================
//    Sorting
//================================================================
// [priority ,req_valid , prefer_ch] 

module compare2 #(
    parameter OUT1_WIDTH = 14,  
    parameter OUT2_WIDTH = 14 
)(
    input signed [13:0] in1, in2,
    output reg signed [OUT1_WIDTH-1:0] out1,
    output reg signed [OUT2_WIDTH-1:0] out2
);

wire signed [7:0] priority_score1;
wire signed [7:0] priority_score2;
assign priority_score1 = in1[13:6];
assign priority_score2 = in2[13:6];

always @(*) begin
    if (priority_score1 > priority_score2) begin
        out1 = in1[OUT1_WIDTH-1:0]; 
        out2 = in2[OUT2_WIDTH-1:0]; 
    end
    else if (priority_score1 < priority_score2) begin
        out1 = in2[OUT1_WIDTH-1:0];
        out2 = in1[OUT2_WIDTH-1:0];
    end
    else begin
        if (in1[5:3] < in2[5:3]) begin
            out1 = in1[OUT1_WIDTH-1:0];
            out2 = in2[OUT2_WIDTH-1:0]; 
        end
        else begin
            out1 = in2[OUT1_WIDTH-1:0];
            out2 = in1[OUT2_WIDTH-1:0]; 
        end
    end
end
endmodule

module MergeSort_8 (
    input signed [13:0] in1,in2,in3,in4,in5,in6,in7,in8,
    output wire signed [8:0] out1,out2,out3,out4,out5,out6,out7,out8
);

wire signed [13:0] First1,First2,First3,First4,First5,First6,First7,First8;
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_1 (.in1(in1), .in2(in2), .out1(First1), .out2(First2));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_2 (.in1(in3), .in2(in4), .out1(First3), .out2(First4));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_3 (.in1(in5), .in2(in6), .out1(First5), .out2(First6));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_4 (.in1(in7), .in2(in8), .out1(First7), .out2(First8));

wire signed [13:0] Second1,Second2,Second3,Second4,Second5,Second6,Second7,Second8;
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_5 (.in1(First2), .in2(First6), .out1(Second1), .out2(Second2));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_6 (.in1(First1), .in2(First5), .out1(Second3), .out2(Second4));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_7 (.in1(First4), .in2(First8), .out1(Second7), .out2(Second8));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_8 (.in1(First3), .in2(First7), .out1(Second5), .out2(Second6));

wire signed [8:0] Third1, Third8; 
wire signed [13:0] Third2,Third3,Third4,Third5,Third6,Third7;
compare2 #(.OUT1_WIDTH(9), .OUT2_WIDTH(14))  COM_9  (.in1(Second3), .in2(Second5), .out1(Third1), .out2(Third2));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_10 (.in1(Second1), .in2(Second7), .out1(Third3), .out2(Third4));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_11 (.in1(Second4), .in2(Second6), .out1(Third5), .out2(Third6));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(9))  COM_12 (.in1(Second2), .in2(Second8), .out1(Third7), .out2(Third8));

wire signed [13:0] Forth1,Forth2,Forth3,Forth4;
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_13 (.in1(Third3), .in2(Third5), .out1(Forth1), .out2(Forth2));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_14 (.in1(Third4), .in2(Third6), .out1(Forth3), .out2(Forth4));

wire signed [13:0] Fifth1,Fifth2,Fifth3,Fifth4;
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_15 (.in1(Third7), .in2(Forth3), .out1(Fifth1), .out2(Fifth2));
compare2 #(.OUT1_WIDTH(14), .OUT2_WIDTH(14)) COM_16 (.in1(Third2), .in2(Forth2), .out1(Fifth3), .out2(Fifth4));

wire signed [8:0] Sixth1,Sixth2,Sixth3,Sixth4,Sixth5,Sixth6;

compare2 #(.OUT1_WIDTH(9), .OUT2_WIDTH(9)) COM_17 (.in1(Fifth1), .in2(Fifth4), .out1(Sixth1), .out2(Sixth2));
compare2 #(.OUT1_WIDTH(9), .OUT2_WIDTH(9)) COM_18 (.in1(Fifth3), .in2(Forth1), .out1(Sixth3), .out2(Sixth4));
compare2 #(.OUT1_WIDTH(9), .OUT2_WIDTH(9)) COM_19 (.in1(Fifth2), .in2(Forth4), .out1(Sixth5), .out2(Sixth6));

assign out4 = Sixth1;
assign out5 = Sixth2;
assign out2 = Sixth3;
assign out3 = Sixth4;
assign out6 = Sixth5;
assign out7 = Sixth6;
assign out1 = Third1;  
assign out8 = Third8;  

endmodule