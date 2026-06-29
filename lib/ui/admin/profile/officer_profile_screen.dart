import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:velocy_app/ui/admin/navigation/officer_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/ui/auth/login_screen.dart';
import 'package:velocy_app/ui/admin/profile/officer_settings_screen.dart';
import 'package:velocy_app/ui/admin/tasks/officer_shift_screen.dart';
import 'package:velocy_app/ui/admin/chat/officer_chat_screen.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class OfficerProfileScreen extends StatefulWidget {
  const OfficerProfileScreen({super.key});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasUnreadChat = false;
  late final Stream<bool> _unreadStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _unreadStream = _firestoreService.getUnreadStatusStream(uid);
      _unreadStream.listen((hasUnread) {
        if (mounted && hasUnread != _hasUnreadChat) {
          setState(() => _hasUnreadChat = hasUnread);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _displayName(user);
    final staffId = _staffId(user);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Stack(
        children: [
          // Background Glow effect
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    child: Column(
                      children: [
                        _buildProfileSection(context, displayName, staffId),
                        const SizedBox(height: 32),
                        _buildPerformanceSection(context),
                        const SizedBox(height: 32),
                        _buildManagementMenu(context),
                        const SizedBox(height: 24),
                        _buildLogoutButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const OfficerBottomNav(currentIndex: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
                  color: AppTheme.surface(context),
                ),
                child: Icon(Icons.engineering, color: AppTheme.primary(context), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.isIndo ? 'Teknisi' : 'Technician',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMain(context),
                ),
              ),
            ],
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getOfficerShiftsStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              bool onDuty = false;
              if (snapshot.hasData) {
                final shifts = snapshot.data!;
                final today = DateTime.now();
                for (var shift in shifts) {
                  final timestamp = shift['date'] as Timestamp?;
                  if (timestamp != null) {
                    final date = timestamp.toDate();
                    if (date.day == today.day && date.month == today.month && date.year == today.year) {
                      if (shift['isCheckedIn'] == true && shift['checkOutTime'] == null) {
                        onDuty = true;
                      }
                    }
                  }
                }
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: onDuty ? AppTheme.primary(context).withOpacity(0.1) : AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: onDuty ? AppTheme.primary(context).withOpacity(0.3) : AppTheme.outline(context)),
                ),
                child: Text(
                  onDuty ? (AppLocalizations.isIndo ? 'Bertugas' : 'On Duty') : (AppLocalizations.isIndo ? 'Tidak Bertugas' : 'Off Duty'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onDuty ? AppTheme.primary(context) : AppTheme.textMuted(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String displayName, String staffId) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary(context).withOpacity(0.5), width: 2),
                color: AppTheme.surface(context),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary(context).withOpacity(0.3),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary(context),
                  ),
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bg(context), width: 4),
              ),
              child: Icon(Icons.verified, color: AppTheme.bg(context), size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ID: $staffId',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 4, height: 4, decoration: BoxDecoration(color: AppTheme.outline(context), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            StreamBuilder<Map<String, dynamic>?>(
              stream: _firestoreService.getOfficerProfileStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final shift = snapshot.data?['shift'] ?? (AppLocalizations.isIndo ? 'Shift Pagi' : 'Morning Shift');
                return Text(
                  shift,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary(context),
                  ),
                );
              }
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<Map<String, int>>(
      stream: _firestoreService.getOfficerStatsStream(uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'tasksCompleted': 0, 'bikesRelocated': 0};
        
        return Row(
          children: [
            Expanded(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.assignment_turned_in, color: AppTheme.primary(context)),
                        Icon(Icons.show_chart, color: AppTheme.primary(context), size: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${stats['tasksCompleted']}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.isIndo ? 'Tugas Selesai\nMinggu Ini' : 'Tasks Completed\nThis Week',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.local_shipping, color: AppTheme.primary(context)),
                        Icon(Icons.show_chart, color: AppTheme.primary(context), size: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${stats['bikesRelocated']}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.isIndo ? 'Sepeda Dipindahkan\n' : 'Bikes Relocated\n',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }


  Widget _buildManagementMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.isIndo ? 'MANAJEMEN' : 'MANAGEMENT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.outline(context),
              letterSpacing: 1.2,
            ),
          ),
        ),
        _GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.calendar_today,
                title: AppLocalizations.isIndo ? 'Jadwal Shift' : 'Shift Schedule',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OfficerShiftScreen()),
                  );
                },
              ),
              Divider(height: 1, color: AppTheme.outline(context)),
              _MenuTile(
                icon: Icons.support_agent,
                title: AppLocalizations.isIndo ? 'Hubungi Bantuan Admin' : 'Contact Admin Support',
                showBadge: _hasUnreadChat,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OfficerChatScreen()),
                  );
                },
              ),
              Divider(height: 1, color: AppTheme.outline(context)),
              _MenuTile(
                icon: Icons.settings,
                title: AppLocalizations.isIndo ? 'Pengaturan Aplikasi' : 'App Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OfficerSettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.error(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error(context).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppTheme.error(context)),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.isIndo ? 'Keluar' : 'Log Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.error(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _displayName(User? user) {
    final rawName = user?.displayName?.trim();
    if (rawName != null && rawName.isNotEmpty) return rawName;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return AppLocalizations.isIndo ? 'Staf Lapangan' : 'Field Staff';
  }

  static String _staffId(User? user) {
    final uid = user?.uid ?? 'vcy-op-8821';
    final fragment = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final suffix = fragment.length >= 4 ? fragment.substring(0, 4) : fragment.padRight(4, '0');
    return '#$suffix-X';
  }

  static void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.isIndo ? '$label sedang dalam pengembangan.' : '$label is under development.')),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary(context).withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.outline(context).withOpacity(0.2)),
                  ),
                  child: Icon(icon, color: AppTheme.primary(context), size: 20),
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface(context), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: AppTheme.textMain(context),
                ),
              ),
            ),
            if (showBadge)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted(context)),
          ],
        ),
      ),
    );
  }
}