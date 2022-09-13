/*
 * agProto.h
 *
 * Copyright (C) 1992-2018 by Bruce Korb - all rights reserved
 * Copyright (C) 2022 Michael Schierl
 *
 * AutoGen is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Manually curated prototypes for Autogen bootstrap.
 *
 * Only prototypes that are needed (i. e. they are referenced before definition) are included.
 */

// autogen.c
static SCM ag_scm_c_eval_string_from_file_line(char const *,char const *, int);
static void * ao_malloc(size_t);
static void * ao_realloc (void *, size_t);
static void done_check(void);

// agDep.c
static void add_source_file(char const *);
static void add_target_file(char const *);
static void rm_target_file(char const *);
// agInit.c
static void config_dep(char const *);
static void initialize(int, char **);
static void init_scm(void);
static void prep_env(void);
// agShell.c
static void close_server_shell(void);
static char * load_data(void);
static char * shell_cmd(char const *);
// agUtils.c
static char * aprf(char const *, ...);
static void fswarn(char const *, char const *);
static void process_ag_opts(int, char **);
static char const * skip_expr(char const *, size_t);
static char const * skip_scheme(char const *,  char const *);
static char * span_quote(char *);

// defDirect.c
static char * processDirective(char *);
// defFind.c
static int canonical_name(char *, char const *, int);
static def_ent_t * find_def_ent(char *, bool *);
static def_ent_t ** find_def_ent_list(char *);
// defLex.c
static void alist_to_autogen_def(void);
static char * build_here_str(char *);
static char * gather_name(char *, te_dp_event *);
static void loadScheme(void);
static void yyerror(char *);
static te_dp_event yylex(void);
// defLoad.c
static void delete_ent(def_ent_t *);
static void mod_time_is_now(void);
static def_ent_t * new_def_ent(void);
static def_ent_t * number_and_insert_ent(char *, char const *);
static void print_ent(def_ent_t *);
static void read_defs(void);

// expExtract.c
static char * load_file(char const *);
// expGuile.c
static teGuileType ag_scm_type_e(SCM);
static char * ag_scm2zchars(SCM, char const *);
// expPrint.c
static SCM run_printf(char const *, int, SCM);
// expString.c
static void do_multi_subs(char **, ssize_t *, SCM, SCM);

// funcEval.c
static SCM eval(char const *);
static char const * eval_mac_expr(bool *);
static char const * scm2display(SCM);
// funcFor.c
static void free_for_context(int);
static for_state_t * new_for_context(void);

// tpLoad.c
static void cleanup(templ_t *);
static tSuccess find_file(char const *, char *, char const * const *, char const *);
static templ_t * find_tpl(char const *);
static templ_t * tpl_load(char const *, char const *);
static void tpl_unload(templ_t *);
// tpParse.c
static macro_t * parse_tpl(macro_t *, char const **);
// tpProcess.c
static void gen_block(templ_t *, macro_t *, macro_t *);
static void open_output(out_spec_t *);
static void out_close(bool);
static void process_tpl(templ_t *);
static void set_utime(char const *);
static void trace_macro(templ_t *, macro_t *);

// cook.c
static char * ao_string_cook(char *, int *);
static unsigned int ao_string_cook_escape_char(char const *, char *, uint_t);
// functions.c
static loop_jmp_type_t call_gen_block(jmp_buf, templ_t *, macro_t *, macro_t *);
static void gen_new_block(templ_t *);
// putshell.c
static char const * optionQuoteString(char const *, char const *);
// text_mmap.c
static void * text_mmap(char const *, int, int, tmap_info_t *);
static int text_munmap(tmap_info_t *);
// usage.c
static void optionPrintParagraphs(char const *, bool, FILE *);
