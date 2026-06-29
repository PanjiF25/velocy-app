import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class OfficerBikesScreen extends StatefulWidget {
  const OfficerBikesScreen({super.key});

  @override
  State<OfficerBikesScreen> createState() => _OfficerBikesScreenState();
}

class _OfficerBikesScreenState extends State<OfficerBikesScreen> {


  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'available', 'in_use', 'broken', 'maintenance'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilters(context),
            Expanded(
              child: _buildBikesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: AppTheme.textMain(context)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Text(
                AppLocalizations.isIndo ? 'Manajemen Sepeda' : 'Bike Management',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            style: TextStyle(color: AppTheme.textMain(context), fontFamily: 'Inter'),
            decoration: InputDecoration(
              hintText: AppLocalizations.isIndo ? 'Cari ID Sepeda...' : 'Search Bike ID...',
              hintStyle: TextStyle(color: AppTheme.textMuted(context)),
              prefixIcon: Icon(Icons.search, color: AppTheme.textMuted(context)),
              filled: true,
              fillColor: AppTheme.surface(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outline(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outline(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary(context).withOpacity(0.2) : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary(context) : AppTheme.outline(context),
                  ),
                ),
                child: Text(
                  _formatStatus(filter),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary(context) : AppTheme.textMuted(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBikesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getBikesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primary(context)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context, AppLocalizations.isIndo ? 'Tidak ada data sepeda.' : 'No bike data.');
        }

        var bikes = snapshot.data!;

        // Apply filters
        if (_selectedFilter != 'All') {
          bikes = bikes.where((b) => b['status'] == _selectedFilter).toList();
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          bikes = bikes.where((b) {
            final id = b['id'].toString().toLowerCase();
            return id.contains(_searchQuery);
          }).toList();
        }

        if (bikes.isEmpty) {
          return _buildEmptyState(context, AppLocalizations.isIndo ? 'Sepeda tidak ditemukan.' : 'Bike not found.');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bikes.length,
          itemBuilder: (context, index) {
            final bike = bikes[index];
            return _buildBikeCard(context, bike);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pedal_bike, size: 64, color: AppTheme.outline(context)),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppTheme.textMuted(context),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeCard(BuildContext context, Map<String, dynamic> bike) {
    final status = bike['status'] ?? 'unknown';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'available':
        statusColor = AppTheme.primary(context);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'in_use':
        statusColor = AppTheme.info(context);
        statusIcon = Icons.directions_bike;
        break;
      case 'broken':
        statusColor = AppTheme.error(context);
        statusIcon = Icons.build_outlined;
        break;
      case 'maintenance':
        statusColor = AppTheme.warning(context);
        statusIcon = Icons.handyman_outlined;
        break;
      default:
        statusColor = AppTheme.textMuted(context);
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.pedal_bike, color: AppTheme.textMain(context), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bike['id'] ?? 'Unknown ID',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusBadge(status, statusColor, statusIcon),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showStatusActionSheet(context, bike),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surface(context),
                          foregroundColor: AppTheme.textMain(context),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: Text(
                          AppLocalizations.isIndo ? 'Perbarui Status' : 'Update Status',
                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            _formatStatus(status),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    if (status == 'All') return AppLocalizations.isIndo ? 'Semua' : 'All';
    if (status == 'available') return AppLocalizations.isIndo ? 'Tersedia' : 'Available';
    if (status == 'in_use') return AppLocalizations.isIndo ? 'Digunakan' : 'In Use';
    if (status == 'broken') return AppLocalizations.isIndo ? 'Rusak' : 'Broken';
    if (status == 'maintenance') return AppLocalizations.isIndo ? 'Perawatan' : 'Maintenance';
    return status[0].toUpperCase() + status.substring(1);
  }

  void _showStatusActionSheet(BuildContext context, Map<String, dynamic> bike) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.outline(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.isIndo ? 'Perbarui Status: ${bike['id']}' : 'Update Status: ${bike['id']}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildActionOption(context, bike['id'], 'available', Icons.check_circle_outline, AppTheme.primary(context)),
              _buildActionOption(context, bike['id'], 'in_use', Icons.directions_bike, AppTheme.info(context)),
              _buildActionOption(context, bike['id'], 'broken', Icons.build_outlined, AppTheme.error(context)),
              _buildActionOption(context, bike['id'], 'maintenance', Icons.handyman_outlined, AppTheme.warning(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionOption(BuildContext context, String bikeId, String newStatus, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        _formatStatus(newStatus),
        style: TextStyle(
          fontFamily: 'Inter',
          color: AppTheme.textMain(context),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        Navigator.pop(context);
        try {
          await _firestoreService.updateBikeStatus(bikeId, newStatus);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.isIndo ? 'Status sepeda $bikeId berhasil diubah menjadi ${_formatStatus(newStatus)}' : 'Bike $bikeId status successfully changed to ${_formatStatus(newStatus)}')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal mengubah status: $e' : 'Failed to change status: $e')),
            );
          }
        }
      },
    );
  }
}
