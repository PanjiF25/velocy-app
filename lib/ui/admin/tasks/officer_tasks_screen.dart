import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/ui/admin/navigation/officer_bottom_nav.dart';
import 'package:velocy_app/ui/admin/tasks/officer_task_detail_screen.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/common/widgets/empty_state.dart';
import 'package:velocy_app/ui/common/widgets/shimmer_loading.dart';

class OfficerTasksScreen extends StatefulWidget {
  const OfficerTasksScreen({super.key});

  @override
  State<OfficerTasksScreen> createState() => _OfficerTasksScreenState();
}

class _OfficerTasksScreenState extends State<OfficerTasksScreen> {


  int _selectedTabIndex = 0; // 0: Pending, 1: In Progress, 2: Completed
  final FirestoreService _firestoreService = FirestoreService();
  final String? _officerId = FirebaseAuth.instance.currentUser?.uid;

  // Track buttons that are loading
  final Set<String> _loadingTaskIds = {};

  Future<void> _startTask(String taskId) async {
    setState(() {
      _loadingTaskIds.add(taskId);
    });
    try {
      await _firestoreService.updateTaskStatus(taskId, 'in_progress');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal memulai tugas: $e' : 'Failed to start task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTaskIds.remove(taskId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.isIndo ? 'Tugas yang Diberikan' : 'Assigned Tasks',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Segmented Control
                    _buildSegmentedControl(context),
                    const SizedBox(height: 24),
                    
                    // Task List
                    if (_officerId == null)
                      Center(child: Text(AppLocalizations.isIndo ? 'Belum login' : 'Not logged in', style: TextStyle(color: AppTheme.textMain(context))))
                    else
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _firestoreService.getTasksForOfficer(_officerId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 3,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => const ShimmerLoading(
                                width: double.infinity,
                                height: 120,
                                borderRadius: 12,
                              ),
                            );
                          }
                          
                          if (snapshot.hasError) {
                            return Center(child: Text(AppLocalizations.isIndo ? 'Gagal memuat tugas' : 'Error loading tasks', style: TextStyle(color: AppTheme.error(context))));
                          }

                          final allTasks = snapshot.data ?? [];
                          
                          // Filter tasks by selected tab
                          // 0: pending, 1: in_progress, 2: completed
                          final statusFilter = _selectedTabIndex == 0 ? 'pending' 
                                             : _selectedTabIndex == 1 ? 'in_progress' 
                                             : 'completed';
                                             
                          final filteredTasks = allTasks.where((t) => t['status'] == statusFilter).toList();
                          
                          if (filteredTasks.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: EmptyState(
                                icon: Icons.assignment_turned_in,
                                title: AppLocalizations.isIndo ? 'Tidak Ada Tugas' : 'No Tasks',
                                message: AppLocalizations.isIndo ? 'Anda sudah menyelesaikan semua tugas di tab ini.' : 'You have completed all tasks in this tab.',
                              ),
                            );
                          }

                          return Column(
                            children: filteredTasks.map((task) {
                              // map priority string to int
                              int pLevel = 3;
                              if (task['priority'] == 'high') pLevel = 1;
                              else if (task['priority'] == 'medium') pLevel = 2;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OfficerTaskDetailScreen(task: task),
                                        ),
                                      );
                                    },
                                    child: _buildTaskCard(context, task: task, priorityLevel: pLevel),
                                  ),
                              );
                            }).toList(),
                          );
                        },
                      ),                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const OfficerBottomNav(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.bg(context).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: AppTheme.outline(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outline(context)),
                ),
                child: Icon(Icons.person, color: AppTheme.textMuted(context), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'On Duty',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary(context),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant(context),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outline(context)),
            ),
            child: IconButton(
              icon: Icon(Icons.sensors, color: AppTheme.primary(context), size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      child: Row(
        children: [
          _buildSegmentTab(context, AppLocalizations.isIndo ? 'Tertunda' : 'Pending', 0),
          _buildSegmentTab(context, AppLocalizations.isIndo ? 'Berjalan' : 'In Progress', 1),
          _buildSegmentTab(context, AppLocalizations.isIndo ? 'Selesai' : 'Completed', 2),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(BuildContext context, String title, int index) {
    final bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.surfaceVariant(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isActive ? Border(bottom: BorderSide(color: AppTheme.primary(context), width: 2)) : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isActive ? AppTheme.primary(context) : AppTheme.textMuted(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, {
    required Map<String, dynamic> task,
    required int priorityLevel, // 1: High, 2: Medium, 3: Low
  }) {
    final title = task['title'] ?? (AppLocalizations.isIndo ? 'Tugas Tidak Diketahui' : 'Unknown Task');
    final location = task['location'] ?? (AppLocalizations.isIndo ? 'Lokasi Tidak Diketahui' : 'Unknown Location');
    final status = task['status'] ?? 'pending';
    final taskId = task['id'];
    Color priorityColor;
    String priorityText;

    switch (priorityLevel) {
      case 1:
        priorityColor = AppTheme.error(context);
        priorityText = AppLocalizations.isIndo ? 'Prioritas Tinggi' : 'High Priority';
        break;
      case 2:
        priorityColor = AppTheme.warning(context);
        priorityText = AppLocalizations.isIndo ? 'Prioritas Sedang' : 'Medium Priority';
        break;
      default:
        priorityColor = AppTheme.outline(context);
        priorityText = AppLocalizations.isIndo ? 'Prioritas Rendah' : 'Low Priority';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outline(context)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Status Bar Indicator
              Container(
                width: 4,
                color: priorityColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority Badge & Menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: priorityColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  priorityText,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: priorityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.more_horiz, color: AppTheme.textMuted(context), size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Task Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain(context),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Task Details
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppTheme.textMuted(context), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Icon(
                                status == 'completed' ? Icons.check_circle :
                                status == 'in_progress' ? Icons.directions_run : Icons.pending, 
                                color: AppTheme.textMuted(context), size: 16
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status == 'completed' ? (AppLocalizations.isIndo ? 'Selesai' : 'Completed') :
                                status == 'in_progress' ? (AppLocalizations.isIndo ? 'Berjalan' : 'In Progress') : (AppLocalizations.isIndo ? 'Tertunda' : 'Pending'),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Start Task Button
                      if (status == 'pending')
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: priorityLevel == 1 ? AppTheme.primary(context) : AppTheme.surfaceVariant(context),
                            borderRadius: BorderRadius.circular(8),
                            border: priorityLevel != 1 ? Border.all(color: AppTheme.outline(context)) : null,
                            boxShadow: priorityLevel == 1
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary(context).withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.primary(context).withOpacity(0.5),
                                      offset: const Offset(0, -1),
                                    )
                                  ]
                                : null,
                          ),
                          child: TextButton.icon(
                            onPressed: _loadingTaskIds.contains(taskId) ? null : () => _startTask(taskId),
                            icon: _loadingTaskIds.contains(taskId)
                              ? const SizedBox(
                                  width: 20, 
                                  height: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                )
                              : Icon(
                                  Icons.play_circle_fill,
                                  color: priorityLevel == 1 ? Colors.white : AppTheme.primary(context),
                                  size: 20,
                                ),
                            label: Text(
                              _loadingTaskIds.contains(taskId) ? (AppLocalizations.isIndo ? 'Memulai...' : 'Starting...') : (AppLocalizations.isIndo ? 'Mulai Tugas' : 'Start Task'),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: priorityLevel == 1 ? Colors.white : AppTheme.primary(context),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
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
