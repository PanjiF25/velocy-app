import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Initialization may fail if platform config not added yet (google-services.json / plist)
    // App can still run but Firestore calls will error until config is provided.
    debugPrint('Firebase.initializeApp() failed: $e');
  }

  runApp(const VelocyApp());
}

class VelocyApp extends StatelessWidget {
  const VelocyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velocy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E56)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
