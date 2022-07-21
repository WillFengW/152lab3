CFLAGS = -g -Wall -ansi -pedantic

miniL: miniL.lex miniL.y
	bison -d -v miniL.y
	flex miniL.lex
	g++ $(CFLAGS) -std=c++11 lex.yy.c miniL.tab.c -lfl -o miniL
clean:
	rm -f lex.yy.c *.output *.tab.h *.tab.c