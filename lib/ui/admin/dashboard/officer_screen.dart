import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:velocy_app/ui/admin/navigation/officer_bottom_nav.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:velocy_app/ui/admin/profile/officer_profile_screen.dart';
import 'package:velocy_app/ui/admin/dashboard/officer_bikes_screen.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/admin/tasks/officer_shift_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerScreen extends StatefulWidget {
  const OfficerScreen({super.key});

  @override
  State<OfficerScreen> createState() => _OfficerScreenState();
}

class _OfficerScreenState extends State<OfficerScreen> {


  bool _isOnDuty = true;
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  static const LatLng _itsCampusCenter = LatLng(-7.2798, 112.7951);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _displayName(user);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Stack(
        children: [
          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, displayName, user?.photoURL),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildQuickStats(context),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildLiveMap(context),
                      const SizedBox(height: 24),
                      _buildTodaysTasks(context),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation & FAB
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: const OfficerBottomNav(currentIndex: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name, String? photoUrl) {
    return SliverAppBar(
      backgroundColor: AppTheme.bg(context),
      floating: true,
      pinned: true,
      elevation: 0,
      titleSpacing: 16,
      toolbarHeight: 64,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.surface(context),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? Text(name.isNotEmpty ? name[0] : 'V', style: TextStyle(color: AppTheme.textMain(context))) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.isIndo ? 'Petugas Lapangan' : 'Field Officer',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain(context),
                  ),
                ),
              ],
            ),
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
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OfficerShiftScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: onDuty ? AppTheme.primary(context) : AppTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: onDuty ? AppTheme.primary(context) : AppTheme.outline(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(onDuty ? Icons.check_circle : Icons.access_time, color: onDuty ? Colors.white : AppTheme.textMuted(context), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        onDuty ? 'On Duty' : 'Off Duty',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: onDuty ? Colors.white : AppTheme.textMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getTasksForOfficer(uid),
      builder: (context, taskSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getBikesStream(),
          builder: (context, bikeSnapshot) {
            int pendingTasks = 0;
            int brokenBikes = 0;
            int inTransit = 0;

            if (taskSnapshot.hasData) {
              pendingTasks = taskSnapshot.data!.where((t) => t['status'] == 'pending' || t['status'] == 'in_progress').length;
            }

            if (bikeSnapshot.hasData) {
              brokenBikes = bikeSnapshot.data!.where((b) => b['status'] == 'repair').length;
              inTransit = bikeSnapshot.data!.where((b) => b['status'] == 'active').length;
            }

            return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.isIndo ? 'Statistik Cepat' : 'Quick Stats',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassCard(
                glow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$pendingTasks',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary(context),
                          ),
                        ),
                        Icon(Icons.warning_amber_rounded, color: AppTheme.primary(context), size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.isIndo ? 'Tugas Tertunda' : 'Pending Tasks',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$inTransit',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain(context),
                          ),
                        ),
                        Icon(Icons.local_shipping_outlined, color: AppTheme.textMuted(context), size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.isIndo ? 'Dalam Transit' : 'In Transit',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$brokenBikes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain(context),
                          ),
                        ),
                        Icon(Icons.build_outlined, color: AppTheme.textMuted(context), size: 24),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.isIndo ? 'Sepeda Rusak' : 'Broken Bikes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
          }
        );
      }
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.isIndo ? 'Aksi Cepat' : 'Quick Actions',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OfficerBikesScreen()),
                  );
                },
                child: _GlassCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary(context).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.pedal_bike, color: AppTheme.primary(context), size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.isIndo ? 'Manajemen\nSepeda' : 'Bike\nManagement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveMap(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Map',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 192,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outline(context)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Real Flutter Map
                FlutterMap(
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
                          -1, 0, 0, 0, 255, // Invert R
                          0, -1, 0, 0, 255, // Invert G
                          0, 0, -1, 0, 255, // Invert B
                          0, 0, 0, 1, 0,    // Alpha
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
                    // Real markers from Firestore
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getStationsStream(),
                      builder: (context, snapshot) {
                        final stations = snapshot.data ?? [];
                        return MarkerLayer(
                          markers: stations.map((station) {
                            double lat = double.tryParse(station['lat']?.toString() ?? '') ?? 0.0;
                            double lng = double.tryParse(station['lng']?.toString() ?? '') ?? 0.0;
                            return Marker(
                              point: LatLng(lat, lng),
                              width: 32,
                              height: 32,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Station: ${station['name']}')),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary(context).withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.ev_station, color: Colors.white, size: 18),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                // Dark tint overlay to make it match the UI perfectly
                IgnorePointer(
                  child: Container(
                    color: AppTheme.isDark(context) ? const Color(0x33000000) : const Color(0x11000000),
                  ),
                ),
                // Map Overlay Badges
                Positioned(
                  top: 12,
                  right: 12,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.getBikesStream(),
                    builder: (context, snapshot) {
                      int totalBikes = 0;
                      int activeBikes = 0;
                      if (snapshot.hasData) {
                        totalBikes = snapshot.data!.length;
                        activeBikes = snapshot.data!.where((b) => b['status'] == 'active' || b['status'] == 'in_use').length;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pedal_bike, color: AppTheme.primary(context), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$activeBikes/$totalBikes',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMain(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysTasks(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.isIndo ? "Tugas Hari Ini" : "Today's Tasks",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getTasksForOfficer(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppTheme.primary(context)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading tasks', style: TextStyle(color: AppTheme.error(context))));
            }

            final allTasks = snapshot.data ?? [];
            final pendingTasks = allTasks.where((t) => t['status'] == 'pending' || t['status'] == 'in_progress').toList();

            if (pendingTasks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline(context)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppTheme.primary(context), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.isIndo ? "Semua tugas selesai!" : "All tasks completed!",
                      style: TextStyle(color: AppTheme.textMain(context), fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            final displayTasks = pendingTasks.take(2).toList();

            return Column(
              children: [
                ...displayTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRealTaskCard(context, task),
                )),
                const SizedBox(height: 4),
                // Static alert for demonstration of urgent notifications
                _AlertCard(
                  color: AppTheme.warning(context),
                  title: 'Urgent: Fix Bike B001',
                  subtitle: 'Fault: Flat tire',
                  icon: Icons.build,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRealTaskCard(BuildContext context, Map<String, dynamic> task) {
    final title = task['title'] ?? (AppLocalizations.isIndo ? 'Tugas Tidak Diketahui' : 'Unknown Task');
    final location = task['location'] ?? (AppLocalizations.isIndo ? 'Lokasi Tidak Diketahui' : 'Unknown Location');
    final status = task['status'] ?? 'pending';
    final priority = task['priority'] ?? 'low';
    final taskId = task['id'];

    Color priorityColor;
    if (priority == 'high') priorityColor = AppTheme.error(context);
    else if (priority == 'medium') priorityColor = AppTheme.warning(context);
    else priorityColor = AppTheme.primary(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: priorityColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.outline(context).withOpacity(0.5)),
                            ),
                            child: Icon(
                              status == 'in_progress' ? Icons.directions_run : Icons.assignment, 
                              color: AppTheme.textMuted(context), size: 20
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMain(context)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  location,
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textMuted(context)),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.more_horiz, color: AppTheme.textMuted(context)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Status: ', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textMuted(context))),
                              Text(
                                status == 'in_progress' ? 'In Progress' : 'Pending', 
                                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: priorityColor)
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _firestoreService.updateTaskStatus(taskId, 'in_progress');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary(context),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppLocalizations.isIndo ? 'Mulai Tugas' : 'Start Task', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _displayName(User? user) {
    final rawName = user?.displayName?.trim();
    if (rawName != null && rawName.isNotEmpty) return rawName;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Petugas';
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool glow;

  const _GlassCard({required this.child, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: glow ? AppTheme.primary(context).withOpacity(0.15) : AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glow ? AppTheme.primary(context).withOpacity(0.3) : AppTheme.outline(context)),
        boxShadow: glow ? [
          BoxShadow(
            color: AppTheme.primary(context).withOpacity(0.15),
            blurRadius: 15,
          )
        ] : [],
      ),
      child: child,
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Color color;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const _AlertCard({
    required this.color,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMain(context)),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textMuted(context)),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.more_horiz, color: AppTheme.textMuted(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

