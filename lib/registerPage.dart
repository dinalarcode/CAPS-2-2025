// lib/registerPage.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';
import 'package:nutrilink/termsAndConditionsDetailPage.dart';

// ====== Palet warna konsisten dengan ChallengePage ======
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill =
    const Color(0xFF000000).withValues(alpha: 0.04);

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
  final _focusPassword = FocusNode();
  final _focusConfirm = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Coba ambil dari arguments terlebih dahulu (dari SummaryPage)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is UserProfileDraft) {
      draft = args;
      debugPrint('✅ Draft loaded from arguments');
    } else {
      // Fallback: ambil dari getDraft (local storage)
      draft = getDraft(context);
      debugPrint('⚠️ Draft loaded from local storage');
    }
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    _confirmPasswordC.dispose();
    _focusPassword.dispose();
    _focusConfirm.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // --- Dekorasi input: border kotak, muted grey, style Funnel Display ---
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontFamily: 'Funnel Display',
        fontSize: 13,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: kMutedBorderGrey,
          width: 1.4,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: kGreenLight,
          width: 1.6,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  /// Bangun map profil dari draft + user.
  Map<String, dynamic> _buildProfileData(User user) {
    // Debug: Print draft data untuk troubleshooting
    debugPrint('=== DEBUG: Draft Data ===');
    debugPrint('name: ${draft.name}');
    debugPrint('target: ${draft.target}');
    debugPrint('healthGoal: ${draft.healthGoal}');
    debugPrint('challenges: ${draft.challenges}');
    debugPrint('heightCm: ${draft.heightCm}');
    debugPrint('weightKg: ${draft.weightKg}');
    debugPrint('targetWeightKg: ${draft.targetWeightKg}');
    debugPrint('birthDate: ${draft.birthDate}');
    debugPrint('sex: ${draft.sex}');
    debugPrint('activityLevel: ${draft.activityLevel}');
    debugPrint('allergies: ${draft.allergies}');
    debugPrint('eatFrequency: ${draft.eatFrequency}');
    debugPrint('wakeTime: ${draft.wakeTime}');
    debugPrint('sleepTime: ${draft.sleepTime}');
    debugPrint('sleepHours: ${draft.sleepHours}');
    debugPrint('=========================');

    final Timestamp? birthDateTimestamp = draft.birthDate != null
        ? Timestamp.fromDate(draft.birthDate!)
        : null;

    final List<String>? allergies = (draft.allergies.isEmpty)
        ? null
        : draft.allergies;

    final List<String>? challenges = (draft.challenges.isEmpty)
        ? null
        : draft.challenges;

    // Konversi TimeOfDay ke format string untuk Firestore
    final wakeTimeString = draft.wakeTime != null
        ? '${draft.wakeTime!.hour.toString().padLeft(2, '0')}:${draft.wakeTime!.minute.toString().padLeft(2, '0')}'
        : null;
    final sleepTimeString = draft.sleepTime != null
        ? '${draft.sleepTime!.hour.toString().padLeft(2, '0')}:${draft.sleepTime!.minute.toString().padLeft(2, '0')}'
        : null;

    // Tentukan profile picture default berdasarkan jenis kelamin
    String profilePicture = 'assets/images/Male Avatar.png'; // default
    if (draft.sex != null) {
      if (draft.sex!.toLowerCase().contains('perempuan') || 
          draft.sex!.toLowerCase().contains('wanita') ||
          draft.sex!.toLowerCase().contains('female')) {
        profilePicture = 'assets/images/Female Avatar.png';
      } else if (draft.sex!.toLowerCase().contains('laki') || 
                 draft.sex!.toLowerCase().contains('pria') ||
                 draft.sex!.toLowerCase().contains('male')) {
        profilePicture = 'assets/images/Male Avatar.png';
      }
    }

    final data = <String, dynamic>{
      'name': (draft.name == null || draft.name!.isEmpty)
          ? (user.displayName ?? '')
          : draft.name,
      'target': draft.target, // Simpan semua, termasuk null
      'healthGoal': draft.healthGoal,
      'challenges': challenges,
      'heightCm': draft.heightCm,
      'weightKg': draft.weightKg,
      'targetWeightKg': draft.targetWeightKg,
      'birthDate': birthDateTimestamp,
      'sex': draft.sex,
      'activityLevel': draft.activityLevel,
      'allergies': allergies,
      'eatFrequency': draft.eatFrequency,
      'wakeTime': wakeTimeString,
      'sleepTime': sleepTimeString,
      'sleepHours': draft.sleepHours,
      'profilePicture': profilePicture,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    debugPrint('=== Profile Data to Save ===');
    debugPrint('name: ${data['name']}');
    debugPrint('target: ${data['target']}');
    debugPrint('healthGoal: ${data['healthGoal']}');
    debugPrint('challenges: ${data['challenges']}');
    debugPrint('heightCm: ${data['heightCm']}');
    debugPrint('weightKg: ${data['weightKg']}');
    debugPrint('targetWeightKg: ${data['targetWeightKg']}');
    debugPrint('birthDate: ${data['birthDate']}');
    debugPrint('sex: ${data['sex']}');
    debugPrint('activityLevel: ${data['activityLevel']}');
    debugPrint('allergies: ${data['allergies']}');
    debugPrint('eatFrequency: ${data['eatFrequency']}');
    debugPrint('wakeTime: ${data['wakeTime']}');
    debugPrint('sleepTime: ${data['sleepTime']}');
    debugPrint('sleepHours: ${data['sleepHours']}');
    debugPrint('profilePicture: ${data['profilePicture']}');
    debugPrint('============================');

    return data;
  }

  Future<void> _afterRegister(User user, String provider) async {
    final db = FirebaseFirestore.instance;

    // Update displayName kalau belum ada & draft punya nama
    if ((user.displayName == null || user.displayName!.isEmpty) &&
        (draft.name != null && draft.name!.isNotEmpty)) {
      await user.updateDisplayName(draft.name);
    }

    // Reload user untuk mendapatkan status terbaru
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // WAJIB kirim email verifikasi untuk SEMUA metode registrasi
    // emailVerifiedByApp akan di-set true hanya setelah user klik link verifikasi
    bool emailSent = false;
    String? emailAddress;
    
    if (refreshedUser != null && refreshedUser.email != null) {
      emailAddress = refreshedUser.email;
      
      try {
        // Kirim email verifikasi untuk SEMUA metode (email & Google)
        await refreshedUser.sendEmailVerification();
        emailSent = true;
        debugPrint('Email verifikasi berhasil dikirim ke $emailAddress');
      } catch (e) {
        debugPrint('ERROR: Gagal kirim email verifikasi: $e');
        _toast('Peringatan: Gagal mengirim email verifikasi. Error: $e');
      }
    }

    // Build data profile dari draft
    final profileData = _buildProfileData(user);

    debugPrint('=== SAVING TO FIRESTORE ===');
    debugPrint('User UID: ${user.uid}');
    debugPrint('Email: ${user.email}');
    debugPrint('Provider: $provider');
    debugPrint('Profile Data: $profileData');
    debugPrint('============================');

    await db.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'email': user.email,
        'provider': provider,
        'emailVerifiedByApp': false, // WAJIB verifikasi email manual
        'createdAt': FieldValue.serverTimestamp(),
        'profile': profileData,
      },
      SetOptions(merge: true),
    );

    debugPrint('✅ Data successfully saved to Firestore!');

    // PENTING: Logout supaya user HARUS login ulang setelah verifikasi email
    await FirebaseAuth.instance.signOut();

    // Pesan yang konsisten untuk semua metode
    if (emailSent) {
      final method = provider == 'google' ? 'Google' : 'email';
      _toast(
        'Registrasi berhasil dengan $method! Email verifikasi telah dikirim ke $emailAddress. '
        'Cek inbox/spam dan klik tautan verifikasi sebelum login.',
      );
    } else {
      _toast(
        'Registrasi berhasil! Namun email verifikasi gagal dikirim. '
        'Silakan coba daftar ulang atau hubungi admin.',
      );
    }

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
        _toast('Terjadi kesalahan. User tidak terbentuk.');
        return;
      }

      await _afterRegister(user, 'password');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' =>
          'Email sudah terdaftar. Coba masuk atau gunakan email lain.',
        'weak-password' =>
          'Password terlalu lemah. Gunakan minimal 6 karakter.',
        'invalid-email' => 'Format email tidak valid.',
        _ => 'Gagal mendaftar: ${e.message}',
      };
      _toast(msg);
    } catch (e) {
      debugPrint('Register error: $e');
      _toast('Terjadi kesalahan saat mendaftar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==== REGISTER / LINK DENGAN GOOGLE ====
  Future<void> _registerWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      UserCredential cred;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        cred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
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

        cred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = cred.user;
      if (user == null) {
        _toast('Gagal menghubungkan akun Google.');
        return;
      }

      await _afterRegister(user, 'google');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'account-exists-with-different-credential' =>
          'Email ini sudah terhubung dengan metode login lain.',
        'invalid-credential' => 'Kredensial Google tidak valid.',
        'operation-not-allowed' =>
          'Login dengan Google belum diaktifkan di Firebase.',
        _ => 'Gagal mendaftar dengan Google: ${e.message}',
      };
      _toast(msg);
    } catch (e) {
      debugPrint('Google register error: $e');
      _toast('Gagal mendaftar dengan Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  // ==== BUILD UI ====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ====== KONTEN UTAMA ======
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 140),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul: style sama dengan ChallengePage
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
                            TextSpan(text: ' kamu.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          padding: const EdgeInsets.only(bottom: 16.0),
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

                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.w500,
                          color: kLightGreyText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailC,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _focusPassword.requestFocus(),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        decoration: _inputDecoration('contoh@email.com'),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(s)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.w500,
                          color: kLightGreyText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordC,
                        focusNode: _focusPassword,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _focusConfirm.requestFocus(),
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration:
                            _inputDecoration('Minimal 6 karakter').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kMutedBorderGrey,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (v.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Konfirmasi Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.w500,
                          color: kLightGreyText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordC,
                        focusNode: _focusConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _registerWithEmail(),
                        obscureText: _obscureConfirm,
                        decoration: _inputDecoration('Ulangi password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: kMutedBorderGrey,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          if (v != _passwordC.text) {
                            return 'Konfirmasi password tidak sama';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // ====== Tombol Google (card style ala pilihan challenge) ======
                      const Text(
                        'Atau daftar dengan',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.w500,
                          color: kLightGreyText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _GoogleRegisterTile(
                        onTap: _isLoading ? null : _registerWithGoogle,
                      ),

                      const SizedBox(height: 24),

                      // "Sudah punya akun? Masuk"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.w500,
                              color: kGreyText,
                            ),
                          ),
                          InkWell(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Funnel Display',
                                fontWeight: FontWeight.w600,
                                color: kGreen,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Dengan mendaftar, kamu menyetujui ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () => showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (_) =>
                                            const TermsAndConditionsDetailPage(),
                                      ),
                              child: const Text(
                                'Syarat & Ketentuan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF196DFD),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
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

            // ====== BACK BUTTON ala ChallengePage ======
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 24,
                  ),
                  tooltip: 'Kembali',
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/summary'),
                ),
              ),
            ),

            // ====== TOMBOL DAFTAR (gradient hijau, fixed di bawah) ======
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: _isLoading ? 'Memproses...' : 'Daftar',
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

// ======================= TILE REGISTER GOOGLE ala kartu Challenge =======================
class _GoogleRegisterTile extends StatefulWidget {
  final VoidCallback? onTap;
  const _GoogleRegisterTile({this.onTap});

  @override
  State<_GoogleRegisterTile> createState() => _GoogleRegisterTileState();
}

class _GoogleRegisterTileState extends State<_GoogleRegisterTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    final Color fallbackFill = isHovered
        ? kGreen.withValues(alpha: 0.04)
        : Colors.white;

    final Color borderColor = isHovered ? kGreenLight : kMutedBorderGrey;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: fallbackFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? widget.onTap : null,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Logo Google.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Daftar dengan Google',
                  style: TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: kLightGreyText,
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

// ======================= Gradient Button (copy dari ChallengePage) =======================
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

