module CNN(
    // Input Port
    clk,
    rst_n,
    in_valid,
    Image,
    Kernel_ch1,
    Kernel_ch2,
	Weight_Bias,
    task_number,
    mode,
    capacity_cost,
    // Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter (You can't modify these parameters)
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
//state
parameter IDLE   = 0;
parameter INPUT  = 1;
parameter WAIT   = 2;
parameter OUTPUT = 3;
integer i,j;
//---------------------------------------------------------------------
//   IO PORT
//--------------------------------------------------------------------

input           clk, rst_n, in_valid;
input   [31:0]  Image;
input   [31:0]  Kernel_ch1;
input   [31:0]  Kernel_ch2;
input   [31:0]  Weight_Bias;
input           task_number;
input   [1:0]   mode;
input   [3:0]   capacity_cost;
output  reg         out_valid;
output  reg [31:0]  out;

//---------------------------------------------------------------------
//   input Reg
//---------------------------------------------------------------------
reg task_reg;
reg  [1:0] mode_comb;
reg  [3:0] capacity_cost_reg;
reg  [inst_sig_width+inst_exp_width : 0] Img_comb;
reg  [inst_sig_width+inst_exp_width : 0] Kernel_ch1_comb;
reg  [inst_sig_width+inst_exp_width : 0] Kernel_ch2_comb;
reg  [inst_sig_width+inst_exp_width : 0] Weight_comb;

//---------------------------------------------------------------------
//   Output Reg
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width : 0] out_comb;
reg out_valid_comb;
//---------------------------------------------------------------------
//   Reg
//---------------------------------------------------------------------
reg [1:0]state,nstate;
reg [inst_sig_width+inst_exp_width :0] img_ch1[7:0][7:0];
reg [inst_sig_width+inst_exp_width :0] img_ch2[7:0][7:0];
reg [inst_sig_width+inst_exp_width :0] img_ch1_comb[7:0][7:0];
reg [inst_sig_width+inst_exp_width :0] img_ch2_comb[7:0][7:0];

reg [inst_sig_width+inst_exp_width :0] K1_1[2:0][2:0];
reg [inst_sig_width+inst_exp_width :0] K1_2[2:0][2:0];
// reg [inst_sig_width+inst_exp_width :0] K1_1_comb[2:0][2:0];
// reg [inst_sig_width+inst_exp_width :0] K1_2_comb[2:0][2:0];

reg [inst_sig_width+inst_exp_width :0] K2_1[2:0][2:0];
reg [inst_sig_width+inst_exp_width :0] K2_2[2:0][2:0];

reg [inst_sig_width+inst_exp_width :0] partial_1_1[5:0][5:0];
reg [inst_sig_width+inst_exp_width :0] partial_1_2[5:0][5:0];

reg [inst_sig_width+inst_exp_width :0] partial_2_1[5:0][5:0];
reg [inst_sig_width+inst_exp_width :0] partial_2_2[5:0][5:0];

reg [inst_sig_width+inst_exp_width :0] add1_1,add1_2;
// reg [inst_sig_width+inst_exp_width :0] add2_1,add2_2;

reg [inst_sig_width+inst_exp_width :0] out_ch1[5:0][5:0]; 
reg [inst_sig_width+inst_exp_width :0] out_ch2[5:0][5:0]; 
reg [inst_sig_width+inst_exp_width :0] findmax_temp [8:0];

reg [inst_sig_width+inst_exp_width :0] pooling_ch1[1:0][1:0];
reg [inst_sig_width+inst_exp_width :0] pooling_ch2[1:0][1:0];

reg [inst_sig_width+inst_exp_width :0] activation_ch1[1:0][1:0];
reg [inst_sig_width+inst_exp_width :0] activation_ch2[1:0][1:0];

reg [inst_sig_width+inst_exp_width :0] FC_layer1[4:0];

reg [inst_sig_width+inst_exp_width :0] activation_leaky[4:0];

reg [inst_sig_width+inst_exp_width :0] FC_layer2[2:0];
reg [inst_sig_width+inst_exp_width :0] FC_layer2_pipe [2:0];

reg [inst_sig_width+inst_exp_width :0] softmax_exp_out [2:0];

reg [inst_sig_width+inst_exp_width :0] Weight_layer1[7:0][4:0];
reg [inst_sig_width+inst_exp_width :0] Weight_layer2[4:0][2:0];
reg [inst_sig_width+inst_exp_width :0] bias_layer1;
reg [inst_sig_width+inst_exp_width :0] bias_layer2;
//------task1---------
reg [3:0] costA, costB, costC, costD,capacity;
reg [inst_sig_width+inst_exp_width :0] resultA, resultB, resultC, resultD;
reg [inst_sig_width+inst_exp_width :0] task1_out;
reg [4:0] task1_count;
wire [2:0] negetive_number;
//---------------------------------------------------------------------
//   Counter
//---------------------------------------------------------------------
reg [1:0] outcount;
reg [7:0] count; //limit 222 (150+72

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) count <=0;
    else if (state == IDLE) count <=0;
    else count<=count+1;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) outcount <=0;
    else if (state == OUTPUT) outcount<=outcount+1;
    else outcount <=0;
end

//---------------------------------------------------------------------
//   taskdone controller
//---------------------------------------------------------------------
reg task0_done, task1_done ;
reg task0_out_done;

always @(*) begin
    if(outcount==2  && task_reg==0) task0_out_done=1;
    else task0_out_done=0;
end

always @(*) begin
    if(count==169   && task_reg==0) task0_done=1;
    else task0_done=0;
end

always @(*) begin
    // if(count==155+task1_count || count==156+task1_count   && task_reg==1) task1_done=1;
    if((count==170 || count==171 )  && task_reg==1) task1_done=1;
    else task1_done=0;
end
//---------------------------------------------------------------------
//  FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) state <= IDLE;
    else state <= nstate;
end

always @(*) begin
    case (state)
        IDLE   : nstate =  (in_valid)                      ?  INPUT : state;
        INPUT  : nstate =  (in_valid)                      ?  state : WAIT ;
        WAIT   : nstate =  (task0_done || task1_done)      ?  OUTPUT: state;
        OUTPUT : nstate =  (task0_out_done || task1_done)  ?  IDLE  : state; //maybe can change (count==2 || task1_done)
        default: nstate = state;
    endcase 
end
//---------------------------------------------------------------------
//   Image input and padding
//---------------------------------------------------------------------
always @(posedge clk ) begin //img_ch1
    for(i=1; i<=6 ; i=i+1) begin
        for(j=1 ; j<=6 ; j=j+1) begin
            img_ch1[i][j] <=img_ch1_comb[i][j];
        end
    end  
        if(mode_comb[1]==0) begin
            img_ch1[0][0]<=img_ch1_comb[1][1];  img_ch1[0][1]<=img_ch1_comb[1][1];  img_ch1[0][2]<=img_ch1_comb[1][2];  img_ch1[0][3]<=img_ch1_comb[1][3];  img_ch1[0][4]<=img_ch1_comb[1][4];  img_ch1[0][5]<=img_ch1_comb[1][5];  img_ch1[0][6]<=img_ch1_comb[1][6]; img_ch1[0][7]<=img_ch1_comb[1][6];
            img_ch1[1][0]<=img_ch1_comb[1][1];                                                                                                                                                                                                                         img_ch1[1][7]<=img_ch1_comb[1][6]; 
            img_ch1[2][0]<=img_ch1_comb[2][1];                                                                                                                                                                                                                         img_ch1[2][7]<=img_ch1_comb[2][6];
            img_ch1[3][0]<=img_ch1_comb[3][1];                                                                                                                                                                                                                         img_ch1[3][7]<=img_ch1_comb[3][6];
            img_ch1[4][0]<=img_ch1_comb[4][1];                                                                                                                                                                                                                         img_ch1[4][7]<=img_ch1_comb[4][6];
            img_ch1[5][0]<=img_ch1_comb[5][1];                                                                                                                                                                                                                         img_ch1[5][7]<=img_ch1_comb[5][6];
            img_ch1[6][0]<=img_ch1_comb[6][1];                                                                                                                                                                                                                         img_ch1[6][7]<=img_ch1_comb[6][6];
            img_ch1[7][0]<=img_ch1_comb[6][1];  img_ch1[7][1]<=img_ch1_comb[6][1];  img_ch1[7][2]<=img_ch1_comb[6][2];  img_ch1[7][3]<=img_ch1_comb[6][3];  img_ch1[7][4]<=img_ch1_comb[6][4];  img_ch1[7][5]<=img_ch1_comb[6][5];  img_ch1[7][6]<=img_ch1_comb[6][6]; img_ch1[7][7]<=img_ch1_comb[6][6];
        end
        else begin
            img_ch1[0][0]<=img_ch1_comb[2][2];  img_ch1[0][1]<=img_ch1_comb[2][1];  img_ch1[0][2]<=img_ch1_comb[2][2];  img_ch1[0][3]<=img_ch1_comb[2][3];  img_ch1[0][4]<=img_ch1_comb[2][4];  img_ch1[0][5]<=img_ch1_comb[2][5];  img_ch1[0][6]<=img_ch1_comb[2][6]; img_ch1[0][7]<=img_ch1_comb[2][5];
            img_ch1[1][0]<=img_ch1_comb[1][2];                                                                                                                                                                                                                         img_ch1[1][7]<=img_ch1_comb[1][5]; 
            img_ch1[2][0]<=img_ch1_comb[2][2];                                                                                                                                                                                                                         img_ch1[2][7]<=img_ch1_comb[2][5];
            img_ch1[3][0]<=img_ch1_comb[3][2];                                                                                                                                                                                                                         img_ch1[3][7]<=img_ch1_comb[3][5];
            img_ch1[4][0]<=img_ch1_comb[4][2];                                                                                                                                                                                                                         img_ch1[4][7]<=img_ch1_comb[4][5];
            img_ch1[5][0]<=img_ch1_comb[5][2];                                                                                                                                                                                                                         img_ch1[5][7]<=img_ch1_comb[5][5];
            img_ch1[6][0]<=img_ch1_comb[6][2];                                                                                                                                                                                                                         img_ch1[6][7]<=img_ch1_comb[6][5];
            img_ch1[7][0]<=img_ch1_comb[5][2];  img_ch1[7][1]<=img_ch1_comb[5][1];  img_ch1[7][2]<=img_ch1_comb[5][2];  img_ch1[7][3]<=img_ch1_comb[5][3];  img_ch1[7][4]<=img_ch1_comb[5][4];  img_ch1[7][5]<=img_ch1_comb[5][5];  img_ch1[7][6]<=img_ch1_comb[5][6]; img_ch1[7][7]<=img_ch1_comb[5][5];
        end
