# ESP32 MQTT Dock Firmware

Firmware contoh ini menerima perintah unlock dari Flutter lewat MQTT.

Kamu bisa upload lewat **Arduino IDE** memakai file [arduino_ide/velocy_dock_mqtt.ino](arduino_ide/velocy_dock_mqtt.ino).

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

- Relay signal -> `GPIO 23`
- Relay VCC -> `5V` atau sesuai modul relay
- Relay GND -> `GND`
- Pastikan supply solenoid/lock terpisah dan cukup arusnya

## Setup cepat

1. Buka file [arduino_ide/velocy_dock_mqtt.ino](arduino_ide/velocy_dock_mqtt.ino) di Arduino IDE.
2. Install library `PubSubClient` dan `ArduinoJson` lewat Library Manager.
3. Pilih board `ESP32 Dev Module` dan port COM yang benar.
4. Isi `WIFI_SSID`, `WIFI_PASSWORD`, dan `MQTT_BROKER_HOST` di sketch.
5. Sesuaikan `DEVICE_DOCK_CODE` dengan dock yang dipakai.
6. Upload ke ESP32.

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
flutter run --dart-define=USE_MOCK_DOCK=false --dart-define=MQTT_BROKER_HOST=192.168.1.10 --dart-define=MQTT_BROKER_PORT=1883 --dart-define=MQTT_TOPIC_PREFIX=velocy/dock
```

Pastikan `dockCode` di Flutter sama dengan `DEVICE_DOCK_CODE` di firmware ESP32.
