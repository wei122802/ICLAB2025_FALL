//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/10
//		Version		: v1.0
//   	File Name   : RPG.sv
//   	Module Name : RPG
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module RPG(input clk, INF.RPG_inf inf);
import usertype::*;
//==============================================//
//              logic declaration               //
// ============================================ //

FSM_state current_state , next_state;

Action           action_type ; 
Warn_Msg         warn_type;
Training_Type    train_type;
Mode             mode_type;
Date             today_date;
// Player_No        player_no;
Player_Info      player_info; //EXP MP HP Attack Defense M D

Player_Info  player_data , player_data_temp ;

// control signals
logic        dram_read_valid , dram_read_temp;
logic        dram_write_valid;
logic [95:0] dram_out_data;
logic write_valid ;

//flag
logic        saturation_flag,exp_flag,mp_flag,hp_flag,date_flag;

logic        login_done;
logic        battle_get_alldata ;
logic        player_no_valid_reg;
logic [7:0]  player_no_reg;

//sorting 
logic [15:0] sort_select [0:3] ; 
logic [15:0] sort_out_select [0:3] ;

//Login
Month today_month ;
Day   today_day ;
logic consecutive;
logic [8:0] days_diff ;

//level up
Training_Type type_reg;
Mode          mode_reg;
logic [17:0]  attribute_sum;
logic [15:0]  attribute_avg;
logic [15:0]  delta [0:3] ; 
logic [16:0]  delta_final [0:3] ;
logic [15:0]  A [0:3] ; 
typedef enum logic  [1:0]{ MP  = 2'b00,	HP  = 2'b01,  ATTACK  = 2'b10,  DEFENSE  = 2'b11} Attribute ;

Attribute   min1 , min2 ;
//battle (monster)
logic [1:0]  monster_cnt;

