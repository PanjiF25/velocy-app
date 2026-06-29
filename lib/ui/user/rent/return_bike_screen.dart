import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:velocy_app/ui/user/stations/station_detail_screen.dart';
import 'package:velocy_app/ui/user/rent/trip_summary_screen.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/utils/qr_helper.dart';
import 'package:velocy_app/services/dock_unlock_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/common/widgets/pulsing_radar.dart';

class ReturnBikeScreen extends StatefulWidget {
  const ReturnBikeScreen({
    super.key,
    required this.tripId,
    required this.originStationName,
    required this.stationName,
    required this.bikeCode,
    required this.duration,
  });

  final String tripId;
  final String originStationName;
  final String stationName;
  final String bikeCode;
  final Duration duration;

  @override
  State<ReturnBikeScreen> createState() => _ReturnBikeScreenState();
}

class _ReturnBikeScreenState extends State<ReturnBikeScreen> {
  final DockUnlockService _dockService = const DockUnlockService(
    useMock: false,
    brokerHost: 'ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud',
    brokerPort: 8883,
    secure: true,
    topicPrefix: 'velocy/dock',
    clientId: 'velocy_app',
    username: 'velocy',
    password: 'Velocy123',
  );

  final FirestoreService _firestoreService = FirestoreService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;
  bool _isProcessing = false;

