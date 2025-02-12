%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
using std::cout;

// Declaração da função do analisador léxico
int yylex(void);
int yyparse(void);
void yyerror(const char *s);

// Função de validação de string
int valid_string(const char* str);
%}

/* União para os valores dos tokens */
%union {
    int intval;
    char* str;
}

%token <str> IDENTIFICADOR STRING_LIT
%token <intval> NUMERO
%token <intval> LIGAR DESLIGAR

/* Declaração dos tokens – devem corresponder aos definidos no Flex e no cabeçalho tokens.h */
%token VAR TIPO_INTEIRO TIPO_TEXTO TIPO_BOOLEANO CONFIG FIM REPITA
%token CONFIGURAR COMO DIRECAO CONFIGURAR_PWM AJUSTAR_PWM
%token CONECTAR_WIFI ENVIAR_HTTP ESCREVER_SERIAL LER_SERIAL
%token SE ENTAO SENAO ENQUANTO ESPERAR
%token IGUAL           /* operador de atribuição "=" */
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

/* Definição de precedências e associatividade */
%left MAIS MENOS
%left VEZES DIV
%nonassoc IGUAL_IGUAL DIFERENTE MENOR MAIOR MENOR_IGUAL MAIOR_IGUAL

/* Declaração do tipo de retorno das expressões */
%type <intval> expression

%%

/* Regra inicial do programa */
program:
      declaration_list configBlock repitaBlock
      { printf("Programa validado corretamente.\n"); }
    ;

/* Lista de declarações de variáveis */
declaration_list:
      /* vazio */
    | declaration_list declaration
    ;

declaration:
      VAR type DOIS_PONTOS identifier_list PONTO_VIRGULA 
      { printf("Declaracao de variaveis realizada.\n"); }
    ;

/* Tipos suportados */
type:
      TIPO_INTEIRO { printf("Tipo: inteiro\n"); }
    | TIPO_TEXTO   { printf("Tipo: texto\n"); }
    ;

/* Cada identificador é impresso ao ser declarado */
identifier_list:
      IDENTIFICADOR { printf("Declarando variavel: %s\n", $1); }
    | identifier_list VIRGULA IDENTIFICADOR { printf("Declarando variavel: %s\n", $3); }
    ;

/* Bloco de configuração: executado uma única vez */
configBlock:
      CONFIG statement_list FIM
      { printf("Bloco de configuracao executado.\n"); }
    ;

/* Bloco principal (loop): executado continuamente */
repitaBlock:
      REPITA statement_list FIM
      { printf("Loop principal (repita) executado.\n"); }
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
      { printf("Atribuindo: %s = %d\n", $1, $3); }
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
      CONFIGURAR IDENTIFICADOR COM DIRECAO PONTO_VIRGULA 
      { printf("Configurando pino: %s como saida.\n", $2); }
    ;

/* Configuracao de PWM (ex.: configurarPWM ledPin com frequencia 5000 resolucao 8;) */
pwm_config_command:
      CONFIGURAR_PWM IDENTIFICADOR COM FREQUENCIA NUMERO RESOLUCAO NUMERO PONTO_VIRGULA 
      { printf("Configurando PWM no pino: %s com frequencia: %d e resolucao: %d\n", $2, $5, $7); }
    ;

/* Ajuste de PWM (ex.: ajustarPWM ledPin com valor brilho;) */
pwm_adjust_command:
      AJUSTAR_PWM IDENTIFICADOR COM VALOR expression PONTO_VIRGULA 
      { printf("Ajustando PWM no pino: %s com valor: %d\n", $2, $5); }
    ;

/* Conexao Wi-Fi (ex.: conectarWifi ssid senha;) */
wifi_connect_command:
      CONECTAR_WIFI IDENTIFICADOR IDENTIFICADOR PONTO_VIRGULA 
      { printf("Conectando WiFi: SSID = %s, SENHA = %s\n", $2, $3); }
    ;

/* Comando de delay (ex.: esperar 1000;) */
wait_command:
      ESPERAR expression PONTO_VIRGULA 
      { printf("Esperando: %d ms\n", $2); }
    ;

/* Comando digital (ex.: ligar ou desligar um pino) */
digital_command:
      LIGAR IDENTIFICADOR PONTO_VIRGULA 
      { printf("Comando digital: LIGAR %s\n", $2); }
    | DESLIGAR IDENTIFICADOR PONTO_VIRGULA 
      { printf("Comando digital: DESLIGAR %s\n", $2); }
    ;

/* Envio de dados via HTTP (ex.: enviarHTTP "http://example.com" "dados=123";) */
http_command:
      ENVIAR_HTTP STRING_LIT STRING_LIT PONTO_VIRGULA 
      { printf("Enviando HTTP: URL = %s, DADOS = %s\n", $2, $3); }
    ;

/* Comunicacao serial (ex.: escreverSerial "Mensagem"; ou lerSerial;) */
serial_command:
      ESCREVER_SERIAL STRING_LIT PONTO_VIRGULA 
      { printf("Escrevendo na Serial: %s\n", $2); }
    | LER_SERIAL PONTO_VIRGULA 
      { printf("Lendo da Serial\n"); }
    ;

/* Estruturas de controle */
control_structure:
      if_statement
    | while_statement
    ;

/* Estrutura condicional (if) */
if_statement:
      SE expression ENTAO statement_list opt_else FIM 
      { printf("Condicional SE executada com condicao: %d\n", $2); }
    ;

/* Opcional: parte SENAO do if */
opt_else:
      /* vazio */
    | SENAO statement_list 
      { printf("Bloco SENAO executado.\n"); }
    ;

/* Estrutura de repeticao (while) */
while_statement:
      ENQUANTO expression statement_list FIM 
      { printf("Estrutura ENQUANTO executada com condicao: %d\n", $2); }
    ;

/* Definicao de expressoes aritmeticas e relacionais */
expression:
      expression MAIS expression
          { $$ = $1 + $3; }
    | expression MENOS expression
          { $$ = $1 - $3; }
    | expression VEZES expression
          { $$ = $1 * $3; }
    | expression DIV expression
          { $$ = $1 / $3; }
    | expression IGUAL_IGUAL expression
          { $$ = ($1 == $3); }
    | expression DIFERENTE expression
          { $$ = ($1 != $3); }
    | expression MENOR expression
          { $$ = ($1 < $3); }
    | expression MAIOR expression
          { $$ = ($1 > $3); }
    | expression MENOR_IGUAL expression
          { $$ = ($1 <= $3); }
    | expression MAIOR_IGUAL expression
          { $$ = ($1 >= $3); }
    | '(' expression ')'
          { $$ = $2; }
    | NUMERO
          { $$ = $1; }
    | IDENTIFICADOR
          { $$ = 0; }         /* Em um analisador completo, deve-se buscar o valor da variável */
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
}

int valid_string(const char* str) {
    // Exemplo de validação: você pode querer garantir que a string não seja vazia
    return str != NULL && strlen(str) > 0;
}