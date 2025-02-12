#ifndef TOKEN_H
#define TOKEN_H

// Definição dos tokens básicos
#define CONFIG 1
#define REPITA 2
#define FIM 3
#define VAR 4
#define TIPO_INTEIRO 5
#define TIPO_TEXTO 6
#define TIPO_BOOLEANO 7
#define CONFIGURAR 8
#define COMO 9
#define DIRECAO 10
#define CONFIGURAR_PWM 11
#define AJUSTAR_PWM 12
#define CONECTAR_WIFI 13
#define ENVIAR_HTTP 14
#define CONFIGURAR_SERIAL 15
#define ESCREVER_SERIAL 16
#define LER_SERIAL 17
#define SE 18
#define ENTAO 19
#define SENAO 20
#define ENQUANTO 21
#define ESPERAR 22
#define LIGAR 23
#define DESLIGAR 24
#define COM 25
#define FREQUENCIA 26
#define RESOLUCAO 27
#define VALOR 28

// Definição dos operadores
#define IGUAL_IGUAL 29
#define DIFERENTE 30
#define MENOR_IGUAL 31
#define MAIOR_IGUAL 32
#define IGUAL 33
#define DOIS_PONTOS 34
#define PONTO_VIRGULA 35
#define MAIS 36
#define MENOS 37
#define VEZES 38
#define DIV 39
#define MAIOR 40
#define MENOR 41
#define VIRGULA 42

// Tokens adicionais

#define NUMERO 43
#define STRING_LIT 44
#define IDENTIFICADOR 45
#define NOVA_LINHA 46
#define ERRO 47

// Definição da estrutura para armazenar valores dos tokens
typedef union {
    int valor_inteiro;  // Para tokens numéricos
    char* valor_texto;  // Para tokens de string
} YYSTYPE;

extern YYSTYPE yylval;

#endif // TOKEN_H
