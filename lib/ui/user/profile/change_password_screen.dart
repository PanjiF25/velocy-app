import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Tidak ada pengguna yang login.');

      // Rekredensial pengguna sebelum mengganti password
      final email = user.email;
      if (email == null) throw Exception('Email pengguna tidak ditemukan.');

      final credential = EmailAuthProvider.credential(
        email: email,
        password: _oldPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah!')),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat mengganti password.';
      if (e.code == 'wrong-password') {
        message = 'Password lama salah.';
      } else if (e.code == 'weak-password') {
        message = 'Password baru terlalu lemah.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textMain(context)),
        title: Text(
          'Ganti Password',
          style: TextStyle(
            color: AppTheme.textMain(context),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPasswordField(
                  controller: _oldPasswordController,
                  label: 'Password Lama',
                  obscureText: _obscureOld,
                  onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
                  validator: (value) => value == null || value.isEmpty ? 'Masukkan password lama' : null,
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Password Baru',
                  obscureText: _obscureNew,
                  onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (value) => value != null && value.length < 6 ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password Baru',
                  obscureText: _obscureConfirm,
                  onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Konfirmasi password baru';
                    if (value != _newPasswordController.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Ubah Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textMuted(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.outline(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary(context), width: 2),
        ),
        prefixIcon: Icon(Icons.lock, color: AppTheme.textMuted(context)),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textMuted(context),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      style: TextStyle(color: AppTheme.textMain(context)),
    );
  }
}
