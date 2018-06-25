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

/* jump label */
int numLabel, numExit;

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
%token IF ELSE ELSEIF FOR
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
        {
            /* empty stat, to add EXIT label */
            fprintf(file, "EXIT_%d\:\n", numExit++);
        }
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
            else {
                fprintf(file, "\tfconst_0\n");   
                insert_symbol($3.type, $2.id, 0);
            }
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
    : if_stat stat end_condition mul_elseif_stat mul_else_stat
;

end_condition
    :
    {
        fprintf(file, "\tgoto EXIT_%d\n", numExit);
        fprintf(file, "LABEL_%d\:\n", numLabel);
    }
;

if_stat
    : IF '(' expr ')' 
        {
            switch ((int)$3.f_val) {
                case EQ_t :
                    fprintf(file, "\tifne LABEL_%d\n", ++numLabel);
                    break;
                case NE_t :
                    fprintf(file, "\tifeq LABEL_%d\n", ++numLabel);
                    break;
                case LT_t :
                    fprintf(file, "\tifge LABEL_%d\n", ++numLabel);
                    break;
                case LE_t :
                    fprintf(file, "\tifgt LABEL_%d\n", ++numLabel);
                    break;
                case GT_t :
                    fprintf(file, "\tifle LABEL_%d\n", ++numLabel);
                    break;
                case GE_t :
                    fprintf(file, "\tiflt LABEL_%d\n", ++numLabel);
                    break;
            }
        }
;

mul_elseif_stat
    : mul_elseif_stat elseif_stat stat end_condition
    |
;

elseif_stat
    :  ELSEIF '(' expr ')' 
        {
            
            switch ((int)$3.f_val) {
                case EQ_t :
                    fprintf(file, "\tifne LABEL_%d\n", ++numLabel);
                    break;
                case NE_t :
                    fprintf(file, "\tifeq LABEL_%d\n", ++numLabel);
                    break;
                case LT_t :
                    fprintf(file, "\tifge LABEL_%d\n", ++numLabel);
                    break;
                case LE_t :
                    fprintf(file, "\tifgt LABEL_%d\n", ++numLabel);
                    break;
                case GT_t :
                    fprintf(file, "\tifle LABEL_%d\n", ++numLabel);
                    break;
                case GE_t :
                    fprintf(file, "\tiflt LABEL_%d\n", ++numLabel);
                    break;
            }
        }
    |
;

mul_else_stat
    : else_stat stat
    |
;

else_stat
    : ELSE
;

expression_stat
    : expr NEWLINE
    | NEWLINE
;

expr
    : equality_expr
    | ID '=' expr
        {
            if ((symbol_cur = lookup_symbol($1.id))) {
                if (symbol_cur->type == INT_t) {
                    fprintf(file, "\tf2i\n");
                    fprintf(file, "\tistore %d\n", symbol_cur->index);
                }
                else
                    fprintf(file, "\tfstore %d\n", symbol_cur->index);
            }            
        }
    | prefix_expr assignment_op expr
        {
            int castNum;
            symbol_cur = lookup_symbol($1.id);

            /* if dest. variable is int, cast both expr and var. */
            if ( $1.type == INT_t || $1.type == STRONG_INT_t) 
                castNum = (int)$3.f_val;
            else {
                fprintf(file, "\tfload %d\n", symbol_cur->index);
                castNum = $3.f_val;
            }

            /* operation */
            switch ($2) {
                case ADD_t :    /* += */
                    symbol_cur->value+=castNum;
                    fprintf(file, "\tfadd\n");
                    fprintf(file, "%s", ($1.type != FLOAT_t)?"\tf2i\n":"");
                    fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
                    break;
                case SUB_t :    /* -= */
                    symbol_cur->value-=castNum;
                    fprintf(file, "\tfsub\n");
                    fprintf(file, "%s", ($1.type != FLOAT_t)?"\tf2i\n":"");
                    fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
                    break;
                case MUL_t :    /* *= */
                    symbol_cur->value*=castNum;
                    fprintf(file, "\tfmul\n");
                    fprintf(file, "%s", ($1.type != FLOAT_t)?"\tf2i\n":"");
                    fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
                    break;
                case DIV_t :    /* /= */
                    symbol_cur->value/=castNum;
                    fprintf(file, "\tfdiv\n");
                    fprintf(file, "%s", ($1.type != FLOAT_t)?"\tf2i\n":"");
                    fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
                    break;
                case MOD_t :    /* %= */
                    /* check if both operands are int */
                    if ($1.type==FLOAT_t||$3.type==FLOAT_t) {
                        printf("[ERROR] invalid operands (double) in MOD at line %d\n", yylineno+1);
                        numErr++;
                    }
                    else {
                        /* cast to int before mod */
                        /* TODO refresh symbol table */ 
                        fprintf(file, "\tf2i\n");
                        fprintf(file, "\tistore %d\n", STACK_MAX-1);
                        fprintf(file, "\tf2i\n");
                        fprintf(file, "\tiload %d\n", STACK_MAX-1);
                        fprintf(file, "\tirem\n");
                        fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
                    }
                    break;
                default :
                    printf("[expr assignment] parsing error\n");
            }

        }
