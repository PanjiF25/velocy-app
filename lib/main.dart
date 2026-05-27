import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
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
