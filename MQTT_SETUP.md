# MQTT Setup Guide

Panduan ini menjelaskan setup MQTT dari nol sampai aplikasi Flutter dan ESP32 bisa dipakai untuk membuka solenoid dock.

## 1. Gambaran alur

Alurnya seperti ini:

1. Flutter kirim perintah `UNLOCK` ke broker MQTT.
2. Broker meneruskan pesan ke topik kontrol dock.
3. ESP32 subscribe topik kontrol itu.
4. ESP32 menerima pesan, lalu menyalakan relay/solenoid selama beberapa detik.
5. ESP32 publish status ke topik status.

## 2. Komponen yang dibutuhkan

- Satu broker MQTT yang bisa diakses oleh Flutter dan ESP32.
- ESP32 + modul relay + solenoid lock.
- Jaringan Wi-Fi untuk ESP32.
- App Flutter yang sudah terhubung ke Firebase dan MQTT.

## 3. Pilih broker

Pilih salah satu model berikut.

### Opsi A: Broker lokal

Cocok untuk tes di rumah/lab yang sama.

- Broker berjalan di laptop, PC, atau Raspberry Pi.
- Semua device harus berada di jaringan yang sama.
- Contoh host: `192.168.1.10`
- Port umum: `1883`

### Opsi B: Broker cloud atau VPS

Cocok kalau temanmu ikut tes dari luar jaringan lokal.

- Broker berjalan di server publik.
- Flutter dan ESP32 sama-sama connect ke broker itu lewat internet.
- Contoh host HiveMQ: `ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud`
- Port umum: `1883` untuk plain MQTT, atau `8883` untuk TLS.

Untuk koneksi dari jaringan yang berbeda-beda, termasuk data seluler, broker cloud adalah pilihan yang paling masuk akal. Rekomendasi paling gampang untuk mulai adalah HiveMQ Cloud.

### 3.1 Cara paling gampang untuk broker lokal: Mosquitto

Kalau kamu cuma mau tes di laptop/PC sendiri atau di satu jaringan Wi-Fi, pakai Mosquitto.

Langkah di Windows:

1. Install Mosquitto dari situs resminya.
2. Saat instalasi, ikutkan juga service dan command line tools.
3. Buka PowerShell atau CMD.
4. Jalankan broker:

```bash
mosquitto -v
```

5. Kalau mau broker bisa diakses dari device lain di jaringan yang sama, pastikan firewall mengizinkan port `1883`.
6. Catat IP laptop/PC kamu, misalnya `192.168.1.10`.

Kalau broker jalan di laptop kamu, maka:

- Flutter pakai host itu.
- ESP32 pakai host itu.
- Temanmu juga pakai host itu selama masih bisa akses jaringan yang sama.

Contoh tes cepat broker lokal:

```bash
mosquitto_sub -h 192.168.1.10 -t "velocy/dock/+/status" -v
```

Di terminal lain:

```bash
mosquitto_pub -h 192.168.1.10 -t "velocy/dock/A1/control" -m "{\"action\":\"UNLOCK\"}"
```

Kalau broker dan ESP32 sudah benar, relay harus aktif saat pesan dikirim.

### 3.2 Cara paling gampang untuk broker cloud: HiveMQ Cloud

Kalau kamu mau temanmu bisa tes dari luar rumah/lab, pakai broker cloud.

Langkah umum:

1. Buat akun di HiveMQ Cloud.
2. Buat cluster gratis.
3. Buat user/password broker.
4. Catat host broker yang diberikan, biasanya bentuknya domain.
5. Catat port yang disediakan.
6. Simpan juga kredensial login broker yang dibuat.

Biasanya broker cloud memberi dua mode:

- MQTT plain di port tertentu
- MQTT TLS di port lain

Untuk project ini, pakai TLS di port `8883` lebih cocok.

Contoh cara pakai:

