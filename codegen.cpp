#include "codegen.h"
#include <map>
#include <tuple>
#include <fstream>
#include <iostream>

/**
 * @brief Auxiliar: converte VarType para string C++ (int, String, bool)
 */
static std::string varTypeToCpp(VarType t) {
    switch(t) {
        case VAR_INTEIRO:
            return "int";
        case VAR_TEXTO:
            return "String";
        case VAR_BOOLEANO:
            return "bool";
        default:
            // caso undefined
            return "int"; // fallback
    }
}

// Precisamos de um contador de canais e uma estrutura para
// armazenar (canal,freq,resol)
static std::map<std::string, std::tuple<int,int,int>> pwmData;
static int nextChannel = 0;

// Prototipos
static void generateGlobals(std::ofstream &out, ASTProgram &program);
static void generateSetup(std::ofstream &out, ASTProgram &program);
static void generateLoop(std::ofstream &out, ASTProgram &program);

/**
 * @brief Função auxiliar que gera a tradução de cada comando
 */
static void generateCommand(std::ofstream &out, const Command &cmd);

/**
 * @brief Função principal de geração de código
 */
void generateCode(ASTProgram& program, const std::string& outputFilename) {
    std::ofstream out(outputFilename);
    if(!out.is_open()) {
        std::cerr << "Erro ao criar arquivo " << outputFilename << "\n";
        return;
    }

    // 1) Includes
    out << "#include <Arduino.h>\n";
    out << "#include <WiFi.h>\n"; 

    // 2) Gera variaveis globais
    generateGlobals(out, program);

    // 3) Gera setup()
    out << "\nvoid setup() {\n";
    generateSetup(out, program);
    out << "}\n";

    // 4) Gera loop()
    out << "\nvoid loop() {\n";
    generateLoop(out, program);
    out << "}\n";

    out.close();
    std::cout << "Código C++ gerado em " << outputFilename << std::endl;
}

static void generateGlobals(std::ofstream &out, ASTProgram &program) {
    // Limpa estruturas
    pwmData.clear();
    nextChannel = 0;

    // 1) Primeiro, varrer configCommands para encontrar CMD_CONFIG_PWM
    for (auto &cmd : program.configCommands) {
        if (cmd.cmdType == CMD_CONFIG_PWM) {
            auto it = pwmData.find(cmd.pin);
            if (it == pwmData.end()) {
                pwmData[cmd.pin] = std::make_tuple(nextChannel, cmd.freq, cmd.resol);
                nextChannel++;
            }
            // Se quiser permitir reconfig do pino, atualize...
        }
    }

    // 2) Agora imprime as variáveis do AST
    out << "\n// ========== Variáveis Globais ==========\n";
    for (auto &decl : program.declarations) {
        std::string cppType = varTypeToCpp(decl.type);
        out << cppType << " " << decl.name << ";\n";
    }

    // 3) Imprime as const do PWM
    for (auto &kv : pwmData) {
        auto &pinName = kv.first;
        auto [ch, fr, rs] = kv.second;
        out << "\nconst int canal_" << pinName << " = " << ch << ";";
        out << "\nconst int freq_" << pinName  << "  = " << fr << ";";
        out << "\nconst int resol_" << pinName << " = " << rs << ";\n";
    }
    out << "\n";
}

static void generateSetup(std::ofstream &out, ASTProgram &program) {
    // Percorrer configCommands
    for (auto &cmd : program.configCommands) {
        generateCommand(out, cmd);
    }

    // Depois de processar, declarar as const para PWM:
    // Precisamos imprimir: 
    // const int canal_pinX = ...
    // const int freq_pinX  = ...
    // const int resol_pinX = ...
    // ou inverso, se quiser em outro local.
}

static void generateLoop(std::ofstream &out, ASTProgram &program) {
    for (auto &cmd : program.repitaCommands) {
        generateCommand(out, cmd);
    }
}

/**
 * @brief Gera a linha de código C++ correspondente a um Command específico.
 */