logic [15:0] monster_HP;
logic [15:0] monster_Attack;
logic [15:0] monster_Defense;
//battle
logic [16:0] damage_2player , damage_2monster ;
logic [16:0] player_HP_temp , monster_HP_temp;
typedef enum logic [1:0] { WIN = 'd0, LOSS= 'd1,TIE = 'd2 } battle_result;
battle_result battle_Result;

//skill
logic [2:0]  mp_cnt;
logic [15:0] mp_skill [0:3] ;
logic [15:0] mp_skill_sort [0:3] ;
logic [15:0] mp_skill_reg [0:3] ;
logic [15:0] mp_remain ; 

logic complete_comb;

//update new info 
logic [17:0] exp_new ,mp_new , attack_new , defense_new;
logic [17:0] hp_new;
logic exceed_exp, exceed_mp, less_exp ,less_attack, less_defense ,exceed_hp , less_hp,less_mp ,exceed_defense;
logic [15:0] exp_out, mp_out, hp_out, attack_out, defense_out;
Month month_out;
Day   day_out;

integer i ;

typedef enum logic [2:0] {
    idle_active      = 'd0,
    check_active     = 'd1,
    battle_active    = 'd2,
    levelup_active   = 'd3,
    login_active     = 'd4, 
    skill_active     = 'd5
} active_state;

active_state active_state_reg ;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   active_state_reg <= idle_active;
    else if (inf.sel_action_valid) begin
        case (inf.D.d_act[0])
            Check_Inactive:    active_state_reg <= check_active;
            Battle:            active_state_reg <= battle_active;
            Level_Up:          active_state_reg <= levelup_active;
            Login:             active_state_reg <= login_active;
            Use_Skill:         active_state_reg <= skill_active;
            default:           active_state_reg <= idle_active;
        endcase
    end
    else if (current_state ==IDLE) active_state_reg <= idle_active;
    else  active_state_reg <= active_state_reg;
end

//==============================================//
//                   Counter                    //
// ============================================ //
logic [4:0] calu_cnt ; 

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   calu_cnt <= '0;
    else if (current_state == CALU)
        calu_cnt <= calu_cnt + 1;
    else
        calu_cnt <= '0;
end
//==============================================//
//                    FSM                       //
// ============================================ //
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin
    case (current_state)
        IDLE:  begin
            if(inf.sel_action_valid)
                next_state = ACTION;
            else
                next_state = IDLE;
        end
        ACTION:    begin
            case(active_state_reg)
                check_active:   next_state = (player_no_valid_reg && dram_read_valid) ? CALU : ACTION ;
                battle_active:  next_state = (battle_get_alldata) ? CALU : ACTION ;
                levelup_active: next_state = (player_no_valid_reg && dram_read_valid) ? CALU : ACTION ;
                login_active:   next_state = (player_no_valid_reg && dram_read_valid) ? CALU : ACTION ;
                skill_active:   next_state = (mp_cnt>3 && dram_read_valid) ? CALU : ACTION ;
                default:        next_state = IDLE ;
            endcase
        end
        CALU : begin // Opt
            case(active_state_reg)
                check_active:   next_state = OUT ;
                battle_active:  next_state = (hp_flag)  ? OUT : (calu_cnt > 3) ? WAIT_DRAM :  CALU;
                levelup_active: next_state = (exp_flag) ? OUT : (calu_cnt > 6) ? WAIT_DRAM :  CALU;
                login_active:   next_state = WAIT_DRAM ;
                skill_active:   next_state = (mp_flag) ? OUT : (calu_cnt > 3) ? WAIT_DRAM :  CALU;
                default:        next_state = WAIT_DRAM ;
            endcase
        end
        WAIT_DRAM: next_state = (dram_write_valid)? OUT : WAIT_DRAM ;
        OUT:       next_state = IDLE ;
        default:    next_state = IDLE;
    endcase
end

//==============================================
// Player No. register
//=============================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        player_no_reg <= '0;
    end
    else if (inf.player_no_valid) begin
        player_no_reg <= inf.D.d_player_no[0];
    end
    else begin
        player_no_reg <= player_no_reg;
    end
end
//==============================================
// Mode and Type register
//=============================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        type_reg <= '0;
    end
    else if (inf.type_valid) begin
        type_reg <= inf.D.d_type[0];
    end
    else begin
        type_reg <= type_reg;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        mode_reg <= '0;
    end
    else if (inf.mode_valid) begin
        mode_reg <= inf.D.d_mode[0];
    end
    else begin
        mode_reg <= mode_reg;
    end
end

//==============================================
// Login
//=============================================

date_diff_calculator day_diff (
    .old_month  (player_data.M),
    .old_day    (player_data.D),
    .new_month  (today_month),
    .new_day    (today_day),
    .days_diff  (days_diff)
); //DFF

assign consecutive = ( (current_state == CALU ) && (days_diff == 1) ) ? 1'b1 : 1'b0 ;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        today_month <= '0;
    end
    else if (inf.date_valid) begin
        today_month <= inf.D.d_date[0].M;
    end
    else if (current_state == IDLE) begin
        today_month <= '0;
    end
    else begin
        today_month <= today_month;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        today_day <= '0;
    end
    else if (inf.date_valid) begin
        today_day <= inf.D.d_date[0].D;
    end
    else if (current_state == IDLE) begin
        today_day <= '0;
    end
    else begin
        today_day <= today_day;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        player_no_valid_reg <= 0;
    end
    else if (current_state == IDLE) begin
        player_no_valid_reg <= 0;
    end
    else if (inf.player_no_valid) begin
        player_no_valid_reg <= 1;
    end
    else begin
        player_no_valid_reg <= player_no_valid_reg;
    end
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        login_done <= 0;
    end
    else if (inf.player_no_valid && (active_state_reg == login_active)) begin
        login_done <= 1;
    end
    else if (current_state == IDLE) begin
        login_done <= 0;
    end
    else begin
        login_done <= login_done;
    end
end

// assign login_get_alldata = dram_read_valid && (current_state == LOGIN);
//==============================================
// Level UP
//=============================================
always_comb begin
    if( (active_state_reg == levelup_active) && (current_state!=ACTION))
        case (mode_reg) 
            Easy   : exp_flag = (player_data.Exp < 4095) ;
            Normal : exp_flag = (player_data.Exp < 16383) ;
            Hard   : exp_flag = (player_data.Exp < 32767) ;
            default: exp_flag = 0 ;
        endcase
    else
        exp_flag = 0 ;
end
// assign exp_flag = 0 ;

//sort
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        A[0] <= '0;
        A[1] <= '0;
        A[2] <= '0;
        A[3] <= '0;
    end  
    else if( (active_state_reg == levelup_active)) begin
        A[0] <= sort_out_select[0];
        A[1] <= sort_out_select[1];
        A[2] <= sort_out_select[2];
        A[3] <= sort_out_select[3];
    end
    else begin
        A[0] <= '0;
        A[1] <= '0;
        A[2] <= '0;
        A[3] <= '0;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        attribute_sum <= '0;
    end  
    else if ( (calu_cnt == 0) && (active_state_reg == levelup_active) ) begin
        attribute_sum <= player_data.Attack + player_data.Defense + player_data.HP + player_data.MP ;
    end
    else begin
        attribute_sum <= '0;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        attribute_avg <= '0;
    end  
    else if ( (calu_cnt == 1) && (active_state_reg == levelup_active) ) begin
        attribute_avg <= attribute_sum / 8 ;
    end
    else if (current_state == IDLE) begin
        attribute_avg <= '0;
    end
    else begin
        attribute_avg <= attribute_avg;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        delta[0] <= '0;
        delta[1] <= '0;
        delta[2] <= '0;
        delta[3] <= '0;
    end  
    else if ( (current_state == CALU) && (active_state_reg == levelup_active) ) begin
        case (type_reg) 
            Type_A : begin
                delta[0] <= attribute_avg;
                delta[1] <= attribute_avg;
                delta[2] <= attribute_avg;
                delta[3] <= attribute_avg;
            end
            Type_B : begin
                delta[0] <= (min1 == MP)      ? (A[2] - A[0]) : (min2 == MP)     ? (A[3] - A[1]) : 0;
                delta[1] <= (min1 == HP)      ? (A[2] - A[0]) : (min2 == HP)     ? (A[3] - A[1]) : 0;
                delta[2] <= (min1 == ATTACK)  ? (A[2] - A[0]) : (min2 == ATTACK) ? (A[3] - A[1]) : 0;
                delta[3] <= (min1 == DEFENSE) ? (A[2] - A[0]) : (min2 == DEFENSE)? (A[3] - A[1]) : 0;
            end
            Type_C : begin
                delta[0] <= (player_data.MP < 16383)      ? 16383 - player_data.MP      : 0 ;
                delta[1] <= (player_data.HP < 16383)      ? 16383 - player_data.HP      : 0 ;
                delta[2] <= (player_data.Attack < 16383)  ? 16383 - player_data.Attack  : 0 ;
                delta[3] <= (player_data.Defense < 16383) ? 16383 - player_data.Defense : 0 ;
            end
            Type_D : begin //critical path 
                // delta[0] <= ( player_data.MP < 32784) ? 5047 :  3000 +( ( 65535 - player_data.MP) >> 4) ;
                // delta[1] <= ( player_data.HP < 32784) ? 5047 :  3000 +( ( 65535 - player_data.HP) >> 4) ;
                // delta[2] <= ( player_data.Attack < 32784) ? 5047 :  3000 +( ( 65535 - player_data.Attack) >> 4 ) ;
                // delta[3] <= ( player_data.Defense < 32784) ? 5047 :  3000 +( ( 65535 - player_data.Defense) >> 4 ) ;
                delta[0] <= ( player_data.MP < 32784) ? 5047 :  7095 - (player_data.MP >> 4) ;
                delta[1] <= ( player_data.HP < 32784) ? 5047 :  7095 - (player_data.HP >> 4) ;
                delta[2] <= ( player_data.Attack < 32784) ? 5047 :  7095 - (player_data.Attack >> 4) ;
                delta[3] <= ( player_data.Defense < 32784) ? 5047 :  7095 - (player_data.Defense >> 4) ;

            end
            default : begin
                delta[0] <= delta[0];
                delta[1] <= delta[1];
                delta[2] <= delta[2];
                delta[3] <= delta[3];
            end
        endcase
    end
    else begin
        delta[0] <= delta[0];
        delta[1] <= delta[1];
        delta[2] <= delta[2];
        delta[3] <= delta[3];
    end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        delta_final[0] <= '0;
        delta_final[1] <= '0;
        delta_final[2] <= '0;
        delta_final[3] <= '0;
    end  
    else if ( (current_state == CALU) && (active_state_reg == levelup_active) ) begin
        case (mode_reg) 
            Easy   : begin
                delta_final[0] <= delta[0] - (delta[0] >> 2) ;
                delta_final[1] <= delta[1] - (delta[1] >> 2) ;
                delta_final[2] <= delta[2] - (delta[2] >> 2) ;
                delta_final[3] <= delta[3] - (delta[3] >> 2) ;
            end
            Normal : begin
                delta_final[0] <= delta[0] ;
                delta_final[1] <= delta[1] ;
                delta_final[2] <= delta[2] ;
                delta_final[3] <= delta[3] ;
            end
            Hard   : begin
                delta_final[0] <= delta[0] + (delta[0] >> 2) ;
                delta_final[1] <= delta[1] + (delta[1] >> 2) ;
                delta_final[2] <= delta[2] + (delta[2] >> 2) ;
                delta_final[3] <= delta[3] + (delta[3] >> 2) ;
            end
            default : begin
                delta_final[0] <= delta_final[0];
                delta_final[1] <= delta_final[1];
                delta_final[2] <= delta_final[2];
                delta_final[3] <= delta_final[3];
            end
        endcase
    end
    else begin
        delta_final[0] <= delta_final[0];
        delta_final[1] <= delta_final[1];
        delta_final[2] <= delta_final[2];
        delta_final[3] <= delta_final[3];
    end
end

//==============================================
// Battle
//=============================================

assign hp_flag  = (player_data.HP == 0 );
assign battle_get_alldata = dram_read_valid && (monster_cnt == 3);
assign damage_2player  = ( monster_Attack < player_data.Defense) ? 17'h10000 : monster_Attack - player_data.Defense ;
assign damage_2monster = ( player_data.Attack < monster_Defense) ? 17'h10000 : player_data.Attack - monster_Defense ;

always_comb begin
    if (!damage_2player[16])
        player_HP_temp = (player_data.HP < damage_2player) ? 17'h10000 : player_data.HP - damage_2player;
    else 
        player_HP_temp = (player_data.HP) ;
end

always_comb begin
    if (!damage_2monster[16])
        monster_HP_temp = (monster_HP < damage_2monster) ? 17'h10000 : monster_HP - damage_2monster ;
    else 
        monster_HP_temp =  (monster_HP) ;
end

always_comb begin
    case(1)
        (!player_HP_temp[16]) && (monster_HP_temp[15:0] == 0) : battle_Result = WIN ;
        (player_HP_temp[15:0] == 0)  : battle_Result = LOSS ;
        (!player_HP_temp[16]) && (!monster_HP_temp[16]) : battle_Result = TIE ;
        default : battle_Result = TIE ;
    endcase
end
//monster info

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)                   monster_cnt <= 0;
    else if (current_state == IDLE)   monster_cnt <= 0;
    else if (inf.monster_valid)       monster_cnt <= monster_cnt+1;
    else                              monster_cnt <= monster_cnt;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        monster_Attack <= '0;
    end
    else if (inf.monster_valid && (monster_cnt == 0)) begin
        monster_Attack <= inf.D.d_attribute[0];
    end
    else begin
        monster_Attack <= monster_Attack;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        monster_Defense <= '0;
    end
    else if (inf.monster_valid && (monster_cnt == 1)) begin
        monster_Defense <= inf.D.d_attribute[0];
    end
    else begin
        monster_Defense <= monster_Defense;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        monster_HP <= '0;
    end
    else if (inf.monster_valid && (monster_cnt == 2)) begin
        monster_HP <= inf.D.d_attribute[0];
    end
    else begin
        monster_HP <= monster_HP;
    end