- `MQTT_BROKER_HOST`: `ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud`
- `MQTT_BROKER_PORT`: `8883`
- `MQTT_USERNAME`: username broker
- `MQTT_PASSWORD`: password broker
- `MQTT_SECURE=true` kalau pakai TLS

Catatan penting: file ESP32 di repo ini sudah disiapkan untuk TLS dengan `MQTT_USE_TLS = true` dan `setInsecure()`. Itu paling cepat untuk testing. Kalau nanti mau produksi, ganti `setInsecure()` dengan CA certificate supaya verifikasi sertifikat tetap aktif.

## 4. Topik MQTT yang dipakai

Struktur topik di project ini:

- Status dock: `velocy/dock/<dockCode>/status`
- Perintah dock: `velocy/dock/<dockCode>/control`
- Subscribe wildcard di ESP32: `velocy/dock/+/control`

Contoh:

- Dock code: `A1`
- Topic control: `velocy/dock/A1/control`
- Topic status: `velocy/dock/A1/status`

## 5. Payload yang dikirim Flutter

Saat tombol mulai pinjam ditekan, Flutter mengirim JSON seperti ini:

```json
{
  "action": "UNLOCK",
  "qrValue": "QR-123",
  "bikeCode": "VLY-002",
  "dockCode": "A1",
  "stationName": "Teknik Informatika"
}
```

ESP32 hanya perlu membaca field `action`. Kalau nilainya `UNLOCK`, relay akan aktif.

## 6. Setup ESP32 dari nol

### 6.1 Install tools

- Install Arduino IDE.
- Install board support ESP32.
- Install library berikut dari Library Manager:
  - `PubSubClient`
  - `ArduinoJson`

### 6.2 Buka sketch

Buka file ini:

- [esp32/arduino_ide/velocy_dock_mqtt.ino](esp32/arduino_ide/velocy_dock_mqtt.ino)

### 6.3 Isi konfigurasi Wi-Fi dan broker

Ubah bagian ini di sketch:

```cpp
constexpr char WIFI_SSID[] = "YOUR_WIFI_SSID";
constexpr char WIFI_PASSWORD[] = "YOUR_WIFI_PASSWORD";
constexpr char MQTT_BROKER_HOST[] = "ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud";
constexpr uint16_t MQTT_BROKER_PORT = 8883;
constexpr char MQTT_USERNAME[] = "";
constexpr char MQTT_PASSWORD[] = "";
constexpr char MQTT_TOPIC_PREFIX[] = "velocy/dock";
constexpr char DEVICE_DOCK_CODE[] = "A1";
constexpr bool MQTT_USE_TLS = true;
```

Isi dengan data nyata:

- `WIFI_SSID`: nama Wi-Fi
- `WIFI_PASSWORD`: password Wi-Fi
- `MQTT_BROKER_HOST`: `ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud`
- `MQTT_BROKER_PORT`: `8883` untuk HiveMQ Cloud TLS
- `MQTT_USERNAME` dan `MQTT_PASSWORD`: isi kalau broker pakai auth
- `DEVICE_DOCK_CODE`: kode dock yang unik, misalnya `A1`
- `MQTT_USE_TLS`: aktifkan `true` untuk broker cloud

### 6.4 Wiring relay dan solenoid

Pakai skema ini kalau kamu ingin satu rangkaian yang rapi dan aman untuk test.

#### A. Jalur daya utama 12V

- Dari adaptor 12V, kabel positif masuk ke input `IN+` step-down.
- Dari adaptor 12V, kabel negatif masuk ke input `IN-` step-down.
- Dari adaptor 12V yang sama, jalur negatif juga menjadi ground utama untuk solenoid.

#### B. Jalur 5V untuk ESP32 dan relay

- Output `OUT+` step-down disambungkan ke `VIN` atau `5V` ESP32.
- Output `OUT+` step-down juga disambungkan ke `VCC` modul relay.
- Output `OUT-` step-down disambungkan ke `GND` ESP32.
- Output `OUT-` step-down juga disambungkan ke `GND` modul relay.

