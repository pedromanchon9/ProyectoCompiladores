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
    char *nueva_etiqueta();
    ListaC generar_etiqueta(char *etiqueta);
    void declarar_id();
    int generar_str(char *str);
    void verificar_id(char *id, bool es_var);
    ListaC generar_llam_sys();
    ListaC expresion_num(char *reg_des, char *valor);
    ListaC expresion_etiq(char* reg_des, char* etiqueta);
    ListaC expresion_move(char* reg_origen, char* reg_destino);
   // void imprimir_ls();
    void imprimir_lc(ListaC codigo1);
    ListaC generar_print_str(int id);
    ListaC generar_print_expresion(ListaC expr);
    void imprimir_datos(Lista lista);
    ListaC guardar_reg(char *reg, ListaC expr);
    ListaC generar_salto(char *etiqueta);
    ListaC generar_jal();
    ListaC generar_jr();
    ListaC generar_bz(ListaC expr, char *etiqueta , char *nombre);    
    ListaC expresion_id(char *id);
    ListaC generar_read_id(char *id);
    ListaC expresion_bin(ListaC expr1, ListaC expr2, char *op);
    ListaC expresion_neg(ListaC expr);
    ListaC fin_programa();
    char registros[10];
    char *obtener_reg();
    void inicializar_reg();
    void liberar_reg(char *reg);

    //Nuevas funcones 
    void asignar_reg(char *reg, long valor);
    void recuperar_reg(char *reg);
 

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


%left "+" "-"     
%left "*" "/"      
%precedence UMINUS 

%precedence NOELSE
%precedence ELSE

%define parse.error verbose 

%define parse.trace

%type <codigo> expresion
%type <codigo> id_decl 
%type <codigo> id_list 
%type <codigo> declaration 
%type <codigo> statement 
%type <codigo> body 
%type <codigo> statement_list 
%type <codigo> print_list
%type <codigo> print_item 
%type <codigo> read_list

%%



program:    {l = creaLS();
             inicializar_reg(); } VOID ID "(" ")" "{" body "}"        { 
             if(strcmp($3, "main") != 0) {          // comprobación de que el parametro 3 de nuestra función (l = crearLS ... ) + void) son 1 y 2 por tanto el siguiente es ID siendo dolar 3
                printf("Error semantico debe existir un main \n "); 
                errores++;
             }

            if(errores == 0) {
                    imprimir_datos(l);      //esta lista imprime las listas de simbolos asociadas a las cadenas con el formato correspondiente 
                    printf("\n###################\n#Seccion de codigo\n.text\n.globl main\nmain:\n");
                        
                    imprimir_lc($7);        //esta lista alamacena las listas de codigo de cada una de las operaciones/instrucciones realizadas por la entrada

                    printf("\n# Fin del programa\n"); // imprime por pantalla el final del programa
                    imprimir_lc(fin_programa());

                }
                liberaLS(l);
            }   
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
      INT                             { }
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
       ID "=" expresion ";"                          { verificar_id($1, true); $$ = guardar_reg($1, $3); }
    | "{" statement_list "}"                         { $$ = $2; } 
    | IF "(" expresion ")" statement %prec NOELSE    { char *etiqueta_fin = nueva_etiqueta();
                                                        
                                                        $$ = $3;
                                                        generar_bz($3, etiqueta_fin,"bnez");
                                                        
                                                        concatenaLC($$, $5);
                                                        liberaLC($5);
                                                        concatenaLC($$, generar_etiqueta(etiqueta_fin));
                                                        }

    | IF "(" expresion ")" statement ELSE statement  { char *etiqueta_else = nueva_etiqueta();
                                                       char *etiqueta_fin = nueva_etiqueta();
                                                       
                                                       $$ = $3;
                                                       generar_bz($$, etiqueta_else,"beqz");

                                                       concatenaLC($$, $5); //codigo del if
                                                       liberaLC($5);
                                                        //salto inc
                                                       concatenaLC($$,generar_salto(etiqueta_fin));  
                                                        //marc comienzo els
                                                       concatenaLC($$,generar_etiqueta(etiqueta_else));
                                                        //codigo els
                                                       concatenaLC($$, $7);

                                                       concatenaLC($$, generar_etiqueta(etiqueta_fin));
                                                    }

    | WHILE "(" expresion ")" statement              { 
                                                       char *etiqueta_inicio = nueva_etiqueta();
                                                       char *etiqueta_fin = nueva_etiqueta();
                                                       
                                                       $$ = $3;
                                                       $$ = generar_etiqueta(etiqueta_inicio);
                                                       generar_bz($3, etiqueta_fin,"beqz");
                                                       concatenaLC($$, $5);
                                                       liberaLC($5);
                                                       concatenaLC($$, generar_salto(etiqueta_inicio));
                                                       concatenaLC($$, generar_etiqueta(etiqueta_fin));
                                                       }
    | PRINT "(" print_list ")" ";"                   { $$ = $3; }
    | READ "(" read_list ")" ";"                     { $$ = $3; }
    | RETR ";"                                       { $$ = generar_jr("$ra");}
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


