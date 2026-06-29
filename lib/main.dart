import 'package:flutter/material.dart';
import 'package:velocy_app/ui/common/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:velocy_app/services/firebase_options.dart';
import 'package:velocy_app/core/providers/settings_provider.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp() failed: $e');
  }

  // Initialize local notifications
  await NotificationService().init();

  runApp(const VelocyApp());
}

class VelocyApp extends StatelessWidget {
  const VelocyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsProvider();
    
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Velocy',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          locale: settings.locale,
          // Define a basic light theme
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryLight,
              brightness: Brightness.light,
              background: AppTheme.bgLight,
              surface: AppTheme.surfaceLight,
              error: AppTheme.errorLight,
              primaryContainer: AppTheme.primaryContainerLight,
            ),
            scaffoldBackgroundColor: AppTheme.bgLight,
            useMaterial3: true,
          ),
          // Define a basic dark theme
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryDark,
              brightness: Brightness.dark,
              background: AppTheme.bgDark,
              surface: AppTheme.surfaceDark,
              error: AppTheme.errorDark,
              primaryContainer: AppTheme.primaryContainerDark,
            ),
            scaffoldBackgroundColor: AppTheme.bgDark,
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