end

//==============================================
// Skill
//=============================================

assign mp_flag = player_data.MP < mp_skill_reg[0] ;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)                   mp_cnt <= 0;
    else if (current_state == IDLE)   mp_cnt <= 0;
    else if (inf.MP_valid)            mp_cnt <= mp_cnt+1;
    else                              mp_cnt <= mp_cnt;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        for(i=0;i<4;i=i+1) begin
            mp_skill[i] <= '0;
        end
    end
    else if (inf.MP_valid) begin
        case (mp_cnt)
            0: mp_skill[0] <= inf.D.d_attribute[0];
            1: mp_skill[1] <= inf.D.d_attribute[0];
            2: mp_skill[2] <= inf.D.d_attribute[0];
            3: mp_skill[3] <= inf.D.d_attribute[0];
        endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        mp_skill_reg[0] <= '0;
        mp_skill_reg[1] <= '0;
        mp_skill_reg[2] <= '0;
        mp_skill_reg[3] <= '0;
    end
    else begin
        mp_skill_reg[0] <= mp_skill_sort[0];
        mp_skill_reg[1] <= mp_skill_sort[1];
        mp_skill_reg[2] <= mp_skill_sort[2];
        mp_skill_reg[3] <= mp_skill_sort[3];
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   mp_remain <= '0;
    else if(current_state == IDLE)  mp_remain <= '0;
    else if(current_state == CALU) begin
        case(calu_cnt)
            0:  mp_remain <= player_data.MP - mp_skill_reg[0] ;
            1:  mp_remain <= (mp_remain >= mp_skill_reg[1]) ? mp_remain - mp_skill_reg[1] : mp_remain ;
            2:  mp_remain <= (mp_remain >= mp_skill_reg[2]) ? mp_remain - mp_skill_reg[2] : mp_remain ;
            3:  mp_remain <= (mp_remain >= mp_skill_reg[3]) ? mp_remain - mp_skill_reg[3] : mp_remain ;
            default: mp_remain <= mp_remain ;
        endcase 
    end
    else  mp_remain <= mp_remain ;
