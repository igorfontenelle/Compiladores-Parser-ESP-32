#ifndef SEMANTIC_H
#define SEMANTIC_H

#include "ast.h"

/**
 * @brief Executa a análise semântica de todo o programa.
 * 
 * - Verifica declarações duplicadas
 * - Cria tabela de símbolos
 * - Valida o uso de cada comando (pinos, pwm, etc.)
 * 
 * @param program Referência ao ASTProgram, populado pelo parser.
 */
void semanticAnalysis(ASTProgram& program);

#endif // SEMANTIC_H
