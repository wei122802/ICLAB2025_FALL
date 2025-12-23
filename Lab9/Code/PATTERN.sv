// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
// `define SEED        1228 //**
`define SEED        123456789
// `define SEED        4121717
`define PAT_NUM     60000
`define CYCLE_TIME 3.3

`define DRAM_PATH TESTBED.dram_r
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
parameter CLK_TIME = `CYCLE_TIME;
parameter DRAM_BASE_ADDR = 17'h10000;
parameter BYTES_PER_PLAYER = 12;

integer seed = `SEED;
integer total_lat, lat;
integer i, i_pat;
integer max_skills_found,current_num_skills;    
integer player_last_seen [0:255];
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+12*256)-1):(65536+0)];  

Action        given_action;
Training_Type given_type;
Mode          given_mode; // 使用您 Usertype 中的 Mode
Date          given_date;
Player_No     given_player_no;
logic [15:0]  monster_atk, monster_def, monster_hp; // 怪物屬性
logic [15:0]  given_skills [4]; // 技能消耗
string debug_battle_result;
// Golden Model 內部變數
Player_Info   golden_player; // 儲存解包後的當前玩家資料
Warn_Msg      golden_warn_msg;
logic         golden_complete;
logic         saturation_flag; // 飽和運算旗標
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
/**
 * Class representing a random action.
 */
// class random_act;
//     randc Action act_id;
//     constraint range{
//         act_id inside{Login, Level_Up, Battle, Use_Skill, Check_Inactive};
//     }
//     function set_seed(int seed);
//         this.srandom(seed);
//     endfunction
// endclass

class random_act;
    randc Action act_id;
    function new (int seed);
        this.srandom(seed);
    endfunction
    constraint limit{
        // 包含 Lab09 所有的 5 個 action
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
    r_action    = random_act::new(seed);
    r_training  = random_training::new(seed);
    r_date      = random_date::new(seed);
    r_player_no = random_player_no::new(seed);
    r_monster   = random_monster::new(seed);
    r_skills    = random_skills::new(seed);

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
        if(i_pat%10000 == 0)
            $display("\033[0;34mPASS PATTERN NO.%4d, \033[m \033[0;32m Execution Cycle: %3d \033[0;32m  \033[0;33m%s\033[0;33m ", i_pat, lat,get_action_name(given_action));
        // check_mem_task;
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

    #CLK_TIME; inf.rst_n = 0; 
    #CLK_TIME; inf.rst_n = 1;

    if(inf.AR_VALID !== 0 || inf.AR_ADDR !== 0 || inf.R_READY !== 0 || inf.AW_VALID !== 0 || inf.AW_ADDR !== 0 || inf.W_VALID !== 0 || inf.W_DATA !== 0 || inf.B_READY !== 0) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                AXI4 signals should be 0 after initial RESET          ");
        $display ("====================================================================");
        // repeat (30) #CLK_TIME;  
        $finish;
    end

    if (inf.out_valid !== 1'b0 || inf.complete !== 1'b0 || inf.warn_msg !== 'b0) begin
        $display("************************************************************");  
        $display ("                      %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display("*  Output signals should be 0 after initial RESET at %8t *", $time);
        $display("************************************************************");
        // repeat (30) #CLK_TIME;
        $finish;
    end
    #CLK_TIME; release clk;

end
endtask

task input_task; begin
    repeat($urandom_range(1, 4)) @(negedge clk); 
    give_action;
    repeat($urandom_range(1, 4)) @(negedge clk); 
    
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
            give_monster; // 會連續給 3 次
        end
        Use_Skill: begin
            give_player_no;
            give_skills; // 會連續給 4 次
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
        if(lat === 1000) begin //
        $display("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                         %0sFAIL!%0s                                           ", txt_red_prefix, reset_color);
        $display("                                                        PATTERN NO.%4d                                                                 ", i_pat);
        $display("                                    The execution latency should not over 1000 cycles                                                  ");
        $display("--------------------------------------------------------------------------------------------------------------------------------------------");
        YOU_FAIL_task;
        end
        @(negedge clk);
    end
    // 檢查 out_valid 是否只 high 一個 cycle
    // @(negedge clk);
    // if (inf.out_valid === 1) begin
    //     $display("--------------------------------------------------------------------------------------------------------------------------------------------");
    //     $display ("                                                         %0sFAIL!%0s                                           ", txt_red_prefix, reset_color);
    //     $display("                                                        PATTERN NO.%4d                                                                 ", i_pat);
    //     $display("                                          out_valid must be high for EXACTLY one cycle.                                                ");
    //     $display("--------------------------------------------------------------------------------------------------------------------------------------------");
    //     YOU_FAIL_task;
    // end
end endtask



task check_ans_task; begin
    // 1. 從 golden_DRAM 解包 (Unpack) 玩家資料
    unpack_golden_dram;
    
    // 2. 根據 action 執行 golden model 運算
    saturation_flag = 1'b0; // 重置飽和旗標
    golden_warn_msg = No_Warn; // 預設為 No_Warn

    case(given_action)
        Login          : Login_task;
        Level_Up       : Level_Up_task;
        Battle         : Battle_task;
        Use_Skill      : Use_Skill_task;
        Check_Inactive : Check_Inactive_task;
    endcase

    // 3. 檢查 Warning 優先級 (如果飽和，總是 Saturation_Warn)
    // 根據 Table 7 [cite: 67-69], Saturation_Warn 優先級最低 (3'b101)
    // 如果同時發生 Exp_Warn 和 Saturation_Warn，應輸出 Exp_Warn (3'b010)
    
    if (saturation_flag && golden_warn_msg == No_Warn) begin
        // 只有在 "沒有其他更高優先級的 warning" 時，才設置 Saturation_Warn
        golden_warn_msg = Saturation_Warn;
    end

    // 4. 決定 golden_complete
    golden_complete = (golden_warn_msg == No_Warn);

    // 5. 比較 DUT 輸出與 Golden Model
    check_task;

    // 6. 如果操作成功 (complete=1)，將更新後的資料寫回 golden_DRAM
    // if (golden_complete) begin
        pack_golden_dram;
    // end
    
end endtask

task pack_golden_dram;
    integer N;
    N = DRAM_BASE_ADDR + given_player_no * BYTES_PER_PLAYER;

    // 依序寫回 (與 unpack 相反)
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
    given_action = r_action.act_id;
    inf.sel_action_valid = 1;
    inf.D.d_act[0] = given_action;
    @(negedge clk);
    inf.sel_action_valid = 0;
    inf.D = 'bx;
end endtask

task give_date; begin
    i = r_date.randomize();
    given_date = r_date.date;
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.date_valid = 1;
    inf.D.d_date[0] = given_date;
    @(negedge clk);
    inf.date_valid = 0;
    inf.D = 'bx;
end endtask

task give_player_no; begin
    i = r_player_no.randomize();
    given_player_no = r_player_no.player_no;
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.player_no_valid = 1;
    inf.D.d_player_no[0] = given_player_no;
    @(negedge clk);
    inf.player_no_valid = 0;
    inf.D = 'bx;
end endtask

task give_type; begin
    i = r_training.randomize(); 
    given_type = r_training.traintype;
    given_mode = r_training.mode; // Type 和 Mode 一起隨機化

    repeat($urandom_range(1, 4)) @(negedge clk); // 規格說 1~4 cycle
    inf.type_valid = 1;
    inf.D.d_type[0] = given_type;
    @(negedge clk);
    inf.type_valid = 0;
    inf.D = 'bx;
end endtask

task give_mode; begin
    // 已經在 give_type 中隨機化
    repeat($urandom_range(1, 4)) @(negedge clk);
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
    repeat($urandom_range(0, 4)) @(negedge clk);
    inf.monster_valid = 1;
    inf.D.d_attribute[0] = monster_atk;
    @(negedge clk);
    inf.monster_valid = 0;
    inf.D = 'bx;

    // 2. Monster Defense
    repeat($urandom_range(0, 4)) @(negedge clk);
    inf.monster_valid = 1;
    inf.D.d_attribute[0] = monster_def;
    @(negedge clk);
    inf.monster_valid = 0;
    inf.D = 'bx;

    // 3. Monster HP
    repeat($urandom_range(0, 4)) @(negedge clk);
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
        repeat($urandom_range(0, 4)) @(negedge clk);
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
    // 檢查是否連續登入
    if (is_consecutive({golden_player.M, golden_player.D}, given_date)) begin
        consecutive_flag = 1;
        temp_exp = sat_add(golden_player.Exp, 512);
        temp_mp  = sat_add(golden_player.MP, 1024);
        golden_player.Exp = temp_exp[15:0];
        golden_player.MP  = temp_mp[15:0];
        if (temp_exp[16] || temp_mp[16]) saturation_flag = 1'b1;
    end

    // 更新登入日期
    golden_player.M = given_date.M;
    golden_player.D = given_date.D;
    // golden_warn_msg = No_Warn; // 已在 check_ans_task 預設
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

// 檢查是否連續
function logic is_consecutive(Date old_d, Date new_d);
    integer doy_old = date_to_doy(old_d);
    integer doy_new = date_to_doy(new_d);
    
    if (doy_new == doy_old + 1) return 1; // 正常隔天
    if (old_d.M == 12 && old_d.D == 31 && new_d.M == 1 && new_d.D == 1) return 1; // 跨年
    
    return 0;
endfunction


// 飽和加法
function logic [16:0] sat_add(logic [15:0] a, logic [15:0] b);
    logic [16:0] result = a+b ;
    if (result > 65535) return 17'h1FFFF; // 65535, [16]=1
    else return {1'b0, result[15:0]};
endfunction

//---------------------------------------------------------------------
//  Level_Up_task
//---------------------------------------------------------------------
logic [18:0] temp_hp, temp_mp, temp_atk, temp_def;
logic [17:0] delta_final_mp, delta_final_hp, delta_final_atk, delta_final_def;
logic [17:0] delta_common;
logic [16:0] d_A0;
logic [16:0] d_A1;
task Level_Up_task;
    
    logic [1:0]   min1 , min2 ;
    logic [15:0] exp_needed;
    
    logic [16:0] delta_i_mp, delta_i_hp, delta_i_atk, delta_i_def;
    
    logic [15:0] sorted [0:3]; // 用於 Type B

    logic [21:0] temp;
    
    // 1. 檢查 Exp (不變)
    case(given_mode)
        Easy:   exp_needed = 4095; 
        Normal: exp_needed = 16383;
        Hard:   exp_needed = 32767; 
    endcase
    
    if (golden_player.Exp < exp_needed) begin
        golden_warn_msg = Exp_Warn; 
        return; // 結束 action
    end

    // 2. 計算 4 個 Delta_i (根據您的新規則)
    case(given_type)
        Type_A: begin
            // "以A為例 那delta_i 四個都是一樣的"
            delta_common = (golden_player.MP + golden_player.HP + golden_player.Attack + golden_player.Defense) /8;  // 除以 8
            delta_i_mp  = delta_common;
            delta_i_hp  = delta_common;
            delta_i_atk = delta_common;
            delta_i_def = delta_common;
        end
        
        Type_B: begin
            // "ΔA₀是排序後最小的attribute可以增加的值...ΔA1是第二小的attribute可以增加的值"
            // "最大跟第二的attribute就不會增加"
            
            // 1. 排序 4 個屬性的值 (假設 sorted[0] 最小, sorted[3] 最大)
            sort4(golden_player.MP, golden_player.HP, golden_player.Attack, golden_player.Defense, sorted[0], sorted[1], sorted[2], sorted[3],min1,min2); 
            
            // 2. 根據 PDF  計算 delta 值
            d_A0 = sorted[2] - sorted[0]; // ΔA₀ = A2 - A0
            d_A1 = sorted[3] - sorted[1]; // ΔA₁ = A3 - A1
            
            // 3. 初始化所有 delta 為 0 (A2 和 A3 不增加)
            delta_i_mp  = 0;
            delta_i_hp  = 0;
            delta_i_atk = 0;
            delta_i_def = 0;
            
            // 4. 將 delta 分配給值為 A0 或 A1 的屬性
            // ** 注意: 如果有兩個屬性值相同 (e.g., MP=10, HP=10, s[0]=10, s[1]=10)
            // ** 這個邏輯可能會出錯 (兩個屬性都拿到 d_A0)。
            // ** 但這是對您範例最直接的詮釋。
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

            // if(golden_player.MP == sorted[0]) delta_i_mp  = d_A0;
            // else if (golden_player.HP == sorted[0]) delta_i_hp  = d_A0;
            // else if (golden_player.Attack == sorted[0]) delta_i_atk = d_A0;
            // else if (golden_player.Defense == sorted[0]) delta_i_def = d_A0;

            // if(golden_player.MP == sorted[1]) delta_i_mp  = d_A1;
            // else if (golden_player.HP == sorted[1]) delta_i_hp  = d_A1;
            // else if (golden_player.Attack == sorted[1]) delta_i_atk = d_A1;
            // else if (golden_player.Defense == sorted[1]) delta_i_def = d_A1;
        end
        
        Type_C: begin
            // "如果attribute<16383 那這個attribute的delta 就會是16383-attribute 否則delta 就是0"
            delta_i_mp  = (golden_player.MP < 16383) ? (16383 - golden_player.MP) : 0;
            delta_i_hp  = (golden_player.HP < 16383) ? (16383 - golden_player.HP) : 0;
            delta_i_atk = (golden_player.Attack < 16383) ? (16383 - golden_player.Attack) : 0;
            delta_i_def = (golden_player.Defense < 16383) ? (16383 - golden_player.Defense) : 0;
        end
        
        Type_D: begin
            // "以D來說 就是跟公式一樣"
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

    // 3. 計算 4 個 Delta_final (Table 2) [cite: 52]
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

    // 4. 更新 4 個屬性
    temp_hp  = golden_player.HP     + delta_final_hp;
    temp_mp  = golden_player.MP     + delta_final_mp;
    temp_atk = golden_player.Attack + delta_final_atk;
    temp_def = golden_player.Defense+ delta_final_def;
    
    // 檢查是否有任一項飽和

    if ((temp_hp > 65535) || (temp_mp > 65535) || (temp_atk > 65535) || (temp_def > 65535)  )
        saturation_flag = 1'b1;
    
    // 寫入 (飽和運算)
    golden_player.HP      = (temp_hp > 65535) ? 65535 : temp_hp[15:0];
    golden_player.MP      = (temp_mp > 65535) ? 65535 : temp_mp[15:0];
    golden_player.Attack  = (temp_atk > 65535) ? 65535 : temp_atk[15:0];
    golden_player.Defense = (temp_def > 65535) ? 65535 : temp_def[15:0];
    // debug_delta_i_mp = delta_i_mp; debug_delta_i_hp = delta_i_hp; // ... 依此類推

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


// task sort4 (
//     input logic [15:0] in1, in2, in3, in4,
//     output logic [15:0] out1, out2, out3, out4);
//     logic [15:0] a, b, c, d;
//     a = in1; b = in2; c = in3; d = in4;
//     if (a > b) swap(a, b);
//     if (c > d) swap(c, d);
//     if (a > c) swap(a, c);
//     if (b > d) swap(b, d);
//     if (b > c) swap(b, c);
//     out1 = a; out2 = b; out3 = c; out4 = d;
// endtask

// task swap(inout logic [15:0] x, inout logic [15:0] y);
//     logic [15:0] temp;
//     temp = x;
//     x = y;
//     y = temp;
// endtask

//---------------------------------------------------------------------
//   Battle_task
//---------------------------------------------------------------------
task Battle_task;
    
    logic signed [16:0] dmg_to_player, dmg_to_monster;
    logic signed [17:0] player_hp_temp, monster_hp_temp;
    logic signed [17:0] temp_exp, temp_mp, temp_atk, temp_def;

    // 1. 檢查 HP
    if (golden_player.HP == 0) begin
        golden_warn_msg = HP_Warn;
        debug_battle_result = "Aborted (Initial HP=0)";
        return; // 結束 action
    end

    // 2. 計算傷害 (Table 4)
    dmg_to_player  = $signed({1'b0, monster_atk}) - $signed({1'b0, golden_player.Defense});
    dmg_to_monster = $signed({1'b0, golden_player.Attack}) - $signed({1'b0, monster_def});

    // 3. 計算 HP_temp (Table 5)
    player_hp_temp  = (dmg_to_player > 0) ? (golden_player.HP -  dmg_to_player[15:0]) : {1'b0, golden_player.HP};
    monster_hp_temp = (dmg_to_monster > 0) ? (monster_hp -  dmg_to_monster[15:0]) : {1'b0, monster_hp};
    
    // if (player_hp_temp < 0) saturation_flag = 1'b1; // 玩家 HP 減到 0
    // if (monster_hp_temp[16]) ; // 怪物 HP 減到 0
    
    // 4. 判斷結果 (Table 6)
    if (player_hp_temp > 0 && monster_hp_temp <= 0) begin // Win
        debug_battle_result = "\033[1;32mWIN\033[1;0m"; // <--- 設定為 WIN (綠色)
        temp_exp = (golden_player.Exp+  2048);
        temp_mp  = (golden_player.MP+ 2048);
        golden_player.Exp = (temp_exp > 65535) ? 65535 : temp_exp[15:0];
        golden_player.MP  = (temp_mp > 65535) ? 65535  : temp_mp[15:0];
        golden_player.HP  = (player_hp_temp > 65535)? 65535 : player_hp_temp[15:0];
        if ((temp_exp > 65535) || (temp_mp > 65535)) saturation_flag = 1'b1;

    end else if (player_hp_temp <= 0) begin // Loss
        debug_battle_result = "\033[1;31mLOSS\033[1;0m"; // <--- 設定為 LOSS (紅色)
        temp_exp = (golden_player.Exp- 2048);
        temp_atk = (golden_player.Attack- 2048);
        temp_def = (golden_player.Defense- 2048);
        golden_player.Exp     = (temp_exp < 0 ) ? 0 : temp_exp[15:0];
        golden_player.HP      = 0; 
        golden_player.Attack  = (temp_atk < 0 ) ? 0 : temp_atk[15:0];
        golden_player.Defense = (temp_def < 0 ) ? 0 : temp_def[15:0];
        if ((temp_exp < 0 ) || (temp_atk < 0 ) || (temp_def < 0 )) saturation_flag = 1'b1;

    end else begin // Tie (Player > 0 && Monster > 0)
        debug_battle_result = "\033[1;33mTIE\033[1;0m";  // <--- 設定為 TIE (黃色)
        golden_player.HP = player_hp_temp[15:0];
    end

    debug_dmg_to_player = dmg_to_player;
    debug_dmg_to_monster = dmg_to_monster;

    // ... 計算完 HP temp 後 ...
    debug_player_hp_temp = player_hp_temp;
    debug_monster_hp_temp = monster_hp_temp;

endtask

// 飽和減法
function logic [16:0] sat_sub(logic [15:0] a, logic [15:0] b);
    logic signed [16:0] result = $signed({1'b0, a}) - $signed({1'b0, b});
    if (result < 0) return 17'h10000; // 0, [16]=1
    else return {1'b0, result[15:0]};
endfunction

//---------------------------------------------------------------------
//   Use_Skill_task
//---------------------------------------------------------------------
logic [17:0] min_cost_for_max_skills;
logic [17:0] current_cost;
logic [15:0] min_skill_mp ,a,b,c; 
logic [17:0] total_cost;
logic [16:0] temp_mp;
logic [1:0] xxx,yyy;
task Use_Skill_task; //notsure
    // min_skill_mp = 65535;
    
    total_cost = 0;
    // --- 1. MP_Warn 檢查 ---
    // (這部分邏輯不變) 找到最便宜的單一技能
    sort4 ( given_skills[0], given_skills[1], given_skills[2], given_skills[3],
            min_skill_mp ,a,b,c ,xxx,yyy ); // 只取最小值 
    // foreach (given_skills[i]) begin
    //     min_skill_mp = $min(min_skill_mp, int'(given_skills[i]));
    // end

    // 檢查 MP 是否連最便宜的技能都用不起 [cite: 113]
    if (golden_player.MP < min_skill_mp) begin
        golden_warn_msg = MP_Warn;
        return; // 結束 action
    end

    // --- 2. 找出最佳技能組合 ---
    max_skills_found = 0;
    min_cost_for_max_skills = 17'h1FFFF; // 17-bit max value

    // 迭代所有 15 種組合 (i=1 是 0001, i=15 是 1111)
    // i 的 4 個 bit 分別代表 {skill4, skill3, skill2, skill1}
    for (int i = 1; i < 16; i++) begin
        current_cost = 0;
        current_num_skills = 0;

        // 根據 i 的 bitmask 計算這個組合的 cost 和 skill 數量
        if (i[0]) begin // 檢查 bit 0 (skill 1)
        current_cost += given_skills[0];
        current_num_skills++;
        end
        if (i[1]) begin // 檢查 bit 1 (skill 2)
        current_cost += given_skills[1];
        current_num_skills++;
        end
        if (i[2]) begin // 檢查 bit 2 (skill 3)
        current_cost += given_skills[2];
        current_num_skills++;
        end
        if (i[3]) begin // 檢查 bit 3 (skill 4)
        current_cost += given_skills[3];
        current_num_skills++;
        end

        // --- 檢查此組合是否為最佳解 ---

        // 1. 檢查 MP 是否負擔得起
        if (current_cost <= golden_player.MP) begin
        
        // 2. 這個組合是否使用了「更多」的技能？
        // (PDF 要求: "maximum number of skills" [cite: 112])
        if (current_num_skills > max_skills_found) begin
            // 找到了新的「最大技能數量」，直接更新
            max_skills_found = current_num_skills;
            min_cost_for_max_skills = current_cost;
        end
        // 3. 技能數量「相同」，但 MP 消耗「更低」？
        // (您範例中的要求)
        else if (current_num_skills == max_skills_found) begin
            if (current_cost < min_cost_for_max_skills) begin
            // 數量一樣，但成本更低，更新
            min_cost_for_max_skills = current_cost;
            end
        end
        
        end // end if (affordable)
    end // end for loop (i=1 to 15)

    // --- 3. 更新 MP ---
    // 經過 15 次迴圈後，min_cost_for_max_skills 就是我們要的總消耗
    // (因為我們已經通過了 MP_Warn 檢查, max_skills_found 至少會是 1)
    
    total_cost = min_cost_for_max_skills;

    // 4. 更新 MP (使用 sat_sub 來確保不會低於 0)
    temp_mp = sat_sub(golden_player.MP, total_cost[15:0]);
    golden_player.MP = temp_mp[15:0];
    if(temp_mp[16]) saturation_flag = 1'b1; // (理論上不應發生)
    debug_min_skill_cost = min_skill_mp;
    debug_total_cost = total_cost;
endtask

//---------------------------------------------------------------------
//   Check_Inactive_task
//---------------------------------------------------------------------
task Check_Inactive_task;
    integer days_diff;
    days_diff = calc_days_diff({golden_player.M, golden_player.D}, given_date);

    // 檢查天數
    if (days_diff > 90) begin
        golden_warn_msg = Date_Warn;
    end
endtask

function integer calc_days_diff(Date old_d, Date new_d);
    integer doy_old = date_to_doy(old_d);
    integer doy_new = date_to_doy(new_d);
    
    // 假設 new_date 總是 >= old_date (除了 Check_Inactive)
    // Lab 規則: Check Inactive [cite: 123-126]
    if (doy_new >= doy_old) begin
        return doy_new - doy_old; // 同年
    end else begin
        // 跨年 (e.g., 12/31 -> 1/1), (365 - 365) + 1 = 1
        return (365 - doy_old) + doy_new;
    end
endfunction

//---------------------------------------------------------------------
//   Check
//---------------------------------------------------------------------
// task check_task; begin
//     if((inf.warn_msg !== golden_warn_msg) | (inf.complete !== golden_complete)) begin
//         $display("---------------------------------------------------------------------------------------------------------------------------");
//         $display("                                       PATTERN NO.%4d                                                                 ", i_pat);
//         $display("                         Golden warn_msg is : %b (%d) , complete is : %b                                          ", golden_warn_msg, golden_warn_msg, golden_complete);
//         $display("                         Your   warn_msg is : %b (%d) , complete is : %b                                          ", inf.warn_msg, inf.warn_msg, inf.complete);
//         $display("---------------------------------------------------------------------------------------------------------------------------");
//         $display("                         Active :  %d , player : %d                                          ", given_action, given_player_no);
//         $display("                         Training Type :  %d , Mode : %d                                          ", given_type, given_mode);
//         $display("                         Date :  %02d/%02d                                          ", given_date.M, given_date.D);
//         $display("                         Monster Atk :  %d , Def : %d , HP : %d                                             ", monster_atk, monster_def, monster_hp);
//         $display("---------------------------------------------------------------------------------------------------------------------------");
//         YOU_FAIL_task;
//     end
// end endtask
task check_task; begin
    
    if((inf.warn_msg !== golden_warn_msg) | (inf.complete !== golden_complete)) begin
        $display("---------------------------------------------------------------------------------------------------------------------------");
        $display("                                         %0sFAIL! (PATTERN NO.%4d)%0s                                       ", txt_red_prefix, i_pat, reset_color);
        $display("---------------------------------------------------------------------------------------------------------------------------");
        $display(" Golden warn_msg : %s , complete : %b", get_warn_name(golden_warn_msg), golden_complete);
        $display(" Your   warn_msg : %s , complete : %b", get_warn_name(inf.warn_msg), inf.complete);
        $display("---------------------------------------------------------------------------------------------------------------------------");
        
        // 顯示通用資訊
        $display(" Action Type     : %s", get_action_name(given_action));
        if (player_last_seen[given_player_no] !== -1) begin
            $display(" Player No.%3d   : REPEATED! (First seen in Pattern NO.%4d)", given_player_no, player_last_seen[given_player_no]);
        end else begin
            $display(" Player No.%3d   : NEW" , given_player_no);
        end
        $display(" Current Date    : %02d/%02d", given_date.M, given_date.D);
        $display(" Orignal Player Stats   : MP=%5d, HP=%5d, Atk=%5d, Def=%5d, Exp=%5d , Last Login=%02d/%02d", 
                 orig_player.MP, orig_player.HP, orig_player.Attack, orig_player.Defense, orig_player.Exp , last_login_month, last_login_day);

        $display(" Golden Player Stats    : MP=%5d, HP=%5d, Atk=%5d, Def=%5d, Exp=%5d , Last Login=%02d/%02d", 
                 golden_player.MP, golden_player.HP, golden_player.Attack, golden_player.Defense, golden_player.Exp , golden_player.M, golden_player.D);
        $display("---------------------------------------------------------------------------------------------------------------------------");
        // 更新該玩家的歷史紀錄為當前 Pattern
        // 針對不同 Action 顯示特定 Debug 資訊
        case(given_action)
            Login: begin
                $display(" [Login Debug Info]");
                $display(" Last Login Date : %02d/%02d", last_login_month, last_login_day);
                $display(" Consecutive?    : %b (1=Yes, 0=No)", consecutive_flag);
            end
            
            Level_Up: begin
                $display(" [Level Up Debug Info]");
                $display(" Training Type   : %s", get_type_name(given_type));
                $display(" Mode            : %s", get_mode_name(given_mode));
                $display(" Exp Needed      : %d (Current Exp: %d)", (given_mode==Easy?4095:(given_mode==Normal?16383:32767)), golden_player.Exp);
                $display(" Delta_i (Calc)  : MP=%d, HP=%d, Atk=%d, Def=%d", debug_delta_i_mp, debug_delta_i_hp, debug_delta_i_atk, debug_delta_i_def);
                $display(" Delta_Final     : MP=%d, HP=%d, Atk=%d, Def=%d", debug_delta_final_mp, debug_delta_final_hp, debug_delta_final_atk, debug_delta_final_def);
            end

            Battle: begin
                $display(" [Battle Debug Info]");
                $display(" Monster Stats   : Atk=%5d, Def=%5d, HP=%5d", monster_atk, monster_def, monster_hp);
                $display(" Dmg to Player   : %d (Monster.Atk %d - Player.Def %d)", $signed(debug_dmg_to_player), monster_atk, golden_player.Defense);
                $display(" Dmg to Monster  : %d (Player.Atk %d - Monster.Def %d)", $signed(debug_dmg_to_monster), golden_player.Attack, monster_def);
                $display(" Battle Outcome  : %s", debug_battle_result);
                $display(" Result HP Temp  : Player=%d, Monster=%d", $signed(debug_player_hp_temp), $signed(debug_monster_hp_temp));
            end

            Use_Skill: begin
                $display(" [Use Skill Debug Info]");
                $display(" Skills Cost     : [0]=%d, [1]=%d, [2]=%d, [3]=%d", given_skills[0], given_skills[1], given_skills[2], given_skills[3]);
                $display(" Min Skill Cost  : %d", debug_min_skill_cost);
                $display(" Calc Total Cost : %d", debug_total_cost);
                $display(" Player MP       : %d", golden_player.MP);
            end
            
            Check_Inactive: begin
                $display(" [Check Inactive Debug Info]");
                $display(" Last Login      : %02d/%02d", last_login_month, last_login_day);
                $display(" Today           : %02d/%02d", given_date.M, given_date.D);
                $display(" Days Diff       : %d", calc_days_diff({golden_player.M, golden_player.D}, given_date));
            end
        endcase
        $display("---------------------------------------------------------------------------------------------------------------------------");
        YOU_FAIL_task;
    end
    // if (player_last_seen[given_player_no]===-1 )
        player_last_seen[given_player_no] = i_pat;
end endtask

// task check_mem_task; begin
//     integer i; // 迴圈變數
//     logic [7:0] golden_data; // Pattern 計算出的正確答案
//     logic [7:0] dram_data;   // 從 DRAM 讀回來的實際資料
//     logic first_fail;

//     first_fail = 1;

//     // 檢查範圍: 從 0x10000 開始，檢查 256 位玩家，每位 12 bytes
//     for (i = DRAM_BASE_ADDR; i < DRAM_BASE_ADDR + (256 * BYTES_PER_PLAYER); i = i + 1) begin
        
//         // 1. 取得 Pattern 預期的資料
//         golden_data = golden_DRAM[i];

//         // 2. 取得 DRAM 內部的資料 (Backdoor Access)
//         // 路徑格式: `路徑宏.內部記憶體變數名稱[位址]`
//         dram_data = `DRAM_PATH.golden_DRAM[i]; 

