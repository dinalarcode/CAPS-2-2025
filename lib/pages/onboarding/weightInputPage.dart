// lib/weightInputPage.dart

import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'onboardingHelpers.dart';
import '../../models/userProfileDraft.dart';

class WeightInputPage extends StatefulWidget {
  const WeightInputPage({super.key});

  @override
  State<WeightInputPage> createState() => _WeightInputPageState();
}

class _WeightInputPageState extends State<WeightInputPage> {
  late UserProfileDraft draft;
  final TextEditingController _c = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    _c.text = (draft.weightKg != null && draft.weightKg! > 0)
        ? draft.weightKg!.toStringAsFixed(
            draft.weightKg! % 1 == 0 ? 0 : 1,
          )
        : '';

    _c.removeListener(_onTextChanged);
    _c.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final parsed =
        double.tryParse(_c.text.replaceAll(',', '.').trim());
    setState(() {
      draft.weightKg = parsed;
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onTextChanged);
    _c.dispose();
    super.dispose();
  }

  // ====== ALERT (SnackBar) ======
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ====== LOGIKA NEXT / BACK ======
  void _next() {
    final rawWeight = _c.text.replaceAll(',', '.').trim();
    draft.weightKg = double.tryParse(rawWeight);

    if (draft.weightKg == null) {
      _toast('Berat badan tidak boleh kosong atau tidak valid.');
      return;
    }

    const double minWeight = 20.0;
    const double maxWeight = 200.0;

    if (draft.weightKg! < minWeight ||
        draft.weightKg! > maxWeight) {
      _toast(
        'Berat badan tidak wajar. Isi antara $minWeight kg sampai $maxWeight kg.',
      );
      return;
    }

    saveDraft(context, draft);
    next(context, '/target-weight', draft);
  }

  void _back() {
    back(context, draft);
  }

  // ====== DECOR INPUT (border sama kayak style kartu) ======
  BoxDecoration _inputBoxDecoration({required bool isValid}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: AppRadius.smallRadius,
      border: Border.all(
        color: isValid ? AppColors.green : AppColors.mutedBorderGrey,
        width: 1.4,
      ),
      boxShadow: AppShadows.small,
    );
  }
  
  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final bool isInputValid = draft.weightKg != null &&
        draft.weightKg! >= 20 &&
        draft.weightKg! <= 200;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ====== KONTEN UTAMA ======
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul ala ChallengePage
                    RichText(
                      text: const TextSpan(
                        style: AppTextStyles.h2,
                        children: [
                          TextSpan(text: 'Berapa '),
                          TextSpan(
                            text: 'berat badanmu',
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

                    // ====== INPUT BERAT (card style) ======
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: _inputBoxDecoration(
                              isValid: isInputValid,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Center(
                              child: TextFormField(
                                controller: _c,
                                keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                  decimal: true,
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Funnel Display',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'cth: 65.5',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Funnel Display',
                                    color: AppColors.lightGreyText
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onFieldSubmitted: (_) => _next(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'kg',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ====== INFO BOX ala ChallengePage ======
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: AppRadius.largeRadius,
                        border: Border.all(
                          color: AppColors.mutedBorderGrey,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000)
                                .withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.greyText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Berat badanmu berperan penting dalam menghitung Indeks Massa Tubuh (IMT) Anda dan kebutuhan nutrisi harian.',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.greyText,
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

            // ====== BACK BUTTON bulat ala ChallengePage ======
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

            // ====== TOMBOL LANJUT (gradient hijau, sama seperti ChallengePage) ======
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: 'Lanjut',
                  enabled: isInputValid, // abu-abu muted jika tidak valid
                  onPressed: _next, // tetap bisa diklik, validasi di _next
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Gradient Button (copas dari ChallengePage) =======================
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
            color:
                widget.enabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.enabled ? AppColors.green : AppColors.disabledGrey,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF000000).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: TextButton(
            onPressed: widget.onPressed, // selalu bisa diklik
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
                  color:
                      widget.enabled ? AppColors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
