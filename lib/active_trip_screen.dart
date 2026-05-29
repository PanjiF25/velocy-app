import 'dart:async';

import 'package:flutter/material.dart';

import 'return_bike_screen.dart';
import 'navigation_helper.dart';
import 'report_issue_sheet.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({
    super.key,
    required this.bikeCode,
    required this.originStationName,
    required this.currentLocationLabel,
    required this.startTime,
    required this.destinationStationName,
  });

  final String bikeCode;
  final String originStationName;
  final String currentLocationLabel;
  final DateTime startTime;
  final String destinationStationName;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final nextElapsed = DateTime.now().difference(widget.startTime);
    if (!mounted) {
      _elapsed = nextElapsed.isNegative ? Duration.zero : nextElapsed;
      return;
    }

    setState(() {
      _elapsed = nextElapsed.isNegative ? Duration.zero : nextElapsed;
    });
  }

  String get _timerText {
    final hours = _elapsed.inHours;
    final minutes = _elapsed.inMinutes.remainder(60);
    final seconds = _elapsed.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
          onPressed: () => switchToTab(context, 0),
        ),
        centerTitle: true,
        title: const Text(
          'Velocy',
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perjalanan Aktif',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pastikan berkendara dengan aman di area kampus.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF3F4944),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18755C),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_bike, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.bikeCode,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _timerText,
                          style: const TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                widget.currentLocationLabel,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Lokasi Saat Ini',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBEC9C3)),
                      color: const Color(0xFFB9D7B0),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MapPatternPainter(),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1960A6),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66000000),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              '12 km/h',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF141B2B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Rincian Peminjaman',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                      children: [
                        _InfoRow(
                          icon: Icons.start,
                          label: 'Stasiun Awal',
                          value: widget.originStationName,
                        ),
                        const Divider(height: 1, color: Color(0xFFBEC9C3)),
                        _InfoRow(
                          icon: Icons.schedule,
                          label: 'Waktu Pinjam',
                          value: _formattedStartTime,
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
              child: Row(
                children: [
                  // Tappable report button (use the left icon as primary report action)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFBA1A1A))),
                      child: IconButton(
                        onPressed: () => showReportIssueSheet(context, tripId: widget.bikeCode),
                        icon: const Icon(Icons.report_problem, color: Color(0xFFBA1A1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _showReturnPlaceholder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6E56),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Kembalikan Sepeda',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedStartTime {
    final hour = widget.startTime.hour.toString().padLeft(2, '0');
    final minute = widget.startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showReturnPlaceholder() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReturnBikeScreen(
          originStationName: widget.originStationName,
          stationName: widget.destinationStationName,
          bikeCode: widget.bikeCode,
          duration: _elapsed,
        ),
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final roadThinPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.12, size.width * 0.35, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.42, size.width * 0.6, size.height * 0.34)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.24, size.width, size.height * 0.36);
    canvas.drawPath(path, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.1, 0)
      ..quadraticBezierTo(size.width * 0.18, size.height * 0.28, size.width * 0.3, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.42, size.width * 0.54, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.67, size.height * 0.68, size.width * 0.85, size.height);
    canvas.drawPath(path2, roadThinPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3F4944), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF3F4944),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF141B2B),
            ),
          ),
        ],
      ),
    );
  }
}
