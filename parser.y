%code requires {
  #include <string>
  #include <vector>
  #include "ast.h"   // Pois VarType está definido em "ast.h"
}

%{
  #include "ast.h"   // Para ASTProgram e etc. no corpo do parser
  #include "semantic.h"
  #include "codegen.h"
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <iostream>


// Para simplificar o uso de std::vector e std::string no %union
using std::cout;
using std::vector;
using std::string;

//Objeto global
ASTProgram astProgram;

/* 
 * Variável global para sabermos em qual bloco estamos
 * 0 = nenhum, 1 = config, 2 = repita
 */
static int currentBlock = 0;

// Declaração da função do analisador léxico
int yylex(void);
int yyparse(void);
void yyerror(const char *s);

// Função de validação de string
int valid_string(const char* str);
%}

/* ------------------------------------------------------------------
   União para os valores dos tokens e não-terminais
   ------------------------------------------------------------------ */
%union {
    int intval;                /* Para tokens NUMERO, LIGAR, DESLIGAR etc. */
    char* str;                 /* Para tokens IDENTIFICADOR, STRING_LIT etc. */
    VarType varType;           /* Para armazenar o tipo de variável (VAR_INTEIRO, etc.) */
    std::vector<std::string>* strList; /* Para listas de identificadores */
}

/* ------------------------------------------------------------------
   Declaração dos tokens
   ------------------------------------------------------------------ */
%token <str> IDENTIFICADOR STRING_LIT
%token <intval> NUMERO
%token <intval> LIGAR DESLIGAR
%token <str> DIRECAO

/* Declaração dos tokens – devem corresponder aos definidos no Flex e no cabeçalho tokens.h */
%token VAR TIPO_INTEIRO TIPO_TEXTO TIPO_BOOLEANO
%token CONFIG FIM REPITA
%token CONFIGURAR COMO CONFIGURAR_PWM AJUSTAR_PWM
%token CONECTAR_WIFI ENVIAR_HTTP ESCREVER_SERIAL LER_SERIAL
%token LER_DIGITAL LER_ANALOGICO
%token SE ENTAO SENAO ENQUANTO ESPERAR
%token IGUAL  /* "=" atribuição */
%token DOIS_PONTOS PONTO_VIRGULA
%token NOVA_LINHA ERRO

/* Tokens para comandos adicionais */
%token COM FREQUENCIA RESOLUCAO VALOR VIRGULA
/* Tokens para operadores aritméticos */
%token MAIS MENOS VEZES DIV
/* Tokens para operadores relacionais */
%token IGUAL_IGUAL      /* "==" */
%token DIFERENTE        /* "!=" */
%token MENOR            /* "<" */
%token MAIOR            /* ">" */
%token MENOR_IGUAL      /* "<=" */
%token MAIOR_IGUAL      /* ">=" */

/* ------------------------------------------------------------------
   Definições de precedência 
   ------------------------------------------------------------------ */
%left MAIS MENOS
%left VEZES DIV
%nonassoc IGUAL_IGUAL DIFERENTE MENOR MAIOR MENOR_IGUAL MAIOR_IGUAL

/* ------------------------------------------------------------------
   Definições de tipo de cada não-terminal
   ------------------------------------------------------------------ */
%type <varType> type
%type <strList> identifier_list
%type <str> expression
%type <str> read_digital
%type <str> read_analog

%%

/* Regra inicial do programa */
program:
    declaration_list configBlock repitaBlock { printf("Programa validado corretamente.\n"); }
    | program '\n'
    ;

/* Lista de declarações de variáveis */
declaration_list:
      /* vazio */
    | declaration_list declaration
    ;

declaration:
      VAR type DOIS_PONTOS identifier_list PONTO_VIRGULA 
      { 
        // $2 é <varType>, $4 é <strList>
        // Inserir as variáveis em astProgram.declarations
        for (auto &nome : *($4)) {
            VarDecl decl;
            decl.name = nome;       // ex.: "ledPin"
            decl.type = $2;        // ex.: VAR_INTEIRO
            // isPin, isPWM, etc. começam em false (construtor default)
            astProgram.declarations.push_back(decl);
        }
        printf("Declaracao de variaveis realizada.\n"); 
        // Liberar a memória da lista
        delete $4;
        
      }
    ;

