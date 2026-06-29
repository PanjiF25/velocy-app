#include <Arduino.h>

const int DATA_OUT_PIN = 25; 
const int LATCH_PIN    = 26; 
const int CLOCK_PIN    = 32; 

void updateRelays(byte val) {
  digitalWrite(LATCH_PIN, LOW);
  shiftOut(DATA_OUT_PIN, CLOCK_PIN, MSBFIRST, val);
  digitalWrite(LATCH_PIN, HIGH);
}

void setup() {
  Serial.begin(115200);
  pinMode(CLOCK_PIN, OUTPUT);
  pinMode(DATA_OUT_PIN, OUTPUT);
  pinMode(LATCH_PIN, OUTPUT);

  // Matikan di awal
  updateRelays(0xFF); // 0xFF (Semua HIGH) biasanya bikin relay Active Low mati.
  
  delay(2000);
  Serial.println("\n\n=========================================");
  Serial.println("🚀 ESP32 BERHASIL BOOTING (NYALA)");
  Serial.println("=========================================");
}

void loop() {
  // Kita tes Q0 (Dock 1) dengan mengirim logika LOW (0)
  Serial.println("\n[1] MENGIRIM LOW (0V) KE DOCK 1 -> (Harusnya Relay CETEK/Nyala)");
  updateRelays(0xFE); // 0xFE = 11111110 (Hanya Q0 yang LOW)
  delay(3000);
  
  // Matikan lagi dengan logika HIGH (1)
  Serial.println("[2] MENGIRIM HIGH (5V) KE DOCK 1 -> (Harusnya Relay MATI)");
  updateRelays(0xFF); // 0xFF = 11111111 (Semua HIGH)
  delay(3000);
}
