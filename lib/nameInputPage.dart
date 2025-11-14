import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nutrilink/models/user_profile_draft.dart';
import 'package:nutrilink/_onb_helpers.dart';

// Palet
const kGreen = Color(0xFF5F9C3F);
const kGreenLight = Color(0xFF7BB662);
const kGreyText = Color(0xFF494949);
const kLightGreyText = Color(0xFF888888);
const kDisabledGrey = Color(0xFFBDBDBD);
const kBaseGreyFill = Color(0xFFF3F3F5);

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});
  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  late UserProfileDraft draft;
  final _c = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TapGestureRecognizer _loginTap;

  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _loginTap = TapGestureRecognizer()
      ..onTap = () => Navigator.pushNamed(context, '/login');
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    final ok = _c.text.trim().length >= 2;
    if (ok != _valid) setState(() => _valid = ok);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
    _c.text = draft.name ?? '';
    _valid = _c.text.trim().length >= 2;
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.dispose();
    _loginTap.dispose();
    super.dispose();
  }

  // 🔥 WAJIB: kembali ke halaman Terms
  void _backToTerms() {
    // Sederhana: pop saja untuk kembali ke halaman sebelumnya
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Fallback: jika tidak bisa pop, gunakan pushReplacementNamed
      Navigator.pushReplacementNamed(context, '/terms');
    }
  }

  // Lanjut
  void _next() {
    if (!_formKey.currentState!.validate()) return;

    draft.name = _c.text.trim();
    saveDraft(context, draft);

    next(context, '/target-selection', draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: kLightGreyText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: kGreen, width: 1.5),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // 🟩 PANAH BACK — sekarang berfungsi ke Terms
              Positioned(
                left: 8,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: _backToTerms,
                ),
              ),

              // 🟦 FORM
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 55, 24, 130),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: 'Halo, siapa '),
                              TextSpan(
                                text: 'nama lengkap',
                                style: TextStyle(color: kGreen),
                              ),
                              TextSpan(text: '/'),
                              TextSpan(
                                text: 'sapaanmu',
                                style: TextStyle(color: kGreen),
                              ),
                              TextSpan(text: '?'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Kita akan menggunakannya untuk mempersonalisasikan aplikasi NutriLink untuk kamu.',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kGreyText,
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Masukkan nama lengkap/sapaan',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: kLightGreyText,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _c,
                          decoration: const InputDecoration(
                            hintText: 'cth: John Felix Cena / John Cena',
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Nama tidak boleh kosong';
                            if (s.length < 2) return 'Nama terlalu pendek';
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (_valid) _next();
                          },
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Nama ini hanya terlihat oleh kamu',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: kGreyText,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 12,
                                color: kGreyText,
                              ),
                              children: [
                                const TextSpan(text: 'Sudah punya akun? '),
                                TextSpan(
                                  text: 'Masuk',
                                  style: const TextStyle(
                                    color: kGreen,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: _loginTap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🟨 TOMBOL LANJUT
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GradientButton(
                    text: 'Lanjut',
                    enabled: _valid,
                    onPressed: _next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🌈 Gradient Button ala WelcomePage
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
