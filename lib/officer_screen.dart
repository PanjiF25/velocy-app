import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class OfficerScreen extends StatelessWidget {
  const OfficerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF141B2B)),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) {
              return;
            }

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Halaman Petugas',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF141B2B),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Halaman Petugas',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF141B2B),
          ),
        ),
      ),
    );
  }
}