// lib/loginPage.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Asumsi path import sudah benar
import 'package:nutrilink/termsAndConditionsDetailPage.dart';

// ====== Palet warna konsisten dengan ChallengePage ======
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill = const Color(0xFF000000).withValues(alpha: 0.04);

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
      hintStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontFamily: 'Funnel Display',
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  // ================== HELPER: HANDLE UNVERIFIED EMAIL ==================
  Future<void> _handleUnverifiedEmail(User user) async {
    if (!mounted) return;
    final shouldResend = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: kGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Email Belum Terverifikasi',
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                'Email kamu belum terverifikasi. Cek inbox/spam untuk email verifikasi.',
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kGreyText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah kamu ingin mengirim ulang email verifikasi?',
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: const BorderSide(
                            color: kMutedBorderGrey,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Tidak',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kGreyText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kGreenLight, kGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Kirim Ulang',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: 'Silakan '),
                            TextSpan(
                              text: 'masuk ke akun NutriLink',
                              style: TextStyle(color: kGreen),
                            ),
                            TextSpan(text: ' kamu.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Masukkan email dan password yang sudah kamu daftarkan.',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kGreyText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Ilustrasi (opsional)
                      Center(
                        child: Image.asset(
                          'assets/images/Login Illustration.png',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),

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
                              color: kMutedBorderGrey,
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
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              color: kGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ====== Tombol Google (card style ala pilihan challenge) ======
                      const Text(
                        'Atau masuk dengan',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.w500,
                          color: kLightGreyText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _GoogleLoginTile(
                        onTap: _loading ? null : _signInWithGoogle,
                      ),

                      const SizedBox(height: 24),

                      // "Belum punya akun? Daftar"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.w500,
                              color: kGreyText,
                            ),
                          ),
                          InkWell(
                            onTap: _loading
                                ? null
                                : () => Navigator.pushNamed(
                                      context,
                                      '/terms',
                                    ),
                            child: const Text(
                              'Daftar',
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
                      const SizedBox(height: 16),

                      // ============ TEKS PERSETUJUAN (DI LUAR TOMBOL) ============
                      // "Dengan masuk, kamu menyetujui Syarat & Ketentuan"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Dengan masuk, kamu menyetujui ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.w500,
                              color: kGreyText,
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
                              child: const Text(
                                'Syarat & Ketentuan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Funnel Display',
                                  fontWeight: FontWeight.w600,
                                  color: kGreen,
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ============ TOMBOL MASUK ============
                      Center(
                        child: GradientButton(
                          text: _loading ? 'Memproses...' : 'Masuk',
                          enabled: !_loading &&
                              _emailC.text.trim().isNotEmpty &&
                              _passC.text.isNotEmpty,
                          onPressed: _loginWithEmail,
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
        isHovered ? kGreen.withValues(alpha: 0.04) : Colors.white;

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
                  'Masuk dengan Google',
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
                  fontFamily: 'Funnel Display',
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
