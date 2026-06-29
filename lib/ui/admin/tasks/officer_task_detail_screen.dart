import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velocy_app/services/firestore_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

class OfficerTaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const OfficerTaskDetailScreen({super.key, required this.task});

  @override
  State<OfficerTaskDetailScreen> createState() => _OfficerTaskDetailScreenState();
}

class _OfficerTaskDetailScreenState extends State<OfficerTaskDetailScreen> {
  bool _isCompleting = false;
  bool _isUploading = false;
  File? _proofImage;

  StreamSubscription<Position>? _positionStream;
  LatLng? _officerPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startTrackingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _officerPosition = LatLng(position.latitude, position.longitude);
        });
      }
    });

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _officerPosition = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (_) {}
  }

  void _completeTask() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.isIndo ? 'Harap unggah bukti perbaikan terlebih dahulu.' : 'Please upload repair proof first.')),
      );
      return;
    }

    setState(() => _isCompleting = true);
    try {
      await FirestoreService().updateTaskStatus(widget.task['id'], 'completed');
      
      // Update bike status based on active trip
      if (widget.task['bikeId'] != null) {
        final bikeId = widget.task['bikeId'];
        final trips = await FirebaseFirestore.instance.collection('trips')
            .where('bikeCode', isEqualTo: bikeId)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
            
        if (trips.docs.isNotEmpty) {
          await FirestoreService().updateBikeStatus(bikeId, 'in_use');
        } else {
          await FirestoreService().updateBikeStatus(bikeId, 'available');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Tugas ditandai selesai' : 'Task marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal menyelesaikan tugas: $e' : 'Failed to complete task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.task['status'] ?? 'pending';
    final isCompleted = status == 'completed';

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(status),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 24),
                    _buildAdminNotes(),
                    const SizedBox(height: 24),
                    _buildActionRequired(),
                    const SizedBox(height: 80), // Padding for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isCompleted ? null : _buildBottomActionArea(),
    );
  }

  Widget _buildHeader(String status) {
    String statusText = AppLocalizations.isIndo ? 'Tertunda' : 'Pending';
    Color statusColor = Colors.orange;
    if (status == 'in_progress') {
      statusText = AppLocalizations.isIndo ? 'Berjalan' : 'In Progress';
      statusColor = AppTheme.primary(context);
    } else if (status == 'completed') {
      statusText = AppLocalizations.isIndo ? 'Selesai' : 'Completed';
      statusColor = Colors.grey;
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bg(context).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.primary(context)),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.isIndo ? 'Detail Tugas' : 'Task Details',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary(context),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          IconButton(
            icon: Icon(Icons.battery_charging_full, color: AppTheme.primary(context)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final title = widget.task['title'] ?? (AppLocalizations.isIndo ? 'Tugas Tidak Diketahui' : 'Unknown Task');
    final location = widget.task['location'] ?? (AppLocalizations.isIndo ? 'Lokasi Tidak Diketahui' : 'Unknown Location');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant(context).withOpacity(0.8), // glass effect approx
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.primary(context), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(Icons.pedal_bike, color: AppTheme.primary(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini Map Preview Context
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.task['tripId'] != null ? StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('trips').doc(widget.task['tripId']).snapshots(),
                builder: (context, snapshot) {
                  LatLng? userPos;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    if (data['currentLat'] != null && data['currentLng'] != null) {
                      userPos = LatLng(data['currentLat'], data['currentLng']);
                    }
                  }
                  
                  return _buildMap(userPos);
                },
              ) : _buildMap(null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng? userPos) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userPos ?? _officerPosition ?? const LatLng(-7.2798, 112.7951),
        initialZoom: 16.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.velocy_app',
        ),
        MarkerLayer(
          markers: [
            if (userPos != null)
              Marker(
                point: userPos,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Color(0xFFBA1A1A), size: 36),
              ),
            if (_officerPosition != null)
              Marker(
                point: _officerPosition!,
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminNotes() {
    final description = widget.task['description'] ?? (AppLocalizations.isIndo ? 'Tidak ada catatan tambahan.' : 'No additional notes provided.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.isIndo ? 'CATATAN ADMIN' : 'ADMIN NOTES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.textMuted(context),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.assignment, color: AppTheme.textMuted(context), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRequired() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.isIndo ? 'TINDAKAN DIPERLUKAN' : 'ACTION REQUIRED',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.textMuted(context),
            ),
          ),
        ),
        Container(
          height: 128,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.outline(context),
              width: 2,
            ),
            // Dashed border effect can be approximated or just use a solid border
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _proofImage != null || _isUploading 
                ? null 
                : () async {
                    setState(() => _isUploading = true);
                    try {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null && mounted) {
                        setState(() {
                          _proofImage = File(pickedFile.path);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.isIndo ? 'Bukti perbaikan dipilih!' : 'Repair proof selected!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal memilih gambar: $e' : 'Error picking image: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isUploading = false);
                    }
                  },
              borderRadius: BorderRadius.circular(8),
              child: _proofImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          _proofImage!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.primary(context), size: 40),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.isIndo ? 'Bukti Terlampir' : 'Proof Attached',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isUploading)
                        CircularProgressIndicator(color: AppTheme.primary(context))
                      else
                        ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.photo_camera, color: AppTheme.textMuted(context)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.isIndo ? 'Ambil Foto Perbaikan' : 'Take Repair Photo',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                        ],
                    ],
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface(context).withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: (_isCompleting || _proofImage == null) ? null : _completeTask,
          icon: _isCompleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                )
              : Icon(Icons.check_circle, color: _proofImage != null ? Colors.black : Colors.grey),
          label: Text(
            _isCompleting ? (AppLocalizations.isIndo ? 'Menyelesaikan...' : 'Completing...') : (AppLocalizations.isIndo ? 'Selesaikan Tugas' : 'Complete Task'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _proofImage != null ? Colors.black : Colors.grey,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _proofImage != null ? AppTheme.primary(context) : AppTheme.surfaceVariant(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: _proofImage != null ? 4 : 0,
            shadowColor: _proofImage != null ? AppTheme.primary(context).withOpacity(0.4) : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
