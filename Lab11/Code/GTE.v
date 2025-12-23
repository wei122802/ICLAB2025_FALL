//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   ICLAB 2025 Fall 
// Lab11 Exercise : Geometric Transform Engine (GTE)
//      File Name : GTE.v
//    Module Name : GTE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module GTE(
    // input signals
    clk,
    rst_n,
	
    in_valid_data,
	data,
	
    in_valid_cmd,
    cmd,    
	
    // output signals
    busy
);

input              clk;
input              rst_n;

input              in_valid_data;
input       [7:0]  data;

input              in_valid_cmd;
input      [17:0]  cmd;

output reg         busy;

//==================================================================
// parameter & integer
//==================================================================
integer row,col, row_1,col_1;
typedef enum logic [2:0] { IDLE = 'd0,  INPUT = 'd1,  WAIT_IN ='d2  , CALU = 'd3,  WAIT_OUT = 'd4 , OUT = 'd5  } FSM_state;
//==================================================================
// reg & wire
//==================================================================
reg [17:0]cmd_reg;
reg [7:0] data_reg;


FSM_state current_state, next_state;

reg [31:0] mem6_dout_reg, mem7_dout_reg;
reg [15:0] mem4_dout_reg, mem5_dout_reg;
reg  [7:0] mem0_dout_reg, mem1_dout_reg, mem2_dout_reg, mem3_dout_reg;

wire [1:0] op;
wire [1:0] func;
wire [6:0] ms;
wire [6:0] md;
reg  [7:0] new_maps [0:15] [0:15];

// -----------------------------------------------------
// MEM
// -----------------------------------------------------

// MEM_0, MEM_1, MEM_2, MEM_3: 8-bit width, 4096 depth
wire        mem0_web, mem1_web, mem2_web, mem3_web;
wire [11:0] mem0_addr, mem1_addr, mem2_addr, mem3_addr;
wire  [7:0] mem0_din, mem1_din, mem2_din, mem3_din;
wire  [7:0] mem0_dout, mem1_dout, mem2_dout, mem3_dout;

// MEM_4, MEM_5: 16-bit width, 2048 depth
wire        mem4_web, mem5_web;
wire [10:0] mem4_addr, mem5_addr;
wire [15:0] mem4_din, mem5_din;
wire [15:0] mem4_dout, mem5_dout;

// MEM_6, MEM_7: 32-bit width, 1024 depth
wire        mem6_web, mem7_web;
wire  [9:0] mem6_addr, mem7_addr;
wire [31:0] mem6_din, mem7_din;
wire [31:0] mem6_dout, mem7_dout;

//==================================================================
// input register
//==================================================================
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)
		cmd_reg <= 18'd0;
	else if (in_valid_cmd)
		cmd_reg <= cmd;
	else
		cmd_reg <= cmd_reg;
end

assign op   = cmd_reg[17:16];
assign func = cmd_reg[15:14];
assign ms   = cmd_reg[13:7];
assign md   = cmd_reg[6:0];
//==================================================================
// MARK:counter
//==================================================================
reg [15:0] input_cnt;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		input_cnt <= 15'd0;
	else if (current_state == INPUT)
		input_cnt <= input_cnt + 15'd1;
	else
		input_cnt <= 15'd0;
end

reg [8:0] calu_cnt;
reg [8:0] sram_out_cnt;
reg [8:0] sram_cnt_pipe;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) 
		sram_cnt_pipe <= 8'd0;
	else 
		sram_cnt_pipe <= sram_out_cnt;
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)
		sram_out_cnt <= 8'd0;
	else if (current_state == WAIT_OUT)
		sram_out_cnt <= sram_out_cnt + 8'd1;
	else
		sram_out_cnt <= 8'd0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		calu_cnt <= 9'd0;
	else if (current_state == WAIT_IN)
		calu_cnt <= calu_cnt + 9'd1;
	else
		calu_cnt <= 9'd0;
end

