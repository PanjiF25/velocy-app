#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

constexpr char WIFI_SSID[] = "YOUR_WIFI_SSID";
constexpr char WIFI_PASSWORD[] = "YOUR_WIFI_PASSWORD";
constexpr char MQTT_BROKER_HOST[] = "192.168.1.10";
constexpr uint16_t MQTT_BROKER_PORT = 1883;
constexpr char MQTT_USERNAME[] = "";
constexpr char MQTT_PASSWORD[] = "";
constexpr char MQTT_TOPIC_PREFIX[] = "velocy/dock";
constexpr char DEVICE_DOCK_CODE[] = "A1";
constexpr char DEVICE_ID[] = "esp32-dock-a1";
constexpr uint8_t RELAY_PIN = 26;
constexpr bool RELAY_ACTIVE_LOW = true;
constexpr unsigned long UNLOCK_PULSE_MS = 1200;
constexpr unsigned long WIFI_RETRY_MS = 10000;
constexpr unsigned long MQTT_RETRY_MS = 5000;

WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);
unsigned long lastWifiAttempt = 0;
unsigned long lastMqttAttempt = 0;

String statusTopic() {
  return String(MQTT_TOPIC_PREFIX) + "/" + DEVICE_DOCK_CODE + "/status";
}

String commandTopic() {
  return String(MQTT_TOPIC_PREFIX) + "/+/control";
}

void setRelayIdle() {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_LOW ? HIGH : LOW);
}

void setRelayActive() {
  digitalWrite(RELAY_PIN, RELAY_ACTIVE_LOW ? LOW : HIGH);
}

void publishStatus(const char *state) {
  mqttClient.publish(statusTopic().c_str(), state, true);
}

void unlockDock(const String &source) {
  Serial.printf("[%s] Unlocking dock %s\n", source.c_str(), DEVICE_DOCK_CODE);
  setRelayActive();
  delay(UNLOCK_PULSE_MS);
  setRelayIdle();
  publishStatus("unlocked");
}

String topicDockCode(const String &topic) {
  const String prefix = String(MQTT_TOPIC_PREFIX) + "/";
  if (!topic.startsWith(prefix)) {
    return String();
  }

  const String remainder = topic.substring(prefix.length());
  const int secondSlash = remainder.indexOf('/');
  if (secondSlash < 0) {
    return String();
  }

  return remainder.substring(0, secondSlash);
}

void handleSerialCommand(const String &command) {
  String trimmed = command;
  trimmed.trim();
  trimmed.toUpperCase();

  if (trimmed == "PING") {
    Serial.println("PONG");
    return;
  }

  if (trimmed == "STATUS") {
    Serial.printf("WiFi=%s MQTT=%s Relay=%s\n",
                  WiFi.isConnected() ? "connected" : "down",
                  mqttClient.connected() ? "connected" : "down",
                  digitalRead(RELAY_PIN) == (RELAY_ACTIVE_LOW ? LOW : HIGH) ? "active" : "idle");
    return;
  }

  if (trimmed == "OPEN") {
    unlockDock("SERIAL");
    return;
  }

  Serial.println("Commands: PING, STATUS, OPEN");
}

void mqttCallback(char *topic, byte *payload, unsigned int length) {
  String topicString = topic;
  String dockCode = topicDockCode(topicString);

  if (dockCode != DEVICE_DOCK_CODE) {
    Serial.printf("Ignoring topic for dock %s\n", dockCode.c_str());
    return;
  }

  String message;
  message.reserve(length);
  for (unsigned int i = 0; i < length; i++) {
    message += static_cast<char>(payload[i]);
  }

  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);
  if (error) {
    Serial.printf("Invalid JSON: %s\n", error.c_str());
    return;
  }

  const char *action = doc["action"] | "";
  if (String(action).equalsIgnoreCase("UNLOCK")) {
    unlockDock("MQTT");
  }
}

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  if (millis() - lastWifiAttempt < WIFI_RETRY_MS) {
    return;
  }
  lastWifiAttempt = millis();

  Serial.printf("Connecting WiFi to %s\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void connectMqtt() {
  if (!WiFi.isConnected()) {
    return;
  }

  if (mqttClient.connected()) {
    return;
  }

  if (millis() - lastMqttAttempt < MQTT_RETRY_MS) {
    return;
  }
  lastMqttAttempt = millis();

  mqttClient.setServer(MQTT_BROKER_HOST, MQTT_BROKER_PORT);
  mqttClient.setCallback(mqttCallback);

  Serial.printf("Connecting MQTT to %s:%u\n", MQTT_BROKER_HOST, MQTT_BROKER_PORT);

  bool connected = false;
  const String status = statusTopic();
  const String willMessage = "offline";

  if (MQTT_USERNAME[0] != '\0') {
    connected = mqttClient.connect(
      DEVICE_ID,
      MQTT_USERNAME,
      MQTT_PASSWORD,
      status.c_str(),
      0,
      true,
      willMessage.c_str()
    );
  } else {
    connected = mqttClient.connect(
      DEVICE_ID,
      status.c_str(),
      0,
      true,
      willMessage.c_str()
    );
  }

  if (connected) {
    mqttClient.subscribe(commandTopic().c_str());
    publishStatus("online");
    Serial.println("MQTT connected");
  } else {
    Serial.printf("MQTT connect failed, state=%d\n", mqttClient.state());
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);
  pinMode(RELAY_PIN, OUTPUT);
  setRelayIdle();
  WiFi.disconnect(true);
  connectWiFi();
}

void loop() {
  connectWiFi();
  connectMqtt();

  if (mqttClient.connected()) {
    mqttClient.loop();
  }

  while (Serial.available() > 0) {
    const String command = Serial.readStringUntil('\n');
    handleSerialCommand(command);
  }

  delay(10);
}
