import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/models/userProfileDraft.dart';
import 'package:nutrilink/pages/onboarding/onboardingHelpers.dart';

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

  // 👉 Back: balik ke /terms (aman, nggak tergantung stack)
  void _back() {
    Navigator.pushReplacementNamed(
      context,
      '/terms',
      arguments: draft,
    );
  }

  // 👉 Lanjut ke Target Selection
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
        hintStyle: TextStyle(color: AppColors.lightGreyText),
        border: OutlineInputBorder(borderRadius: AppRadius.mediumRadius),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.green, width: 1.5),
          borderRadius: AppRadius.mediumRadius,
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
              // 🟦 FORM (letakkan duluan)
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 130),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: AppTextStyles.h2,
                            children: [
                              TextSpan(text: 'Halo, siapa '),
                              TextSpan(
                                text: 'nama lengkap',
                                style: TextStyle(color: AppColors.green),
                              ),
                              TextSpan(text: '/'),
                              TextSpan(
                                text: 'sapaanmu',
                                style: TextStyle(color: AppColors.green),
                              ),
                              TextSpan(text: '?'),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        const Text(
                          'Kita akan menggunakannya untuk mempersonalisasikan aplikasi NutriLink untuk kamu.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        Text(
                          'Masukkan nama lengkap/sapaan',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.lightGreyText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

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
                        const SizedBox(height: AppSpacing.md),

                        const Text(
                          'Nama ini hanya terlihat oleh kamu',
                          style: AppTextStyles.caption,
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySmall,
                              children: [
                                const TextSpan(text: 'Sudah punya akun? '),
                                TextSpan(
                                  text: 'Masuk',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.green,
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

              // 🟨 TOMBOL LANJUT (gradient hijau)
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

              // 🔙 PANAH BACK — DITARUH PALING AKHIR BIAR DI ATAS SEMUA
              Positioned(
                left: 12,
                top: 10,
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
                    onPressed: _back,
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
                ? const [AppColors.green, AppColors.greenLight]
                : const [AppColors.greenLight, AppColors.green],
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
            color: widget.enabled ? null : AppColors.white.withValues(alpha: 0.04),
            borderRadius: AppRadius.xxlargeRadius,
            border: Border.all(
              color: widget.enabled ? AppColors.green : AppColors.disabledGrey,
              width: 2,
            ),
            boxShadow: widget.enabled ? AppShadows.button : null,
          ),
          child: TextButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.xxlargeRadius,
              ),
            ),
            child: Center(
              child: Text(
                widget.text,
                style: AppTextStyles.button.copyWith(
                  fontSize: 15,
                  color: widget.enabled ? AppColors.white : AppColors.black.withValues(alpha: 0.54),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
