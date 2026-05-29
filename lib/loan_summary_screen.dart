import 'package:flutter/material.dart';

import 'destination_station_screen.dart';
import 'dock_unlock_service.dart';
import 'active_trip_screen.dart';
import 'trip_session_state.dart';

class LoanSummaryScreen extends StatefulWidget {
  const LoanSummaryScreen({
    super.key,
    required this.qrValue,
    required this.originStationName,
    required this.originDockLabel,
    required this.originDockCode,
    required this.destinationStation,
  });

  final String qrValue;
  final String originStationName;
  final String originDockLabel;
  final String originDockCode;
  final DestinationStationItem destinationStation;

  @override
  State<LoanSummaryScreen> createState() => _LoanSummaryScreenState();
}

class _LoanSummaryScreenState extends State<LoanSummaryScreen> {
  final DockUnlockService _dockUnlockService = const DockUnlockService(
    useMock: bool.fromEnvironment('USE_MOCK_DOCK', defaultValue: true),
    brokerHost: String.fromEnvironment('MQTT_BROKER_HOST', defaultValue: ''),
    brokerPort: int.fromEnvironment('MQTT_BROKER_PORT', defaultValue: 1883),
    topicPrefix: String.fromEnvironment('MQTT_TOPIC_PREFIX', defaultValue: 'velocy/dock'),
    clientId: String.fromEnvironment('MQTT_CLIENT_ID', defaultValue: 'velocy_app'),
    username: String.fromEnvironment('MQTT_USERNAME', defaultValue: ''),
    password: String.fromEnvironment('MQTT_PASSWORD', defaultValue: ''),
  );

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F4944)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Konfirmasi Peminjaman',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF005440),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF3F4944)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBEC9C3)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _SectionRow(
                                  icon: Icons.location_on,
                                  iconColor: const Color(0xFF0F6E56),
                                  label: 'STASIUN AWAL',
                                  title: widget.originStationName,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9EDFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.dock, size: 16, color: Color(0xFF3F4944)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Nomor Dok: ${widget.originDockCode}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          color: Color(0xFF3F4944),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFFBEC9C3)),
                                const SizedBox(height: 12),
                                _SectionRow(
                                  icon: Icons.flag,
                                  iconColor: const Color(0xFF1960A6),
                                  label: 'STASIUN TUJUAN',
                                  title: widget.destinationStation.name,
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFFBEC9C3)),
                                const SizedBox(height: 12),
                                _DetailLine(
                                  icon: Icons.pedal_bike,
                                  title: 'Sepeda',
                                  value: 'Akan ditentukan sistem',
                                ),
                                const SizedBox(height: 12),
                                _DetailLine(
                                  icon: Icons.timer,
                                  title: 'Estimasi',
                                  value: 'Berdasarkan jarak ± 5 menit',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE2F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBEC9C3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_outlined, color: Color(0xFF0F6E56)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Color(0xFF141B2B),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '⚠️ Pastikan kamu sudah siap... ',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: 'Solenoid kunci akan terbuka segera setelah kamu mengonfirmasi peminjaman.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dengan memulai sewa, kamu setuju untuk mengembalikan sepeda ke stasiun tujuan yang dipilih.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF3F4944),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9FF),
              border: Border(top: BorderSide(color: Color(0xFFBEC9C3))),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleStartBorrow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6E56),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFA0F3D4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? 'Memproses...' : 'Mulai Pinjam Sekarang',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F6E56),
                          side: const BorderSide(color: Color(0xFF0F6E56)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ganti Stasiun Tujuan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartBorrow() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final response = await _dockUnlockService.unlockDock(
      DockUnlockRequest(
        qrValue: widget.qrValue,
        bikeCode: 'SYSTEM',
        dockCode: widget.originDockCode,
        stationName: widget.originStationName,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    if (!mounted) return;

    TripSessionState.hasActiveTrip = true;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ActiveTripScreen(
          bikeCode: 'VLY-002',
          originStationName: widget.originStationName,
          currentLocationLabel: widget.originStationName,
          startTime: DateTime.now(),
          destinationStationName: widget.destinationStation.name,
        ),
      ),
    );

    return;
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: Color(0xFF3F4944),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF141B2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3F4944), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF3F4944),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF141B2B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
