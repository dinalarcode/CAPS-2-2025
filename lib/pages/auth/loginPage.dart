// lib/loginPage.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/pages/auth/termsAndConditionsDetailPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _focusPass = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes untuk update button state
    _emailC.addListener(() => setState(() {}));
    _passC.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _focusPass.dispose();
    super.dispose();
  }

  // --- Helper SnackBar ---
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, 
        vertical: AppSpacing.md,
      ),
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

  // ================== HELPER: HANDLE UNVERIFIED EMAIL ==================
  Future<void> _handleUnverifiedEmail(User user) async {
    if (!mounted) return;
    final shouldResend = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.largeRadius,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: AppDecorations.card(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                'Email Belum Terverifikasi',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Content
              Text(
                'Email kamu belum terverifikasi. Cek inbox/spam untuk email verifikasi.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.greyText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Apakah kamu ingin mengirim ulang email verifikasi?',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.xxlargeRadius,
                          side: const BorderSide(
                            color: AppColors.mutedBorderGrey,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        'Tidak',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      decoration: AppDecorations.gradientButton,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.xxlargeRadius,
                          ),
                        ),
                        child: Text(
                          'Kirim Ulang',
                          style: AppTextStyles.buttonSmall,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldResend == true) {
      try {
        await user.sendEmailVerification();
        if (mounted) {
          _toast('Email verifikasi telah dikirim ulang ke ${user.email}');
        }
      } catch (e) {
        if (mounted) {
          _toast('Gagal mengirim email verifikasi: $e');
        }
      }
    }

    await FirebaseAuth.instance.signOut();
  }

  // ================== LOGIN DENGAN EMAIL ==================
  Future<void> _loginWithEmail() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passC.text,
      );

      final user = cred.user;
      if (user == null) {
        _toast('Terjadi kesalahan. User tidak terbentuk.');
        return;
      }

      // Cek apakah akun terdaftar di Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        _toast('Akun belum terdaftar. Silakan daftar terlebih dahulu.');
        return;
      }

      // Cek verifikasi email dari Firebase Auth
      if (!user.emailVerified) {
        await _handleUnverifiedEmail(user);
        return;
      }

      // Cek verifikasi email dari Firestore (emailVerifiedByApp)
      final emailVerifiedByApp = userDoc.data()?['emailVerifiedByApp'] ?? false;

      // Jika Firebase Auth sudah verified tapi Firestore belum, update Firestore LALU login
      if (!emailVerifiedByApp) {
        // Update Firestore karena user sudah klik link verifikasi
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'emailVerifiedByApp': true});

        debugPrint('✅ Email verified! Updated emailVerifiedByApp to true');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'Format email tidak valid.',
        'user-disabled' => 'Akun dinonaktifkan.',
        'user-not-found' =>
          'Akun belum terdaftar. Silakan daftar terlebih dahulu.',
        'wrong-password' => 'Password salah.',
        _ => 'Gagal login: ${e.message}',
      };
      _toast(msg);
    } catch (e) {
      _toast('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================== LOGIN DENGAN GOOGLE ==================
  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      UserCredential cred;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        cred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? gUser = await googleSignIn.signIn();
        if (gUser == null) {
          // user batal pilih akun
          setState(() => _loading = false);
          return;
        }

        final gAuth = await gUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        cred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final user = cred.user;
      if (user == null) {
        _toast('Gagal mendapatkan informasi akun Google.');
        return;
      }

      // Cek apakah akun sudah terdaftar di Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Akun Google belum terdaftar, hapus dan minta daftar dulu
        try {
          await user.delete();
        } catch (_) {}
        await FirebaseAuth.instance.signOut();
        _toast(
          'Akun Google ini belum terdaftar. Silakan daftar terlebih dahulu.',
        );
        return;
      }

      // Cek verifikasi email dari Firebase Auth
      if (!user.emailVerified) {
        await _handleUnverifiedEmail(user);
        return;
      }

      // Cek verifikasi email dari Firestore (emailVerifiedByApp)
      final emailVerifiedByApp = userDoc.data()?['emailVerifiedByApp'] ?? false;

      // Jika Firebase Auth sudah verified tapi Firestore belum, update Firestore LALU login
      if (!emailVerifiedByApp) {
        // Update Firestore karena user sudah klik link verifikasi
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'emailVerifiedByApp': true});

        debugPrint('✅ Email verified! Updated emailVerifiedByApp to true');
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'account-exists-with-different-credential' =>
          'Email ini sudah terhubung dengan metode login lain.',
        'invalid-credential' => 'Kredensial Google tidak valid.',
        'operation-not-allowed' =>
          'Login dengan Google belum diaktifkan di Firebase.',
        _ => 'Gagal login dengan Google: ${e.message}',
      };
      _toast(msg);
    } catch (e) {
      _toast('Gagal login dengan Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================== FORGOT PASSWORD ==================
  Future<void> _forgotPassword() async {
    final email = _emailC.text.trim();
    if (email.isEmpty) {
      _toast('Masukkan email dulu untuk reset password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('Tautan reset password telah dikirim ke email kamu.');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'Format email tidak valid.',
        'user-not-found' => 'Email tidak terdaftar. Daftar terlebih dahulu.',
        _ => 'Gagal mengirim email reset: ${e.message}',
      };
      _toast(msg);
    } catch (e) {
      _toast('Gagal mengirim email reset: $e');
    }
  }

  // ================== BUILD ==================
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
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
                            const TextSpan(text: 'Silakan '),
                            TextSpan(
                              text: 'masuk ke akun NutriLink',
                              style: TextStyle(color: AppColors.green),
                            ),
                            const TextSpan(text: ' kamu.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Masukkan email dan password yang sudah kamu daftarkan.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Ilustrasi (opsional)
                      Center(
                        child: Image.asset(
                          'assets/images/illustrations/Login Illustration.png',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),

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
                        onFieldSubmitted: (_) => _focusPass.requestFocus(),
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
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'Password',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _passC,
                        focusNode: _focusPass,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _loginWithEmail(),
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: _inputDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.mutedBorderGrey,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password wajib diisi'
                            : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _forgotPassword,
                          child: Text(
                            'Lupa password?',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // ====== Tombol Google (card style ala pilihan challenge) ======
                      Text(
                        'Atau masuk dengan',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GoogleLoginTile(
                        onTap: _loading ? null : _signInWithGoogle,
                      ),

                      const SizedBox(height: 24),

                      // "Belum punya akun? Daftar"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyText,
                            ),
                          ),
                          InkWell(
                            onTap: _loading
                                ? null
                                : () => Navigator.pushNamed(
                                      context,
                                      '/terms',
                                    ),
                            child: Text(
                              'Daftar',
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
                      const SizedBox(height: 16),

                      // ============ TEKS PERSETUJUAN (DI LUAR TOMBOL) ============
                      // "Dengan masuk, kamu menyetujui Syarat & Ketentuan"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Dengan masuk, kamu menyetujui ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.greyText,
                            ),
                          ),
                          Center(
                            child: InkWell(
                              onTap: _loading
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
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ============ TOMBOL MASUK ============
                      if (_loading)
                        AppWidgets.loading()
                      else
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            child: AppWidgets.gradientButton(
                              text: 'Masuk',
                              onPressed: _loginWithEmail,
                              enabled: _emailC.text.trim().isNotEmpty &&
                                  _passC.text.isNotEmpty,
                            ),
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
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= TILE LOGIN GOOGLE ala kartu Challenge =======================
class _GoogleLoginTile extends StatefulWidget {
  final VoidCallback? onTap;
  const _GoogleLoginTile({this.onTap});

  @override
  State<_GoogleLoginTile> createState() => _GoogleLoginTileState();
}

class _GoogleLoginTileState extends State<_GoogleLoginTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    final Color fallbackFill =
        isHovered ? AppColors.green.withValues(alpha: 0.04) : AppColors.white;

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
                  'Masuk dengan Google',
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


