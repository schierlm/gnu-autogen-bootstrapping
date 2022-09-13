/*
 * agFSM.c
 *
 * Copyright (C) 1992-2018 by Bruce Korb - all rights reserved
 * Copyright (C) 2022 Michael Schierl
 *
 * AutoGen is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Autogen's finite state machines (defParse.def, pseudo.def) and states, implemented as ordinary logic.
 */

// pseudo.def
typedef enum {
    PM_ST_INIT, PM_ST_ST_MARK, PM_ST_AGEN, PM_ST_TEMPL, PM_ST_END_MARK, PM_ST_INVALID, PM_ST_DONE
} te_pm_state;

typedef enum {
    PM_EV_ED_MODE, PM_EV_MARKER, PM_EV_END_PSEUDO, PM_EV_AUTOGEN, PM_EV_TEMPLATE, PM_EV_SUFFIX, PM_EV_SCHEME, PM_EV_INVALID
} te_pm_event;

typedef enum {
    PM_TR_INIT_MARKER, PM_TR_INVALID, PM_TR_NOOP, PM_TR_SKIP_ED_MODE, PM_TR_TEMPL_MARKER,PM_TR_TEMPL_SCHEME, PM_TR_TEMPL_SUFFIX
} te_pm_trans;


// defParse.def
typedef enum {
    DP_ST_INIT, DP_ST_NEED_DEF, DP_ST_NEED_TPL, DP_ST_NEED_SEMI, DP_ST_NEED_NAME, DP_ST_HAVE_NAME, DP_ST_NEED_VALUE, DP_ST_NEED_IDX,
    DP_ST_NEED_CBKT, DP_ST_INDX_NAME, DP_ST_HAVE_VALUE, DP_ST_INVALID, DP_ST_DONE
} te_dp_state;

typedef enum {
    DP_EV_AUTOGEN, DP_EV_DEFINITIONS, DP_EV_END, DP_EV_VAR_NAME, DP_EV_OTHER_NAME, DP_EV_STRING, DP_EV_HERE_STRING, DP_EV_DELETE_ENT, DP_EV_NUMBER,
    DP_EV_LIT_SEMI, DP_EV_LIT_EQ, DP_EV_LIT_COMMA, DP_EV_LIT_O_BRACE, DP_EV_LIT_C_BRACE, DP_EV_LIT_OPEN_BKT, DP_EV_LIT_CLOSE_BKT, DP_EV_INVALID
} te_dp_event;

