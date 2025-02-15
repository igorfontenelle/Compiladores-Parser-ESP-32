#include "codegen.h"
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
    // Se quiser outras libs, inclua aqui.

    out << "\n// ========== Variáveis Globais ==========\n";
    // 2) Declarações de variáveis
    for (auto &decl : program.declarations) {
        std::string cppType = varTypeToCpp(decl.type);
        // Exemplo: "int ledPin;"
        out << cppType << " " << decl.name << ";\n";
    }

    // 3) Gera a função setup() - com base em configCommands
    out << "\nvoid setup() {\n";
    // Se quiser, comece com "Serial.begin(115200);" ou algo do tipo
    // out << "  Serial.begin(115200);\n";

    // Percorra os comandos do bloco config
    for (auto &cmd : program.configCommands) {
        generateCommand(out, cmd);
    }

    out << "}\n";

    // 4) Gera a função loop() - com base em repitaCommands
    out << "\nvoid loop() {\n";
    // Percorra os comandos do bloco repita
    for (auto &cmd : program.repitaCommands) {
        generateCommand(out, cmd);
    }

    out << "}\n";

    out.close();
    std::cout << "Código C++ gerado com sucesso em " << outputFilename << "\n";
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
            // Exemplo: "configurarPWM ledPin com freq=5000, resol=8"
            // No Arduino/ESP32 real, precisamos do ledcSetup e ledcAttachPin
            // Exemplo (usando canal 0 fixo - poderia ficar mais elaborado):
            out << "  ledcSetup(0, " << cmd.freq 
                << ", " << cmd.resol << ");\n";
            out << "  ledcAttachPin(" << cmd.pin << ", 0);\n";
        } break;

        case CMD_PWM_ADJUST: {
            // Exemplo: "ajustarPWM ledPin com valor brilho"
            // => "ledcWrite(0, brilho);"
            out << "  ledcWrite(" << cmd.pin << ", " << cmd.valueExpr << ");\n";
        } break;

        case CMD_LIGAR: {
            // Exemplo: "ligar ledPin;" => "digitalWrite(ledPin, HIGH);"
            out << "  digitalWrite(" << cmd.digitalPin << ", HIGH);\n";
        } break;

        case CMD_DESLIGAR: {
            // Exemplo: "desligar ledPin;" => "digitalWrite(ledPin, LOW);"
            out << "  digitalWrite(" << cmd.digitalPin << ", LOW);\n";
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