/* Tipos suportados */
type:
      TIPO_INTEIRO { printf("Tipo: inteiro\n"); }
    | TIPO_TEXTO   { printf("Tipo: texto\n"); }
    | TIPO_BOOLEANO { $$ = VAR_BOOLEANO; }
    ;

/* Lista de identificadores: "ledPin, brilho" */
identifier_list:
      IDENTIFICADOR 
      { 
        // Cria uma lista e insere $1
        auto v = new vector<string>();
        v->push_back($1);
        $$ = v;
        printf("Declarando variavel: %s\n", $1); 
        free($1); // liberamos a string alocada pelo lexer
      }
    | identifier_list VIRGULA IDENTIFICADOR 
    { 
      // anexa $3 na lista existente $1
      $1->push_back($3);
      $$ = $1;
      printf("Declarando variavel: %s\n", $3); 
      free($3);
    }
    ;

/* Bloco de configuração (executado uma única vez) */
configBlock:
      CONFIG
        {
          currentBlock = 1; // Indica que estamos em "config"
        }
      statement_list FIM
        {
          currentBlock = 0; // encerramos config
          printf("Bloco de configuracao executado.\n");
        }
    ;

/* Bloco principal (loop contínuo) */
repitaBlock:
      REPITA
        {
          currentBlock = 2; // Indica que estamos em "repita"
        }
      statement_list FIM
        {
          currentBlock = 0; // encerra "repita"
          // printf("Loop principal (repita) executado.\n");
        }
    ;

/* Lista de comandos */
statement_list:
      /* vazio */
    | statement_list statement
    ;

statement:
      assignment_statement
    | command_statement
    | control_structure
    ;

/* Atribuição de valor a uma variável */
assignment_statement:
      IDENTIFICADOR IGUAL expression PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_ASSIGN;
        cmd.varName = $1;  // ex.: "ledPin"
        cmd.expr = $3;     // ex.: "2", "brilho", etc.

        // Adiciona no bloco atual (config ou repita)
        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Atribuindo: %s = %s\n", $1, $3);
        free($1);
        free($3);
      }
      | IDENTIFICADOR IGUAL read_digital PONTO_VIRGULA
      {
        // "estadoBotao = lerDigital botao;"
        Command cmd;
        cmd.cmdType = CMD_LER_DIGITAL;
        cmd.varName = $1; // ex.: "estadoBotao"
        cmd.pin     = $3; // ex.: "botao" (vem da regra read_digital)
        // ...
        // Inserir no configCommands ou repitaCommands dependendo de currentBlock
        if(currentBlock == 1) 
            astProgram.configCommands.push_back(cmd);
        else if(currentBlock == 2)
            astProgram.repitaCommands.push_back(cmd);

        free($1);
        free($3);
      }
      | IDENTIFICADOR IGUAL read_analog PONTO_VIRGULA
      {
        // "sensorValor = lerAnalogico sensor;"
        Command cmd;
        cmd.cmdType = CMD_LER_ANALOGICO;
        cmd.varName = $1;  // ex.: "sensorValor"
        cmd.pin     = $3;  // ex.: "sensor"
        // ...
        if(currentBlock == 1)
            astProgram.configCommands.push_back(cmd);
        else if(currentBlock == 2)
            astProgram.repitaCommands.push_back(cmd);

        free($1);
        free($3);
      }
    ;

/* Comandos disponíveis na linguagem */
command_statement:
      config_command
    | pwm_config_command
    | pwm_adjust_command
    | wifi_connect_command
    | wait_command
    | digital_command
    | http_command
    | serial_command
    ;

/* Configuracao de pino (ex.: configurar ledPin como saida;) */
config_command:
      CONFIGURAR IDENTIFICADOR COMO DIRECAO PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_CONFIG_PIN;
        cmd.pin = $2;        // "ledPin"
        cmd.pinMode = $4;    // "saida", "entrada", etc.

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Configurando pino: %s como saida.\n", $2);
        free($2);
        free($4);
      }
    ;

