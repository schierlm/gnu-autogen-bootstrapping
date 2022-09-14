/*
 * agBootstrap.c
 *
 * Copyright (C) 1992-2018 by Bruce Korb - all rights reserved
 * Copyright (C) 2022 Michael Schierl
 *
 * AutoGen is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Main bootstrap code for Autogen.
 */

#undef   PKGDATADIR
#define  PKGDATADIR ""
#define AUTOGEN_VERSION "5.18.986"
#define REGEX_HEADER <regex.h>
#define VALUE(s)      = s
#define MODE
#define NUL                     '\0'
#define BEL                     '\a'
#define BS                      '\b'
#define HT                      '\t'
#define LF                      '\n'
#define NL                      '\n'
#define VT                      '\v'
#define FF                      '\f'
#define CR                      '\r'
#define MK_STR_OCT_FMT  "\%03o"
#define LINE_SPLICE "\\n\\\n"
#define PUTS_FMT "  puts(_(%s));\n"
#define parse_duration option_parse_duration
#define HAVE_OPT(foo) 0
#define OPT_ARG(foo) NULL
#define STATE_OPT(foo) 0
#define ENABLED_OPT(foo) false
#define SUCCESS  ((tSuccess) 0)
#define FAILURE  ((tSuccess)-1)
#define PROBLEM  ((tSuccess) 1)
#define VOIDP(_a)  ((void *)(uintptr_t)(_a))
#define C(_t,_p)  ((_t)VOIDP(_p))
#define NOT_REACHED __builtin_unreachable();
#define STMTS(s)  do { s; } while (false)
#define FOPEN_BINARY_FLAG ""
#define FOPEN_TEXT_FLAG ""
#define CONFIG_SHELL /bin/bash

typedef unsigned int uint_t;
typedef int tSuccess;

#define SUCCEEDED(p)    ((p) == SUCCESS)
#define SUCCESSFUL(p)   SUCCEEDED(p)
#define FAILED(p)       ((p) <  SUCCESS)
#define HADGLITCH(p)    ((p) >  SUCCESS)

static char const make_prog[] = "make";

typedef enum {
    AUTOGEN_EXIT_SUCCESS = 0,
    AUTOGEN_EXIT_OPTION_ERROR = 1,
    AUTOGEN_EXIT_BAD_TEMPLATE = 2,
    AUTOGEN_EXIT_BAD_DEFINITIONS = 3,
    AUTOGEN_EXIT_LOAD_ERROR = 4,
    AUTOGEN_EXIT_FS_ERROR = 5,
    AUTOGEN_EXIT_SIGNAL = 128,
    AUTOGEN_EXIT_USAGE_ERROR = 64
}   autogen_exit_code_t;

typedef enum { TRACE_NOTHING, TRACE_DEBUG_MESSAGE, TRACE_SERVER_SHELL, TRACE_BLOCK_MACROS, TRACE_EXPRESSIONS, TRACE_EVERYTHING } te_Trace;

#define SHELL_ENABLED
#define HAVE_WORKING_FORK
#define HAVE_CONFIG_H
#define HAVE_STDARG_H
#define HAVE_STRING_H
#define HAVE_STDBOOL_H
#define HAVE_STRFTIME
#define HAVE_STRSIGNAL
#define HAVE_UNISTD_H
#define HAVE_UINTMAX_T
#define OPT_VALUE_TRACE 0
#define OPT_VALUE_LOOP_LIMIT 256
#define AG_PATH_MAX PATH_MAX
#include <unistd.h>
#include <sys/wait.h>
#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <utime.h>
#include <fcntl.h>
#include <dirent.h>
#include <ctype.h>

typedef intptr_t t_word;

#include <getopt.h>
const char *opt_override_tpl = NULL;
const char *opt_define = NULL;
const char *opt_tpl_dirs = NULL;
const char *opt_base_name = NULL;
const char *opt_definitions = NULL;
const char *opt_PROGPATH = NULL;