// prototypes
static te_dp_event yylex(void);
static te_dp_state dp_do_empty_val(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_end_block(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_have_name_lit_eq(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_indexed_name(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_invalid(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_need_name_end(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_need_name_var_name(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_need_value_delete_ent(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_next_val(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_start_block(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_str_value(te_dp_state, te_dp_state, te_dp_event);
static te_dp_state dp_do_tpl_name(te_dp_state, te_dp_state, te_dp_event);
static int dp_invalid_transition( te_dp_state, te_dp_event);

static te_dp_state dp_run_fsm( void )
{
    te_dp_state dp_state = DP_ST_INIT;
    te_dp_event trans_evt;
    te_dp_state nxtSt;
    while (dp_state < DP_ST_INVALID) {

#define FSM_FIND_TRANSITION
#include "defParse.x"
#undef  FSM_FIND_TRANSITION

        if (dp_state == DP_ST_INIT && (trans_evt == DP_EV_AUTOGEN)) {
            dp_state = DP_ST_NEED_DEF;
        } else if (dp_state == DP_ST_NEED_DEF && (trans_evt == DP_EV_DEFINITIONS)) {
            dp_state = DP_ST_NEED_TPL;
        } else if (dp_state == DP_ST_NEED_TPL && (trans_evt == DP_EV_STRING || trans_evt == DP_EV_OTHER_NAME || trans_evt == DP_EV_VAR_NAME)) {
            dp_state = dp_do_tpl_name(dp_state, DP_ST_NEED_SEMI, trans_evt);
        } else if (dp_state == DP_ST_NEED_SEMI && (trans_evt == DP_EV_LIT_SEMI)) {
            dp_state = DP_ST_NEED_NAME;
        } else if (dp_state == DP_ST_NEED_NAME && (trans_evt == DP_EV_AUTOGEN)) {
            dp_state = DP_ST_NEED_DEF;
        } else if (dp_state == DP_ST_NEED_NAME && (trans_evt == DP_EV_VAR_NAME)) {
            dp_state = dp_do_need_name_var_name(dp_state, DP_ST_HAVE_NAME, trans_evt);
        } else if (dp_state == DP_ST_NEED_NAME && (trans_evt == DP_EV_LIT_C_BRACE)) {
            dp_state = dp_do_end_block(dp_state, DP_ST_HAVE_VALUE, trans_evt);
        } else if (dp_state == DP_ST_NEED_NAME && (trans_evt == DP_EV_END)) {
            dp_state = dp_do_need_name_end(dp_state, DP_ST_DONE, trans_evt);
        } else if (dp_state == DP_ST_HAVE_NAME && (trans_evt == DP_EV_LIT_SEMI)) {
            dp_state = dp_do_empty_val(dp_state, DP_ST_NEED_NAME, trans_evt);
        } else if (dp_state == DP_ST_HAVE_NAME && (trans_evt == DP_EV_LIT_EQ)) {
            dp_state = dp_do_have_name_lit_eq(dp_state, DP_ST_NEED_VALUE, trans_evt);
        } else if (dp_state == DP_ST_HAVE_NAME && (trans_evt == DP_EV_LIT_OPEN_BKT)) {
            dp_state = DP_ST_NEED_IDX;
        } else if (dp_state == DP_ST_NEED_IDX && (trans_evt == DP_EV_NUMBER || trans_evt == DP_EV_VAR_NAME)) {
            dp_state = dp_do_indexed_name(dp_state, DP_ST_NEED_CBKT, trans_evt);
        } else if (dp_state == DP_ST_NEED_CBKT && (trans_evt == DP_EV_LIT_CLOSE_BKT)) {
            dp_state = DP_ST_INDX_NAME;
        } else if (dp_state == DP_ST_INDX_NAME && (trans_evt == DP_EV_LIT_SEMI)) {
            dp_state = dp_do_empty_val(dp_state, DP_ST_NEED_NAME, trans_evt);
        } else if (dp_state == DP_ST_INDX_NAME && (trans_evt == DP_EV_LIT_EQ)) {
            dp_state = DP_ST_NEED_VALUE;
        } else if (dp_state == DP_ST_NEED_VALUE && (trans_evt == DP_EV_STRING || trans_evt == DP_EV_HERE_STRING || trans_evt == DP_EV_OTHER_NAME || trans_evt == DP_EV_VAR_NAME || trans_evt == DP_EV_NUMBER)) {
            dp_state = dp_do_str_value(dp_state, DP_ST_HAVE_VALUE, trans_evt);
        } else if (dp_state == DP_ST_NEED_VALUE && (trans_evt == DP_EV_LIT_O_BRACE)) {
            dp_state = dp_do_start_block(dp_state, DP_ST_NEED_NAME, trans_evt);
        } else if (dp_state == DP_ST_NEED_VALUE && (trans_evt == DP_EV_DELETE_ENT)) {
            dp_state = dp_do_need_value_delete_ent(dp_state, DP_ST_NEED_NAME, trans_evt);
        } else if (dp_state == DP_ST_HAVE_VALUE && (trans_evt == DP_EV_LIT_SEMI)) {
            dp_state = DP_ST_NEED_NAME;
        } else if (dp_state == DP_ST_HAVE_VALUE && (trans_evt == DP_EV_LIT_COMMA)) {
            dp_state = dp_do_next_val(dp_state, DP_ST_NEED_VALUE, trans_evt);
        } else {
            dp_state = dp_do_invalid(dp_state, DP_ST_INVALID, trans_evt);
        }
    }
    return dp_state;
}