end

always_comb begin
    if(active_state_reg == skill_active) begin
        sort_select[0] = mp_skill[0];
        sort_select[1] = mp_skill[1];
        sort_select[2] = mp_skill[2];
        sort_select[3] = mp_skill[3];
    end
    else begin
        sort_select[0] = player_data.MP ;
        sort_select[1] = player_data.HP ; 
        sort_select[2] = player_data.Attack ;
        sort_select[3] = player_data.Defense ;
    end
end

always_comb begin
    if(active_state_reg == skill_active) begin
        mp_skill_sort[0] = sort_out_select[0];
        mp_skill_sort[1] = sort_out_select[1];
        mp_skill_sort[2] = sort_out_select[2];
        mp_skill_sort[3] = sort_out_select[3];
    end
    else begin
        mp_skill_sort[0] = 0;
        mp_skill_sort[1] = 0;
        mp_skill_sort[2] = 0;
        mp_skill_sort[3] = 0;
    end
end

MergeSort_4 sort4 (
    .in1 (sort_select[0]),
    .in2 (sort_select[1]),
    .in3 (sort_select[2]),
    .in4 (sort_select[3]),
    .out1(sort_out_select[0]),
    .out2(sort_out_select[1]),
    .out3(sort_out_select[2]),
    .out4(sort_out_select[3]),
    .min1 (min1) , 
    .min2 (min2)
);
//==============================================
// Date Check
//=============================================
assign date_flag = ( active_state_reg == check_active ) && 
                   ( current_state == CALU ) &&
                   ( days_diff > 90) ;

