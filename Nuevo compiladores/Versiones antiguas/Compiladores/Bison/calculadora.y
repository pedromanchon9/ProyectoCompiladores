%{
    #include <stdio.h>
    #include <stdlib.h>
    extern int yylineno;
    extern int yylex();
    extern int errores;
    void yyerror(const char *msg); //bison dejara que hagas lo que quieras con los mensajes de error
    //Registros
    long registros[10];
    void asigna_reg(char *reg, long valor);
    long recupera_reg(char *reg);
    void imprimir_reg();
%}

/* Tipos de datos de los símbolos de la gramática*/

%union {
  long num;
  char *reg;
}


%token MAS "+"
%token RES "-"
%token POR "*"
%token DIV "/"
%token <num> NUM "number"
%token PAI "("
%token PAD ")"
%token PYC ";"
%token IGU "="
%token <reg> REG "register"

/*Tipos para no terminales */
%type <num> e

%define parse.error verbose //genera más información sobre el error
%define parse.trace

/*Asociatividad de los op

%left "+": asociatividad izquierda 1+1+1 = (1+1)+1
%right "+": asociatividad derecha 1+1+1 = 1+(1+1)
%nonassoc "+": el op no es asociativo 1+1+1 error sintáctico

Asociatividad en la misma linea: igual precedencia
En líneas sucesivas, más precedencia

%precedence sólo define preferncia (sin asociatividad)

*/
%left "+" "-"
%left "*" "/"
%precendece SIGNO

%%

s : {yydebug=0;} l         { imprimir_reg();}
  ;

l : a ";"     { printf("l->a ;"); }
  | l a ";"   { printf("l->l a ;\n"); }
  | error ";" { }
  ;

a : REG "=" e  { printf("a->r = e [%ld];\n", $3);
                    asigna_reg($1,$3);
                   }
  ;



e : e "+" e   { printf("e->e+e\n"); $$ = $1 + $3; }
  | e "-" e   { printf("e->e-e\n");$$ = $1 - $3; }
  | e "*" e   { printf("e->e*e\n"); $$ = $1 * $3; }
  | e "/" e   { printf("e->e/e\n"); $$ = $1 / $3; }
  | NUM       { printf("e->num %ld\n", $1); $$ = $1; }
  | REG       { printf("e->reg\n");$$ = recupera_reg($1); }
  | "(" e ")" { printf("e->(e)\n"); $$ = $2; }
  | "-" e %prec SIGNO  { printf("e->-e\n"); $$ = -$2; } 
  ;


%%

void yyerror(const char *msg){
    printf("Error en línea %d: %s\n", yylineno, msg);
    errores++;
}

void asigna_reg(char *reg, long valor){
  // reg= "r/d"
  // int idx= reg[1]-'0'; resta cod ASCII. 
  int idx= atoi(&(reg[1]));
  registros[idx]=valor;
}

long recupera_reg(char *reg){
  int idx= atoi(&(reg[1]));
  return registros[idx];
}

void imprimir_reg(){
  for (int i=0; i<10; i++){
    printf("reg[%d]=%ld\n",i,registros[i]);
  }
}