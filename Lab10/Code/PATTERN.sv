// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
// `define SEED        1228 //** 321
`define SEED        1234
// `define SEED        4121717
`define PAT_NUM    6400
// `define CYCLE_TIME 3.3

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

// ==============
//     Colors
// ==============
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PAT_NUM  = `PAT_NUM;
// parameter CLK_TIME = `CYCLE_TIME;
parameter DRAM_BASE_ADDR = 17'h10000;
parameter BYTES_PER_PLAYER = 12;
parameter MAX_CYCLE=1000;

integer seed = `SEED;
integer total_lat, lat;
integer i, i_pat;
integer max_skills_found,current_num_skills;    
integer player_last_seen [0:255];
integer train_cnt = 0;
integer mode_cnt = 0; 
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+12*256)-1):(65536+0)];  

Action        given_action;
Training_Type given_type;
Mode          given_mode; 
Date          given_date;
Player_No     given_player_no;
logic [15:0]  monster_atk, monster_def, monster_hp; 
logic [15:0]  given_skills [4]; 
string debug_battle_result;
Player_Info   golden_player; 
Warn_Msg      golden_warn_msg;
logic         golden_complete;
logic         saturation_flag; 
// ===============================================================
// Debug Variables (Global for visibility in check_task)
// ===============================================================

// For Level Up Debug
logic [16:0] debug_delta_i_mp, debug_delta_i_hp, debug_delta_i_atk, debug_delta_i_def;
logic [16:0] debug_delta_final_mp, debug_delta_final_hp, debug_delta_final_atk, debug_delta_final_def;

// For Battle Debug
logic signed [16:0] debug_dmg_to_player, debug_dmg_to_monster;
logic [18:0] debug_player_hp_temp, debug_monster_hp_temp;

// For Use Skill Debug
logic [16:0] debug_total_cost;
logic [16:0] debug_min_skill_cost;

//================================================================
// class random
//================================================================

class random_act;
    randc Action act_id;
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        act_id inside {Login, Level_Up, Battle, Use_Skill, Check_Inactive};
    } 
endclass

class random_training;
    randc Training_Type traintype;
    randc Mode          mode;
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        traintype inside {Type_A, Type_B, Type_C, Type_D}; 
        mode inside {Easy, Normal, Hard};
    }
endclass

class random_date;
    randc Date date;
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        date.M inside{[1:12]};
        (date.M == 1 | date.M == 3 | date.M == 5 | date.M == 7 | date.M == 8 | date.M == 10 | date.M == 12) -> date.D inside{[1:31]};
        (date.M == 4 | date.M == 6 | date.M == 9 | date.M == 11) -> date.D inside{[1:30]};
        (date.M == 2) -> date.D inside{[1:28]};
    }
endclass

class random_player_no;
    randc Player_No player_no;
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        player_no inside {[0:255]};
    }
endclass

class random_monster;
    randc logic [15:0] attack;
    randc logic [15:0] defense;
    randc logic [15:0] hp;
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        attack  inside {[0:65535]};
        defense inside {[0:65535]};
        hp      inside {[1:65535]}; 
    }
endclass

class random_skills;
    randc logic [15:0] skill_mp[4];
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        foreach (skill_mp[i]) {
        skill_mp[i] inside {[1:65535]};
        }
    }
endclass

random_act       r_action;
random_training  r_training;
random_date      r_date;
random_player_no r_player_no;
random_monster   r_monster;
random_skills    r_skills;

//================================================================
// initial
//================================================================
// initial $readmemh(DRAM_p_r, golden_DRAM);

initial begin
    $display("\033[1;31m  _       __  ______   ____    \033[0m");
    $display("\033[1;32m | |     / / / ____/  /  _/     \033[0m");
    $display("\033[1;33m | | /| / / / __/     / /     \033[0m");
    $display("\033[1;34m | |/ |/ / / /___   _/ /     \033[0m");
    $display("\033[1;31m |__/|__/ /_____/  /___/      \033[0m");
    $display("\033[1;33m                             \033[0m");
    r_action    = new(seed);
    r_training  = new(seed);
    r_date      = new(seed);
    r_player_no = new(seed);
    r_monster   = new(seed);
    r_skills    = new(seed);

    for(i=0; i<256; i++) begin
        player_last_seen[i] = -1;
    end

    $readmemh(DRAM_p_r, golden_DRAM);
    reset_signal_task;

    for (i_pat=0; i_pat<PAT_NUM; i_pat++) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;

        total_lat += lat;
        // if(i_pat%10000 == 0)
        //     $display("\033[0;34mPASS PATTERN NO.%4d, \033[m \033[0;32m Execution Cycle: %3d \033[0;32m  \033[0;33m%s\033[0;33m ", i_pat, lat,get_action_name(given_action));
    end
    YOU_PASS_task;
end

//---------------------------------------------------------------------
//   TASKS
//---------------------------------------------------------------------
task reset_signal_task;
begin
    inf.rst_n            = 1;
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.mode_valid       = 0;
    inf.date_valid       = 0;
    inf.player_no_valid  = 0;
    inf.monster_valid    = 0;
    inf.MP_valid         = 0;
    inf.D                = 'bx;
    total_lat            = 0;

    #12; inf.rst_n = 0; 
    #12; inf.rst_n = 1;

    #12; release clk;

end
endtask

task input_task; begin
    @(negedge clk); 
    give_action;
    // repeat($urandom_range(1, 4)) @(negedge clk); 
    
    case(given_action)
        Login: begin
            give_date;
            give_player_no;
        end
        Level_Up: begin
            give_type;
            give_mode;
            give_player_no;
        end
        Battle: begin
            give_player_no;
            give_monster; 
        end
        Use_Skill: begin
            give_player_no;
            give_skills;
        end
        Check_Inactive: begin
            give_date;
            give_player_no;
        end
    endcase
end
endtask

task wait_out_valid_task; begin
    lat = 0;
    while(inf.out_valid !== 1) begin
        lat += 1;
        if(lat === MAX_CYCLE) begin
        $display("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                         %0sFAIL!%0s                                           ", txt_red_prefix, reset_color);
        $display("                                                        PATTERN NO.%4d                                                                 ", i_pat);
        $display("                                    The execution latency should not over 1000 cycles                                                  ");
        $display("--------------------------------------------------------------------------------------------------------------------------------------------");
        YOU_FAIL_task;
        end
        @(negedge clk);
    end
end endtask

task check_ans_task; begin
    unpack_golden_dram;
    
    saturation_flag = 1'b0; 
    golden_warn_msg = No_Warn; 

    case(given_action)
        Login          : Login_task;
        Level_Up       : Level_Up_task;
        Battle         : Battle_task;
        Use_Skill      : Use_Skill_task;
        Check_Inactive : Check_Inactive_task;
    endcase
    
    if (saturation_flag && golden_warn_msg == No_Warn) begin
        golden_warn_msg = Saturation_Warn;
    end

    golden_complete = (golden_warn_msg == No_Warn);

    check_task;

    pack_golden_dram;
    
end endtask

task pack_golden_dram;
    integer N;
    N = DRAM_BASE_ADDR + given_player_no * BYTES_PER_PLAYER;

    {golden_DRAM[N+1], golden_DRAM[N+0]}   = golden_player.MP;
    {golden_DRAM[N+3], golden_DRAM[N+2]}   = golden_player.Exp;
    {golden_DRAM[N+5], golden_DRAM[N+4]}   = golden_player.Defense;
    {golden_DRAM[N+7], golden_DRAM[N+6]}   = golden_player.Attack;
    golden_DRAM[N+8]  = golden_player.D;
    golden_DRAM[N+9]  = golden_player.M;
    {golden_DRAM[N+11], golden_DRAM[N+10]} = golden_player.HP;

endtask
//---------------------------------------------------------------------
//   Giver
//---------------------------------------------------------------------
task give_action; begin
    i = r_action.randomize();

    // given_action = r_action.act_id;
    inf.sel_action_valid = 1;
    if(i_pat<5000) begin
        case (i_pat%25)
            0 : given_action = Level_Up;
            1 : given_action = Level_Up;
            2 : given_action = Battle;
            3 : given_action = Battle;
            4 : given_action = Use_Skill;
            5 : given_action = Use_Skill;
            6 : given_action = Check_Inactive;
            7 : given_action = Check_Inactive;
            8 : given_action = Login;
            9 : given_action = Check_Inactive;
            10: given_action = Level_Up;
            11: given_action = Check_Inactive;
            12: given_action = Battle;
            13: given_action = Check_Inactive;
            14: given_action = Use_Skill;
            15: given_action = Login;
            16: given_action = Battle;
            17: given_action = Level_Up;
            18: given_action = Login;
            19: given_action = Use_Skill;
            20: given_action = Level_Up;
            21: given_action = Use_Skill;
            22: given_action = Battle;
            23: given_action = Login;
            24: given_action = Login;
        endcase
    end
    else
        // given_action = r_action.act_id;
        given_action = Level_Up ;
        
    if (given_action ==Level_Up) begin
        if(train_cnt == 11) train_cnt = 0;
        else train_cnt = train_cnt + 1;
    end
    inf.D.d_act[0] = given_action;
    @(negedge clk);
    inf.sel_action_valid = 0;
    inf.D = 'bx;
    
end endtask

task give_date; begin
    i = r_date.randomize();
    given_date = r_date.date;
    // @(negedge clk);
    inf.date_valid = 1;
    inf.D.d_date[0] = given_date;
    @(negedge clk);
    inf.date_valid = 0;
    inf.D = 'bx;
end endtask

task give_player_no; begin
    i = r_player_no.randomize();
    given_player_no = r_player_no.player_no;
    // @(negedge clk);
    inf.player_no_valid = 1;
    inf.D.d_player_no[0] = given_player_no;
    @(negedge clk);
    inf.player_no_valid = 0;
    inf.D = 'bx;
end endtask

task give_type; begin

    case(train_cnt)
        0,1,2 : given_type = Type_A;
        3,4,5 : given_type = Type_B;
        6,7,8 : given_type = Type_C;
        9,10,11   : given_type = Type_D;
    endcase

    case (train_cnt)
        0,3,6,9 : given_mode = Easy;
        1,4,7,10: given_mode = Normal;
        2,5,8,11 : given_mode = Hard;
    endcase

    // i = r_training.randomize(); 
    // given_type = r_training.traintype;
    // given_mode = r_training.mode; 

    // @(negedge clk); 
    inf.type_valid = 1;
    inf.D.d_type[0] = given_type;
    @(negedge clk);
    inf.type_valid = 0;
    inf.D = 'bx;
end endtask

task give_mode; begin
    
    // @(negedge clk);
    inf.mode_valid = 1;
    inf.D.d_mode[0] = given_mode;
    @(negedge clk);
    inf.mode_valid = 0;
    inf.D = 'bx;
end endtask

task give_monster; begin //not sure
    i = r_monster.randomize();
    monster_atk = r_monster.attack;
    monster_def = r_monster.defense;
    monster_hp  = r_monster.hp;
    
    // 1. Monster Attack
    // @(negedge clk);
    inf.monster_valid = 1;
    inf.D.d_attribute[0] = monster_atk;
    @(negedge clk);
    inf.monster_valid = 0;
    inf.D = 'bx;

    // 2. Monster Defense
    // @(negedge clk);
    inf.monster_valid = 1;
    inf.D.d_attribute[0] = monster_def;
    @(negedge clk);
    inf.monster_valid = 0;
    inf.D = 'bx;

    // 3. Monster HP
    // @(negedge clk);
    inf.monster_valid = 1;
    inf.D.d_attribute[0] = monster_hp;
    @(negedge clk);
    inf.monster_valid = 0;
    inf.D = 'bx;
end endtask

task give_skills; begin
    i = r_skills.randomize();
    given_skills = r_skills.skill_mp;

    for(int j=0; j<4; j++) begin
        // @(negedge clk);
        inf.MP_valid = 1;
        inf.D.d_attribute[0] = given_skills[j];
        @(negedge clk);
        inf.MP_valid = 0;
        inf.D = 'bx;
    end

end endtask

//---------------------------------------------------------------------
//   Unpack
//---------------------------------------------------------------------
logic [7:0] last_login_month, last_login_day;
Player_Info orig_player;
task unpack_golden_dram;
    integer N;
    logic [31:0] entry0, entry1, entry2;
    N = DRAM_BASE_ADDR + given_player_no * BYTES_PER_PLAYER;

    golden_player.MP      = {golden_DRAM[N+1], golden_DRAM[N+0]}; // {E1, 0A} -> 16'hE10A
    golden_player.Exp     = {golden_DRAM[N+3], golden_DRAM[N+2]}; // {22, 60} -> 16'h2260

    golden_player.Defense = {golden_DRAM[N+5], golden_DRAM[N+4]}; // {B4, 05} -> 16'hB405
    golden_player.Attack  = {golden_DRAM[N+7], golden_DRAM[N+6]}; // {D5, 93} -> 16'hD593

    golden_player.D  = golden_DRAM[N+8]; // 1D
    golden_player.M  = golden_DRAM[N+9]; // 0B
    golden_player.HP      = {golden_DRAM[N+11], golden_DRAM[N+10]}; // {36, 4F} -> 16'h364F

    last_login_month = golden_player.M;
    last_login_day   = golden_player.D;
    orig_player.MP   = golden_player.MP;
    orig_player.HP   = golden_player.HP;
    orig_player.Attack = golden_player.Attack;
    orig_player.Defense= golden_player.Defense;
    orig_player.Exp    = golden_player.Exp;
endtask

//---------------------------------------------------------------------
//  Login_task
//---------------------------------------------------------------------
logic [16:0] temp_exp, temp_mp;
logic consecutive_flag;
task Login_task;
    consecutive_flag = 0;
    if (is_consecutive({golden_player.M, golden_player.D}, given_date)) begin
        consecutive_flag = 1;
        temp_exp = sat_add(golden_player.Exp, 512);
        temp_mp  = sat_add(golden_player.MP, 1024);
        golden_player.Exp = temp_exp[15:0];
        golden_player.MP  = temp_mp[15:0];
        if (temp_exp[16] || temp_mp[16]) saturation_flag = 1'b1;
    end

    golden_player.M = given_date.M;
    golden_player.D = given_date.D;

endtask

function integer date_to_doy(Date d);
    integer doy = d.D;
    integer m = d.M - 1; // 0-based month
    // Feb=28
    automatic integer days_in_month[12] = '{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    
    while (m > 0) begin
        doy += days_in_month[m-1];
        m = m - 1;
    end
    return doy;
endfunction

function logic is_consecutive(Date old_d, Date new_d);
    integer doy_old = date_to_doy(old_d);
    integer doy_new = date_to_doy(new_d);
    
    if (doy_new == doy_old + 1) return 1;
    if (old_d.M == 12 && old_d.D == 31 && new_d.M == 1 && new_d.D == 1) return 1;
    
    return 0;
endfunction

function logic [16:0] sat_add(logic [15:0] a, logic [15:0] b);
    logic [16:0] result = a+b ;
    if (result > 65535) return 17'h1FFFF; // 65535, [16]=1
    else return {1'b0, result[15:0]};
endfunction

//---------------------------------------------------------------------
//  Level_Up_task
//---------------------------------------------------------------------

task Level_Up_task;
    logic [18:0] temp_hp, temp_mp, temp_atk, temp_def;
    logic [17:0] delta_final_mp, delta_final_hp, delta_final_atk, delta_final_def;
    logic [17:0] delta_common;
    logic [16:0] d_A0;
    logic [16:0] d_A1;
    logic [1:0]   min1 , min2 ;
    logic [15:0] exp_needed;
    
    logic [16:0] delta_i_mp, delta_i_hp, delta_i_atk, delta_i_def;
    
    logic [15:0] sorted [0:3]; 
    logic [21:0] temp;
    
    case(given_mode)
        Easy:   exp_needed = 4095; 
        Normal: exp_needed = 16383;
        Hard:   exp_needed = 32767; 
    endcase
    
    if (golden_player.Exp < exp_needed) begin
        golden_warn_msg = Exp_Warn; 
        return; 
    end

    
    case(given_type)
        Type_A: begin
            delta_common = (golden_player.MP + golden_player.HP + golden_player.Attack + golden_player.Defense) /8; 
            delta_i_mp  = delta_common;
            delta_i_hp  = delta_common;
            delta_i_atk = delta_common;
            delta_i_def = delta_common;
        end
        
        Type_B: begin
            sort4(golden_player.MP, golden_player.HP, golden_player.Attack, golden_player.Defense, sorted[0], sorted[1], sorted[2], sorted[3],min1,min2); 
            
            d_A0 = sorted[2] - sorted[0]; 
            d_A1 = sorted[3] - sorted[1];
            
            delta_i_mp  = 0;
            delta_i_hp  = 0;
            delta_i_atk = 0;
            delta_i_def = 0;
            
           
            case (min1)
                0 : delta_i_mp  = d_A0;
                1 : delta_i_hp  = d_A0;
                2 : delta_i_atk = d_A0;
                3 : delta_i_def = d_A0;
            endcase

            case (min2)
                0 : delta_i_mp  = d_A1;
                1 : delta_i_hp  = d_A1;
                2 : delta_i_atk = d_A1;
                3 : delta_i_def = d_A1;
            endcase

            
        end
        
        Type_C: begin
           
            delta_i_mp  = (golden_player.MP < 16383) ? (16383 - golden_player.MP) : 0;
            delta_i_hp  = (golden_player.HP < 16383) ? (16383 - golden_player.HP) : 0;
            delta_i_atk = (golden_player.Attack < 16383) ? (16383 - golden_player.Attack) : 0;
            delta_i_def = (golden_player.Defense < 16383) ? (16383 - golden_player.Defense) : 0;
        end
        
        Type_D: begin
            temp = 3000 + ((65535 - golden_player.MP) >> 4);
            delta_i_mp = (temp > 5047) ? 5047 : temp;
            
            temp = 3000 + ((65535 - golden_player.HP) >> 4);
            delta_i_hp = (temp > 5047) ? 5047 : temp;
            
            temp = 3000 + ((65535 - golden_player.Attack) >> 4);
            delta_i_atk = (temp > 5047) ? 5047 : temp;
            
            temp = 3000 + ((65535 - golden_player.Defense) >> 4);
            delta_i_def = (temp > 5047) ? 5047 : temp;
        end
    endcase

    // ==========================================
    // *** UPDATE DEBUG VARS (Delta_i) ***
    // ==========================================
    debug_delta_i_mp  = delta_i_mp;
    debug_delta_i_hp  = delta_i_hp;
    debug_delta_i_atk = delta_i_atk;
    debug_delta_i_def = delta_i_def;

    case(given_mode)
        Easy: begin
            delta_final_mp  = delta_i_mp  - (delta_i_mp  >> 2); // delta - floor(delta/4)
            delta_final_hp  = delta_i_hp  - (delta_i_hp  >> 2);
            delta_final_atk = delta_i_atk - (delta_i_atk >> 2);
            delta_final_def = delta_i_def - (delta_i_def >> 2);
        end
        Normal: begin
            delta_final_mp  = delta_i_mp;
            delta_final_hp  = delta_i_hp;
            delta_final_atk = delta_i_atk;
            delta_final_def = delta_i_def;
        end
        Hard: begin
            delta_final_mp  = delta_i_mp  + (delta_i_mp  >> 2); // delta + floor(delta/4)
            delta_final_hp  = delta_i_hp  + (delta_i_hp  >> 2);
            delta_final_atk = delta_i_atk + (delta_i_atk >> 2);
            delta_final_def = delta_i_def + (delta_i_def >> 2);
        end
    endcase
    // ==========================================
    // *** UPDATE DEBUG VARS (Delta_final) ***
    // ==========================================
    debug_delta_final_mp  = delta_final_mp;
    debug_delta_final_hp  = delta_final_hp;
    debug_delta_final_atk = delta_final_atk;
    debug_delta_final_def = delta_final_def;

    temp_hp  = golden_player.HP     + delta_final_hp;
    temp_mp  = golden_player.MP     + delta_final_mp;
    temp_atk = golden_player.Attack + delta_final_atk;
    temp_def = golden_player.Defense+ delta_final_def;
    
    if ((temp_hp > 65535) || (temp_mp > 65535) || (temp_atk > 65535) || (temp_def > 65535)  )
        saturation_flag = 1'b1;
    
    golden_player.HP      = (temp_hp > 65535) ? 65535 : temp_hp[15:0];
    golden_player.MP      = (temp_mp > 65535) ? 65535 : temp_mp[15:0];
    golden_player.Attack  = (temp_atk > 65535) ? 65535 : temp_atk[15:0];
    golden_player.Defense = (temp_def > 65535) ? 65535 : temp_def[15:0];
    // debug_delta_i_mp = delta_i_mp; debug_delta_i_hp = delta_i_hp;

    // debug_delta_final_mp = delta_final_mp;
endtask


task compare2 (
    input [17:0] in1,in2,
    output[17:0] out1,out2
);
    out1 = (in1 > in2) ? in2 : in1;
    out2 = (in1 > in2) ? in1 : in2;
endtask

task sort4 (
    input  [15:0] in1,in2,in3,in4,
    output [15:0] out1,out2,out3,out4, // out1 : smallest     out4 : largest
    output [1:0]  min1, min2 
);
    logic [17:0] c1,c2,c3,c4,c5,c6;
    logic [17:0] d1, d2, d3, d4;
    logic [17:0] res1, res2, res3, res4;

    d1 = {in1, 2'd0};
    d2 = {in2, 2'd1};
    d3 = {in3, 2'd2};
    d4 = {in4, 2'd3};

    compare2  (.in1(d1), .in2(d2), .out1(c1), .out2(c2)); // c1=min(1,2)
    compare2  (.in1(d3), .in2(d4), .out1(c3), .out2(c4)); // c3=min(3,4)
    compare2  (.in1(c4), .in2(c2), .out1(c5), .out2(res4)); 
    compare2  (.in1(c1), .in2(c3), .out1(res1), .out2(c6));

    compare2  (.in1(c5), .in2(c6), .out1(res2), .out2(res3));

    out1 = res1[17:2];
    out2 = res2[17:2]; 
    out3 = res3[17:2];
    out4 = res4[17:2]; 
    min1 = res1[1:0];
    min2 = res2[1:0]; 

endtask

//---------------------------------------------------------------------
//   Battle_task
//---------------------------------------------------------------------
task Battle_task;
    
    logic signed [16:0] dmg_to_player, dmg_to_monster;
    logic signed [17:0] player_hp_temp, monster_hp_temp;
    logic signed [17:0] temp_exp, temp_mp, temp_atk, temp_def;

    if (golden_player.HP == 0) begin
        golden_warn_msg = HP_Warn;
        debug_battle_result = "Aborted (Initial HP=0)";
        return; 
    end

    dmg_to_player  = $signed({1'b0, monster_atk}) - $signed({1'b0, golden_player.Defense});
    dmg_to_monster = $signed({1'b0, golden_player.Attack}) - $signed({1'b0, monster_def});

    player_hp_temp  = (dmg_to_player > 0) ? (golden_player.HP -  dmg_to_player[15:0]) : {1'b0, golden_player.HP};
    monster_hp_temp = (dmg_to_monster > 0) ? (monster_hp -  dmg_to_monster[15:0]) : {1'b0, monster_hp};
    
    if (player_hp_temp > 0 && monster_hp_temp <= 0) begin // Win
        debug_battle_result = "\033[1;32mWIN\033[1;0m"; 
        temp_exp = (golden_player.Exp+  2048);
        temp_mp  = (golden_player.MP+ 2048);
        golden_player.Exp = (temp_exp > 65535) ? 65535 : temp_exp[15:0];
        golden_player.MP  = (temp_mp > 65535) ? 65535  : temp_mp[15:0];
        golden_player.HP  = (player_hp_temp > 65535)? 65535 : player_hp_temp[15:0];
        if ((temp_exp > 65535) || (temp_mp > 65535)) saturation_flag = 1'b1;

    end else if (player_hp_temp <= 0) begin // Loss
        debug_battle_result = "\033[1;31mLOSS\033[1;0m"; 
        temp_exp = (golden_player.Exp- 2048);
        temp_atk = (golden_player.Attack- 2048);
        temp_def = (golden_player.Defense- 2048);
        golden_player.Exp     = (temp_exp < 0 ) ? 0 : temp_exp[15:0];
        golden_player.HP      = 0; 
        golden_player.Attack  = (temp_atk < 0 ) ? 0 : temp_atk[15:0];
        golden_player.Defense = (temp_def < 0 ) ? 0 : temp_def[15:0];
        if ((temp_exp < 0 ) || (temp_atk < 0 ) || (temp_def < 0 )) saturation_flag = 1'b1;

    end else begin // Tie (Player > 0 && Monster > 0)
        debug_battle_result = "\033[1;33mTIE\033[1;0m"; 
        golden_player.HP = player_hp_temp[15:0];
    end

    debug_dmg_to_player = dmg_to_player;
    debug_dmg_to_monster = dmg_to_monster;

    debug_player_hp_temp = player_hp_temp;
    debug_monster_hp_temp = monster_hp_temp;

endtask

function logic [16:0] sat_sub(logic [15:0] a, logic [15:0] b);
    logic signed [16:0] result = $signed({1'b0, a}) - $signed({1'b0, b});
    if (result < 0) return 17'h10000; // 0, [16]=1
    else return {1'b0, result[15:0]};
endfunction

//---------------------------------------------------------------------
//   Use_Skill_task
//---------------------------------------------------------------------

task Use_Skill_task; //notsure
    // min_skill_mp = 65535;
    logic [17:0] min_cost_for_max_skills;
    logic [17:0] current_cost;
    logic [15:0] min_skill_mp ,a,b,c; 
    logic [17:0] total_cost;
    logic [16:0] temp_mp;
    logic [1:0] xxx,yyy;
    total_cost = 0;
    sort4 ( given_skills[0], given_skills[1], given_skills[2], given_skills[3],
            min_skill_mp ,a,b,c ,xxx,yyy ); 
    
    if (golden_player.MP < min_skill_mp) begin
        golden_warn_msg = MP_Warn;
        return; 
    end

    
    max_skills_found = 0;
    min_cost_for_max_skills = 17'h1FFFF; 

    for (int i = 1; i < 16; i++) begin
        current_cost = 0;
        current_num_skills = 0;

       
        if (i[0]) begin 
        current_cost += given_skills[0];
        current_num_skills++;
        end
        if (i[1]) begin 
        current_cost += given_skills[1];
        current_num_skills++;
        end
        if (i[2]) begin
        current_cost += given_skills[2];
        current_num_skills++;
        end
        if (i[3]) begin 
        current_cost += given_skills[3];
        current_num_skills++;
        end

        if (current_cost <= golden_player.MP) begin
        
        
        if (current_num_skills > max_skills_found) begin
            max_skills_found = current_num_skills;
            min_cost_for_max_skills = current_cost;
        end
       
        else if (current_num_skills == max_skills_found) begin
            if (current_cost < min_cost_for_max_skills) begin
                min_cost_for_max_skills = current_cost;
            end
        end
        
        end // end if (affordable)
    end // end for loop (i=1 to 15)
    
    total_cost = min_cost_for_max_skills;

    temp_mp = sat_sub(golden_player.MP, total_cost[15:0]);
    golden_player.MP = temp_mp[15:0];
    if(temp_mp[16]) saturation_flag = 1'b1;
    debug_min_skill_cost = min_skill_mp;
    debug_total_cost = total_cost;
endtask

//---------------------------------------------------------------------
//   Check_Inactive_task
//---------------------------------------------------------------------
task Check_Inactive_task;
    integer days_diff;
    days_diff = calc_days_diff({golden_player.M, golden_player.D}, given_date);

    if (days_diff > 90) begin
        golden_warn_msg = Date_Warn;
    end
endtask

function integer calc_days_diff(Date old_d, Date new_d);
    integer doy_old = date_to_doy(old_d);
    integer doy_new = date_to_doy(new_d);
    
    if (doy_new >= doy_old) begin
        return doy_new - doy_old; 
    end else begin
        return (365 - doy_old) + doy_new;
    end
endfunction

task check_task; begin
    
    if((inf.warn_msg !== golden_warn_msg) | (inf.complete !== golden_complete)) begin
        $display("---------------------------------------------------------------------------------------------------------------------------");
        $display("                                                  Wrong Answer                                                             ");         
        $display("---------------------------------------------------------------------------------------------------------------------------");
        $display("                                         %0sFAIL! (PATTERN NO.%4d)%0s                                       ", txt_red_prefix, i_pat, reset_color);
        $display("---------------------------------------------------------------------------------------------------------------------------");
        $display(" Golden warn_msg : %s , complete : %b", get_warn_name(golden_warn_msg), golden_complete);
        $display(" Your   warn_msg : %s , complete : %b", get_warn_name(inf.warn_msg), inf.complete);
        $display("---------------------------------------------------------------------------------------------------------------------------");
        
        // $display(" Action Type     : %s", get_action_name(given_action));
        // if (player_last_seen[given_player_no] !== -1) begin
        //     $display(" Player No.%3d   : REPEATED! (First seen in Pattern NO.%4d)", given_player_no, player_last_seen[given_player_no]);
        // end else begin
        //     $display(" Player No.%3d   : NEW" , given_player_no);
        // end
        // $display(" Current Date    : %02d/%02d", given_date.M, given_date.D);
        // $display(" Orignal Player Stats   : MP=%5d, HP=%5d, Atk=%5d, Def=%5d, Exp=%5d , Last Login=%02d/%02d", 
        //          orig_player.MP, orig_player.HP, orig_player.Attack, orig_player.Defense, orig_player.Exp , last_login_month, last_login_day);

        // $display(" Golden Player Stats    : MP=%5d, HP=%5d, Atk=%5d, Def=%5d, Exp=%5d , Last Login=%02d/%02d", 
        //          golden_player.MP, golden_player.HP, golden_player.Attack, golden_player.Defense, golden_player.Exp , golden_player.M, golden_player.D);
        // $display("---------------------------------------------------------------------------------------------------------------------------");

        // case(given_action)
        //     Login: begin
        //         $display(" [Login Debug Info]");
        //         $display(" Last Login Date : %02d/%02d", last_login_month, last_login_day);
        //         $display(" Consecutive?    : %b (1=Yes, 0=No)", consecutive_flag);
        //     end
            
        //     Level_Up: begin
        //         $display(" [Level Up Debug Info]");
        //         $display(" Training Type   : %s", get_type_name(given_type));
        //         $display(" Mode            : %s", get_mode_name(given_mode));
        //         $display(" Exp Needed      : %d (Current Exp: %d)", (given_mode==Easy?4095:(given_mode==Normal?16383:32767)), golden_player.Exp);
        //         $display(" Delta_i (Calc)  : MP=%d, HP=%d, Atk=%d, Def=%d", debug_delta_i_mp, debug_delta_i_hp, debug_delta_i_atk, debug_delta_i_def);
        //         $display(" Delta_Final     : MP=%d, HP=%d, Atk=%d, Def=%d", debug_delta_final_mp, debug_delta_final_hp, debug_delta_final_atk, debug_delta_final_def);
        //     end

        //     Battle: begin
        //         $display(" [Battle Debug Info]");
        //         $display(" Monster Stats   : Atk=%5d, Def=%5d, HP=%5d", monster_atk, monster_def, monster_hp);
        //         $display(" Dmg to Player   : %d (Monster.Atk %d - Player.Def %d)", $signed(debug_dmg_to_player), monster_atk, golden_player.Defense);
        //         $display(" Dmg to Monster  : %d (Player.Atk %d - Monster.Def %d)", $signed(debug_dmg_to_monster), golden_player.Attack, monster_def);
        //         $display(" Battle Outcome  : %s", debug_battle_result);
        //         $display(" Result HP Temp  : Player=%d, Monster=%d", $signed(debug_player_hp_temp), $signed(debug_monster_hp_temp));
        //     end

        //     Use_Skill: begin
        //         $display(" [Use Skill Debug Info]");
        //         $display(" Skills Cost     : [0]=%d, [1]=%d, [2]=%d, [3]=%d", given_skills[0], given_skills[1], given_skills[2], given_skills[3]);
        //         $display(" Min Skill Cost  : %d", debug_min_skill_cost);
        //         $display(" Calc Total Cost : %d", debug_total_cost);
        //         $display(" Player MP       : %d", golden_player.MP);
        //     end
            
        //     Check_Inactive: begin
        //         $display(" [Check Inactive Debug Info]");
        //         $display(" Last Login      : %02d/%02d", last_login_month, last_login_day);
        //         $display(" Today           : %02d/%02d", given_date.M, given_date.D);
        //         $display(" Days Diff       : %d", calc_days_diff({golden_player.M, golden_player.D}, given_date));
        //     end
        // endcase
        // $display("---------------------------------------------------------------------------------------------------------------------------");
        YOU_FAIL_task;
    end
    if (player_last_seen[given_player_no]===-1 ||  player_last_seen[given_player_no]===190 || player_last_seen[given_player_no]===446)
        player_last_seen[given_player_no] = i_pat;
end endtask


function string get_warn_name(Warn_Msg w);
    case(w)
        No_Warn: return "No_Warn";
        Date_Warn: return "Date_Warn";
        Exp_Warn: return "Exp_Warn";
        HP_Warn: return "HP_Warn";
        MP_Warn: return "MP_Warn";
        Saturation_Warn: return "Saturation_Warn";
        default: return "Unknown";
    endcase
endfunction

function string get_action_name(Action a);
    case(a)
        Login: return "Login";
        Level_Up: return "Level_Up";
        Battle: return "Battle";
        Use_Skill: return "Use_Skill";
        Check_Inactive: return "Check_Inactive";
        default: return "Unknown";
    endcase
endfunction

function string get_type_name(Training_Type t);
    case(t)
        Type_A: return "Type_A";
        Type_B: return "Type_B";
        Type_C: return "Type_C";
        Type_D: return "Type_D";
    endcase
endfunction

function string get_mode_name(Mode m);
    case(m)
        Easy: return "Easy";
        Normal: return "Normal";
        Hard: return "Hard";
    endcase
endfunction

//---------------------------------------------------------------------
//   PASS OR FAIL
//---------------------------------------------------------------------
task YOU_FAIL_task;
begin
    $finish;
end
endtask

task YOU_PASS_task; begin
    $display("------------------------------------------------------------------------------------------------------------------------------------");
    $display ("                                                 %0sCongratulations%0s                   ", txt_green_prefix, reset_color);
    $display("                                           Execution cycles = %5d cycles                                                 ", total_lat);
    // $display("                                           Clock period = %.1f ns                                                        ", CLK_TIME);
    // $display("                                           Total Latency = %.1f ns                                                     ", total_lat * CLK_TIME);
    $display("                                           Average Latency = %.4f ns                                                     ", (total_lat*1.0) / (PAT_NUM*1.0));
    $display("------------------------------------------------------------------------------------------------------------------------------------");
    $finish;
end
endtask

endprogram

//let action not random
// 737217 NS      PAT_NUM    10000

//let type and mode not random
// 597264 NS      PAT_NUM    8400 

//let remove some negedge clk
// 499933800 PS 

//let action early
// 404306400 PS   PAT_NUM    6401

// 401910600 PS   PAT_NUM    6400