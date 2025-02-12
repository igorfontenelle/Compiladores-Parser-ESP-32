%{
#include <iostream>
#include "tokens.h"      // Contém as definições dos tokens

// Declarar yylval para armazenar valores dos tokens
YYSTYPE yylval;
%}

%option noyywrap

%%

"var"                   { 
    std::cout << "Token: VAR" << std::endl; 
    return VAR; 
}
"inteiro"               { 
    std::cout << "Token: TIPO_INTEIRO" << std::endl; 
    return TIPO_INTEIRO; 
}
"texto"                 { 
    std::cout << "Token: TIPO_TEXTO" << std::endl; 
    return TIPO_TEXTO; 
}
"booleano"              {
    std::cout << "Token: TIPO_BOOLEANO" << std::endl; 
    return TIPO_BOOLEANO; 
}
"config"                { 
    std::cout << "Token: CONFIG" << std::endl; 
    return CONFIG; 
}
"fim"                   { 
    std::cout << "Token: FIM" << std::endl; 
    return FIM; 
}
"repita"                {
    std::cout << "Token: REPITA" << std::endl;
    return REPITA;
}
"configurar"            { 
    std::cout << "Token: CONFIGURAR" << std::endl; 
    return CONFIGURAR; 
}
"como"                  { 
    std::cout << "Token: COMO" << std::endl; 
    return COMO; 
}
"saida"                 { 
    std::cout << "Token: DIRECAO" << std::endl; 
    return DIRECAO; 
}
"configurarPWM"         { 
    std::cout << "Token: CONFIGURAR_PWM" << std::endl; 
    return CONFIGURAR_PWM; 
}
"ajustarPWM"            { 
    std::cout << "Token: AJUSTAR_PWM" << std::endl; 
    return AJUSTAR_PWM; 
}
"conectarWifi"          { 
    std::cout << "Token: CONECTAR_WIFI" << std::endl; 
    return CONECTAR_WIFI; 
}
"enviarHTTP"            { 
    std::cout << "Token: ENVIAR_HTTP" << std::endl; 
    return ENVIAR_HTTP; 
}
"escreverSerial"        { 
    std::cout << "Token: ESCREVER_SERIAL" << std::endl; 
    return ESCREVER_SERIAL; 
}
"lerSerial"             { 
    std::cout << "Token: LER_SERIAL" << std::endl; 
    return LER_SERIAL; 
}
"se"                    { 
    std::cout << "Token: SE" << std::endl; 
    return SE; 
}
"entao"                 { 
    std::cout << "Token: ENTAO" << std::endl; 
    return ENTAO; 
}
"senão"                 { 
    std::cout << "Token: SENAO" << std::endl; 
    return SENAO; 
}
"enquanto"              { 
    std::cout << "Token: ENQUANTO" << std::endl; 
    return ENQUANTO; 
}
"esperar"               { 
    std::cout << "Token: ESPERAR" << std::endl; 
    return ESPERAR; 
}
"ligar"                 { 
    std::cout << "Token: LIGAR" << std::endl; 
    return LIGAR; 
}
"desligar"              { 
    std::cout << "Token: DESLIGAR" << std::endl; 
    return DESLIGAR; 
}
"com"                 { std::cout << "Token: COM" << std::endl; return COM; }
"frequencia"          { std::cout << "Token: FREQUENCIA" << std::endl; return FREQUENCIA; }
"resolucao"           { std::cout << "Token: RESOLUCAO" << std::endl; return RESOLUCAO; }
"valor"               { std::cout << "Token: VALOR" << std::endl; return VALOR; }

"=="   { std::cout << "Token: IGUAL_IGUAL" << std::endl; return IGUAL_IGUAL; }
"!="   { std::cout << "Token: DIFERENTE" << std::endl; return DIFERENTE; }
"<="   { std::cout << "Token: MENOR_IGUAL" << std::endl; return MENOR_IGUAL; }
">="   { std::cout << "Token: MAIOR_IGUAL" << std::endl; return MAIOR_IGUAL; }
"="                     { 
    std::cout << "Token: IGUAL" << std::endl; 
    return IGUAL; 
}
":"                     { 
    std::cout << "Token: DOIS_PONTOS" << std::endl; 
    return DOIS_PONTOS; 
}
";"                     { 
    std::cout << "Token: PONTO_VIRGULA" << std::endl; 
    return PONTO_VIRGULA; 
}

"\+"                 { std::cout << "Token: MAIS" << std::endl; return MAIS; }
"-"                   { std::cout << "Token: MENOS" << std::endl; return MENOS; }
"\*"                 { std::cout << "Token: VEZES" << std::endl; return VEZES; }
"/"                   { std::cout << "Token: DIV" << std::endl; return DIV; }

">"                   { std::cout << "Token: MAIOR" << std::endl; return MAIOR; }
"<"                   { std::cout << "Token: MENOR" << std::endl; return MENOR; }

"\("                 { return '('; }
"\)"                 { return ')'; }
","                   { std::cout << "Token: VIRGULA" << std::endl; return VIRGULA; }

 

[0-9]+                  { 
    yylval.valor_inteiro = atoi(yytext);  // Converte o texto para inteiro
    std::cout << "Token: NUMERO, Valor: " << yylval.valor_inteiro << std::endl;
    return NUMERO; 
}

\"[^\"]*\"              { 
    std::cout << "Token: STRING_LIT, Valor: " << yytext << std::endl; 
    return STRING_LIT; 
}

[a-zA-Z_][a-zA-Z0-9_]*  { 
    std::cout << "Token: IDENTIFICADOR, Valor: " << yytext << std::endl; 
    return IDENTIFICADOR; 
}

"//".*                  { /* Ignora comentários */ }

[ \t\r]+                { /* Ignora espaços e tabulações */ }

\n                      { return NOVA_LINHA; }

.                       { 
     std::cerr << "Erro: caractere inválido " << yytext << std::endl;
    return ERRO; 
}

%%

int yywrap() {
    return 1; // Indica que não há mais entradas para processar
}

int main() {
    yyFlexLexer lexer;  // Cria uma instância do analisador léxico
    int token;
    
    // Enquanto houver tokens para processar
    while ((token = lexer.yylex()) != 0) {
        // O token já foi impresso pelas regras no Flex
    }
    
    return 0;
}
