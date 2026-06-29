import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:velocy_app/ui/user/home_screen.dart';
import 'package:velocy_app/ui/admin/dashboard/officer_screen.dart';
import 'package:velocy_app/ui/auth/register_screen.dart';
import 'package:velocy_app/debug/seed_data_screen.dart';
import 'package:velocy_app/services/notification_service.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';

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
      String role = 'user';

      // 1. Cek apakah user ada di koleksi officers terlebih dahulu
      final officerRef = FirebaseFirestore.instance.collection('officers').doc(user.uid);
      final officerSnapshot = await officerRef.get();

      if (officerSnapshot.exists) {
        role = 'officer';
      } else {
        // 2. Jika bukan petugas, cek koleksi users (pengguna biasa / admin)
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final data = snapshot.data();
          role = (data?['role'] as String?) ?? 'user';
        } else {
          _showMessage(
            'Akun berhasil login, tapi profil Firestore belum ada. Harap lapor admin.',
          );
          return;
        }
      }

      if (!mounted) return;

      // Start notification listener for officers
      if (role == 'officer') {
        NotificationService().startListening();
      }

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
      _showMessage('Mohon lengkapi email dan kata sandi Anda.', isError: true);
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
      
      final user = credential.user;
      if (user != null) {
        // TODO: ENABLE THIS FOR PRODUCTION (Currently bypassed for testing dummy accounts)
        // if (!user.emailVerified) {
        //   await FirebaseAuth.instance.signOut();
        //   _showMessage('Email belum diverifikasi. Silakan cek kotak masuk atau folder spam email Anda.', isError: true);
        //   setState(() { _isLoading = false; });
        //   return;
        // }
        await _routeBasedOnRole(user);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during login: ${e.code}');
      _showMessage(_mapFirebaseError(e.code), isError: true);
    } catch (e, st) {
      debugPrint('Unknown error during login: $e');
      debugPrintStack(stackTrace: st);
      _showMessage('Gagal masuk: Terjadi kesalahan sistem.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'Akun tidak ditemukan.';
      case 'wrong-password': return 'Kata sandi salah.';
      case 'invalid-email': return 'Format email tidak valid.';
      case 'user-disabled': return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests': return 'Terlalu banyak percobaan gagal. Coba lagi nanti.';
      case 'invalid-credential': return 'Email atau kata sandi salah.';
      case 'email-already-in-use': return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password': return 'Kata sandi terlalu lemah. Minimal 6 karakter.';
      default: return 'Terjadi kesalahan sistem. Silakan coba lagi.';
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Section
                Text(
                  AppLocalizations.tr('LoginTitle'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary(context),
                    letterSpacing: -0.56,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.tr('LoginSubtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 48),

                // Form Card Section
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outline(context)),
                    boxShadow: [
                      if (!AppTheme.isDark(context))
                        const BoxShadow(
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
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.textMain(context),
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.tr('EmailHint'),
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: AppTheme.outline(context),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.mail_outline,
                            color: AppTheme.outline(context),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppTheme.outline(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppTheme.primary(context)),
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
                            Text(
                              'Password',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigate to Forgot Password
                              },
                              child: Text(
                                AppLocalizations.tr('ForgotPassword'),
                                style: const TextStyle(
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
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.textMain(context),
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: AppTheme.outline(context),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.outline(context),
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
                              color: AppTheme.outline(context),
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
                                BorderSide(color: AppTheme.outline(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppTheme.primary(context)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Primary Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary(context),
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
                            : Text(
                                AppLocalizations.tr('SignIn'),
                                style: const TextStyle(
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
                    Text(
                      AppLocalizations.tr('CreatingAccount'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppTheme.textMuted(context),
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
                      child: Text(
                        AppLocalizations.tr('Register'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1960A6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Temporary Seed Button

              ],
            ),
          ),
        ),
      ),
    );
  }
}
