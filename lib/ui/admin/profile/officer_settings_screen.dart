import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:velocy_app/core/providers/settings_provider.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';

class OfficerSettingsScreen extends StatelessWidget {
  const OfficerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsProvider(),
      builder: (context, _) {
        final settings = SettingsProvider();
        final isIndo = settings.locale.languageCode == 'id';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: AppTheme.bg(context),
          appBar: AppBar(
            backgroundColor: AppTheme.bg(context).withOpacity(0.8),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.tr('Settings'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary(context),
              ),
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(AppLocalizations.tr('Appearance'), context),
                const SizedBox(height: 12),
                _buildThemeSelector(context, isDark, isIndo),
                
                const SizedBox(height: 32),
                _buildSectionTitle(AppLocalizations.tr('Localization'), context),
                const SizedBox(height: 12),
                _buildLocalization(context, isDark, isIndo),
                
                const SizedBox(height: 32),
                _buildSectionTitle(AppLocalizations.tr('Notifications'), context),
                const SizedBox(height: 12),
                _buildNotifications(context, isDark, isIndo),
                
                const SizedBox(height: 32),
                _buildSectionTitle(AppLocalizations.tr('About'), context),
                const SizedBox(height: 12),
                _buildAbout(context, isDark, isIndo),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted(context),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, bool isDark, bool isIndo) {
    final settings = SettingsProvider();
    final mode = settings.themeMode;
    
    return _GlassCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.tr('Theme'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMain(context),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bg(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ThemeButton(
                    context: context,
                    icon: Icons.light_mode,
                    label: AppLocalizations.tr('Light'),
                    isSelected: mode == ThemeMode.light,
                    onTap: () => settings.setThemeMode(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: _ThemeButton(
                    context: context,
                    icon: Icons.dark_mode,
                    label: AppLocalizations.tr('Dark'),
                    isSelected: mode == ThemeMode.dark,
                    onTap: () => settings.setThemeMode(ThemeMode.dark),
                  ),
                ),
                Expanded(
                  child: _ThemeButton(
                    context: context,
                    icon: Icons.settings_suggest,
                    label: AppLocalizations.tr('System'),
                    isSelected: mode == ThemeMode.system,
                    onTap: () => settings.setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLocalization(BuildContext context, bool isDark, bool isIndo) {
    final settings = SettingsProvider();
    
    return _GlassCard(
      context: context,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (!isIndo) {
            settings.setLocale(const Locale('id', 'ID'));
          } else {
            settings.setLocale(const Locale('en', 'US'));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.language, color: AppTheme.primary(context), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.tr('Language'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: AppTheme.textMain(context),
                  ),
                ),
              ),
              Text(
                !isIndo ? 'English (US)' : 'Bahasa Indonesia',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.textMuted(context),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppTheme.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifications(BuildContext context, bool isDark, bool isIndo) {
    final settings = SettingsProvider();
    
    return _GlassCard(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SwitchTile(
            context: context,
            icon: Icons.notifications_active,
            title: AppLocalizations.tr('PushNotifications'),
            value: settings.pushNotificationsEnabled,
            onChanged: (val) => settings.togglePushNotifications(),
          ),
          Divider(height: 1, color: AppTheme.outline(context)),
          _SwitchTile(
            context: context,
            icon: Icons.assignment_late,
            title: isIndo ? 'Peringatan Tugas' : 'Task Alerts',
            value: settings.taskAlertsEnabled,
            onChanged: (val) => settings.toggleTaskAlerts(),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout(BuildContext context, bool isDark, bool isIndo) {
    return _GlassCard(
      context: context,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.tr('Version'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: AppTheme.textMain(context),
                  ),
                ),
                Text(
                  'v3.4.1-rc2',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.outline(context)),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.tr('TermsOfService'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: AppTheme.textMain(context),
                    ),
                  ),
                  Icon(Icons.open_in_new, color: AppTheme.textMuted(context), size: 20),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.context,
    this.padding,
  });

  final Widget child;
  final BuildContext context;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext c) {
    final isDark = Theme.of(c).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outline(context).withOpacity(0.5),
        ),
        boxShadow: isDark ? null : const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.context,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final BuildContext context;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext c) {
    final isDark = Theme.of(c).brightness == Brightness.dark;
    final selectedBg = AppTheme.primary(context);
    final selectedText = AppTheme.surface(context);
    final unselectedText = AppTheme.textMuted(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: (isSelected && isDark) ? [
            BoxShadow(
              color: AppTheme.primary(context).withOpacity(0.3),
              blurRadius: 15,
            )
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? selectedText : unselectedText,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedText : unselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.context,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final BuildContext context;
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext c) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary(context), size: 20),
          const SizedBox(width: 12),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary(context),
            activeTrackColor: AppTheme.primary(context).withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMuted(context),
            inactiveTrackColor: AppTheme.surfaceVariant(context),
          ),
        ],
      ),
    );
  }
}
