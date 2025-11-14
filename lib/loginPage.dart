import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Asumsi path import sudah benar
import 'package:nutrilink/termsAndConditionsDetailPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Brand Colors (Warna-warna dari skema NutriLink)
  static const Color green = Color(0xFF5F9C3F);
  static const Color greenLight = Color(0xFF7BB662);
  static const Color gray = Color(0xFFBDBDBD);

  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _focusPass = FocusNode();

  bool _obscure = true;
  bool _loading = false; // dipakai untuk semua proses login

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _focusPass.dispose();
    super.dispose();
  }

  // --- Email Login ---
  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final ok = await _ensureAppCheckToken();
      if (!ok) {
        throw Exception('Verifikasi keamanan (App Check) belum siap. Coba lagi.');
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passC.text,
      );

      if (!mounted) return;
      // BERHASIL LOGIN → arahkan ke /home
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

  // --- Google Login (tanpa fetchSignInMethodsForEmail) ---
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      UserCredential cred;

      if (kIsWeb) {
        // WEB: popup Google langsung
        final provider = GoogleAuthProvider();
        cred = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // ANDROID / IOS: pakai google_sign_in
        final googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? gUser = await googleSignIn.signIn();
        if (gUser == null) {
          // user batal memilih akun
          return;
        }

        final gAuth = await gUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: gAuth.accessToken,
          idToken: gAuth.idToken,
        );

        cred = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final isNewUser = cred.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Tidak mengizinkan akun baru via Google
        final user = cred.user;
        try {
          await user?.delete();
        } catch (_) {
          // kalau delete gagal (misal permission), minimal logout saja
        }
        await FirebaseAuth.instance.signOut();
        _toast(
          'Akun Google ini belum terdaftar. Silakan daftar terlebih dahulu.',
        );
        return;
      }

      if (!mounted) return;
      // BERHASIL LOGIN GOOGLE → arahkan ke /home
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

  // --- Forgot Password ---
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

  // --- UI Helpers ---
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontFamily: 'Funnel Display',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gray, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: greenLight, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // --- Widget Build ---
  @override
  Widget build(BuildContext context) {
    final softShadow = [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.12),
        blurRadius: 12,
        offset: const Offset(0, 6),
      )
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Masuk Akun',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 8),

                    // Illustration
                    LayoutBuilder(
                      builder: (context, _) {
                        final w = MediaQuery.of(context).size.width;
                        final h = (w.clamp(320.0, 480.0)) * 0.42;

                        return Transform.translate(
                          offset: const Offset(0, -10),
                          child: SizedBox(
                            height: h,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/Login Illustration.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: _LoginPageState.gray,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Headline
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Halo, silahkan masuk dengan'),
                          TextSpan(
                            text: ' akunmu.',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    // Info App Check
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _appCheckReady
                              ? Icons.verified_user
                              : Icons.shield_outlined,
                          color: _appCheckReady
                              ? Colors.green
                              : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _appCheckReady
                                ? 'Perlindungan aktif (App Check).'
                                : (_appCheckHint ??
                                    'Mengaktifkan perlindungan…'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Email Input
                    const Text(
                      'Masukkan email kamu',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Funnel Display',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
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
                      decoration: _inputDecoration('Email'),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(s)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Input
                    const Text(
                      'Masukkan password kamu',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Funnel Display',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
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
                          icon: Icon(_obscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password wajib diisi'
                          : null,
                    ),

                    // Lupa password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text(
                          'Lupa password?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            color: green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tombol login email (gradient hijau on hover/press)
                    _ActionButton(
                      text: _loading ? 'Memproses…' : 'Masuk',
                      onPressed: _loading ? null : _loginWithEmail,
                      idleFillColor: Colors.white,
                      idleBorderColor: gray,
                      idleTextColor: Colors.black,
                      activeColor: greenLight,
                      activeTextColor: Colors.white,
                      activeGradientColors: const [greenLight, green],
                      boxShadow: softShadow,
                      busy: _loading,
                    ),

                    const SizedBox(height: 14),

                    // Tombol login dengan Google (gradient hijau on hover/press)
                    _ActionButton(
                      text: _loading ? 'Memproses…' : 'Masuk dengan Google',
                      onPressed: _loading ? null : _signInWithGoogle,
                      idleFillColor: Colors.white,
                      idleBorderColor: gray,
                      idleTextColor: Colors.black,
                      activeColor: greenLight,
                      activeTextColor: Colors.white,
                      activeGradientColors: const [greenLight, green],
                      icon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Image.asset(
                          'assets/images/Logo Google.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                      ),
                      boxShadow: softShadow,
                      busy: _loading,
                    ),

                    const SizedBox(height: 20),

                    // “Belum punya akun? Daftar”
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Funnel Display',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF494949),
                          ),
                        ),
                        InkWell(
                          onTap: _loading
                              ? null
                              : () => Navigator.pushNamed(context, '/terms'),
                          child: const Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.w600,
                              color: green,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    const Divider(height: 1),

                    const SizedBox(height: 12),
                    // T&C
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Dengan masuk, Anda menyetujui ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          InkWell(
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
                                color: Color(0xFF196DFD),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol interaktif (hover/press) dengan gradient hijau dan loader kecil saat busy.
class _ActionButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color idleBorderColor;
  final Color idleFillColor;
  final Color idleTextColor;
  final Color activeColor;
  final Color activeTextColor;
  final List<Color>? activeGradientColors;
  final Widget? icon;
  final List<BoxShadow>? boxShadow;
  final bool busy;

  const _ActionButton({
    required this.text,
    required this.onPressed,
    this.idleBorderColor = const Color(0xFFBDBDBD),
    this.idleFillColor = Colors.white,
    this.idleTextColor = Colors.black,
    this.activeColor = const Color(0xFF7BB662),
    this.activeTextColor = Colors.white,
    this.activeGradientColors,
    this.icon,
    this.boxShadow,
    this.busy = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    final enabled = widget.onPressed != null && !widget.busy;

    final bool useGradient =
        active && enabled && widget.activeGradientColors != null;

    final Color fill =
        (active && enabled) ? widget.activeColor : widget.idleFillColor;
    final Color border = useGradient
        ? widget.activeGradientColors!.first
        : ((active && enabled) ? widget.activeColor : widget.idleBorderColor);
    final Color textColor =
        (active && enabled) ? widget.activeTextColor : widget.idleTextColor;

    final double opacity = enabled ? 1.0 : 0.5;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onHighlightChanged: (v) => setState(() => _pressed = v),
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: useGradient ? null : fill.withValues(alpha: opacity),
            gradient: useGradient
                ? LinearGradient(
                    colors: widget.activeGradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 2),
            boxShadow: widget.boxShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
