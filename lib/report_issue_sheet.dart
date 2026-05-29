import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Displays a bottom-sheet modal for reporting an issue during an active trip.
///
/// Usage:
/// await showReportIssueSheet(context, onSubmit: (desc, tripId) async { ... });
Future<void> showReportIssueSheet(BuildContext context,
    {String? tripId,
    Future<bool> Function(String description, String? tripId)? onSubmit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return _ReportIssueSheetContent(
        tripId: tripId,
        onSubmit: onSubmit,
      );
    },
  );
}

class _ReportIssueSheetContent extends StatefulWidget {
  final String? tripId;
  final Future<bool> Function(String description, String? tripId)? onSubmit;

  const _ReportIssueSheetContent({Key? key, this.tripId, this.onSubmit}) : super(key: key);

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
        ok = await widget.onSubmit!(desc, widget.tripId);
      } else {
        // Default behaviour: try to write to Firestore using current user if available.
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final doc = FirebaseFirestore.instance.collection('reports').doc();
          await doc.set({
            'userId': uid,
            'tripId': widget.tripId,
            'description': desc,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
          ok = true;
        } catch (e) {
          // fallback to simulated send
          await Future.delayed(const Duration(milliseconds: 800));
          ok = false;
        }
      }
    } catch (e) {
      ok = false;
    }
    setState(() => _sending = false);
    if (!mounted) return;
    if (ok) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan terkirim')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim laporan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = const Radius.circular(24);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(width: 48, height: 6, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(12))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Laporkan Masalah', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Issue context card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.12), shape: BoxShape.circle),
                          child: Icon(Icons.report_problem, color: theme.colorScheme.error),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Masalah Sepeda atau Stasiun?', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Beri tahu kami detail masalah yang Anda temui selama perjalanan ini agar kami dapat segera memperbaikinya.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75))),
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
                        Text('Deskripsi Masalah', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ctrl,
                          maxLines: 5,
                          minLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Jelaskan masalah Anda di sini...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Deskripsi diperlukan';
                            if (v.trim().length < 6) return 'Tolong jelaskan lebih lengkap';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: theme.dividerColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Mohon berikan informasi spesifik (misal: rem blong, ban kempes).', style: theme.textTheme.bodySmall)),
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
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Kirim Laporan'),
                  ),
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