;

assignment_op
    : ADDASGN   { $$ = ADD_t; }
    | SUBASGN   { $$ = SUB_t; }
    | MULASGN   { $$ = MUL_t; }
    | DIVASGN   { $$ = DIV_t; }
    | MODASGN   { $$ = MOD_t; }
;

equality_expr
    : relational_expr
    | equality_expr equality_op relational_expr
        {
            fprintf(file, "\tfcmpl\n");
            $$.f_val = $2;
        }
;

equality_op
    : EQ    { $$ = EQ_t; }
    | NE    { $$ = NE_t; }
;

relational_expr
    : additive_expr
    | relational_expr relational_op additive_expr
        {
            fprintf(file, "\tfcmpl\n");
            $$.f_val = $2;
        }
;

relational_op
    : '<'   { $$ = LT_t; }
    | '>'   { $$ = GT_t; }
    | LTE   { $$ = LE_t; }
    | MTE   { $$ = GE_t; }
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
                    printf("[ERROR] invalid operands (double) in MOD at line %d\n", yylineno+1);
                    numErr++;
                }
                else {
                    /* cast to int before mod */
                    fprintf(file, "\tf2i\n");
                    fprintf(file, "\tistore %d\n", STACK_MAX-1);
                    fprintf(file, "\tf2i\n");
                    fprintf(file, "\tiload %d\n", STACK_MAX-1);
                    fprintf(file, "\tirem\n");
                    fprintf(file, "\ti2f\n");
                }
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
    | INC prefix_expr   { $$.f_val = $2.f_val+1; }
    | DEC prefix_expr   { $$.f_val = $2.f_val-1; }
;

postfix_expr
    : primary_expr
    | postfix_expr INC
        {
            symbol_cur = lookup_symbol($1.id);
            fprintf(file, "\tldc 1.0\n");
            fprintf(file, "\tfadd\n");
            fprintf(file, "%s", ($1.type != FLOAT_t)?"\tf2i\n":"");
            fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
            symbol_cur->value++;
        }
    | postfix_expr DEC
        {
            symbol_cur = lookup_symbol($1.id);
            fprintf(file, "\tldc 1.0\n");
            fprintf(file, "\tfsub\n");
            fprintf(file, "%s", ($1.type != FLOAT_t)?"\tf2i\n":"");
            fprintf(file, "\t%cstore %d\n", ($1.type != FLOAT_t)?'i':'f', symbol_cur->index);
            symbol_cur->value--;
        }
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
    | '(' expr ')'  { $$ = $2;}
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
            fprintf(file, ".limit stack %d\n", STACK_MAX);
            fprintf(file, ".limit locals %d\n", STACK_MAX);
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
    numLabel = 0;
    numExit = 0;

    yylineno = 0;
    yyparse();
    
    if (!numErr)    /* parsing valid */ 
        createJasmin(end);
    else            /* contain error, don't generate .j file */ 
        createJasmin(err);

    return 0;
}