//         // 3. 比對
//         if (golden_data !== dram_data) begin
//             if (first_fail) begin
//                 $display("------------------------------------------------------------------------------------------------------------------------------------");
//                 $display("                                                  %0sDRAM DATA CORRUPTION DETECTED!%0s", txt_red_prefix, reset_color);
//                 $display("------------------------------------------------------------------------------------------------------------------------------------");
//                 $display("      Address      |   Player No.   |   Expected (Gold)   |    Actual (DRAM)    ");
//                 $display("------------------------------------------------------------------------------------------------------------------------------------");
//                 first_fail = 0;
//             end
            
//             // 顯示錯誤資訊 (包含換算後的 Player ID)
//             $display("      0x%5d      |       %3d       |          0x%2h          |         0x%2h       ", 
//                      i, (i - DRAM_BASE_ADDR) / 12, golden_data, dram_data);
            
//             // 為了避免錯誤訊息洗版，可以設定錯誤超過一定數量就停止 (選擇性)
//             // if ((i - DRAM_BASE_ADDR) > 50) $finish; 
//         end
//     end

//     // 如果有錯誤，強制結束
//     if (first_fail == 0) begin
//         $display("------------------------------------------------------------------------------------------------------------------------------------");
//         $display("                                                      %0sFAIL! (DRAM Check)%0s", txt_red_prefix, reset_color);
//         $display("------------------------------------------------------------------------------------------------------------------------------------");
//         // repeat (10) #CLK_TIME;
//         $finish;
//     end
// end endtask


// ===============================================================
// 輔助 function: 將 Enum 轉為字串顯示，方便閱讀
// ===============================================================
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
    $display("                     \033[0;31m fail QQ \033[m                 ");
    // repeat (30) #CLK_TIME;
    $finish;
end
endtask

task YOU_PASS_task; begin
    $display("------------------------------------------------------------------------------------------------------------------------------------");
    $display ("                                                 %0sCongratulation!!%0s                   ", txt_green_prefix, reset_color);
    $display("                                             Execution cycles = %5d cycles                                                 ", total_lat);
    $display("                                             Clock period = %.1f ns                                                        ", CLK_TIME);
    $display("                                             Total Latency = %.1f ns                                                     ", total_lat * CLK_TIME);
    $display("                                             Average Latency = %.4f ns                                                     ", (total_lat*1.0) / (PAT_NUM*1.0));
    $display("------------------------------------------------------------------------------------------------------------------------------------");
    $finish;
end
endtask

endprogram