wire calu_finish;
wire out_finish ; 
wire done_img0_63 , done_img64_95 , done_img96_127 ;
assign done_img0_63   = ((calu_cnt == 9'd257) &&(ms<64)) ;
assign done_img64_95  = ((calu_cnt == 8'd129) &&( (ms>=64) && (ms<96) )) ;
assign done_img96_127 = ((calu_cnt == 8'd65)  &&( (ms>=96) && (ms<128) )) ;

wire out_img0_63 , out_img64_95 , out_img96_127 ;
assign out_img0_63   = ((sram_out_cnt == 9'd256) &&(md<64)) ;
assign out_img64_95  = ((sram_out_cnt == 8'd128) &&( (md>=64) && (md<96) )) ;
assign out_img96_127 = ((sram_out_cnt == 8'd64)  &&( (md>=96) && (md<128) )) ;
assign out_finish = (out_img0_63 || out_img64_95 || out_img96_127) ;

assign calu_finish = (done_img0_63 || done_img64_95 || done_img96_127) ;
//==================================================================
// MARK:FSM
//==================================================================
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		current_state <= IDLE;
	else
		current_state <= next_state;
end

always @(*) begin
	case (current_state) // Average Latency: 364.196444 cycles
		IDLE 	:  next_state = (in_valid_data) ? INPUT : (in_valid_cmd)? WAIT_IN :  IDLE;
		INPUT	:  next_state = (in_valid_cmd)  ? WAIT_IN : INPUT;
		WAIT_IN :  next_state = (calu_finish) ? CALU : WAIT_IN;
		CALU 	:  next_state =  WAIT_OUT;
		WAIT_OUT:  next_state =  (out_finish) ?OUT : WAIT_OUT ;
		OUT  	:  next_state =  IDLE;
		default:  next_state = IDLE;
	endcase
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		busy <= 1'b1;
	else if (current_state  == OUT)
		busy <= 1'b0;
	else
		busy <= 1'b1;
end

//==================================================================
// New Input Maps
//==================================================================
//MARK:IN Pixel
reg [7:0] pixel , pixel_1 , pixel_2 , pixel_3 ;

always @(*) begin
	case(1)
		(ms< 16) : pixel = mem0_dout_reg;
		(ms< 32) : pixel = mem1_dout_reg;
		(ms< 48) : pixel = mem2_dout_reg;
		(ms< 64) : pixel = mem3_dout_reg;
		(ms< 80) : pixel = mem4_dout_reg[7:0];
		(ms< 96) : pixel = mem5_dout_reg[7:0];
		(ms<112) : pixel = mem6_dout_reg[7:0];
		(ms<128) : pixel = mem7_dout_reg[7:0];
		default  : pixel = 8'd0;
	endcase
end

always @(*) begin
	case(1)
		(ms< 16) : pixel_1 = 0;
		(ms< 32) : pixel_1 = 0;
		(ms< 48) : pixel_1 = 0;
		(ms< 64) : pixel_1 = 0;
		(ms< 80) : pixel_1 = mem4_dout_reg[15:8];
		(ms< 96) : pixel_1 = mem5_dout_reg[15:8];
		(ms<112) : pixel_1 = mem6_dout_reg[15:8];
		(ms<128) : pixel_1 = mem7_dout_reg[15:8];
		default  : pixel_1 = 8'd0;
	endcase
end

always @(*) begin
	case(1)
		(ms< 16) : pixel_2 = 0;
		(ms< 32) : pixel_2 = 0;
		(ms< 48) : pixel_2 = 0;
		(ms< 64) : pixel_2 = 0;
		(ms< 80) : pixel_2 = 0;
		(ms< 96) : pixel_2 = 0;
		(ms<112) : pixel_2 = mem6_dout_reg[23:16];
		(ms<128) : pixel_2 = mem7_dout_reg[23:16];
		default  : pixel_2 = 8'd0;
	endcase
end

always @(*) begin
	case(1)
		(ms< 16) : pixel_3 = 0;
		(ms< 32) : pixel_3 = 0;
		(ms< 48) : pixel_3 = 0;
		(ms< 64) : pixel_3 = 0;
		(ms< 80) : pixel_3 = 0;
		(ms< 96) : pixel_3 = 0;
		(ms<112) : pixel_3 = mem6_dout_reg[31:24];
		(ms<128) : pixel_3 = mem7_dout_reg[31:24];
		default  : pixel_3 = 8'd0;
	endcase
end

//MARK:OUT Pixel

reg [7:0] pixel_out_0 , pixel_out_1 , pixel_out_2 , pixel_out_3 ;

always @(*) begin
	case(1)
		(md < 64) : pixel_out_0 = new_maps[0][0];
		(md < 96) : pixel_out_0 = new_maps[0][1];
		(md < 128): pixel_out_0 = new_maps[0][3];
		default    : pixel_out_0 = 8'd0;
	endcase
end

always @(*) begin
	case(1)
		(md < 64) : pixel_out_1 = 0;
		(md < 96) : pixel_out_1 = new_maps[0][0];
		(md < 128): pixel_out_1 = new_maps[0][2];
		default    : pixel_out_1 = 8'd0;
	endcase
end

always @(*) begin
	if(md<128 && md>=96)
		pixel_out_2 = new_maps[0][1];
	else
		pixel_out_2  = 0;
	// case(1)
	// 	(md < 64) : pixel_out_2 = 0;
	// 	(md < 96) : pixel_out_2 = 0;
	// 	(md < 128): pixel_out_2 = new_maps[0][1];
	// 	default    : pixel_out_2 = 8'd0;
	// endcase
end

always @(*) begin
	if(md<128 && md>=96)
		pixel_out_3 = new_maps[0][0];
	else
		pixel_out_3  = 0;
	// case(1)
	// 	(md < 64) : pixel_out_3 = 0;
	// 	(md < 96) : pixel_out_3 = 0;
	// 	(md < 128): pixel_out_3 = new_maps[0][0];
	// 	default    : pixel_out_3 = 8'd0;
	// endcase
end

//MARK:Operations
wire Mem_8, Mem_16, Mem_32;
assign Mem_8  = (ms < 7'd64) ;
assign Mem_16 = ( (ms >= 7'd64) && (ms < 7'd96) ) ;
assign Mem_32 = ( (ms >= 7'd96) && (ms < 8'd128) ) ;
wire [3:0] type_func ;
assign type_func = {op,func} ;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for(row=0; row<16; row=row+1) 
			for(col=0; col<16; col=col+1) 
				new_maps[row][col] <= 8'd0;
	end
	else if (current_state == WAIT_IN) begin
		case(1)
			Mem_8 : begin
				new_maps[15][15] <= pixel;  new_maps[15][14] <= new_maps[15][15];  new_maps[15][13] <= new_maps[15][14];  new_maps[15][12] <= new_maps[15][13];
				new_maps[15][11] <= new_maps[15][12];  new_maps[15][10] <= new_maps[15][11];  new_maps[15][9] <= new_maps[15][10];   new_maps[15][8] <= new_maps[15][9];
				new_maps[15][7] <= new_maps[15][8];    new_maps[15][6] <= new_maps[15][7];    new_maps[15][5] <= new_maps[15][6];    new_maps[15][4] <= new_maps[15][5];
				new_maps[15][3] <= new_maps[15][4];    new_maps[15][2] <= new_maps[15][3];    new_maps[15][1] <= new_maps[15][2];    new_maps[15][0] <= new_maps[15][1];
				new_maps[14][15] <= new_maps[15][0];	new_maps[13][15] <= new_maps[14][0];   new_maps[12][15] <= new_maps[13][0];	new_maps[11][15] <= new_maps[12][0];
				new_maps[10][15] <= new_maps[11][0];	new_maps[9][15]  <= new_maps[10][0];   new_maps[8][15]  <= new_maps[9][0];	new_maps[7][15]  <= new_maps[8][0];
				new_maps[6][15]  <= new_maps[7][0];	    new_maps[5][15]  <= new_maps[6][0];    new_maps[4][15]  <= new_maps[5][0];	new_maps[3][15]  <= new_maps[4][0];
				new_maps[2][15]  <= new_maps[3][0];	    new_maps[1][15]  <= new_maps[2][0];    new_maps[0][15]  <= new_maps[1][0];
				for(row=0; row<15; row=row+1) 
					for(col=0; col<15; col=col+1) 
						new_maps[row][col] <= new_maps[row][col+1];
			end
			Mem_16 : begin
				for(row=0; row<16; row=row+1) 
					for(col=0; col<14; col=col+1) 
						new_maps[row][col] <= new_maps[row][col+2];
				new_maps[15][14] <= pixel_1;			new_maps[15][15] <= pixel;
				new_maps[14][15] <= new_maps[15][1];	new_maps[14][14] <= new_maps[15][0];  
				new_maps[13][15] <= new_maps[14][1];	new_maps[13][14] <= new_maps[14][0];
				new_maps[12][15] <= new_maps[13][1];	new_maps[12][14] <= new_maps[13][0];
				new_maps[11][15] <= new_maps[12][1];	new_maps[11][14] <= new_maps[12][0];
				new_maps[10][15] <= new_maps[11][1];	new_maps[10][14] <= new_maps[11][0];
				new_maps[9][15]  <= new_maps[10][1];	new_maps[9][14]  <= new_maps[10][0];
				new_maps[8][15]  <= new_maps[9][1];	    new_maps[8][14]  <= new_maps[9][0];
				new_maps[7][15]  <= new_maps[8][1];	    new_maps[7][14]  <= new_maps[8][0];
				new_maps[6][15]  <= new_maps[7][1];	    new_maps[6][14]  <= new_maps[7][0];
				new_maps[5][15]  <= new_maps[6][1];	    new_maps[5][14]  <= new_maps[6][0];
				new_maps[4][15]  <= new_maps[5][1];	    new_maps[4][14]  <= new_maps[5][0];
				new_maps[3][15]  <= new_maps[4][1];	    new_maps[3][14]  <= new_maps[4][0];
				new_maps[2][15]  <= new_maps[3][1];	    new_maps[2][14]  <= new_maps[3][0];
				new_maps[1][15]  <= new_maps[2][1];	    new_maps[1][14]  <= new_maps[2][0];
				new_maps[0][15]  <= new_maps[1][1];	    new_maps[0][14]  <= new_maps[1][0];
			end
			Mem_32 : begin
				new_maps[15][12] <= pixel_3;		  	new_maps[15][13] <= pixel_2;			new_maps[15][14] <= pixel_1;			new_maps[15][15] <= pixel;
				new_maps[14][15] <= new_maps[15][3];	new_maps[14][14] <= new_maps[15][2];	new_maps[14][13] <= new_maps[15][1];	new_maps[14][12] <= new_maps[15][0];
				new_maps[13][15] <= new_maps[14][3];	new_maps[13][14] <= new_maps[14][2];	new_maps[13][13] <= new_maps[14][1];	new_maps[13][12] <= new_maps[14][0];
				new_maps[12][15] <= new_maps[13][3];	new_maps[12][14] <= new_maps[13][2];	new_maps[12][13] <= new_maps[13][1];	new_maps[12][12] <= new_maps[13][0];
				new_maps[11][15] <= new_maps[12][3];	new_maps[11][14] <= new_maps[12][2];	new_maps[11][13] <= new_maps[12][1];	new_maps[11][12] <= new_maps[12][0];
				new_maps[10][15] <= new_maps[11][3];	new_maps[10][14] <= new_maps[11][2];	new_maps[10][13] <= new_maps[11][1];	new_maps[10][12] <= new_maps[11][0];
				new_maps[9][15]  <= new_maps[10][3];	new_maps[9][14]  <= new_maps[10][2];	new_maps[9][13]  <= new_maps[10][1];	new_maps[9][12]  <= new_maps[10][0];
				new_maps[8][15]  <= new_maps[9][3];	    new_maps[8][14]  <= new_maps[9][2];	    new_maps[8][13]  <= new_maps[9][1];	    new_maps[8][12]  <= new_maps[9][0];
				new_maps[7][15]  <= new_maps[8][3];	    new_maps[7][14]  <= new_maps[8][2];	    new_maps[7][13]  <= new_maps[8][1];	    new_maps[7][12]  <= new_maps[8][0];
				new_maps[6][15]  <= new_maps[7][3];	    new_maps[6][14]  <= new_maps[7][2];	    new_maps[6][13]  <= new_maps[7][1];	    new_maps[6][12]  <= new_maps[7][0];
				new_maps[5][15]  <= new_maps[6][3];	    new_maps[5][14]  <= new_maps[6][2];	    new_maps[5][13]  <= new_maps[6][1];	    new_maps[5][12]  <= new_maps[6][0];
				new_maps[4][15]  <= new_maps[5][3];	    new_maps[4][14]  <= new_maps[5][2];	    new_maps[4][13]  <= new_maps[5][1];	    new_maps[4][12]  <= new_maps[5][0];
				new_maps[3][15]  <= new_maps[4][3];	    new_maps[3][14]  <= new_maps[4][2];	    new_maps[3][13]  <= new_maps[4][1];	    new_maps[3][12]  <= new_maps[4][0];
				new_maps[2][15]  <= new_maps[3][3];	    new_maps[2][14]  <= new_maps[3][2];	    new_maps[2][13]  <= new_maps[3][1];	    new_maps[2][12]  <= new_maps[3][0];
				new_maps[1][15]  <= new_maps[2][3];	    new_maps[1][14]  <= new_maps[2][2];	    new_maps[1][13]  <= new_maps[2][1];	    new_maps[1][12]  <= new_maps[2][0];
				new_maps[0][15]  <= new_maps[1][3];	    new_maps[0][14]  <= new_maps[1][2];	    new_maps[0][13]  <= new_maps[1][1];	    new_maps[0][12]  <= new_maps[1][0];
				for(row=0; row<16; row=row+1) 
					for(col=0; col<12; col=col+1) 
						new_maps[row][col] <= new_maps[row][col+4];
			end
		endcase
	end
	else if (current_state == WAIT_OUT)
		case(1)
			(md<64) : begin
				new_maps[15][15] <= 0;  new_maps[15][14] <= new_maps[15][15];  new_maps[15][13] <= new_maps[15][14];  new_maps[15][12] <= new_maps[15][13];
				new_maps[15][11] <= new_maps[15][12];  new_maps[15][10] <= new_maps[15][11];  new_maps[15][9] <= new_maps[15][10];   new_maps[15][8] <= new_maps[15][9];
				new_maps[15][7] <= new_maps[15][8];    new_maps[15][6] <= new_maps[15][7];    new_maps[15][5] <= new_maps[15][6];    new_maps[15][4] <= new_maps[15][5];
				new_maps[15][3] <= new_maps[15][4];    new_maps[15][2] <= new_maps[15][3];    new_maps[15][1] <= new_maps[15][2];    new_maps[15][0] <= new_maps[15][1];
				new_maps[14][15] <= new_maps[15][0];	new_maps[13][15] <= new_maps[14][0];   new_maps[12][15] <= new_maps[13][0];	new_maps[11][15] <= new_maps[12][0];
				new_maps[10][15] <= new_maps[11][0];	new_maps[9][15]  <= new_maps[10][0];   new_maps[8][15]  <= new_maps[9][0];	new_maps[7][15]  <= new_maps[8][0];
				new_maps[6][15]  <= new_maps[7][0];	    new_maps[5][15]  <= new_maps[6][0];    new_maps[4][15]  <= new_maps[5][0];	new_maps[3][15]  <= new_maps[4][0];
				new_maps[2][15]  <= new_maps[3][0];	    new_maps[1][15]  <= new_maps[2][0];    new_maps[0][15]  <= new_maps[1][0];
				for(row=0; row<15; row=row+1) 
					for(col=0; col<15; col=col+1) 
						new_maps[row][col] <= new_maps[row][col+1];
			end
			(md<96) : begin
				for(row=0; row<16; row=row+1) 
					for(col=0; col<14; col=col+1) 
						new_maps[row][col] <= new_maps[row][col+2];
				new_maps[15][14] <= 0;					new_maps[15][15] <= 0;
				new_maps[14][15] <= new_maps[15][1];	new_maps[14][14] <= new_maps[15][0];  
				new_maps[13][15] <= new_maps[14][1];	new_maps[13][14] <= new_maps[14][0];
				new_maps[12][15] <= new_maps[13][1];	new_maps[12][14] <= new_maps[13][0];
				new_maps[11][15] <= new_maps[12][1];	new_maps[11][14] <= new_maps[12][0];
				new_maps[10][15] <= new_maps[11][1];	new_maps[10][14] <= new_maps[11][0];
				new_maps[9][15]  <= new_maps[10][1];	new_maps[9][14]  <= new_maps[10][0];
				new_maps[8][15]  <= new_maps[9][1];	    new_maps[8][14]  <= new_maps[9][0];
				new_maps[7][15]  <= new_maps[8][1];	    new_maps[7][14]  <= new_maps[8][0];
				new_maps[6][15]  <= new_maps[7][1];	    new_maps[6][14]  <= new_maps[7][0];
				new_maps[5][15]  <= new_maps[6][1];	    new_maps[5][14]  <= new_maps[6][0];
				new_maps[4][15]  <= new_maps[5][1];	    new_maps[4][14]  <= new_maps[5][0];
				new_maps[3][15]  <= new_maps[4][1];	    new_maps[3][14]  <= new_maps[4][0];
				new_maps[2][15]  <= new_maps[3][1];	    new_maps[2][14]  <= new_maps[3][0];
				new_maps[1][15]  <= new_maps[2][1];	    new_maps[1][14]  <= new_maps[2][0];
				new_maps[0][15]  <= new_maps[1][1];	    new_maps[0][14]  <= new_maps[1][0];
			end
			(md<128) : begin
				new_maps[15][12] <= 0;				  	new_maps[15][13] <= 0;					new_maps[15][14] <= 0;					new_maps[15][15] <= 0;
				new_maps[14][15] <= new_maps[15][3];	new_maps[14][14] <= new_maps[15][2];	new_maps[14][13] <= new_maps[15][1];	new_maps[14][12] <= new_maps[15][0];
				new_maps[13][15] <= new_maps[14][3];	new_maps[13][14] <= new_maps[14][2];	new_maps[13][13] <= new_maps[14][1];	new_maps[13][12] <= new_maps[14][0];
				new_maps[12][15] <= new_maps[13][3];	new_maps[12][14] <= new_maps[13][2];	new_maps[12][13] <= new_maps[13][1];	new_maps[12][12] <= new_maps[13][0];
				new_maps[11][15] <= new_maps[12][3];	new_maps[11][14] <= new_maps[12][2];	new_maps[11][13] <= new_maps[12][1];	new_maps[11][12] <= new_maps[12][0];
				new_maps[10][15] <= new_maps[11][3];	new_maps[10][14] <= new_maps[11][2];	new_maps[10][13] <= new_maps[11][1];	new_maps[10][12] <= new_maps[11][0];
				new_maps[9][15]  <= new_maps[10][3];	new_maps[9][14]  <= new_maps[10][2];	new_maps[9][13]  <= new_maps[10][1];	new_maps[9][12]  <= new_maps[10][0];
				new_maps[8][15]  <= new_maps[9][3];	    new_maps[8][14]  <= new_maps[9][2];	    new_maps[8][13]  <= new_maps[9][1];	    new_maps[8][12]  <= new_maps[9][0];
				new_maps[7][15]  <= new_maps[8][3];	    new_maps[7][14]  <= new_maps[8][2];	    new_maps[7][13]  <= new_maps[8][1];	    new_maps[7][12]  <= new_maps[8][0];
				new_maps[6][15]  <= new_maps[7][3];	    new_maps[6][14]  <= new_maps[7][2];	    new_maps[6][13]  <= new_maps[7][1];	    new_maps[6][12]  <= new_maps[7][0];
				new_maps[5][15]  <= new_maps[6][3];	    new_maps[5][14]  <= new_maps[6][2];	    new_maps[5][13]  <= new_maps[6][1];	    new_maps[5][12]  <= new_maps[6][0];
				new_maps[4][15]  <= new_maps[5][3];	    new_maps[4][14]  <= new_maps[5][2];	    new_maps[4][13]  <= new_maps[5][1];	    new_maps[4][12]  <= new_maps[5][0];
				new_maps[3][15]  <= new_maps[4][3];	    new_maps[3][14]  <= new_maps[4][2];	    new_maps[3][13]  <= new_maps[4][1];	    new_maps[3][12]  <= new_maps[4][0];
				new_maps[2][15]  <= new_maps[3][3];	    new_maps[2][14]  <= new_maps[3][2];	    new_maps[2][13]  <= new_maps[3][1];	    new_maps[2][12]  <= new_maps[3][0];
				new_maps[1][15]  <= new_maps[2][3];	    new_maps[1][14]  <= new_maps[2][2];	    new_maps[1][13]  <= new_maps[2][1];	    new_maps[1][12]  <= new_maps[2][0];
				new_maps[0][15]  <= new_maps[1][3];	    new_maps[0][14]  <= new_maps[1][2];	    new_maps[0][13]  <= new_maps[1][1];	    new_maps[0][12]  <= new_maps[1][0];
				for(row=0; row<16; row=row+1) 
					for(col=0; col<12; col=col+1) 
						new_maps[row][col] <= new_maps[row][col+4];
			end
		endcase
	else if (current_state == CALU)
		case (type_func)
			4'b0000 : begin // Mirror X
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[15-row][col] <= new_maps[row][col];
			end
			4'b0001 : begin // Mirror Y
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[row][15-col] <= new_maps[row][col];
			end
			4'b0010 : begin // Transpose 
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[col][row] <= new_maps[row][col];
			end
			4'b0011 : begin // Secondary Transpose
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[15-col][15-row] <= new_maps[row][col];
			end
			4'b0100 : begin // Rotate 90
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[col][15-row] <= new_maps[row][col];
			end
			4'b0101 : begin // Rotate 180
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[15-row][15-col] <= new_maps[row][col];
			end
			4'b0110 : begin // Rotate 270
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[15-col][row] <= new_maps[row][col];
			end

			4'b1000 : begin // Right Shift 5
				for(row=0; row<16; row=row+1) 
					for(col=5; col<16; col=col+1) 
						new_maps[row][col] <=  new_maps [row][col-5];

				for(row_1=0; row_1<16; row_1=row_1+1)
					for(col_1=0; col_1<5; col_1=col_1+1) 
						new_maps[row_1][col_1] <= new_maps[row_1][4-col_1];
			end

			4'b1001 : begin // Left Shift 5
				for(row=0; row<16; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[row][col] <= ( col <=10 ) ? new_maps[row][col+5] : new_maps[row][15-(col-11)];
			end

			4'b1010 : begin // Up Shift 5
				for(row=0; row<11; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[row][col] <=  new_maps [row+5][col];

				for(row_1=11; row_1<16; row_1=row_1+1)
					for(col_1=0; col_1<16; col_1=col_1+1) 
						new_maps[row_1][col_1] <= new_maps[26-row_1][col_1];
			end

			4'b1011 : begin // Down Shift 5
				for(row=0; row<5; row=row+1) 
					for(col=0; col<16; col=col+1) 
						new_maps[row][col] <=  new_maps [4-row][col];

				for(row_1=5; row_1<16; row_1=row_1+1)
					for(col_1=0; col_1<16; col_1=col_1+1) 
						new_maps[row_1][col_1] <= new_maps[row_1-5][col_1];

			end
			4'b1100 : begin // 4x4 Zigzag
				// --- Block (0,0) : Rows 0-3, Cols 0-3 ---V
				new_maps[0][0] <= new_maps[0][0]; new_maps[0][1] <= new_maps[0][1]; new_maps[0][2] <= new_maps[1][0]; new_maps[0][3] <= new_maps[2][0];
				new_maps[1][0] <= new_maps[1][1]; new_maps[1][1] <= new_maps[0][2]; new_maps[1][2] <= new_maps[0][3]; new_maps[1][3] <= new_maps[1][2];
				new_maps[2][0] <= new_maps[2][1]; new_maps[2][1] <= new_maps[3][0]; new_maps[2][2] <= new_maps[3][1]; new_maps[2][3] <= new_maps[2][2];
				new_maps[3][0] <= new_maps[1][3]; new_maps[3][1] <= new_maps[2][3]; new_maps[3][2] <= new_maps[3][2]; new_maps[3][3] <= new_maps[3][3];

				// --- Block (0,1) : Rows 0-3, Cols 4-7 ---
				new_maps[0][4] <= new_maps[0][4]; new_maps[0][5] <= new_maps[0][5]; new_maps[0][6] <= new_maps[1][4]; new_maps[0][7] <= new_maps[2][4];
				new_maps[1][4] <= new_maps[1][5]; new_maps[1][5] <= new_maps[0][6]; new_maps[1][6] <= new_maps[0][7]; new_maps[1][7] <= new_maps[1][6];
				new_maps[2][4] <= new_maps[2][5]; new_maps[2][5] <= new_maps[3][4]; new_maps[2][6] <= new_maps[3][5]; new_maps[2][7] <= new_maps[2][6];
				new_maps[3][4] <= new_maps[1][7]; new_maps[3][5] <= new_maps[2][7]; new_maps[3][6] <= new_maps[3][6]; new_maps[3][7] <= new_maps[3][7];

				// --- Block (0,2) : Rows 0-3, Cols 8-11 ---
				new_maps[0][8] <= new_maps[0][8]; new_maps[0][9] <= new_maps[0][9]; new_maps[0][10] <= new_maps[1][8]; new_maps[0][11] <= new_maps[2][8];
				new_maps[1][8] <= new_maps[1][9]; new_maps[1][9] <= new_maps[0][10]; new_maps[1][10] <= new_maps[0][11]; new_maps[1][11] <= new_maps[1][10];
				new_maps[2][8] <= new_maps[2][9]; new_maps[2][9] <= new_maps[3][8]; new_maps[2][10] <= new_maps[3][9]; new_maps[2][11] <= new_maps[2][10];
				new_maps[3][8] <= new_maps[1][11]; new_maps[3][9] <= new_maps[2][11]; new_maps[3][10] <= new_maps[3][10]; new_maps[3][11] <= new_maps[3][11];

				// --- Block (0,3) : Rows 0-3, Cols 12-15 ---
				new_maps[0][12] <= new_maps[0][12]; new_maps[0][13] <= new_maps[0][13]; new_maps[0][14] <= new_maps[1][12]; new_maps[0][15] <= new_maps[2][12];
				new_maps[1][12] <= new_maps[1][13]; new_maps[1][13] <= new_maps[0][14]; new_maps[1][14] <= new_maps[0][15]; new_maps[1][15] <= new_maps[1][14];
				new_maps[2][12] <= new_maps[2][13]; new_maps[2][13] <= new_maps[3][12]; new_maps[2][14] <= new_maps[3][13]; new_maps[2][15] <= new_maps[2][14];
				new_maps[3][12] <= new_maps[1][15]; new_maps[3][13] <= new_maps[2][15]; new_maps[3][14] <= new_maps[3][14]; new_maps[3][15] <= new_maps[3][15];

				// --- Block (1,0) : Rows 4-7, Cols 0-3 ---
				new_maps[4][0] <= new_maps[4][0]; new_maps[4][1] <= new_maps[4][1]; new_maps[4][2] <= new_maps[5][0]; new_maps[4][3] <= new_maps[6][0];
				new_maps[5][0] <= new_maps[5][1]; new_maps[5][1] <= new_maps[4][2]; new_maps[5][2] <= new_maps[4][3]; new_maps[5][3] <= new_maps[5][2];
				new_maps[6][0] <= new_maps[6][1]; new_maps[6][1] <= new_maps[7][0]; new_maps[6][2] <= new_maps[7][1]; new_maps[6][3] <= new_maps[6][2];
				new_maps[7][0] <= new_maps[5][3]; new_maps[7][1] <= new_maps[6][3]; new_maps[7][2] <= new_maps[7][2]; new_maps[7][3] <= new_maps[7][3];

				// --- Block (1,1) : Rows 4-7, Cols 4-7 ---
				new_maps[4][4] <= new_maps[4][4]; new_maps[4][5] <= new_maps[4][5]; new_maps[4][6] <= new_maps[5][4]; new_maps[4][7] <= new_maps[6][4];
				new_maps[5][4] <= new_maps[5][5]; new_maps[5][5] <= new_maps[4][6]; new_maps[5][6] <= new_maps[4][7]; new_maps[5][7] <= new_maps[5][6];
				new_maps[6][4] <= new_maps[6][5]; new_maps[6][5] <= new_maps[7][4]; new_maps[6][6] <= new_maps[7][5]; new_maps[6][7] <= new_maps[6][6];
				new_maps[7][4] <= new_maps[5][7]; new_maps[7][5] <= new_maps[6][7]; new_maps[7][6] <= new_maps[7][6]; new_maps[7][7] <= new_maps[7][7];

				// --- Block (1,2) : Rows 4-7, Cols 8-11 ---
				new_maps[4][8] <= new_maps[4][8]; new_maps[4][9] <= new_maps[4][9]; new_maps[4][10] <= new_maps[5][8]; new_maps[4][11] <= new_maps[6][8];
				new_maps[5][8] <= new_maps[5][9]; new_maps[5][9] <= new_maps[4][10]; new_maps[5][10] <= new_maps[4][11]; new_maps[5][11] <= new_maps[5][10];
				new_maps[6][8] <= new_maps[6][9]; new_maps[6][9] <= new_maps[7][8]; new_maps[6][10] <= new_maps[7][9]; new_maps[6][11] <= new_maps[6][10];
				new_maps[7][8] <= new_maps[5][11]; new_maps[7][9] <= new_maps[6][11]; new_maps[7][10] <= new_maps[7][10]; new_maps[7][11] <= new_maps[7][11];

				// --- Block (1,3) : Rows 4-7, Cols 12-15 ---
				new_maps[4][12] <= new_maps[4][12]; new_maps[4][13] <= new_maps[4][13]; new_maps[4][14] <= new_maps[5][12]; new_maps[4][15] <= new_maps[6][12];
				new_maps[5][12] <= new_maps[5][13]; new_maps[5][13] <= new_maps[4][14]; new_maps[5][14] <= new_maps[4][15]; new_maps[5][15] <= new_maps[5][14];
				new_maps[6][12] <= new_maps[6][13]; new_maps[6][13] <= new_maps[7][12]; new_maps[6][14] <= new_maps[7][13]; new_maps[6][15] <= new_maps[6][14];
				new_maps[7][12] <= new_maps[5][15]; new_maps[7][13] <= new_maps[6][15]; new_maps[7][14] <= new_maps[7][14]; new_maps[7][15] <= new_maps[7][15];

				// --- Block (2,0) : Rows 8-11, Cols 0-3 ---
				new_maps[8][0] <= new_maps[8][0]; new_maps[8][1] <= new_maps[8][1]; new_maps[8][2] <= new_maps[9][0]; new_maps[8][3] <= new_maps[10][0];
				new_maps[9][0] <= new_maps[9][1]; new_maps[9][1] <= new_maps[8][2]; new_maps[9][2] <= new_maps[8][3]; new_maps[9][3] <= new_maps[9][2];
				new_maps[10][0] <= new_maps[10][1]; new_maps[10][1] <= new_maps[11][0]; new_maps[10][2] <= new_maps[11][1]; new_maps[10][3] <= new_maps[10][2];
				new_maps[11][0] <= new_maps[9][3]; new_maps[11][1] <= new_maps[10][3]; new_maps[11][2] <= new_maps[11][2]; new_maps[11][3] <= new_maps[11][3];

				// --- Block (2,1) : Rows 8-11, Cols 4-7 ---
				new_maps[8][4] <= new_maps[8][4]; new_maps[8][5] <= new_maps[8][5]; new_maps[8][6] <= new_maps[9][4]; new_maps[8][7] <= new_maps[10][4];
				new_maps[9][4] <= new_maps[9][5]; new_maps[9][5] <= new_maps[8][6]; new_maps[9][6] <= new_maps[8][7]; new_maps[9][7] <= new_maps[9][6];
				new_maps[10][4] <= new_maps[10][5]; new_maps[10][5] <= new_maps[11][4]; new_maps[10][6] <= new_maps[11][5]; new_maps[10][7] <= new_maps[10][6];
				new_maps[11][4] <= new_maps[9][7]; new_maps[11][5] <= new_maps[10][7]; new_maps[11][6] <= new_maps[11][6]; new_maps[11][7] <= new_maps[11][7];

				// --- Block (2,2) : Rows 8-11, Cols 8-11 ---
				new_maps[8][8] <= new_maps[8][8]; new_maps[8][9] <= new_maps[8][9]; new_maps[8][10] <= new_maps[9][8]; new_maps[8][11] <= new_maps[10][8];
				new_maps[9][8] <= new_maps[9][9]; new_maps[9][9] <= new_maps[8][10]; new_maps[9][10] <= new_maps[8][11]; new_maps[9][11] <= new_maps[9][10];
				new_maps[10][8] <= new_maps[10][9]; new_maps[10][9] <= new_maps[11][8]; new_maps[10][10] <= new_maps[11][9]; new_maps[10][11] <= new_maps[10][10];
				new_maps[11][8] <= new_maps[9][11]; new_maps[11][9] <= new_maps[10][11]; new_maps[11][10] <= new_maps[11][10]; new_maps[11][11] <= new_maps[11][11];

				// --- Block (2,3) : Rows 8-11, Cols 12-15 ---
				new_maps[8][12] <= new_maps[8][12]; new_maps[8][13] <= new_maps[8][13]; new_maps[8][14] <= new_maps[9][12]; new_maps[8][15] <= new_maps[10][12];
				new_maps[9][12] <= new_maps[9][13]; new_maps[9][13] <= new_maps[8][14]; new_maps[9][14] <= new_maps[8][15]; new_maps[9][15] <= new_maps[9][14];
				new_maps[10][12] <= new_maps[10][13]; new_maps[10][13] <= new_maps[11][12]; new_maps[10][14] <= new_maps[11][13]; new_maps[10][15] <= new_maps[10][14];
				new_maps[11][12] <= new_maps[9][15]; new_maps[11][13] <= new_maps[10][15]; new_maps[11][14] <= new_maps[11][14]; new_maps[11][15] <= new_maps[11][15];

				// --- Block (3,0) : Rows 12-15, Cols 0-3 ---
				new_maps[12][0] <= new_maps[12][0]; new_maps[12][1] <= new_maps[12][1]; new_maps[12][2] <= new_maps[13][0]; new_maps[12][3] <= new_maps[14][0];
				new_maps[13][0] <= new_maps[13][1]; new_maps[13][1] <= new_maps[12][2]; new_maps[13][2] <= new_maps[12][3]; new_maps[13][3] <= new_maps[13][2];
				new_maps[14][0] <= new_maps[14][1]; new_maps[14][1] <= new_maps[15][0]; new_maps[14][2] <= new_maps[15][1]; new_maps[14][3] <= new_maps[14][2];
				new_maps[15][0] <= new_maps[13][3]; new_maps[15][1] <= new_maps[14][3]; new_maps[15][2] <= new_maps[15][2]; new_maps[15][3] <= new_maps[15][3];

				// --- Block (3,1) : Rows 12-15, Cols 4-7 ---
				new_maps[12][4] <= new_maps[12][4]; new_maps[12][5] <= new_maps[12][5]; new_maps[12][6] <= new_maps[13][4]; new_maps[12][7] <= new_maps[14][4];
				new_maps[13][4] <= new_maps[13][5]; new_maps[13][5] <= new_maps[12][6]; new_maps[13][6] <= new_maps[12][7]; new_maps[13][7] <= new_maps[13][6];
				new_maps[14][4] <= new_maps[14][5]; new_maps[14][5] <= new_maps[15][4]; new_maps[14][6] <= new_maps[15][5]; new_maps[14][7] <= new_maps[14][6];
				new_maps[15][4] <= new_maps[13][7]; new_maps[15][5] <= new_maps[14][7]; new_maps[15][6] <= new_maps[15][6]; new_maps[15][7] <= new_maps[15][7];

				// --- Block (3,2) : Rows 12-15, Cols 8-11 ---
				new_maps[12][8] <= new_maps[12][8]; new_maps[12][9] <= new_maps[12][9]; new_maps[12][10] <= new_maps[13][8]; new_maps[12][11] <= new_maps[14][8];
				new_maps[13][8] <= new_maps[13][9]; new_maps[13][9] <= new_maps[12][10]; new_maps[13][10] <= new_maps[12][11]; new_maps[13][11] <= new_maps[13][10];
				new_maps[14][8] <= new_maps[14][9]; new_maps[14][9] <= new_maps[15][8]; new_maps[14][10] <= new_maps[15][9]; new_maps[14][11] <= new_maps[14][10];
				new_maps[15][8] <= new_maps[13][11]; new_maps[15][9] <= new_maps[14][11]; new_maps[15][10] <= new_maps[15][10]; new_maps[15][11] <= new_maps[15][11];

				// --- Block (3,3) : Rows 12-15, Cols 12-15 ---
				new_maps[12][12] <= new_maps[12][12]; new_maps[12][13] <= new_maps[12][13]; new_maps[12][14] <= new_maps[13][12]; new_maps[12][15] <= new_maps[14][12];
				new_maps[13][12] <= new_maps[13][13]; new_maps[13][13] <= new_maps[12][14]; new_maps[13][14] <= new_maps[12][15]; new_maps[13][15] <= new_maps[13][14];
				new_maps[14][12] <= new_maps[14][13]; new_maps[14][13] <= new_maps[15][12]; new_maps[14][14] <= new_maps[15][13]; new_maps[14][15] <= new_maps[14][14];
				new_maps[15][12] <= new_maps[13][15]; new_maps[15][13] <= new_maps[14][15]; new_maps[15][14] <= new_maps[15][14]; new_maps[15][15] <= new_maps[15][15];
			end
			4'b1101 : begin // 8x8 Zigzag
				// ------------------------------------------------------------------------------------------------
				//  Block (0,0) : Rows 0-7, Cols 0-7
				// ------------------------------------------------------------------------------------------------
				// Row 0 V
				new_maps[0][0] <= new_maps[0][0]; new_maps[0][1] <= new_maps[0][1]; new_maps[0][2] <= new_maps[1][0]; new_maps[0][3] <= new_maps[2][0];
				new_maps[0][4] <= new_maps[1][1]; new_maps[0][5] <= new_maps[0][2]; new_maps[0][6] <= new_maps[0][3]; new_maps[0][7] <= new_maps[1][2];
				// Row 1 V
				new_maps[1][0] <= new_maps[2][1]; new_maps[1][1] <= new_maps[3][0]; new_maps[1][2] <= new_maps[4][0]; new_maps[1][3] <= new_maps[3][1];
				new_maps[1][4] <= new_maps[2][2]; new_maps[1][5] <= new_maps[1][3]; new_maps[1][6] <= new_maps[0][4]; new_maps[1][7] <= new_maps[0][5];
				// Row 2 V
				new_maps[2][0] <= new_maps[1][4]; new_maps[2][1] <= new_maps[2][3]; new_maps[2][2] <= new_maps[3][2]; new_maps[2][3] <= new_maps[4][1];
				new_maps[2][4] <= new_maps[5][0]; new_maps[2][5] <= new_maps[6][0]; new_maps[2][6] <= new_maps[5][1]; new_maps[2][7] <= new_maps[4][2];
				// Row 3
				new_maps[3][0] <= new_maps[3][3]; new_maps[3][1] <= new_maps[2][4]; new_maps[3][2] <= new_maps[1][5]; new_maps[3][3] <= new_maps[0][6];
				new_maps[3][4] <= new_maps[0][7]; new_maps[3][5] <= new_maps[1][6]; new_maps[3][6] <= new_maps[2][5]; new_maps[3][7] <= new_maps[3][4];
				// Row 4
				new_maps[4][0] <= new_maps[4][3]; new_maps[4][1] <= new_maps[5][2]; new_maps[4][2] <= new_maps[6][1]; new_maps[4][3] <= new_maps[7][0];
				new_maps[4][4] <= new_maps[7][1]; new_maps[4][5] <= new_maps[6][2]; new_maps[4][6] <= new_maps[5][3]; new_maps[4][7] <= new_maps[4][4];
				// Row 5
				new_maps[5][0] <= new_maps[3][5]; new_maps[5][1] <= new_maps[2][6]; new_maps[5][2] <= new_maps[1][7]; new_maps[5][3] <= new_maps[2][7];
				new_maps[5][4] <= new_maps[3][6]; new_maps[5][5] <= new_maps[4][5]; new_maps[5][6] <= new_maps[5][4]; new_maps[5][7] <= new_maps[6][3];
				// Row 6
				new_maps[6][0] <= new_maps[7][2]; new_maps[6][1] <= new_maps[7][3]; new_maps[6][2] <= new_maps[6][4]; new_maps[6][3] <= new_maps[5][5];
				new_maps[6][4] <= new_maps[4][6]; new_maps[6][5] <= new_maps[3][7]; new_maps[6][6] <= new_maps[4][7]; new_maps[6][7] <= new_maps[5][6];
				// Row 7
				new_maps[7][0] <= new_maps[6][5]; new_maps[7][1] <= new_maps[7][4]; new_maps[7][2] <= new_maps[7][5]; new_maps[7][3] <= new_maps[6][6];
				new_maps[7][4] <= new_maps[5][7]; new_maps[7][5] <= new_maps[6][7]; new_maps[7][6] <= new_maps[7][6]; new_maps[7][7] <= new_maps[7][7];

				// ------------------------------------------------------------------------------------------------
				//  Block (0,1) : Rows 0-7, Cols 8-15 (Col Offset +8)
				// ------------------------------------------------------------------------------------------------
				// Row 0
				new_maps[0][8] <= new_maps[0][8]; new_maps[0][9] <= new_maps[0][9]; new_maps[0][10] <= new_maps[1][8]; new_maps[0][11] <= new_maps[2][8];
				new_maps[0][12] <= new_maps[1][9]; new_maps[0][13] <= new_maps[0][10]; new_maps[0][14] <= new_maps[0][11]; new_maps[0][15] <= new_maps[1][10];
				// Row 1
				new_maps[1][8] <= new_maps[2][9]; new_maps[1][9] <= new_maps[3][8]; new_maps[1][10] <= new_maps[4][8]; new_maps[1][11] <= new_maps[3][9];
				new_maps[1][12] <= new_maps[2][10]; new_maps[1][13] <= new_maps[1][11]; new_maps[1][14] <= new_maps[0][12]; new_maps[1][15] <= new_maps[0][13];
				// Row 2
				new_maps[2][8] <= new_maps[1][12]; new_maps[2][9] <= new_maps[2][11]; new_maps[2][10] <= new_maps[3][10]; new_maps[2][11] <= new_maps[4][9];
				new_maps[2][12] <= new_maps[5][8]; new_maps[2][13] <= new_maps[6][8]; new_maps[2][14] <= new_maps[5][9]; new_maps[2][15] <= new_maps[4][10];
				// Row 3
				new_maps[3][8] <= new_maps[3][11]; new_maps[3][9] <= new_maps[2][12]; new_maps[3][10] <= new_maps[1][13]; new_maps[3][11] <= new_maps[0][14];
				new_maps[3][12] <= new_maps[0][15]; new_maps[3][13] <= new_maps[1][14]; new_maps[3][14] <= new_maps[2][13]; new_maps[3][15] <= new_maps[3][12];
				// Row 4
				new_maps[4][8] <= new_maps[4][11]; new_maps[4][9] <= new_maps[5][10]; new_maps[4][10] <= new_maps[6][9]; new_maps[4][11] <= new_maps[7][8];
				new_maps[4][12] <= new_maps[7][9]; new_maps[4][13] <= new_maps[6][10]; new_maps[4][14] <= new_maps[5][11]; new_maps[4][15] <= new_maps[4][12];
				// Row 5
				new_maps[5][8] <= new_maps[3][13]; new_maps[5][9] <= new_maps[2][14]; new_maps[5][10] <= new_maps[1][15]; new_maps[5][11] <= new_maps[2][15];
				new_maps[5][12] <= new_maps[3][14]; new_maps[5][13] <= new_maps[4][13]; new_maps[5][14] <= new_maps[5][12]; new_maps[5][15] <= new_maps[6][11];
				// Row 6
				new_maps[6][8] <= new_maps[7][10]; new_maps[6][9] <= new_maps[7][11]; new_maps[6][10] <= new_maps[6][12]; new_maps[6][11] <= new_maps[5][13];
				new_maps[6][12] <= new_maps[4][14]; new_maps[6][13] <= new_maps[3][15]; new_maps[6][14] <= new_maps[4][15]; new_maps[6][15] <= new_maps[5][14];
				// Row 7
				new_maps[7][8] <= new_maps[6][13]; new_maps[7][9] <= new_maps[7][12]; new_maps[7][10] <= new_maps[7][13]; new_maps[7][11] <= new_maps[6][14];
				new_maps[7][12] <= new_maps[5][15]; new_maps[7][13] <= new_maps[6][15]; new_maps[7][14] <= new_maps[7][14]; new_maps[7][15] <= new_maps[7][15];

				// ------------------------------------------------------------------------------------------------
				//  Block (1,0) : Rows 8-15, Cols 0-7 (Row Offset +8)
				// ------------------------------------------------------------------------------------------------
				// Row 8
				new_maps[8][0] <= new_maps[8][0]; new_maps[8][1] <= new_maps[8][1]; new_maps[8][2] <= new_maps[9][0]; new_maps[8][3] <= new_maps[10][0];
				new_maps[8][4] <= new_maps[9][1]; new_maps[8][5] <= new_maps[8][2]; new_maps[8][6] <= new_maps[8][3]; new_maps[8][7] <= new_maps[9][2];
				// Row 9
				new_maps[9][0] <= new_maps[10][1]; new_maps[9][1] <= new_maps[11][0]; new_maps[9][2] <= new_maps[12][0]; new_maps[9][3] <= new_maps[11][1];
				new_maps[9][4] <= new_maps[10][2]; new_maps[9][5] <= new_maps[9][3]; new_maps[9][6] <= new_maps[8][4]; new_maps[9][7] <= new_maps[8][5];
				// Row 10
				new_maps[10][0] <= new_maps[9][4]; new_maps[10][1] <= new_maps[10][3]; new_maps[10][2] <= new_maps[11][2]; new_maps[10][3] <= new_maps[12][1];
				new_maps[10][4] <= new_maps[13][0]; new_maps[10][5] <= new_maps[14][0]; new_maps[10][6] <= new_maps[13][1]; new_maps[10][7] <= new_maps[12][2];
				// Row 11
				new_maps[11][0] <= new_maps[11][3]; new_maps[11][1] <= new_maps[10][4]; new_maps[11][2] <= new_maps[9][5]; new_maps[11][3] <= new_maps[8][6];
				new_maps[11][4] <= new_maps[8][7]; new_maps[11][5] <= new_maps[9][6]; new_maps[11][6] <= new_maps[10][5]; new_maps[11][7] <= new_maps[11][4];
				// Row 12
				new_maps[12][0] <= new_maps[12][3]; new_maps[12][1] <= new_maps[13][2]; new_maps[12][2] <= new_maps[14][1]; new_maps[12][3] <= new_maps[15][0];
				new_maps[12][4] <= new_maps[15][1]; new_maps[12][5] <= new_maps[14][2]; new_maps[12][6] <= new_maps[13][3]; new_maps[12][7] <= new_maps[12][4];
				// Row 13
				new_maps[13][0] <= new_maps[11][5]; new_maps[13][1] <= new_maps[10][6]; new_maps[13][2] <= new_maps[9][7]; new_maps[13][3] <= new_maps[10][7];
				new_maps[13][4] <= new_maps[11][6]; new_maps[13][5] <= new_maps[12][5]; new_maps[13][6] <= new_maps[13][4]; new_maps[13][7] <= new_maps[14][3];
				// Row 14
				new_maps[14][0] <= new_maps[15][2]; new_maps[14][1] <= new_maps[15][3]; new_maps[14][2] <= new_maps[14][4]; new_maps[14][3] <= new_maps[13][5];
				new_maps[14][4] <= new_maps[12][6]; new_maps[14][5] <= new_maps[11][7]; new_maps[14][6] <= new_maps[12][7]; new_maps[14][7] <= new_maps[13][6];
				// Row 15
				new_maps[15][0] <= new_maps[14][5]; new_maps[15][1] <= new_maps[15][4]; new_maps[15][2] <= new_maps[15][5]; new_maps[15][3] <= new_maps[14][6];
				new_maps[15][4] <= new_maps[13][7]; new_maps[15][5] <= new_maps[14][7]; new_maps[15][6] <= new_maps[15][6]; new_maps[15][7] <= new_maps[15][7];

				// ------------------------------------------------------------------------------------------------
				//  Block (1,1) : Rows 8-15, Cols 8-15 (Row & Col Offset +8)
				// ------------------------------------------------------------------------------------------------
				// Row 8
				new_maps[8][8] <= new_maps[8][8]; new_maps[8][9] <= new_maps[8][9]; new_maps[8][10] <= new_maps[9][8]; new_maps[8][11] <= new_maps[10][8];
				new_maps[8][12] <= new_maps[9][9]; new_maps[8][13] <= new_maps[8][10]; new_maps[8][14] <= new_maps[8][11]; new_maps[8][15] <= new_maps[9][10];
				// Row 9
				new_maps[9][8] <= new_maps[10][9]; new_maps[9][9] <= new_maps[11][8]; new_maps[9][10] <= new_maps[12][8]; new_maps[9][11] <= new_maps[11][9];
				new_maps[9][12] <= new_maps[10][10]; new_maps[9][13] <= new_maps[9][11]; new_maps[9][14] <= new_maps[8][12]; new_maps[9][15] <= new_maps[8][13];
				// Row 10
				new_maps[10][8] <= new_maps[9][12]; new_maps[10][9] <= new_maps[10][11]; new_maps[10][10] <= new_maps[11][10]; new_maps[10][11] <= new_maps[12][9];
				new_maps[10][12] <= new_maps[13][8]; new_maps[10][13] <= new_maps[14][8]; new_maps[10][14] <= new_maps[13][9]; new_maps[10][15] <= new_maps[12][10];
				// Row 11
				new_maps[11][8] <= new_maps[11][11]; new_maps[11][9] <= new_maps[10][12]; new_maps[11][10] <= new_maps[9][13]; new_maps[11][11] <= new_maps[8][14];
				new_maps[11][12] <= new_maps[8][15]; new_maps[11][13] <= new_maps[9][14]; new_maps[11][14] <= new_maps[10][13]; new_maps[11][15] <= new_maps[11][12];
				// Row 12
				new_maps[12][8] <= new_maps[12][11]; new_maps[12][9] <= new_maps[13][10]; new_maps[12][10] <= new_maps[14][9]; new_maps[12][11] <= new_maps[15][8];
				new_maps[12][12] <= new_maps[15][9]; new_maps[12][13] <= new_maps[14][10]; new_maps[12][14] <= new_maps[13][11]; new_maps[12][15] <= new_maps[12][12];
				// Row 13
				new_maps[13][8] <= new_maps[11][13]; new_maps[13][9] <= new_maps[10][14]; new_maps[13][10] <= new_maps[9][15]; new_maps[13][11] <= new_maps[10][15];
				new_maps[13][12] <= new_maps[11][14]; new_maps[13][13] <= new_maps[12][13]; new_maps[13][14] <= new_maps[13][12]; new_maps[13][15] <= new_maps[14][11];
				// Row 14
				new_maps[14][8] <= new_maps[15][10]; new_maps[14][9] <= new_maps[15][11]; new_maps[14][10] <= new_maps[14][12]; new_maps[14][11] <= new_maps[13][13];
				new_maps[14][12] <= new_maps[12][14]; new_maps[14][13] <= new_maps[11][15]; new_maps[14][14] <= new_maps[12][15]; new_maps[14][15] <= new_maps[13][14];
				// Row 15
				new_maps[15][8] <= new_maps[14][13]; new_maps[15][9] <= new_maps[15][12]; new_maps[15][10] <= new_maps[15][13]; new_maps[15][11] <= new_maps[14][14];
				new_maps[15][12] <= new_maps[13][15]; new_maps[15][13] <= new_maps[14][15]; new_maps[15][14] <= new_maps[15][14]; new_maps[15][15] <= new_maps[15][15];
			end
			4'b1110 : begin // 4X4 Morton
				// --- Block (0,0) : Rows 0-3, Cols 0-3 --- V
				new_maps[0][0] <= new_maps[0][0]; new_maps[0][1] <= new_maps[0][1]; new_maps[0][2] <= new_maps[1][0]; new_maps[0][3] <= new_maps[1][1];
				new_maps[1][0] <= new_maps[0][2]; new_maps[1][1] <= new_maps[0][3]; new_maps[1][2] <= new_maps[1][2]; new_maps[1][3] <= new_maps[1][3];
				new_maps[2][0] <= new_maps[2][0]; new_maps[2][1] <= new_maps[2][1]; new_maps[2][2] <= new_maps[3][0]; new_maps[2][3] <= new_maps[3][1];
				new_maps[3][0] <= new_maps[2][2]; new_maps[3][1] <= new_maps[2][3]; new_maps[3][2] <= new_maps[3][2]; new_maps[3][3] <= new_maps[3][3];

				// --- Block (0,1) : Rows 0-3, Cols 4-7 ---
				new_maps[0][4] <= new_maps[0][4]; new_maps[0][5] <= new_maps[0][5]; new_maps[0][6] <= new_maps[1][4]; new_maps[0][7] <= new_maps[1][5];
				new_maps[1][4] <= new_maps[0][6]; new_maps[1][5] <= new_maps[0][7]; new_maps[1][6] <= new_maps[1][6]; new_maps[1][7] <= new_maps[1][7];
				new_maps[2][4] <= new_maps[2][4]; new_maps[2][5] <= new_maps[2][5]; new_maps[2][6] <= new_maps[3][4]; new_maps[2][7] <= new_maps[3][5];
				new_maps[3][4] <= new_maps[2][6]; new_maps[3][5] <= new_maps[2][7]; new_maps[3][6] <= new_maps[3][6]; new_maps[3][7] <= new_maps[3][7];

				// --- Block (0,2) : Rows 0-3, Cols 8-11 ---
				new_maps[0][8] <= new_maps[0][8]; new_maps[0][9] <= new_maps[0][9]; new_maps[0][10] <= new_maps[1][8]; new_maps[0][11] <= new_maps[1][9];
				new_maps[1][8] <= new_maps[0][10]; new_maps[1][9] <= new_maps[0][11]; new_maps[1][10] <= new_maps[1][10]; new_maps[1][11] <= new_maps[1][11];
				new_maps[2][8] <= new_maps[2][8]; new_maps[2][9] <= new_maps[2][9]; new_maps[2][10] <= new_maps[3][8]; new_maps[2][11] <= new_maps[3][9];
				new_maps[3][8] <= new_maps[2][10]; new_maps[3][9] <= new_maps[2][11]; new_maps[3][10] <= new_maps[3][10]; new_maps[3][11] <= new_maps[3][11];

				// --- Block (0,3) : Rows 0-3, Cols 12-15 ---
				new_maps[0][12] <= new_maps[0][12]; new_maps[0][13] <= new_maps[0][13]; new_maps[0][14] <= new_maps[1][12]; new_maps[0][15] <= new_maps[1][13];
				new_maps[1][12] <= new_maps[0][14]; new_maps[1][13] <= new_maps[0][15]; new_maps[1][14] <= new_maps[1][14]; new_maps[1][15] <= new_maps[1][15];
				new_maps[2][12] <= new_maps[2][12]; new_maps[2][13] <= new_maps[2][13]; new_maps[2][14] <= new_maps[3][12]; new_maps[2][15] <= new_maps[3][13];
				new_maps[3][12] <= new_maps[2][14]; new_maps[3][13] <= new_maps[2][15]; new_maps[3][14] <= new_maps[3][14]; new_maps[3][15] <= new_maps[3][15];

				// --- Block (1,0) : Rows 4-7, Cols 0-3 ---
				new_maps[4][0] <= new_maps[4][0]; new_maps[4][1] <= new_maps[4][1]; new_maps[4][2] <= new_maps[5][0]; new_maps[4][3] <= new_maps[5][1];
				new_maps[5][0] <= new_maps[4][2]; new_maps[5][1] <= new_maps[4][3]; new_maps[5][2] <= new_maps[5][2]; new_maps[5][3] <= new_maps[5][3];
				new_maps[6][0] <= new_maps[6][0]; new_maps[6][1] <= new_maps[6][1]; new_maps[6][2] <= new_maps[7][0]; new_maps[6][3] <= new_maps[7][1];
				new_maps[7][0] <= new_maps[6][2]; new_maps[7][1] <= new_maps[6][3]; new_maps[7][2] <= new_maps[7][2]; new_maps[7][3] <= new_maps[7][3];

				// --- Block (1,1) : Rows 4-7, Cols 4-7 ---
				new_maps[4][4] <= new_maps[4][4]; new_maps[4][5] <= new_maps[4][5]; new_maps[4][6] <= new_maps[5][4]; new_maps[4][7] <= new_maps[5][5];
				new_maps[5][4] <= new_maps[4][6]; new_maps[5][5] <= new_maps[4][7]; new_maps[5][6] <= new_maps[5][6]; new_maps[5][7] <= new_maps[5][7];
				new_maps[6][4] <= new_maps[6][4]; new_maps[6][5] <= new_maps[6][5]; new_maps[6][6] <= new_maps[7][4]; new_maps[6][7] <= new_maps[7][5];
				new_maps[7][4] <= new_maps[6][6]; new_maps[7][5] <= new_maps[6][7]; new_maps[7][6] <= new_maps[7][6]; new_maps[7][7] <= new_maps[7][7];

				// --- Block (1,2) : Rows 4-7, Cols 8-11 ---
				new_maps[4][8] <= new_maps[4][8]; new_maps[4][9] <= new_maps[4][9]; new_maps[4][10] <= new_maps[5][8]; new_maps[4][11] <= new_maps[5][9];
				new_maps[5][8] <= new_maps[4][10]; new_maps[5][9] <= new_maps[4][11]; new_maps[5][10] <= new_maps[5][10]; new_maps[5][11] <= new_maps[5][11];
				new_maps[6][8] <= new_maps[6][8]; new_maps[6][9] <= new_maps[6][9]; new_maps[6][10] <= new_maps[7][8]; new_maps[6][11] <= new_maps[7][9];
				new_maps[7][8] <= new_maps[6][10]; new_maps[7][9] <= new_maps[6][11]; new_maps[7][10] <= new_maps[7][10]; new_maps[7][11] <= new_maps[7][11];

				// --- Block (1,3) : Rows 4-7, Cols 12-15 ---
				new_maps[4][12] <= new_maps[4][12]; new_maps[4][13] <= new_maps[4][13]; new_maps[4][14] <= new_maps[5][12]; new_maps[4][15] <= new_maps[5][13];
				new_maps[5][12] <= new_maps[4][14]; new_maps[5][13] <= new_maps[4][15]; new_maps[5][14] <= new_maps[5][14]; new_maps[5][15] <= new_maps[5][15];
				new_maps[6][12] <= new_maps[6][12]; new_maps[6][13] <= new_maps[6][13]; new_maps[6][14] <= new_maps[7][12]; new_maps[6][15] <= new_maps[7][13];
				new_maps[7][12] <= new_maps[6][14]; new_maps[7][13] <= new_maps[6][15]; new_maps[7][14] <= new_maps[7][14]; new_maps[7][15] <= new_maps[7][15];

				// --- Block (2,0) : Rows 8-11, Cols 0-3 ---
				new_maps[8][0] <= new_maps[8][0]; new_maps[8][1] <= new_maps[8][1]; new_maps[8][2] <= new_maps[9][0]; new_maps[8][3] <= new_maps[9][1];
				new_maps[9][0] <= new_maps[8][2]; new_maps[9][1] <= new_maps[8][3]; new_maps[9][2] <= new_maps[9][2]; new_maps[9][3] <= new_maps[9][3];
				new_maps[10][0] <= new_maps[10][0]; new_maps[10][1] <= new_maps[10][1]; new_maps[10][2] <= new_maps[11][0]; new_maps[10][3] <= new_maps[11][1];
				new_maps[11][0] <= new_maps[10][2]; new_maps[11][1] <= new_maps[10][3]; new_maps[11][2] <= new_maps[11][2]; new_maps[11][3] <= new_maps[11][3];

				// --- Block (2,1) : Rows 8-11, Cols 4-7 ---
				new_maps[8][4] <= new_maps[8][4]; new_maps[8][5] <= new_maps[8][5]; new_maps[8][6] <= new_maps[9][4]; new_maps[8][7] <= new_maps[9][5];
				new_maps[9][4] <= new_maps[8][6]; new_maps[9][5] <= new_maps[8][7]; new_maps[9][6] <= new_maps[9][6]; new_maps[9][7] <= new_maps[9][7];
				new_maps[10][4] <= new_maps[10][4]; new_maps[10][5] <= new_maps[10][5]; new_maps[10][6] <= new_maps[11][4]; new_maps[10][7] <= new_maps[11][5];
				new_maps[11][4] <= new_maps[10][6]; new_maps[11][5] <= new_maps[10][7]; new_maps[11][6] <= new_maps[11][6]; new_maps[11][7] <= new_maps[11][7];

				// --- Block (2,2) : Rows 8-11, Cols 8-11 ---
				new_maps[8][8] <= new_maps[8][8]; new_maps[8][9] <= new_maps[8][9]; new_maps[8][10] <= new_maps[9][8]; new_maps[8][11] <= new_maps[9][9];
				new_maps[9][8] <= new_maps[8][10]; new_maps[9][9] <= new_maps[8][11]; new_maps[9][10] <= new_maps[9][10]; new_maps[9][11] <= new_maps[9][11];
				new_maps[10][8] <= new_maps[10][8]; new_maps[10][9] <= new_maps[10][9]; new_maps[10][10] <= new_maps[11][8]; new_maps[10][11] <= new_maps[11][9];
				new_maps[11][8] <= new_maps[10][10]; new_maps[11][9] <= new_maps[10][11]; new_maps[11][10] <= new_maps[11][10]; new_maps[11][11] <= new_maps[11][11];

				// --- Block (2,3) : Rows 8-11, Cols 12-15 ---
				new_maps[8][12] <= new_maps[8][12]; new_maps[8][13] <= new_maps[8][13]; new_maps[8][14] <= new_maps[9][12]; new_maps[8][15] <= new_maps[9][13];
				new_maps[9][12] <= new_maps[8][14]; new_maps[9][13] <= new_maps[8][15]; new_maps[9][14] <= new_maps[9][14]; new_maps[9][15] <= new_maps[9][15];
				new_maps[10][12] <= new_maps[10][12]; new_maps[10][13] <= new_maps[10][13]; new_maps[10][14] <= new_maps[11][12]; new_maps[10][15] <= new_maps[11][13];
				new_maps[11][12] <= new_maps[10][14]; new_maps[11][13] <= new_maps[10][15]; new_maps[11][14] <= new_maps[11][14]; new_maps[11][15] <= new_maps[11][15];

				// --- Block (3,0) : Rows 12-15, Cols 0-3 ---
				new_maps[12][0] <= new_maps[12][0]; new_maps[12][1] <= new_maps[12][1]; new_maps[12][2] <= new_maps[13][0]; new_maps[12][3] <= new_maps[13][1];
				new_maps[13][0] <= new_maps[12][2]; new_maps[13][1] <= new_maps[12][3]; new_maps[13][2] <= new_maps[13][2]; new_maps[13][3] <= new_maps[13][3];
				new_maps[14][0] <= new_maps[14][0]; new_maps[14][1] <= new_maps[14][1]; new_maps[14][2] <= new_maps[15][0]; new_maps[14][3] <= new_maps[15][1];
				new_maps[15][0] <= new_maps[14][2]; new_maps[15][1] <= new_maps[14][3]; new_maps[15][2] <= new_maps[15][2]; new_maps[15][3] <= new_maps[15][3];

				// --- Block (3,1) : Rows 12-15, Cols 4-7 ---
				new_maps[12][4] <= new_maps[12][4]; new_maps[12][5] <= new_maps[12][5]; new_maps[12][6] <= new_maps[13][4]; new_maps[12][7] <= new_maps[13][5];
				new_maps[13][4] <= new_maps[12][6]; new_maps[13][5] <= new_maps[12][7]; new_maps[13][6] <= new_maps[13][6]; new_maps[13][7] <= new_maps[13][7];
				new_maps[14][4] <= new_maps[14][4]; new_maps[14][5] <= new_maps[14][5]; new_maps[14][6] <= new_maps[15][4]; new_maps[14][7] <= new_maps[15][5];
				new_maps[15][4] <= new_maps[14][6]; new_maps[15][5] <= new_maps[14][7]; new_maps[15][6] <= new_maps[15][6]; new_maps[15][7] <= new_maps[15][7];

				// --- Block (3,2) : Rows 12-15, Cols 8-11 ---
				new_maps[12][8] <= new_maps[12][8]; new_maps[12][9] <= new_maps[12][9]; new_maps[12][10] <= new_maps[13][8]; new_maps[12][11] <= new_maps[13][9];
				new_maps[13][8] <= new_maps[12][10]; new_maps[13][9] <= new_maps[12][11]; new_maps[13][10] <= new_maps[13][10]; new_maps[13][11] <= new_maps[13][11];
				new_maps[14][8] <= new_maps[14][8]; new_maps[14][9] <= new_maps[14][9]; new_maps[14][10] <= new_maps[15][8]; new_maps[14][11] <= new_maps[15][9];
				new_maps[15][8] <= new_maps[14][10]; new_maps[15][9] <= new_maps[14][11]; new_maps[15][10] <= new_maps[15][10]; new_maps[15][11] <= new_maps[15][11];

				// --- Block (3,3) : Rows 12-15, Cols 12-15 ---
				new_maps[12][12] <= new_maps[12][12]; new_maps[12][13] <= new_maps[12][13]; new_maps[12][14] <= new_maps[13][12]; new_maps[12][15] <= new_maps[13][13];
				new_maps[13][12] <= new_maps[12][14]; new_maps[13][13] <= new_maps[12][15]; new_maps[13][14] <= new_maps[13][14]; new_maps[13][15] <= new_maps[13][15];
				new_maps[14][12] <= new_maps[14][12]; new_maps[14][13] <= new_maps[14][13]; new_maps[14][14] <= new_maps[15][12]; new_maps[14][15] <= new_maps[15][13];
				new_maps[15][12] <= new_maps[14][14]; new_maps[15][13] <= new_maps[14][15]; new_maps[15][14] <= new_maps[15][14]; new_maps[15][15] <= new_maps[15][15];
			end
			4'b1111 : begin // 8X8 Morton
				// ------------------------------------------------------------------------------------------------
				//  Block (0,0) : Rows 0-7, Cols 0-7
				// ------------------------------------------------------------------------------------------------
				// Row 0 V
				new_maps[0][0] <= new_maps[0][0]; new_maps[0][1] <= new_maps[0][1]; new_maps[0][2] <= new_maps[1][0]; new_maps[0][3] <= new_maps[1][1];
				new_maps[0][4] <= new_maps[0][2]; new_maps[0][5] <= new_maps[0][3]; new_maps[0][6] <= new_maps[1][2]; new_maps[0][7] <= new_maps[1][3];
				// Row 1
				new_maps[1][0] <= new_maps[2][0]; new_maps[1][1] <= new_maps[2][1]; new_maps[1][2] <= new_maps[3][0]; new_maps[1][3] <= new_maps[3][1];
				new_maps[1][4] <= new_maps[2][2]; new_maps[1][5] <= new_maps[2][3]; new_maps[1][6] <= new_maps[3][2]; new_maps[1][7] <= new_maps[3][3];
				// Row 2
				new_maps[2][0] <= new_maps[0][4]; new_maps[2][1] <= new_maps[0][5]; new_maps[2][2] <= new_maps[1][4]; new_maps[2][3] <= new_maps[1][5];
				new_maps[2][4] <= new_maps[0][6]; new_maps[2][5] <= new_maps[0][7]; new_maps[2][6] <= new_maps[1][6]; new_maps[2][7] <= new_maps[1][7];
				// Row 3
				new_maps[3][0] <= new_maps[2][4]; new_maps[3][1] <= new_maps[2][5]; new_maps[3][2] <= new_maps[3][4]; new_maps[3][3] <= new_maps[3][5];
				new_maps[3][4] <= new_maps[2][6]; new_maps[3][5] <= new_maps[2][7]; new_maps[3][6] <= new_maps[3][6]; new_maps[3][7] <= new_maps[3][7];
				// Row 4
				new_maps[4][0] <= new_maps[4][0]; new_maps[4][1] <= new_maps[4][1]; new_maps[4][2] <= new_maps[5][0]; new_maps[4][3] <= new_maps[5][1];
				new_maps[4][4] <= new_maps[4][2]; new_maps[4][5] <= new_maps[4][3]; new_maps[4][6] <= new_maps[5][2]; new_maps[4][7] <= new_maps[5][3];
				// Row 5
				new_maps[5][0] <= new_maps[6][0]; new_maps[5][1] <= new_maps[6][1]; new_maps[5][2] <= new_maps[7][0]; new_maps[5][3] <= new_maps[7][1];
				new_maps[5][4] <= new_maps[6][2]; new_maps[5][5] <= new_maps[6][3]; new_maps[5][6] <= new_maps[7][2]; new_maps[5][7] <= new_maps[7][3];
				// Row 6
				new_maps[6][0] <= new_maps[4][4]; new_maps[6][1] <= new_maps[4][5]; new_maps[6][2] <= new_maps[5][4]; new_maps[6][3] <= new_maps[5][5];
				new_maps[6][4] <= new_maps[4][6]; new_maps[6][5] <= new_maps[4][7]; new_maps[6][6] <= new_maps[5][6]; new_maps[6][7] <= new_maps[5][7];
				// Row 7
				new_maps[7][0] <= new_maps[6][4]; new_maps[7][1] <= new_maps[6][5]; new_maps[7][2] <= new_maps[7][4]; new_maps[7][3] <= new_maps[7][5];
				new_maps[7][4] <= new_maps[6][6]; new_maps[7][5] <= new_maps[6][7]; new_maps[7][6] <= new_maps[7][6]; new_maps[7][7] <= new_maps[7][7];

				// ------------------------------------------------------------------------------------------------
				//  Block (0,1) : Rows 0-7, Cols 8-15
				// ------------------------------------------------------------------------------------------------
				// Row 0
				new_maps[0][8] <= new_maps[0][8]; new_maps[0][9] <= new_maps[0][9]; new_maps[0][10] <= new_maps[1][8]; new_maps[0][11] <= new_maps[1][9];
				new_maps[0][12] <= new_maps[0][10]; new_maps[0][13] <= new_maps[0][11]; new_maps[0][14] <= new_maps[1][10]; new_maps[0][15] <= new_maps[1][11];
				// Row 1
				new_maps[1][8] <= new_maps[2][8]; new_maps[1][9] <= new_maps[2][9]; new_maps[1][10] <= new_maps[3][8]; new_maps[1][11] <= new_maps[3][9];
				new_maps[1][12] <= new_maps[2][10]; new_maps[1][13] <= new_maps[2][11]; new_maps[1][14] <= new_maps[3][10]; new_maps[1][15] <= new_maps[3][11];
				// Row 2
				new_maps[2][8] <= new_maps[0][12]; new_maps[2][9] <= new_maps[0][13]; new_maps[2][10] <= new_maps[1][12]; new_maps[2][11] <= new_maps[1][13];
				new_maps[2][12] <= new_maps[0][14]; new_maps[2][13] <= new_maps[0][15]; new_maps[2][14] <= new_maps[1][14]; new_maps[2][15] <= new_maps[1][15];
				// Row 3
				new_maps[3][8] <= new_maps[2][12]; new_maps[3][9] <= new_maps[2][13]; new_maps[3][10] <= new_maps[3][12]; new_maps[3][11] <= new_maps[3][13];
				new_maps[3][12] <= new_maps[2][14]; new_maps[3][13] <= new_maps[2][15]; new_maps[3][14] <= new_maps[3][14]; new_maps[3][15] <= new_maps[3][15];
				// Row 4
				new_maps[4][8] <= new_maps[4][8]; new_maps[4][9] <= new_maps[4][9]; new_maps[4][10] <= new_maps[5][8]; new_maps[4][11] <= new_maps[5][9];
				new_maps[4][12] <= new_maps[4][10]; new_maps[4][13] <= new_maps[4][11]; new_maps[4][14] <= new_maps[5][10]; new_maps[4][15] <= new_maps[5][11];
				// Row 5
				new_maps[5][8] <= new_maps[6][8]; new_maps[5][9] <= new_maps[6][9]; new_maps[5][10] <= new_maps[7][8]; new_maps[5][11] <= new_maps[7][9];
				new_maps[5][12] <= new_maps[6][10]; new_maps[5][13] <= new_maps[6][11]; new_maps[5][14] <= new_maps[7][10]; new_maps[5][15] <= new_maps[7][11];
				// Row 6
				new_maps[6][8] <= new_maps[4][12]; new_maps[6][9] <= new_maps[4][13]; new_maps[6][10] <= new_maps[5][12]; new_maps[6][11] <= new_maps[5][13];
				new_maps[6][12] <= new_maps[4][14]; new_maps[6][13] <= new_maps[4][15]; new_maps[6][14] <= new_maps[5][14]; new_maps[6][15] <= new_maps[5][15];
				// Row 7
				new_maps[7][8] <= new_maps[6][12]; new_maps[7][9] <= new_maps[6][13]; new_maps[7][10] <= new_maps[7][12]; new_maps[7][11] <= new_maps[7][13];
				new_maps[7][12] <= new_maps[6][14]; new_maps[7][13] <= new_maps[6][15]; new_maps[7][14] <= new_maps[7][14]; new_maps[7][15] <= new_maps[7][15];

				// ------------------------------------------------------------------------------------------------
				//  Block (1,0) : Rows 8-15, Cols 0-7
				// ------------------------------------------------------------------------------------------------
				// Row 8
				new_maps[8][0] <= new_maps[8][0]; new_maps[8][1] <= new_maps[8][1]; new_maps[8][2] <= new_maps[9][0]; new_maps[8][3] <= new_maps[9][1];
				new_maps[8][4] <= new_maps[8][2]; new_maps[8][5] <= new_maps[8][3]; new_maps[8][6] <= new_maps[9][2]; new_maps[8][7] <= new_maps[9][3];
				// Row 9
				new_maps[9][0] <= new_maps[10][0]; new_maps[9][1] <= new_maps[10][1]; new_maps[9][2] <= new_maps[11][0]; new_maps[9][3] <= new_maps[11][1];
				new_maps[9][4] <= new_maps[10][2]; new_maps[9][5] <= new_maps[10][3]; new_maps[9][6] <= new_maps[11][2]; new_maps[9][7] <= new_maps[11][3];
				// Row 10
				new_maps[10][0] <= new_maps[8][4]; new_maps[10][1] <= new_maps[8][5]; new_maps[10][2] <= new_maps[9][4]; new_maps[10][3] <= new_maps[9][5];
				new_maps[10][4] <= new_maps[8][6]; new_maps[10][5] <= new_maps[8][7]; new_maps[10][6] <= new_maps[9][6]; new_maps[10][7] <= new_maps[9][7];
				// Row 11
				new_maps[11][0] <= new_maps[10][4]; new_maps[11][1] <= new_maps[10][5]; new_maps[11][2] <= new_maps[11][4]; new_maps[11][3] <= new_maps[11][5];
				new_maps[11][4] <= new_maps[10][6]; new_maps[11][5] <= new_maps[10][7]; new_maps[11][6] <= new_maps[11][6]; new_maps[11][7] <= new_maps[11][7];
				// Row 12
				new_maps[12][0] <= new_maps[12][0]; new_maps[12][1] <= new_maps[12][1]; new_maps[12][2] <= new_maps[13][0]; new_maps[12][3] <= new_maps[13][1];
				new_maps[12][4] <= new_maps[12][2]; new_maps[12][5] <= new_maps[12][3]; new_maps[12][6] <= new_maps[13][2]; new_maps[12][7] <= new_maps[13][3];
				// Row 13
				new_maps[13][0] <= new_maps[14][0]; new_maps[13][1] <= new_maps[14][1]; new_maps[13][2] <= new_maps[15][0]; new_maps[13][3] <= new_maps[15][1];
				new_maps[13][4] <= new_maps[14][2]; new_maps[13][5] <= new_maps[14][3]; new_maps[13][6] <= new_maps[15][2]; new_maps[13][7] <= new_maps[15][3];
				// Row 14
				new_maps[14][0] <= new_maps[12][4]; new_maps[14][1] <= new_maps[12][5]; new_maps[14][2] <= new_maps[13][4]; new_maps[14][3] <= new_maps[13][5];
				new_maps[14][4] <= new_maps[12][6]; new_maps[14][5] <= new_maps[12][7]; new_maps[14][6] <= new_maps[13][6]; new_maps[14][7] <= new_maps[13][7];
				// Row 15
				new_maps[15][0] <= new_maps[14][4]; new_maps[15][1] <= new_maps[14][5]; new_maps[15][2] <= new_maps[15][4]; new_maps[15][3] <= new_maps[15][5];
				new_maps[15][4] <= new_maps[14][6]; new_maps[15][5] <= new_maps[14][7]; new_maps[15][6] <= new_maps[15][6]; new_maps[15][7] <= new_maps[15][7];

				// ------------------------------------------------------------------------------------------------
				//  Block (1,1) : Rows 8-15, Cols 8-15
				// ------------------------------------------------------------------------------------------------
				// Row 8
				new_maps[8][8] <= new_maps[8][8]; new_maps[8][9] <= new_maps[8][9]; new_maps[8][10] <= new_maps[9][8]; new_maps[8][11] <= new_maps[9][9];
				new_maps[8][12] <= new_maps[8][10]; new_maps[8][13] <= new_maps[8][11]; new_maps[8][14] <= new_maps[9][10]; new_maps[8][15] <= new_maps[9][11];
				// Row 9
				new_maps[9][8] <= new_maps[10][8]; new_maps[9][9] <= new_maps[10][9]; new_maps[9][10] <= new_maps[11][8]; new_maps[9][11] <= new_maps[11][9];
				new_maps[9][12] <= new_maps[10][10]; new_maps[9][13] <= new_maps[10][11]; new_maps[9][14] <= new_maps[11][10]; new_maps[9][15] <= new_maps[11][11];
				// Row 10
				new_maps[10][8] <= new_maps[8][12]; new_maps[10][9] <= new_maps[8][13]; new_maps[10][10] <= new_maps[9][12]; new_maps[10][11] <= new_maps[9][13];
				new_maps[10][12] <= new_maps[8][14]; new_maps[10][13] <= new_maps[8][15]; new_maps[10][14] <= new_maps[9][14]; new_maps[10][15] <= new_maps[9][15];
				// Row 11
				new_maps[11][8] <= new_maps[10][12]; new_maps[11][9] <= new_maps[10][13]; new_maps[11][10] <= new_maps[11][12]; new_maps[11][11] <= new_maps[11][13];
				new_maps[11][12] <= new_maps[10][14]; new_maps[11][13] <= new_maps[10][15]; new_maps[11][14] <= new_maps[11][14]; new_maps[11][15] <= new_maps[11][15];
				// Row 12
				new_maps[12][8] <= new_maps[12][8]; new_maps[12][9] <= new_maps[12][9]; new_maps[12][10] <= new_maps[13][8]; new_maps[12][11] <= new_maps[13][9];
				new_maps[12][12] <= new_maps[12][10]; new_maps[12][13] <= new_maps[12][11]; new_maps[12][14] <= new_maps[13][10]; new_maps[12][15] <= new_maps[13][11];
				// Row 13
				new_maps[13][8] <= new_maps[14][8]; new_maps[13][9] <= new_maps[14][9]; new_maps[13][10] <= new_maps[15][8]; new_maps[13][11] <= new_maps[15][9];
				new_maps[13][12] <= new_maps[14][10]; new_maps[13][13] <= new_maps[14][11]; new_maps[13][14] <= new_maps[15][10]; new_maps[13][15] <= new_maps[15][11];
				// Row 14
				new_maps[14][8] <= new_maps[12][12]; new_maps[14][9] <= new_maps[12][13]; new_maps[14][10] <= new_maps[13][12]; new_maps[14][11] <= new_maps[13][13];
				new_maps[14][12] <= new_maps[12][14]; new_maps[14][13] <= new_maps[12][15]; new_maps[14][14] <= new_maps[13][14]; new_maps[14][15] <= new_maps[13][15];
				// Row 15
				new_maps[15][8] <= new_maps[14][12]; new_maps[15][9] <= new_maps[14][13]; new_maps[15][10] <= new_maps[15][12]; new_maps[15][11] <= new_maps[15][13];
				new_maps[15][12] <= new_maps[14][14]; new_maps[15][13] <= new_maps[14][15]; new_maps[15][14] <= new_maps[15][14]; new_maps[15][15] <= new_maps[15][15];
			end
		endcase
end

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/* 
  There are eight SRAMs in your GTE. You should not change the name of those SRAMs.
  TA will check the value in each SRAMs when your GTE is not busy.
  If you change the name of SRAMs below, you must get the fail in this lab.
  
  You should finish SRAM-related signals assignments for each SRAM.
*/
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// SRAM-related signals assignments
reg [11:0] addr_mem_select [0:7];

always @(*) begin
	if((input_cnt < 15'd4096) && (current_state == INPUT))  begin
		addr_mem_select[0] = input_cnt[11:0];
	end
	else if ( (current_state == WAIT_IN) && (ms <= 15) ) 
		addr_mem_select[0] = calu_cnt + 256*ms;
	else if ((current_state == WAIT_OUT) && (md <= 15) && (sram_out_cnt > 0) )
		addr_mem_select[0] = sram_cnt_pipe + 256*md;
	else begin
		addr_mem_select[0] = 12'd0; // read
	end
end

always @(*) begin
	if((input_cnt >= 15'd4096) && (input_cnt < 15'd8192) && (current_state == INPUT))  begin
		addr_mem_select[1] = input_cnt[11:0] - 'd4096;
	end
	else if ( (current_state == WAIT_IN) && (ms > 15) && (ms <= 31) ) 
		addr_mem_select[1] = calu_cnt + 256 * (ms-16);
	else if ((current_state == WAIT_OUT) && (md > 15) && (md <= 31) && (sram_out_cnt > 0) )
		addr_mem_select[1] = sram_cnt_pipe + 256 * (md-16);
	else begin
		addr_mem_select[1] = 12'd0;// read
	end
end

always @(*) begin
	if((input_cnt >= 15'd8192) && (input_cnt < 15'd12288) && (current_state == INPUT))  begin
		addr_mem_select[2] = input_cnt[11:0] - 'd8192;
	end
	else if ( (current_state == WAIT_IN) && (ms > 31) && (ms <= 47) ) 
		addr_mem_select[2] = calu_cnt + 256 * (ms-32);
	else if ((current_state == WAIT_OUT) && (md > 31) && (md <= 47) && (sram_out_cnt > 0) )
		addr_mem_select[2] = sram_cnt_pipe + 256 * (md-32);
	else begin
		addr_mem_select[2] = 12'd0;// read
	end
end

always @(*) begin
	if((input_cnt >= 15'd12288) && (input_cnt < 15'd16384) && (current_state == INPUT))  begin
		addr_mem_select[3] = input_cnt[11:0] - 'd12288;
	end
	else if ( (current_state == WAIT_IN) && (ms > 47) && (ms <= 63) ) 
		addr_mem_select[3] = calu_cnt + 256 * (ms-48);
	else if ((current_state == WAIT_OUT) && (md > 47) && (md <= 63) && (sram_out_cnt > 0) )
		addr_mem_select[3] = sram_cnt_pipe + 256 * (md-48);
	else begin
		addr_mem_select[3] = 12'd0;// read
	end
end

always @(*) begin
	if((input_cnt >= 15'd16384) && (input_cnt < 15'd20480) && (current_state == INPUT))  begin
		addr_mem_select[4] = input_cnt[11:1] - 'd8192;
	end
	else if ( (current_state == WAIT_IN) && (ms > 63) && (ms <= 79) ) 
		addr_mem_select[4] = calu_cnt + 128 * (ms-64);
	else if ((current_state == WAIT_OUT) && (md > 63) && (md <= 79) && (sram_out_cnt > 0) )
		addr_mem_select[4] = sram_cnt_pipe + 128 * (md-64);
	else begin
		addr_mem_select[4] = 11'd0;// read
	end
end

always @(*) begin
	if((input_cnt >= 15'd20480) && (input_cnt < 15'd24576) && (current_state == INPUT))  begin
		addr_mem_select[5] = input_cnt[11:1] - 'd10240;
	end
	else if ( (current_state == WAIT_IN) && (ms > 79) && (ms <= 95) ) 
		addr_mem_select[5] = calu_cnt + 128 * (ms-80);
	else if ((current_state == WAIT_OUT) && (md > 79) && (md <= 95) && (sram_out_cnt > 0) )
		addr_mem_select[5] = sram_cnt_pipe + 128 * (md-80);
	else begin
		addr_mem_select[5] = 11'd0;// read
	end
end

always @(*) begin
	if((input_cnt >= 15'd24576) && (input_cnt < 15'd28672) && (current_state == INPUT))  begin
		addr_mem_select[6] = input_cnt[11:2] - 'd6144;
	end
	else if ( (current_state == WAIT_IN) && (ms > 95) && (ms <= 111) ) 
		addr_mem_select[6] = calu_cnt + 64 * (ms-96); 
	else if ((current_state == WAIT_OUT) && (md > 95) && (md <= 111) && (sram_out_cnt > 0) )
		addr_mem_select[6] = sram_cnt_pipe + 64 * (md-96);
	else begin
		addr_mem_select[6] = 10'd0;// read
	end
end

always @(*) begin
	if((input_cnt >= 15'd28672) && (input_cnt < 16'd32768) && (current_state == INPUT))  begin
		addr_mem_select[7] = input_cnt[11:2] - 'd7168;
	end
	else if ( (current_state == WAIT_IN) && (ms > 111) && (ms <= 127) ) 
		addr_mem_select[7] = calu_cnt + 64 * (ms-112);
	else if ((current_state == WAIT_OUT) && (md > 111) && (md <= 127) && (sram_out_cnt > 0) )
		addr_mem_select[7] = sram_cnt_pipe + 64 * (md-112);
	else begin
		addr_mem_select[7] = 10'd0;// read
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		data_reg <= 8'd0;
	else if (in_valid_data)
		data_reg <= data;
	else if(current_state == WAIT_OUT)
		data_reg <= pixel_out_0; 
	else
		data_reg <= data_reg;
end


reg [15:0] data_16  ; 
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		data_16 <= 16'd0;
	else if (in_valid_data) begin
		if (input_cnt[0])
			data_16 <= {data , data_16[7:0]};
		else
			data_16 <= {data_16[15:8], data};
	end
	else if (current_state == WAIT_OUT )
		data_16 <= {pixel_out_1 , pixel_out_0};
	else 
		data_16 <= data_16;
end

reg [31:0] data_32 ; 
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n)
		data_32 <= 32'd0;
	else if (in_valid_data) begin
		case (input_cnt[1:0])
			2'b11: data_32 <= {data , data_32[23:0]};
			2'b00: data_32 <= {data_32[31:24], data , data_32[15:0]};
			2'b01: data_32 <= {data_32[31:16], data , data_32[7:0]};
			2'b10: data_32 <= {data_32[31:8], data};
		endcase
	end
	else if (current_state == WAIT_OUT )
		data_32 <= {pixel_out_3,pixel_out_2,pixel_out_1 , pixel_out_0};
	else 
		data_32 <= data_32;
end

//MARK:Memory
wire   mem0_target = (current_state == WAIT_OUT) && (md <= 15) && (sram_out_cnt>0);
assign mem0_addr = addr_mem_select[0];
assign mem0_web  = !(input_cnt < 15'd4096 && (current_state == INPUT) || mem0_target) ;
assign mem0_din  = data_reg;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem0_dout_reg <= 8'd0;
	else		mem0_dout_reg <= mem0_dout;
end

wire   mem1_target = (current_state == WAIT_OUT) && (md > 15) && (md <= 31) && (sram_out_cnt>0);
assign mem1_addr = addr_mem_select[1];
assign mem1_web  = !((input_cnt >= 15'd4096) && (input_cnt < 15'd8192) || (mem1_target));
assign mem1_din  = data_reg;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem1_dout_reg <= 8'd0;
	else		mem1_dout_reg <= mem1_dout;
end

wire   mem2_target = (current_state == WAIT_OUT) && (md > 31) && (md <= 47) && (sram_out_cnt>0);
assign mem2_addr =	addr_mem_select[2];
assign mem2_web  = !((input_cnt >= 15'd8192) && (input_cnt < 15'd12288) || (mem2_target));
assign mem2_din  = data_reg;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem2_dout_reg <= 8'd0;
	else		mem2_dout_reg <= mem2_dout;
end

wire   mem3_target = (current_state == WAIT_OUT) && (md > 47) && (md <= 63) && (sram_out_cnt>0);
assign mem3_addr = addr_mem_select[3];
assign mem3_web  = !((input_cnt >= 15'd12288 )&& (input_cnt < 15'd16384) || mem3_target);
assign mem3_din  = data_reg;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem3_dout_reg <= 8'd0;
	else		mem3_dout_reg <= mem3_dout;
end

wire   mem4_target = (current_state == WAIT_OUT) && (md > 63) && (md <= 79) && (sram_out_cnt>0);
assign mem4_addr = addr_mem_select[4];
assign mem4_web  = !((input_cnt >= 15'd16384) && (input_cnt < 15'd20480) || mem4_target);
assign mem4_din  = data_16 ;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem4_dout_reg <= 16'd0;
	else		mem4_dout_reg <= mem4_dout;
end

wire   mem5_target = (current_state == WAIT_OUT) && (md > 79) && (md <= 95) && (sram_out_cnt>0);
assign mem5_addr = addr_mem_select[5];
assign mem5_web  = !((input_cnt >= 15'd20480) && (input_cnt < 15'd24576) || mem5_target);
assign mem5_din  = data_16;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem5_dout_reg <= 16'd0;
	else		mem5_dout_reg <= mem5_dout;
end

wire   mem6_target = (current_state == WAIT_OUT) && (md > 95) && (md <= 111) && (sram_out_cnt>0);
assign mem6_addr = addr_mem_select[6];
assign mem6_web  = !((input_cnt >= 15'd24576) && (input_cnt < 15'd28672) || mem6_target);
assign mem6_din  = data_32;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem6_dout_reg <= 32'd0;
	else		mem6_dout_reg <= mem6_dout;
end

wire   mem7_target = (current_state == WAIT_OUT) && (md > 111) && (md <= 127) && (sram_out_cnt>0);
assign mem7_addr = addr_mem_select[7];
assign mem7_web  = !((input_cnt >= 15'd28672) && (input_cnt < 16'd32768) || mem7_target);
assign mem7_din  = data_32;
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) mem7_dout_reg <= 32'd0;
	else		mem7_dout_reg <= mem7_dout;
end

// MEM_0, MEM_1, MEM_2, MEM_3, MEM_4, MEM_5, MEM_6, MEM_7 instantiation
SUMA180_4096X8X1BM4 MEM0(
    .A0(mem0_addr[0]), .A1(mem0_addr[1]), .A2(mem0_addr[2]), .A3(mem0_addr[3]), .A4(mem0_addr[4]), .A5(mem0_addr[5]), .A6(mem0_addr[6]), .A7(mem0_addr[7]), 
    .A8(mem0_addr[8]), .A9(mem0_addr[9]), .A10(mem0_addr[10]), .A11(mem0_addr[11]),
    .DO0(mem0_dout[0]), .DO1(mem0_dout[1]), .DO2(mem0_dout[2]), .DO3(mem0_dout[3]), .DO4(mem0_dout[4]), .DO5(mem0_dout[5]), .DO6(mem0_dout[6]), .DO7(mem0_dout[7]),
    .DI0(mem0_din[0]), .DI1(mem0_din[1]), .DI2(mem0_din[2]), .DI3(mem0_din[3]), .DI4(mem0_din[4]), .DI5(mem0_din[5]), .DI6(mem0_din[6]), .DI7(mem0_din[7]),
    .CK(clk), .WEB(mem0_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_4096X8X1BM4 MEM1(
    .A0(mem1_addr[0]), .A1(mem1_addr[1]), .A2(mem1_addr[2]), .A3(mem1_addr[3]), .A4(mem1_addr[4]), .A5(mem1_addr[5]), .A6(mem1_addr[6]), .A7(mem1_addr[7]), 
    .A8(mem1_addr[8]), .A9(mem1_addr[9]), .A10(mem1_addr[10]), .A11(mem1_addr[11]),
    .DO0(mem1_dout[0]), .DO1(mem1_dout[1]), .DO2(mem1_dout[2]), .DO3(mem1_dout[3]), .DO4(mem1_dout[4]), .DO5(mem1_dout[5]), .DO6(mem1_dout[6]), .DO7(mem1_dout[7]),
    .DI0(mem1_din[0]), .DI1(mem1_din[1]), .DI2(mem1_din[2]), .DI3(mem1_din[3]), .DI4(mem1_din[4]), .DI5(mem1_din[5]), .DI6(mem1_din[6]), .DI7(mem1_din[7]),
    .CK(clk), .WEB(mem1_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_4096X8X1BM4 MEM2 (
    .A0(mem2_addr[0]), .A1(mem2_addr[1]), .A2(mem2_addr[2]), .A3(mem2_addr[3]), .A4(mem2_addr[4]), .A5(mem2_addr[5]), .A6(mem2_addr[6]), .A7(mem2_addr[7]),
    .A8(mem2_addr[8]), .A9(mem2_addr[9]), .A10(mem2_addr[10]), .A11(mem2_addr[11]),
    .DO0(mem2_dout[0]), .DO1(mem2_dout[1]), .DO2(mem2_dout[2]), .DO3(mem2_dout[3]), .DO4(mem2_dout[4]), .DO5(mem2_dout[5]), .DO6(mem2_dout[6]), .DO7(mem2_dout[7]),
    .DI0(mem2_din[0]), .DI1(mem2_din[1]), .DI2(mem2_din[2]), .DI3(mem2_din[3]), .DI4(mem2_din[4]), .DI5(mem2_din[5]), .DI6(mem2_din[6]), .DI7(mem2_din[7]),
    .CK(clk), .WEB(mem2_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_4096X8X1BM4 MEM3(
    .A0(mem3_addr[0]), .A1(mem3_addr[1]), .A2(mem3_addr[2]), .A3(mem3_addr[3]), .A4(mem3_addr[4]), .A5(mem3_addr[5]), .A6(mem3_addr[6]), .A7(mem3_addr[7]), 
    .A8(mem3_addr[8]), .A9(mem3_addr[9]), .A10(mem3_addr[10]), .A11(mem3_addr[11]),
    .DO0(mem3_dout[0]), .DO1(mem3_dout[1]), .DO2(mem3_dout[2]), .DO3(mem3_dout[3]), .DO4(mem3_dout[4]), .DO5(mem3_dout[5]), .DO6(mem3_dout[6]), .DO7(mem3_dout[7]),
    .DI0(mem3_din[0]), .DI1(mem3_din[1]), .DI2(mem3_din[2]), .DI3(mem3_din[3]), .DI4(mem3_din[4]), .DI5(mem3_din[5]), .DI6(mem3_din[6]), .DI7(mem3_din[7]),
    .CK(clk), .WEB(mem3_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_2048X16X1BM1 MEM4(
	.A0(mem4_addr[0]), .A1(mem4_addr[1]), .A2(mem4_addr[2]), .A3(mem4_addr[3]), .A4(mem4_addr[4]), .A5(mem4_addr[5]), .A6(mem4_addr[6]), .A7(mem4_addr[7]), 
	.A8(mem4_addr[8]), .A9(mem4_addr[9]), .A10(mem4_addr[10]),
	.DO0(mem4_dout[0]), .DO1(mem4_dout[1]), .DO2(mem4_dout[2]), .DO3(mem4_dout[3]), .DO4(mem4_dout[4]), .DO5(mem4_dout[5]), .DO6(mem4_dout[6]), .DO7(mem4_dout[7]), 
	.DO8(mem4_dout[8]), .DO9(mem4_dout[9]), .DO10(mem4_dout[10]), .DO11(mem4_dout[11]), .DO12(mem4_dout[12]), .DO13(mem4_dout[13]), .DO14(mem4_dout[14]), .DO15(mem4_dout[15]),
	.DI0(mem4_din[0]), .DI1(mem4_din[1]), .DI2(mem4_din[2]), .DI3(mem4_din[3]), .DI4(mem4_din[4]), .DI5(mem4_din[5]), .DI6(mem4_din[6]), .DI7(mem4_din[7]), 
	.DI8(mem4_din[8]), .DI9(mem4_din[9]), .DI10(mem4_din[10]), .DI11(mem4_din[11]), .DI12(mem4_din[12]), .DI13(mem4_din[13]), .DI14(mem4_din[14]), .DI15(mem4_din[15]),
	.CK(clk), .WEB(mem4_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_2048X16X1BM1 MEM5(
	.A0(mem5_addr[0]), .A1(mem5_addr[1]), .A2(mem5_addr[2]), .A3(mem5_addr[3]), .A4(mem5_addr[4]), .A5(mem5_addr[5]), .A6(mem5_addr[6]), .A7(mem5_addr[7]), 
	.A8(mem5_addr[8]), .A9(mem5_addr[9]), .A10(mem5_addr[10]),
	.DO0(mem5_dout[0]), .DO1(mem5_dout[1]), .DO2(mem5_dout[2]), .DO3(mem5_dout[3]), .DO4(mem5_dout[4]), .DO5(mem5_dout[5]), .DO6(mem5_dout[6]), .DO7(mem5_dout[7]), 
	.DO8(mem5_dout[8]), .DO9(mem5_dout[9]), .DO10(mem5_dout[10]), .DO11(mem5_dout[11]), .DO12(mem5_dout[12]), .DO13(mem5_dout[13]), .DO14(mem5_dout[14]), .DO15(mem5_dout[15]),
	.DI0(mem5_din[0]), .DI1(mem5_din[1]), .DI2(mem5_din[2]), .DI3(mem5_din[3]), .DI4(mem5_din[4]), .DI5(mem5_din[5]), .DI6(mem5_din[6]), .DI7(mem5_din[7]), 
	.DI8(mem5_din[8]), .DI9(mem5_din[9]), .DI10(mem5_din[10]), .DI11(mem5_din[11]), .DI12(mem5_din[12]), .DI13(mem5_din[13]), .DI14(mem5_din[14]), .DI15(mem5_din[15]),
	.CK(clk), .WEB(mem5_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_1024X32X1BM2 MEM6(
	.A0(mem6_addr[0]), .A1(mem6_addr[1]), .A2(mem6_addr[2]), .A3(mem6_addr[3]), .A4(mem6_addr[4]), .A5(mem6_addr[5]), .A6(mem6_addr[6]), .A7(mem6_addr[7]), 
	.A8(mem6_addr[8]), .A9(mem6_addr[9]),
	.DO0(mem6_dout[0]), .DO1(mem6_dout[1]), .DO2(mem6_dout[2]), .DO3(mem6_dout[3]), .DO4(mem6_dout[4]), .DO5(mem6_dout[5]), .DO6(mem6_dout[6]), .DO7(mem6_dout[7]), 
	.DO8(mem6_dout[8]), .DO9(mem6_dout[9]), .DO10(mem6_dout[10]), .DO11(mem6_dout[11]), .DO12(mem6_dout[12]), .DO13(mem6_dout[13]), .DO14(mem6_dout[14]), .DO15(mem6_dout[15]), 
	.DO16(mem6_dout[16]), .DO17(mem6_dout[17]), .DO18(mem6_dout[18]), .DO19(mem6_dout[19]), .DO20(mem6_dout[20]), .DO21(mem6_dout[21]), .DO22(mem6_dout[22]), .DO23(mem6_dout[23]), 
	.DO24(mem6_dout[24]), .DO25(mem6_dout[25]), .DO26(mem6_dout[26]), .DO27(mem6_dout[27]), .DO28(mem6_dout[28]), .DO29(mem6_dout[29]), .DO30(mem6_dout[30]), .DO31(mem6_dout[31]),
	.DI0(mem6_din[0]), .DI1(mem6_din[1]), .DI2(mem6_din[2]), .DI3(mem6_din[3]), .DI4(mem6_din[4]), .DI5(mem6_din[5]), .DI6(mem6_din[6]), .DI7(mem6_din[7]), 
	.DI8(mem6_din[8]), .DI9(mem6_din[9]), .DI10(mem6_din[10]), .DI11(mem6_din[11]), .DI12(mem6_din[12]), .DI13(mem6_din[13]), .DI14(mem6_din[14]), .DI15(mem6_din[15]), 
	.DI16(mem6_din[16]), .DI17(mem6_din[17]), .DI18(mem6_din[18]), .DI19(mem6_din[19]), .DI20(mem6_din[20]), .DI21(mem6_din[21]), .DI22(mem6_din[22]), .DI23(mem6_din[23]), 
	.DI24(mem6_din[24]), .DI25(mem6_din[25]), .DI26(mem6_din[26]), .DI27(mem6_din[27]), .DI28(mem6_din[28]), .DI29(mem6_din[29]), .DI30(mem6_din[30]), .DI31(mem6_din[31]),
	.CK(clk), .WEB(mem6_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_1024X32X1BM2 MEM7(
	.A0(mem7_addr[0]), .A1(mem7_addr[1]), .A2(mem7_addr[2]), .A3(mem7_addr[3]), .A4(mem7_addr[4]), .A5(mem7_addr[5]), .A6(mem7_addr[6]), .A7(mem7_addr[7]), 
	.A8(mem7_addr[8]), .A9(mem7_addr[9]),
	.DO0(mem7_dout[0]), .DO1(mem7_dout[1]), .DO2(mem7_dout[2]), .DO3(mem7_dout[3]), .DO4(mem7_dout[4]), .DO5(mem7_dout[5]), .DO6(mem7_dout[6]), .DO7(mem7_dout[7]), 
	.DO8(mem7_dout[8]), .DO9(mem7_dout[9]), .DO10(mem7_dout[10]), .DO11(mem7_dout[11]), .DO12(mem7_dout[12]), .DO13(mem7_dout[13]), .DO14(mem7_dout[14]), .DO15(mem7_dout[15]), 
	.DO16(mem7_dout[16]), .DO17(mem7_dout[17]), .DO18(mem7_dout[18]), .DO19(mem7_dout[19]), .DO20(mem7_dout[20]), .DO21(mem7_dout[21]), .DO22(mem7_dout[22]), .DO23(mem7_dout[23]), 
	.DO24(mem7_dout[24]), .DO25(mem7_dout[25]), .DO26(mem7_dout[26]), .DO27(mem7_dout[27]), .DO28(mem7_dout[28]), .DO29(mem7_dout[29]), .DO30(mem7_dout[30]), .DO31(mem7_dout[31]),
	.DI0(mem7_din[0]), .DI1(mem7_din[1]), .DI2(mem7_din[2]), .DI3(mem7_din[3]), .DI4(mem7_din[4]), .DI5(mem7_din[5]), .DI6(mem7_din[6]), .DI7(mem7_din[7]), 
	.DI8(mem7_din[8]), .DI9(mem7_din[9]), .DI10(mem7_din[10]), .DI11(mem7_din[11]), .DI12(mem7_din[12]), .DI13(mem7_din[13]), .DI14(mem7_din[14]), .DI15(mem7_din[15]), 
	.DI16(mem7_din[16]), .DI17(mem7_din[17]), .DI18(mem7_din[18]), .DI19(mem7_din[19]), .DI20(mem7_din[20]), .DI21(mem7_din[21]), .DI22(mem7_din[22]), .DI23(mem7_din[23]), 
	.DI24(mem7_din[24]), .DI25(mem7_din[25]), .DI26(mem7_din[26]), .DI27(mem7_din[27]), .DI28(mem7_din[28]), .DI29(mem7_din[29]), .DI30(mem7_din[30]), .DI31(mem7_din[31]),
	.CK(clk), .WEB(mem7_web), .OE(1'b1), .CS(1'b1)
);

endmodule

// Cycle: 20.00
// Area: 2769433.502030
// Performance: 55388670.04060000

// Cycle: 10.00
// Area: 2768524.185246
// Performance: 27685241.85246000

// Cycle: 8.00
// Area: 2768605.430018
// Performance: 22148843.44014400

// Cycle: 5.00
// Area: 2775798.719512
// Performance: 13878993.59756000

// Cycle: 4.20 //03 have problem
// Area: 2797503.580322
// Performance: 11749515.03735240

// Cycle: 4.70
// Area: 2784720.023751
// Performance: 13088184.11162970

// Cycle: 6.00  
// Area: 2770145.956401
// Performance: 16620875.73840600

// Cycle: 5.50
// Area: 2770945.905182
// Performance: 15240202.47850100

// Cycle: 5.00   //****************
// Area: 2775798.719512
// Performance: 13878993.59756000

// Cycle: 4.50 //03 have problem
// Area: 2791560.210836
// Performance: 12562020.94876200

// Cycle: 4.70 //03 have problem
// Area: 2784720.023751
// Performance: 13088184.11162970

// Cycle: 4.90 //****************
// Area: 2772802.036368
// Performance: 13586729.97820320

// Cycle: 4.80  -> 6.0 to APR
// Area: 2778998.514935
// Performance: 13339192.87168800

// Cycle: 6.00
// Area: 2770402.190019
// Performance: 16622413.14011400

//================================================================================
//remove new_maps rst_n ***************
// Cycle: 4.80
// Area: 2770217.827980
// Performance: 13297045.57430400

//================================================================================
//remove mem_dout_reg rst_n
