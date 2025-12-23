interface INF();
    import  usertype::*;

    logic rst_n;
    logic sel_action_valid;
    logic type_valid;
    logic mode_valid;
    logic date_valid;
    logic player_no_valid;
    logic monster_valid;
    logic MP_valid;
    Data D;

    logic out_valid;
    Warn_Msg warn_msg;
    logic complete;

    logic AR_VALID, R_READY, AW_VALID, W_VALID, B_READY;
    logic [16:0] AR_ADDR, AW_ADDR;
    logic [95:0] W_DATA;

    logic AR_READY, R_VALID, AW_READY, W_READY, B_VALID;
    logic [1:0] R_RESP, B_RESP;
    logic [95:0] R_DATA;

    modport PATTERN(
        input out_valid, warn_msg, complete,
        AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
        output rst_n, sel_action_valid, type_valid, mode_valid, date_valid, player_no_valid, monster_valid, MP_valid, D,
        AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );

    modport DRAM(
	    input  AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	    output AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );

    modport RPG_inf(
        input rst_n, sel_action_valid, type_valid, mode_valid, date_valid, player_no_valid, monster_valid, MP_valid, D,
            AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
        output out_valid, warn_msg, complete,
            AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY
    );

    modport CHECKER(
	input  	rst_n, sel_action_valid, type_valid, mode_valid, date_valid, player_no_valid, monster_valid, MP_valid, D, 
            out_valid, warn_msg, complete,  
			AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY, 
			AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
    );
    
endinterface