#### C. Jalur kontrol relay

- `GPIO 26` ESP32 disambungkan ke pin `IN1` relay.
- `IN2` relay dibiarkan kosong.

#### D. Jalur solenoid

- Kabel merah solenoid masuk ke terminal `NC` pada relay channel 1 jika kamu memang ingin mode yang sekarang kamu pakai.
- Kabel hitam solenoid disambungkan ke ground utama / negatif 12V.

Kalau perilaku lock-mu menunjukkan bahwa `NO` bikin solenoid panas terus dan `NC` hanya bereaksi sebentar lalu aman, maka gunakan `NC` seperti di atas.

#### E. Dioda proteksi

- Pasang diode `1N4007` paralel di solenoid.
- Kaki gelang perak/abu-abu diode ke kabel merah solenoid.
- Kaki hitam polos diode ke kabel hitam solenoid.

#### F. Catatan penting

- Ground step-down, ESP32, dan relay harus common.
- Solenoid jangan ambil daya dari ESP32.
- Kalau relay LED menyala tapi tidak ada bunyi click, cek dulu supply 5V ke relay dan sambungan `IN1` dari GPIO 26.
- Kalau solenoid panas terus, stop pengujian dan cek ulang terminal `NC`/`NO`.

### 6.5 Upload ke board

- Pilih board `ESP32 Dev Module`
- Pilih port COM yang benar
- Upload sketch
- Buka Serial Monitor dengan baud rate `115200`

Kalau kamu ingin tes relay tanpa MQTT, buka Serial Monitor lalu kirim `OPEN`. Relay harus click sebentar lalu kembali normal.

### 6.6 Cek koneksi ESP32

Di Serial Monitor, kamu harus lihat log seperti ini:

- `Connecting WiFi to ...`
- `Connecting MQTT to ...`
- `MQTT connected`

Kalau gagal, cek:

- SSID/password Wi-Fi
- host broker
- port broker
- username/password broker
- jaringan internet atau jaringan lokal

### 6.7 Tes manual tanpa Flutter

Di Serial Monitor, kirim perintah:

```text
PING
STATUS
OPEN
```

Hasil yang diharapkan:

- `PING` -> balasan `PONG`
- `STATUS` -> status Wi-Fi, MQTT, dan relay
- `OPEN` -> relay aktif sebentar lalu kembali idle

## 7. Setup Flutter

### 7.1 Jalankan app dengan broker lokal

Kalau broker ada di jaringan lokal:

```bash
flutter run --dart-define=USE_MOCK_DOCK=false --dart-define=MQTT_BROKER_HOST=192.168.1.10 --dart-define=MQTT_BROKER_PORT=1883 --dart-define=MQTT_TOPIC_PREFIX=velocy/dock --dart-define=MQTT_CLIENT_ID=velocy_app_test
```

### 7.2 Jalankan app dengan broker cloud

Kalau broker ada di server publik:

```bash
flutter run --dart-define=USE_MOCK_DOCK=false --dart-define=MQTT_BROKER_HOST=ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud --dart-define=MQTT_BROKER_PORT=8883 --dart-define=MQTT_SECURE=true --dart-define=MQTT_TOPIC_PREFIX=velocy/dock --dart-define=MQTT_CLIENT_ID=velocy_app_test
```

Kalau broker cloud pakai username/password, tambahkan `MQTT_USERNAME` dan `MQTT_PASSWORD` juga.

## 8. Setting di code Flutter

File yang membaca konfigurasi MQTT adalah:

- [lib/loan_summary_screen.dart](lib/loan_summary_screen.dart)
- [lib/dock_unlock_service.dart](lib/dock_unlock_service.dart)

Define yang dikenali:

