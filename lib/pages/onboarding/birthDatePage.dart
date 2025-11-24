// lib/birthDatePage.dart

import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'onboardingHelpers.dart';
import '../../models/userProfileDraft.dart';

class BirthDatePage extends StatefulWidget {
  const BirthDatePage({super.key});

  @override
  State<BirthDatePage> createState() => _BirthDatePageState();
}

class _BirthDatePageState extends State<BirthDatePage> {
  late UserProfileDraft draft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
  }

  // Tanggal default adalah hari ini
  DateTime _initialDate(DateTime now) =>
      draft.birthDate ?? now;

  // --- Fungsi Hitung Umur ---
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    // Mengurangi 1 jika ulang tahun belum tiba tahun ini
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // --- Konversi ke Bahasa Indonesia ---
  String _formatDateIndonesia(DateTime date) {
    const hariIndonesia = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const bulanIndonesia = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final hari = hariIndonesia[date.weekday - 1];
    final tanggal = date.day;
    final bulan = bulanIndonesia[date.month - 1];
    final tahun = date.year;
    
    return '$hari, $tanggal $bulan $tahun';
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

  // --- Fungsi untuk membuka Date Picker ---
  Future<void> _selectDate() async {
    final now = DateTime.now();
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDate(now),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
      locale: const Locale('id', 'ID'), // Format Indonesia DD/MM/YYYY
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.green,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        draft.birthDate = pickedDate;
      });
    }
  }

  // ====== LOGIKA NEXT / BACK ======
  void _next() {
    if (draft.birthDate == null) {
      _toast('Pilih tanggal lahir terlebih dahulu.');
      return;
    }

    saveDraft(context, draft);
    next(context, '/sex', draft);
  }

  void _back() {
    back(context, draft);
  }

  // ====== DECOR INPUT (border sama kayak style kartu) ======
  BoxDecoration _inputBoxDecoration({required bool isValid}) {
    return BoxDecoration(
      gradient: isValid ? AppColors.primaryGradient : null,
      color: isValid ? null : AppColors.white,
      borderRadius: AppRadius.smallRadius,
      border: Border.all(
        color: isValid ? AppColors.green : AppColors.mutedBorderGrey,
        width: 1.4,
      ),
      boxShadow: AppShadows.small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInputValid = draft.birthDate != null;
    
    final String dateDisplay = draft.birthDate != null
        ? _formatDateIndonesia(draft.birthDate!)
        : 'Pilih Tanggal Lahir';
    
    final int age =
        draft.birthDate != null ? _calculateAge(draft.birthDate!) : 0;

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
                          TextSpan(text: 'Kapan '),
                          TextSpan(
                            text: 'tanggal lahirmu',
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
                    const SizedBox(height: 24),

                    // ====== INPUT DATE BOX (card style) ======
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        height: 60,
                        decoration: _inputBoxDecoration(
                          isValid: isInputValid,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Center(
                          child: Text(
                            dateDisplay,
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: draft.birthDate != null
                                  ? AppColors.white
                                  : AppColors.lightGreyText.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // UMUR KAMU (centered)
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.greyText,
                          ),
                          children: [
                            const TextSpan(text: 'Kamu berumur: '),
                            TextSpan(
                              text: '$age tahun',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              'Umur kamu berpengaruh terhadap berapa banyak energi yang dibutuhkan oleh tubuh setiap harinya.',
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
