// lib/targetSelectionPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

enum TargetChoice { lose, maintain, gain }

// ==== Palet Warna ====
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
final Color kBaseGreyFill = const Color(0xFF000000).withValues(alpha: 0.04);

class TargetSelectionPage extends StatefulWidget {
  const TargetSelectionPage({super.key});
  @override
  State<TargetSelectionPage> createState() => _TargetSelectionPageState();
}

class _TargetSelectionPageState extends State<TargetSelectionPage> {
  late UserProfileDraft draft;
  TargetChoice? selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    switch ((draft.target ?? '').toLowerCase()) {
      case 'menurunkan berat badan':
      case 'lose':
        selected = TargetChoice.lose;
        break;
      case 'menjaga berat badan':
      case 'maintain':
        selected = TargetChoice.maintain;
        break;
      case 'menaikkan berat badan':
      case 'gain':
        selected = TargetChoice.gain;
        break;
      default:
        selected = null;
    }
  }

  void _updateSelection(TargetChoice choice) {
    setState(() => selected = choice);

    // Langsung simpan ke draft + Firebase (via helper)
    draft.target = switch (choice) {
      TargetChoice.lose => 'Menurunkan berat badan',
      TargetChoice.maintain => 'Menjaga berat badan',
      TargetChoice.gain => 'Menaikkan berat badan',
    };

    saveDraft(context, draft);
  }

  void _backToName() {
    Navigator.pushReplacementNamed(context, '/name-input');
  }

  void _next() {
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih salah satu target terlebih dahulu.'),
        ),
      );
      return;
    }

    // draft.target sudah di-set di _updateSelection, tapi kita pastikan lagi
    draft.target = switch (selected!) {
      TargetChoice.lose => 'Menurunkan berat badan',
      TargetChoice.maintain => 'Menjaga berat badan',
      TargetChoice.gain => 'Menaikkan berat badan',
    };

    saveDraft(context, draft);
    next(context, '/health-goal', draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ======= KONTEN UTAMA =======
            Positioned.fill(
              child: SingleChildScrollView(
                // Samain padding dengan NameInputPage
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading (ukuran & weight sama dengan NameInputPage)
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(text: 'Apa '),
                          TextSpan(
                            text: 'tujuan utama',
                            style: TextStyle(color: kGreen),
                          ),
                          TextSpan(text: ' kamu dengan NutriLink?'),
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
                      'Pilih target utamamu',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kLightGreyText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ==== PILIHAN TARGET ====
                    _ChoiceRow(
                      text: 'Menurunkan berat badan',
                      selected: selected == TargetChoice.lose,
                      onTap: () => _updateSelection(TargetChoice.lose),
                    ),
                    const SizedBox(height: 16),
                    _ChoiceRow(
                      text: 'Menjaga berat badan',
                      selected: selected == TargetChoice.maintain,
                      onTap: () => _updateSelection(TargetChoice.maintain),
                    ),
                    const SizedBox(height: 16),
                    _ChoiceRow(
                      text: 'Menaikkan berat badan',
                      selected: selected == TargetChoice.gain,
                      onTap: () => _updateSelection(TargetChoice.gain),
                    ),
                    const SizedBox(height: 32),

                    const Center(
                      child: Text(
                        'Pilih salah satu untuk melanjutkan',
                        style: TextStyle(
                          color: kLightGreyText,
                          fontSize: 12,
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======= FOOTER: tombol LANJUT (gradient hijau, sama kayak NameInput) =======
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: 'Lanjut',
                  enabled: selected != null,
                  onPressed: _next,
                ),
              ),
            ),

            // ======= PANAH BACK (posisi sama pattern NameInput) - LETAKKAN PALING AKHIR =======
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
                  onPressed: _backToName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PILIHAN CARD (gradient hijau ketika dipilih)
// ============================================================================
class _ChoiceRow extends StatefulWidget {
  const _ChoiceRow({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChoiceRow> createState() => _ChoiceRowState();
}

class _ChoiceRowState extends State<_ChoiceRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final bool useGradient = selected;

    final Color fallbackFill =
        isHovered ? kGreen.withValues(alpha: 0.08) : Colors.white;

    final Color borderColor = selected
        ? kGreen
        : (isHovered ? kGreenLight : const Color(0xFFA9ABAD));

    final Color textColor = selected ? Colors.white : kLightGreyText;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: useGradient
              ? const LinearGradient(
                  colors: [kGreenLight, kGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: useGradient ? null : fallbackFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GRADIENT BUTTON ala NameInput / Welcome (tombol "Lanjut")
// ============================================================================
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
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
