import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:velocy_app/ui/user/rent/destination_station_screen.dart';
import 'package:velocy_app/ui/user/rent/loan_summary_screen.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/common/widgets/shimmer_loading.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({super.key, required this.qrValue});

  final String qrValue;

  factory StationDetailScreen.fromQr(String qrValue) {
    return StationDetailScreen(qrValue: qrValue);
  }

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _stationName = '';
  String _selectedDockCode = '';
  Map<String, dynamic>? _stationData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseQrAndLoadStation();
  }

  Future<void> _parseQrAndLoadStation() async {
    try {
      final parsed = _tryParseQrJson(widget.qrValue);
      _selectedDockCode = parsed?['dockCode']?.toString() ?? _extractDockCode(widget.qrValue) ?? 'D1';
      _stationName = parsed?['stationName']?.toString().trim() ?? 'Stasiun Gedung Teknik Informatika';

      // Fetch station by name from Firestore
      final station = await _firestoreService.getStationByName(_stationName);
      if (station != null) {
        setState(() {
          _stationData = station;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = AppLocalizations.isIndo ? 'Stasiun "$_stationName" tidak ditemukan di database.' : 'Station "$_stationName" not found in database.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.isIndo ? 'Gagal memproses data QR: $e' : 'Failed to process QR data: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _tryParseQrJson(String qrValue) {
    try {
      final decoded = jsonDecode(qrValue);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  String? _extractDockCode(String qrValue) {
    final match = RegExp(r'\b([A-Z]?\d{1,2})\b', caseSensitive: false).firstMatch(qrValue);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Velocy',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary(context),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildShimmerLoading()
            : _errorMessage != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!)))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final stationId = _stationData!['id'] as String;
    final address = _stationData!['address'] ?? '';
    final totalDocksStation = _stationData!['totalDocks'] ?? 0;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getDocksStreamForStation(stationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        final docks = snapshot.data ?? [];
        if (docks.isEmpty) {
          return Center(child: Text(AppLocalizations.isIndo ? 'Tidak ada data dock untuk stasiun ini.' : 'No dock data for this station.', style: TextStyle(color: AppTheme.textMuted(context))));
        }

        // Count occupancy
        int occupiedCount = docks.where((d) => d['status'] == 'occupied').length;
        double occupancyProgress = docks.isNotEmpty ? occupiedCount / docks.length : 0;
        String occupancyLabel = '$occupiedCount/${docks.length}';

        final dockStr = AppLocalizations.isIndo ? 'Dok' : 'Dock';

        // Find selected dock label
        String selectedDockLabel = dockStr;
        for (final dock in docks) {
          if (dock['dockCode'] == _selectedDockCode) {
            selectedDockLabel = dock['dockCode'] != null ? '$dockStr ${dock['dockCode']}' : dockStr;
            break;
          }
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stationName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted(context)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              height: 1.5,
                              color: AppTheme.textMuted(context),
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
                        boxShadow: [
                          if (!AppTheme.isDark(context))
                            const BoxShadow(
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
                              Text(
                                AppLocalizations.isIndo ? 'Status Stasiun' : 'Station Status',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.isIndo ? 'Tingkat Okupansi' : 'Occupancy Rate',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFFA0F3D4),
                                ),
                              ),
                            ],
                          ),
                          _OccupancyIndicator(
                            label: occupancyLabel,
                            progress: occupancyProgress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.isIndo ? 'Ketersediaan Dok' : 'Dock Availability',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docks.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (context, index) {
                        final dock = docks[index];
                        return _DockCard(
                          label: dock['dockCode'] != null ? '$dockStr ${dock['dockCode']}' : dockStr,
                          isAvailable: dock['status'] == 'available',
                          isSelected: dock['dockCode'] == _selectedDockCode,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bg(context),
                border: Border(top: BorderSide(color: AppTheme.outline(context))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final selectedStation = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (context) => DestinationStationScreen(
                            originStationId: stationId,
                            originStationName: _stationName,
                            originDockLabel: selectedDockLabel,
                            originDockCode: _selectedDockCode,
                          ),
                        ),
                      );

                      if (!context.mounted || selectedStation == null) {
                        return;
                      }

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoanSummaryScreen(
                            qrValue: widget.qrValue,
                            originStationId: stationId,
                            originStationName: _stationName,
                            originDockLabel: selectedDockLabel,
                            originDockCode: _selectedDockCode,
                            destinationStation: selectedStation,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.isIndo ? 'Pilih Stasiun Tujuan' : 'Select Destination Station',
                      style: const TextStyle(
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
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 200, height: 28),
          const SizedBox(height: 8),
          const ShimmerLoading(width: double.infinity, height: 16),
          const SizedBox(height: 16),
          const ShimmerLoading(width: double.infinity, height: 100, borderRadius: 16),
          const SizedBox(height: 24),
          const ShimmerLoading(width: 150, height: 20),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(4, (index) => const ShimmerLoading(width: double.infinity, height: double.infinity, borderRadius: 10)),
          ),
        ],
      ),
    );
  }
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
  const _DockCard({
    required this.label,
    required this.isAvailable,
    required this.isSelected,
  });

  final String label;
  final bool isAvailable;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected ? AppTheme.primary(context).withOpacity(0.1) : AppTheme.surface(context);
    final labelColor = isAvailable ? (isSelected ? AppTheme.primary(context) : AppTheme.textMain(context)) : AppTheme.textMuted(context);
    final statusColor = isAvailable ? AppTheme.primary(context) : AppTheme.textMuted(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border(left: BorderSide(color: AppTheme.primary(context), width: 4))
            : Border.all(color: AppTheme.outline(context)),
        boxShadow: [
          if (!AppTheme.isDark(context))
            const BoxShadow(
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
                isAvailable ? (AppLocalizations.isIndo ? 'Tersedia' : 'Available') : (AppLocalizations.isIndo ? 'Terisi' : 'Occupied'),
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
                  label,
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
                color: isAvailable ? AppTheme.primary(context) : AppTheme.textMuted(context),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
