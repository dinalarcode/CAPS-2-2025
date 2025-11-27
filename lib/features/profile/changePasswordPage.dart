import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrilink/config/appTheme.dart';

const Color kGreen = Color(0xFF5F9C3F);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : AppColors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _toast('User tidak ditemukan', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      debugPrint('🔐 Attempting to change password for: ${user.email}');

      // Step 1: Re-authenticate dengan password lama
      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint('✅ Re-authentication successful');
      } on FirebaseAuthException catch (e) {
        final errorMsg = switch (e.code) {
          'wrong-password' => 'Password saat ini tidak sesuai',
          'invalid-credential' => 'Kredensial tidak valid',
          'user-mismatch' => 'User tidak cocok',
          _ => 'Gagal verifikasi password: ${e.message}',
        };
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
        _toast(errorMsg, isError: true);
        debugPrint('❌ Re-authentication failed: ${e.code}');
        return;
      }

      // Step 2: Update password
      await user.updatePassword(newPassword);
      debugPrint('✅ Password updated successfully');

      // Step 3: Reload user untuk update state
      await user.reload();
      debugPrint('✅ User reloaded');

      // Success
      if (!mounted) return;
      _toast('✅ Password berhasil diubah!');

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Delay sebelum pop
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      final errorMsg = switch (e.code) {
        'weak-password' =>
          'Password terlalu lemah. Gunakan minimal 6 karakter dengan kombinasi huruf dan angka.',
        'requires-recent-login' =>
          'Silakan login kembali untuk keamanan akun Anda.',
        'operation-not-allowed' => 'Operasi tidak diizinkan untuk akun ini.',
        _ => 'Gagal mengubah password: ${e.message}',
      };
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      _toast(errorMsg, isError: true);
      debugPrint('❌ Error changing password: ${e.code} - ${e.message}');
    } catch (e) {
      final errorMsg = 'Terjadi kesalahan: $e';
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      _toast(errorMsg, isError: true);
      debugPrint('❌ Unexpected error: $e');
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    String hint, {
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kMutedBorderGrey, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kMutedBorderGrey, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[600]!, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: IconButton(
        icon: Icon(
          showPassword ? Icons.visibility : Icons.visibility_off,
          color: kMutedBorderGrey,
          size: 20,
        ),
        onPressed: onToggleVisibility,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ganti Password',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- INFO SECTION ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kGreen.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: kGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Untuk keamanan akun, masukkan password saat ini terlebih dahulu untuk verifikasi.',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- ERROR MESSAGE ---
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // --- CURRENT PASSWORD ---
              Text(
                'Password Saat Ini',
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                enabled: !_isLoading,
                decoration: _buildInputDecoration(
                  'Password Saat Ini',
                  'Masukkan password Anda saat ini',
                  showPassword: _showCurrentPassword,
                  onToggleVisibility: () {
                    setState(
                        () => _showCurrentPassword = !_showCurrentPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password saat ini harus diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- NEW PASSWORD ---
              Text(
                'Password Baru',
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                enabled: !_isLoading,
                decoration: _buildInputDecoration(
                  'Password Baru',
                  'Buat password baru Anda',
                  showPassword: _showNewPassword,
                  onToggleVisibility: () {
                    setState(() => _showNewPassword = !_showNewPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru harus diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'Password baru tidak boleh sama dengan password saat ini';
                  }
                  // Check complexity
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Password harus mengandung huruf kecil';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Password harus mengandung huruf besar';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Password harus mengandung angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Minimal 6 karakter dengan kombinasi huruf besar, huruf kecil, dan angka',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // --- CONFIRM PASSWORD ---
              Text(
                'Konfirmasi Password Baru',
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _changePassword(),
                decoration: _buildInputDecoration(
                  'Konfirmasi Password Baru',
                  'Ulangi password baru Anda',
                  showPassword: _showConfirmPassword,
                  onToggleVisibility: () {
                    setState(
                        () => _showConfirmPassword = !_showConfirmPassword);
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password harus diisi';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Konfirmasi password tidak sesuai dengan password baru';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // --- PASSWORD STRENGTH INDICATOR ---
              if (_newPasswordController.text.isNotEmpty) ...[
                _buildPasswordStrengthIndicator(),
                const SizedBox(height: 24),
              ],

              // --- BUTTONS ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Ubah Password',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          setState(() => _errorMessage = null);
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: _isLoading ? Colors.grey[300]! : kMutedBorderGrey,
                      width: 1.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _isLoading ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    int strength = 0;
    String strengthText = '';
    Color strengthColor = Colors.red;

    // Check strength criteria
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>?]').hasMatch(password))
      strength++;

    // Determine strength level
    if (strength <= 2) {
      strengthText = 'Lemah';
      strengthColor = Colors.red;
    } else if (strength <= 4) {
      strengthText = 'Sedang';
      strengthColor = Colors.orange;
    } else {
      strengthText = 'Kuat';
      strengthColor = kGreen;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kekuatan Password',
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength / 6,
            minHeight: 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
      ],
    );
  }
}