end

always @(posedge clk ) begin //img_ch2
    if(task_reg==0) begin
        for(i=1; i<=6 ; i=i+1) begin
            for(j=1 ; j<=6 ; j=j+1) begin
                img_ch2[i][j] <=img_ch2_comb[i][j];
            end
        end  
        if(mode_comb[1]==0) begin
            img_ch2[0][0]<=img_ch2_comb[1][1];  img_ch2[0][1]<=img_ch2_comb[1][1];  img_ch2[0][2]<=img_ch2_comb[1][2];  img_ch2[0][3]<=img_ch2_comb[1][3];  img_ch2[0][4]<=img_ch2_comb[1][4];  img_ch2[0][5]<=img_ch2_comb[1][5];  img_ch2[0][6]<=img_ch2_comb[1][6]; img_ch2[0][7]<=img_ch2_comb[1][6];
            img_ch2[1][0]<=img_ch2_comb[1][1];                                                                                                                                                                                                                         img_ch2[1][7]<=img_ch2_comb[1][6]; 
            img_ch2[2][0]<=img_ch2_comb[2][1];                                                                                                                                                                                                                         img_ch2[2][7]<=img_ch2_comb[2][6];
            img_ch2[3][0]<=img_ch2_comb[3][1];                                                                                                                                                                                                                         img_ch2[3][7]<=img_ch2_comb[3][6];
            img_ch2[4][0]<=img_ch2_comb[4][1];                                                                                                                                                                                                                         img_ch2[4][7]<=img_ch2_comb[4][6];
            img_ch2[5][0]<=img_ch2_comb[5][1];                                                                                                                                                                                                                         img_ch2[5][7]<=img_ch2_comb[5][6];
            img_ch2[6][0]<=img_ch2_comb[6][1];                                                                                                                                                                                                                         img_ch2[6][7]<=img_ch2_comb[6][6];
            img_ch2[7][0]<=img_ch2_comb[6][1];  img_ch2[7][1]<=img_ch2_comb[6][1];  img_ch2[7][2]<=img_ch2_comb[6][2];  img_ch2[7][3]<=img_ch2_comb[6][3];  img_ch2[7][4]<=img_ch2_comb[6][4];  img_ch2[7][5]<=img_ch2_comb[6][5];  img_ch2[7][6]<=img_ch2_comb[6][6]; img_ch2[7][7]<=img_ch2_comb[6][6];
        end
        else begin
            img_ch2[0][0]<=img_ch2_comb[2][2];  img_ch2[0][1]<=img_ch2_comb[2][1];  img_ch2[0][2]<=img_ch2_comb[2][2];  img_ch2[0][3]<=img_ch2_comb[2][3];  img_ch2[0][4]<=img_ch2_comb[2][4];  img_ch2[0][5]<=img_ch2_comb[2][5];  img_ch2[0][6]<=img_ch2_comb[2][6]; img_ch2[0][7]<=img_ch2_comb[2][5];
            img_ch2[1][0]<=img_ch2_comb[1][2];                                                                                                                                                                                                                         img_ch2[1][7]<=img_ch2_comb[1][5]; 
            img_ch2[2][0]<=img_ch2_comb[2][2];                                                                                                                                                                                                                         img_ch2[2][7]<=img_ch2_comb[2][5];
            img_ch2[3][0]<=img_ch2_comb[3][2];                                                                                                                                                                                                                         img_ch2[3][7]<=img_ch2_comb[3][5];
            img_ch2[4][0]<=img_ch2_comb[4][2];                                                                                                                                                                                                                         img_ch2[4][7]<=img_ch2_comb[4][5];
            img_ch2[5][0]<=img_ch2_comb[5][2];                                                                                                                                                                                                                         img_ch2[5][7]<=img_ch2_comb[5][5];
            img_ch2[6][0]<=img_ch2_comb[6][2];                                                                                                                                                                                                                         img_ch2[6][7]<=img_ch2_comb[6][5];
            img_ch2[7][0]<=img_ch2_comb[5][2];  img_ch2[7][1]<=img_ch2_comb[5][1];  img_ch2[7][2]<=img_ch2_comb[5][2];  img_ch2[7][3]<=img_ch2_comb[5][3];  img_ch2[7][4]<=img_ch2_comb[5][4];  img_ch2[7][5]<=img_ch2_comb[5][5];  img_ch2[7][6]<=img_ch2_comb[5][6]; img_ch2[7][7]<=img_ch2_comb[5][5];
        end
    end
    else
        for(i=0; i<=7 ; i=i+1) begin
            for(j=0 ; j<=7 ; j=j+1) begin
                img_ch2[i][j] <=0;
            end
        end  
end

always @(*) begin
    for(i=0; i<=7 ; i=i+1) 
        for(j=0 ; j<=7 ; j=j+1) begin
            img_ch1_comb[i][j] =img_ch1[i][j];
        end
    if(state == INPUT && count<36) begin
        img_ch1_comb[1+((count)/6)][1+((count)%6)] = Img_comb;
    end else if (state == IDLE) begin
        for(i=0; i<=7 ; i=i+1) begin
            for(j=0 ; j<=7 ; j=j+1) begin
                img_ch1_comb[i][j] = 0;
            end
        end  
    end
end

always @(*) begin
    for(i=0; i<=7 ; i=i+1) 
        for(j=0 ; j<=7 ; j=j+1) begin
            img_ch2_comb[i][j] =img_ch2[i][j]; 
        end
    if (state == INPUT && count>=36 && count<72 && task_reg==0) begin
        img_ch2_comb[1+((count-36)/6)][1+((count-36)%6)] = Img_comb;
    end else if (state == IDLE) begin
        for(i=0; i<=7 ; i=i+1) begin
            for(j=0 ; j<=7 ; j=j+1) begin
                img_ch2_comb[i][j] = 0;
            end
        end  
    end
end
//---------------------------------------------------------------------
//   Kernel input 
//---------------------------------------------------------------------
always @(posedge clk) begin //K1 reset
    if(state == IDLE) begin
        for(i=0; i<=2 ; i=i+1) begin
            for(j=0 ; j<=2 ; j=j+1) begin
                K1_1[i][j] <=0;
            end
        end 
    end else if ( count<9 ) begin
        K1_1[0][0] <=K1_1[0][1];    K1_1[0][1] <=K1_1[0][2];   K1_1[0][2] <=K1_1[1][0];
        K1_1[1][0] <=K1_1[1][1];    K1_1[1][1] <=K1_1[1][2];   K1_1[1][2] <=K1_1[2][0];
        K1_1[2][0] <=K1_1[2][1];    K1_1[2][1] <=K1_1[2][2];   K1_1[2][2] <=Kernel_ch1_comb;
    end
end 

always @(posedge clk) begin //K1 reset
    if(state == IDLE) begin
        for(i=0; i<=2 ; i=i+1) begin
            for(j=0 ; j<=2 ; j=j+1) begin
                K1_2[i][j] <=0;
            end
        end 
    end else if (count<18 &&  count>=9 ) begin
        K1_2[0][0] <=K1_2[0][1];    K1_2[0][1] <=K1_2[0][2];   K1_2[0][2] <=K1_2[1][0];
        K1_2[1][0] <=K1_2[1][1];    K1_2[1][1] <=K1_2[1][2];   K1_2[1][2] <=K1_2[2][0];
        K1_2[2][0] <=K1_2[2][1];    K1_2[2][1] <=K1_2[2][2];   K1_2[2][2] <=Kernel_ch1_comb;
    end
end 

always @(posedge clk) begin //K2 reset
    if(state == IDLE) begin
        for(i=0; i<=2 ; i=i+1) begin
            for(j=0 ; j<=2 ; j=j+1) begin
                K2_1[i][j] <=0;
            end
        end 
    end else if ( count<9 ) begin
        K2_1[0][0] <=K2_1[0][1];    K2_1[0][1] <=K2_1[0][2];   K2_1[0][2] <=K2_1[1][0];
        K2_1[1][0] <=K2_1[1][1];    K2_1[1][1] <=K2_1[1][2];   K2_1[1][2] <=K2_1[2][0];
        K2_1[2][0] <=K2_1[2][1];    K2_1[2][1] <=K2_1[2][2];   K2_1[2][2] <=Kernel_ch2_comb;
    end
end 

always @(posedge clk) begin //K2 reset
    if(state == IDLE) begin
        for(i=0; i<=2 ; i=i+1) begin
            for(j=0 ; j<=2 ; j=j+1) begin
                K2_2[i][j] <=0;
            end
        end 
    end else if (count<18 &&  count>=9 ) begin
        K2_2[0][0] <=K2_2[0][1];    K2_2[0][1] <=K2_2[0][2];   K2_2[0][2] <=K2_2[1][0];
        K2_2[1][0] <=K2_2[1][1];    K2_2[1][1] <=K2_2[1][2];   K2_2[1][2] <=K2_2[2][0];
        K2_2[2][0] <=K2_2[2][1];    K2_2[2][1] <=K2_2[2][2];   K2_2[2][2] <=Kernel_ch2_comb;
    end
end 