/* Configuracao de PWM (ex.: configurarPWM ledPin com frequencia 5000 resolucao 8;) */
pwm_config_command:
      CONFIGURAR_PWM IDENTIFICADOR COM FREQUENCIA NUMERO RESOLUCAO NUMERO PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_CONFIG_PWM;
        cmd.pin = $2;    // ex.: "ledPin"
        cmd.freq = $5;   // ex.: 5000
        cmd.resol = $7;  // ex.: 8

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Configurando PWM no pino: %s com frequencia: %d e resolucao: %d\n", $2, $5, $7);
        free($2);
      }
    ;

/* Ajuste de PWM (ex.: ajustarPWM ledPin com valor brilho;) */
pwm_adjust_command:
      AJUSTAR_PWM IDENTIFICADOR COM VALOR expression PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_PWM_ADJUST;
        cmd.pin = $2;         // "ledPin"
        cmd.valueExpr = $5;   // "brilho", "128", etc.

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Ajustando PWM no pino: %s com valor: %s\n", $2, $5);
        free($2);
        free($5);
      }
    ;

/* Conexao Wi-Fi (ex.: conectarWifi ssid senha;) */
wifi_connect_command:
      CONECTAR_WIFI IDENTIFICADOR IDENTIFICADOR PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_WIFI_CONNECT;
        cmd.ssid = $2;
        cmd.password = $3;

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Conectando WiFi: SSID = %s, SENHA = %s\n", $2, $3);
        free($2);
        free($3);
      }
    ;

/* Comando de delay (ex.: esperar 1000;) */
wait_command:
      ESPERAR expression PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_WAIT;
        cmd.waitTime = $2; // ex. "1000"

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Esperando: %s ms\n", $2);
        free($2);
      }
    ;

/* Comando digital (ex.: ligar ou desligar um pino) */
digital_command:
      LIGAR IDENTIFICADOR PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_LIGAR;
        cmd.digitalPin = $2;

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Comando digital: LIGAR %s\n", $2);
        free($2);
      }
    | DESLIGAR IDENTIFICADOR PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_DESLIGAR;
        cmd.digitalPin = $2;

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Comando digital: DESLIGAR %s\n", $2);
        free($2);
      }
    ;

read_digital:
    LER_DIGITAL IDENTIFICADOR
    {
       // Retornamos o pino
       $$ = $2;  // ex.: "botao"
    }
    ;

read_analog:
    LER_ANALOGICO IDENTIFICADOR
    {
       // Retornamos o pino
       $$ = $2;  // ex.: "sensor"
    }
    

/* Envio de dados via HTTP (ex.: enviarHTTP "http://example.com" "dados=123";) */
http_command:
      ENVIAR_HTTP STRING_LIT STRING_LIT PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_ENVIAR_HTTP;
        cmd.httpUrl = $2;   // ex.: "http://example.com"
        cmd.httpData = $3;  // ex.: "dados=123"

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Enviando HTTP: URL = %s, DADOS = %s\n", $2, $3);
        free($2);
        free($3);
      }
    ;

/* Comunicacao serial (ex.: escreverSerial "Mensagem"; ou lerSerial;) */
serial_command:
      ESCREVER_SERIAL STRING_LIT PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_ESCREVER_SERIAL;
        cmd.serialMsg = $2;  // ex.: "Mensagem"

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Escrevendo na Serial: %s\n", $2);
        free($2);
      }
    | LER_SERIAL PONTO_VIRGULA
      {
        Command cmd;
        cmd.cmdType = CMD_LER_SERIAL;

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Lendo da Serial\n");
      }
    ;

/* Estruturas de controle */
control_structure:
      if_statement
    | while_statement
    ;

/* Estrutura condicional (if) */
/* if_statement: se expr entao statement_list [senao statement_list] fim */
if_statement:
      SE expression ENTAO statement_list opt_else FIM
      {
        Command cmd;
        cmd.cmdType = CMD_IF;
        cmd.conditionExpr = $2; // ex.: "(brilho>128)"
        // Caso queira guardar os subcomandos do 'then' e 'else', 
        // teria que expandir a AST para suportar sub-blocos.
        // Aqui, simplificamos e guardamos só a expressão.

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Condicional SE executada com condicao: %s\n", $2);
        free($2);
      }
    ;

