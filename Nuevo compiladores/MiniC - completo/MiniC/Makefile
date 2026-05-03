miniC : miniC.tab.c main.c lex.yy.c  listaSimbolos.c listaCodigo.c func_semantico.c
	gcc miniC.tab.c main.c lex.yy.c listaSimbolos.c listaCodigo.c func_semantico.c -lfl -o miniC

lex.yy.c : miniC.l miniC.tab.h
	flex miniC.l

miniC.tab.h miniC.tab.c : miniC.y
	 bison -d -v miniC.y

clean: 
	rm -f miniC.tab.* lex.yy.c miniC.output miniC

run : miniC entrada.txt
	./miniC entrada.txt > a_salida.s	

run2 : miniC entrada2.txt
	./miniC entrada2.txt > a_salida2.s	

run_s : miniC entrada_sencilla.txt
	./miniC entrada_sencilla.txt > a_entrada_sencilla.s	



