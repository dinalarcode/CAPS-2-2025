// lib/nameInputPage.dart
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
const kBaseGreyFill = Color(0xFFF3F3F5); // fill abu-abu lembut utk tombol default

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
      // PENTING: pushNamed agar back dari Login kembali ke NameInput
      ..onTap = () => Navigator.pushNamed(context, '/login');
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    final v = _c.text.trim().length >= 2;
    if (v != _valid) setState(() => _valid = v);
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
    _loginTap.dispose();
    _c.dispose();
    super.dispose();
  }

  void _backToTerms() => Navigator.pushReplacementNamed(context, '/terms');

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    draft.name = _c.text.trim();
    Navigator.pushReplacementNamed(context, '/target-selection');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: kLightGreyText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
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
              // Panah back: DITAMPILKAN tapi DISABLED (tidak berfungsi)
              Positioned(
                left: 8,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black38),
                  onPressed: null, // nonaktif
                  tooltip: 'Kembali',
                ),
              ),

              // Konten
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16 + 40, 24, 120),
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
                              height: 1.25,
                            ),
                            children: [
                              TextSpan(text: 'Halo, siapa '),
                              TextSpan(text: 'nama lengkap', style: TextStyle(color: kGreen)),
                              TextSpan(text: '/'),
                              TextSpan(text: 'sapaanmu', style: TextStyle(color: kGreen)),
                              TextSpan(text: '?'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

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
                        const SizedBox(height: 6),

                        TextFormField(
                          controller: _c,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'cth: John Felix Anthony Cena / John Cena',
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
                          'Nama lengkap/sapaanmu bersifat privat dan hanya terlihat oleh kamu',
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
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                                  recognizer: _loginTap, // -> pushNamed('/login')
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

              // Footer tombol
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // Kembali: base abu-abu + teks muted, hover → hijau + teks putih
                      Expanded(
                        child: HoverButton(
                          text: 'Kembali',
                          onPressed: _backToTerms,
                          borderColor: kDisabledGrey,
                          hoverColor: kGreen,
                          baseFillColor: kBaseGreyFill,
                          baseTextColor: Colors.black54,
                          enabled: true,
                          filledWhenEnabled: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Lanjut: abu-abu saat invalid, hijau saat valid
                      Expanded(
                        child: HoverButton(
                          text: 'Lanjut',
                          onPressed: _valid ? _next : () {},
                          borderColor: _valid ? kGreen : kDisabledGrey,
                          hoverColor: _valid ? kGreenLight : kDisabledGrey,
                          baseFillColor: _valid ? kGreen : kBaseGreyFill,
                          baseTextColor: _valid ? Colors.white : Colors.black54,
                          enabled: _valid,
                          filledWhenEnabled: true,
                        ),
                      ),
                    ],
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

/// HoverButton dengan kontrol warna dasar (non-hover) & state disabled.
class HoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color hoverColor;

  /// Warna dasar (non-hover)
  final Color baseFillColor;
  final Color baseTextColor;

  final bool enabled;
  final bool filledWhenEnabled;

  const HoverButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.borderColor,
    required this.hoverColor,
    required this.baseFillColor,
    required this.baseTextColor,
    this.enabled = true,
    this.filledWhenEnabled = false,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hoverActive = widget.enabled && isHovered;

    final Color fillColor = hoverActive
        ? widget.hoverColor
        : widget.baseFillColor;

    final Color borderColor =
        widget.enabled ? (hoverActive ? widget.hoverColor : widget.borderColor) : kDisabledGrey;

    final Color textColor =
        hoverActive ? Colors.white : widget.baseTextColor;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            foregroundColor: textColor,
          ),
          onPressed: widget.enabled ? widget.onPressed : null,
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