# define AG_SCM_IS_PROC(_p)           scm_is_true( scm_procedure_p(_p))
# define AG_SCM_LIST_P(_l)            scm_is_true( scm_list_p(_l))
# define AG_SCM_PAIR_P(_p)            scm_is_true( scm_pair_p(_p))
# define AG_SCM_STR02SCM(_s)          scm_from_latin1_string(_s)
# define AG_SCM_STR2SCM(_st,_sz)      scm_from_latin1_stringn(_st,_sz)
# define AG_SCM_TO_NEWSTR(_s)         scm_to_latin1_string(_s)
# define AG_SCM_STRING_P(_s)          scm_is_string(_s)
# define AG_SCM_STRLEN(_s)            scm_c_string_length(_s)
# define AG_SCM_SYM_P(_s)             scm_is_symbol(_s)
# define AG_SCM_TO_INT(_i)            scm_to_int(_i)
# define AG_SCM_TO_LONG(_v)           scm_to_long(_v)
# define AG_SCM_TO_ULONG(_v)          ((unsigned long)scm_to_ulong(_v))
# define AG_SCM_VEC_P(_v)             scm_is_vector(_v)

typedef struct {
    void *      txt_data;      ///< text file data
    size_t      txt_size;      ///< actual file size
    size_t      txt_full_size; ///< mmaped mem size
    int         txt_fd;        ///< file descriptor
    int         txt_zero_fd;   ///< fd for /dev/zero
    int         txt_errno;     ///< warning code
    int         txt_prot;      ///< "prot" flags
    int         txt_flags;     ///< mapping type
} tmap_info_t;

typedef enum {
    GH_TYPE_UNDEFINED = 0,
    GH_TYPE_BOOLEAN,
    GH_TYPE_SYMBOL,
    GH_TYPE_CHAR,
    GH_TYPE_VECTOR,
    GH_TYPE_PAIR,
    GH_TYPE_NUMBER,
    GH_TYPE_STRING,
    GH_TYPE_PROCEDURE,
    GH_TYPE_LIST,
    GH_TYPE_INEXACT,
    GH_TYPE_EXACT
} teGuileType;

#  ifndef  PROT_READ
#   define PROT_READ            0x01
#  endif
#  ifndef  PROT_WRITE
#   define PROT_WRITE           0x02
#  endif
#  ifndef  MAP_SHARED
#   define MAP_SHARED           0x01
#  endif
#  ifndef  MAP_PRIVATE
#   define MAP_PRIVATE          0x02
#  endif
#define TEXT_MMAP_FAILED_ADDR(a)  (VOIDP(a) == VOIDP(MAP_FAILED))
#ifndef MAP_FAILED
#  define  MAP_FAILED           VOIDP(-1)
#endif

//#include "autoopts/project.h"
#include "autogen.h"

bool opt_writable = false;
int opt_timeout = 10;
static bool trace_is_to_pipe = false;

void vdie(int exit_code, char const * fmt, va_list ap)
{
    fputs("fatal error:\n", stderr);
    vfprintf(stderr, fmt, ap);
    fflush(stderr);
    exit(exit_code);
}

void die(int exit_code, char const * fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    vdie(exit_code, fmt, ap);
}

void fserr(int exit_code, char const * op, char const * fname)
{
    die(exit_code, "Fserr %s on %s\n", op, fname);
}

static void
fserr_warn(char const * prog, char const * op, char const * fname)
{
    fprintf(stderr, "Fserr (in %s) %d %s: %s on %s", prog, errno, strerror(errno),
            op, fname);
}

static time_t option_parse_duration(char const * in_pz)
{
  die(1, "MISSING option_parse_duration\n");
  return 0;
}

static directive_enum_t find_directive(char const * str)
{
  static char const accept[] =
      "abcdefghijklmnopqrstuvwxyz";
  unsigned int clen = strspn(str, accept);

  if (isalnum((unsigned char)str[clen]))
      return DIR_INVALID;

  for(directive_enum_t id = DIR_INVALID; id < DIR_COUNT; id++) {
    if (directive_keywd_len[id] == clen && strncmp(directive_nm_table[id], str, clen) == 0) {
      return id;
    }
  }

  return DIR_INVALID;
}

static char const * directive_name(directive_enum_t id)
{
    static char const undef[] = "* UNDEFINED *";
    char const * res = undef;
    if (id < DIR_COUNT) {
        res = directive_nm_table[id];
        if (res == NULL)
            res = undef;
    }
    return res;
}

