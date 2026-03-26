#include <stdlib.h>
#include <stdio.h>
extern int yyparse();
extern int errores;
extern FILE *yyin;

int main( int argc, char *argv[]){
    int token;
    if(argc != 2){
        printf("Uso: %S fichero\n",argv[0]);
    }
    yyin = fopen(argv[1], "r");
    if(yyin ==NULL){
        printf("No se puede abrir el fichero %s\n", argv[1]);
        exit(2);
    }

    yyparse();
    printf("Compilacion termina con %d errores\n",errores);
}