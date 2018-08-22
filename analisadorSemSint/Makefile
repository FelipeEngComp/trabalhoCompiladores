all:
	flex lexico.l
	bison  parser.y
	g++ -o compilador parser.tab.c  -DDEBUG  -lfl

clean:
	rm saida.out	
