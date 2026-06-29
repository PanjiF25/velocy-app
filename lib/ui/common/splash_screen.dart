import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:velocy_app/ui/auth/login_screen.dart';
import 'package:velocy_app/ui/user/home_screen.dart';
import 'package:velocy_app/ui/admin/dashboard/officer_screen.dart';
import 'package:velocy_app/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _routeNext();
      }
    });
  }

  Future<void> _routeNext() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    String role = 'user';

    // 1. Cek apakah user ada di koleksi officers terlebih dahulu
    final officerRef = FirebaseFirestore.instance.collection('officers').doc(user.uid);
    final officerSnapshot = await officerRef.get();

    if (officerSnapshot.exists) {
      role = 'officer';
    } else {
      // 2. Jika bukan petugas, cek koleksi users
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'role': 'user',
          'displayName': user.email ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data();
        role = (data?['role'] as String?) ?? 'user';
      }
    }

    // Start notification listener for officers
    if (role == 'officer') {
      NotificationService().startListening();
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            role == 'officer' ? const OfficerScreen() : const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F6E56),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bike,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'Velocy',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.64, // -0.02em of 32px
              ),
            ),
            SizedBox(height: 40),
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
