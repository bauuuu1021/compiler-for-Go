#ifndef _COMMON_H_
#define _COMMON_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define STACK_MAX 15    /* limit stack, limit locals, and temp local variable */

typedef enum { VOID_t, INT_t, FLOAT_t, STRING_t, STRONG_INT_t } SEMTYPE;
typedef enum { ADD_t, SUB_t, MUL_t, DIV_t, MOD_t, LT_t, LE_t, EQ_t, GE_t, GT_t, NE_t, AND_t, OR_t, NOT_t, NONE_t } OPERATOR;
typedef enum { start, end, err } JASMIN_CMD;

typedef struct rule_type {
    int i_val, reg;
    double f_val;
    char* id;
    char* string;
    SEMTYPE type;
} RULE_TYPE;

#endif
