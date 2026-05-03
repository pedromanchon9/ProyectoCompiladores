calculadora : lex.yy.c main.c
	gcc lex.yy.c main.c -lfl -o calculadora

lex.yy.c : calculadora.l calculadora.h
	flex calculadora.l

run : calculadora entrada.txt
	./calculadora entrada.txt

clean : 
	rm -f calculadora lex.yy.c