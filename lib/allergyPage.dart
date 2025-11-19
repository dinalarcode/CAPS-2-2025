// lib/allergyPage.dart

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

class AllergyPage extends StatefulWidget {
  const AllergyPage({super.key});
  
  @override
  State<AllergyPage> createState() => _AllergyPageState();
}

class _AllergyPageState extends State<AllergyPage> {
  late UserProfileDraft draft;

  // Daftar Opsi Alergi dengan placeholder gambar (gunakan assets/images/ di proyek Anda)
  static const List<Map<String, String>> _allergyOptions = [
    {'name': 'Tidak Ada Alergi', 'image': 'assets/images/No_Allergy.png'}, // Opsi tanpa alergi
    {'name': 'Seafood', 'image': 'assets/images/Seafood.png'},
    {'name': 'Ikan', 'image': 'assets/images/Fish.png'},
    {'name': 'Udang', 'image': 'assets/images/Shrimp.png'},
    {'name': 'Sapi', 'image': 'assets/images/Beef.png'},
    {'name': 'Ayam', 'image': 'assets/images/Chicken.png'},
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
    if (draft.allergies.isEmpty) {
      _toast('Pilih minimal satu alergi makanan.');
      return;
    }

    saveDraft(context, draft);
    next(context, '/eat-frequency', draft);
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
    final bool isInputValid = draft.allergies.isNotEmpty;

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
                          TextSpan(text: 'Apa saja '),
                          TextSpan(
                            text: 'alergi kamu',
                            style: TextStyle(color: kGreen),
                          ),
                          TextSpan(text: '?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kami akan mempersonalisasikan menu makanan yang tidak mengandung alergi kamu.',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ====== LIST PILIHAN ALERGI ======
                    ..._allergyOptions.map((option) {
                      final name = option['name']!;
                      final isNoAllergy = name == 'Tidak Ada Alergi';
                      final isSelected = draft.allergies.contains(name);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isNoAllergy) {
                                // Jika pilih "Tidak Ada Alergi", clear semua dan set hanya ini
                                draft.allergies.clear();
                                draft.allergies.add(name);
                              } else {
                                // Jika pilih alergi lain, hapus "Tidak Ada Alergi" dulu
                                draft.allergies.remove('Tidak Ada Alergi');
                                if (isSelected) {
                                  draft.allergies.remove(name);
                                } else {
                                  draft.allergies.add(name);
                                }
                              }
                            });
                          },
                          child: Container(
                            height: 80,
                            decoration: _cardDecoration(
                              isSelected: isSelected,
                            ),
                            child: isNoAllergy
                                ? Center(
                                    // Card "Tidak Ada Alergi" - rata tengah tanpa gambar
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: 'Funnel Display',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  )
                                : Row(
                                    // Card alergi lain - dengan gambar
                                    children: [
                                      // Bagian Gambar (80x80)
                                      Container(
                                        width: 80,
                                        height: 80,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                          ),
                                          image: DecorationImage(
                                            image: AssetImage(option['image']!),
                                            fit: BoxFit.cover,
                                            filterQuality: FilterQuality.medium,
                                            colorFilter: ColorFilter.mode(
                                              Colors.black.withValues(
                                                alpha: isSelected ? 0.0 : 0.2,
                                              ),
                                              BlendMode.darken,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Bagian Label Teks
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            name,
                                            style: TextStyle(
                                              fontFamily: 'Funnel Display',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: kGreyText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pilih semua jenis makanan yang menyebabkan alergi pada kamu. Kamu dapat memilih lebih dari satu.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            color: widget.enabled ? null : const Color(0xFFE0E0E0),
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