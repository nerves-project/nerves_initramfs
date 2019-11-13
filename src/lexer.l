%{
#include "script.h"
#include "parser.tab.h"

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>

#undef YY_INPUT
#define YY_INPUT(buffer, result, max_size) (result = lexer_next(buffer, max_size))

static char *lexer_input = NULL;
static int lexer_input_length = 0;
static int lexer_input_index = 0;

int lexer_set_input(char *input)
{
    if (lexer_input)
        free(lexer_input);

    lexer_input = input;
    lexer_input_length = strlen(input);
    lexer_input_index = 0;
    return 0;
}

int lexer_set_file(const char *path)
{
    int fd = open(path, O_RDONLY);
    if (fd < 0)
        return -1;

    off_t len = lseek(fd, 0, SEEK_END);
    if (len < 0) {
        close(fd);
        return -1;
    }
    lseek(fd, 0, SEEK_SET);

    char *new_lexer_input = malloc(len);

    ssize_t amount_read = read(fd, new_lexer_input, len);
    close(fd);

    if (amount_read != len) {
        free(new_lexer_input);
        return -1;
    }

    if (lexer_input)
        free(lexer_input);

    lexer_input = new_lexer_input;
    lexer_input_length = len;
    lexer_input_index = 0;

    return 0;
}

static int lexer_next(char *buffer, int max_size)
{
    if (lexer_input == NULL)
        return 0;

    int n = lexer_input_index + max_size;
    if (n > lexer_input_length)
        n = lexer_input_length - lexer_input_index;

    memcpy(buffer, lexer_input + lexer_input_index, n);
    lexer_input_index += n;
    return n;
}
%}

ws              [ \t]+
nl              \n
comment         #.*
identifier      [_a-zA-Z0-9.]+
hex_number      0x[0-9a-fA-F]+
dec_number      [0-9]+
string          \"[^\"\n]*\"

%option noyywrap
%option nounput
%option noinput

%%

{ws}        ;
{comment}   ;

"true"         { yylval.boolean = true; return BOOLEAN; }
"false"        { yylval.boolean = false; return BOOLEAN; }
"{"             return '{';
"}"             return '}';
"("             return '(';
")"             return ')';
"&&"            return AND;
"||"            return OR;
"=="            return EQ;
"!="            return NEQ;
"<="            return LTE;
">="            return GTE;
">"             return GT;
"<"             return GT;
"!"             return NOT;
"="             return '=';
"->"            return ARROW;
";"             ;
"+"             return '+';
"-"             return '-';
","             return ',';

{string}        {   yylval.term = term_new_qstring(yytext);
                    return STRING;
                }

{hex_number}    {   yylval.term = term_new_number(strtoul(yytext, NULL, 16));
                    return NUMBER;
                }

{dec_number}    { yylval.term = term_new_number(strtoul(yytext, NULL, 10));
                    return NUMBER;
                }

{identifier}    {   yylval.term = term_new_identifier(yytext);
                    return IDENTIFIER;
                }

{nl}            { yylineno++; }

%%

