// lib/sexPage.dart

import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'onboardingHelpers.dart';
import '../../models/userProfileDraft.dart';

class SexPage extends StatefulWidget {
  const SexPage({super.key});

  @override
  State<SexPage> createState() => _SexPageState();
}

class _SexPageState extends State<SexPage> {
  late UserProfileDraft draft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
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
    if (draft.sex == null) {
      _toast('Pilih jenis kelamin terlebih dahulu.');
      return;
    }

    saveDraft(context, draft);
    next(context, '/daily-activity', draft);
  }

  void _back() {
    back(context, draft);
  }

  // ====== DECOR untuk kartu pilihan ======
  BoxDecoration _cardDecoration({required bool isSelected}) {
    return BoxDecoration(
      gradient: isSelected ? AppColors.primaryGradient : null,
      color: isSelected ? null : AppColors.white,
      borderRadius: AppRadius.smallRadius,
      border: Border.all(
        color: isSelected ? AppColors.green : AppColors.mutedBorderGrey,
        width: 1.4,
      ),
      boxShadow: AppShadows.small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInputValid = draft.sex != null;

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
                          TextSpan(text: 'Apa '),
                          TextSpan(
                            text: 'jenis kelaminmu',
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

                    // ====== PILIHAN LAKI-LAKI ======
                    InkWell(
                      onTap: () {
                        setState(() {
                          draft.sex = 'Laki-laki';
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: _cardDecoration(
                          isSelected: draft.sex == 'Laki-laki',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/images/avatars/Male Avatar.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Laki - Laki',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: draft.sex == 'Laki-laki'
                                    ? AppColors.white
                                    : AppColors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ====== PILIHAN PEREMPUAN ======
                    InkWell(
                      onTap: () {
                        setState(() {
                          draft.sex = 'Perempuan';
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: _cardDecoration(
                          isSelected: draft.sex == 'Perempuan',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image.asset(
                                'assets/images/avatars/Female Avatar.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Perempuan',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: draft.sex == 'Perempuan'
                                    ? AppColors.white
                                    : AppColors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // ====== INFO BOX ala ChallengePage ======
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: AppRadius.largeRadius,
                        border: Border.all(
                          color: AppColors.mutedBorderGrey,
                          width: 1,
                        ),
                        boxShadow: AppShadows.small,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.greyText,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Jenis kelamin kamu berpengaruh terhadap berapa banyak energi yang dibutuhkan oleh tubuh setiap harinya.',
                              style: AppTextStyles.caption,
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
            borderRadius: AppRadius.xxlargeRadius,
            border: Border.all(
              color: widget.enabled ? AppColors.green : AppColors.disabledGrey,
              width: 2,
            ),
            boxShadow: widget.enabled ? AppShadows.button : null,
          ),
          child: TextButton(
            onPressed: widget.onPressed, // selalu bisa diklik
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
                  color:
                      widget.enabled ? AppColors.white : AppColors.black.withValues(alpha: 0.54),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
