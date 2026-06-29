import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

/// Displays a bottom-sheet modal for reporting an issue during an active trip.
///
/// Usage:
/// await showReportIssueSheet(context, onSubmit: (desc, tripId) async { ... });
Future<void> showReportIssueSheet(BuildContext context,
    {String? tripId,
    String? bikeCode,
    Future<bool> Function(String description, String? tripId, String? bikeCode)? onSubmit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.bg(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return _ReportIssueSheetContent(
        tripId: tripId,
        bikeCode: bikeCode,
        onSubmit: onSubmit,
      );
    },
  );
}

class _ReportIssueSheetContent extends StatefulWidget {
  final String? tripId;
  final String? bikeCode;
  final Future<bool> Function(String description, String? tripId, String? bikeCode)? onSubmit;

  const _ReportIssueSheetContent({Key? key, this.tripId, this.bikeCode, this.onSubmit}) : super(key: key);

  @override
  State<_ReportIssueSheetContent> createState() => _ReportIssueSheetContentState();
}

class _ReportIssueSheetContentState extends State<_ReportIssueSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final desc = _ctrl.text.trim();
    setState(() => _sending = true);
    bool ok = false;
    try {
      if (widget.onSubmit != null) {
        ok = await widget.onSubmit!(desc, widget.tripId, widget.bikeCode);
      } else {
        // Default behaviour: Auto-assign to nearest officer and create task.
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          
          // 1. Fetch an officer (simulating nearest)
          final officersSnap = await FirebaseFirestore.instance.collection('officers').limit(1).get();
          String assignedOfficer = 'Unassigned';
          if (officersSnap.docs.isNotEmpty) {
            assignedOfficer = officersSnap.docs.first.id;
          }
          
          // 2. Create task
          final taskDoc = FirebaseFirestore.instance.collection('tasks').doc();
          await taskDoc.set({
            'title': 'Perbaikan Sepeda ${widget.bikeCode ?? 'Tidak Diketahui'}',
            'description': desc,
            'type': 'repair',
            'status': 'pending',
            'priority': 'high',
            'assignedTo': assignedOfficer,
            'bikeId': widget.bikeCode,
            'location': 'Dari Laporan Pengguna',
            'createdAt': FieldValue.serverTimestamp(),
            'reporterId': uid,
            'tripId': widget.tripId,
          });

          // 3. Update bike status to in_repair
          if (widget.bikeCode != null) {
            await FirebaseFirestore.instance.collection('bikes').doc(widget.bikeCode).update({
              'status': 'maintenance'
            });
          }
          
          ok = true;
        } catch (e) {
          debugPrint('Error reporting issue: $e');
          ok = false;
        }
      }
    } catch (e) {
      ok = false;
    }
    setState(() => _sending = false);
    if (!mounted) return;
    
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (ok) {
      nav.pop();
      messenger.showSnackBar(SnackBar(content: Text(AppLocalizations.isIndo ? 'Laporan terkirim' : 'Report sent')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(AppLocalizations.isIndo ? 'Gagal mengirim laporan' : 'Failed to send report')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(width: 48, height: 6, decoration: BoxDecoration(color: AppTheme.outline(context), borderRadius: BorderRadius.circular(12))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text(AppLocalizations.isIndo ? 'Laporkan Masalah' : 'Report Issue', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textMain(context)))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.textMuted(context)),
                  )
                ],
              ),
            ),
            Divider(height: 1, color: AppTheme.outline(context)),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Issue context card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outline(context)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppTheme.error(context).withOpacity(0.12), shape: BoxShape.circle),
                          child: Icon(Icons.report_problem, color: AppTheme.error(context)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.isIndo ? 'Masalah Sepeda atau Stasiun?' : 'Bike or Station Issue?', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMain(context))),
                              const SizedBox(height: 6),
                              Text(AppLocalizations.isIndo ? 'Beri tahu kami detail masalah yang Anda temui selama perjalanan ini agar kami dapat segera memperbaikinya.' : 'Tell us the details of the issue you encountered during this trip so we can fix it immediately.', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textMuted(context))),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.isIndo ? 'Deskripsi Masalah' : 'Issue Description', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain(context))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ctrl,
                          maxLines: 5,
                          minLines: 3,
                          style: TextStyle(fontFamily: 'Inter', color: AppTheme.textMain(context)),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.isIndo ? 'Jelaskan masalah Anda di sini...' : 'Explain your issue here...',
                            hintStyle: TextStyle(color: AppTheme.textMuted(context)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.outline(context)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return AppLocalizations.isIndo ? 'Deskripsi diperlukan' : 'Description is required';
                            if (v.trim().length < 6) return AppLocalizations.isIndo ? 'Tolong jelaskan lebih lengkap' : 'Please explain in more detail';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted(context)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(AppLocalizations.isIndo ? 'Mohon berikan informasi spesifik (misal: rem blong, ban kempes).' : 'Please provide specific information (e.g., faulty brakes, flat tire).', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppTheme.textMuted(context)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _handleSubmit,
                  icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      AppLocalizations.isIndo ? 'Kirim Laporan' : 'Send Report',
                      style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