/* Opcional: parte SENAO do if */
/* Parte opcional SENAO */
opt_else:
      /* vazio */
    | SENAO statement_list 
      { printf("Bloco SENAO executado.\n"); /* Em um design mais avançado, armazenaríamos os comandos do else. */ }
    ;

/* Estrutura de repeticao (while) */
/* while_statement: enquanto expr statement_list fim */
while_statement:
      ENQUANTO expression statement_list FIM
      {
        Command cmd;
        cmd.cmdType = CMD_WHILE;
        cmd.conditionExpr = $2; // ex.: "(brilho<255)"

        if (currentBlock == 1) {
            astProgram.configCommands.push_back(cmd);
        } else if (currentBlock == 2) {
            astProgram.repitaCommands.push_back(cmd);
        }
        printf("Estrutura ENQUANTO executada com condicao: %s\n", $2);
        free($2);
      }
    ;

/* ------------------------------------------------------------------
   Definição de expressão unificada
   (sempre retorna <str>, que é um char*)
   ------------------------------------------------------------------ */
expression:
      /* 1) Valor inteiro literal */
      NUMERO 
        {
          char buffer[32];
          sprintf(buffer, "%d", $1);  /* $1 é <intval> */
          $$ = strdup(buffer);        /* $$ é <str> */
        }
    | IDENTIFICADOR
        {
          $$ = strdup($1);
          free($1);
        }
    | STRING_LIT
        {
          $$ = strdup($1);
          free($1);
        }
    | expression MAIS expression
        {
          int len = strlen($1) + strlen($3) + 5;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s+%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression MENOS expression
        {
          int len = strlen($1) + strlen($3) + 5;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s-%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression VEZES expression
        {
          int len = strlen($1) + strlen($3) + 5;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s*%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression DIV expression
        {
          int len = strlen($1) + strlen($3) + 5;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s/%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | '(' expression ')'
        {
          int len = strlen($2) + 3;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s)", $2);
          $$ = buf;
          free($2);
        }
    | expression MENOR expression
        {
          int len = strlen($1) + strlen($3) + 5;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s<%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression MAIOR expression
        {
          int len = strlen($1) + strlen($3) + 5;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s>%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression MENOR_IGUAL expression
        {
          int len = strlen($1) + strlen($3) + 6;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s<=%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression MAIOR_IGUAL expression
        {
          int len = strlen($1) + strlen($3) + 6;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s>=%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression IGUAL_IGUAL expression
        {
          int len = strlen($1) + strlen($3) + 6;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s==%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    | expression DIFERENTE expression
        {
          int len = strlen($1) + strlen($3) + 6;
          char* buf = (char*) malloc(len);
          sprintf(buf, "(%s!=%s)", $1, $3);
          $$ = buf;
          free($1); free($3);
        }
    ;

%%

void yyerror(const char *s) {
    /* variáveis definidas no analisador léxico */
	extern int yylineno;    
	extern char * yytext;   
	
	/* mensagem de erro exibe o símbolo que causou erro e o número da linha */
    cout << "Erro (" << s << "): símbolo \"" << yytext << "\" (linha " << yylineno << ")\n";
}

/* Função principal */
int main() {
    yyparse();
    semanticAnalysis(astProgram);
    // Exemplo: ao final, podemos mostrar quantas declarações e comandos lemos:
    // (ou chamaremos análise semântica e geração de código, etc.)
    cout << "\n========== Resumo do AST ==========\n";
    cout << "Declaracoes de variaveis: " << astProgram.declarations.size() << "\n";
    cout << "Comandos em config:       " << astProgram.configCommands.size() << "\n";
    cout << "Comandos em repita:       " << astProgram.repitaCommands.size() << "\n";

    generateCode(astProgram, "output.cpp");

    return 0;
}

int valid_string(const char* str) {
    // Exemplo de validação: você pode querer garantir que a string não seja vazia
    return str != NULL && strlen(str) > 0;
}