import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class DockUnlockRequest {
  const DockUnlockRequest({
    required this.qrValue,
    required this.bikeCode,
    required this.dockCode,
    required this.stationName,
  });

  final String qrValue;
  final String bikeCode;
  final String dockCode;
  final String stationName;
}

class DockUnlockResponse {
  const DockUnlockResponse({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class DockUnlockService {
  const DockUnlockService({
    this.useMock = true,
    this.brokerHost = '',
    this.brokerPort = 1883,
    this.topicPrefix = 'velocy/dock',
    this.clientId = 'velocy_app',
    this.username,
    this.password,
  });

  final bool useMock;
  final String brokerHost;
  final int brokerPort;
  final String topicPrefix;
  final String clientId;
  final String? username;
  final String? password;

  Future<DockUnlockResponse> unlockDock(DockUnlockRequest request) async {
    if (useMock || brokerHost.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));

      return DockUnlockResponse(
        success: true,
        message: 'Solenoid dock ${request.dockCode} terbuka',
      );
    }

    final client = MqttServerClient(brokerHost, clientId)
      ..port = brokerPort
      ..keepAlivePeriod = 20
      ..logging(on: false)
      ..secure = false
      ..onConnected = () {}
      ..onDisconnected = () {}
      ..onSubscribed = (String topic) {};

    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);

      if (username != null && username!.isNotEmpty) {
        client.connectionMessage = client.connectionMessage?.authenticateAs(
          username!,
          password ?? '',
        );
      }

      await client.connect().timeout(const Duration(seconds: 10));

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        throw Exception('MQTT connection failed');
      }

      final payload = jsonEncode({
        'action': 'UNLOCK',
        'qrValue': request.qrValue,
        'bikeCode': request.bikeCode,
        'dockCode': request.dockCode,
        'stationName': request.stationName,
      });

      final topic = '$topicPrefix/${request.dockCode}/control';
      final builder = MqttClientPayloadBuilder()..addString(payload);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

      return DockUnlockResponse(
        success: true,
        message: 'Perintah unlock terkirim ke dock ${request.dockCode}',
      );
    } on TimeoutException {
      return DockUnlockResponse(
        success: false,
        message: 'Koneksi MQTT timeout',
      );
    } on Exception {
      return DockUnlockResponse(
        success: false,
        message: 'Broker MQTT tidak bisa dijangkau',
      );
    } finally {
      client.disconnect();
    }
  }
}