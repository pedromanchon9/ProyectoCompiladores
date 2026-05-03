%{
    #include "calculadora.tab.h"
    int errores=0;
%}

%option yylineno

%%

[ \t\n\r]+      { }
"+"             { return MAS; }
"*"             { return POR; }
"-"             { return RES; }
"/"             { return DIV; }
"="             { return IGU; }
"r"[0-9]        { yylval.reg = strdup(yytext); return REG; }
[0-9]+          { yylval.num = atoi(yytext); return NUM; }
"("             { return PAI; }
")"             { return PAD; }
";"             { return PYC; }
.               { printf("Error lexico: %s\n", yytext); errores++;}


%%