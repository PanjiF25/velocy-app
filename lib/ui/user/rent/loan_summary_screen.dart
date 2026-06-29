import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velocy_app/services/dock_unlock_service.dart';
import 'package:velocy_app/ui/user/rent/active_trip_screen.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/common/widgets/pulsing_radar.dart';

class LoanSummaryScreen extends StatefulWidget {
  const LoanSummaryScreen({
    super.key,
    required this.qrValue,
    required this.originStationId,
    required this.originStationName,
    required this.originDockLabel,
    required this.originDockCode,
    required this.destinationStation,
  });

  final String qrValue;
  final String originStationId;
  final String originStationName;
  final String originDockLabel;
  final String originDockCode;
  final Map<String, dynamic> destinationStation;

  @override
  State<LoanSummaryScreen> createState() => _LoanSummaryScreenState();
}

class _LoanSummaryScreenState extends State<LoanSummaryScreen> {
  final DockUnlockService _dockUnlockService = const DockUnlockService(
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
  bool _isSubmitting = false;

  Future<void> _handleStartBorrow() async {
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog(AppLocalizations.isIndo ? 'Harap login ulang untuk meminjam sepeda.' : 'Please re-login to borrow a bike.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    
    _showProcessingDialog();

    try {
      // 1. Dapatkan informasi dock untuk tahu bikeCode apa yang terpasang
      final dockInfo = await _firestoreService.getDockByCode(widget.originStationId, widget.originDockCode);
      if (dockInfo == null || dockInfo['currentBikeCode'] == null) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(AppLocalizations.isIndo ? 'Dok tidak memiliki sepeda atau tidak ditemukan di database.' : 'Dock has no bike or not found in database.');
        return;
      }
      final bikeCode = dockInfo['currentBikeCode'] as String;
      final originDockId = dockInfo['id'] as String;

      // 2. Buka kunci via MQTT
      final response = await _dockUnlockService.unlockDock(
        DockUnlockRequest(
          qrValue: widget.qrValue,
          bikeCode: bikeCode,
          dockCode: widget.originDockCode,
          stationName: widget.originStationName,
          stationId: widget.originStationId,
          relayPin: dockInfo['relayPin'] ?? 0,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close processing dialog

      if (!response.success) {
        setState(() => _isSubmitting = false);
        _showErrorDialog(response.message);
        return;
      }

      // 3. Catat di Firestore
      final tripId = await _firestoreService.startTrip(
        userId: user.uid,
        bikeCode: bikeCode,
        originStationId: widget.originStationId,
        originStationName: widget.originStationName,
        originDockId: originDockId,
        destinationStationId: widget.destinationStation['id'],
        destinationStationName: widget.destinationStation['name'],
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop(); // Close processing dialog

      // 4. Lanjut ke layar Active Trip
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ActiveTripScreen(
            tripId: tripId,
            bikeCode: bikeCode,
            originStationName: widget.originStationName,
            currentLocationLabel: widget.originStationName,
            startTime: DateTime.now(),
            destinationStationName: widget.destinationStation['name'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(); // Close processing dialog
        _showErrorDialog(AppLocalizations.isIndo ? 'Terjadi kesalahan saat memproses data: $e' : 'Error processing data: $e');
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsingRadar(color: Colors.white, size: 100, icon: Icons.lock_open),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.isIndo ? 'Membuka Kunci...' : 'Unlocking...',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.error(context)),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.isIndo ? 'Gagal Membuka Kunci' : 'Failed to Unlock',
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
              AppLocalizations.tr('Close'),
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
          AppLocalizations.isIndo ? 'Konfirmasi Peminjaman' : 'Loan Confirmation',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary(context),
          ),
        ),
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
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.outline(context)),
                            boxShadow: [
                              if (!AppTheme.isDark(context))
                                const BoxShadow(
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
                                  iconColor: AppTheme.primary(context),
                                  label: AppLocalizations.isIndo ? 'STASIUN AWAL' : 'ORIGIN STATION',
                                  title: widget.originStationName,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary(context).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.dock, size: 16, color: AppTheme.textMain(context)),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.isIndo ? 'Nomor Dok: ${widget.originDockCode}' : 'Dock Number: ${widget.originDockCode}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          color: AppTheme.textMain(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: AppTheme.outline(context)),
                                const SizedBox(height: 12),
                                _SectionRow(
                                  icon: Icons.flag,
                                  iconColor: const Color(0xFF1960A6),
                                  label: AppLocalizations.isIndo ? 'STASIUN TUJUAN' : 'DESTINATION STATION',
                                  title: widget.destinationStation['name'],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: AppTheme.outline(context)),
                                const SizedBox(height: 12),
                                _DetailLine(
                                  icon: Icons.pedal_bike,
                                  title: AppLocalizations.isIndo ? 'Sepeda' : 'Bike',
                                  value: AppLocalizations.isIndo ? 'Akan ditentukan sistem' : 'To be determined by system',
                                ),
                                const SizedBox(height: 12),
                                _DetailLine(
                                  icon: Icons.timer,
                                  title: AppLocalizations.isIndo ? 'Estimasi' : 'Estimation',
                                  value: AppLocalizations.isIndo ? 'Berdasarkan jarak ± 5 menit' : 'Based on distance ± 5 minutes',
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
                            color: AppTheme.surfaceVariant(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.outline(context)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_outlined, color: AppTheme.primary(context)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      height: 1.4,
                                      color: AppTheme.textMain(context),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: AppLocalizations.isIndo ? '⚠️ Pastikan kamu sudah siap... ' : '⚠️ Make sure you are ready... ',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: AppLocalizations.isIndo ? 'Solenoid kunci akan terbuka segera setelah kamu mengonfirmasi peminjaman.' : 'The lock solenoid will open as soon as you confirm the loan.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.isIndo ? 'Dengan memulai sewa, kamu setuju untuk mengembalikan sepeda ke stasiun tujuan yang dipilih.' : 'By starting the rental, you agree to return the bike to the selected destination station.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.textMuted(context),
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
            decoration: BoxDecoration(
              color: AppTheme.bg(context),
              border: Border(top: BorderSide(color: AppTheme.outline(context))),
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
                          backgroundColor: AppTheme.primary(context),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.primary(context).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? (AppLocalizations.isIndo ? 'Memproses...' : 'Processing...') : (AppLocalizations.isIndo ? 'Mulai Pinjam Sekarang' : 'Start Borrowing Now'),
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
                          foregroundColor: AppTheme.primary(context),
                          side: BorderSide(color: AppTheme.primary(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.isIndo ? 'Ganti Stasiun Tujuan' : 'Change Destination Station',
                          style: const TextStyle(
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
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain(context),
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
        Icon(icon, color: AppTheme.textMuted(context), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.textMuted(context),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.textMain(context),
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
