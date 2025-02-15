#include <Arduino.h>
#include <WiFi.h>

// ========== Variáveis Globais ==========
int ledPin;
int brilho;
int vermelho;
bool botao;
bool estadoBotao;
int ssid;
int senha;


void setup() {
  pinMode(ledPin, OUTPUT);
  pinMode(botao, INPUT);
  digitalWrite(ledPin, HIGH);
  digitalWrite(ledPin, LOW);
  estadoBotao = digitalRead(botao);
}

void loop() {
}
