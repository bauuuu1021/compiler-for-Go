/*	Definition section */
%{
#include "common.h" //Extern variables that communicate with lex

extern int yylineno;
extern int yylex();

/* symbol element */
typedef struct symbol {
    int index;
    char id[16];
    int type;
    double value;
    struct symbol *next;
} SYMBOL;

SYMBOL *symbol_head = NULL, *symbol_tail = NULL, *symbol_cur = NULL;

/* create jasmin file */
void createJasmin(int cmd);
FILE *file;

/* error handling */
int numErr;
void yyerror(const char* error);

/* symbol table function */
SYMBOL* lookup_symbol(char *id);
void create_symbol();
void insert_symbol(int type, char *id, double insert_value);
void dump_symbol();

%}

%union {
    RULE_TYPE rule_type;
    int intVal;
}

/* Token definition */
%token INC DEC
%token MTE LTE EQ NE
%token <rule_type> ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token AND OR NOT
%token PRINT PRINTLN
%token IF ELSE FOR
%token VAR
%token QUOTA
%token NEWLINE

%token <rule_type> I_CONST
%token <rule_type> F_CONST
%token <rule_type> VOID INT FLOAT STRING ID

%type <rule_type> initializer expr equality_expr relational_expr
%type <rule_type> additive_expr multiplicative_expr prefix_expr postfix_expr
%type <rule_type> primary_expr constant
%type <rule_type> type

%type <intVal> add_op mul_op print_func_op assignment_op equality_op relational_op

%start program

%right ')' ELSE

/* Grammar section */
%%


program
    : program stat
    |
;

stat
    : declaration
    | compound_stat
    | expression_stat
    | print_func
    | selection_stat
;

declaration
    : VAR ID type '=' initializer NEWLINE
        {
            if (lookup_symbol($2.id)) { /* redefined */
                printf("[ERROR] redeclaration of ‘%s’ at line %d\n", $2.id, yylineno);
                numErr++;
            }
            else
                insert_symbol($3.type, $2.id, $5.f_val);
        }
    | VAR ID type NEWLINE
        {
            if (lookup_symbol($2.id)) { /* redefined */
                printf("[ERROR] redeclaration of ‘%s’ at line %d\n", $2.id, yylineno);
                numErr++;
            }
            else
                insert_symbol($3.type, $2.id, 0);
        }
;

type
    : INT
    | FLOAT
    | VOID
;

initializer
    : equality_expr
;

compound_stat
    : '{' '}'
    | '{' block_item_list '}'
;

block_item_list
    : block_item
    | block_item_list block_item 
;

block_item
    : stat
;

selection_stat
    : IF '(' expr ')' stat ELSE stat
    | IF '(' expr ')' stat
;

expression_stat
    : expr NEWLINE
    | NEWLINE
;

expr
    : equality_expr
    | ID '=' expr
    | prefix_expr assignment_op expr
;

assignment_op
    : ADDASGN
    | SUBASGN
    | MULASGN
    | DIVASGN
    | MODASGN
;

equality_expr
    : relational_expr
    | equality_expr equality_op relational_expr
;

equality_op
    : EQ
    | NE
;

relational_expr
    : additive_expr
    | relational_expr relational_op additive_expr
;

relational_op
    : '<'
    | '>'
    | LTE
    | MTE
;

additive_expr
    : multiplicative_expr
    | additive_expr add_op multiplicative_expr
        {
            /* operation */
            if ($2 == ADD_t) {  /* add */
                fprintf(file, "\tfadd\n");
            }
            else {              /* sub */
                fprintf(file, "\tfsub\n");
            }

            /* modify data type of $$ */
            if ($1.type==FLOAT_t || $3.type==FLOAT_t)
                $$.type = FLOAT_t;
            else if ($1.type==INT_t && $3.type==INT_t) {
                $$.type = INT_t;
            }
            else {
                $$.type = STRONG_INT_t;
                fprintf(file, "\tf2i\n\ti2f\n");    /* cast to int */
            }
        }
;

add_op
    : '+'   { $$ = ADD_t; }
    | '-'   { $$ = SUB_t; }
;

multiplicative_expr
    : prefix_expr
    | multiplicative_expr mul_op prefix_expr
        {
            /* operation */
            if ($2 == MUL_t) {      /* mul */
                fprintf(file, "\tfmul\n");
            }
            else if ($2 == DIV_t) { /* div */
                fprintf(file, "\tfdiv\n");
            }
            else {                  /* mod */
                /* check if both operands are int */
                if ($1.type==FLOAT_t||$3.type==FLOAT_t) {
                    printf("[ERROR] invalid operands (double) in MOD at line %d\n", yylineno);
                    numErr++;
                }
                else
                    fprintf(file, "\tirem\n");
            } 

            /* modify data type of $$ */
            if ($1.type==FLOAT_t || $3.type==FLOAT_t)
                $$.type = FLOAT_t;
            else if ($1.type==INT_t && $3.type==INT_t)
                $$.type = INT_t;
            else {
                $$.type = STRONG_INT_t;
                fprintf(file, "\tf2i\n\ti2f\n");    /* cast to int */
            }
        }
