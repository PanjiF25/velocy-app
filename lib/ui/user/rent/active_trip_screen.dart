import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:velocy_app/services/firestore_service.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:velocy_app/ui/user/rent/return_bike_screen.dart';
import 'package:velocy_app/core/utils/navigation_helper.dart';
import 'package:velocy_app/ui/user/stations/report_issue_sheet.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({
    super.key,
    required this.tripId,
    required this.bikeCode,
    required this.originStationName,
    required this.currentLocationLabel,
    required this.startTime,
    required this.destinationStationName,
  });

  final String tripId;
  final String bikeCode;
  final String originStationName;
  final String currentLocationLabel;
  final DateTime startTime;
  final String destinationStationName;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _destinationLatLng;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFetchingRoute = false;
  StreamSubscription<DocumentSnapshot>? _tripSubscription;

  Timer? _timer;
  Duration _elapsed = Duration.zero;


  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
    _initTrackingAndRoute();
    
    // Listen for force-ends from Admin
    _tripSubscription = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data != null && data['status'] == 'completed') {
        // Only trigger force-end alert if user hasn't naturally completed the flow
        // The natural return flow will pushReplacement so this listener might be unmounted,
        // but if it's still mounted, we check actualReturnStationName to confirm it was admin
        final returnName = data['actualReturnStationName'] as String?;
        if (mounted && returnName != null && returnName.contains('Force Ended')) {
          _showForceEndedDialog();
        }
      }
    });
  }

  Future<void> _showForceEndedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),
            SizedBox(width: 8),
            Text('Sesi Dihentikan', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Sesi perjalanan Anda telah dihentikan secara paksa oleh Admin.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              switchToTab(context, 0); // Go back to Home
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _initTrackingAndRoute() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Start location stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        // Push live location to Firestore
        FirebaseFirestore.instance.collection('trips').doc(widget.tripId).update({
          'currentLat': position.latitude,
          'currentLng': position.longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }
    });

    // Get current position once for initial routing
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      if (mounted) setState(() {});
    } catch (e) {}

    // Fetch destination station coordinates
    final stationData = await _firestoreService.getStationByName(widget.destinationStationName);
    if (stationData != null) {
      double lat = double.tryParse(stationData['lat']?.toString() ?? '') ?? 0.0;
      double lng = double.tryParse(stationData['lng']?.toString() ?? '') ?? 0.0;
      if (lat != 0.0 && lng != 0.0) {
        _destinationLatLng = LatLng(lat, lng);
        if (mounted) setState(() {});
        _fetchRoute();
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null || _destinationLatLng == null) return;
    if (_isFetchingRoute) return;
    _isFetchingRoute = true;
    try {
      final start = '${_currentPosition!.longitude},${_currentPosition!.latitude}';
      final end = '${_destinationLatLng!.longitude},${_destinationLatLng!.latitude}';
      final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/$start;$end?geometries=geojson&overview=full');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Routing error: $e');
    } finally {
      _isFetchingRoute = false;
    }
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
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
                      children: [    Positioned.fill(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentPosition != null 
                                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
                                  : LatLng(-7.2798, 112.7951),
                              initialZoom: 16.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.velocy_app',
                              ),
                              if (_routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      color: const Color(0xFF0F6E56),
                                      strokeWidth: 4.0,
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  if (_destinationLatLng != null)
                                    Marker(
                                      point: _destinationLatLng!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_on, color: Color(0xFFBA1A1A), size: 36),
                                    ),
                                  if (_currentPosition != null)
                                    Marker(
                                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      width: 18,
                                      height: 18,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: IconButton(
                                  icon: const Icon(Icons.my_location, color: Color(0xFF005440)),
                                  onPressed: () {
                                    if (_currentPosition != null) {
                                      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 16.0);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Text(
                                  '12 km/h',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF141B2B)),
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
                        onPressed: () => showReportIssueSheet(context, tripId: widget.tripId, bikeCode: widget.bikeCode),
                        icon: const Icon(Icons.report_problem, color: Color(0xFFBA1A1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReturnBikeScreen(
                                tripId: widget.tripId,
                                originStationName: widget.originStationName,
                                stationName: widget.originStationName,
                                bikeCode: widget.bikeCode,
                                duration: _elapsed,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBA1A1A),
                          side: const BorderSide(color: Color(0xFFBA1A1A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        child: const Text(
                          'Kembalikan',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
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
          tripId: widget.tripId,
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
