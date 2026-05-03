miniC : miniC.tab.c main.c lex.yy.c  listaSimbolos.c listaCodigo.c
	gcc miniC.tab.c main.c lex.yy.c listaSimbolos.c listaCodigo.c -lfl -o miniC

lex.yy.c : miniC.l miniC.tab.h
	flex miniC.l

miniC.tab.h miniC.tab.c : miniC.y
	 bison -d -v miniC.y

clean: 
	rm -f miniC.tab.* lex.yy.c miniC.output miniC

run : miniC prueba.txt 
	./miniC prueba.txt




