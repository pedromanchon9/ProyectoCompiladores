%{
    /*Código literal q se coloca en lex.yy.c al comienzo*/

    #include <stdio.h>
    #include <stdlib.h>
    #include "miniC.tab.h"

    #define MAX_ID 32
    #define MAX_INT 2147483648

    extern int errores;
    int inicio_comentario;

%}

L   [a-zA-Z_]
D   [0-9]
/*definimos un conjunto complementario de los caracteres correctos, reconoce cualquier caracter no correcto*/
panico [^a-zA-Z_0-9(); \n\t\r+\-*/={},\"]+

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
<cadena_text>\" { BEGIN(INITIAL); 
                  yylval.cadena = strdup(yytext);
                  return STR; }
<cadena_text>\\\"|.   { yymore(); }


 /*Expresiones regulares de Tokens. Importante dejar espacio antes del comentario*/
"print"         { return PRINT; }
"void"          { return VOID; }
"var"           { return VAR;  }
"const"         { return CONST; }
"int"           { return INT;  }
"if"            { return IF;  }
"else"          { return ELSE; }
"while"         { return WHILE; }
"do"            { return DO;   }
"read"          { return READ; }
"return"        { return RETR; }

{L}({L}|{D})*   { 
                    if(yyleng > MAX_ID) {
                        printf("Error en la linea %d: identificador demasiado largo %s\n",
                                yylineno, yytext);
                        errores++;
                    }
                    yylval.cadena = strdup(yytext);
                    return ID; 
                }

"="             { return IGU; }
";"             { return PYC; }
"+"             { return SUMA; }
"-"             { return REST; }
"*"             { return MUL; }
"/"             { return DIV; }
"("             { return PAI; }
")"             { return PAD; }
"{"             { return LLI; }
"}"             { return LLD; }
","             { return COMA; }



{D}+            { 
                    if(atol(yytext)>=MAX_INT){      /*ascii to long*/
                        printf("Error en linea %d: entero demasiado grande %s\n",
                            yylineno, yytext);
                        errores++;
                    }
                    yylval.cadena = strdup(yytext);
                    return NUM; 
                }

{panico}        {
                    printf("Error en linea %d: %s\n",
                        yylineno, yytext
                    );
                }

%%
