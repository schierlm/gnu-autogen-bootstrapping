/*
 * agCharMap.c
 *
 * Copyright (C) 1992-2018 by Bruce Korb - all rights reserved
 * Copyright (C) 2022 Michael Schierl
 *
 * AutoGen is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Char-mapper definitions (only those that are actually used by Autogen).
 * Implemented manually without mapping arrays.
 *
 * For rules, see autoopts/autogen.map.
 */

static bool IS_HORIZ_WHITE_CHAR(char ch) {
  return ch == ' ' || ch == '\t';
}

static bool IS_NON_NL_WHITE_CHAR(char ch) {
  return ch == ' ' || ch == '\t' || ch == '\v' || ch == '\f' || ch == '\r' || ch == '\b';
}

static bool IS_NEWLINE_CHAR(char ch) {
  return ch == '\n';
}

static bool IS_WHITESPACE_CHAR(char ch) {
  return IS_NEWLINE_CHAR(ch) || IS_NON_NL_WHITE_CHAR(ch);
}

static bool IS_UPPER_CASE_CHAR(char ch) {
  return ch >= 'A' && ch <= 'Z';
}

static bool IS_LOWER_CASE_CHAR(char ch) {
  return ch >= 'a' && ch <= 'z';
}

static bool IS_ALPHABETIC_CHAR(char ch) {
  return IS_LOWER_CASE_CHAR(ch) || IS_UPPER_CASE_CHAR(ch);
}

static bool IS_OCT_DIGIT_CHAR(char ch) {
  return ch >= '0' && ch <= '7';
}

static bool IS_DEC_DIGIT_CHAR(char ch) {
  return ch >= '0' && ch <= '9';
}

