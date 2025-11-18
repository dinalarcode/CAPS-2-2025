// lib/dailyActivityPage.dart

import 'package:flutter/material.dart';
import '../_onb_helpers.dart';
import '../models/user_profile_draft.dart';

// ====== Palet warna konsisten dengan ChallengePage ======
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill =
    const Color(0xFF000000).withValues(alpha: 0.04);

class DailyActivityPage extends StatefulWidget {
  const DailyActivityPage({super.key});

  @override
  State<DailyActivityPage> createState() => _DailyActivityPageState();
}

class _DailyActivityPageState extends State<DailyActivityPage> {
  late UserProfileDraft draft;

  // Mendefinisikan opsi lengkap dengan label panjang dan nilai (value) yang digunakan.
  static const List<Map<String, dynamic>> _activityOptions = [
    {
      'label': 'Sangat Rendah (Sedentary lifestyle)',
      'value': 'sedentary',
      'icon': Icons.self_improvement,
    },
    {
      'label': 'Rendah (1-3x Olahraga per minggu)',
      'value': 'lightly_active',
      'icon': Icons.directions_walk,
    },
    {
      'label': 'Sedang (4-5x Olahraga per Minggu)',
      'value': 'moderately_active',
      'icon': Icons.directions_run,
    },
    {
      'label': 'Tinggi (Olahraga tiap hari/Olahraga intens 3-4x per minggu)',
      'value': 'very_active',
      'icon': Icons.sports_gymnastics,
    },
    {
      'label': 'Sangat Tinggi (Olahraga intens 6-7x per minggu)',
      'value': 'extremely_active_1',
      'icon': Icons.fitness_center,
    },
    {
      'label': 'Sangat Sangat Tinggi (Olahraga intens tiap hari/pekerjaan fisik)',
      'value': 'extremely_active_2',
      'icon': Icons.construction,
    },
  ];

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
    if (draft.activityLevel == null) {
      _toast('Pilih tingkat aktivitas harian terlebih dahulu.');
      return;
    }

    saveDraft(context, draft);
    next(context, '/allergy', draft);
  }

  void _back() {
    back(context, draft);
  }

  // ====== DECOR untuk kartu pilihan ======
  BoxDecoration _cardDecoration({required bool isSelected}) {
    return BoxDecoration(
      gradient: isSelected
          ? const LinearGradient(
              colors: [kGreenLight, kGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: isSelected ? null : Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected ? kGreen : kMutedBorderGrey,
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isInputValid = draft.activityLevel != null;

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
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(text: 'Seberapa tinggi tingkat '),
                          TextSpan(
                            text: 'aktivitas harianmu',
                            style: TextStyle(color: kGreen),
                          ),
                          TextSpan(text: '?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tingkat aktivitasmu akan membantu kita menentukan berapa banyaknya kalori yang dibutuhkan tiap hari.',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ====== LIST PILIHAN AKTIVITAS ======
                    ..._activityOptions.map((option) {
                      final isSelected = draft.activityLevel == option['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              draft.activityLevel = option['value'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 16.0,
                            ),
                            decoration: _cardDecoration(
                              isSelected: isSelected,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option['icon'] as IconData,
                                  color: isSelected ? Colors.white : kGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Funnel Display',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // ====== INFO BOX ala ChallengePage (di bawah) ======
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kMutedBorderGrey,
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
                            color: kGreyText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Jika kamu tidak yakin opsi mana untuk dipilih, lebih baik pilih opsi paling rendah untuk menghindari kebutuhan kalori yang berlebihan.',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: kGreyText,
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: 0.1),
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
            color:
                widget.enabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.enabled ? kGreen : kDisabledGrey,
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
                      widget.enabled ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}