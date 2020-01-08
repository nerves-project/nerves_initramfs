%{
#include <stdio.h>
#include <strings.h>
#include "script.h"

extern int yylex(void);
extern int yyerror(const char *s);

%}

// Symbols.
%union
{
    bool boolean;
    struct term *term;
};

%token <boolean> BOOLEAN

%token <term> IDENTIFIER
%token <term> NUMBER
%token <term> STRING

%token AND OR NOT NEQ LT LTE EQ GTE GT ARROW

%type <boolean> BooleanExpression Comparison
%type <term> term Parameters FunctionCall Action Actions ActionBlock Assignment

%left '-' '+'
%nonassoc UMINUS

%%

Statements:
  /* empty */
  | Statements Statement
  ;

Statement:
  Rule
  | Action { run_functions($1); }
  ;

Rule:
  BooleanExpression ARROW ActionBlock { if ($1) run_functions($3); }
  ;

ActionBlock:
  Action
  | '{' Actions '}' { $$ = $2; }
  ;

Actions:
  /* Empty */      { $$ = NULL; }
  | Actions Action { $2->next = $1; $$ = $2; }
  ;

Action:
  FunctionCall
  | Assignment
  ;

Assignment:
  IDENTIFIER '=' term { $1->next = $3; $$ = term_new_fun("=", $1); }
  ;

BooleanExpression:
  term                                    { $$ = term_to_boolean($1); }
  | '(' BooleanExpression ')'               { $$ = $2; }
  | Comparison
  | NOT BooleanExpression                   { $$ = !$2; }
  | BooleanExpression AND BooleanExpression { $$ = $1 && $3; }
  | BooleanExpression OR BooleanExpression  { $$ = $1 || $3; }
  ;

Comparison:
  term NEQ term               { $$ = (term_compare($1, $3) != 0); }
  | term LT term              { $$ = (term_compare($1, $3) < 0); }
  | term LTE term             { $$ = (term_compare($1, $3) <= 0); }
  | term EQ term              { $$ = (term_compare($1, $3) == 0); }
  | term GTE term             { $$ = (term_compare($1, $3) >= 0); }
  | term GT term              { $$ = (term_compare($1, $3) > 0); }
  ;

FunctionCall:
  IDENTIFIER '(' Parameters ')' { struct term *rc = term_new_fun($1->identifier, term_reverse($3));
                                  if (!rc) {
                                    yyerror("unknown function");
                                    YYERROR;
                                  }
                                  $$ = rc;
                                  }
  ;

Parameters:
  /* Empty */             { $$ = NULL; }
  | Parameters ',' term { $3->next = $1; $$ = $3; }
  | term
  ;

term:
  term '+' term { $1->next = $3; $$ = term_new_fun("+", $1); }
  | term '-' term { $1->next = $3; $$ = term_new_fun("-", $1); }
  | '-' term %prec UMINUS { $$ = term_new_number(-term_to_number($2)); }
  | '(' term ')' { $$ = $2; }
  | IDENTIFIER
  | STRING
  | NUMBER
  | BOOLEAN { $$ = term_new_boolean($1); }
  | FunctionCall
  ;

%%
