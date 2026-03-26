%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Declaraciones de funciones externas de Flex */
void yyerror();

extern int yylex();
extern int yylineno;
extern char* yytext;
extern int yyin;
/* Para el control de errores */


void yyerror(const char *msg);
extern int errores = 0;

//Listas de elementos
    Lista l;
    Tipo t;
    int idx_str = 1;
    void declarar_id();
    int declarar_str(char *str);
    void verificar_id(char *id, bool es_var);
    void imprimir_ls();

%}

//parte de ensamblador
%code requires {
    #include "listaCodigo.h"
}

%union{
    char *cadena;
    ListaC codigo;
}
/*
%union {
   string cadena;
}
*/

%token <cadena> ID      "id"
%token <cadena> NUM     "num"
%token <cadena> STR     "string"

/* Palabras reservadas */
%token VOID              "void"
%token VAR               "var"
%token CONST             "const"
%token IF                 "if"
%token ELSE               "else"
%token WHILE              "while"
%token PRINT              "print"
%token READ               "read"
%token INT                "int"
%token SUMA "+"
%token REST "-"
%token IGU "="
%token PYC ";"
%token COMA ","
%token PAI "("
%token PAD ")"
%token LLI "{"
%token LLD "}"
%token MUL "*"
%token DIV "/"

%left '+' '-'     
%left '*' '/'      
%precedence UMINUS 

%precedence NOELSE
%precedence ELSE

%define parse.error verbose 

%define parse.trace

%type <codigo> expresion

%%



program:    {l = creaLS(); } VOID ID "(" ")" "{" body "}"       { 
                if(errores == 0) {
                    imprimir_ls();
                }
                liberaLS(l);
            }   
    ;

body:
    | body declaration                { }
    | body statement                  { }
    | %empty                          { }
    ;

declaration:
    | VAR           { t = VARIABLE; } tipo id_list ";"         { }
    | CONST         { t = CONSTANTE; } tipo id_list ";"          { }
    ;

tipo:
      INT                             { }
    ;

id_list:
      id_decl                         { }
    | id_list COMA id_decl            { }
    ;

id_decl:
      ID                { declarar_id($1,t); }
    | ID IGU expresion  { declarar_id($1,t); }
    ;

statement:  ID "=" expresion ";"            { }
    |       "{" statement_list "}"          { }
    |       IF "(" expresion ")" ELSE statement { }
    |       IF "(" expresion ")"                { }
    |       WHILE "(" expresion ")" statement   { }
    |       PRINT "(" print_list ")" ";"        { }
    |       READ "(" read_list ")" ";"             { }
    ;

statement_list: statement_list statement { }
    |           %empty  { }
    ;
print_list: print_item                            { }
    |       print_list"," print_item              { }
    ;


print_item: expresion                             { }
    ;

read_list:  ID                                    { }
    |       read_list"," ID                       { }
    ;


expresion:  expresion "+" expresion                 { }
    |       expresion "-" expresion                 { }
    |       expresion "*" expresion                 { }
    |       expresion "/" expresion                 { }
    |       "-" expresion                           { }
    |       "(" expresion ")"                       { }
    |       ID                                      { }
    |       NUM                                     { }

%%


void yyerror(const char *msg) {
    fprintf(stderr, "Error sintáctico en línea %d: %s\n", yylineno, msg);
    errores++;
}

void declarar_id( char *id, Tipo t){
    PosicionLista p = buscaLS(l,id);
    if(p != finalLS(l)) {
        errores++;
        printf("Errores en linea %d: %s redeclarador \n", yylineno, id);
    }
    else{

        Simbolo s;
        s.nombre = id;
        s.tipo = t;
        s.valor = 0;
        insertaLS(l,finalLS(l),s);

    }
}

 void imprimir_ls(){
    PosicionLista p = inicioLS(l);
    while (p != finalLS(l)){
        Simbolo aux = recuperaLS(l,p);
        if (aux.tipo == VARIABLE || aux.tipo == CONSTANTE) {
            printf("_%s: .word %d\n", aux.nombre, aux.valor);
        }
            p = siguienteLS(l,p);
        }
}
