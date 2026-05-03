calculadora : lex.yy.c calculadora.tab.c main.c
	gcc lex.yy.c calculadora.tab.c main.c -lfl -o calculadora

lex.yy.c : calculadora.l calculadora.tab.h
	flex calculadora.l

calculadora.tab.c calculadora.tab.h : calculadora.y
	bison -d -v calculadora.y

run : calculadora entrada.txt
	./calculadora entrada.txt

clean : 
	rm -f calculadora lex.yy.c calculadora.tab.*