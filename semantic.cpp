#include "semantic.h"
#include <iostream>
#include <unordered_map>
#include <string>

/**
 * @brief Estrutura para manter informações de cada variável
 *        no contexto da análise semântica (tabela de símbolos).
 * 
 * Você pode simplesmente usar VarDecl, mas às vezes 
 * há dados extras. Aqui está um exemplo simples.
 */
struct SymbolInfo {
    VarType type;
    bool isPin;
    bool isPWM;
    std::string pinMode; // "saida" ou "entrada"

    SymbolInfo() : type(VAR_UNDEFINED), isPin(false), isPWM(false) {}
};

/**
 * @brief Tabela de símbolos: nome da var -> informações
 */
static std::unordered_map<std::string, SymbolInfo> symbolTable;

/**
 * @brief Funções auxiliares de verificação de cada tipo de comando
 */
static void checkCommand(const Command& cmd);
static void checkAssign(const Command& cmd);
static void checkConfigPin(const Command& cmd);
static void checkConfigPwm(const Command& cmd);
static void checkPwmAdjust(const Command& cmd);
static void checkDigital(const Command& cmd);
static void checkLerDigital(const Command& cmd);
static void checkLerAnalogico(const Command& cmd);

/**
 * @brief Função principal de Análise Semântica
 */
void semanticAnalysis(ASTProgram& program) {
    symbolTable.clear();

    // 1) Registrar cada declaração de variável na tabela de símbolos
    for (auto &decl : program.declarations) {
        // Verifica se a variável já existe
        if (symbolTable.find(decl.name) != symbolTable.end()) {
            std::cerr << "Erro semântico: Variável '" << decl.name 
                      << "' declarada mais de uma vez.\n";
            exit(1); // ou trate de modo a continuar procurando erros
        }

        // Cria SymbolInfo com base em VarDecl
        SymbolInfo info;
        info.type = decl.type;       // ex. VAR_INTEIRO, VAR_TEXTO, etc.
        info.isPin = decl.isPin;     // false inicialmente
        info.isPWM = decl.isPWM;     // false inicialmente
        info.pinMode = decl.pinMode; // ""

        symbolTable[decl.name] = info;
    }

    // 2) Percorrer blocos "config" e "repita" checando comandos
    for (auto &cmd : program.configCommands) {
        checkCommand(cmd);
    }

    for (auto &cmd : program.repitaCommands) {
        checkCommand(cmd);
    }

    std::cout << "Análise semântica concluída sem erros!\n";
}

/**
 * @brief Decide qual verificação chamar, dependendo do cmdType
 */
static void checkCommand(const Command& cmd) {
    switch(cmd.cmdType) {
        case CMD_ASSIGN:
            checkAssign(cmd);
            break;
        case CMD_CONFIG_PIN:
            checkConfigPin(cmd);
            break;
        case CMD_CONFIG_PWM:
            checkConfigPwm(cmd);
            break;
        case CMD_PWM_ADJUST:
            checkPwmAdjust(cmd);
            break;
        case CMD_LIGAR:
        case CMD_DESLIGAR:
            checkDigital(cmd);
            break;
        case CMD_LER_DIGITAL:
            checkLerDigital(cmd);
            break;
        case CMD_LER_ANALOGICO:
            checkLerAnalogico(cmd);
            break;
        // Se quiser WiFi, HTTP, Serial etc. com checagens adicionais
        // case CMD_WIFI_CONNECT: ...
        // case CMD_ENVIAR_HTTP:  ...
        // etc.
        default:
            // Por enquanto, sem checagem específica
            break;
    }
}

/**
 * @brief Verifica atribuição: "ledPin = 2;"
 *        - Se varName existe na tabela
 *        - Se tipo é compatível
 */
static void checkAssign(const Command& cmd) {
    auto it = symbolTable.find(cmd.varName);
    if (it == symbolTable.end()) {
        std::cerr << "Erro semântico: Variável '" 
                  << cmd.varName << "' não foi declarada.\n";
        exit(1);
    }

    // Se quiser verificar se a varName é "inteiro" mas o cmd.expr é string...
    // Lembre-se que cmd.expr é do tipo string. 
    // Você teria que fazer uma lógica de "é um literal numérico?" ou "identificador?" etc.
    // Exemplo simplificado:
    if (it->second.type == VAR_INTEIRO) {
        // Você poderia checar se cmd.expr tem formato numérico
        // ou se é uma outra var do tipo inteiro.
        // Exemplo raso:
        if (cmd.expr.size() > 0 && cmd.expr[0] == '"') {
            std::cerr << "Erro semântico: Atribuição de texto em variável inteira '"
                      << cmd.varName << "'\n";
            exit(1);
        }
    }

    // etc.
}

