# Compiladores-Parser-ESP-32

Ao invés de utilizar um arquivo `.sh`, foi criado um **Makefile** para automatizar todo o processo de compilação. O arquivo `Makefile` é responsável por:

1. Executar o **Flex** no arquivo `lexer.l`, gerando `lex.yy.c`;
2. Executar o **Bison** no arquivo `parser.y`, gerando `parser.tab.c` e `parser.tab.h`;
3. Compilar todos os arquivos `.c`/`.cpp` (incluindo `semantic.cpp` e `codegen.cpp`) e gerar o executável final `parser`.

### Como usar

- Para gerar o executável, basta digitar no terminal:
	```bash
	make
	```
    
    Isso executa, em sequência:
    
    1. `flex lexer.l` → gera `lex.yy.c`
    2. `bison -d parser.y` → gera `parser.tab.c` e `parser.tab.h`
    3. `g++ lex.yy.c parser.tab.c semantic.cpp codegen.cpp -o parser` → cria o binário `parser`
    
- Para limpar todos os arquivos gerados:
    
    ```bash
    make clean
	```
    Remove `parser`, `lex.yy.c`, `parser.tab.c` e `parser.tab.h`.

	Com esse **Makefile**, todo o processo de compilação do projeto (análise léxica, análise sintática, semântica e geração do executável final) fica automatizado, o que cumpre o requisito (e) do trabalho.