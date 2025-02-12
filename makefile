all: parser

# Compiler
CPPC=g++

# Lexer
FLEX=flex

# Yacc 
BISON=bison

parser: lex.yy.c parser.tab.c
	$(CPPC) lex.yy.c parser.tab.c -std=c++17 -o parser

lex.yy.c: lexer.l
	$(FLEX) lexer.l

parser.tab.c: parser.y
	$(BISON) -d parser.y

clean:
	rm parser lex.yy.c parser.tab.c parser.tab.h