//---------------------------------------------------------------------
//   Weight input 
//---------------------------------------------------------------------
always @(posedge clk) begin //weight reset
    if(state == INPUT && count<40)begin //maybe need add task_reg ==0 
        Weight_layer1[7][4] <= Weight_comb;           Weight_layer1[6][4] <= Weight_layer1[7][4];  Weight_layer1[5][4]<= Weight_layer1[6][4]; 
        Weight_layer1[4][4] <= Weight_layer1[5][4];   Weight_layer1[3][4] <= Weight_layer1[4][4];  Weight_layer1[2][4]<= Weight_layer1[3][4];
        Weight_layer1[1][4] <= Weight_layer1[2][4];   Weight_layer1[0][4] <= Weight_layer1[1][4];
        Weight_layer1[7][3] <= Weight_layer1[0][4];   Weight_layer1[6][3] <= Weight_layer1[7][3];  Weight_layer1[5][3]<= Weight_layer1[6][3];
        Weight_layer1[4][3] <= Weight_layer1[5][3];   Weight_layer1[3][3] <= Weight_layer1[4][3];  Weight_layer1[2][3]<= Weight_layer1[3][3];
        Weight_layer1[1][3] <= Weight_layer1[2][3];   Weight_layer1[0][3] <= Weight_layer1[1][3];
        Weight_layer1[7][2] <= Weight_layer1[0][3];   Weight_layer1[6][2] <= Weight_layer1[7][2];  Weight_layer1[5][2]<= Weight_layer1[6][2];
        Weight_layer1[4][2] <= Weight_layer1[5][2];   Weight_layer1[3][2] <= Weight_layer1[4][2];  Weight_layer1[2][2]<= Weight_layer1[3][2];
        Weight_layer1[1][2] <= Weight_layer1[2][2];   Weight_layer1[0][2] <= Weight_layer1[1][2];
        Weight_layer1[7][1] <= Weight_layer1[0][2];   Weight_layer1[6][1] <= Weight_layer1[7][1];  Weight_layer1[5][1]<= Weight_layer1[6][1];
        Weight_layer1[4][1] <= Weight_layer1[5][1];   Weight_layer1[3][1] <= Weight_layer1[4][1];  Weight_layer1[2][1]<= Weight_layer1[3][1];
        Weight_layer1[1][1] <= Weight_layer1[2][1];   Weight_layer1[0][1] <= Weight_layer1[1][1];
        Weight_layer1[7][0] <= Weight_layer1[0][1];   Weight_layer1[6][0] <= Weight_layer1[7][0];  Weight_layer1[5][0]<= Weight_layer1[6][0];
        Weight_layer1[4][0] <= Weight_layer1[5][0];   Weight_layer1[3][0] <= Weight_layer1[4][0];  Weight_layer1[2][0]<= Weight_layer1[3][0];
        Weight_layer1[1][0] <= Weight_layer1[2][0];   Weight_layer1[0][0] <= Weight_layer1[1][0];
    end else if (state == IDLE) begin
        for(i=0; i<=7 ; i=i+1) begin
            for(j=0 ; j<=4 ; j=j+1) begin
                Weight_layer1[i][j] <= 0;
            end
        end  
    end
end 
always @(posedge clk) begin
    if( count==40) //maybe can cancel state == INPUT
        bias_layer1 <= Weight_comb;
    else if (state == IDLE) 
        bias_layer1 <= 0;
    else 
        bias_layer1 <= bias_layer1;
end 

always @(posedge clk) begin //weight reset
    if(state == INPUT && count<56 && count>40)begin
        Weight_layer2[4][2] <= Weight_comb;         Weight_layer2[3][2] <= Weight_layer2[4][2]; Weight_layer2[2][2]<= Weight_layer2[3][2];
        Weight_layer2[1][2] <= Weight_layer2[2][2]; Weight_layer2[0][2] <= Weight_layer2[1][2];
        Weight_layer2[4][1] <= Weight_layer2[0][2]; Weight_layer2[3][1] <= Weight_layer2[4][1]; Weight_layer2[2][1]<= Weight_layer2[3][1];
        Weight_layer2[1][1] <= Weight_layer2[2][1]; Weight_layer2[0][1] <= Weight_layer2[1][1];
        Weight_layer2[4][0] <= Weight_layer2[0][1]; Weight_layer2[3][0] <= Weight_layer2[4][0]; Weight_layer2[2][0]<= Weight_layer2[3][0];
        Weight_layer2[1][0] <= Weight_layer2[2][0]; Weight_layer2[0][0] <= Weight_layer2[1][0];

    end else if (state == IDLE) begin
        for(i=0; i<=4 ; i=i+1) begin
            for(j=0 ; j<=2 ; j=j+1) begin
                Weight_layer2[i][j] <= 0;
            end
        end  
    end
end 

always @(posedge clk) begin
    if( count==56)
        bias_layer2 <= Weight_comb;
    else if (state == IDLE) 
        bias_layer2 <= 0;
    else
        bias_layer2 <= bias_layer2;
end 

//---------------------------------------------------------------------
// Convolution and Fully Connection (Multiple) and *0.01
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width :0] mul1 ,mul2 ,mul3 ,mul4,mul5 ,mul6 ,mul7 ,mul8 , mul9;
reg [inst_sig_width+inst_exp_width :0] mulk1,mulk2,mulk3,mulk4,mulk5,mulk6,mulk7,mulk8 ,mulk9;


always @(*) begin
    if(count>8 && count<45 ) begin
        mul1 = img_ch1 [(count-9)/6]     [(count-9)%6];
        mul2 = img_ch1 [(count-9)/6]     [((count-9)%6)+1];
        mul3 = img_ch1 [((count-9)/6)]   [((count-9)%6)+2];
        mul4 = img_ch1 [((count-9)/6)+1] [(count-9)%6];
        mul5 = img_ch1 [((count-9)/6)+1] [((count-9)%6)+1];
        mul6 = img_ch1 [((count-9)/6)+1] [((count-9)%6)+2];
        mul7 = img_ch1 [((count-9)/6)+2] [(count-9)%6];
        mul8 = img_ch1 [((count-9)/6)+2] [((count-9)%6)+1];
        mul9 = img_ch1 [((count-9)/6)+2] [((count-9)%6)+2];
    end 
    else if(count>44 && count<81 ) begin
        if(task_reg==0) begin
            mul1 = img_ch2 [(count-45)/6]     [(count-45)%6];
            mul2 = img_ch2 [(count-45)/6]     [((count-45)%6)+1];
            mul3 = img_ch2 [((count-45)/6)]   [((count-45)%6)+2];
            mul4 = img_ch2 [((count-45)/6)+1] [(count-45)%6];
            mul5 = img_ch2 [((count-45)/6)+1] [((count-45)%6)+1];
            mul6 = img_ch2 [((count-45)/6)+1] [((count-45)%6)+2];
            mul7 = img_ch2 [((count-45)/6)+2] [(count-45)%6];
            mul8 = img_ch2 [((count-45)/6)+2] [((count-45)%6)+1];
            mul9 = img_ch2 [((count-45)/6)+2] [((count-45)%6)+2];
        end
        else begin
            mul1 = img_ch1 [(count-45)/6]     [(count-45)%6];
            mul2 = img_ch1 [(count-45)/6]     [((count-45)%6)+1];
            mul3 = img_ch1 [((count-45)/6)]   [((count-45)%6)+2];
            mul4 = img_ch1 [((count-45)/6)+1] [(count-45)%6];
            mul5 = img_ch1 [((count-45)/6)+1] [((count-45)%6)+1];
            mul6 = img_ch1 [((count-45)/6)+1] [((count-45)%6)+2];
            mul7 = img_ch1 [((count-45)/6)+2] [(count-45)%6];
            mul8 = img_ch1 [((count-45)/6)+2] [((count-45)%6)+1];
            mul9 = img_ch1 [((count-45)/6)+2] [((count-45)%6)+2];
        end
    end 
    else if(count>80 && count<117) begin
        mul1 = img_ch1 [(count-81)/6]     [(count-81)%6];
        mul2 = img_ch1 [(count-81)/6]     [((count-81)%6)+1];
        mul3 = img_ch1 [((count-81)/6)]   [((count-81)%6)+2];
        mul4 = img_ch1 [((count-81)/6)+1] [(count-81)%6];
        mul5 = img_ch1 [((count-81)/6)+1] [((count-81)%6)+1];
        mul6 = img_ch1 [((count-81)/6)+1] [((count-81)%6)+2];
        mul7 = img_ch1 [((count-81)/6)+2] [(count-81)%6];
        mul8 = img_ch1 [((count-81)/6)+2] [((count-81)%6)+1];
        mul9 = img_ch1 [((count-81)/6)+2] [((count-81)%6)+2];
    end
    else if (count>116 && count<153) begin
        if(task_reg==0) begin
            mul1 = img_ch2 [(count-117)/6]     [(count-117)%6];
            mul2 = img_ch2 [(count-117)/6]     [((count-117)%6)+1];
            mul3 = img_ch2 [((count-117)/6)]   [((count-117)%6)+2];
            mul4 = img_ch2 [((count-117)/6)+1] [(count-117)%6];
            mul5 = img_ch2 [((count-117)/6)+1] [((count-117)%6)+1];
            mul6 = img_ch2 [((count-117)/6)+1] [((count-117)%6)+2];
            mul7 = img_ch2 [((count-117)/6)+2] [(count-117)%6];
            mul8 = img_ch2 [((count-117)/6)+2] [((count-117)%6)+1];
            mul9 = img_ch2 [((count-117)/6)+2] [((count-117)%6)+2];
        end
        else begin
            mul1 = img_ch1 [(count-117)/6]     [(count-117)%6];
            mul2 = img_ch1 [(count-117)/6]     [((count-117)%6)+1];
            mul3 = img_ch1 [((count-117)/6)]   [((count-117)%6)+2];
            mul4 = img_ch1 [((count-117)/6)+1] [(count-117)%6];
            mul5 = img_ch1 [((count-117)/6)+1] [((count-117)%6)+1];
            mul6 = img_ch1 [((count-117)/6)+1] [((count-117)%6)+2];
            mul7 = img_ch1 [((count-117)/6)+2] [(count-117)%6];
            mul8 = img_ch1 [((count-117)/6)+2] [((count-117)%6)+1];
            mul9 = img_ch1 [((count-117)/6)+2] [((count-117)%6)+2];
        end
    end
    else if (count>156 && count <162) begin
        mul1 = activation_ch1[0][0]; mul2 = activation_ch1[0][1]; mul3 = activation_ch1[1][0]; 
        mul4 = activation_ch1[1][1]; mul5 = activation_ch2[0][0]; mul6 = activation_ch2[0][1];
        mul7 = activation_ch2[1][0]; mul8 = activation_ch2[1][1]; mul9 = FC_layer1[4];
    end
    else if (count == 162) begin
        mul1=0;  mul2=0;  mul3=0;  mul4=0;  mul5=0;  mul6=0;  mul7=0;  mul8=0;
        mul9 = FC_layer1[4];
    end 
    else if (count >163 && count < 167) begin
        mul1 = activation_leaky[0]; mul2 = activation_leaky[1]; mul3 = activation_leaky[2];
        mul4 = activation_leaky[3]; mul5 = activation_leaky[4]; mul6= 0;
        mul7 = 0; mul8 = 0; mul9 = 0;
    end else begin
        mul1 = 0; mul2 = 0; mul3 = 0; mul4 = 0; mul5 = 0; mul6= 0; mul7 = 0; mul8 = 0; mul9 = 0;
    end
