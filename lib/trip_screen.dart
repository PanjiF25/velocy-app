import 'package:flutter/material.dart';
import 'navigation_helper.dart';

class TripScreen extends StatelessWidget {
  const TripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F4944)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Riwayat Pinjam',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF005440),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Color(0xFF3F4944)),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F9FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: const [
            _TripCard(
              bikeCode: 'VLY-006',
              status: 'Selesai',
              from: 'Stasiun Rektorat',
              to: 'Stasiun Perpustakaan',
              date: '17 Mei 2025, 08:30',
              duration: '22 menit',
              statusColor: Color(0xFF86F8C9),
              statusIcon: Icons.check_circle,
            ),
            SizedBox(height: 16),
            _TripCard(
              bikeCode: 'VLY-042',
              status: 'Dibatalkan',
              from: 'Stasiun Fakultas Teknik',
              to: 'Stasiun Pusat Mahasiswa',
              date: '16 Mei 2025, 14:15',
              duration: '0 menit',
              statusColor: Color(0xFFBA1A1A),
              statusIcon: Icons.cancel,
            ),
            SizedBox(height: 16),
            _TripCard(
              bikeCode: 'VLY-018',
              status: 'Selesai',
              from: 'Stasiun Asrama',
              to: 'Stasiun Fakultas Sains',
              date: '15 Mei 2025, 07:45',
              duration: '15 menit',
              statusColor: Color(0xFF86F8C9),
              statusIcon: Icons.check_circle,
            ),
            SizedBox(height: 16),
            _TripCard(
              bikeCode: 'VLY-102',
              status: 'Selesai',
              from: 'Stasiun Pusat Mahasiswa',
              to: 'Stasiun Olahraga',
              date: '12 Mei 2025, 16:20',
              duration: '35 menit',
              statusColor: Color(0xFF86F8C9),
              statusIcon: Icons.check_circle,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 2) {
            return;
          }

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
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.bikeCode,
    required this.status,
    required this.from,
    required this.to,
    required this.date,
    required this.duration,
    required this.statusColor,
    required this.statusIcon,
  });

  final String bikeCode;
  final String status;
  final String from;
  final String to;
  final String date;
  final String duration;
  final Color statusColor;
  final IconData statusIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBEC9C3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BIKE CODE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bikeCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF141B2B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.directions_bike, color: Color(0xFF005440), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      from,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward, color: Color(0xFF6F7A74), size: 18),
                  ),
                  Expanded(
                    child: Text(
                      to,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFBEC9C3)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3F4944)),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Color(0xFF3F4944)),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
