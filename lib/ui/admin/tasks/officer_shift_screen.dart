import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class OfficerShiftScreen extends StatefulWidget {
  const OfficerShiftScreen({super.key});

  @override
  State<OfficerShiftScreen> createState() => _OfficerShiftScreenState();
}

class _OfficerShiftScreenState extends State<OfficerShiftScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isGenerating = false;
  bool _isLoadingLocation = false;

  Future<void> _handleCheckIn(String shiftId) async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      
      await _firestoreService.checkInShift(_uid, shiftId, GeoPoint(position.latitude, position.longitude));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Berhasil Check-In!' : 'Check-In Successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleCheckOut(String shiftId) async {
    try {
      await _firestoreService.checkOutShift(_uid, shiftId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Berhasil Check-Out!' : 'Check-Out Successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showSwapRequestSheet(String shiftId, String currentShiftName, DateTime date) {
    final reasonController = TextEditingController();
    String requestedShift = 'Libur';
    final shifts = ['Shift Pagi', 'Shift Siang', 'Shift Malam', 'Libur'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.isIndo ? 'Ajukan Tukar Jadwal' : 'Request Shift Swap',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('dd MMM yyyy').format(date)} - $currentShiftName',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.isIndo ? 'Ubah Menjadi:' : 'Change to:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain(context),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outline(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: requestedShift,
                      isExpanded: true,
                      dropdownColor: AppTheme.surface(context),
                      items: shifts.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: TextStyle(color: AppTheme.textMain(context))),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => requestedShift = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.textMain(context)),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.isIndo ? 'Alasan' : 'Reason',
                    labelStyle: TextStyle(color: AppTheme.textMuted(context)),
                    filled: true,
                    fillColor: AppTheme.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.outline(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.outline(context)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.isIndo ? 'Silakan isi alasan pertukaran shift.' : 'Please provide a reason for the shift swap.')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      try {
                        await _firestoreService.requestShiftSwap(_uid, shiftId, reasonController.text.trim(), requestedShift);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.isIndo ? 'Permohonan terkirim' : 'Request sent')),
                          );
                        }
                      } catch (e) {
                         if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      AppLocalizations.isIndo ? 'Kirim Permohonan' : 'Submit Request',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          AppLocalizations.isIndo ? 'Jadwal Shift' : 'Shift Schedule',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain(context),
          ),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firestoreService.getOfficerProfileStream(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primary(context)));
          }

          final officer = snapshot.data;
          final currentShift = officer?['shift'] ?? (AppLocalizations.isIndo ? 'Shift Pagi' : 'Morning Shift');
          
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary(context).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary(context),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.isIndo ? 'Shift Anda Saat Ini' : 'Your Current Shift',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppTheme.primary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentShift,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.isIndo ? 'Jadwal Minggu Ini' : "This Week's Schedule",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain(context),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getOfficerShiftsStream(_uid),
                builder: (context, shiftSnapshot) {
                  if (shiftSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final shiftsList = shiftSnapshot.data ?? [];
                  
                  if (shiftsList.isEmpty) {
                    if (!_isGenerating) {
                      _isGenerating = true;
                      _firestoreService.generateInitialShifts(_uid, currentShift).then((_) {
                        if (mounted) {
                          setState(() => _isGenerating = false);
                        }
                      }).catchError((error) {
                        if (mounted) {
                          setState(() => _isGenerating = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error generating shifts: $error')),
                          );
                        }
                      });
                    }
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: shiftsList.map((shiftData) {
                      final timestamp = shiftData['date'] as Timestamp?;
                      if (timestamp == null) return const SizedBox.shrink();
                      
                      final date = timestamp.toDate();
                      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
                      
                      return _buildShiftCard(context, shiftData, isToday);
                    }).toList(),
                  );
                }
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Map<String, dynamic> shiftData, bool isToday) {
    final timestamp = shiftData['date'] as Timestamp;
    final date = timestamp.toDate();
    final shiftName = shiftData['shiftName'] ?? 'Shift Pagi';
    final shiftId = shiftData['id'];
    final isCheckedIn = shiftData['isCheckedIn'] ?? false;
    final isCheckedOut = shiftData['checkOutTime'] != null;
    final swapStatus = shiftData['swapStatus'];
    
    final isPendingSwap = swapStatus == 'pending';
    final isPast = date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

    Widget content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppTheme.primary(context) : AppTheme.outline(context),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primary(context) : AppTheme.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.white : AppTheme.textMuted(context),
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(date),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : AppTheme.textMain(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shiftName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain(context),
                            ),
                          ),
                        ),
                        if (isPendingSwap)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              AppLocalizations.isIndo ? 'PENDING' : 'PENDING',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getShiftTime(shiftName),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    AppLocalizations.isIndo ? 'HARI INI' : 'TODAY',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary(context),
                    ),
                  ),
                ),
            ],
          ),
          if (isToday && !isPast) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (!isCheckedIn)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : () => _handleCheckIn(shiftId),
                  icon: _isLoadingLocation 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.location_on, size: 18),
                  label: Text(
                    _isLoadingLocation 
                        ? (AppLocalizations.isIndo ? 'Mendapatkan Lokasi...' : 'Getting Location...')
                        : (AppLocalizations.isIndo ? 'Check-In Sekarang' : 'Check-In Now'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else if (isCheckedIn && !isCheckedOut)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleCheckOut(shiftId),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    AppLocalizations.isIndo ? 'Check-Out (Selesai Shift)' : 'Check-Out (End Shift)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.isIndo ? 'Shift Telah Selesai' : 'Shift Completed',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ]
        ],
      ),
    );

    if (!isToday && !isPast && !isPendingSwap && shiftName.toLowerCase() != 'libur') {
      return InkWell(
        onTap: () => _showSwapRequestSheet(shiftId, shiftName, date),
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }

  String _getShiftTime(String shiftName) {
    final lower = shiftName.toLowerCase();
    if (lower.contains('pagi') || lower.contains('morning')) return '06:00 - 14:00';
    if (lower.contains('siang') || lower.contains('afternoon')) return '14:00 - 22:00';
    if (lower.contains('malam') || lower.contains('night')) return '22:00 - 06:00';
    if (lower.contains('libur') || lower.contains('off')) return '-';
    return '08:00 - 16:00'; // Default
  }
}
