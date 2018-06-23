/*	Definition section */
%{
#include "common.h" //Extern variables that communicate with lex

extern int yylineno;
extern int yylex();

typedef struct symbol {
    int index;
    char id[16];
    int type;
    double value;
    struct symbol *next;
} SYMBOL;

SYMBOL *symbol_head = NULL, *symbol_tail = NULL;

/* create jasmin file */
void createJasmin(int cmd);
FILE *file;

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
            insert_symbol($3.type, $2.id, $5.f_val);
        }
    | VAR ID type NEWLINE
        {
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
;

add_op
    : '+'
    | '-'
;

multiplicative_expr
    : prefix_expr
    | multiplicative_expr mul_op prefix_expr
;

mul_op
    : '*'
    | '/'
    | '%'
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
    | constant
    | '(' expr ')'
;

constant
    : I_CONST
    | F_CONST
;
 
print_func
    : print_func_op '(' equality_expr ')' NEWLINE
    | print_func_op '(' QUOTA STRING QUOTA ')' NEWLINE  
        {
            fprintf(file, "ldc \"%s\"\n", $4.string);
            fprintf(file, "getstatic java/lang/System/out Ljava/io/PrintStream;\n");
	        fprintf(file, "swap\n");
	        fprintf(file, "invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }
;

print_func_op
    : PRINT
    | PRINTLN
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
            fprintf(file,"return\n.end method");
            break;
        case err:
            break;
    }
}

SYMBOL* lookup_symbol(char *id) {

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

    insert->type = type;
    insert->value = insert_value;
    strcpy(insert->id, id);

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
    
    yylineno = 0;
    yyparse();

    createJasmin(end);
    fclose(file);

    return 0;
}