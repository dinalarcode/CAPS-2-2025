// lib/targetWeightInputPage.dart

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

class TargetWeightInputPage extends StatefulWidget {
  const TargetWeightInputPage({super.key});

  @override
  State<TargetWeightInputPage> createState() => _TargetWeightInputPageState();
}

class _TargetWeightInputPageState extends State<TargetWeightInputPage> {
  late UserProfileDraft draft;
  final TextEditingController _c = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    _c.text = (draft.targetWeightKg != null && draft.targetWeightKg! > 0)
        ? draft.targetWeightKg!.toStringAsFixed(
            draft.targetWeightKg! % 1 == 0 ? 0 : 1,
          )
        : '';

    _c.removeListener(_onTextChanged);
    _c.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final parsed =
        double.tryParse(_c.text.replaceAll(',', '.').trim());
    setState(() {
      draft.targetWeightKg = parsed;
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

  // ====== VALIDASI GOAL ======
  String? _checkGoalValidation(double targetWeight) {
    final currentWeight = draft.weightKg;
    final goal = draft.target;

    if (currentWeight == null) {
      return 'Data berat badan saat ini tidak ditemukan. Silakan kembali dan isi berat badan Anda.';
    }

    if (goal == 'Menurunkan berat badan' && targetWeight >= currentWeight) {
      return 'Target harus LEBIH RENDAH dari berat badan Anda saat ini ($currentWeight} kg).';
    } else if (goal == 'Menaikkan berat badan' && targetWeight <= currentWeight) {
      return 'Target harus LEBIH TINGGI dari berat badan Anda saat ini ($currentWeight} kg).';
    } else if (goal == 'Menjaga berat badan' && targetWeight != currentWeight) {
      return 'Target harus SAMA dengan berat badan Anda saat ini ($currentWeight} kg).';
    }
    return null;
  }

  // ====== LOGIKA NEXT / BACK ======
  void _next() {
    final rawTargetWeight = _c.text.replaceAll(',', '.').trim();
    draft.targetWeightKg = double.tryParse(rawTargetWeight);

    if (draft.targetWeightKg == null) {
      _toast('Target berat badan tidak boleh kosong atau tidak valid.');
      return;
    }

    const double minWeight = 20.0;
    const double maxWeight = 200.0;

    if (draft.targetWeightKg! < minWeight ||
        draft.targetWeightKg! > maxWeight) {
      _toast(
        'Target berat badan tidak wajar. Isi antara $minWeight kg sampai $maxWeight kg.',
      );
      return;
    }

    // Validasi goal
    final validationError = _checkGoalValidation(draft.targetWeightKg!);
    if (validationError != null) {
      _toast(validationError);
      return;
    }

    saveDraft(context, draft);
    next(context, '/birth-date', draft);
  }

  void _back() {
    back(context, draft);
  }

  // ====== DECOR INPUT (border sama kayak style kartu) ======
  BoxDecoration _inputBoxDecoration({required bool isValid}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isValid ? kGreen : kMutedBorderGrey,
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

  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final bool isInputValid = draft.targetWeightKg != null &&
        draft.targetWeightKg! >= 20 &&
        draft.targetWeightKg! <= 200;

    // Ambil string goal untuk ditampilkan
    final String goalString = draft.target ?? 'Target belum dipilih';

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
                          TextSpan(text: 'Berapa '),
                          TextSpan(
                            text: 'target berat badanmu',
                            style: TextStyle(color: kGreen),
                          ),
                          TextSpan(text: '?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Target saat ini: $goalString. Target Anda harus konsisten dengan tujuan ini.',
                      style: const TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ====== INPUT TARGET BERAT (card style) ======
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
                                  hintText: 'cth: 65.5 kg',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Funnel Display',
                                    color: kLightGreyText
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
                              'Tips: Target harus realistis dan konsisten dengan tujuan Anda. Anda tidak dapat menetapkan target yang lebih rendah saat tujuan Anda menaikkan berat badan.',
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