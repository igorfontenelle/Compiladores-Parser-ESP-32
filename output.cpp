#include <Arduino.h>
#include <WiFi.h>

// ========== Variáveis Globais ==========
int ledPin;
int brilho;
bool botao;
bool estadoBotao;
String ssid;
String senha;

const int canal_ledPin = 0;
const int freq_ledPin  = 5000;
const int resol_ledPin = 8;


void setup() {
  ledPin = 2;
  pinMode(ledPin, OUTPUT);
  botao = 4;
  pinMode(botao, INPUT);
  brilho = (100+((20*2)));
  ssid = "MinhaRedeWiFi";
  senha = "SenhaSegura";
  ledcSetup(canal_ledPin, freq_ledPin, resol_ledPin);
  ledcAttachPin(ledPin, canal_ledPin);
}

void loop() {
  estadoBotao = digitalRead(botao);
  brilho = (brilho+1);
  ledcWrite(canal_ledPin, brilho);
  delay(1000);
  brilho = 0;
  ledcWrite(canal_ledPin, brilho);
  delay(1000);
}
