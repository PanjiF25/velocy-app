import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';

class ExitConfirmationWrapper extends StatelessWidget {
  final Widget child;

  const ExitConfirmationWrapper({super.key, required this.child});

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bg(context),
        title: Text(
          AppLocalizations.isIndo ? 'Keluar Aplikasi' : 'Exit App',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: AppTheme.textMain(context),
          ),
        ),
        content: Text(
          AppLocalizations.isIndo
              ? 'Apakah Anda yakin ingin keluar dari aplikasi?'
              : 'Are you sure you want to exit the app?',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppTheme.textMuted(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.isIndo ? 'Batal' : 'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.textMuted(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error(context),
              foregroundColor: Colors.white,
            ),
            child: Text(
              AppLocalizations.isIndo ? 'Keluar' : 'Exit',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}
