import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:velocy_app/ui/user/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showMessage('Semua kolom wajib diisi.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'Akun gagal dibuat.',
        );
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'role': 'user',
          'displayName': name,
          'email': email,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e, st) {
        debugPrint('Firestore write failed: $e');
        debugPrintStack(stackTrace: st);
        _showMessage('Gagal mendaftar: tidak bisa menyimpan profil.', isError: true);
        return;
      }

      // Send verification email
      await user.sendEmailVerification();
      
      // Sign out so they have to login after verifying
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      _showMessage('Pendaftaran berhasil! Silakan cek kotak masuk email Anda untuk verifikasi.', isError: false);
      
      // Return to login screen
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during register: ${e.code}');
      _showMessage(_mapFirebaseError(e.code), isError: true);
    } catch (e, st) {
      debugPrint('Unknown error during register: $e');
      debugPrintStack(stackTrace: st);
      _showMessage('Pendaftaran gagal: Terjadi kesalahan sistem.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
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
                const SizedBox(height: 8),
                const Text(
                  'Daftar akun pengguna untuk mulai meminjam sepeda',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3F4944),
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card Section
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBEC9C3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000), // rgba(0,0,0,0.05)
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name Field
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          'Nama Lengkap',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF141B2B),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF141B2B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama lengkap',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFBEC9C3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF3F4944),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF005440)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF141B2B),
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
                          hintText: 'Masukkan alamat email',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFBEC9C3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF3F4944),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF005440)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Number Field
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          'Nomor Telepon',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF141B2B),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF141B2B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nomor telepon',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFBEC9C3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF3F4944),
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF005440)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          'Kata Sandi',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF141B2B),
                          ),
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
                          hintText: 'Buat kata sandi',
                          hintStyle: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFFBEC9C3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF3F4944),
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
                              color: const Color(0xFF3F4944),
                              size: 20,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF005440)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Akun petugas dibuat oleh admin, bukan dari halaman ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF3F4944),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6E56),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                                'Daftar',
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
                const SizedBox(height: 24),

                // Login Link
                GestureDetector(
                  onTap: () {
                    // Navigate back to Login Screen
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF1960A6),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
