import 'package:flutter/material.dart';

import 'navigation_helper.dart';
import 'trip_session_state.dart';

class TripSummaryScreen extends StatefulWidget {
  const TripSummaryScreen({
    super.key,
    required this.fromStationName,
    required this.toStationName,
    required this.duration,
  });

  final String fromStationName;
  final String toStationName;
  final Duration duration;

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  @override
  void initState() {
    super.initState();
    TripSessionState.hasActiveTrip = false;
  }

  String get _durationText {
    final minutes = widget.duration.inMinutes;
    return '$minutes menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Velocy',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF005440),
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F6E56),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sepeda berhasil dikembalikan!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141B2B),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.my_location,
                        label: 'Dari',
                        value: widget.fromStationName,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 32),
                        child: Divider(height: 20, thickness: 1, color: Color(0x80BEC9C3)),
                      ),
                      _DetailRow(
                        icon: Icons.flag,
                        label: 'Ke',
                        value: widget.toStationName,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 32),
                        child: Divider(height: 20, thickness: 1, color: Color(0x80BEC9C3)),
                      ),
                      _DetailRow(
                        icon: Icons.timer,
                        label: 'Durasi',
                        value: _durationText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => switchToTab(context, 0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kembali ke Beranda',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE9EDFF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF3F4944), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Color(0xFF3F4944),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
