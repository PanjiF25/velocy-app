import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:velocy_app/ui/auth/login_screen.dart';
import 'package:velocy_app/core/utils/navigation_helper.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/core/providers/settings_provider.dart';
import 'package:velocy_app/ui/user/profile/user_settings_screen.dart';
import 'package:velocy_app/ui/common/widgets/exit_confirmation_wrapper.dart';
import 'package:velocy_app/ui/user/profile/edit_profile_screen.dart';
import 'package:velocy_app/ui/user/profile/change_password_screen.dart';
import 'package:velocy_app/ui/common/help_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Future<_UserProfileData> _loadUserProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return _UserProfileData(
        name: AppLocalizations.isIndo ? 'Pengguna' : 'User',
        email: '-',
        phone: '-',
        initials: 'U',
      );
    }

    final profileSnapshot = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
    final profile = profileSnapshot.data();

    final displayName = (profile?['displayName'] as String?)?.trim().isNotEmpty == true
        ? profile!['displayName'].toString().trim()
        : (authUser.displayName?.trim().isNotEmpty == true
            ? authUser.displayName!.trim()
            : (authUser.email?.split('@').first ?? (AppLocalizations.isIndo ? 'Pengguna' : 'User')));
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
    final parts = value.split(RegExp(r'\s+')).where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UserProfileData>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _UserProfileData(
          name: AppLocalizations.tr('Loading'),
          email: '-',
          phone: '-',
          initials: '...',
        );

        return ListenableBuilder(
          listenable: SettingsProvider(),
          builder: (context, _) {
            return ExitConfirmationWrapper(
              child: Scaffold(
                backgroundColor: AppTheme.bg(context),
                body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    child: Column(
                      children: [
                        _buildProfileSection(context, profile),
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: 3,
            onDestinationSelected: (index) {
              if (index == 3) return;
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
        ));
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
                onPressed: () => switchToTab(context, 0),
              ),
              Text(
                AppLocalizations.tr('NavProfile'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary(context),
                ),
              ),
            ],
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
    );
  }

  Widget _buildProfileSection(BuildContext context, _UserProfileData profile) {
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
                border: Border.all(color: AppTheme.primary(context).withOpacity(0.3), width: 2),
                color: AppTheme.surfaceVariant(context),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary(context),
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.surface(context),
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
              child: const Icon(Icons.verified, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textMuted(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.phone,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppTheme.textMuted(context),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  currentName: profile.name,
                  currentPhone: profile.phone,
                ),
              ),
            );
            if (result == true) {
              setState(() {}); // Trigger refresh
            }
          },
          icon: Icon(Icons.edit, size: 16, color: AppTheme.primary(context)),
          label: Text(
            'Edit Profil',
            style: TextStyle(
              color: AppTheme.primary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primary(context)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'MENU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted(context),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
            boxShadow: [
              if (!AppTheme.isDark(context))
                const BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.settings,
                title: AppLocalizations.tr('Settings'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const UserSettingsScreen()),
                  );
                },
              ),
              Divider(height: 1, color: AppTheme.outline(context)),
              _MenuTile(
                icon: Icons.lock_outline,
                title: 'Ganti Password',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                  );
                },
              ),
              Divider(height: 1, color: AppTheme.outline(context)),
              _MenuTile(
                icon: Icons.directions_bike,
                title: AppLocalizations.tr('TripHistory'),
                onTap: () => switchToTab(context, 2),
              ),
              Divider(height: 1, color: AppTheme.outline(context)),
              _MenuTile(
                icon: Icons.help_outline,
                title: AppLocalizations.isIndo ? 'Pusat Bantuan' : 'Help Center',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
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
              AppLocalizations.tr('Logout'),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary(context), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMain(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted(context)),
          ],
        ),
      ),
    );
  }
}