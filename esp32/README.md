# ESP32 MQTT Dock Firmware

Firmware contoh ini menerima perintah unlock dari Flutter lewat MQTT.

Kalau kamu baru mulai dari nol, baca dulu panduan lengkap di [../MQTT_SETUP.md](../MQTT_SETUP.md).

Kalau kamu pakai **Arduino IDE**, upload file [arduino_ide/velocy_dock_mqtt.ino](arduino_ide/velocy_dock_mqtt.ino).

## Topic

- Subscribe: `velocy/dock/+/control`
- Publish status: `velocy/dock/<dockCode>/status`

Contoh payload unlock:

```json
{
  "action": "UNLOCK",
  "qrValue": "QR-123",
  "bikeCode": "VLY-002",
  "dockCode": "A1",
  "stationName": "Teknik Informatika"
}
```

## Wiring

- Relay signal -> `GPIO 26`
- Relay VCC -> `5V` dari step-down
- Relay GND -> `GND` dari step-down
- Pastikan supply solenoid/lock terpisah dan cukup arusnya
- Kalau mode yang dipakai adalah `NC`, pastikan kabel merah solenoid masuk ke terminal `NC` dan kabel hitam ke ground utama

## Setup cepat

1. Buka file [arduino_ide/velocy_dock_mqtt.ino](arduino_ide/velocy_dock_mqtt.ino) di Arduino IDE.
2. Install library `PubSubClient` dan `ArduinoJson` lewat Library Manager.
3. Pilih board `ESP32 Dev Module` dan port COM yang benar.
4. Isi `WIFI_SSID` dan `WIFI_PASSWORD` di sketch kalau belum pakai nilai kamu sendiri.
5. Sesuaikan `DEVICE_DOCK_CODE` dengan dock yang dipakai.
6. Upload ke ESP32.
7. Untuk tes relay, buka Serial Monitor dan kirim `OPEN`.

## Test cepat tanpa Flutter

Buka Serial Monitor lalu kirim:

```text
PING
STATUS
OPEN
```

## Cocok dengan app Flutter

Jalankan app Flutter dengan:

```bash
flutter run --dart-define=USE_MOCK_DOCK=false --dart-define=MQTT_BROKER_HOST=ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud --dart-define=MQTT_BROKER_PORT=8883 --dart-define=MQTT_SECURE=true --dart-define=MQTT_TOPIC_PREFIX=velocy/dock
```

Pastikan `dockCode` di Flutter sama dengan `DEVICE_DOCK_CODE` di firmware ESP32.

Kalau broker kamu pakai TLS, Flutter sudah bisa diberi `--dart-define=MQTT_SECURE=true`, dan sketch `.ino` di repo ini juga sudah disiapkan untuk TLS.
