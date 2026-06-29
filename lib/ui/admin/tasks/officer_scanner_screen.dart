import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:velocy_app/services/dock_unlock_service.dart';
import 'package:velocy_app/core/utils/qr_helper.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ScannerMode { general, pickUp, dropOff }

class OfficerScannerScreen extends StatefulWidget {
  final ScannerMode mode;
  const OfficerScannerScreen({super.key, this.mode = ScannerMode.general});

  @override
  State<OfficerScannerScreen> createState() => _OfficerScannerScreenState();
}

class _OfficerScannerScreenState extends State<OfficerScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  final TextEditingController _idController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasScanned = false;
  bool _isUnlocking = false;
  bool _isMarkingBroken = false;
  bool _isManualInput = false;
  bool _isProcessingDropOff = false;
  bool _isProcessingPickUp = false;

  final DockUnlockService _dockUnlockService = const DockUnlockService(
    useMock: false,
    brokerHost: 'ed8353af22094db7abcc96751b2e696d.s1.eu.hivemq.cloud',
    brokerPort: 8883,
    secure: true,
    topicPrefix: 'velocy/dock',
    clientId: 'velocy_app_officer',
    username: 'velocy',
    password: 'Velocy123',
  );
  final FirestoreService _firestoreService = FirestoreService();



  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _scannerController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _handleManualSubmit() {
    FocusScope.of(context).unfocus();
    if (_idController.text.trim().isNotEmpty) {
      setState(() {
        _hasScanned = true;
        _isManualInput = false;
      });
    }
  }

  void _handleUnlockDock() {
    final qrValue = _idController.text.trim();
    if (qrValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.isIndo ? 'ID kosong. Harap scan atau ketik ID dok.' : 'ID is empty. Please scan or type dock ID.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant(context),
        title: Text(AppLocalizations.isIndo ? 'Konfirmasi' : 'Confirmation', style: TextStyle(color: AppTheme.textMain(context))),
        content: Text(AppLocalizations.isIndo ? 'Yakin ingin membuka solenoid dok secara langsung dengan Master Key?' : 'Are you sure you want to open the dock solenoid directly with the Master Key?', style: TextStyle(color: AppTheme.textMuted(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.isIndo ? 'Batal' : 'Cancel', style: TextStyle(color: AppTheme.textMuted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary(context), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _executeUnlockDock(qrValue);
            },
            child: Text(AppLocalizations.isIndo ? 'Buka Kunci' : 'Unlock'),
          ),
        ],
      ),
    );
  }

  void _executeUnlockDock(String qrValue) async {
    setState(() => _isUnlocking = true);
    
    try {
      final parsed = QrHelper.parseQr(qrValue);
      final stationName = parsed['stationName'] ?? '';
      final dockCode = parsed['dockCode'] ?? '';
      
      final stationInfo = await _firestoreService.getStationByName(stationName);
      if (stationInfo == null) {
        throw Exception(AppLocalizations.isIndo ? 'Stasiun tidak ditemukan di database.' : 'Station not found in database.');
      }
      final stationId = stationInfo['id'];
      
      final docks = await _firestoreService.getDocksStreamForStation(stationId).first;
      final dockInfo = docks.firstWhere((d) {
        final code = d['dockCode'] ?? d['number'] ?? '';
        return code.toString().toUpperCase() == dockCode.toUpperCase() || 
               code.toString().toUpperCase() == 'D${dockCode.toUpperCase()}';
      }, orElse: () => <String, dynamic>{});
      
      final relayPin = dockInfo['relayPin'];
      if (relayPin == null) {
        throw Exception(AppLocalizations.isIndo ? 'Relay Pin tidak dikonfigurasi untuk dok ini.' : 'Relay Pin is not configured for this dock.');
      }

      final response = await _dockUnlockService.unlockDock(
        DockUnlockRequest(
          qrValue: qrValue,
          bikeCode: 'MASTER_KEY',
          dockCode: dockCode,
          stationName: stationName,
          stationId: stationId,
          relayPin: relayPin,
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal: $e' : 'Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUnlocking = false);
      }
    }
  }

  Future<void> _handleMarkBroken() async {
    if (_idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.isIndo ? 'Tidak ada data yang di-scan' : 'No data scanned')),
      );
      return;
    }

    setState(() => _isMarkingBroken = true);

    try {
      final parsed = QrHelper.parseQr(_idController.text);
      await _firestoreService.markItemAsBroken(parsed);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Berhasil menandai sebagai rusak' : 'Successfully marked as broken')),
        );
        setState(() {
          _hasScanned = false;
          _idController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal: $e' : 'Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingBroken = false);
      }
    }
  }

  void _handlePickUp() async {
    final qrValue = _idController.text.trim();
    if (qrValue.isEmpty) return;

    setState(() => _isProcessingPickUp = true);

    try {
      final parsed = QrHelper.parseQr(qrValue);
      final stationName = parsed['stationName'] ?? '';
      final dockCode = parsed['dockCode'] ?? '';

      final stationInfo = await _firestoreService.getStationByName(stationName);
      if (stationInfo == null) throw Exception('Station not found');
      final stationId = stationInfo['id'];

      final docks = await _firestoreService.getDocksStreamForStation(stationId).first;
      final dockInfo = docks.firstWhere((d) {
        final code = d['dockCode'] ?? d['number'] ?? '';
        return code.toString().toUpperCase() == dockCode.toUpperCase() ||
               code.toString().toUpperCase() == 'D${dockCode.toUpperCase()}';
      }, orElse: () => <String, dynamic>{});
      
      final dockId = dockInfo['id'];
      if (dockId == null) throw Exception('Dock not found');
      
      final currentBikeCode = dockInfo['currentBikeCode'];
      if (currentBikeCode == null || dockInfo['status'] != 'occupied') {
        throw Exception(AppLocalizations.isIndo ? 'Dok kosong, tidak ada sepeda untuk diambil.' : 'Dock is empty, no bike to pick up.');
      }

      final relayPin = dockInfo['relayPin'];
      if (relayPin == null) throw Exception('Relay Pin is not configured.');

      // 1. Unlock Dock
      await _dockUnlockService.unlockDock(
        DockUnlockRequest(
          qrValue: qrValue,
          bikeCode: 'PICKUP',
          dockCode: dockCode,
          stationName: stationName,
          stationId: stationId,
          relayPin: relayPin,
        ),
      );

      // 2. Process Pick up in Firestore
      await _firestoreService.pickUpBike(dockId: dockId, bikeCode: currentBikeCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Berhasil mengambil sepeda!' : 'Successfully picked up bike!')),
        );
        setState(() {
          _hasScanned = false;
          _idController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPickUp = false);
      }
    }
  }

  void _handleDropOff() async {
    final qrValue = _idController.text.trim();
    if (qrValue.isEmpty) return;

    final TextEditingController bikeCodeController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant(context),
        title: Text(AppLocalizations.isIndo ? 'Masukkan Kode Sepeda' : 'Enter Bike Code', style: TextStyle(color: AppTheme.textMain(context))),
        content: TextField(
          controller: bikeCodeController,
          style: TextStyle(color: AppTheme.textMain(context)),
          decoration: InputDecoration(
            hintText: 'Contoh: B-001',
            hintStyle: TextStyle(color: AppTheme.textMuted(context)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.isIndo ? 'Batal' : 'Cancel', style: TextStyle(color: AppTheme.textMuted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary(context), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _executeDropOff(qrValue, bikeCodeController.text.trim());
            },
            child: Text(AppLocalizations.isIndo ? 'Lanjut' : 'Continue'),
          ),
        ],
      ),
    );
  }

  void _executeDropOff(String qrValue, String bikeCode) async {
    if (bikeCode.isEmpty) return;
    setState(() => _isProcessingDropOff = true);
    bool dialogShown = false;

    try {
      final parsed = QrHelper.parseQr(qrValue);
      final stationName = parsed['stationName'] ?? '';
      final dockCode = parsed['dockCode'] ?? '';

      final stationInfo = await _firestoreService.getStationByName(stationName);
      if (stationInfo == null) throw Exception('Station not found');
      final stationId = stationInfo['id'];

      final docks = await _firestoreService.getDocksStreamForStation(stationId).first;
      final dockInfo = docks.firstWhere((d) {
        final code = d['dockCode'] ?? d['number'] ?? '';
        return code.toString().toUpperCase() == dockCode.toUpperCase() ||
               code.toString().toUpperCase() == 'D${dockCode.toUpperCase()}';
      }, orElse: () => <String, dynamic>{});
      
      final dockId = dockInfo['id'];
      if (dockId == null) throw Exception('Dock not found');
      
      if (dockInfo['status'] == 'occupied') {
        throw Exception(AppLocalizations.isIndo ? 'Dok sudah terisi!' : 'Dock is already occupied!');
      }

      if (mounted) {
        dialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceVariant(context),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Expanded(child: Text(AppLocalizations.isIndo ? 'Silakan masukkan sepeda ke dok... Menunggu limit switch...' : 'Please push bike into dock... Waiting for limit switch...', style: TextStyle(color: AppTheme.textMain(context)))),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      int sensorPin = dockInfo['sensorPin'] is int 
          ? dockInfo['sensorPin'] 
          : (int.tryParse(dockInfo['sensorPin']?.toString() ?? '') ?? (int.tryParse(dockInfo['number']?.toString() ?? '1') ?? 1) - 1);

      final response = await _dockUnlockService.waitForSensor(
        stationId: stationId,
        sensorPin: sensorPin,
        timeoutSeconds: 30,
      );

      if (!response.success) {
        throw Exception(response.message);
      }

      await _firestoreService.dropOffBike(dockId: dockId, bikeCode: bikeCode, stationId: stationId);

      if (mounted) {
        if (dialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
          dialogShown = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Berhasil menaruh sepeda!' : 'Successfully dropped off bike!')),
        );
        setState(() {
          _hasScanned = false;
          _idController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        if (dialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingDropOff = false);
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _hasScanned = true;
          _idController.text = barcode.rawValue!;
        });
        _handleManualSubmit();
        

        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Upper 70%: Camera Viewfinder
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.75, // Overlap a bit
            child: _buildCameraView(),
          ),

          // Lower 30%: Bottom Sheet UI
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Real Camera Feed
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          fit: BoxFit.cover,
        ),
        
        // Dark Gradient Overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000), // black/60
                Colors.transparent,
                Color(0xCC000000), // black/80
              ],
            ),
          ),
        ),

        // Top Bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassIconButton(context, 
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
              Text(
                AppLocalizations.isIndo ? 'PEMINDAI' : 'SCANNER',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppTheme.textMain(context),
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              _buildGlassIconButton(context, 
                icon: Icons.flashlight_on,
                onTap: () {
                  _scannerController.toggleTorch();
                },
              ),
            ],
          ),
        ),

        // Scanner Reticle
        Center(
          child: Container(
            width: 256, // 64 * 4
            height: 256,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary(context).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Corners
                _buildReticleCorner(context, top: 0, left: 0, borderTop: true, borderLeft: true),
                _buildReticleCorner(context, top: 0, right: 0, borderTop: true, borderRight: true),
                _buildReticleCorner(context, bottom: 0, left: 0, borderBottom: true, borderLeft: true),
                _buildReticleCorner(context, bottom: 0, right: 0, borderBottom: true, borderRight: true),
                
                // Scan Line
                AnimatedBuilder(
                  animation: _scanAnimationController,
                  builder: (context, child) {
                    final value = _scanAnimationController.value;
                    double opacity = 1.0;
                    if (value < 0.1) opacity = value * 10;
                    if (value > 0.9) opacity = (1.0 - value) * 10;
                    
                    return Positioned(
                      top: 256 * value,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primary(context), blurRadius: 10),
                              BoxShadow(color: AppTheme.primary(context), blurRadius: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Scanning Instructions Overlay
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.15,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.outline(context).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.primary(context), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    widget.mode == ScannerMode.pickUp ? (AppLocalizations.isIndo ? 'ARAHKAN DOK UNTUK MENGAMBIL' : 'ALIGN DOCK TO PICK UP') :
                    widget.mode == ScannerMode.dropOff ? (AppLocalizations.isIndo ? 'ARAHKAN DOK UNTUK MENARUH' : 'ALIGN DOCK TO DROP OFF') :
                    (AppLocalizations.isIndo ? 'ARAHKAN KODE QR KE DALAM BINGKAI' : 'ALIGN QR CODE WITHIN FRAME'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppTheme.textMain(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReticleCorner(BuildContext context, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool borderTop = false,
    bool borderBottom = false,
    bool borderLeft = false,
    bool borderRight = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: borderTop ? BorderSide(color: AppTheme.primary(context), width: 4) : BorderSide.none,
            bottom: borderBottom ? BorderSide(color: AppTheme.primary(context), width: 4) : BorderSide.none,
            left: borderLeft ? BorderSide(color: AppTheme.primary(context), width: 4) : BorderSide.none,
            right: borderRight ? BorderSide(color: AppTheme.primary(context), width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surface(context).withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.outline(context).withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppTheme.textMain(context)),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.outline(context).withOpacity(0.2))), // outline-variant/20
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            // Swipe down to clear
            setState(() {
              _hasScanned = false;
              _isManualInput = false;
              _idController.clear();
            });
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.outline(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          
          // Title & Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.mode == ScannerMode.pickUp ? (AppLocalizations.isIndo ? 'Pindai Dok (Pick-up)' : 'Scan Dock (Pick-up)') :
                widget.mode == ScannerMode.dropOff ? (AppLocalizations.isIndo ? 'Pindai Dok (Drop-off)' : 'Scan Dock (Drop-off)') :
                (AppLocalizations.isIndo ? 'Pindai QR Dok atau Sepeda' : 'Scan Dock or Bike QR'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppTheme.textMain(context),
                ),
              ),
              if (_hasScanned)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.qr_code_scanner, color: AppTheme.primary(context), size: 20),
                      tooltip: AppLocalizations.isIndo ? 'Pindai Ulang' : 'Scan Again',
                      onPressed: () {
                        setState(() {
                          _hasScanned = false;
                          _isManualInput = false;
                          _idController.clear();
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: AppTheme.textMuted(context), size: 20),
                      tooltip: AppLocalizations.isIndo ? 'Input Manual' : 'Manual Input',
                      onPressed: () {
                        setState(() {
                          _isManualInput = true;
                        });
                      },
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Area (Manual Input OR Parsed Card)
          if (!_hasScanned || _isManualInput)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.keyboard, color: AppTheme.textMuted(context), size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _idController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.textMain(context),
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.isIndo ? 'Masukkan ID manual...' : 'Enter ID manually...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.textMuted(context).withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleManualSubmit,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.outline(context).withOpacity(0.3)),
                          ),
                          child: Text(
                            'GO',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppTheme.textMain(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Builder(builder: (context) {
              final parsed = QrHelper.parseQr(_idController.text);
              final isBike = parsed.containsKey('bikeCode');

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant(context).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary(context).withOpacity(0.3)),
                ),
                child: isBike
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pedal_bike, color: AppTheme.primary(context), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.isIndo ? 'Sepeda: ${parsed['bikeCode']}' : 'Bike: ${parsed['bikeCode']}',
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
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppTheme.primary(context), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.isIndo ? 'Stasiun: ${parsed['stationName'] ?? 'Stasiun Tidak Diketahui'}' : 'Station: ${parsed['stationName'] ?? 'Unknown Station'}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.dock, color: AppTheme.primary(context), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.isIndo ? 'Nomor Dok: ${parsed['dockCode'] ?? '-'}' : 'Dock Number: ${parsed['dockCode'] ?? '-'}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              );
            }),
          
          const SizedBox(height: 24),

          // Action Buttons
          if (widget.mode == ScannerMode.pickUp)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context, 
                    icon: Icons.upload_rounded,
                    label: AppLocalizations.isIndo ? 'Ambil Sepeda (Pick-up)' : 'Pick-up Bike',
                    color: AppTheme.primary(context),
                    borderColor: AppTheme.primary(context),
                    onTap: _isProcessingPickUp ? () {} : _handlePickUp,
                    isLoading: _isProcessingPickUp,
                  ),
                ),
              ],
            )
          else if (widget.mode == ScannerMode.dropOff)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context, 
                    icon: Icons.download_rounded,
                    label: AppLocalizations.isIndo ? 'Taruh Sepeda (Drop-off)' : 'Drop-off Bike',
                    color: AppTheme.primary(context),
                    borderColor: AppTheme.primary(context),
                    onTap: _isProcessingDropOff ? () {} : _handleDropOff,
                    isLoading: _isProcessingDropOff,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(context, 
                    icon: Icons.key,
                    label: AppLocalizations.isIndo ? 'Buka Dok' : 'Unlock Dock',
                    subLabel: '(Master Key)',
                    color: AppTheme.textMain(context),
                    borderColor: AppTheme.outline(context).withOpacity(0.5),
                    onTap: (_isUnlocking || _isMarkingBroken) ? () {} : _handleUnlockDock,
                    isLoading: _isUnlocking,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(context, 
                    icon: Icons.build,
                    label: AppLocalizations.isIndo ? 'Tandai Rusak' : 'Mark Broken',
                    color: AppTheme.error(context),
                    borderColor: AppTheme.error(context).withOpacity(0.3),
                    onTap: (_isUnlocking || _isMarkingBroken) ? () {} : _handleMarkBroken,
                    isLoading: _isMarkingBroken,
                  ),
                ),
              ],
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    String? subLabel,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
              if (subLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