  String get _durationText {
    final hours = widget.duration.inHours;
    final minutes = widget.duration.inMinutes.remainder(60);
    final seconds = widget.duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cutOutSize = MediaQuery.of(context).size.width * 0.55;

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bg(context),
                border: Border(bottom: BorderSide(color: AppTheme.outline(context))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.isIndo ? 'Kembalikan Sepeda' : 'Return Bike',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary(context),
                    ),
                  ),
                ],
              ),
            ),

            // Info card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline(context)),
                  boxShadow: [
                    if (!AppTheme.isDark(context))
                      const BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.isIndo ? 'STASIUN TUJUAN' : 'DESTINATION STATION',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.stationName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppTheme.outline(context)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.isIndo ? 'DURASI' : 'DURATION',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _durationText,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scanner area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MobileScanner(
                          controller: _scannerController,
                          onDetect: (capture) async {
                            if (!_isScanning || _isProcessing || capture.barcodes.isEmpty) return;

                            final barcode = capture.barcodes.first;
                            final value = barcode.rawValue ?? barcode.displayValue ?? '';
                            if (value.isEmpty) return;

                            setState(() {
                              _isScanning = false;
                            });
                            await _scannerController.stop();

                            await _handleScannedDock(value);
                          },
                        ),
                      ),
                      // Scanner overlay
                      Center(
                        child: SizedBox(
                          width: cutOutSize,
                          height: cutOutSize,
                          child: Stack(
                            children: const [
                              Positioned(top: 0, left: 0, child: _CornerBracket(top: true, left: true)),
                              Positioned(top: 0, right: 0, child: _CornerBracket(top: true, left: false)),
                              Positioned(bottom: 0, left: 0, child: _CornerBracket(top: false, left: true)),
                              Positioned(bottom: 0, right: 0, child: _CornerBracket(top: false, left: false)),
                            ],
                          ),
                        ),
                      ),
                      // Processing overlay
                      if (_isProcessing)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const PulsingRadar(color: Colors.white, size: 80, icon: Icons.login),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppLocalizations.isIndo ? 'Menunggu sepeda dimasukkan...' : 'Waiting for bike insertion...',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
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
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline(context)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2, color: AppTheme.primary(context), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.isIndo ? 'Scan QR pada dock tujuan untuk mengembalikan sepeda' : 'Scan QR on destination dock to return bike',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScannedDock(String qrValue) async {
    final scannedData = QrHelper.parseQr(qrValue);
    final scannedStation = scannedData['stationName'] ?? '';
    final scannedDockCode = scannedData['dockCode'] ?? '';

    // Cek apakah stasiun berbeda dari tujuan
    if (scannedStation != widget.stationName) {
      final confirmed = await _showDifferentStationDialog(scannedStation);
      if (!confirmed) {
        // User batal — restart scanner
        if (mounted) {
          setState(() => _isScanning = true);
          await _scannerController.start();
        }
        return;
      }
    }

    // Proses pengembalian
    if (!mounted) return;
    setState(() => _isProcessing = true);

    // Ambil data dock untuk mengetahui sensorPin-nya
    final stationData = await _firestoreService.getStationByName(scannedStation);
    final returnStationId = stationData?['id'] ?? 'unknown_station';
    
    // Cari dock yang discan
    final docksQuery = await _firestoreService.getDocksStreamForStation(returnStationId).first;
    final dockInfo = docksQuery.firstWhere((d) {
      final rawCode = d['dockCode'] ?? d['number'] ?? '';
      final dCode = rawCode.toString().toUpperCase();
      final sCode = scannedDockCode.toUpperCase();
      return dCode == sCode || d['id'] == scannedDockCode || dCode == 'D$sCode' || 'D$dCode' == sCode;
    }, orElse: () => <String, dynamic>{});
    
    int rawOrder = 1;
    if (dockInfo.containsKey('order')) {
      rawOrder = dockInfo['order'] as int;
    } else {
      final code = (dockInfo['dockCode'] ?? dockInfo['number'] ?? '1').toString();
      rawOrder = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    }
    
    var sensorPin = dockInfo['sensorPin'];
    if (sensorPin == null) {
      sensorPin = rawOrder - 1; // Fallback ke index (0-based)
    }

    // Tampilkan pesan untuk memasukkan sepeda
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.isIndo ? 'Silakan masukkan sepeda ke Dok $scannedDockCode sampai berbunyi klik!' : 'Please insert the bike into Dock $scannedDockCode until it clicks!'),
          duration: const Duration(seconds: 30),
          backgroundColor: AppTheme.primary(context),
        ),
      );
    }

    final response = await _dockService.waitForSensor(
      stationId: returnStationId,
      sensorPin: sensorPin is int ? sensorPin : int.tryParse(sensorPin.toString()) ?? (rawOrder - 1),
      timeoutSeconds: 30,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }


    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!response.success) {
      await _showErrorDialog(response.message);
      if (mounted) {
        setState(() => _isScanning = true);
        await _scannerController.start();
      }
      return;
    }

    // Sukses Lock Dock via MQTT, sekarang update Firestore
    try {
      await _firestoreService.completeTrip(
        tripId: widget.tripId,
        returnStationId: returnStationId,
        returnStationName: scannedStation,
        returnDockId: dockInfo['id'],
        bikeCode: widget.bikeCode,
      );

      // Sukses — navigasi ke Trip Summary
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TripSummaryScreen(
            fromStationName: widget.originStationName,
            toStationName: scannedStation,
            duration: widget.duration,
          ),
        ),
      );
    } catch (e) {
      await _showErrorDialog('Gagal memperbarui database: $e');
      if (mounted) {
        setState(() => _isScanning = true);
        await _scannerController.start();
      }
    }
  }

  Future<bool> _showDifferentStationDialog(String scannedStation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFE6A700)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.isIndo ? 'Stasiun Berbeda' : 'Different Station',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain(context),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.isIndo ? 'Kamu mengembalikan sepeda di "$scannedStation", '
          'bukan di "${widget.stationName}" (tujuan awal).\n\n'
          'Lanjutkan pengembalian di sini?' : 'You are returning the bike at "$scannedStation", '
          'not at "${widget.stationName}" (initial destination).\n\n'
          'Continue returning here?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textMain(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppLocalizations.tr('Cancel'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              AppLocalizations.isIndo ? 'Ya, Kembalikan' : 'Yes, Return',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        backgroundColor: AppTheme.surface(context),
      ),
    );
    return result ?? false;
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error(context)),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.isIndo ? 'Gagal Mengembalikan' : 'Failed to Return',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain(context),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textMain(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              AppLocalizations.isIndo ? 'Coba Lagi' : 'Try Again',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: AppTheme.primary(context),
              ),
            ),
          ),
        ],
        backgroundColor: AppTheme.surface(context),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: top ? BorderSide.none : const BorderSide(color: Colors.white, width: 4),
          left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: left ? BorderSide.none : const BorderSide(color: Colors.white, width: 4),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(top && left ? 12 : 0),
          topRight: Radius.circular(top && !left ? 12 : 0),
          bottomLeft: Radius.circular(!top && left ? 12 : 0),
          bottomRight: Radius.circular(!top && !left ? 12 : 0),
        ),
      ),
    );
  }
}