static void generateCommand(std::ofstream &out, const Command &cmd) {
    switch(cmd.cmdType) {
        case CMD_ASSIGN: {
            // Exemplo:  ledPin = 2;
            // Se cmd.varName="ledPin" e cmd.expr="2"
            out << "  " << cmd.varName << " = " << cmd.expr << ";\n";
        } break;

        case CMD_CONFIG_PIN: {
            // Exemplo: config pino:   pinMode(ledPin, OUTPUT);
            // Se cmd.pinMode="saida", use "OUTPUT"
            // Se cmd.pinMode="entrada", use "INPUT"
            std::string mode = "OUTPUT";
            if (cmd.pinMode == "entrada") {
                mode = "INPUT";
            }
            out << "  pinMode(" << cmd.pin << ", " << mode << ");\n";
        } break;

        case CMD_CONFIG_PWM: {
            // canal/freq/resol já está em pwmData, não precisamos atribuir de novo
            // Basta imprimir as chamadas usando as const
            out << "  ledcSetup(canal_" << cmd.pin << ", freq_" 
            << cmd.pin << ", resol_" << cmd.pin << ");\n";
            out << "  ledcAttachPin(" << cmd.pin << ", canal_" << cmd.pin << ");\n";
        } break;

        case CMD_PWM_ADJUST: {
            auto it = pwmData.find(cmd.pin);
            if (it == pwmData.end()) {
                // caso o parser permitir configPWM tardio, ou gera erro...
                // Mas provavelmente no semântico já geraria erro.
            }
            out << "  ledcWrite(" 
                << "canal_" << cmd.pin << ", " << cmd.valueExpr << ");\n";
        } break;

        case CMD_LIGAR: {
            // Exemplo: "ligar ledPin;" => "digitalWrite(ledPin, HIGH);"
            out << "  digitalWrite(" << cmd.digitalPin << ", HIGH);\n";
        } break;

        case CMD_DESLIGAR: {
            // Exemplo: "desligar ledPin;" => "digitalWrite(ledPin, LOW);"
            out << "  digitalWrite(" << cmd.digitalPin << ", LOW);\n";
        } break;

        case CMD_LER_DIGITAL: {
            // Exemplo: "estadoBotao = digitalRead(botao);"
            out << "  " << cmd.varName << " = digitalRead(" << cmd.pin << ");\n";
        } break;
        
        case CMD_LER_ANALOGICO: {
            // Exemplo: "sensorValor = analogRead(sensor);"
            out << "  " << cmd.varName << " = analogRead(" << cmd.pin << ");\n";
        } break;

        case CMD_WIFI_CONNECT: {
            // Exemplo: "conectarWifi ssid senha;"
            // => 
            // WiFi.begin(ssid.c_str(), password.c_str());
            out << "  WiFi.begin(" << cmd.ssid << ".c_str(), " 
                << cmd.password << ".c_str());\n";
            out << "  while(WiFi.status() != WL_CONNECTED) {\n";
            out << "    delay(500);\n";
            out << "  }\n";
        } break;

        case CMD_WAIT: {
            // Exemplo: "esperar 1000;" => "delay(1000);"
            out << "  delay(" << cmd.waitTime << ");\n";
        } break;

        case CMD_ENVIAR_HTTP: {
            // Exemplo: "enviarHttp \"http://exemplo.com\" \"dados=123\";"
            // => uso de bibliotecas HTTP no ESP32
            // Exemplo rudimentar:
            out << "  {\n";
            out << "    HTTPClient http;\n";
            out << "    http.begin(" << cmd.httpUrl << ");\n";
            out << "    http.addHeader(\"Content-Type\", "
                << "\"application/x-www-form-urlencoded\");\n";
            out << "    int httpCode = http.POST(" << cmd.httpData << ");\n";
            out << "    http.end();\n";
            out << "  }\n";
        } break;

        case CMD_ESCREVER_SERIAL: {
            // Exemplo: "escreverSerial \"Mensagem\";" => "Serial.println(\"Mensagem\");"
            out << "  Serial.println(" << cmd.serialMsg << ");\n";
        } break;

        case CMD_LER_SERIAL: {
            // Exemplo: "lerSerial;" => "String valor = Serial.readString();"
            out << "  {\n";
            out << "    String valor = Serial.readString();\n";
            out << "    // se quiser fazer algo com 'valor'\n";
            out << "  }\n";
        } break;

        case CMD_IF:
        case CMD_WHILE:
            // Se sua AST não guarda sub-blocos, pode ser que
            // você não gere nada específico, ou print um comentário.
            out << "  // (IF/WHILE) Comandos não expandidos\n";
            break;

        default:
            // se não houver nada definido, ignore.
            break;
    }
}