end

always @(*) begin
    if(count>8 && count<45 ) begin
        mulk1 = K1_1 [0][0];     mulk2 = K1_1 [0][1];     mulk3 = K1_1 [0][2];
        mulk4 = K1_1 [1][0];     mulk5 = K1_1 [1][1];     mulk6 = K1_1 [1][2];
        mulk7 = K1_1 [2][0];     mulk8 = K1_1 [2][1];     mulk9 = K1_1 [2][2];
    end 
    else if(count>44 && count<81 ) begin
        mulk1 = K1_2 [0][0];     mulk2 = K1_2 [0][1];     mulk3 = K1_2 [0][2];
        mulk4 = K1_2 [1][0];     mulk5 = K1_2 [1][1];     mulk6 = K1_2 [1][2];
        mulk7 = K1_2 [2][0];     mulk8 = K1_2 [2][1];     mulk9 = K1_2 [2][2];
    end 
    else if(count>80 && count<117) begin
        mulk1 = K2_1 [0][0];     mulk2 = K2_1 [0][1];     mulk3 = K2_1 [0][2];
        mulk4 = K2_1 [1][0];     mulk5 = K2_1 [1][1];     mulk6 = K2_1 [1][2];
        mulk7 = K2_1 [2][0];     mulk8 = K2_1 [2][1];     mulk9 = K2_1 [2][2];
    end
    else if (count>116 && count<153) begin
        mulk1 = K2_2 [0][0];     mulk2 = K2_2 [0][1];     mulk3 = K2_2 [0][2];
        mulk4 = K2_2 [1][0];     mulk5 = K2_2 [1][1];     mulk6 = K2_2 [1][2];
        mulk7 = K2_2 [2][0];     mulk8 = K2_2 [2][1];     mulk9 = K2_2 [2][2];
    end
    else if (count>156 && count <162) begin
        mulk1 = Weight_layer1 [0] [count-157];
        mulk2 = Weight_layer1 [1] [count-157];
        mulk3 = Weight_layer1 [2] [count-157];
        mulk4 = Weight_layer1 [3] [count-157];
        mulk5 = Weight_layer1 [4] [count-157];
        mulk6 = Weight_layer1 [5] [count-157];
        mulk7 = Weight_layer1 [6] [count-157];
        mulk8 = Weight_layer1 [7] [count-157];
        mulk9 = 32'h3C23D70A; //0.01
    end
    else if (count == 162)   begin  
        mulk1 = 0;
        mulk2 = 0;
        mulk3 = 0;
        mulk4 = 0;
        mulk5 = 0;
        mulk6 = 0;
        mulk7 = 0;
        mulk8 = 0;
        mulk9 = 32'h3C23D70A; //0.01
    end
    else if (count >163 && count <167) begin
        mulk1 = Weight_layer2 [0] [count-164];
        mulk2 = Weight_layer2 [1] [count-164];
        mulk3 = Weight_layer2 [2] [count-164];
        mulk4 = Weight_layer2 [3] [count-164];
        mulk5 = Weight_layer2 [4] [count-164];
        mulk6  = 0 ;
        mulk7  = 0 ;
        mulk8  = 0 ;
        mulk9  = 0 ;
    end
    else begin
        mulk1 = 0; mulk2 = 0; mulk3 = 0; mulk4 = 0; mulk5 = 0; mulk6= 0; mulk7 = 0; mulk8 = 0; mulk9 = 0;
    end
end
wire [inst_sig_width+inst_exp_width :0] convtempk1,convtempk2,convtempk3,convtempk4,convtempk5,convtempk6,convtempk7,convtempk8,convtempk9;
wire [inst_sig_width+inst_exp_width :0] convtempk9_bias_select , convtempk6_bias_select;
assign convtempk6_bias_select = (count>163 && count <167) ? bias_layer2 : convtempk6;
assign convtempk9_bias_select = (count>156 && count <162) ? bias_layer1 : convtempk9;

DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_1( .a(mul1) , .b(mulk1) , .rnd(3'b0), .z(convtempk1) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_2( .a(mul2) , .b(mulk2) , .rnd(3'b0), .z(convtempk2) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_3( .a(mul3) , .b(mulk3) , .rnd(3'b0), .z(convtempk3) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_4( .a(mul4) , .b(mulk4) , .rnd(3'b0), .z(convtempk4) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_5( .a(mul5) , .b(mulk5) , .rnd(3'b0), .z(convtempk5) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_6( .a(mul6) , .b(mulk6) , .rnd(3'b0), .z(convtempk6) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_7( .a(mul7) , .b(mulk7) , .rnd(3'b0), .z(convtempk7) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_8( .a(mul8) , .b(mulk8) , .rnd(3'b0), .z(convtempk8) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mul_9( .a(mul9) , .b(mulk9) , .rnd(3'b0), .z(convtempk9) , .status( ));
wire [inst_sig_width+inst_exp_width :0] convsum3_1,convsum3_2,convsum3_3;
//maybe can change 4 4 3 
DW_fp_sum3 #(inst_sig_width, inst_exp_width ) sum3_1 (.a(convtempk1), .b(convtempk2), .c(convtempk3), .rnd(3'b0), .z(convsum3_1), .status( ));
DW_fp_sum3 #(inst_sig_width, inst_exp_width ) sum3_2 (.a(convtempk4), .b(convtempk5), .c(convtempk6_bias_select), .rnd(3'b0), .z(convsum3_2), .status( ));
DW_fp_sum3 #(inst_sig_width, inst_exp_width ) sum3_3 (.a(convtempk7), .b(convtempk8), .c(convtempk9_bias_select), .rnd(3'b0), .z(convsum3_3), .status( ));
wire [inst_sig_width+inst_exp_width :0] convadd;
DW_fp_sum3 #(inst_sig_width, inst_exp_width ) sum3_4 (.a(convsum3_1), .b(convsum3_2), .c(convsum3_3), .rnd(3'b0), .z(convadd), .status( ));

always @(posedge clk) begin
    if(count>8 && count<45 ) begin
        partial_1_1[5][5] <= convadd;           partial_1_1[5][4] <= partial_1_1[5][5];     partial_1_1[5][3] <= partial_1_1[5][4];     partial_1_1[5][2] <= partial_1_1[5][3];     partial_1_1[5][1] <= partial_1_1[5][2];     partial_1_1[5][0] <= partial_1_1[5][1];
        partial_1_1[4][5] <= partial_1_1[5][0]; partial_1_1[4][4] <= partial_1_1[4][5];     partial_1_1[4][3] <= partial_1_1[4][4];     partial_1_1[4][2] <= partial_1_1[4][3];     partial_1_1[4][1] <= partial_1_1[4][2];     partial_1_1[4][0] <= partial_1_1[4][1];
        partial_1_1[3][5] <= partial_1_1[4][0]; partial_1_1[3][4] <= partial_1_1[3][5];     partial_1_1[3][3] <= partial_1_1[3][4];     partial_1_1[3][2] <= partial_1_1[3][3];     partial_1_1[3][1] <= partial_1_1[3][2];     partial_1_1[3][0] <= partial_1_1[3][1];
        partial_1_1[2][5] <= partial_1_1[3][0]; partial_1_1[2][4] <= partial_1_1[2][5];     partial_1_1[2][3] <= partial_1_1[2][4];     partial_1_1[2][2] <= partial_1_1[2][3];     partial_1_1[2][1] <= partial_1_1[2][2];     partial_1_1[2][0] <= partial_1_1[2][1];
        partial_1_1[1][5] <= partial_1_1[2][0]; partial_1_1[1][4] <= partial_1_1[1][5];     partial_1_1[1][3] <= partial_1_1[1][4];     partial_1_1[1][2] <= partial_1_1[1][3];     partial_1_1[1][1] <= partial_1_1[1][2];     partial_1_1[1][0] <= partial_1_1[1][1];
        partial_1_1[0][5] <= partial_1_1[1][0]; partial_1_1[0][4] <= partial_1_1[0][5];     partial_1_1[0][3] <= partial_1_1[0][4];     partial_1_1[0][2] <= partial_1_1[0][3];     partial_1_1[0][1] <= partial_1_1[0][2];     partial_1_1[0][0] <= partial_1_1[0][1];
    end else if (state == IDLE)
        for(i=0; i<=5 ; i=i+1) begin
            for(j=0 ; j<=5 ; j=j+1) begin
                partial_1_1[i][j] <=0;
            end
        end
    else begin
        for(i=0; i<=5 ; i=i+1) 
            for(j=0 ; j<=5 ; j=j+1)
                partial_1_1[i][j] <=partial_1_1[i][j];
    end
end

always @(posedge clk) begin
    if(count>44 && count<81 ) begin
        partial_1_2[5][5] <= convadd;           partial_1_2[5][4] <= partial_1_2[5][5];     partial_1_2[5][3] <= partial_1_2[5][4];     partial_1_2[5][2] <= partial_1_2[5][3];     partial_1_2[5][1] <= partial_1_2[5][2];     partial_1_2[5][0] <= partial_1_2[5][1];
        partial_1_2[4][5] <= partial_1_2[5][0]; partial_1_2[4][4] <= partial_1_2[4][5];     partial_1_2[4][3] <= partial_1_2[4][4];     partial_1_2[4][2] <= partial_1_2[4][3];     partial_1_2[4][1] <= partial_1_2[4][2];     partial_1_2[4][0] <= partial_1_2[4][1];
        partial_1_2[3][5] <= partial_1_2[4][0]; partial_1_2[3][4] <= partial_1_2[3][5];     partial_1_2[3][3] <= partial_1_2[3][4];     partial_1_2[3][2] <= partial_1_2[3][3];     partial_1_2[3][1] <= partial_1_2[3][2];     partial_1_2[3][0] <= partial_1_2[3][1];
        partial_1_2[2][5] <= partial_1_2[3][0]; partial_1_2[2][4] <= partial_1_2[2][5];     partial_1_2[2][3] <= partial_1_2[2][4];     partial_1_2[2][2] <= partial_1_2[2][3];     partial_1_2[2][1] <= partial_1_2[2][2];     partial_1_2[2][0] <= partial_1_2[2][1];
        partial_1_2[1][5] <= partial_1_2[2][0]; partial_1_2[1][4] <= partial_1_2[1][5];     partial_1_2[1][3] <= partial_1_2[1][4];     partial_1_2[1][2] <= partial_1_2[1][3];     partial_1_2[1][1] <= partial_1_2[1][2];     partial_1_2[1][0] <= partial_1_2[1][1];
        partial_1_2[0][5] <= partial_1_2[1][0]; partial_1_2[0][4] <= partial_1_2[0][5];     partial_1_2[0][3] <= partial_1_2[0][4];     partial_1_2[0][2] <= partial_1_2[0][3];     partial_1_2[0][1] <= partial_1_2[0][2];     partial_1_2[0][0] <= partial_1_2[0][1];
    end else if (state == IDLE)
        for(i=0; i<=5 ; i=i+1) begin
            for(j=0 ; j<=5 ; j=j+1) begin
                partial_1_2[i][j] <=0;
            end
        end
    else begin
        for(i=0; i<=5 ; i=i+1) 
            for(j=0 ; j<=5 ; j=j+1)
                partial_1_2[i][j] <=partial_1_2[i][j];
    end
end

always @ (posedge clk) begin
    if(count>80 && count<117 ) begin
        partial_2_1[5][5] <= convadd;           partial_2_1[5][4] <= partial_2_1[5][5];     partial_2_1[5][3] <= partial_2_1[5][4];     partial_2_1[5][2] <= partial_2_1[5][3];     partial_2_1[5][1] <= partial_2_1[5][2];     partial_2_1[5][0] <= partial_2_1[5][1];
        partial_2_1[4][5] <= partial_2_1[5][0]; partial_2_1[4][4] <= partial_2_1[4][5];     partial_2_1[4][3] <= partial_2_1[4][4];     partial_2_1[4][2] <= partial_2_1[4][3];     partial_2_1[4][1] <= partial_2_1[4][2];     partial_2_1[4][0] <= partial_2_1[4][1];
        partial_2_1[3][5] <= partial_2_1[4][0]; partial_2_1[3][4] <= partial_2_1[3][5];     partial_2_1[3][3] <= partial_2_1[3][4];     partial_2_1[3][2] <= partial_2_1[3][3];     partial_2_1[3][1] <= partial_2_1[3][2];     partial_2_1[3][0] <= partial_2_1[3][1];
        partial_2_1[2][5] <= partial_2_1[3][0]; partial_2_1[2][4] <= partial_2_1[2][5];     partial_2_1[2][3] <= partial_2_1[2][4];     partial_2_1[2][2] <= partial_2_1[2][3];     partial_2_1[2][1] <= partial_2_1[2][2];     partial_2_1[2][0] <= partial_2_1[2][1];
        partial_2_1[1][5] <= partial_2_1[2][0]; partial_2_1[1][4] <= partial_2_1[1][5];     partial_2_1[1][3] <= partial_2_1[1][4];     partial_2_1[1][2] <= partial_2_1[1][3];     partial_2_1[1][1] <= partial_2_1[1][2];     partial_2_1[1][0] <= partial_2_1[1][1];
        partial_2_1[0][5] <= partial_2_1[1][0]; partial_2_1[0][4] <= partial_2_1[0][5];     partial_2_1[0][3] <= partial_2_1[0][4];     partial_2_1[0][2] <= partial_2_1[0][3];     partial_2_1[0][1] <= partial_2_1[0][2];     partial_2_1[0][0] <= partial_2_1[0][1];
    end else if (state == IDLE)
        for(i=0; i<=5 ; i=i+1) begin
            for(j=0 ; j<=5 ; j=j+1) begin
                partial_2_1[i][j] <=0;
            end
        end
    else begin
        for(i=0; i<=5 ; i=i+1) 
            for(j=0 ; j<=5 ; j=j+1)
                partial_2_1[i][j] <=partial_2_1[i][j];
    end
end

always@(posedge clk) begin
    if(count>116 && count<153 ) begin
        partial_2_2[5][5] <= convadd;           partial_2_2[5][4] <= partial_2_2[5][5];     partial_2_2[5][3] <= partial_2_2[5][4];     partial_2_2[5][2] <= partial_2_2[5][3];     partial_2_2[5][1] <= partial_2_2[5][2];     partial_2_2[5][0] <= partial_2_2[5][1];
        partial_2_2[4][5] <= partial_2_2[5][0]; partial_2_2[4][4] <= partial_2_2[4][5];     partial_2_2[4][3] <= partial_2_2[4][4];     partial_2_2[4][2] <= partial_2_2[4][3];     partial_2_2[4][1] <= partial_2_2[4][2];     partial_2_2[4][0] <= partial_2_2[4][1];
        partial_2_2[3][5] <= partial_2_2[4][0]; partial_2_2[3][4] <= partial_2_2[3][5];     partial_2_2[3][3] <= partial_2_2[3][4];     partial_2_2[3][2] <= partial_2_2[3][3];     partial_2_2[3][1] <= partial_2_2[3][2];     partial_2_2[3][0] <= partial_2_2[3][1];
        partial_2_2[2][5] <= partial_2_2[3][0]; partial_2_2[2][4] <= partial_2_2[2][5];     partial_2_2[2][3] <= partial_2_2[2][4];     partial_2_2[2][2] <= partial_2_2[2][3];     partial_2_2[2][1] <= partial_2_2[2][2];     partial_2_2[2][0] <= partial_2_2[2][1];
        partial_2_2[1][5] <= partial_2_2[2][0]; partial_2_2[1][4] <= partial_2_2[1][5];     partial_2_2[1][3] <= partial_2_2[1][4];     partial_2_2[1][2] <= partial_2_2[1][3];     partial_2_2[1][1] <= partial_2_2[1][2];     partial_2_2[1][0] <= partial_2_2[1][1];
        partial_2_2[0][5] <= partial_2_2[1][0]; partial_2_2[0][4] <= partial_2_2[0][5];     partial_2_2[0][3] <= partial_2_2[0][4];     partial_2_2[0][2] <= partial_2_2[0][3];     partial_2_2[0][1] <= partial_2_2[0][2];     partial_2_2[0][0] <= partial_2_2[0][1];
    end else if (state == IDLE)
        for(i=0; i<=5 ; i=i+1) begin
            for(j=0 ; j<=5 ; j=j+1) begin
                partial_2_2[i][j] <=0;
            end
        end
    else begin
        for(i=0; i<=5 ; i=i+1) 
            for(j=0 ; j<=5 ; j=j+1)
                partial_2_2[i][j] <=partial_2_2[i][j];
    end
end
//---------------------------------------------------------------------
// Convolution (Add)
//---------------------------------------------------------------------
reg  [inst_sig_width+inst_exp_width :0] addouttemp_reg ; // for task 1 
always @(*) begin
    if(task_reg == 0) begin
        if(count>45 && count<82 ) begin
            add1_1 = partial_1_1 [(count-46)/6]     [(count-46)%6];
            add1_2 = partial_1_2[5][5];
        end
        else if (count>117 && count<154) begin
            add1_1 = partial_2_1 [(count-118)/6]     [(count-118)%6];
            add1_2 = partial_2_2[5][5];
        end
        else begin
            add1_1 = 0;
            add1_2 = 0;
        end
        //here
    end
    else begin
        // task 1 adder
        if (count ==11) begin
            add1_1 = partial_1_1[5][4];
            add1_2 = partial_1_1[5][5];
        end
        else if (count >11 && count < 46) begin
            add1_1 = partial_1_1[5][5];
            add1_2 = addouttemp_reg;
        end
        else if (count == 47) begin
            add1_1 = partial_1_2[5][4];
            add1_2 = partial_1_2[5][5];
        end
        else if (count >47 && count < 82) begin
            add1_1 = partial_1_2[5][5];
            add1_2 = addouttemp_reg;
        end
        else if (count == 83) begin
            add1_1 = partial_2_1[5][4];
            add1_2 = partial_2_1[5][5];
        end
        else if (count >83 && count < 118) begin
            add1_1 = partial_2_1[5][5];
            add1_2 = addouttemp_reg;
        end
        else if (count == 119) begin
            add1_1 = partial_2_2[5][4];
            add1_2 = partial_2_2[5][5];
        end
        else if (count >119 && count < 154) begin
            add1_1 = partial_2_2[5][5];
            add1_2 = addouttemp_reg;
        end
        else begin
            add1_1 = 0;
            add1_2 = 0;
        end 
    end
end
wire [inst_sig_width+inst_exp_width :0] addouttemp;

always @(posedge clk) begin
    if(task_reg==1)  addouttemp_reg <= addouttemp;
    else addouttemp_reg <= addouttemp_reg;
end

// reg [inst_sig_width+inst_exp_width :0] exp_adder ; 

//maybe can optimize (maybe share)
DW_fp_add #(inst_sig_width, inst_exp_width ) add_1( .a(add1_1) , .b(add1_2) , .rnd(3'b0), .z(addouttemp) , .status( ));

always @(posedge clk) begin
    if(count>45 && count<82) begin
        out_ch1[5][5] <= addouttemp;    out_ch1[5][4] <= out_ch1[5][5];     out_ch1[5][3] <= out_ch1[5][4];     out_ch1[5][2] <= out_ch1[5][3];     out_ch1[5][1] <= out_ch1[5][2];     out_ch1[5][0] <= out_ch1[5][1];
        out_ch1[4][5] <= out_ch1[5][0]; out_ch1[4][4] <= out_ch1[4][5];     out_ch1[4][3] <= out_ch1[4][4];     out_ch1[4][2] <= out_ch1[4][3];     out_ch1[4][1] <= out_ch1[4][2];     out_ch1[4][0] <= out_ch1[4][1];
        out_ch1[3][5] <= out_ch1[4][0]; out_ch1[3][4] <= out_ch1[3][5];     out_ch1[3][3] <= out_ch1[3][4];     out_ch1[3][2] <= out_ch1[3][3];     out_ch1[3][1] <= out_ch1[3][2];     out_ch1[3][0] <= out_ch1[3][1];
        out_ch1[2][5] <= out_ch1[3][0]; out_ch1[2][4] <= out_ch1[2][5];     out_ch1[2][3] <= out_ch1[2][4];     out_ch1[2][2] <= out_ch1[2][3];     out_ch1[2][1] <= out_ch1[2][2];     out_ch1[2][0] <= out_ch1[2][1];
        out_ch1[1][5] <= out_ch1[2][0]; out_ch1[1][4] <= out_ch1[1][5];     out_ch1[1][3] <= out_ch1[1][4];     out_ch1[1][2] <= out_ch1[1][3];     out_ch1[1][1] <= out_ch1[1][2];     out_ch1[1][0] <= out_ch1[1][1];
        out_ch1[0][5] <= out_ch1[1][0]; out_ch1[0][4] <= out_ch1[0][5];     out_ch1[0][3] <= out_ch1[0][4];     out_ch1[0][2] <= out_ch1[0][3];     out_ch1[0][1] <= out_ch1[0][2];     out_ch1[0][0] <= out_ch1[0][1];
    end else if (state == IDLE)
        for(i=0; i<=6 ; i=i+1) begin
            for(j=0 ; j<=6 ; j=j+1) begin
                out_ch1[i][j] <=0;
            end
        end  
    else begin
        for(i=0; i<=6 ; i=i+1) begin
            for(j=0 ; j<=6 ; j=j+1) begin
                out_ch1[i][j] <=out_ch1[i][j];
            end
        end 
    end
end

always @(posedge clk) begin
    if(count>117 && count<154) begin
        out_ch2[5][5] <= addouttemp;    out_ch2[5][4] <= out_ch2[5][5];     out_ch2[5][3] <= out_ch2[5][4];     out_ch2[5][2] <= out_ch2[5][3];     out_ch2[5][1] <= out_ch2[5][2];     out_ch2[5][0] <= out_ch2[5][1];
        out_ch2[4][5] <= out_ch2[5][0]; out_ch2[4][4] <= out_ch2[4][5];     out_ch2[4][3] <= out_ch2[4][4];     out_ch2[4][2] <= out_ch2[4][3];     out_ch2[4][1] <= out_ch2[4][2];     out_ch2[4][0] <= out_ch2[4][1];
        out_ch2[3][5] <= out_ch2[4][0]; out_ch2[3][4] <= out_ch2[3][5];     out_ch2[3][3] <= out_ch2[3][4];     out_ch2[3][2] <= out_ch2[3][3];     out_ch2[3][1] <= out_ch2[3][2];     out_ch2[3][0] <= out_ch2[3][1];
        out_ch2[2][5] <= out_ch2[3][0]; out_ch2[2][4] <= out_ch2[2][5];     out_ch2[2][3] <= out_ch2[2][4];     out_ch2[2][2] <= out_ch2[2][3];     out_ch2[2][1] <= out_ch2[2][2];     out_ch2[2][0] <= out_ch2[2][1];
        out_ch2[1][5] <= out_ch2[2][0]; out_ch2[1][4] <= out_ch2[1][5];     out_ch2[1][3] <= out_ch2[1][4];     out_ch2[1][2] <= out_ch2[1][3];     out_ch2[1][1] <= out_ch2[1][2];     out_ch2[1][0] <= out_ch2[1][1];
        out_ch2[0][5] <= out_ch2[1][0]; out_ch2[0][4] <= out_ch2[0][5];     out_ch2[0][3] <= out_ch2[0][4];     out_ch2[0][2] <= out_ch2[0][3];     out_ch2[0][1] <= out_ch2[0][2];     out_ch2[0][0] <= out_ch2[0][1];
    end else if (state == IDLE)
        for(i=0; i<=6 ; i=i+1) begin
            for(j=0 ; j<=6 ; j=j+1) begin
                out_ch2[i][j] <=0;
            end
        end  
    else begin
        for(i=0; i<=6 ; i=i+1) begin
            for(j=0 ; j<=6 ; j=j+1) begin
                out_ch2[i][j] <=out_ch2[i][j];
            end
        end 
    end
end
//---------------------------------------------------------------------
// Maxpooling
//---------------------------------------------------------------------
wire [inst_sig_width+inst_exp_width :0] findmax_pooling;

always @(*) begin
    case(count) 
        61 , 64 ,79 ,82 : begin
            findmax_temp[0] = out_ch1[3][3];   findmax_temp[1] = out_ch1[3][4];   findmax_temp[2] = out_ch1[3][5];
            findmax_temp[3] = out_ch1[4][3];   findmax_temp[4] = out_ch1[4][4];   findmax_temp[5] = out_ch1[4][5];
            findmax_temp[6] = out_ch1[5][3];   findmax_temp[7] = out_ch1[5][4];   findmax_temp[8] = out_ch1[5][5];
        end
        133 ,136 ,151 ,154 : begin
            findmax_temp[0] = out_ch2[3][3];   findmax_temp[1] = out_ch2[3][4];   findmax_temp[2] = out_ch2[3][5];
            findmax_temp[3] = out_ch2[4][3];   findmax_temp[4] = out_ch2[4][4];   findmax_temp[5] = out_ch2[4][5];
            findmax_temp[6] = out_ch2[5][3];   findmax_temp[7] = out_ch2[5][4];   findmax_temp[8] = out_ch2[5][5];
        end
        default: begin
            for(i=0; i<9 ; i=i+1) begin
                findmax_temp[i] = 0;
            end
        end
    endcase
end

findmax #(inst_sig_width, inst_exp_width)
    Maxpooling( .in1(findmax_temp[0]) , .in2(findmax_temp[1]) , .in3(findmax_temp[2]) ,
                .in4(findmax_temp[3]) , .in5(findmax_temp[4]) , .in6(findmax_temp[5]) , 
                .in7(findmax_temp[6]) , .in8(findmax_temp[7]) , .in9(findmax_temp[8]) , .maxvalue(findmax_pooling));

always @(posedge clk) begin //maybe can use shifter register
    if (state == IDLE) begin
        pooling_ch1[0][0] <=0 ; pooling_ch1[0][1] <=0 ; 
        pooling_ch1[1][0] <=0 ; pooling_ch1[1][1] <=0 ; 
    end else begin
        case (count)
            61 : pooling_ch1[0][0] <= findmax_pooling;
            64 : pooling_ch1[0][1] <= findmax_pooling;
            79 : pooling_ch1[1][0] <= findmax_pooling;
            82 : pooling_ch1[1][1] <= findmax_pooling;
            default: begin
                pooling_ch1[0][0] <=pooling_ch1[0][0] ; pooling_ch1[0][1] <=pooling_ch1[0][1] ; 
                pooling_ch1[1][0] <=pooling_ch1[1][0] ; pooling_ch1[1][1] <=pooling_ch1[1][1] ; 
            end
        endcase
    end
end

always @(posedge clk) begin //maybe can use shifter register
    if (state == IDLE) begin
        pooling_ch2[0][0] <=0 ; pooling_ch2[0][1] <=0 ; 
        pooling_ch2[1][0] <=0 ; pooling_ch2[1][1] <=0 ; 
    end else begin
        case (count)
            133 : pooling_ch2[0][0] <= findmax_pooling;
            136 : pooling_ch2[0][1] <= findmax_pooling;
            151 : pooling_ch2[1][0] <= findmax_pooling;
            154 : pooling_ch2[1][1] <= findmax_pooling;
            default: begin
                pooling_ch2[0][0] <=pooling_ch2[0][0] ; pooling_ch2[0][1] <=pooling_ch2[0][1] ; 
                pooling_ch2[1][0] <=pooling_ch2[1][0] ; pooling_ch2[1][1] <=pooling_ch2[1][1] ; 
            end
        endcase
    end
end

//---------------------------------------------------------------------
// Activation Function layer1
//---------------------------------------------------------------------
reg [inst_sig_width+inst_exp_width :0] exp_power;

always @(*) begin
    if(mode_comb[0]==1) begin//swith e^-x
        case(count)
            148 : exp_power = {~pooling_ch1[0][0][31],pooling_ch1[0][0][30:0]};
            149 : exp_power = {~pooling_ch1[0][1][31],pooling_ch1[0][1][30:0]};
            150 : exp_power = {~pooling_ch1[1][0][31],pooling_ch1[1][0][30:0]};
            151 : exp_power = {~pooling_ch1[1][1][31],pooling_ch1[1][1][30:0]};
            152 : exp_power = {~pooling_ch2[0][0][31],pooling_ch2[0][0][30:0]};
            153 : exp_power = {~pooling_ch2[0][1][31],pooling_ch2[0][1][30:0]};
            154 : exp_power = {~pooling_ch2[1][0][31],pooling_ch2[1][0][30:0]};
            155 : exp_power = {~pooling_ch2[1][1][31],pooling_ch2[1][1][30:0]};
            default : exp_power = 0;
        endcase
    end
    else begin //tanh e^2x
      case(count)
            148 : exp_power = (pooling_ch1[0][0][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch1[0][0][31],pooling_ch1[0][0][30:23]+1'b1,pooling_ch1[0][0][22:0]};
            149 : exp_power = (pooling_ch1[0][1][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch1[0][1][31],pooling_ch1[0][1][30:23]+1'b1,pooling_ch1[0][1][22:0]};
            150 : exp_power = (pooling_ch1[1][0][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch1[1][0][31],pooling_ch1[1][0][30:23]+1'b1,pooling_ch1[1][0][22:0]};
            151 : exp_power = (pooling_ch1[1][1][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch1[1][1][31],pooling_ch1[1][1][30:23]+1'b1,pooling_ch1[1][1][22:0]};
            152 : exp_power = (pooling_ch2[0][0][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch2[0][0][31],pooling_ch2[0][0][30:23]+1'b1,pooling_ch2[0][0][22:0]};
            153 : exp_power = (pooling_ch2[0][1][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch2[0][1][31],pooling_ch2[0][1][30:23]+1'b1,pooling_ch2[0][1][22:0]};
            154 : exp_power = (pooling_ch2[1][0][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch2[1][0][31],pooling_ch2[1][0][30:23]+1'b1,pooling_ch2[1][0][22:0]};
            155 : exp_power = (pooling_ch2[1][1][30:0] == 31'b0) ?
                                32'b0 : {pooling_ch2[1][1][31],pooling_ch2[1][1][30:23]+1'b1,pooling_ch2[1][1][22:0]};
            default : exp_power = 0;
        endcase
    end
end
reg [inst_sig_width+inst_exp_width :0] exp_out;
wire  [inst_sig_width+inst_exp_width :0] exp_power_selection; //maybe can add pipe
assign exp_power_selection = (count>165 && count <169) ? FC_layer2_pipe[2] : exp_power;

DW_fp_exp #(inst_sig_width, inst_exp_width ) exp_1( .a(exp_power_selection) , .z(exp_out) , .status( ));

reg [inst_sig_width+inst_exp_width :0] exp_pipe;
reg [inst_sig_width+inst_exp_width :0] momtemp,sontemp,recip_out_mom;
always @(posedge clk) begin
    if(state == IDLE) exp_pipe <= 0;
    else exp_pipe <= exp_out;
end

reg [inst_sig_width+inst_exp_width :0] adder1_select,adder2_select,adder0_select;

always @(*) begin
    if(count ==169) adder0_select = softmax_exp_out[1];
    else adder0_select = exp_pipe;
end

always @(*) begin
    if(count ==169) adder1_select = softmax_exp_out[2];
    else adder1_select = 32'h3f800000;
end

always @(*) begin
    if(count == 169) adder2_select = momtemp;
    else adder2_select = 32'hbf800000;
end

DW_fp_add #(inst_sig_width, inst_exp_width ) add_mom( .a(adder0_select) , .b(adder1_select) , .rnd(3'b0), .z(momtemp) , .status( ));
DW_fp_add #(inst_sig_width, inst_exp_width ) add_son( .a(exp_pipe) , .b(adder2_select) , .rnd(3'b0), .z(sontemp) , .status( ));
reg [inst_sig_width+inst_exp_width :0] sontemp_select,activationout;

reg [inst_sig_width+inst_exp_width :0] softmom_reg;

always @(posedge clk) begin
    if(count ==169) softmom_reg <= sontemp;
    else if(state == IDLE) softmom_reg <= 0;
    else softmom_reg <= softmom_reg;
end

always @(*) begin
    if(mode_comb[0]==1) begin
        case(count)
            149 : sontemp_select = pooling_ch1[0][0];
            150 : sontemp_select = pooling_ch1[0][1];
            151 : sontemp_select = pooling_ch1[1][0];
            152 : sontemp_select = pooling_ch1[1][1];
            153 : sontemp_select = pooling_ch2[0][0];
            154 : sontemp_select = pooling_ch2[0][1];
            155 : sontemp_select = pooling_ch2[1][0];
            156 : sontemp_select = pooling_ch2[1][1];
            170 : sontemp_select = softmax_exp_out[0];
            171 : sontemp_select = softmax_exp_out[1];
            172 : sontemp_select = softmax_exp_out[2];
            default : sontemp_select = 0;
        endcase
    end
    else begin
        case (count)
            170 : sontemp_select = softmax_exp_out[0];
            171 : sontemp_select = softmax_exp_out[1];
            172 : sontemp_select = softmax_exp_out[2];
            default :sontemp_select = sontemp;
        endcase
    end
end

reg [inst_sig_width+inst_exp_width :0] mom_temp_select;
always @(*) begin
    if(count >169 && count <173) mom_temp_select = softmom_reg;
    else mom_temp_select = momtemp;
end
//maybe can add pipe
DW_fp_recip #(inst_sig_width, inst_exp_width ) recip_1( .a(mom_temp_select) , .rnd(3'b0), .z(recip_out_mom) , .status( ));
DW_fp_mult #(inst_sig_width, inst_exp_width ) mult_1( .a(sontemp_select) , .b(recip_out_mom) , .rnd(3'b0), .z(activationout) , .status( ));

always @(posedge clk) begin
    if (state== IDLE) begin
        activation_ch1[0][0] <= 0;
        activation_ch1[0][1] <= 0;
        activation_ch1[1][0] <= 0;
        activation_ch1[1][1] <= 0;
    end
    else
        case (count)
            149 : activation_ch1[0][0] <= activationout;
            150 : activation_ch1[0][1] <= activationout;
            151 : activation_ch1[1][0] <= activationout;
            152 : activation_ch1[1][1] <= activationout;
        endcase
end

always @(posedge clk) begin
    if (state== IDLE) begin
        activation_ch2[0][0] <= 0;
        activation_ch2[0][1] <= 0;
        activation_ch2[1][0] <= 0;
        activation_ch2[1][1] <= 0;
    end
    else
        case (count)
            153 : activation_ch2[0][0] <= activationout;
            154 : activation_ch2[0][1] <= activationout;
            155 : activation_ch2[1][0] <= activationout;
            156 : activation_ch2[1][1] <= activationout;
        endcase
end

//---------------------------------------------------------------------
// Fully Connected layer1
//---------------------------------------------------------------------
always @(posedge clk) begin
    if(count>156 && count <162) begin
      FC_layer1[4] <= convadd;      FC_layer1[3] <= FC_layer1[4];
      FC_layer1[2] <= FC_layer1[3]; FC_layer1[1] <= FC_layer1[2]; FC_layer1[0] <= FC_layer1[1];
    end else if (state == IDLE)
        for(i=0; i<=4 ; i=i+1)
            FC_layer1[i] <=0;
    else 
        for(i=0; i<=4 ; i=i+1)
            FC_layer1[i] <=FC_layer1[i];
end
//---------------------------------------------------------------------
// Activation Function layer2
//---------------------------------------------------------------------
// reg [inst_sig_width+inst_exp_width :0] activation_leaky[4:0];

always @(posedge clk) begin
    if(count>157 && count <163) begin
        activation_leaky[3] <= activation_leaky[4];  activation_leaky[2] <= activation_leaky[3];
        activation_leaky[1] <= activation_leaky[2];  activation_leaky[0] <= activation_leaky[1];
        if(FC_layer1[4][31]==1) activation_leaky[4] <= convtempk9;
        else activation_leaky[4] <= FC_layer1[4];
    end else if (state == IDLE) begin
        activation_leaky[4] <=0;    activation_leaky[3] <=0;    activation_leaky[2] <=0;    
        activation_leaky[1] <=0;    activation_leaky[0] <=0;
    end else begin
        activation_leaky[4] <=activation_leaky[4];  activation_leaky[3] <=activation_leaky[3];
        activation_leaky[2] <=activation_leaky[2];  activation_leaky[1] <=activation_leaky[1];
        activation_leaky[0] <=activation_leaky[0];
    end
end


//---------------------------------------------------------------------
// Fully Connected layer2
//---------------------------------------------------------------------
always @(posedge clk) begin
    if(count>163 && count <167) begin
      FC_layer2[2] <= convadd;      FC_layer2[1] <= FC_layer2[2];   FC_layer2[0] <= FC_layer2[1];
    end else if (state == IDLE)
        for(i=0; i<=2 ; i=i+1)
            FC_layer2[i] <=0;
    else 
        for(i=0; i<=2 ; i=i+1)
            FC_layer2[i] <=FC_layer2[i];
end

always @(posedge clk) begin
    if(state == IDLE) begin 
        FC_layer2_pipe[2] <= 0; FC_layer2_pipe[1] <= 0; FC_layer2_pipe[0] <= 0;
    end else begin
        FC_layer2_pipe[2] <= FC_layer2[2];
        FC_layer2_pipe[1] <= FC_layer2[1];
        FC_layer2_pipe[0] <= FC_layer2[0];
    end
end

//---------------------------------------------------------------------
// Softmax
//---------------------------------------------------------------------
always @(posedge clk) begin
    if(count>166 && count <170) begin
        softmax_exp_out[2] <= exp_pipe; softmax_exp_out[1] <= softmax_exp_out[2]; softmax_exp_out[0] <= softmax_exp_out[1];
    end else if (state == IDLE)
        for(i=0; i<=2 ; i=i+1)
            softmax_exp_out[i] <=0;
    else 
        for(i=0; i<=2 ; i=i+1)
            softmax_exp_out[i] <=softmax_exp_out[i];
end

//task1---------------------------------------------------------------------

//---------------------------------------------------------------------
// Input
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) capacity <= 0;
    else if (in_valid && task_reg==1 && count==0) capacity <= capacity_cost_reg; //maybe need add counter 
    else capacity <= capacity;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) costA <= 0;
    else if (in_valid && task_reg==1 && count==1) costA <= capacity_cost_reg; 
    else costA <= costA;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) costB <= 0;
    else if (in_valid && task_reg==1 && count==2) costB <= capacity_cost_reg; 
    else costB <= costB;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) costC <= 0;
    else if (in_valid && task_reg==1 && count==3) costC <= capacity_cost_reg; 
    else costC <= costC;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) costD <= 0;
    else if (in_valid && task_reg==1 && count==4) costD <= capacity_cost_reg; 
    else costD <= costD;
end
//---------------------------------------------------------------------
// Result 
//---------------------------------------------------------------------
// addouttemp_reg
always @(posedge clk) begin
    if(state == IDLE) resultA <= 0;
    else if(count==46 && task_reg==1) resultA <= addouttemp_reg;
    else resultA <= resultA;
end

always @(posedge clk) begin
    if(state == IDLE) resultB <= 0;
    else if(count==82 && task_reg==1) resultB <= addouttemp_reg;
    else resultB <= resultB;
end

always @(posedge clk) begin
    if(state == IDLE) resultC <= 0;
    else if(count==118 && task_reg==1) resultC <= addouttemp_reg;
    else resultC <= resultC;
end

always @(posedge clk) begin
    if(state == IDLE) resultD <= 0;
    else if(count==154 && task_reg==1) resultD <= addouttemp_reg;
    else resultD <= resultD;
end
//---------------------------------------------------------------------
// Select Max value
//---------------------------------------------------------------------
assign negetive_number = (resultA[31]) + (resultB[31])+ (resultC[31]) + (resultD[31]);
// always @(*) begin
//     if(count > 154)
//         case(negetive_number)
//             0: task1_count =16; 
//             1: task1_count =8;
//             2: task1_count =4;
//             3: task1_count =2;
//             4: task1_count =1;
//             default : task1_count=0;
//         endcase
//     else task1_count=0;
// end
reg [inst_sig_width+inst_exp_width :0] max_temp,max_reg,max;

reg [5:0] cost_number;

reg [inst_sig_width+inst_exp_width :0] selectA , selectB , selectC , selectD ;

always @(*) begin
    case(count)
        156: cost_number = costD;
        157: cost_number = costC;
        158: cost_number = costC+costD;
        159: cost_number = costB;
        160: cost_number = costB+costD;
        161: cost_number = costB+costC;
        162: cost_number = costB+costC+costD;
        163: cost_number = costA;
        164: cost_number = costA+costD;
        165: cost_number = costA+costC;
        166: cost_number = costA+costC+costD;
        167: cost_number = costA+costB;
        168: cost_number = costA+costB+costD;
        169: cost_number = costA+costB+costC;
        170: cost_number = costA+costB+costC+costD;
        default: cost_number = 0;
    endcase
end

always @ (*) begin
    case (count)
        156 : begin
            selectA = 0; selectB = 0; selectC = 0; selectD = resultD;
        end
        157 : begin
            selectA = 0; selectB = 0; selectC = resultC; selectD = 0;
        end
        158 : begin
            selectA = 0; selectB = 0; selectC = resultC; selectD = resultD;
        end
        159 : begin
            selectA = 0; selectB = resultB; selectC = 0; selectD = 0;
        end
        160 : begin //B+D
            selectA = 0; selectB = resultB; selectC = 0; selectD = resultD;
        end
        161 : begin //B+C
            selectA = 0; selectB = resultB; selectC = resultC; selectD = 0;
        end
        162 : begin //B+C+D
            selectA = 0; selectB = resultB; selectC = resultC; selectD = resultD;
        end
        163 : begin //A
            selectA = resultA; selectB = 0; selectC = 0; selectD = 0;
        end
        164 : begin //A+D
            selectA = resultA; selectB = 0; selectC = 0; selectD = resultD;
        end
        165 : begin //A+C
            selectA = resultA; selectB = 0; selectC = resultC; selectD = 0;
        end
        166 : begin //A+C+D
            selectA = resultA; selectB = 0; selectC = resultC; selectD = resultD;
        end
        167 : begin //A+B
            selectA = resultA; selectB = resultB; selectC = 0; selectD = 0;
        end
        168 : begin //A+B+D
            selectA = resultA; selectB = resultB; selectC = 0; selectD = resultD;
        end
        169 : begin //A+B+C
            selectA = resultA; selectB = resultB; selectC = resultC; selectD = 0;
        end
        170 : begin //A+B+C+D
            selectA = resultA; selectB = resultB; selectC = resultC; selectD = resultD;
        end
        default: begin
            selectA = 0; selectB = 0; selectC = 0; selectD = 0;
        end
    endcase
end
reg maxfind;
DW_fp_sum4 #(inst_sig_width, inst_exp_width ) selectmax( .a(selectA) , .b(selectB) , .c(selectC) , .d(selectD) , .rnd(3'b0), .z(max_temp) , .status( ));
DW_fp_cmp #(inst_sig_width, inst_exp_width ) comparemax (.a(max_reg)   , .b(max_temp)  , .altb(maxfind) , .zctr(1'b1) , .z0(max) ); //zctr 1 is max

always @(posedge clk) begin
    if(state == IDLE) max_reg <= 0;
    else if(count>155 && task_reg==1 &&  cost_number<=capacity) max_reg <= max;
    else max_reg <= max_reg;
end

// task1_out
always @(posedge clk) begin
    if(state == IDLE) task1_out <= 0;
    // else if(count==155 && negetive_number==4 ) task1_out <= 0;
    else if(count==155 ) task1_out <= 0; //maybe 
    else if(count>155 && maxfind==1 &&  cost_number<=capacity) begin
        case(count)
            // 155 : task1_out <= {28'b0,4'b0000};
            156 : task1_out <= {28'b0,4'b0001};
            157 : task1_out <= {28'b0,4'b0010};
            158 : task1_out <= {28'b0,4'b0011};
            159 : task1_out <= {28'b0,4'b0100};
            160 : task1_out <= {28'b0,4'b0101};
            161 : task1_out <= {28'b0,4'b0110};
            162 : task1_out <= {28'b0,4'b0111};
            163 : task1_out <= {28'b0,4'b1000};
            164 : task1_out <= {28'b0,4'b1001};
            165 : task1_out <= {28'b0,4'b1010};
            166 : task1_out <= {28'b0,4'b1011};
            167 : task1_out <= {28'b0,4'b1100};
            168 : task1_out <= {28'b0,4'b1101};
            169 : task1_out <= {28'b0,4'b1110};
            170 : task1_out <= {28'b0,4'b1111};
            default : task1_out <= task1_out;
        endcase
    end
    else task1_out <= task1_out;
end

//---------------------------------------------------------------------
// Output
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) out_valid <= 0;
    else if (state== OUTPUT) out_valid <= 1;
    else out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) out <= 0;
    else if (state == OUTPUT && task_reg==0) out <= activationout;
    else if (state == OUTPUT && task_reg==1) out <= task1_out;
    else out <= 0;
end

//---------------------------------------------------------------------
// Input Buffer
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) Img_comb <= 0;
    else if(in_valid) Img_comb <= Image;
    else Img_comb <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) Kernel_ch1_comb <= 0;
    else if(in_valid) Kernel_ch1_comb <= Kernel_ch1; //maybe need add counter 
    else Kernel_ch1_comb <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) Kernel_ch2_comb <= 0;
    else if(in_valid) Kernel_ch2_comb <= Kernel_ch2; //maybe need add counter 
    else Kernel_ch2_comb <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) mode_comb <= 0;
    else if (state == IDLE && in_valid) mode_comb <= mode;
    else mode_comb <= mode_comb;
end

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n) Weight_comb <= 0;
    // else if(in_valid && task_reg==0) Weight_comb <= Weight_Bias;//maybe need add counter 
    else if(in_valid) Weight_comb <= Weight_Bias;
    else Weight_comb <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) capacity_cost_reg <= 0;
    else if (in_valid) capacity_cost_reg <= capacity_cost; //maybe need add counter 
    else capacity_cost_reg <= capacity_cost_reg;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) task_reg <= 0;
    else if (state == IDLE && in_valid) task_reg <= task_number; 
    else task_reg <= task_reg;
end

endmodule
//---------------------------------------------------------------------
// Find maximum module
//---------------------------------------------------------------------
module findmax (
    in1,in2,in3,in4,in5,in6,in7,in8,in9,maxvalue
);
parameter inst_sig_width=23;
parameter inst_exp_width=8;

input [inst_sig_width+inst_exp_width : 0] in1,in2,in3,in4,in5,in6,in7,in8,in9;
output[inst_sig_width+inst_exp_width : 0] maxvalue;

wire [inst_sig_width+inst_exp_width : 0] max12,max34,max56,max78,max13,max57,max9;

DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare1 (.a(in1)   , .b(in2)   , .zctr(1'b1) , .z0(max12)); //zctr 1 is max
DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare2 (.a(in3)   , .b(in4)   , .zctr(1'b1) , .z0(max34));
DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare3 (.a(in5)   , .b(in6)   , .zctr(1'b1) , .z0(max56));
DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare4 (.a(in7)   , .b(in8)   , .zctr(1'b1) , .z0(max78));

DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare5 (.a(max12) , .b(max34) , .zctr(1'b1) , .z0(max13));
DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare6 (.a(max56) , .b(max78) , .zctr(1'b1) , .z0(max57));

DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare7 (.a(max13) , .b(max57) , .zctr(1'b1) , .z0(max9) );

DW_fp_cmp #(inst_sig_width, inst_exp_width ) compare8 (.a(max9)  , .b(in9)   , .zctr(1'b1) , .z0(maxvalue));

endmodule

// Cycle: 29.30
// Area: 3036850.230329
// Performance: 270218058118464.50029743346130

// remove 1254 && negetive_number==4 //2
// Cycle: 29.30
// Area: 3069914.641732
// Performance: 276134214090351.05773762284320

// remove 382 and 409 state == INPUT     (bias_layer1 and bias_layer2) //3 **best
// Cycle: 29.30
// Area: 3036730.478082
// Performance: 270196747497805.47587428261320

//remove 382 and 409 state == INPUT     (bias_layer1 and bias_layer2) and add 1254 && negetive_number==4