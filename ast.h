#ifndef AST_H
#define AST_H

#include <string>
#include <vector>

/* -------------------------------------------------
 * 1) Tipo de variável
 * ------------------------------------------------- */
enum VarType {
    VAR_INTEIRO,
    VAR_TEXTO,
    VAR_BOOLEANO,
    VAR_UNDEFINED
};

/* -------------------------------------------------
 * 2) Estrutura de Declaração de Variável
 * ------------------------------------------------- */
struct VarDecl {
    std::string name;   // nome da variável, ex. "ledPin"
    VarType type;       // VAR_INTEIRO, VAR_TEXTO, etc.

    // Flags de contexto (úteis na análise semântica):
    bool isPin;         // se foi configurada como pino (entrada/saída)
    bool isPWM;         // se foi configurada como PWM
    std::string pinMode; // "saida", "entrada", etc.

    // Construtor padrão (inicializa flags)
    VarDecl() : type(VAR_UNDEFINED), isPin(false), isPWM(false) {}
};

/* -------------------------------------------------
 * 3) Tipos de Comando
 * ------------------------------------------------- */
enum CmdType {
    CMD_ASSIGN,          // ex.:  ledPin = 2;
    CMD_CONFIG_PIN,      // ex.:  configurar ledPin como saida;
    CMD_CONFIG_PWM,      // ex.:  configurarPWM ledPin com freq e resol
    CMD_PWM_ADJUST,      // ex.:  ajustarPWM ledPin com valor brilho;
    CMD_WIFI_CONNECT,    // ex.:  conectarWifi ssid senha;
    CMD_WAIT,            // ex.:  esperar 1000;
    CMD_LIGAR,           // ex.:  ligar ledPin;
    CMD_DESLIGAR,        // ex.:  desligar ledPin;
    CMD_ENVIAR_HTTP,     // ex.:  enviarHttp "url" "dados";
    CMD_ESCREVER_SERIAL, // ex.:  escreverSerial "msg";
    CMD_LER_SERIAL,      // ex.:  lerSerial;
    CMD_IF,              // ex.:  se expr entao ... fim
    CMD_WHILE,           // ex.:  enquanto expr ... fim
    // etc. Adicione conforme sua linguagem
    CMD_UNDEFINED
};

/* -------------------------------------------------
 * 4) Estrutura de Comando (Command)
 * ------------------------------------------------- */
struct Command {
    CmdType cmdType;  // qual tipo de comando?

    // Campos genéricos. Nem todos serão usados em todo comando, 
    // mas isso simplifica se você não quiser uma struct por comando
    std::string varName;     // para assignment: ex.: "ledPin"
    std::string expr;        // para assignment ou qualquer expression (ex.: "2", "brilho", "128", etc.)

    // Para config pino
    std::string pin;         // ex.: "ledPin"
    std::string pinMode;     // "saida" ou "entrada"

    // Para config PWM
    int freq;                // ex.: 5000
    int resol;               // ex.: 8
    // Ajuste de PWM
    std::string valueExpr;   // ex.: "brilho", "128", etc.

    // Wi-Fi
    std::string ssid;
    std::string password;

    // Esperar (delay)
    std::string waitTime;    // ex.: "1000"

    // Ligar/Desligar
    std::string digitalPin;  // ex.: "ledPin"

    // Envio HTTP
    std::string httpUrl;
    std::string httpData;

    // Serial
    std::string serialMsg;

    // IF/WHILE (apenas exemplificando; se quiser sub-blocos, precisa vector<Command>)
    std::string conditionExpr;

    // Construtor default
    Command() : cmdType(CMD_UNDEFINED), freq(0), resol(0) {}
};

/* -------------------------------------------------
 * 5) Estrutura principal do Programa
 * ------------------------------------------------- */
struct ASTProgram {
    // Lista de variáveis declaradas
    std::vector<VarDecl> declarations;

    // Bloco "config"
    std::vector<Command> configCommands;

    // Bloco "repita" (loop principal)
    std::vector<Command> repitaCommands;

    // Se precisar de IF aninhado ou WHILE aninhado,
    // pode guardar sub-blocos, mas isso é opcional 
    // num design mais simples.

    // Construtor default
    ASTProgram() {}
};

#endif // AST_H
