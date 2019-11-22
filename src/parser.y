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
  term NEQ term               { $$ = term_to_boolean($1) != term_to_boolean($3); }
  | term LT term              { $$ = term_to_boolean($1) <  term_to_boolean($3); }
  | term LTE term             { $$ = term_to_boolean($1) <= term_to_boolean($3); }
  | term EQ term              { $$ = term_to_boolean($1) == term_to_boolean($3); }
  | term GTE term             { $$ = term_to_boolean($1) >= term_to_boolean($3); }
  | term GT term              { $$ = term_to_boolean($1) >  term_to_boolean($3); }
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
  | IDENTIFIER
  | STRING
  | NUMBER
  | BOOLEAN { $$ = term_new_boolean($1); }
  ;

%%
