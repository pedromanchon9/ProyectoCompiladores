%{
#define _GNU_SOURCE
// para asprintf
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "listaSimbolos.h"
#include  "listaCodigo.h"
/* Declaraciones de funciones externas de Flex */
void yyerror();
extern int yylex();
extern int yylineno;
extern char* yytext;
extern int yyin;
extern int errores;
/* Para el control de errores */


void yyerror(const char *msg);


//Listas de elementos
    Lista l;
    Tipo t;
    int idx_str = 1;
    void declarar_id();
    int declarar_str(char *str);
    void verificar_id(char *id, bool es_var);
    void imprimir_ls();
    ListaC expresion_num(char *num);
    ListaC expresion_id(char *id);
    ListaC expresion_bin(ListaC expr1, ListaC expr2, char *op);
    char registros[10];
    char *obtener_reg();
    void inicializar_reg();
    void liberar_reg(char *reg);

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
      %empty                          { }
    | body declaration                { }
    | body statement                  { }
    ;

declaration:
      VAR           { t = VARIABLE; } tipo id_list ";"         { }
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

statement:  ID "=" expresion ";"            { verificar_id($1,true);
                                              imprimir_lc($3);

}
    |       "{" statement_list "}"          { }
    |       IF "(" expresion ")" ELSE statement { }
    |       IF "(" expresion ")" statement %prec NOELSE { }
    |       WHILE "(" expresion ")" statement   { }
    |       PRINT "(" print_list ")" ";"        { }
    |       READ "(" read_list ")" ";"             { }
    ;

statement_list: statement_list statement { }
    |           %empty  { }
    ;
print_list: print_item                            { }
    |       print_list COMA print_item              { }
    ;


print_item: expresion                             { }
    ;

read_list:  ID                                    { }
    |       read_list COMA ID                       { }
    ;


expresion:  expresion "+" expresion                 { $$ = expresion_bin($1,$3,"add"); }
    |       expresion "-" expresion                 { $$ = expresion_bin($1,$3,"sub");}
    |       expresion "*" expresion                 { $$ = expresion_bin($1,$3,"mul");}
    |       expresion "/" expresion                 { $$ = expresion_bin($1,$3,"div");}
    |       "-" expresion %prec UMINUS              { }
    |       "(" expresion ")"                       { }
    |       ID                                      { verificar_id($1, false); }
    |       NUM                                     { $$ = expresion_num($1);  }

%%

void inicializar_reg(){
    memset(registros,0,sizeof(char)*10);
}

char *obtener_reg(){
    for(int i = 0; i < 10; i++){
        if (registros[i] == 0){
            // $ti
            char *reg;
            asprintf(&reg, "$t%d", i);
            registros[i] = 1;
            return reg;
        }
    }
    printf("Error fatal; regustros agotados!\n");
    exit(1);
}
void liberar_reg(char *reg){
    //reg = %ti
    assert(reg[0]=='$');
    assert(reg[1]=='t');
    int i = reg[2] - '0';
    assert(i <= 9);
    assert(i >= 0);
    registros[i] = 0;
}

void imprimir_lc(ListaC codigo1){
    PosicionListaC p = inicioLC(codigo1);
    while(p != finalLC(codigo1)){
        Operacion oper = recuperaLC(codigo1,p);
        printf("%s", oper.op);
        if(oper.res) printf("%s", oper.res);
        if(oper.res) printf("%s", oper.arg1);
        if(oper.res) printf("%s", oper.arg2);
        printf("/n");
        p = siguienteLC(codigo1,p);
    }
}

ListaC expresion_num(char *num) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "li";
    o.res = obtener_reg();
    o.arg1 = num;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    guardaResLC(codigo, o.res);
    return codigo;
}


ListaC expresion_id(char *id) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "lw";
    o.res = obtener_reg();
    asprintf(&(o.arg1), "_%s", id);
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    guardaResLC(codigo, o.res);
    return codigo;
}

ListaC expresion_bin(ListaC expr1, ListaC expr2, char *op) {
    ListaC codigo = expr1;
    concatenaLC(codigo, expr2);
    Operacion o;
    o.op = op;
    o.res = o.arg1 = recuperaResLC(expr1);
    o.arg2 = recuperaResLC(expr2);
    insertaLC(codigo, finalLC(codigo), o);
    liberar_reg(o.arg2);
    liberaLC(expr2);
    return codigo;

}

void yyerror(const char *msg) {
    printf("Error sintáctico en línea %d: %s\n", yylineno, msg);
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
