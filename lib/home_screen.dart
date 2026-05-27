import 'package:flutter/material.dart';
import 'navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
          onPressed: () {},
        ),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Muhammad Panji Fathuroni!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mau ke mana hari ini?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF3F4944),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Trip Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF18755C),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 12,
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
                        Row(
                          children: const [
                            Icon(Icons.directions_bike, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'VLY-002',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '00:14:32',
                          style: TextStyle(
                            fontFamily: 'Roboto Mono',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => switchToTab(context, 2),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Lihat Perjalanan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Map Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peta Stasiun',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF141B2B),
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
                  // Map Placeholder
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBEC9C3)),
                    ),
                    child: Stack(
                      children: [
                        // Fake Map background pattern
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.4,
                            child: Image.network(
                              'https://www.transparenttextures.com/patterns/cubes.png',
                              fit: BoxFit.cover,
                              color: const Color(0xFF0F6E56),
                            ),
                          ),
                        ),
                        // Pins
                        const Positioned(
                          top: 40,
                          left: 100,
                          child: Icon(Icons.location_on, color: Color(0xFF00543C), size: 32),
                        ),
                        const Positioned(
                          top: 100,
                          right: 80,
                          child: Icon(Icons.location_on, color: Colors.amber, size: 32),
                        ),
                        const Positioned(
                          bottom: 80,
                          left: 150,
                          child: Icon(Icons.directions_bike, color: Color(0xFF1960A6), size: 18),
                        ),
                        // User location dot
                        Positioned(
                          bottom: 100,
                          left: 130,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // Location button
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(Icons.my_location, color: Color(0xFF005440), size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.touch_app, size: 14, color: Color(0xFF3F4944)),
                      SizedBox(width: 4),
                      Text(
                        'Ketuk marker untuk detail stasiun',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF3F4944),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rent Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                    const Text(
                      'Pinjam Sepeda',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF141B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Arahkan kamera ke QR Code di sepeda atau stasiun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nearby Stations
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stasiun Terdekat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF141B2B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      children: [
                        _buildStationCard(
                          'Stasiun Gedung TI',
                          12,
                          0.8,
                          const Color(0xFF86F8C9),
                          'Tersedia',
                          const Color(0xFF002115),
                        ),
                        const SizedBox(width: 16),
                        _buildStationCard(
                          'Stasiun Perpustakaan',
                          5,
                          0.35,
                          const Color(0xFF86F8C9),
                          'Tersedia',
                          const Color(0xFF002115),
                        ),
                        const SizedBox(width: 16),
                      ],
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
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0F6E56),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner, color: Colors.white),
            label: 'Rent',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bike),
            selectedIcon: Icon(Icons.directions_bike, color: Colors.white),
            label: 'Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3F4944),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF141B2B),
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
              const Icon(Icons.directions_bike, size: 18, color: Color(0xFF3F4944)),
              const SizedBox(width: 6),
              Text(
                '$bikes Sepeda Tersedia',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF3F4944),
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