static bool IS_HEX_DIGIT_CHAR(char ch) {
  return (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f');
}

static bool IS_ALPHANUMERIC_CHAR(char ch) {
  return IS_ALPHABETIC_CHAR(ch) || IS_DEC_DIGIT_CHAR(ch);
}

static bool IS_VAR_FIRST_CHAR(char ch) {
  return IS_ALPHABETIC_CHAR(ch) || ch == '_';
}

static bool IS_VARIABLE_NAME_CHAR(char ch) {
  return IS_ALPHANUMERIC_CHAR(ch) || ch == '_';
}

static bool IS_OPTION_NAME_CHAR(char ch) {
  return IS_VARIABLE_NAME_CHAR(ch) || ch == '-' || ch == '^';
}

static bool IS_VALUE_NAME_CHAR(char ch) {
  return IS_OPTION_NAME_CHAR(ch) || ch == ':';
}

static bool IS_GRAPHIC_CHAR(char ch) {
  return ch >= '!' && ch <= '~';
}

static bool IS_QUOTE_CHAR(char ch) {
  return ch == '"' || ch == '\'';
}

static bool IS_UNQUOTABLE_CHAR(char ch) {
  return IS_GRAPHIC_CHAR(ch) && strchr("#,;<=>[\\]`{}?*\"'()", ch) == NULL;
}

static bool IS_END_TOKEN_CHAR(char ch) {
  return ch == '\0' || IS_WHITESPACE_CHAR(ch);
}

static bool IS_FALSE_TYPE_CHAR(char ch) {
  return ch == '\0' || ch == 'n' || ch == 'N' || ch == 'f' || ch == 'F' || ch == '0';
}

static bool IS_PUNCTUATION_CHAR(char ch) {
  return IS_GRAPHIC_CHAR(ch) && !IS_ALPHANUMERIC_CHAR(ch) && ch != '_';
}

static bool IS_SIGNED_NUMBER_CHAR(char ch) {
  return IS_DEC_DIGIT_CHAR(ch) || ch == '-' || ch == '~';
}

static bool IS_SUFFIX_CHAR(char ch) {
  return IS_ALPHANUMERIC_CHAR(ch) || ch == '-' || ch == '.' || ch == '_';
}

static bool IS_FILE_NAME_CHAR(char ch) {
  return IS_SUFFIX_CHAR(ch) || ch == '/' || ch == '\\';
}

static bool IS_SUFFIX_FMT_CHAR(char ch) {
  return IS_FILE_NAME_CHAR(ch) || ch == '%';
}

static bool IS_MAKE_SCRIPT_CHAR(char ch) {
  return ch == '$' || ch == '\n';
}

static bool IS_NAME_SEP_CHAR(char ch) {
  return ch == '.' || ch == '[' || ch == ']';
}

static bool IS_SCHEME_NOTE_CHAR(char ch) {
  return ch == '"' || ch == '\'' || ch == '(' || ch == ')';
}

static inline char * SPN_CHAR_MAP_CHARS(char const * p, bool (*is_func)(char ch))
{
    while ((*is_func)(*p)) p++;
    return (char *)(uintptr_t)p;
}

static inline char * SPN_CHAR_MAP_BACK(char const * s, char const * e,  bool (*is_func)(char ch))
{
   if (s >= e) e = s + strlen(s);
    while ((e > s) && (*is_func)(e[-1])) e--;
    return (char *)(uintptr_t)e;
}

static inline char * BRK_CHAR_MAP_CHARS(char const * p, bool (*is_func)(char ch))
{
    while ((*p != '\0') && (!(*is_func)(*p))) p++;
    return (char *)(uintptr_t)p;
}

#define SPN_HORIZ_WHITE_CHARS(p)    SPN_CHAR_MAP_CHARS(p, IS_HORIZ_WHITE_CHAR)
#define SPN_NON_NL_WHITE_CHARS(p)   SPN_CHAR_MAP_CHARS(p, IS_NON_NL_WHITE_CHAR)
#define SPN_WHITESPACE_CHARS(p)     SPN_CHAR_MAP_CHARS(p, IS_WHITESPACE_CHAR)
#define SPN_VALUE_NAME_CHARS(p)     SPN_CHAR_MAP_CHARS(p, IS_VALUE_NAME_CHAR)
#define SPN_VARIABLE_NAME_CHARS(p)  SPN_CHAR_MAP_CHARS(p, IS_VARIABLE_NAME_CHAR)
#define SPN_UNQUOTABLE_CHARS(p)     SPN_CHAR_MAP_CHARS(p, IS_UNQUOTABLE_CHAR)
#define SPN_HEX_DIGIT_CHARS(p)      SPN_CHAR_MAP_CHARS(p, IS_HEX_DIGIT_CHAR)
#define SPN_DEC_DIGIT_CHARS(p)      SPN_CHAR_MAP_CHARS(p, IS_DEC_DIGIT_CHAR)
#define SPN_FILE_NAME_CHARS(p)      SPN_CHAR_MAP_CHARS(p, IS_FILE_NAME_CHAR)
#define SPN_SUFFIX_CHARS(p)         SPN_CHAR_MAP_CHARS(p, IS_SUFFIX_CHAR)
#define SPN_SUFFIX_FMT_CHARS(p)     SPN_CHAR_MAP_CHARS(p, IS_SUFFIX_FMT_CHAR)

#define SPN_WHITESPACE_BACK(s,e)    SPN_CHAR_MAP_BACK(s, e, IS_WHITESPACE_CHAR)
#define SPN_HORIZ_WHITE_BACK(s,e)   SPN_CHAR_MAP_BACK(s, e, IS_HORIZ_WHITE_CHAR)

#define BRK_ALPHANUMERIC_CHARS(p)     BRK_CHAR_MAP_CHARS(p, IS_ALPHANUMERIC_CHAR)
#define BRK_MAKE_SCRIPT_CHARS(p)     BRK_CHAR_MAP_CHARS(p, IS_MAKE_SCRIPT_CHAR)
#define BRK_NAME_SEP_CHARS(p)     BRK_CHAR_MAP_CHARS(p, IS_NAME_SEP_CHAR)
#define BRK_NEWLINE_CHARS(p)     BRK_CHAR_MAP_CHARS(p, IS_NEWLINE_CHAR)
#define BRK_SCHEME_NOTE_CHARS(p)     BRK_CHAR_MAP_CHARS(p, IS_SCHEME_NOTE_CHAR)
#define BRK_WHITESPACE_CHARS(p)     BRK_CHAR_MAP_CHARS(p, IS_WHITESPACE_CHAR)
