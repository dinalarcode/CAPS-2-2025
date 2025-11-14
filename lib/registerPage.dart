// lib/registerPage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

// ==== Palet warna konsisten ====
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
final Color kBaseGreyFill = const Color(0xFF000000).withValues(alpha: .04);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late UserProfileDraft draft;

  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context); // ambil draft onboarding terakhir
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    _confirmPasswordC.dispose();
    super.dispose();
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  /// Bangun map profil dari draft + user.
  /// Field yang nilainya null akan dibuang supaya tidak tersimpan sebagai null di Firestore.
  Map<String, dynamic> _buildProfileData(User user) {
    final Timestamp? birthDateTimestamp = draft.birthDate != null
        ? Timestamp.fromDate(draft.birthDate!)
        : null;

    final List<String>? allergies = (draft.allergies.isEmpty)
        ? null
        : draft.allergies;

    final List<String>? challenges = (draft.challenges.isEmpty)
        ? null
        : draft.challenges;

    final data = <String, dynamic>{
      'name': (draft.name == null || draft.name!.isEmpty)
          ? (user.displayName ?? '')
          : draft.name,
      'target': (draft.target == null || draft.target!.isEmpty)
          ? null
          : draft.target,
      'healthGoal': (draft.healthGoal == null || draft.healthGoal!.isEmpty)
          ? null
          : draft.healthGoal,
      'challenges': challenges,
      'heightCm': draft.heightCm,
      'weightKg': draft.weightKg,
      'targetWeightKg': draft.targetWeightKg,
      'birthDate': birthDateTimestamp,
      'sex': (draft.sex == null || draft.sex!.isEmpty) ? null : draft.sex,
      'activityLevel': (draft.activityLevel == null ||
              draft.activityLevel!.isEmpty)
          ? null
          : draft.activityLevel,
      'allergies': allergies,
      'eatFrequency': draft.eatFrequency,
      'sleepHours': draft.sleepHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Buang semua field yang nilainya null
    data.removeWhere((key, value) => value == null);

    return data;
  }

  Future<void> _afterRegister(User user, String provider) async {
    final db = FirebaseFirestore.instance;

    // Update displayName kalau belum ada & draft punya nama
    if ((user.displayName == null || user.displayName!.isEmpty) &&
        (draft.name != null && draft.name!.isNotEmpty)) {
      await user.updateDisplayName(draft.name);
    }

    // Kirim email verifikasi kalau belum
    if (!user.emailVerified && user.email != null) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('Gagal kirim email verifikasi: $e');
      }
    }

    // Build data profile dari draft
    final profileData = _buildProfileData(user);

    await db.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'email': user.email,
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
        'profile': profileData,
      },
      SetOptions(merge: true),
    );

    // Logout supaya user harus login ulang setelah verifikasi email
    await FirebaseAuth.instance.signOut();

    _showSnack(
      provider == 'google'
          ? 'Akun berhasil terdaftar. Jika diminta verifikasi, cek email kamu lalu login kembali.'
          : 'Registrasi berhasil. Cek email kamu untuk verifikasi sebelum login.',
      color: Colors.green,
    );

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ==== REGISTER EMAIL & PASSWORD ====
  Future<void> _registerWithEmail() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailC.text.trim();
      final password = _passwordC.text.trim();

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = cred.user;
      if (user == null) {
        _showSnack('Terjadi kesalahan. User tidak terbentuk.');
        return;
      }

      await _afterRegister(user, 'password');
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mendaftar. Coba lagi.';
      if (e.code == 'email-already-in-use') {
        msg = 'Email sudah terdaftar. Coba masuk atau gunakan email lain.';
      } else if (e.code == 'weak-password') {
        msg = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      } else if (e.code == 'invalid-email') {
        msg = 'Format email tidak valid.';
      }
      if (!mounted) return;
      _showSnack(msg, color: Theme.of(context).colorScheme.error);
    } catch (e) {
      debugPrint('Register error: $e');
      if (!mounted) return;
      _showSnack(
        'Terjadi kesalahan saat mendaftar.',
        color: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==== REGISTER / LINK DENGAN GOOGLE ====
  Future<void> _registerWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // user batal pilih akun
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        _showSnack('Gagal menghubungkan akun Google.');
        return;
      }

      await _afterRegister(user, 'google');
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in error: $e');
      if (!mounted) return;
      _showSnack(
        'Gagal mendaftar dengan Google.',
        color: Theme.of(context).colorScheme.error,
      );
    } catch (e) {
      debugPrint('Google register error: $e');
      if (!mounted) return;
      _showSnack(
        'Terjadi kesalahan saat mendaftar dengan Google.',
        color: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==== UI FIELD ====
  Widget _buildTextFieldEmail() {
    return TextFormField(
      controller: _emailC,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'nama@email.com',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Email tidak boleh kosong.';
        }
        if (!v.contains('@')) {
          return 'Format email tidak valid.';
        }
        return null;
      },
    );
  }

  Widget _buildTextFieldPassword() {
    return TextFormField(
      controller: _passwordC,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Minimal 6 karakter',
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Password tidak boleh kosong.';
        }
        if (v.length < 6) {
          return 'Password minimal 6 karakter.';
        }
        return null;
      },
    );
  }

  Widget _buildTextFieldConfirmPassword() {
    return TextFormField(
      controller: _confirmPasswordC,
      obscureText: _obscureConfirm,
      decoration: InputDecoration(
        labelText: 'Konfirmasi Password',
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscureConfirm = !_obscureConfirm);
          },
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Konfirmasi password tidak boleh kosong.';
        }
        if (v != _passwordC.text) {
          return 'Konfirmasi password tidak sama.';
        }
        return null;
      },
    );
  }

  // ==== BUILD UI ====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Daftar Akun',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading mirip style onboarding
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: 'Buat akun '),
                            TextSpan(
                              text: 'NutriLink',
                              style: TextStyle(color: kGreen),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dengan akun, progres dan pengaturan makananmu akan tersimpan rapi di satu tempat.',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kGreyText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (draft.name != null && draft.name!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Halo, ${draft.name}! Daftarkan email untuk menghubungkan profilmu.',
                            style: const TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kLightGreyText,
                            ),
                          ),
                        ),

                      _buildTextFieldEmail(),
                      const SizedBox(height: 16),
                      _buildTextFieldPassword(),
                      const SizedBox(height: 16),
                      _buildTextFieldConfirmPassword(),
                      const SizedBox(height: 24),

                      const Center(
                        child: Text(
                          'Dengan mendaftar, kamu menyetujui Ketentuan Layanan & Kebijakan Privasi NutriLink.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 11,
                            color: kLightGreyText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 12,
                                color: kLightGreyText,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tombol Google
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _registerWithGoogle,
                          icon: Image.asset(
                            'assets/images/Logo Google.png',
                            width: 20,
                            height: 20,
                          ),
                          label: const Text(
                            'Daftar dengan Google',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kGreyText,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 12,
                                color: kGreyText,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      ),
                              child: const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontFamily: 'Funnel Display',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer: tombol Daftar (gradient hijau, non-transparan)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: _isLoading ? 'Memproses...' : 'Simpan & Lanjut ke Login',
                  enabled: !_isLoading,
                  onPressed: _registerWithEmail,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GRADIENT BUTTON (copy style dari onboarding / TargetSelectionPage)
// ============================================================================
class GradientButton extends StatefulWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool hover = false;
  bool press = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && (hover || press);

    final gradient = widget.enabled
        ? LinearGradient(
            colors: active
                ? const [kGreen, kGreenLight]
                : const [kGreenLight, kGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() {
        hover = false;
        press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enabled) setState(() => press = true);
        },
        onTapUp: (_) {
          if (widget.enabled) setState(() => press = false);
        },
        onTapCancel: () {
          if (widget.enabled) setState(() => press = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            color: widget.enabled ? null : kBaseGreyFill,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.enabled ? kGreen : kDisabledGrey,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: TextButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