//==============================================
// Update New Info
//=============================================
assign exceed_exp     = (exp_new[16]) ;  //opt
assign exceed_mp      = (mp_new[16]) ;
assign exceed_attack  = (attack_new[16]) ;
assign exceed_defense = (defense_new[16]) ;
assign exceed_hp      = (hp_new[16]) ;

assign less_exp       = (exp_new[17]) ;
assign less_mp        = (mp_new[17]) ;
assign less_attack    = (attack_new[17]) ;
assign less_defense   = (defense_new[17]) ;
assign less_hp        = (hp_new[17]) ; //here has problem

assign exp_out      = exceed_exp    ? 16'hFFFF : exp_new[15:0] ;
assign mp_out       = exceed_mp     ? 16'hFFFF : mp_new[15:0] ;
assign attack_out   = exceed_attack ? 16'hFFFF : attack_new[15:0] ;
assign defense_out  = exceed_defense? 16'hFFFF : defense_new[15:0] ;
assign hp_out       = exceed_hp     ? 16'hFFFF : hp_new[15:0] ;
assign month_out    = (active_state_reg == login_active) ? today_month :  player_data.M ;
assign day_out      = (active_state_reg == login_active) ? today_day   :  player_data.D ;


always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   exp_new  <= '0;
    else if(current_state == IDLE)  exp_new  <= '0;
    else if(current_state == CALU) begin
        if((active_state_reg==battle_active)) begin
            case(battle_Result)
                WIN :   exp_new <= player_data.Exp + 16'd2048; //exp will not lower 2048 Opt
                LOSS:   exp_new <= (player_data.Exp < 16'd2048 )? 18'h20000: player_data.Exp - 16'd2048 ;
                default: exp_new <= player_data.Exp ;
            endcase
        end
        else if ((active_state_reg==login_active) && consecutive) exp_new <= player_data.Exp + 512;
        else exp_new <= player_data.Exp ;
    end
    else  exp_new <= exp_new ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   mp_new  <= '0;
    else if(current_state == IDLE)  mp_new  <= '0;
    else if(current_state == CALU) begin
        if(active_state_reg == battle_active && (battle_Result == WIN))
            mp_new <= player_data.MP + 16'd2048;
        else if (active_state_reg == skill_active)
            mp_new <= mp_remain;
        else if (active_state_reg == levelup_active)
            mp_new <= player_data.MP + delta_final[0] ;
        else if((active_state_reg==login_active) && consecutive)  mp_new <= player_data.MP + 1024; 
        else
            mp_new <= player_data.MP ;
    end
    else  mp_new <= mp_new ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   hp_new  <= '0;
    else if(current_state == IDLE)  hp_new  <= '0;
    else if(current_state == CALU) begin
        if(active_state_reg == battle_active)
            hp_new <= (player_HP_temp[16]) ? 18'h20000 :  player_HP_temp ;
        else if (active_state_reg == levelup_active)
            hp_new <= player_data.HP + delta_final[1] ;
        else
            hp_new <= player_data.HP ;
    end
    else  hp_new <= hp_new ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   attack_new  <= '0;
    else if(current_state == IDLE)  attack_new  <= '0;
    else if (current_state == CALU) begin
        if((battle_Result==LOSS) && (active_state_reg == battle_active))
            attack_new <= (player_data.Attack < 16'd2048) ? 18'h20000 : player_data.Attack - 16'd2048 ; //unsigned? 
        else if (active_state_reg == levelup_active)
            attack_new <= player_data.Attack + delta_final[2] ;
        else  
            attack_new <= player_data.Attack ;
    end
    else attack_new <= attack_new ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   defense_new  <= '0;
    else if(current_state == IDLE)  defense_new  <= '0;
    else if (current_state == CALU) begin
        if((battle_Result==LOSS) && (active_state_reg == battle_active))
            defense_new <= (player_data.Defense < 16'd2048) ? 18'h20000 : player_data.Defense - 16'd2048 ; //unsigned? 
        else if (active_state_reg == levelup_active)
            defense_new <= player_data.Defense + delta_final[3] ;
        else  
            defense_new <= player_data.Defense ;
    end
    else  defense_new <= defense_new ;
end
//==============================================
// Warn Message
//=============================================
assign saturation_flag = ( exceed_exp || exceed_mp || exceed_hp || exceed_attack || exceed_defense ||
                           less_exp   || less_mp   || less_hp   || less_attack   || less_defense   )  ;

Warn_Msg warn_message ;

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        warn_message <= No_Warn ;
    end
    else begin
        case (active_state_reg)
            login_active : begin
                if (saturation_flag) warn_message <= Saturation_Warn ;
                else                 warn_message <= No_Warn ;
            end
            check_active: begin
                if (date_flag)       warn_message <= Date_Warn ;
                else                 warn_message <= No_Warn ;
            end
            skill_active: begin
                if (mp_flag)         warn_message <= MP_Warn ;
                else                 warn_message <= No_Warn ;
            end
            battle_active: begin
                if (hp_flag)                 warn_message <= HP_Warn ;
                else if (saturation_flag)    warn_message <= Saturation_Warn ;
                else                         warn_message <= No_Warn ;
            end
            levelup_active: begin
                if (exp_flag)               warn_message <= Exp_Warn ;
                else if (saturation_flag)   warn_message <= Saturation_Warn ;
                else                        warn_message <= No_Warn ;
            end
            // idle_active: warn_message <= No_Warn ;
            default: warn_message <= warn_message ;
        endcase
    end
end


assign complete_comb = (warn_message == No_Warn) ;

//==============================================
// DRAM control
//=============================================

always_comb begin
    if(current_state == WAIT_DRAM) 
    dram_out_data = {hp_out, 4'd0 ,month_out, 3'd0 ,day_out,
                    attack_out,defense_out,
                    exp_out, mp_out};
    else            dram_out_data = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   dram_read_valid <= 1'b0;
    else if (current_state == IDLE) dram_read_valid <= 1'b0;
    else if (dram_read_temp) dram_read_valid <= 1'b1;
    else dram_read_valid <= dram_read_valid;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)   player_data <= '0;
    else if (current_state == IDLE) player_data <= '0;
    else if (dram_read_temp) player_data <= player_data_temp;
    else player_data <= player_data;
end

Read_DRAM u_read_dram (
    .clk        (clk),
    .in_valid   (inf.player_no_valid),
    .player_no  (player_no_reg),
    .out_data   (player_data_temp),
    .out_valid  (dram_read_temp),
    .inf        (inf) 
);

assign write_valid = (current_state != WAIT_DRAM) && (next_state == WAIT_DRAM) ;

Write_DRAM u_write_dram (
    .clk        (clk),
    .in_valid   (write_valid),
    .player_no  (player_no_reg),
    .in_data    (dram_out_data),
    .out_valid  (dram_write_valid),
    .inf        (inf) 
);


//--------------OUTPUT----------------//
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.complete <= 1'b0;
    end
    else if (current_state == OUT) begin
        inf.complete <= complete_comb;
    end
    else inf.complete <= 1'b0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.warn_msg <= No_Warn;
    end
    else if (current_state == OUT)begin
        inf.warn_msg <= warn_message;
    end
    else 
        inf.warn_msg <= No_Warn;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.out_valid <= 1'b0;
    end
    else begin
        inf.out_valid <= (current_state == OUT);
    end
end

//==============================================//


endmodule

module Read_DRAM 
(
    clk, in_valid,
    player_no,  out_data , out_valid,
    inf
);
input  clk , in_valid;

input        [7:0]      player_no;  //0~255
output  Player_Info      out_data;
output logic            out_valid;
INF.RPG_inf inf;
//==============================================
// FSM
//=============================================

typedef enum logic [1:0] {
    IDLE     = 'd0,
    REQ      = 'd1,
    WAIT     = 'd2,
    FINISH   = 'd3
} FSM_state;

FSM_state current_state, next_state;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin
    case(current_state)
        IDLE:     next_state = (in_valid)     ? REQ    : IDLE ;
        REQ:      next_state = (inf.AR_READY) ? WAIT   : REQ  ;
        WAIT:     next_state = (inf.R_VALID)  ? FINISH : WAIT ;
        FINISH:   next_state = IDLE ; 
        default:  next_state = IDLE;
    endcase
end
//==============================================
// design
//=============================================
//inf.AR_ADDR
logic [11:0] addr;
assign addr = player_no * 12'd12;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AR_ADDR <= 17'b0;
    else if(in_valid || current_state ==REQ) begin 
        inf.AR_ADDR <= {1'b1,4'b0,addr} ;
    end
    else inf.AR_ADDR <= 17'b0;
end

//inf.AR_VALID
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        inf.AR_VALID <= 1'b0;
    else if(in_valid || current_state ==REQ)
        inf.AR_VALID <= 1'b1;
    else
        inf.AR_VALID <= 1'b0;
end

//inf.R_READY
assign inf.R_READY =( (current_state==REQ) ||(current_state == WAIT) ) ? 1'b1 : 1'b0;

//=============================================
assign out_valid = inf.R_VALID;

always_comb begin
     if (next_state == FINISH)begin
        out_data.HP     = inf.R_DATA[95:80];
        out_data.M      = inf.R_DATA[79:72];
        out_data.D      = inf.R_DATA[71:64];
        out_data.Attack = inf.R_DATA[63:48];
        out_data.Defense= inf.R_DATA[47:32];
        out_data.Exp    = inf.R_DATA[31:16];
        out_data.MP     = inf.R_DATA[15:0];
        // out_data <= inf.R_DATA;
    end
    else out_data =  0; 

end

endmodule

module Write_DRAM
(
    clk, in_valid,out_valid,
    player_no,
    in_data,
    inf
);
input                 clk , in_valid;
input         [7:0]   player_no;  //0~255
input         [95:0]  in_data;
output logic          out_valid;
INF.RPG_inf inf;

//==============================================
// FSM
//=============================================

typedef enum logic [1:0] {
    IDLE    = 'd0,
    REQ     = 'd1,
    WRITE   = 'd2,
    WAIT    = 'd3
} FSM_state;

FSM_state current_state, next_state;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin
    case(current_state)
        IDLE : next_state = (in_valid)     ? REQ  : IDLE;
        REQ  : next_state = (inf.AW_READY) ? WRITE: REQ;
        WRITE: next_state = (inf.W_READY)  ? WAIT : WRITE;
        WAIT : next_state = (inf.B_VALID)  ? IDLE : WAIT;
        default: next_state = IDLE;
    endcase
end
//==============================================
// design
//=============================================
logic [11:0] addr;
assign addr = player_no * 12'd12;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AW_ADDR <= 17'b0;
    else if((current_state ==REQ) )begin 
        inf.AW_ADDR <= {1'b1,4'b0,addr} ;
    end
    else inf.AW_ADDR <= 17'b0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) inf.AW_VALID <= 0;
    else            inf.AW_VALID <= (current_state == REQ) ;
end

// assign inf.AW_VALID  = (current_state == REQ) ;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) inf.W_VALID <=0;
    else            inf.W_VALID <= (current_state == WRITE);
end
// assign inf.W_VALID   = (current_state == WRITE);
assign inf.B_READY  = (current_state == WRITE) || (current_state == WAIT);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)  inf.W_DATA <= 0;
    else if (current_state == WRITE)  inf.W_DATA <= in_data;
end

assign out_valid = inf.B_VALID;

endmodule

module date_diff_calculator (
    input  logic [3:0]  old_month,    // 1-12
    input  logic [4:0]  old_day,      // 1-31
    input  logic [3:0]  new_month,    // 1-12
    input  logic [4:0]  new_day,      // 1-31
    output logic [8:0]  days_diff     // 0-365
);
    logic [8:0] doy_old, doy_new;
    always_comb begin
        case (old_month)
            4'd1:  doy_old = 9'd0 + old_day;
            4'd2:  doy_old = 9'd31 + old_day;
            4'd3:  doy_old = 9'd59 + old_day;
            4'd4:  doy_old = 9'd90 + old_day;
            4'd5:  doy_old = 9'd120 + old_day;
            4'd6:  doy_old = 9'd151 + old_day;
            4'd7:  doy_old = 9'd181 + old_day;
            4'd8:  doy_old = 9'd212 + old_day;
            4'd9:  doy_old = 9'd243 + old_day;
            4'd10: doy_old = 9'd273 + old_day;
            4'd11: doy_old = 9'd304 + old_day;
            4'd12: doy_old = 9'd334 + old_day;
            default: doy_old = 9'd0;
        endcase
    end

    always_comb begin
        case (new_month)
            4'd1:  doy_new = 9'd0 + new_day;
            4'd2:  doy_new = 9'd31 + new_day;
            4'd3:  doy_new = 9'd59 + new_day;
            4'd4:  doy_new = 9'd90 + new_day;
            4'd5:  doy_new = 9'd120 + new_day;
            4'd6:  doy_new = 9'd151 + new_day;
            4'd7:  doy_new = 9'd181 + new_day;
            4'd8:  doy_new = 9'd212 + new_day;
            4'd9:  doy_new = 9'd243 + new_day;
            4'd10: doy_new = 9'd273 + new_day;
            4'd11: doy_new = 9'd304 + new_day;
            4'd12: doy_new = 9'd334 + new_day;
            default: doy_new = 9'd0;
        endcase
    end

    always_comb begin
        if (doy_new >= doy_old) begin
            days_diff = doy_new - doy_old;
        end else begin
            days_diff = 365 - doy_old + doy_new;
        end
    end

endmodule

module compare2 (
    input  [17:0] in1, in2,
    output [17:0] out1, out2 // out1: min, out2: max
);
    assign out1 = (in1 > in2) ? in2 : in1;
    assign out2 = (in1 > in2) ? in1 : in2;
endmodule

module MergeSort_4 (
    input  [15:0] in1, in2, in3, in4,
    output [15:0] out1, out2, out3, out4, // out1 : smallest value
    output [1:0]  min1, min2            
);
    wire [17:0] d1, d2, d3, d4;
    wire [17:0] c1, c2, c3, c4, c5, c6;
    wire [17:0] res1, res2, res3, res4;

    assign d1 = {in1, 2'd0};
    assign d2 = {in2, 2'd1};
    assign d3 = {in3, 2'd2};
    assign d4 = {in4, 2'd3};

    compare2 COM_1 (.in1(d1), .in2(d2), .out1(c1), .out2(c2)); // c1=min(1,2)
    compare2 COM_2 (.in1(d3), .in2(d4), .out1(c3), .out2(c4)); // c3=min(3,4)
    compare2 COM_3 (.in1(c4), .in2(c2), .out1(c5), .out2(res4)); 
    compare2 COM_4 (.in1(c1), .in2(c3), .out1(res1), .out2(c6));

    compare2 COM_5 (.in1(c5), .in2(c6), .out1(res2), .out2(res3));

    assign out1 = res1[17:2];
    assign out2 = res2[17:2]; 
    assign out3 = res3[17:2];
    assign out4 = res4[17:2]; 

    assign min1 = res1[1:0];
    assign min2 = res2[1:0]; 

endmodule

//RPG_done
// Cycle: 15.00
// Area: 115311.370340
// Performance: 1729670.55510000

// Cycle: 10.00
// Area: 118376.799048
// Performance: 1183767.99048000

// Cycle: 8.00
// Area: 121582.843997
// Performance: 972662.75197600

// Cycle: 7.00 
// Area: 130707.259802
// Performance: 914950.81861400

//Cycle: 6.00  02 have timing problem

//==============================================Optimize Type C formula
// Cycle: 7.00
// Area: 128582.395726
// Performance: 900076.77008200

//SEED 1228