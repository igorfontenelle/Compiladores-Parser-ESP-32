#ifndef CODEGEN_H
#define CODEGEN_H

#include <string>
#include "ast.h"

/**
 * @brief Gera um arquivo C++ (Arduino/ESP32) a partir do ASTProgram.
 * @param program O AST do programa (contém declarações e comandos).
 * @param outputFilename Caminho/nome do arquivo .cpp a ser gerado.
 */
void generateCode(ASTProgram& program, const std::string& outputFilename);

#endif // CODEGEN_H