expresion:  expresion "+" expresion                 { $$ = expresion_bin($1,$3,"add"); }   
    |       expresion "-" expresion                 { $$ = expresion_bin($1,$3,"sub"); }
    |       expresion "*" expresion                 { $$ = expresion_bin($1,$3,"mul"); }
    |       expresion "/" expresion                 { $$ = expresion_bin($1,$3,"div"); }
    |       "-" expresion %prec UMINUS              { $$ = expresion_neg($2); }
    |       "(" expresion ")"                       { $$ = $2; }
    |       ID                                      {
                                                        verificar_id($1, false); 
                                                        $$ = expresion_id($1); 
                                                    } 
    |       NUM                                     { $$ = expresion_num(obtener_reg(),$1);  }

%%

int id_label = 1;
int cont_str = 1;

char *nueva_etiqueta() {
    char *nom;
    asprintf(&nom, "$l%d", id_label++); // Cambiado de "label%d" a "$l%d"
    return nom;
}

ListaC generar_etiqueta(char *etiqueta) {
    ListaC codigo = creaLC();
    Operacion o;
    
    char *marca;
    asprintf(&marca, "%s:", etiqueta);
    
    o.op = marca;     
    o.res = NULL;
    o.arg1 = NULL;
    o.arg2 = NULL;
    
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
}

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

int generar_str(char *str){
    Simbolo s;
    s.nombre = str;
    s.tipo = CADENA;
    s.valor = cont_str;
    insertaLS(l,finalLS(l), s);
    return cont_str++;
}

ListaC generar_salto(char *etiqueta) {
    ListaC codigo = creaLC();
    Operacion o;
    
    o.op = "b";          
    o.res = etiqueta;   
    o.arg1 = NULL;
    o.arg2 = NULL;
    
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
}

ListaC generar_jr(char *registro){
    ListaC codigo = creaLC();
    Operacion o;

    o.op = "jr";
    o.res = registro;
    o.arg1 = NULL;
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    return codigo;
}

ListaC generar_jal(char *etiqueta){
      ListaC codigo = creaLC();
    Operacion o;

    o.op = "jal";
    o.res = etiqueta;
    o.arg1 = NULL;
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    return codigo;

}


ListaC generar_bz(ListaC expr, char *etiqueta , char *nombre) {
    ListaC codigo = expr;
    Operacion o;
    o.op = nombre;
    o.res = recuperaResLC(expr);
    o.arg1 = strdup(etiqueta);
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    liberar_reg(o.res);

    return codigo;
}

void imprimir_lc(ListaC codigo1){
    PosicionListaC p = inicioLC(codigo1);
    while(p != finalLC(codigo1)){
        Operacion oper = recuperaLC(codigo1,p);
        if(oper.op[strlen(oper.op)-1] == ':'){
        printf("%s\n", oper.op);
        }else{
            printf("\t%s ", oper.op);
            int primero_impreso = 0;

            if(oper.res) {
                printf(" %s", oper.res);
                primero_impreso = 1;
            };

            if(oper.arg1) {
                if (primero_impreso) printf(","); // Añadimos coma si ya hay algo antes
                printf(" %s", oper.arg1);
                primero_impreso = 1;
            }

            if (oper.arg2) {
                if (primero_impreso) printf(","); // Añadimos coma si ya hay algo antes
                printf(" %s", oper.arg2);
            }
                printf("\n");
            }
        p = siguienteLC(codigo1,p);
    }
}

ListaC generar_llam_sys() {
    ListaC codigo = creaLC();
    Operacion o;
    
    o.op = "syscall";
    o.res =  NULL;
    o.arg1 = NULL;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
}

ListaC generar_print_expresion(ListaC expr) {
    ListaC codigo = expr;
    Operacion o;

    char* registro_resultado = strdup(recuperaResLC(expr)); 
    concatenaLC(codigo,expresion_move("$a0", registro_resultado));
    liberar_reg(registro_resultado);

    concatenaLC(codigo, expresion_num("$v0","1"));
    
    concatenaLC(codigo, generar_llam_sys());
    
    return codigo;
}