static char * doDir_directive_disp(char const * str, char * scan_next)
{
    directive_enum_t id = find_directive(str);
    doDir_hdl_t * disp = directive_dispatch[id];
    if (disp == NULL) disp = doDir_invalid;
    return disp(id, str + directive_keywd_len[id], scan_next);
}

#define FTYP_SELECT_COMPARE_FULL           0x8000  /* *==* */
#define FTYP_SELECT_COMPARE_SKP_START      0x8001  /* *==  */
#define FTYP_SELECT_COMPARE_SKP_END        0x8002  /*  ==* */
#define FTYP_SELECT_COMPARE                0x8003  /*  ==  */

#define FTYP_SELECT_EQUIVALENT_FULL        0x8004  /* *=*  */
#define FTYP_SELECT_EQUIVALENT_SKP_START   0x8005  /* *=   */
#define FTYP_SELECT_EQUIVALENT_SKP_END     0x8006  /*  =*  */
#define FTYP_SELECT_EQUIVALENT             0x8007  /*  =   */

#define FTYP_SELECT_MATCH_FULL             0x8008  /* *~~* */
#define FTYP_SELECT_MATCH_SKP_START        0x8009  /* *~~  */
#define FTYP_SELECT_MATCH_SKP_END          0x800A  /*  ~~* */
#define FTYP_SELECT_MATCH                  0x800B  /*  ~~  */

#define FTYP_SELECT_EQV_MATCH_FULL         0x800C  /* *~*  */
#define FTYP_SELECT_EQV_MATCH_SKP_START    0x800D  /* *~   */
#define FTYP_SELECT_EQV_MATCH_SKP_END      0x800E  /*  ~*  */
#define FTYP_SELECT_EQV_MATCH              0x800F  /*  ~   */

#define FTYP_SELECT_MATCH_ANYTHING         0x801C  /*  *   */
#define FTYP_SELECT_MATCH_EXISTENCE        0x801D  /* +E   */
#define FTYP_SELECT_MATCH_NONEXISTENCE     0x801E  /* !E   */

#include "agCharMap.c"

#define AGALOC(_c, _w) ao_malloc((size_t)_c)
#define AGREALOC(_p, _c, _w)  ao_realloc(VOIDP(_p), (size_t)_c)
#define AGFREE(_p) free((void*)(_p))
#define AGDUPSTR(_p, _s, _w)  (_p = ao_strdup(_s))
char const * tpl_fname = NULL;
typedef SCM (*scm_callback_t)(void);

#include "autogen.c"
#include "../autoopts/streqvcmp.c"
#include "../compat/pathfind.c"
#define FSM_USER_HEADERS
#define FSM_HANDLER_CODE
#include "defParse.x"
#undef  FSM_USER_HEADERS
#undef  FSM_HANDLER_CODE
#include "defLex.c"
#include "funcCase.c"
#include "funcDef.c"
#include "funcEval.c"
#include "funcFor.c"
#include "funcIf.c"
#include "functions.c"
#include "expExtract.c"
#include "expFormat.c"
#include "expGperf.c"
#include "expGuile.c"
#include "expMake.c"
#include "expOutput.c"
#include "expPrint.c"
#include "expState.c"
#include "expString.c"
#include "agShell.c"
#include "ag-text.c"
#include "agDep.c"
#include "agInit.c"
#include "agUtils.c"
#include "defDirect.c"
#include "defFind.c"
#include "defLoad.c"
#include "fmemopen.c"
#include "loadPseudo.c"
#include "scribble.c"
#include "tpLoad.c"
#include "tpParse.c"
#include "tpProcess.c"
#include "autoopts/cook.c"
#include "autoopts/text_mmap.c"
#include "autoopts/putshell.c"
#include "autoopts/usage.c"

#undef HAVE_CONFIG_H
#define HAVE_STRTOUL
#define HAVE_LIMITS_H
#undef assert
#include "snprintfv/printf.c"
#include "snprintfv/filament.c"
#include "snprintfv/mem.c"
#include "snprintfv/stream.c"
#include "snprintfv/format.c"
#include "snprintfv/custom.c"
