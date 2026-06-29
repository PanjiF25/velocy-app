import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/utils/navigation_helper.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/common/widgets/exit_confirmation_wrapper.dart';
import 'package:velocy_app/ui/common/widgets/empty_state.dart';
import 'package:velocy_app/ui/common/widgets/shimmer_loading.dart';
import 'package:velocy_app/core/providers/settings_provider.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return '-';
    final diff = end.difference(start);
    return '${diff.inMinutes} menit';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsProvider(),
      builder: (context, _) {
        return ExitConfirmationWrapper(
          child: Scaffold(
            appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.tr('TripHistory'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary(context),
          ),
        ),
        centerTitle: true,
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
      backgroundColor: AppTheme.bg(context),
      body: _userId == null
          ? Center(child: Text(AppLocalizations.isIndo ? 'Harap login untuk melihat riwayat perjalanan.' : 'Please log in to view trip history.', style: TextStyle(color: AppTheme.textMuted(context))))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getTripHistoryStream(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: 4,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => const ShimmerLoading(
                      width: double.infinity,
                      height: 160,
                      borderRadius: 16,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${AppLocalizations.isIndo ? 'Terjadi kesalahan:' : 'An error occurred:'} ${snapshot.error}', style: TextStyle(color: AppTheme.error(context))));
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return EmptyState(
                    icon: Icons.directions_bike_outlined,
                    title: AppLocalizations.isIndo ? 'Belum Ada Perjalanan' : 'No Trips Yet',
                    message: AppLocalizations.isIndo ? 'Mulai sewa sepeda pertamamu sekarang juga!' : 'Start your first bike rental today!',
                    actionLabel: AppLocalizations.isIndo ? 'Sewa Sekarang' : 'Rent Now',
                    onActionPressed: () => switchToTab(context, 1),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: trips.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final isCompleted = trip['status'] == 'completed';
                    
                    final startTimestamp = trip['startedAt'] as Timestamp?;
                    final endTimestamp = trip['completedAt'] as Timestamp?;
                    
                    final startDate = startTimestamp?.toDate() ?? DateTime.now();
                    final endDate = endTimestamp?.toDate();

                    return _TripCard(
                      bikeCode: trip['bikeCode'] ?? '-',
                      status: isCompleted ? (AppLocalizations.isIndo ? 'Selesai' : 'Completed') : (AppLocalizations.isIndo ? 'Dibatalkan' : 'Cancelled'),
                      from: trip['originStationName'] ?? '-',
                      to: trip['actualReturnStationName'] ?? trip['destinationStationName'] ?? '-',
                      date: _formatDate(startDate),
                      duration: _formatDuration(startDate, endDate),
                      statusColor: isCompleted ? const Color(0xFF137333) : AppTheme.error(context),
                      statusIcon: isCompleted ? Icons.check_circle : Icons.cancel,
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 2) {
            return;
          }

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
      color: AppTheme.surface(context),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outline(context)),
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
                    Text(
                      AppLocalizations.tr('BikeID').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bikeCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain(context),
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
              decoration: BoxDecoration(color: AppTheme.surfaceVariant(context), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.directions_bike, color: AppTheme.primary(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      from,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward, color: AppTheme.textMuted(context), size: 18),
                  ),
                  Expanded(
                    child: Text(
                      to,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: AppTheme.outline(context)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppTheme.textMuted(context)),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: AppTheme.textMuted(context)),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain(context),
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
