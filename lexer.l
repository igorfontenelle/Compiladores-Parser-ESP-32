%{
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"      // Contém as definições dos tokens
%}

%option yylineno
%option noyywrap

%%

"var"                   { printf("Token: VAR\n"); return VAR; }
"inteiro"               { printf("Token: TIPO_INTEIRO\n"); return TIPO_INTEIRO; }
"texto"                 { printf("Token: TIPO_TEXTO\n"); return TIPO_TEXTO; }
"booleano"              { printf("Token: TIPO_BOOLEANO\n"); return TIPO_BOOLEANO; }
"config"                { printf("Token: CONFIG\n"); return CONFIG; }
"fim"                   { printf("Token: FIM\n"); return FIM; }
"repita"                { printf("Token: REPITA\n"); return REPITA; }
"configurar"            { printf("Token: CONFIGURAR\n"); return CONFIGURAR; }
"como"                  { printf("Token: COMO\n"); return COMO; }
"saida"                 { yylval.str = strdup("saida");  return DIRECAO; }
"entrada"               { yylval.str = strdup("entrada");  return DIRECAO; }
"configurarPWM"         { printf("Token: CONFIGURAR_PWM\n"); return CONFIGURAR_PWM; }
"ajustarPWM"            { printf("Token: AJUSTAR_PWM\n"); return AJUSTAR_PWM; }
"conectarWifi"          { printf("Token: CONECTAR_WIFI\n"); return CONECTAR_WIFI; }
"enviarHTTP"            { printf("Token: ENVIAR_HTTP\n"); return ENVIAR_HTTP; }
"escreverSerial"        { printf("Token: ESCREVER_SERIAL\n"); return ESCREVER_SERIAL; }
"lerSerial"             { printf("Token: LER_SERIAL\n"); return LER_SERIAL; }
"se"                    { printf("Token: SE\n"); return SE; }
"entao"                 { printf("Token: ENTAO\n"); return ENTAO; }
"senão"                 { printf("Token: SENAO\n"); return SENAO; }
"enquanto"              { printf("Token: ENQUANTO\n"); return ENQUANTO; }
"esperar"               { printf("Token: ESPERAR\n"); return ESPERAR; }
"ligar"                 { yylval.intval = 1; printf("Token: LIGAR\n"); return LIGAR; }
"desligar"              { yylval.intval = 0; printf("Token: DESLIGAR\n"); return DESLIGAR; }
"com"                   { printf("Token: COM\n"); return COM; }
"frequencia"            { printf("Token: FREQUENCIA\n"); return FREQUENCIA; }
"resolucao"             { printf("Token: RESOLUCAO\n"); return RESOLUCAO; }
"valor"                 { printf("Token: VALOR\n"); return VALOR; }

"=="                    { printf("Token: IGUAL_IGUAL\n"); return IGUAL_IGUAL; }
"!="                    { printf("Token: DIFERENTE\n"); return DIFERENTE; }
"<="                    { printf("Token: MENOR_IGUAL\n"); return MENOR_IGUAL; }
">="                    { printf("Token: MAIOR_IGUAL\n"); return MAIOR_IGUAL; }
"="                     { printf("Token: IGUAL\n"); return IGUAL; }
":"                     { printf("Token: DOIS_PONTOS\n"); return DOIS_PONTOS; }
";"                     { printf("Token: PONTO_VIRGULA\n"); return PONTO_VIRGULA; }

"\+"                    { printf("Token: MAIS\n"); return MAIS; }
"-"                     { printf("Token: MENOS\n"); return MENOS; }
"\*"                    { printf("Token: VEZES\n"); return VEZES; }
"/"                     { printf("Token: DIV\n"); return DIV; }

">"                     { printf("Token: MAIOR\n"); return MAIOR; }
"<"                     { printf("Token: MENOR\n"); return MENOR; }

"\("                    { return '('; }
"\)"                    { return ')'; }
","                     { printf("Token: VIRGULA\n"); return VIRGULA; }

\"[^\"]*\"              { 
                            yylval.str = strndup(yytext, yyleng); // Mantém as aspas
                            printf("Token: STRING_LIT, Valor: %s\n", yylval.str); 
                            return STRING_LIT; 
                        }

[a-zA-Z_][a-zA-Z0-9_]*  { 
                            yylval.str = strdup(yytext);
                            printf("Token: IDENTIFICADOR, Valor: %s\n", yytext); 
                            return IDENTIFICADOR; 
                        }

[0-9]+                  { 
                            yylval.intval = atoi(yytext);  // Converte o texto para inteiro
                            printf("Token: NUMERO, Valor: %d\n", yylval.intval);
                            return NUMERO; 
                        }

"//".*                  { /* Ignora comentários */ }

[ \t\r]+                { /* Ignora espaços e tabulações */ }

\n                      {  /* Ignora */  }

.                       { 
                            fprintf(stderr, "Erro: caractere inválido %s\n", yytext);
                            return ERRO; 
                        }

%%

