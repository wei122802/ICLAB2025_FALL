`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;


class Type_and_mode;
    Training_Type f_type;
    Mode f_mode;
endclass

Type_and_mode fm_info = new();

always_comb begin
    if(inf.type_valid) fm_info.f_type = inf.D.d_type[0];
    if(inf.mode_valid) fm_info.f_mode = inf.D.d_mode[0];
end

parameter   TRAIN_TIMES      = 200;
parameter   MODE_TIMES       = 200;
parameter   CROSS_TIMES      = 200;
parameter   WARN_TIMES       = 20;
parameter   ACTION_TIMES     = 200;
parameter   MP_TIMES         = 1;
parameter   NO_TIMES         = 2;

parameter   MP_AUTO_BIN_MAX  = 32;
parameter   NO_AUTO_BIN_MAX  = 256;

//================================================================
// MARK:Coverage
//================================================================
covergroup SPEC1 @(posedge clk iff (inf.type_valid));
    option.name = "Training_Type_coverage";
    option.per_instance = 1;
    option.at_least = TRAIN_TIMES;
    coverpoint fm_info.f_type {
        bins b_type[] = {[Type_A : Type_D]}; 
    }
endgroup

covergroup SPEC2 @(posedge clk iff (inf.mode_valid));
    option.name = "Mode_coverage";
    option.per_instance = 1;
    option.at_least = MODE_TIMES;
    coverpoint fm_info.f_mode {
        bins b_mode[] = {[Easy : Hard]}; 
    }
endgroup

// 3. (Type_A, Type_B, Type_C, Type_D) x (Easy, Normal, Hard)
covergroup SPEC3 @(posedge clk iff (inf.mode_valid));
    option.name = "Training_Mode_Cross_coverage";
    option.per_instance = 1;
    option.at_least = CROSS_TIMES;
    cross fm_info.f_type, fm_info.f_mode;
endgroup


covergroup SPEC4 @(posedge clk iff (inf.player_no_valid));
    option.name = "PlayerNo_coverage";
    option.per_instance = 1;
    option.at_least = NO_TIMES;
    coverpoint inf.D.d_player_no[0] {
        option.auto_bin_max = NO_AUTO_BIN_MAX;
    }
endgroup

covergroup SPEC5 @(posedge clk iff (inf.sel_action_valid));
    option.name = "Action_coverage";
    option.per_instance = 1;
    option.at_least = ACTION_TIMES;
    coverpoint inf.D.d_act[0] {
        bins b_act [] = ([Login:Check_Inactive] => [Login:Check_Inactive]); 
    }
endgroup

covergroup SPEC6 @(posedge clk iff (inf.MP_valid));
    option.name = "MPskill_coverage";
    option.per_instance = 1;
    option.at_least = MP_TIMES;
    // option.auto_bin_max = MP_AUTO_BIN_MAX;
    // coverpoint inf.D.d_attribute[0] ;
    coverpoint inf.D.d_attribute[0] {
        option.auto_bin_max = MP_AUTO_BIN_MAX;
    }
endgroup

covergroup SPEC7 @(posedge clk iff (inf.out_valid));
    option.name = "Warning_coverage";
    option.per_instance = 1;
    option.at_least = WARN_TIMES;
    coverpoint inf.warn_msg {
        // bins b_warn_msg[] = {No_Warn, Date_Warn, Exp_Warn, HP_Warn, MP_Warn, Saturation_Warn};
        bins b_warn_msg [] = {[No_Warn : Saturation_Warn]};
    }
endgroup

SPEC1 spec1_inst = new();
SPEC2 spec2_inst = new();
SPEC3 spec3_inst = new();
SPEC4 spec4_inst = new();
SPEC5 spec5_inst = new();
SPEC6 spec6_inst = new();
SPEC7 spec7_inst = new();

//================================================================
// MARK: ASSERTION
//================================================================
property ASSERT_1;
    @(posedge inf.rst_n) 1 |-> @(posedge clk)
    (inf.out_valid === 0 && inf.complete === 0 && inf.warn_msg === 0 &&
     inf.AR_VALID  === 0 && inf.AR_ADDR  === 0 && inf.R_READY  === 0 &&
     inf.AW_VALID  === 0 && inf.AW_ADDR  === 0 &&
     inf.W_VALID   === 0 && inf.W_DATA   === 0 &&
     inf.B_READY   === 0);
endproperty

property ASSERT_2_Login;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Login) 
        ##[1:4] inf.date_valid
        ##[1:4] inf.player_no_valid |->
        ##[1:999] inf.out_valid;
endproperty

// Level Up: sel_action_valid -> type_valid -> mode_valid -> player_no_valid
property ASSERT_2_Level_Up;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Level_Up)
    ##[1:4] inf.type_valid
    ##[1:4] inf.mode_valid
    ##[1:4] inf.player_no_valid |->
    ##[1:999] inf.out_valid;
endproperty

// Battle: sel_action_valid -> player_no_valid -> monster_valid (3 times)
property ASSERT_2_Battle;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Battle)
    ##[1:4] inf.player_no_valid
    ##[1:4] inf.monster_valid
    ##[1:4] inf.monster_valid
    ##[1:4] inf.monster_valid |->
    ##[1:999] inf.out_valid;
endproperty

// Use Skill: sel_action_valid -> player_no_valid -> MP_valid (4 times)
property ASSERT_2_Use_Skill;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Use_Skill)
    ##[1:4] inf.player_no_valid
    ##[1:4] inf.MP_valid
    ##[1:4] inf.MP_valid
    ##[1:4] inf.MP_valid
    ##[1:4] inf.MP_valid |->
    ##[1:999] inf.out_valid;
endproperty

// Check Inactive: sel_action_valid -> date_valid -> player_no_valid
property ASSERT_2_Check_Inactive;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Check_Inactive)
    ##[1:4] inf.date_valid
    ##[1:4] inf.player_no_valid |-> 
    ##[1:999] inf.out_valid;
endproperty

property ASSERT_3;
    @(negedge clk) ((inf.out_valid !==0 ) & (inf.complete === 1)) |-> (inf.warn_msg === No_Warn);
endproperty

//================================================================

// Login
property ASSERT_4_Login;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Login) |->
    ##[1:4] inf.date_valid
    ##[1:4] inf.player_no_valid;
endproperty

// Level Up
property ASSERT_4_Level_Up;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Level_Up) |->
    ##[1:4] inf.type_valid
    ##[1:4] inf.mode_valid
    ##[1:4] inf.player_no_valid;
endproperty

// Battle
property ASSERT_4_Battle;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Battle) |->
    ##[1:4] inf.player_no_valid
    ##[1:4] inf.monster_valid
    ##[1:4] inf.monster_valid
    ##[1:4] inf.monster_valid;
endproperty

// Use Skill
property ASSERT_4_Use_Skill;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Use_Skill) |->
    ##[1:4] inf.player_no_valid
    ##[1:4] inf.MP_valid
    ##[1:4] inf.MP_valid
    ##[1:4] inf.MP_valid
    ##[1:4] inf.MP_valid;
endproperty

// Check Inactive
property ASSERT_4_Check_Inactive;
    @(posedge clk) (inf.sel_action_valid === 1 & inf.D.d_act[0] === Check_Inactive) |->
    ##[1:4] inf.date_valid
    ##[1:4] inf.player_no_valid;
endproperty


property ASSERT_5_sel_action;
    @(posedge clk) (inf.sel_action_valid === 1) |->
    !(inf.type_valid || inf.mode_valid || inf.date_valid || inf.player_no_valid || inf.monster_valid || inf.MP_valid);
endproperty

property ASSERT_5_type;
    @(posedge clk) (inf.type_valid === 1) |->
    !(inf.sel_action_valid || inf.mode_valid || inf.date_valid || inf.player_no_valid || inf.monster_valid || inf.MP_valid);
endproperty

property ASSERT_5_mode;
    @(posedge clk) (inf.mode_valid === 1) |->
    !(inf.sel_action_valid || inf.type_valid || inf.date_valid || inf.player_no_valid || inf.monster_valid || inf.MP_valid);
endproperty

property ASSERT_5_date;
    @(posedge clk) (inf.date_valid === 1) |->
    !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || inf.player_no_valid || inf.monster_valid || inf.MP_valid);
endproperty

property ASSERT_5_player_no;
    @(posedge clk) (inf.player_no_valid === 1) |->
    !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || inf.date_valid || inf.monster_valid || inf.MP_valid);
endproperty

property ASSERT_5_monster;
    @(posedge clk) (inf.monster_valid === 1) |->
    !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || inf.date_valid || inf.player_no_valid || inf.MP_valid);
endproperty

property ASSERT_5_MP;
    @(posedge clk) (inf.MP_valid === 1) |->
    !(inf.sel_action_valid || inf.type_valid || inf.mode_valid || inf.date_valid || inf.player_no_valid || inf.monster_valid);
endproperty

property ASSERT_6;
    @(posedge clk) inf.out_valid |=> !inf.out_valid;
endproperty

property ASSERT_7;
    @(posedge clk) (inf.out_valid === 1) |-> ##[1:4] inf.sel_action_valid; //maybe
endproperty


property ASSERT_8_MONTH;
    @(posedge clk) (inf.date_valid === 1) |-> inf.D.d_date[0].M inside {[1:12]};
endproperty

property ASSERT_8_DAY_28; 
    @(posedge clk) ((inf.date_valid === 1) & inf.D.d_date[0].M === 2) |-> inf.D.d_date[0].D inside {[1:28]};
endproperty

property ASSERT_8_DAY_30;
    @(posedge clk) ((inf.date_valid === 1) & (inf.D.d_date[0].M === 4 || inf.D.d_date[0].M === 6 || inf.D.d_date[0].M === 9 || inf.D.d_date[0].M === 11)) |-> inf.D.d_date[0].D inside {[1:30]};
endproperty

property ASSERT_8_DAY_31; //
    @(posedge clk) ((inf.date_valid === 1) & (inf.D.d_date[0].M === 1 || inf.D.d_date[0].M === 3 || inf.D.d_date[0].M === 5 || inf.D.d_date[0].M === 7 || inf.D.d_date[0].M === 8 || inf.D.d_date[0].M === 10 || inf.D.d_date[0].M === 12)) |-> inf.D.d_date[0].D inside {[1:31]};
endproperty

property ASSERT_9_write;
    @(posedge clk) inf.AR_VALID |-> !inf.AW_VALID;
endproperty

property ASSERT_9_read;
    @(posedge clk) inf.AW_VALID |-> !inf.AR_VALID;
endproperty

//================================================================
// MARK: DISPLAY

assert property(ASSERT_1)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 1 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_2_Login)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 2 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_2_Level_Up)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 2 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_2_Battle)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 2 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_2_Use_Skill)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 2 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_2_Check_Inactive)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 2 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_3)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 3 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_4_Login)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 4 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_4_Level_Up)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 4 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_4_Battle)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 4 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_4_Use_Skill)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 4 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_4_Check_Inactive)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 4 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_sel_action)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_type)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_mode)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_date)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_player_no)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_monster)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_5_MP)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 5 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_6)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 6 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_7)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 7 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_8_MONTH)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 8 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_8_DAY_28)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 8 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_8_DAY_30)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 8 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_8_DAY_31)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 8 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_9_write)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 9 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

assert property(ASSERT_9_read)
    else begin
        $display("----------------------------------------------------");
        $display(" Assertion 9 is violated ");
        $display("----------------------------------------------------");
        $fatal;
    end

endmodule