- `USE_MOCK_DOCK`
- `MQTT_BROKER_HOST`
- `MQTT_BROKER_PORT`
- `MQTT_TOPIC_PREFIX`
- `MQTT_CLIENT_ID`
- `MQTT_USERNAME`
- `MQTT_PASSWORD`
- `MQTT_SECURE`

Contoh pakai auth:

```bash
flutter run --dart-define=USE_MOCK_DOCK=false --dart-define=MQTT_BROKER_HOST=ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud --dart-define=MQTT_BROKER_PORT=8883 --dart-define=MQTT_SECURE=true --dart-define=MQTT_TOPIC_PREFIX=velocy/dock --dart-define=MQTT_CLIENT_ID=velocy_app_test --dart-define=MQTT_USERNAME=USERNAME_HIVEMQ_KAMU --dart-define=MQTT_PASSWORD=PASSWORD_HIVEMQ_KAMU
```

## 9. Cara tes end-to-end

Lakukan urutan ini:

1. Nyalakan broker MQTT.
2. Sambungkan ESP32 ke Wi-Fi.
3. Pastikan ESP32 statusnya `MQTT connected`.
4. Jalankan Flutter dengan `USE_MOCK_DOCK=false` dan host broker yang benar.
5. Login ke app.
6. Pilih stasiun dan lanjut ke halaman konfirmasi pinjam.
7. Tekan tombol mulai pinjam.
8. Lihat Serial Monitor ESP32.
9. Kalau benar, log akan menunjukkan pesan `Unlocking dock ...` dan relay aktif.

## 9.1 Cara tes broker dulu sebelum menyentuh app

Sebelum buka Flutter dan ESP32, tes broker terlebih dahulu.

Kalau pakai broker lokal:

```bash
mosquitto_sub -h 192.168.1.10 -t "velocy/dock/A1/control" -v
```

Di terminal lain:

```bash
mosquitto_pub -h 192.168.1.10 -t "velocy/dock/A1/control" -m "{\"action\":\"UNLOCK\"}"
```

Kalau pesan tampil di subscriber, berarti broker sudah OK.

Kalau pakai broker cloud, kamu bisa lakukan tes yang sama dengan host dan kredensial dari cloud broker.

## 10. Kalau solenoid belum terbuka

Cek poin-poin ini dulu:

- `dockCode` di Flutter harus sama dengan `DEVICE_DOCK_CODE` di firmware ESP32.
- Topik kontrol harus sama, misalnya `velocy/dock/A1/control`.
- ESP32 harus subscribe ke `velocy/dock/+/control`.
- Broker harus bisa diakses dari Flutter dan ESP32.
- Kalau broker cloud, pastikan port dan kredensial benar.
- Kalau pakai relay active-low, pastikan wiring dan logika `RELAY_ACTIVE_LOW` cocok.

## 11. Mode mock untuk development

Kalau kamu belum mau nyambung ke hardware, app masih bisa dijalankan dalam mode mock.

- Default `USE_MOCK_DOCK=true`
- Aksi unlock akan sukses secara simulasi
- Cocok untuk UI testing dan demo flow

Kalau sudah mau tes solenoid beneran, ubah ke:

```bash
--dart-define=USE_MOCK_DOCK=false
```

## 12. Rekomendasi setup paling cepat

Kalau targetmu adalah demo ke teman dalam waktu singkat:

1. Pakai HiveMQ Cloud.
2. Set `MQTT_TOPIC_PREFIX=velocy/dock`.
3. Set `DEVICE_DOCK_CODE=A1` di ESP32.
4. Jalankan Flutter dengan `USE_MOCK_DOCK=false`, `MQTT_SECURE=true`, dan port `8883`.
5. Pakai setup ESP32 TLS dari file yang sudah diubah di repo ini.
5. Tes unlock dari halaman konfirmasi pinjam.

Kalau kamu mau, langkah berikutnya yang paling berguna adalah menambah halaman "MQTT Test" di app supaya kamu bisa kirim perintah unlock langsung tanpa lewat flow sewa penuh.
