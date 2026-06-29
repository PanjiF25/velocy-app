import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:velocy_app/core/utils/navigation_helper.dart';
import 'package:velocy_app/ui/user/stations/station_detail_screen.dart';
import 'package:velocy_app/ui/user/rent/active_trip_screen.dart' as velocy_active_trip;
import 'package:velocy_app/ui/common/widgets/exit_confirmation_wrapper.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/core/providers/settings_provider.dart';
import 'package:velocy_app/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const LatLng _itsCampusCenter = LatLng(-7.2798, 112.7951);
  LatLng? _currentPosition;
  final MapController _mapController = MapController();

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

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition!, 15.3);
    }
  }

  Future<String> _loadGreetingName() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return 'Pengguna';
    }

    final profileSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
    final profile = profileSnapshot.data();

    final displayName = (profile?['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final authDisplayName = authUser.displayName?.trim();
    if (authDisplayName != null && authDisplayName.isNotEmpty) {
      return authDisplayName;
    }

    final email = authUser.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsProvider(),
      builder: (context, _) {
        return ExitConfirmationWrapper(
          child: Scaffold(
            backgroundColor: AppTheme.bg(context),
            appBar: AppBar(
              backgroundColor: AppTheme.bg(context),
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'Velocy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary(context),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, 
                    color: AppTheme.textMuted(context)
                  ),
                  onPressed: () {
                    final settings = SettingsProvider();
                    settings.setThemeMode(Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.language, color: AppTheme.textMuted(context)),
                  onPressed: () {
                    final settings = SettingsProvider();
                    settings.setLocale(
                      settings.locale.languageCode == 'id' ? const Locale('en') : const Locale('id')
                    );
                  },
                ),
              ],
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: FutureBuilder<String>(
                future: _loadGreetingName(),
                builder: (context, snapshot) {
                  final greetingName = snapshot.data ?? 'Pengguna';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $greetingName!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mau ke mana hari ini?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // No active trip banner

            // Map Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Peta Stasiun',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain(context),
                        ),
                      ),
                      Row(
                        children: [
                          _buildLegendItem(const Color(0xFF00543C), 'Tersedia'),
                          const SizedBox(width: 12),
                          _buildLegendItem(Colors.yellow.shade600, 'Sedang'),
                          const SizedBox(width: 12),
                          _buildLegendItem(const Color(0xFFBA1A1A), 'Penuh'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFBEC9C3)),
                        color: const Color(0xFFF3F7F5),
                      ),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _itsCampusCenter,
                              initialZoom: 15.3,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.drag |
                                    InteractiveFlag.pinchZoom |
                                    InteractiveFlag.doubleTapZoom,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.velocy_app',
                              ),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: FirestoreService().getStationsWithBikeCountStream(),
                                builder: (context, snapshot) {
                                  final stations = snapshot.data ?? [];
                                  return MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _currentPosition ?? _itsCampusCenter,
                                        width: 18,
                                        height: 18,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                      ...stations.map((station) {
                                        final latVal = station['lat'];
                                        final lngVal = station['lng'];
                                        if (latVal == null || lngVal == null) return null;
                                        final lat = (latVal is num) ? latVal.toDouble() : double.tryParse(latVal.toString());
                                        final lng = (lngVal is num) ? lngVal.toDouble() : double.tryParse(lngVal.toString());
                                        if (lat == null || lng == null) return null;
                                        
                                        final point = LatLng(lat, lng);
                                        final availableBikes = station['availableBikes'] ?? 0;
                                        final totalDocks = station['totalDocks'] ?? 0;
                                        
                                        Color markerColor = const Color(0xFFBA1A1A); // Merah (Penuh / Kosong)
                                        if (availableBikes > 0 && availableBikes < totalDocks) {
                                          markerColor = const Color(0xFFF6B700); // Kuning (Sedang)
                                        } else if (availableBikes > 0) {
                                          markerColor = const Color(0xFF00543C); // Hijau (Tersedia)
                                        }

                                          return Marker(
                                            point: point,
                                            width: 120,
                                            height: 80,
                                            child: GestureDetector(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                                  ),
                                                  builder: (context) => Padding(
                                                    padding: const EdgeInsets.all(24.0),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          station['name'] ?? 'Stasiun',
                                                          style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          station['address'] ?? 'Alamat tidak tersedia',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: AppTheme.textMuted(context),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 24),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                          children: [
                                                            Column(
                                                              children: [
                                                                Icon(Icons.pedal_bike, size: 32, color: AppTheme.primary(context)),
                                                                const SizedBox(height: 8),
                                                                const Text('Sepeda', style: TextStyle(fontWeight: FontWeight.w600)),
                                                                Text('$availableBikes Tersedia', style: const TextStyle(fontSize: 16)),
                                                              ],
                                                            ),
                                                            Column(
                                                              children: [
                                                                Icon(Icons.local_parking, size: 32, color: AppTheme.primary(context)),
                                                                const SizedBox(height: 8),
                                                                const Text('Dock', style: TextStyle(fontWeight: FontWeight.w600)),
                                                                Text('$totalDocks Total', style: const TextStyle(fontSize: 16)),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 24),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: _DashboardMarker(
                                                color: markerColor,
                                                availableBikes: availableBikes,
                                                stationName: station['name'] ?? 'Stasiun',
                                              ),
                                            ),
                                          );
                                      }).whereType<Marker>(),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: IconButton(
                                icon: const Icon(Icons.my_location, color: Color(0xFF005440)),
                                onPressed: _getCurrentLocation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.touch_app, size: 14, color: AppTheme.textMuted(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Ketuk marker untuk detail stasiun',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Rent Card
            StreamBuilder<Map<String, dynamic>?>(
              stream: FirestoreService().getActiveTripStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                // Jika sedang loading atau ada trip aktif, sembunyikan card
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Bisa juga kasih shimmer, tapi shrink agar tidak lompat
                }
                final activeTrip = snapshot.data;
                if (activeTrip != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        // Pergi ke ActiveTripScreen
                        final startTime = (activeTrip['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => 
                          velocy_active_trip.ActiveTripScreen(
                            tripId: activeTrip['id'],
                            bikeCode: activeTrip['bikeCode'] ?? 'Unknown',
                            originStationName: activeTrip['originStationName'] ?? 'Stasiun',
                            destinationStationName: activeTrip['destinationStationName'] ?? 'Tujuan',
                            currentLocationLabel: 'Lokasi Saat Ini',
                            startTime: startTime,
                          )
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.primary(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions_bike, color: AppTheme.primary(context), size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perjalanan Sedang Berlangsung',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ketuk untuk melihat rute dan waktu',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppTheme.textMuted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: AppTheme.primary(context), size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Tampilkan card Pinjam Sepeda jika TIDAK ada trip aktif

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      switchToTab(context, 1); // 1 = Tab NavRent
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outline(context)),
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
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F3FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code_scanner, color: Color(0xFF005440), size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pinjam Sepeda',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Arahkan kamera ke QR Code di sepeda atau stasiun',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),


            // Nearby Stations
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stasiun Terdekat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMain(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirestoreService().getStationsWithBikeCountStream(),
                      builder: (context, snapshot) {
                        final stations = snapshot.data ?? [];
                        if (stations.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: stations.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final station = stations[index];
                            final availableBikes = station['availableBikes'] ?? 0;
                            final totalDocks = station['totalDocks'] ?? 0;
                            final progress = totalDocks > 0 ? availableBikes / totalDocks : 0.0;

                            String badgeText = 'Kosong';
                            Color badgeBgColor = const Color(0xFFFFDAD6);
                            Color badgeTextColor = const Color(0xFF410002);

                            if (availableBikes > 0 && availableBikes < totalDocks) {
                              badgeText = 'Sedang';
                              badgeBgColor = const Color(0xFFFFF0C3);
                              badgeTextColor = const Color(0xFF241A00);
                            } else if (availableBikes > 0) {
                              badgeText = 'Tersedia';
                              badgeBgColor = const Color(0xFF86F8C9);
                              badgeTextColor = const Color(0xFF002115);
                            }

                            return _buildStationCard(
                              station['name'] ?? 'Stasiun',
                              availableBikes,
                              progress,
                              badgeBgColor,
                              badgeText,
                              badgeTextColor,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48), // Padding bottom
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          if (index == _selectedIndex) {
            return;
          }

          setState(() {
            _selectedIndex = index;
          });

          switchToTab(context, index);
        },
        backgroundColor: AppTheme.surface(context),
        indicatorColor: AppTheme.primary(context),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.textMuted(context)),
            selectedIcon: Icon(Icons.home, color: AppTheme.surface(context)),
            label: AppLocalizations.tr('NavHome'),
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner, color: AppTheme.textMuted(context)),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.surface(context)),
            label: AppLocalizations.tr('NavRent'),
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bike, color: AppTheme.textMuted(context)),
            selectedIcon: Icon(Icons.directions_bike, color: AppTheme.surface(context)),
            label: AppLocalizations.tr('NavTrip'),
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppTheme.textMuted(context)),
            selectedIcon: Icon(Icons.person, color: AppTheme.surface(context)),
            label: AppLocalizations.tr('NavProfile'),
          ),
        ],
      ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard(String title, int bikes, double progress,
      Color badgeColor, String badgeText, Color badgeTextColor) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.directions_bike, size: 18, color: AppTheme.textMuted(context)),
              const SizedBox(width: 6),
              Text(
                '$bikes Sepeda Tersedia',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.textMuted(context),
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFDCE2F7),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F6E56)),
            borderRadius: BorderRadius.circular(8),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}

class _DashboardMarker extends StatelessWidget {
  const _DashboardMarker({
    required this.color,
    required this.availableBikes,
    required this.stationName,
  });

  final Color color;
  final int availableBikes;
  final String stationName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The teardrop pin
          // Center of the 120x80 box is (60, 40). We want the bottom tip of the pin to be at (60, 40).
          // The pin is a 28x28 square rotated -45 deg. Distance from center to bottom tip is ~19.8.
          // So the center of the 28x28 square should be at (60, 20.2).
          // Top-left of the 28x28 square is at (60-14, 20.2-14) = (46, 6.2).
          Positioned(
            left: 46,
            top: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -3.14159 / 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(0),
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33102017),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  availableBikes.toString(),
                  style: TextStyle(
                    color: AppTheme.isDark(context) ? Colors.black : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          
          // The text number label below the pin
          Positioned(
            top: 44,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline(context), width: 0.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14102017),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  stationName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain(context),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

