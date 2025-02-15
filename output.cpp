#include <Arduino.h>
#include <WiFi.h>

// ========== Variáveis Globais ==========
int ledPin;
int brilho;
int ssid;
int senha;
int testePin;

void setup() {
  ledPin = 2;
  testePin = 3;
  ssid = "MinhaRedeWiFi";
  senha = "MinhaSenhaWiFi";
  pinMode(ledPin, OUTPUT);
  ledcSetup(0, 5000, 8);
  ledcAttachPin(testePin, 0);
  WiFi.begin(ssid.c_str(), senha.c_str());
  while(WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
}

void loop() {
  brilho = 128;
  ledcWrite(testePin, brilho);
  delay(1000);
  brilho = 0;
  ledcWrite(testePin, brilho);
  delay(1000);
}