;

mul_op
    : '*'   { $$ = MUL_t; }
    | '/'   { $$ = DIV_t; }
    | '%'   { $$ = MOD_t; }
;

prefix_expr
    : postfix_expr
    | INC prefix_expr
    | DEC prefix_expr
;

postfix_expr
    : primary_expr
    | postfix_expr INC
    | postfix_expr DEC
;

primary_expr
    : ID
        {
            if (!(symbol_cur=lookup_symbol($1.id))) { /* doesn't defined before */
                printf("[ERROR] undeclaration variable ‘%s’ at line %d\n", $1.id\
                        , yylineno+1);   /* haven't match token **NEWLINE** yet */
                numErr++;
            }
            else {      /* normal */
                if (symbol_cur->type == INT_t) {
                    fprintf(file, "\tiload %d\n", symbol_cur->index);
                    fprintf(file, "\ti2f\n");   /* cast to float */
                    $$.type = STRONG_INT_t;     /* mark:must cast it back to int */
                }
                else if (symbol_cur->type == FLOAT_t) {
                    fprintf(file, "\tfload %d\n", symbol_cur->index);
                    $$.type = FLOAT_t;
                }
            }
        }
    | constant
    | '(' expr ')'
;

constant
    : I_CONST   { fprintf(file, "\tldc %f\n", $1.f_val); $$.type=INT_t; }
    | F_CONST   { fprintf(file, "\tldc %f\n", $1.f_val); $$.type=FLOAT_t;}
;
 
print_func
    : print_func_op '(' equality_expr ')' NEWLINE
        {
            if ($3.type==INT_t || $3.type==STRONG_INT_t)
                fprintf(file, "\tf2i\n");

            fprintf(file, "\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n");
	        fprintf(file, "\tswap\n");
	        fprintf(file, "\tinvokevirtual java/io/PrintStream/%s(%c)V\n",\
                    $1? "print":"println", ($3.type==INT_t || $3.type==STRONG_INT_t)? 'I':'F');  
        }
    | print_func_op '(' QUOTA STRING QUOTA ')' NEWLINE  
        {
            fprintf(file, "\tldc \"%s\"\n", $4.string);
            fprintf(file, "\tgetstatic java/lang/System/out Ljava/io/PrintStream;\n");
	        fprintf(file, "\tswap\n");
	        fprintf(file, "\tinvokevirtual java/io/PrintStream/%s(Ljava/lang/String;)V\n",\
                    $1? "print":"println");     /* print or println*/
        }
;

print_func_op
    : PRINT     { $$=1; }
    | PRINTLN   { $$=0; }
;

%%

/* C code section */

void yyerror(const char* error) {

}

void createJasmin(int cmd) {
    switch (cmd) {
        case start:
            fprintf(file, ".class public main\n");
            fprintf(file, ".super java/lang/Object\n");
            fprintf(file, ".method public static main([Ljava/lang/String;)V\n");
            fprintf(file, ".limit stack 10\n");
            fprintf(file, ".limit locals 10\n");
            break;
        case end:
            fprintf(file,"\treturn\n.end method");
            fclose(file);
            break;
        case err:
            fclose(file);
            remove("Computer.j");
            printf("**************Didn't generate jasmin code**************\n");
            break;
    }
}

SYMBOL* lookup_symbol(char *id) {
    SYMBOL *current = symbol_head;
    while (current) {
        if (!strcmp(current->id,id))
            return current;
        current = current->next;
    }
    return NULL;
}

void create_symbol() {

}

void insert_symbol(int type, char *id, double insert_value) {
    
    SYMBOL *tail, *insert = (SYMBOL*)malloc(sizeof (SYMBOL));
    if (!insert) {
        printf("[insert_symbol]malloc failed\n");
        createJasmin(err);
    }

    if (symbol_tail) {
        insert->index = symbol_tail->index + 1;
        symbol_tail->next = insert;
    }
    else {
        insert->index = 0;
        symbol_head = insert;
    }
    symbol_tail = insert;

    /* symbol table */
    insert->type = type;
    insert->value = insert_value;
    strcpy(insert->id, id);

    /* .j file */
    if (insert->type == INT_t) 
        fprintf(file, "\tf2i\n\tistore %d\n", insert->index);
    else if (insert->type == FLOAT_t) 
        fprintf(file, "\tfstore %d\n", insert->index);

}

void dump_symbol() {
    SYMBOL * current;
    printf("index\tID\ttype\tdata\n");

	for (current=symbol_head; current; current=current->next) {
		printf("%d\t%s\t",current->index, current->id);
		switch (current->type) {
		case INT_t:
			printf("int\t%d\n", (int)current->value);
			break;
		case FLOAT_t:
            printf("float32\t%f\n", current->value);	
			break;
		
		}
	}

}

int main(int argc, char** argv)
{
    file = fopen("Computer.j","w");
    createJasmin(start);
    
    numErr = 0;
    yylineno = 0;
    yyparse();
    
    if (!numErr)    /* parsing valid */ 
        createJasmin(end);
    else            /* contain error, don't generate .j file */ 
        createJasmin(err);

    return 0;
}
