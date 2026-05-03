%{
#define _GNU_SOURCE
// para asprintf
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include "listaSimbolos.h"
#include "listaCodigo.h"
#include "func_semantico.h"
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
    Tipo t;

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
%token RETR               "return"
%token SUMA                "+"
%token REST                "-"
%token IGU                 "="
%token PYC                 ";"
%token COMA                ","
%token PAI                 "("
%token PAD                 ")"
%token LLI                 "{"
%token LLD                 "}"
%token MUL                 "*"
%token DIV                 "/"
%token DO                  "do"
//%token BREAK               "break"


%left "+" "-"     
%left "*" "/"      
%precedence UMINUS 

%precedence NOELSE
%precedence ELSE

%define parse.error verbose 

%define parse.trace

%type <codigo> expresion
%type <codigo> parametros_list                  //Esto debe estar para la funcion 
%type <codigo> parametros_decl                  // ""
%type <codigo> parametros_body                  // ""
%type <codigo> id_decl 
%type <codigo> id_list 
%type <codigo> declaration 
%type <codigo> statement
%type <codigo> functions
%type <codigo> function 
%type <codigo> body 
%type <codigo> statement_list 
%type <codigo> argumentos_list
%type <codigo> argumentos_body
%type <codigo> print_list
%type <codigo> print_item 
%type <codigo> read_list

%%


program:    {l = creaLS();
             inicializar_reg(); } functions        { 
             if(buscaLS(l, "main") == finalLS(l)) {          // comprobación que existe el nombre main en nuestra tabla de simbolos 
                printf("Error semantico debe existir un main \n "); 
                errores++;
             }

            if(errores == 0) {
                    imprimir_datos(l);      //esta lista imprime las listas de simbolos asociadas a las cadenas con el formato correspondiente 
                    printf("\n###################\n#Seccion de codigo\n.text\n.globl main\n");
                    printf(" j main\n\n");
                    imprimir_lc($2);        //esta lista alamacena las listas de codigo de cada una de las operaciones/instrucciones realizadas por la entrada

                    printf("\n# Fin del programa\n"); // imprime por pantalla el final del programa
                    imprimir_lc(fin_programa());

                }
                liberaLS(l);
            }   
    ;

functions:
    function { $$ = $1; }
    | functions function { $$ = concatenar_funciones($1, $2); }
    ;

function:
     tipo ID "(" {entrar_nivel($2); decl_param = 0;} parametros_body ")" { tipo_retorno = tipo_actual; ex_return = 0; }   "{" body "}" { 
                                                        if(tipo_retorno == 1 && ex_return == 0){
                                                            errores++;
                                                            printf("Error en la linea %d , la fución %s de tipo int no tiene un return, ", yylineno, func_actual);
                                                        }
                                                        ListaC body = $5; 
                                                        concatenaLC(body,$9);
                                                        $$ = declarar_funcion($2, body); 
                                                        salir_nivel();
                                                        }
    ;

parametros_decl:
      INT ID                          { $$ = declarar_parametro($2, VARIABLE); }
    | CONST INT ID                    { $$ = declarar_parametro($3, CONSTANTE); }
;

parametros_list:
      parametros_decl                               { $$ = $1; }
    | parametros_list "," parametros_decl           { $$ = $1; concatenaLC($$, $3); liberaLC($3);}

;
parametros_body:
    %empty                               { $$ = creaLC(); }
    |  parametros_list                   { $$ = $1; }
;

body:
      %empty                          { $$ = creaLC(); }
    | body declaration                { $$ = $1; concatenaLC($$, $2); liberaLC($2); }
    | body statement                  { $$ = $1; concatenaLC($$, $2); liberaLC($2); }
    ;

declaration:
      VAR           { t = VARIABLE; } tipo id_list ";"         { $$ = $4; }
    | CONST         { t = CONSTANTE; } tipo id_list ";"        { $$ = $4; }
    ;

tipo:
      INT                             { tipo_actual = 1; }
    | VOID                            { tipo_actual = 0; }
    ;

id_list:
      id_decl                         { $$ = $1; }
    | id_list COMA id_decl            { $$ = $1; concatenaLC($$, $3); liberaLC($3);}
    ;

id_decl:
      ID                { declarar_id($1,t); $$ = creaLC(); }
    | ID IGU expresion  { declarar_id($1,t); $$ = guardar_reg($1, $3); }
    ;

statement:
      ID "=" expresion ";"                         {  verificar_asignacion($1); $$ = guardar_reg($1, $3); }
    | "{" statement_list "}"                         {  $$ = $2; } 
    | IF "(" expresion ")" statement %prec NOELSE    {  $$ = statment_if($3, $5); }
    | IF "(" expresion ")" statement ELSE statement  {  $$ = statment_if_else($3, $5, $7); }
    | WHILE "(" expresion ")" statement              {  $$ = statment_while($3, $5); }
    | DO "{" statement "}" WHILE "(" expresion")"    {  $$ = statment_do_while($7,$3);}
    | PRINT "(" print_list ")" ";"                   {  $$ = $3; }
    | READ "(" read_list ")" ";"                     {  $$ = $3; }
    | RETR ";"                                       {  $$ = expresion_return(NULL); }
    | RETR expresion ";"                             {  $$ = expresion_return($2); }
    
    ;

statement_list: 
      %empty                                { $$ = creaLC(); }
    | statement_list statement              { $$ = $1; concatenaLC($$, $2); liberaLC($2); }
    ;

print_list: 
      print_item                            { $$ = $1; }
    | print_list COMA print_item            { $$ = $1; concatenaLC($$, $3); liberaLC($3); }
    ;

print_item: 
      expresion                             { $$ = generar_print_expresion($1);}
    | STR                                   {
                                                int id = generar_str($1);
                                                $$ = generar_print_str(id);
                                            }
    ;

read_list:  
      ID                                    { $$ = generar_read_id($1); }
    | read_list COMA ID                     { 
                                                $$ = $1;
                                                concatenaLC($$, generar_read_id($3)); 
                                            }
    ;
argumentos_body:
     %empty                                 { $$ = creaLC(); }
    | argumentos_list                       { $$ = $1; }
;
argumentos_list:
    expresion                               { $$ = pasar_argumento($1);}
    | argumentos_list "," expresion         { $$ = $1; concatenaLC($$, pasar_argumento($3)); }
;


expresion:  expresion "+" expresion                 { $$ = expresion_bin($1,$3,"add"); }   
    |       expresion "-" expresion                 { $$ = expresion_bin($1,$3,"sub"); }
    |       expresion "*" expresion                 { $$ = expresion_bin($1,$3,"mul"); }
    |       expresion "/" expresion                 { $$ = expresion_bin($1,$3,"div"); }
    |       "-" expresion %prec UMINUS              { $$ = expresion_neg($2); }
    |       "(" expresion ")"                       { $$ = $2; }
    |       ID                                      {
                                                        verificar_id($1); 
                                                        $$ = expresion_id($1); 
                                                    } 
    |       ID "(" { cont_arg = 0; } argumentos_body ")"       { $$ = expresion_llamada_func($1, $4);}
    |       NUM                                                { $$ = expresion_num(obtener_reg(),$1);  }

%%

void yyerror(const char *msg) {
    printf("Error sintáctico en línea %d: %s\n", yylineno, msg);
    errores++;
}