/**
 * @brief Verifica se "configurar ledPin como saida"
 *        - Se ledPin foi declarado
 *        - Marca isPin=true; pinMode="saida"
 */
static void checkConfigPin(const Command& cmd) {
    auto it = symbolTable.find(cmd.pin);
    if (it == symbolTable.end()) {
        std::cerr << "Erro semântico: Variável '" 
                  << cmd.pin << "' não foi declarada.\n";
        exit(1);
    }
    // Marca como pino
    it->second.isPin = true;
    it->second.pinMode = cmd.pinMode; // "saida" ou "entrada"
}

/**
 * @brief Verifica se "configurarPWM ledPin com freq e resol"
 *        - Se ledPin foi declarado
 *        - Marca isPWM=true
 */
static void checkConfigPwm(const Command& cmd) {
    auto it = symbolTable.find(cmd.pin);
    if (it == symbolTable.end()) {
        std::cerr << "Erro semântico: Variável '"
                  << cmd.pin << "' não foi declarada.\n";
        exit(1);
    }
    it->second.isPWM = true;
}

/**
 * @brief Verifica se "ajustarPWM ledPin com valor X"
 *        - Se ledPin existe
 *        - Se isPWM=true antes de usar
 */
static void checkPwmAdjust(const Command& cmd) {
    auto it = symbolTable.find(cmd.pin);
    if (it == symbolTable.end()) {
        std::cerr << "Erro semântico: Variável '" 
                  << cmd.pin << "' não foi declarada.\n";
        exit(1);
    }
    if (!it->second.isPWM) {
        std::cerr << "Erro semântico: Pino '"
                  << cmd.pin << "' não foi configurado como PWM antes de usar 'ajustarPWM'.\n";
        exit(1);
    }
}

/**
 * @brief Verifica "ligar ledPin;" ou "desligar ledPin;"
 *        - Se ledPin existe
 *        - Se isPin=true e pinMode="saida"
 */
static void checkDigital(const Command& cmd) {
    auto it = symbolTable.find(cmd.digitalPin);
    if (it == symbolTable.end()) {
        std::cerr << "Erro semântico: Variável '" 
                  << cmd.digitalPin << "' não foi declarada.\n";
        exit(1);
    }
    if (!it->second.isPin) {
        std::cerr << "Erro semântico: '" << cmd.digitalPin
                  << "' não foi configurado como pino.\n";
        exit(1);
    }
    if (it->second.pinMode != "saida") {
        std::cerr << "Erro semântico: '" << cmd.digitalPin 
                  << "' não está como 'saida'.\n";
        exit(1);
    }
}

static void checkLerDigital(const Command &cmd) {
    // 1) Verifique se varName existe:
    auto itVar = symbolTable.find(cmd.varName);
    if (itVar == symbolTable.end()) {
        std::cerr << "Erro semântico: variável de destino '" 
                  << cmd.varName << "' não foi declarada.\n";
        exit(1);
    }
    // 2) Verifique se pin existe e está configurado como entrada:
    auto itPin = symbolTable.find(cmd.pin);
    if (itPin == symbolTable.end()) {
        std::cerr << "Erro semântico: pino '" 
                  << cmd.pin << "' não foi declarado.\n";
        exit(1);
    }
    if (!itPin->second.isPin || itPin->second.pinMode != "entrada") {
        std::cerr << "Erro semântico: 'lerDigital' requer pino configurado como entrada.\n";
        exit(1);
    }
}

static void checkLerAnalogico(const Command &cmd) {
    // Mesmo processo, mas se você tiver "entradaAnalog" ou algo do tipo:
    auto itVar = symbolTable.find(cmd.varName);
    if (itVar == symbolTable.end()) {
        std::cerr << "Erro semântico: variável de destino '" 
                  << cmd.varName << "' não foi declarada.\n";
        exit(1);
    }
    auto itPin = symbolTable.find(cmd.pin);
    if (itPin == symbolTable.end()) {
        std::cerr << "Erro semântico: pino '" 
                  << cmd.pin << "' não foi declarado.\n";
        exit(1);
    }
    // Se sua DSL exige "entradaAnalog" ou "entrada" normal, verifique aqui.
    if (!itPin->second.isPin /* ou itPin->second.pinMode != "entradaAnalog" */ ) {
        std::cerr << "Erro semântico: 'lerAnalogico' requer pino configurado como entrada analog.\n";
        exit(1);
    }
}