ListaC generar_print_str(int id) {
    ListaC codigo = creaLC();
    Operacion o;
    char *etiqueta;
    
    asprintf(&etiqueta, "$str%d", id); 

    // la $a0 etiqueta
    concatenaLC(codigo, expresion_etiq("$a0", etiqueta));

    // li $v0, 4
    concatenaLC(codigo, expresion_num("$v0", "4"));

    // syscall
    concatenaLC(codigo, generar_llam_sys());
    return codigo;
}

ListaC generar_read_id(char *id) {

    verificar_id(id,true);

    ListaC codigo = creaLC();
    Operacion o;

    concatenaLC(codigo, expresion_num("$v0", "5"));

    concatenaLC(codigo, generar_llam_sys());

    o.op = "sw";
    o.res = "$v0";
    asprintf(&o.arg1, "_%s", id);
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);

    return codigo;

}

ListaC guardar_reg(char *id, ListaC expr) {
    ListaC codigo = expr;
    Operacion o;
    o.op = "sw";
    o.res = NULL;
    o.arg1 = recuperaResLC(expr);                   //recuperamos reg
    asprintf(&(o.arg2), "_%s", id);                 //preparamos mem
    insertaLC(codigo, finalLC(codigo), o);          //guardamos el valor
    liberar_reg(o.arg1);                            //liberamos registro libre
    return codigo;
}

ListaC expresion_num(char *reg_des, char *valor) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "li";
    o.res = reg_des;
    o.arg1 = valor;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);

    if (reg_des[0] == '$' && reg_des[1] == 't') {
        guardaResLC(codigo, reg_des);
    }

    return codigo;
}

ListaC expresion_etiq(char *reg_des, char *etiqueta) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "la";
    o.res = reg_des;
    o.arg1 = etiqueta;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
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

ListaC expresion_move(char *reg_des, char *reg_origen) {     //move

    ListaC codigo = creaLC();
    Operacion o; 
    o.op = "move";
    o.res = reg_des;
    o.arg1 = reg_origen;
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    return codigo;
}

ListaC expresion_neg(ListaC expr) {
    ListaC codigo = expr;
    Operacion o;
    o.op = "neg";
    o.res = recuperaResLC(expr);   //reescribimos el registro
    o.arg1 = recuperaResLC(expr);  //el registro a negar
    o.arg2 = NULL;
    
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
} 

ListaC expresion_bin(ListaC expr1, ListaC expr2, char *op) {
    ListaC codigo = expr1;
    Operacion o;
    if (strcmp(op, "add") == 0 && longitudLC(expr2) == 1) {
        
        o.op = "addi";
        o.res = o.arg1 = recuperaResLC(expr1);
        o.arg2 = recuperaLC(expr2, inicioLC(expr2)).arg1; 
        
        insertaLC(codigo, finalLC(codigo), o);
        liberaLC(expr2);
        return codigo;
    }
    concatenaLC(codigo, expr2);
    o.op = op;
    o.res = o.arg1 = recuperaResLC(expr1);
    o.arg2 = recuperaResLC(expr2);
    insertaLC(codigo, finalLC(codigo), o);
    liberar_reg(o.arg2);
    liberaLC(expr2);
    return codigo;

}

ListaC fin_programa(){
    ListaC codigo = creaLC();
    Operacion o;
    concatenaLC(codigo, expresion_num("$v0","10"));
    concatenaLC(codigo, generar_llam_sys());

    return codigo;
};

void yyerror(const char *msg) {
    printf("Error sintáctico en línea %d: %s\n", yylineno, msg);
    errores++;
}

void verificar_id(char *id, bool es_var) {
    PosicionLista p = buscaLS(l, id);
    if(p == finalLS(l)) {
        printf("Errores en linea %d: variable '%s' no declarada\n" , yylineno, id);
        errores++;
    }
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

void imprimir_datos(Lista lista) {
    printf("##################\n# Seccion de datos\n.data\n\n");
    
    PosicionLista p = inicioLS(lista);
    while (p != finalLS(lista)) {
        Simbolo s = recuperaLS(lista, p);
        if (s.tipo == CADENA) {
            printf("$str%d:\n\t.asciiz %s\n", s.valor, s.nombre);
        }
        p = siguienteLS(lista, p);
    }
    
    p = inicioLS(lista);
    while (p != finalLS(lista)) {
        Simbolo s = recuperaLS(lista, p);
        if (s.tipo != CADENA) {
            printf("_%s:\n\t.word 0\n", s.nombre);
        }
        p = siguienteLS(lista, p);
    }
    printf("\n");
}

