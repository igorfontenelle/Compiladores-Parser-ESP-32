%{
#include <iostream>
#include <cstdlib>
#include <string>

using namespace std;

// Declaração da função do analisador léxico
extern int yylex();
extern int yylineno;
void yyerror(const char *s);
%}

/* Definição de tipos (união) para os valores dos tokens */
%union {
    int intval;
    char* str;
}

/* Declaração dos tokens – estes devem corresponder aos gerados pelo Flex */
%token VAR TIPO_INTEIRO TIPO_TEXTO CONFIG FIM REPITA
%token CONFIGURAR CONFIGURAR_PWM AJUSTAR_PWM
%token CONECTAR_WIFI ENVIAR_HTTP ESCREVER_SERIAL LER_SERIAL
%token SE ENTAO SENAO ENQUANTO ESPERAR LIGAR DESLIGAR
%token IGUAL DOIS_PONTOS PONTO_VIRGULA
%token IDENTIFICADOR NUMERO STRING_LIT NOVA_LINHA

/* Tokens adicionais para palavras reservadas dos comandos */
%token COM FREQUENCIA RESOLUCAO VALOR
%token COMMA

/* Tokens para operadores aritméticos e relacionais */
%token MAIS MENOS VEZES DIV
%token MAIOR MENOR

/* Definição das precedências (opcional, para resolução de conflitos) */
%left MAIS MENOS
%left VEZES DIV
%nonassoc MAIOR MENOR

/* Declaração de tipos para símbolos não terminais */
%type <intval> expression

%%

/* Regra inicial do programa */
program:
      declaration_list configBlock repitaBlock
    ;

/* Lista de declarações de variáveis */
declaration_list:
      /* vazio */
    | declaration_list declaration
    ;

declaration:
      VAR type DOIS_PONTOS identifier_list PONTO_VIRGULA
    ;

type:
      TIPO_INTEIRO
    | TIPO_TEXTO
    ;

identifier_list:
      IDENTIFICADOR
    | identifier_list COMMA IDENTIFICADOR
    ;

/* Bloco de configuração: executado uma única vez */
configBlock:
      CONFIG statement_list FIM
    ;

/* Bloco principal: loop contínuo */
repitaBlock:
      REPITA statement_list FIM
    ;

/* Lista de comandos ou instruções */
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

/* Exemplo: configurar pino como saída (configurar ledPin como saida;) */
config_command:
      CONFIGURAR IDENTIFICADOR COM DIRECAO PONTO_VIRGULA
    ;

/* Configuração de PWM:
   Exemplo: configurarPWM ledPin com frequencia 5000 resolucao 8; */
pwm_config_command:
      CONFIGURAR_PWM IDENTIFICADOR COM FREQUENCIA NUMERO RESOLUCAO NUMERO PONTO_VIRGULA
    ;

/* Ajuste de PWM:
   Exemplo: ajustarPWM ledPin com valor brilho; */
pwm_adjust_command:
      AJUSTAR_PWM IDENTIFICADOR COM VALOR expression PONTO_VIRGULA
    ;

/* Conexão Wi-Fi:
   Exemplo: conectarWifi ssid senha; */
wifi_connect_command:
      CONECTAR_WIFI IDENTIFICADOR IDENTIFICADOR PONTO_VIRGULA
    ;

/* Comando de delay:
   Exemplo: esperar 1000; */
wait_command:
      ESPERAR expression PONTO_VIRGULA
    ;

/* Comandos para ligar ou desligar um dispositivo:
   Exemplo: ligar ledPin; ou desligar ledPin; */
digital_command:
      ( LIGAR | DESLIGAR ) IDENTIFICADOR PONTO_VIRGULA
    ;

/* Envio de dados via HTTP:
   Exemplo: enviarHTTP "http://example.com" "dados=123"; */
http_command:
      ENVIAR_HTTP STRING_LIT STRING_LIT PONTO_VIRGULA
    ;

/* Comandos de comunicação serial:
   Exemplo: escreverSerial "Mensagem"; ou lerSerial; */
serial_command:
      ESCREVER_SERIAL STRING_LIT PONTO_VIRGULA
    | LER_SERIAL PONTO_VIRGULA
    ;

/* Estruturas de controle */
control_structure:
      if_statement
    | while_statement
    ;

/* Estrutura condicional:
   Exemplo:
       se condição entao
         instruções
       senão
         instruções
       fim
*/
if_statement:
      SE expression ENTAO statement_list opt_else FIM
    ;

/* Parte opcional do 'if' */
opt_else:
      /* vazio */
    | SENAO statement_list
    ;

/* Estrutura de repetição (loop):
   Exemplo:
       enquanto condição
         instruções
       fim
*/
while_statement:
      ENQUANTO expression statement_list FIM
    ;

/* Definição de expressões aritméticas e relacionais */
expression:
      expression MAIS expression
    | expression MENOS expression
    | expression VEZES expression
    | expression DIV expression
    | expression MAIOR expression
    | expression MENOR expression
    | '(' expression ')'
    | NUMERO
    | STRING_LIT
    | IDENTIFICADOR
    ;

%%

/* Função de tratamento de erros */
void yyerror(const char *s) {
    std::cerr << "Erro: " << s << " na linha " << yylineno << std::endl;
}

/* Função principal */
int main() {
    return yyparse();
}
