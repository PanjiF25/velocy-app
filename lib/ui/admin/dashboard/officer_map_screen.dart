import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:velocy_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velocy_app/ui/admin/navigation/officer_bottom_nav.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/ui/admin/tasks/officer_scanner_screen.dart';

class OfficerMapScreen extends StatefulWidget {
  const OfficerMapScreen({super.key});

  @override
  State<OfficerMapScreen> createState() => _OfficerMapScreenState();
}

class _OfficerMapScreenState extends State<OfficerMapScreen> {
  Color get _bgDark => AppTheme.bg(context);
  Color get _surfaceDark => AppTheme.surface(context);
  Color get _surfaceBorder => AppTheme.outline(context);
  Color get _primary => AppTheme.primary(context);
  Color get _textMain => AppTheme.textMain(context);
  Color get _textMuted => AppTheme.textMuted(context);
  
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  static const LatLng _itsCampusCenter = LatLng(-7.2798, 112.7951);

  Map<String, dynamic>? _selectedStation;
  bool _isPanelVisible = false;
  Position? _currentPosition;
  final String? _officerId = FirebaseAuth.instance.currentUser?.uid;
  final String? _officerName = FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email?.split('@').first;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 15.3);
        
        // Push initial location to Firestore
        if (_officerId != null) {
          _firestoreService.updateOfficerLocation(_officerId!, _officerName ?? 'Officer', position.latitude, position.longitude);
        }
      }
      
      // Start listening to location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          // Update location to Firestore
          if (_officerId != null) {
            _firestoreService.updateOfficerLocation(_officerId!, _officerName ?? 'Officer', position.latitude, position.longitude);
          }
        }
      });
    } catch (_) {}
  }

  void _onStationTapped(Map<String, dynamic> station) {
    setState(() {
      _selectedStation = station;
      _isPanelVisible = true;
    });
    
    // Pan map to the selected station
    double lat = double.tryParse(station['lat']?.toString() ?? '') ?? 0.0;
    double lng = double.tryParse(station['lng']?.toString() ?? '') ?? 0.0;
    _mapController.move(LatLng(lat, lng), 16.0);
  }

  void _closePanel() {
    setState(() {
      _isPanelVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // 1. Full Screen Map
          GestureDetector(
            onTap: _closePanel, // Tap anywhere on map to close panel
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _itsCampusCenter,
                initialZoom: 15.3,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
              ),
              children: [
                if (AppTheme.isDark(context))
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1, 0, 0, 0, 255,
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Color(0xFF222222), BlendMode.saturation),
                      child: TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.velocy_app',
                      ),
                    ),
                  )
                else
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.velocy_app',
                  ),
                // Real Markers from Firestore
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getStationsStream(),
                  builder: (context, snapshot) {
                    final stations = snapshot.data ?? [];
                    final markersList = stations.map((station) {
                        double lat = double.tryParse(station['lat']?.toString() ?? '') ?? 0.0;
                        double lng = double.tryParse(station['lng']?.toString() ?? '') ?? 0.0;
                        final isSelected = _isPanelVisible && _selectedStation?['id'] == station['id'];

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            onTap: () => _onStationTapped(station),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 40 : 32,
                                height: isSelected ? 40 : 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : _primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? _primary : Colors.white, width: isSelected ? 3 : 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withValues(alpha: isSelected ? 0.8 : 0.4),
                                      blurRadius: isSelected ? 16 : 8,
                                      spreadRadius: isSelected ? 4 : 2,
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.ev_station, 
                                  color: isSelected ? _primary : Colors.white, 
                                  size: isSelected ? 24 : 18
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList();

                      if (_currentPosition != null) {
                        markersList.add(
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6), // Blue 500
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return MarkerLayer(
                        markers: markersList,
                      );
                  },
                ),
              ],
            ),
          ),
          
          // Dark tint overlay to make it match the UI perfectly
          IgnorePointer(
            child: Container(
              color: AppTheme.isDark(context) ? const Color(0x33000000) : const Color(0x11000000),
            ),
          ),

          // 2. Top App Bar Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Map Badge
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location, color: _primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Live Map',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Filter Button
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context).withOpacity(0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: _surfaceBorder),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_list, color: _textMain, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filter options')));
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Dynamic Bottom Sheet Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: _isPanelVisible ? MediaQuery.of(context).padding.bottom + 90 : -300,
            left: 16,
            right: 16,
            child: _buildStationDetailsPanel(),
          ),

          // 4. Bottom Nav
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: OfficerBottomNav(currentIndex: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildStationDetailsPanel() {
    if (_selectedStation == null) return const SizedBox.shrink();

    final String name = _selectedStation!['name'] ?? 'Unknown Station';
    final String stationId = _selectedStation!['id'];

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getDocksStreamForStation(stationId),
      builder: (context, snapshot) {
        int availableBikes = 0;
        int emptyDocks = 0;

        if (snapshot.hasData) {
          final docks = snapshot.data!;
          availableBikes = docks.where((d) => d['status'] == 'occupied').length;
          emptyDocks = docks.where((d) => d['status'] == 'available').length;
        }

        return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface(context).withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle pill and Close Button
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 5) {
                    _closePanel();
                  }
                },
                child: Container(
                  color: Colors.transparent, // expand tap area
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 24,
                      ),
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _surfaceBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: _closePanel,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: _textMuted, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: _textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Station Area • 1.2km away',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant(context),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.directions, color: _textMain, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Get directions')));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.pedal_bike, color: _primary, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AVAILABLE', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 0.5)),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: '$availableBikes', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: _textMain)),
                                      TextSpan(text: '/${availableBikes + emptyDocks}', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: _textMuted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.local_parking, color: _textMuted, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMPTY', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 0.5)),
                                Text('$emptyDocks', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: _textMain)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfficerScannerScreen(mode: ScannerMode.dropOff),
                          ),
                        );
                      },
                      icon: const Icon(Icons.south_east, size: 20),
                      label: const Text('Drop-off Bikes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfficerScannerScreen(mode: ScannerMode.pickUp),
                          ),
                        );
                      },
                      icon: const Icon(Icons.north_west, size: 20),
                      label: const Text('Pick-up Bikes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMain,
                        side: BorderSide(color: AppTheme.outline(context)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  });
}
}
