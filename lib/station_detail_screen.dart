import 'dart:convert';

import 'package:flutter/material.dart';

import 'destination_station_screen.dart';
import 'loan_summary_screen.dart';

class StationDetailScreen extends StatelessWidget {
  const StationDetailScreen({super.key, required this.data});

  factory StationDetailScreen.fromQr(String qrValue) {
    return StationDetailScreen(data: StationDetailData.fromQr(qrValue));
  }

  final StationDetailData data;

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.stationName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3F4944)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            data.address,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF3F4944),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18755C),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status Stasiun',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.statusLabel,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFFA0F3D4),
                                ),
                              ),
                            ],
                          ),
                          _OccupancyIndicator(
                            label: data.occupancyLabel,
                            progress: data.occupancyProgress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ketersediaan Dok',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF141B2B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.docks.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (context, index) {
                        final dock = data.docks[index];
                        return _DockCard(dock: dock);
                      },
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
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final selectedStation = await Navigator.of(context).push<DestinationStationItem>(
                        MaterialPageRoute(
                          builder: (context) => DestinationStationScreen(
                            originStationName: data.stationName,
                            originDockLabel: data.selectedDockLabel,
                            originDockCode: data.selectedDockCode,
                          ),
                        ),
                      );

                      if (!context.mounted || selectedStation == null) {
                        return;
                      }

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoanSummaryScreen(
                            qrValue: data.qrValue,
                            originStationName: data.stationName,
                            originDockLabel: data.selectedDockLabel,
                            originDockCode: data.selectedDockCode,
                            destinationStation: selectedStation,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F6E56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Pilih Stasiun Tujuan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationDetailData {
  const StationDetailData({
    required this.qrValue,
    required this.stationName,
    required this.address,
    required this.occupancyLabel,
    required this.occupancyProgress,
    required this.selectedDockCode,
    required this.selectedDockLabel,
    required this.statusLabel,
    required this.docks,
  });

  factory StationDetailData.fromQr(String qrValue) {
    final parsed = _tryParseQrJson(qrValue);

    final selectedDockCode = _normalizeDockCode(
      parsed?['dockCode']?.toString() ?? _extractDockCode(qrValue) ?? 'A1',
    );
    final selectedDockIndex = _dockIndexFromCode(selectedDockCode);

    final stationName = parsed?['stationName']?.toString().trim().isNotEmpty == true
        ? parsed!['stationName'].toString()
        : 'Departemen Arsitektur';

    final address = parsed?['address']?.toString().trim().isNotEmpty == true
        ? parsed!['address'].toString()
        : 'Jl. Teknik Kimia, Keputih, Kec. Sukolilo, Surabaya, Jawa Timur 60111';

    final docks = <DockSlot>[
      DockSlot(label: 'Dok 1', isAvailable: true, isSelected: selectedDockIndex == 0),
      DockSlot(label: 'Dok 2', isAvailable: true, isSelected: selectedDockIndex == 1),
      DockSlot(label: 'Dok 3', isAvailable: false, isSelected: selectedDockIndex == 2),
      DockSlot(label: 'Dok 4', isAvailable: true, isSelected: selectedDockIndex == 3),
      DockSlot(label: 'Dok 5', isAvailable: false, isSelected: selectedDockIndex == 4),
      DockSlot(label: 'Dok 6', isAvailable: false, isSelected: selectedDockIndex == 5),
    ];

    return StationDetailData(
      qrValue: qrValue,
      stationName: stationName,
      address: address,
      occupancyLabel: '${selectedDockIndex + 1}/6',
      occupancyProgress: ((selectedDockIndex + 1) / 6).clamp(0.0, 1.0),
      selectedDockCode: selectedDockCode,
      selectedDockLabel: 'Dok ${selectedDockIndex + 1}',
      statusLabel: 'Tingkat Okupansi',
      docks: docks,
    );
  }

  final String qrValue;
  final String stationName;
  final String address;
  final String occupancyLabel;
  final double occupancyProgress;
  final String selectedDockCode;
  final String selectedDockLabel;
  final String statusLabel;
  final List<DockSlot> docks;
}

class DockSlot {
  const DockSlot({
    required this.label,
    required this.isAvailable,
    required this.isSelected,
  });

  final String label;
  final bool isAvailable;
  final bool isSelected;
}

class _OccupancyIndicator extends StatelessWidget {
  const _OccupancyIndicator({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 4,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF114D3B)),
            backgroundColor: const Color(0xFF86F8C9),
          ),
          CircularProgressIndicator(
            value: clampedProgress,
            strokeWidth: 4,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF84D6B9)),
            backgroundColor: Colors.transparent,
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockCard extends StatelessWidget {
  const _DockCard({required this.dock});

  final DockSlot dock;

  @override
  Widget build(BuildContext context) {
    final isSelected = dock.isSelected;
    final isAvailable = dock.isAvailable;

    final backgroundColor = isSelected
        ? const Color(0xFFF0FBF7)
        : const Color(0xFFFFFFFF);
    final labelColor = isAvailable
        ? (isSelected ? const Color(0xFF0F6E56) : const Color(0xFF141B2B))
        : const Color(0xFF6F7A74);
    final statusColor = isAvailable
        ? const Color(0xFF0F6E56)
        : const Color(0xFF6F7A74);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? const Border(left: BorderSide(color: Color(0xFF0F6E56), width: 4))
            : Border.all(color: const Color(0xFFBEC9C3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAvailable ? 'Tersedia' : 'Terisi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  dock.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
              Icon(
                isAvailable ? Icons.qr_code_scanner : Icons.lock_outline,
                color: isAvailable ? const Color(0xFF0F6E56) : const Color(0xFF9AA3A0),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic>? _tryParseQrJson(String qrValue) {
  try {
    final decoded = jsonDecode(qrValue);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    // Fall through to mock resolver.
  }
  return null;
}

String? _extractDockCode(String qrValue) {
  final match = RegExp(r'\b([A-Z]?\d{1,2})\b', caseSensitive: false).firstMatch(qrValue);
  if (match != null) {
    return match.group(1);
  }
  return null;
}

String _normalizeDockCode(String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized.startsWith('D')) {
    return normalized.substring(1);
  }
  if (normalized.startsWith('DOCK')) {
    return normalized.replaceFirst('DOCK', '');
  }
  return normalized;
}

int _dockIndexFromCode(String code) {
  final match = RegExp(r'(\d{1,2})').firstMatch(code);
  if (match == null) {
    return 0;
  }

  final index = int.tryParse(match.group(1) ?? '') ?? 1;
  if (index <= 0) {
    return 0;
  }
  if (index > 6) {
    return 5;
  }
  return index - 1;
}
