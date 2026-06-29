import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:velocy_app/ui/admin/dashboard/officer_screen.dart';
import 'package:velocy_app/ui/admin/dashboard/officer_map_screen.dart';
import 'package:velocy_app/ui/admin/tasks/officer_tasks_screen.dart';
import 'package:velocy_app/ui/admin/profile/officer_profile_screen.dart';
import 'package:velocy_app/ui/admin/tasks/officer_scanner_screen.dart';

import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class OfficerBottomNav extends StatefulWidget {
  final int currentIndex;
  final bool showProfileBadge;

  const OfficerBottomNav({super.key, required this.currentIndex, this.showProfileBadge = false});

  @override
  State<OfficerBottomNav> createState() => _OfficerBottomNavState();
}

class _OfficerBottomNavState extends State<OfficerBottomNav> {
  bool _hasUnread = false;
  StreamSubscription<bool>? _unreadSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _unreadSub = FirestoreService().getUnreadStatusStream(uid).listen((val) {
        if (mounted && val != _hasUnread) {
          setState(() => _hasUnread = val);
        }
      });
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const OfficerScreen();
        break;
      case 1:
        page = const OfficerTasksScreen();
        break;
      case 2:
        page = const OfficerMapScreen();
        break;
      case 3:
        page = const OfficerProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, -10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, top: 12, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context).withOpacity(0.95),
                  border: Border(top: BorderSide(color: AppTheme.outline(context).withOpacity(0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavButton(
                      icon: Icons.home,
                      label: AppLocalizations.isIndo ? 'Beranda' : 'Home',
                      isActive: widget.currentIndex == 0,
                      onTap: () => _onTap(context, 0),
                    ),
                    _NavButton(
                      icon: Icons.assignment_outlined,
                      label: AppLocalizations.isIndo ? 'Tugas' : 'Tasks',
                      isActive: widget.currentIndex == 1,
                      onTap: () => _onTap(context, 1),
                    ),
                    const SizedBox(width: 60), // Spacer for FAB
                    _NavButton(
                      icon: Icons.map_outlined,
                      label: AppLocalizations.isIndo ? 'Peta' : 'Map',
                      isActive: widget.currentIndex == 2,
                      onTap: () => _onTap(context, 2),
                    ),
                    _NavButton(
                      icon: Icons.person_outline,
                      label: AppLocalizations.isIndo ? 'Profil' : 'Profile',
                      isActive: widget.currentIndex == 3,
                      showBadge: _hasUnread || widget.showProfileBadge,
                      onTap: () => _onTap(context, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // FAB (Moved outside ClipRRect)
        Positioned(
          top: -24, // Float above the bar
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OfficerScannerScreen()),
              );
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bg(context), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary(context).withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(Icons.qr_code_scanner, color: AppTheme.surface(context), size: 32),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = AppTheme.primary(context);
    final Color muted = AppTheme.textMuted(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? primary : muted,
                  size: 26,
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface(context), width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? primary : muted,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
            ]
          ],
        ),
      ),
    );
  }
}
