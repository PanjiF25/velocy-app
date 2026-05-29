import 'package:flutter/material.dart';

import 'trip_summary_screen.dart';
import 'navigation_helper.dart';

class ReturnBikeScreen extends StatefulWidget {
  const ReturnBikeScreen({
    super.key,
    required this.originStationName,
    required this.stationName,
    required this.bikeCode,
    required this.duration,
  });

  final String originStationName;
  final String stationName;
  final String bikeCode;
  final Duration duration;

  @override
  State<ReturnBikeScreen> createState() => _ReturnBikeScreenState();
}

class _ReturnBikeScreenState extends State<ReturnBikeScreen> {
  static const List<_ReturnDockData> _docks = [
    _ReturnDockData(code: 'B1', isLocked: true),
    _ReturnDockData(code: 'B2', isLocked: false),
    _ReturnDockData(code: 'B3', isLocked: true),
    _ReturnDockData(code: 'B4', isLocked: false),
    _ReturnDockData(code: 'B5', isLocked: false),
    _ReturnDockData(code: 'B6', isLocked: false),
    _ReturnDockData(code: 'B7', isLocked: false),
    _ReturnDockData(code: 'B8', isLocked: false),
  ];

  late String _selectedDockCode;

  @override
  void initState() {
    super.initState();
    _selectedDockCode = 'B2';
  }

  String get _durationText {
    final hours = widget.duration.inHours;
    final minutes = widget.duration.inMinutes.remainder(60);
    final seconds = widget.duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFBEC9C3))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF3F4944)),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Pilih Dok',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005440),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StationContextCard(stationName: widget.stationName),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _docks.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 96,
                      ),
                      itemBuilder: (context, index) {
                        final dock = _docks[index];
                        return _DockCard(
                          dock: dock,
                          selected: dock.code == _selectedDockCode,
                          onTap: dock.isLocked ? null : () => setState(() => _selectedDockCode = dock.code),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFBEC9C3))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Kembalikan ke sini?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBEC9C3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DOK TERPILIH',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF3F4944),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedDockCode,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F6E56),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 56, color: const Color(0xFFBEC9C3)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DURASI',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: Color(0xFF3F4944),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _durationText,
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmReturn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6E56),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Ya, Kembalikan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3F4944),
                        side: const BorderSide(color: Color(0xFFBEC9C3)),
                        backgroundColor: const Color(0xFFF1F3FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Batal',
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
          ],
        ),
      ),
    );
  }

  void _confirmReturn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TripSummaryScreen(
          fromStationName: widget.originStationName,
          toStationName: widget.stationName,
          duration: widget.duration,
        ),
      ),
    );
  }
}

class _StationContextCard extends StatelessWidget {
  const _StationContextCard({required this.stationName});

  final String stationName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBEC9C3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF0F6E56), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141B2B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockCard extends StatelessWidget {
  const _DockCard({
    required this.dock,
    required this.selected,
    required this.onTap,
  });

  final _ReturnDockData dock;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable = !dock.isLocked;
    final backgroundColor = dock.isLocked ? const Color(0xFFF1F3FF) : Colors.white;
    final borderColor = selected ? const Color(0xFF0F6E56) : const Color(0xFFBEC9C3);
    final borderWidth = selected ? 2.0 : 1.0;

    final content = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  dock.isLocked ? Icons.lock : Icons.local_parking,
                  color: dock.isLocked ? const Color(0xFF9AA3B2) : const Color(0xFF3F4944),
                  size: 22,
                ),
                const SizedBox(height: 6),
                Text(
                  'Dok ${dock.code}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: dock.isLocked ? FontWeight.w500 : FontWeight.w600,
                    color: dock.isLocked ? const Color(0xFF9AA3B2) : const Color(0xFF141B2B),
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.check_circle, color: Color(0xFF0F6E56), size: 20),
            ),
        ],
      ),
    );

    if (!isAvailable) {
      return Opacity(opacity: 0.55, child: IgnorePointer(child: content));
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}

class _ReturnDockData {
  const _ReturnDockData({required this.code, required this.isLocked});

  final String code;
  final bool isLocked;
}
