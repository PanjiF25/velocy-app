import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class DockUnlockRequest {
  const DockUnlockRequest({
    required this.qrValue,
    required this.bikeCode,
    required this.dockCode,
    required this.stationName,
    required this.stationId,
    required this.relayPin,
  });

  final String qrValue;
  final String bikeCode;
  final String dockCode;
  final String stationName;
  final String stationId;
  final int relayPin;
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
    this.secure = false,
    this.topicPrefix = 'velocy/dock',
    this.clientId = 'velocy_app',
    this.username,
    this.password,
  });

  final bool useMock;
  final String brokerHost;
  final int brokerPort;
  final bool secure;
  final String topicPrefix;
  final String clientId;
  final String? username;
  final String? password;

  static const _timeoutSeconds = 10;

  /// Kirim UNLOCK ke dock (untuk peminjaman)
  Future<DockUnlockResponse> unlockDock(DockUnlockRequest request) async {
    return _sendCommand(
      stationId: request.stationId,
      payload: {
        'action': 'open',
        'relayPin': request.relayPin,
        'duration': 15,
        'qrValue': request.qrValue,
        'bikeCode': request.bikeCode,
        'dockCode': request.dockCode,
        'stationName': request.stationName,
      },
      successMessage: 'Perintah unlock terkirim ke stasiun ${request.stationName} (Pin ${request.relayPin})',
    );
  }


  /// Tunggu Limit Switch tertekan (Pengembalian Sepeda)
  Future<DockUnlockResponse> waitForSensor({
    required String stationId,
    required int sensorPin,
    int timeoutSeconds = 30,
  }) async {
    if (useMock || brokerHost.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
      return const DockUnlockResponse(success: true, message: 'Sensor terdeteksi (mock)');
    }

    final uniqueClientId = '${clientId}_wait_${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(brokerHost, uniqueClientId, brokerPort)
      ..keepAlivePeriod = 20
      ..logging(on: false)
      ..secure = secure
      ..connectTimeoutPeriod = (5000);

    client.setProtocolV311();
    final completer = Completer<DockUnlockResponse>();

    try {
      final connMsg = MqttConnectMessage().withClientIdentifier(uniqueClientId).startClean();
      client.connectionMessage = (username != null && username!.isNotEmpty)
          ? connMsg.authenticateAs(username!, password ?? '')
          : connMsg;

      await client.connect();

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        return const DockUnlockResponse(success: false, message: 'Gagal konek MQTT');
      }

      final topic = 'velocy/station/$stationId/sensor';
      client.subscribe(topic, MqttQos.atLeastOnce);

      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        if (recMess.header != null && recMess.header!.retain) {
          print('Mengabaikan pesan retained (sisa testing sebelumnya)');
          return;
        }
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('MQTT Received on sensor wait: $pt');
        try {
          final data = jsonDecode(pt);
          if (data['sensorPin'].toString() == sensorPin.toString() && data['status'] == 'filled') {
            if (!completer.isCompleted) {
              completer.complete(const DockUnlockResponse(success: true, message: 'Sepeda berhasil dikembalikan!'));
            }
          } else {
            print('Mismatch: expected sensorPin $sensorPin, got ${data['sensorPin']}');
          }
        } catch (e) {
          print('Error decoding MQTT message: $e');
        }
      });

      // Timeout
      Future.delayed(Duration(seconds: timeoutSeconds), () {
        if (!completer.isCompleted) {
          completer.complete(const DockUnlockResponse(success: false, message: 'Waktu tunggu habis. Pastikan sepeda didorong sampai limit switch berbunyi klik.'));
        }
      });

      final result = await completer.future;
      client.disconnect();
      return result;
    } catch (e) {
      return DockUnlockResponse(success: false, message: 'Error: $e');
    }
  }



  Future<DockUnlockResponse> _sendCommand({
    required String stationId,
    required Map<String, dynamic> payload,
    required String successMessage,
  }) async {
    if (useMock || brokerHost.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
      return DockUnlockResponse(success: true, message: successMessage);
    }

    // Step 1: Test TCP
    try {
      final socket = await Socket.connect(
        brokerHost, brokerPort,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
    } catch (e) {
      return DockUnlockResponse(
        success: false,
        message: 'Tidak bisa terhubung ke broker:\n$brokerHost:$brokerPort\n\nError: $e',
      );
    }

    // Step 2: MQTT dengan race vs timer
    return Future.any<DockUnlockResponse>([
      _doSend(stationId, payload, successMessage),
      Future.delayed(
        const Duration(seconds: _timeoutSeconds),
        () => const DockUnlockResponse(
          success: false,
          message: 'MQTT timeout — TCP OK tapi TLS/Auth gagal.\nCek kredensial HiveMQ.',
        ),
      ),
    ]);
  }

  Future<DockUnlockResponse> _doSend(
    String stationId,
    Map<String, dynamic> payload,
    String successMessage,
  ) async {
    final uniqueClientId = '${clientId}_${DateTime.now().millisecondsSinceEpoch}';

    final client = MqttServerClient.withPort(brokerHost, uniqueClientId, brokerPort)
      ..keepAlivePeriod = 20
      ..logging(on: false)
      ..secure = secure
      ..connectTimeoutPeriod = (_timeoutSeconds * 1000)
      ..onConnected = () {}
      ..onDisconnected = () {}
      ..onSubscribed = (String topic) {};

    client.setProtocolV311();

    try {
      final connMsg = MqttConnectMessage()
          .withClientIdentifier(uniqueClientId)
          .startClean();

      client.connectionMessage = (username != null && username!.isNotEmpty)
          ? connMsg.authenticateAs(username!, password ?? '')
          : connMsg;

      await client.connect();

      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        final code = client.connectionStatus?.returnCode;
        return DockUnlockResponse(
          success: false,
          message: 'MQTT ditolak broker (code: $code)\nCek username & password HiveMQ.',
        );
      }

      final topic = 'velocy/station/$stationId/command';
      final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

      await Future<void>.delayed(const Duration(milliseconds: 500));

      return DockUnlockResponse(success: true, message: successMessage);
    } catch (e) {
      return DockUnlockResponse(
        success: false,
        message: 'MQTT error: $e',
      );
    } finally {
      try {
        client.disconnect();
      } catch (_) {}
    }
  }
}

