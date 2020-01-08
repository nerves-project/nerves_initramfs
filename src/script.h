#ifndef SCRIPT_H
#define SCRIPT_H

#include <stdbool.h>

typedef const struct term *(*fun_handler)(const struct term *);

struct function
{
    fun_handler fun;
    const struct term *parameters;
};

struct variable
{
    const char *name;
    const struct term *value;
};

struct term
{
    enum
    {
        term_identifier,
        term_string,
        term_number,
        term_boolean,
        term_fun,
        term_variable
    } kind;
    union {
        char *identifier;
        char *string;
        int number;
        bool boolean;
        struct function fun;
        struct variable var;
    };
    struct term *next;
};

struct function_info
{
    const char *name;
    int arity;
    fun_handler handler;
    const char *description;
};

fun_handler lookup_function(const char *name, int arity);
const struct function_info *function_info_by_fun(fun_handler fun);

const struct term *run_functions(const struct term *rv);

void term_gc_heap();
struct term *term_new_number(int value);
struct term *term_new_string(const char *value);
struct term *term_new_qstring(const char *value);
struct term *term_new_boolean(bool value);
struct term *term_new_identifier(const char *value);
struct term *term_new_fun(const char *name, struct term *parameters);
struct term *term_dupe(const struct term *rv);

struct term *term_reverse(struct term *rv);

int term_compare(const struct term *left, const struct term *right);
bool term_to_boolean(const struct term *rv);
int term_to_number(const struct term *rv);
const struct term *term_to_string(const struct term *rv);
const struct term *term_resolve(const struct term *rv);

const struct term *get_variable(const char *name);
void set_variable(const char *name, const struct term *value);
const char *get_variable_as_string(const char *name);
bool get_variable_as_boolean(const char *name);
int get_variable_as_number(const char *name);
void set_string_variable(const char *name, const char *value);
void set_boolean_variable(const char *name, bool value);
void set_number_variable(const char *name, int value);

void inspect(const struct term *rv);

int eval_string(char *input);
int eval_file(const char *path);

#endif
