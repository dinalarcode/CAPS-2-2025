// lib/registerPage.dart
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/pages/onboarding/onboardingHelpers.dart';
import 'package:nutrilink/models/userProfileDraft.dart';
import 'package:nutrilink/pages/auth/termsAndConditionsDetailPage.dart';

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
      hintStyle: AppTextStyles.bodySmall.copyWith(
        color: const Color(0xFFB0B0B0),
        fontSize: 13,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.mutedBorderGrey,
          width: 1.4,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.greenLight,
          width: 1.6,
        ),
      ),
      filled: true,
      fillColor: AppColors.white,
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
    String profilePicture = 'assets/images/avatars/Male Avatar.png'; // default
    if (draft.sex != null) {
      if (draft.sex!.toLowerCase().contains('perempuan') || 
          draft.sex!.toLowerCase().contains('wanita') ||
          draft.sex!.toLowerCase().contains('female')) {
        profilePicture = 'assets/images/avatars/Female Avatar.png';
      } else if (draft.sex!.toLowerCase().contains('laki') || 
                 draft.sex!.toLowerCase().contains('pria') ||
                 draft.sex!.toLowerCase().contains('male')) {
        profilePicture = 'assets/images/avatars/Male Avatar.png';
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
                        text: TextSpan(
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 22,
                          ),
                          children: [
                            const TextSpan(text: 'Buat akun '),
                            TextSpan(
                              text: 'NutriLink',
                              style: TextStyle(color: AppColors.green),
                            ),
                            const TextSpan(text: ' kamu.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Dengan akun, progres dan pengaturan makananmu akan tersimpan rapi di satu tempat.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      if (draft.name != null && draft.name!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Text(
                            'Halo, ${draft.name}! Daftarkan email untuk menghubungkan profilmu.',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightGreyText,
                            ),
                          ),
                        ),

                      Text(
                        'Email',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Password',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                              color: AppColors.mutedBorderGrey,
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
                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'Konfirmasi Password',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                              color: AppColors.mutedBorderGrey,
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
                      const SizedBox(height: AppSpacing.sm),

                      // ====== Tombol Google (card style ala pilihan challenge) ======
                      Text(
                        'Atau daftar dengan',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GoogleRegisterTile(
                        onTap: _isLoading ? null : _registerWithGoogle,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // "Sudah punya akun? Masuk"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyText,
                            ),
                          ),
                          InkWell(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    ),
                            child: Text(
                              'Masuk',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.green,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),

                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Dengan mendaftar, kamu menyetujui ',
                              style: AppTextStyles.bodySmall,
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
                              child: Text(
                                'Syarat & Ketentuan',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF196DFD),
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
              left: AppSpacing.md,
              top: AppSpacing.sm,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.small,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.black87,
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
              bottom: AppSpacing.lg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _isLoading
                    ? AppWidgets.loading()
                    : SizedBox(
                        width: double.infinity,
                        child: AppWidgets.gradientButton(
                          text: 'Daftar',
                          onPressed: _registerWithEmail,
                          enabled: !_isLoading,
                        ),
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
        ? AppColors.green.withValues(alpha: 0.04)
        : AppColors.white;

    final Color borderColor = isHovered ? AppColors.greenLight : AppColors.mutedBorderGrey;

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
          boxShadow: AppShadows.small,
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
                  'assets/images/logos/Logo Google.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Daftar dengan Google',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: AppColors.lightGreyText,
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


Future<void> generateMenuForUser(String uid, Map<String, dynamic> profile) async {
  final db = FirebaseFirestore.instance;

  // Ambil data penting (untuk digunakan di versi mendatang)
  // ignore: unused_local_variable
  final int eatFreq = profile['eatFrequency'] ?? 3;
  // ignore: unused_local_variable
  final String? wake = profile['wakeTime'];
  // ignore: unused_local_variable
  final String? sleep = profile['sleepTime'];
  // ignore: unused_local_variable
  final String? goal = profile['healthGoal'];
  // ignore: unused_local_variable
  final List<dynamic>? allergies = profile['allergies'];
  // ignore: unused_local_variable
  final List<dynamic>? challenges = profile['challenges'];

  // List dummy menu, nanti bisa kamu ganti ke API kamu
  final meals = {
    'breakfast': [
      'Oatmeal + buah', 'Roti gandum + telur', 'Yogurt + granola'
    ],
    'lunch': [
      'Nasi merah + ayam', 'Salad sayur + tuna', 'Kentang + dada ayam'
    ],
    'dinner': [
      'Sup sayur', 'Ikan kukus + sayur', 'Tahu tempe + sayur'
    ]
  };

  Random r = Random();

  final batch = db.batch();
  final scheduleRef = db.collection('users').doc(uid).collection('schedule');

  for (int i = 1; i <= 7; i++) {
    final data = {
      'day': i,
      'breakfast': meals['breakfast']?[r.nextInt(meals['breakfast']!.length)],
      'lunch': meals['lunch']?[r.nextInt(meals['lunch']!.length)],
      'dinner': meals['dinner']?[r.nextInt(meals['dinner']!.length)],
      'generatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(scheduleRef.doc('day_$i'), data);
  }

  await batch.commit();
  debugPrint("✅ Jadwal makanan untuk $uid berhasil dibuat!");
}
