import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'officer_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _routeBasedOnRole(User user) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        _showMessage(
          'Akun berhasil login, tapi profil Firestore belum ada. Tambahkan dokumen users/{uid} dengan role officer atau user dulu.',
        );
        return;
      }

      final data = snapshot.data();
      final role = (data?['role'] as String?) ?? 'user';

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              role == 'officer' ? const OfficerScreen() : const HomeScreen(),
        ),
        (route) => false,
      );
      return;
    } catch (e, st) {
      debugPrint('Error routing by role: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _routeBasedOnRole(credential.user!);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.code} ${e.message}');
      _showMessage(e.message ?? 'Login gagal.');
    } catch (e, st) {
      debugPrint('Unknown error during login: $e');
      debugPrintStack(stackTrace: st);
      _showMessage('Login gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Section
                const Text(
                  'Velocy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F6E56),
                    letterSpacing: -0.56,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masuk untuk mulai meminjam sepeda',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3F4944),
                  ),
                ),
                const SizedBox(height: 48),

                // Form Card Section
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBEC9C3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000), // rgba(0,0,0,0.05)
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3F4944),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF141B2B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'nama@email.com',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFBEC9C3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFFBEC9C3),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFBEC9C3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF0F6E56)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 4.0, right: 4.0, bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3F4944),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigate to Forgot Password
                              },
                              child: const Text(
                                'Lupa?',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1960A6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF141B2B),
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFBEC9C3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFFBEC9C3),
                            size: 20,
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFFBEC9C3),
                              size: 20,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFBEC9C3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFF0F6E56)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Primary Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6E56),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Footer Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1960A6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
