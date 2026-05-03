%{
    /*Código literal q se coloca en lex.yy.c al comienzo*/

    #include <stdio.h>
    #include <stdlib.h>
    #include "calculadora.h"
    int errores_lexicos = 0;
    int inicio_comentario = 0;
    int errores = 0;
    #define MAX_INT 2147483648

%}

L   [a-zA-Z_]
D   [0-9]
panico [^a-zA-Z_0-9(); \n\t\r+\-*/={},]+

/*para actializar la variable*/
%option yylineno 

/*Condición de contexto*/
%x comentario
%x cadena_text
%%

 /*Expresiones regulares de espacios en blanco y comentarios*/

[ \n\t\r]+          { }
"//".*              { }
"/*"                { inicio_comentario =yylineno;
                      BEGIN(comentario); }
<comentario>.|\n    { }
<comentario>"*/"    { BEGIN(INITIAL);   }
<comentario><<EOF>> {
                 printf("Comentario sin cerrar desde %d\n",
                        inicio_comentario);
                 return 0;
                }
\"              { BEGIN(cadena_text); yymore(); }
<cadena_text>\" { BEGIN(INITIAL); return CAD; }
<cadena_text>\\\"|.   { yymore(); }


 /*Expresiones regulares de Tokens. Importante dejar espacio antes del comentario*/
"print"         { return PRI; }
"void"          { return VOI; }
"var"           { return VAR; }
"const"         { return COM; }
"int"           { return INT; }
"if"            { return IIF; }
"else"          { return ELS; }
"while"         { return WHI; }
"read"          { return REA; }

{L}({L}|{D})*   { 
                    if(yyleng > 32){
                        printf("Error en la linea %d: identificador demasiado largo %s\n",
                                yylineno, yytext);
                        errores++;
                    }
                    return IDE; 
                }
"="             { return IGU; }
";"             { return PYC; }
"+"             { return MAS; }
"-"             { return MEN; }
"*"             { return POR; }
"/"             { return DIV; }
"("             { return PAI; }
")"             { return PAD; }
"{"             { return LLI; }
"}"             { return LLD; }
","             { return COM; }
{D}+            { 
                    if(strtoll(yytext,NULL,10)>MAX_INT){
                        printf("Error en linea %d: entero demasiado grande %s\n",
                            yylineno, yytext);
                        errores++;
                    }
                    return NUM; 
                }

{panico}        {
                    printf("Error en linea %d: %s\n",
                        yylineno, yytext
                    );
                }

%%
