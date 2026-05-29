import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'navigation_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<_UserProfileData> _loadUserProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const _UserProfileData(
        name: 'Pengguna',
        email: '-',
        phone: '-',
        initials: 'U',
      );
    }

    final profileSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
    final profile = profileSnapshot.data();

    final displayName = (profile?['displayName'] as String?)?.trim().isNotEmpty == true
        ? profile!['displayName'].toString().trim()
        : (authUser.displayName?.trim().isNotEmpty == true
            ? authUser.displayName!.trim()
            : (authUser.email?.split('@').first ?? 'Pengguna'));
    final email = (profile?['email'] as String?)?.trim().isNotEmpty == true
        ? profile!['email'].toString().trim()
        : (authUser.email ?? '-');
    final phone = (profile?['phone'] as String?)?.trim().isNotEmpty == true
        ? profile!['phone'].toString().trim()
        : '-';

    return _UserProfileData(
      name: displayName,
      email: email,
      phone: phone,
      initials: _buildInitials(displayName),
    );
  }

  static String _buildInitials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      final firstPart = parts.first;
      return firstPart.substring(0, firstPart.length.clamp(1, 2)).toUpperCase();
    }

    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UserProfileData>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const _UserProfileData(
          name: 'Memuat...',
          email: '-',
          phone: '-',
          initials: '...',
        );

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
              'Profil',
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F6E56),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          profile.initials,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9AEDCF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF141B2B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF3F4944),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.phone,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF3F4944),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      _ProfileMenuTile(
                        icon: Icons.language,
                        title: 'Bahasa',
                        subtitle: 'Bahasa Indonesia',
                        onTap: () {},
                      ),
                      _DividerLine(),
                      _ProfileMenuTile(
                        icon: Icons.directions_bike,
                        title: 'Riwayat Pinjam',
                        onTap: () {
                          switchToTab(context, 2);
                        },
                      ),
                      _DividerLine(),
                      _ProfileMenuTile(
                        icon: Icons.help_outline,
                        title: 'Pusat Bantuan',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD7D4)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      foregroundColor: const Color(0xFFBA1A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                        SizedBox(width: 12),
                        Text(
                          'Keluar',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 3,
            onDestinationSelected: (index) {
              if (index == 3) {
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
      },
    );
  }
}

class _UserProfileData {
  const _UserProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.initials,
  });

  final String name;
  final String email;
  final String phone;
  final String initials;
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE9EDFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF005440), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF3F4944)),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFBEC9C3));
  }
}