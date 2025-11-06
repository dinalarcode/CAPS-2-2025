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

  void _backToName() {
    Navigator.pushReplacementNamed(context, '/name-input');
  }

  void _next() {
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih salah satu target terlebih dahulu.')),
      );
      return;
    }
    draft.target = switch (selected!) {
      TargetChoice.lose => 'Menurunkan berat badan',
      TargetChoice.maintain => 'Menjaga berat badan',
      TargetChoice.gain => 'Menaikkan berat badan',
    };
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
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'Saya di sini untuk',
                            style: TextStyle(color: kGreen),
                          ),
                          TextSpan(text: ':'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kita akan menggunakannya untuk mempersonalisasikan aplikasi NutriLink untuk kamu.',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==== PILIHAN TARGET ====
                    _ChoiceRow(
                      text: 'Menurunkan berat badan',
                      selected: selected == TargetChoice.lose,
                      onTap: () => setState(() => selected = TargetChoice.lose),
                    ),
                    const SizedBox(height: 16),
                    _ChoiceRow(
                      text: 'Menjaga berat badan',
                      selected: selected == TargetChoice.maintain,
                      onTap: () => setState(() => selected = TargetChoice.maintain),
                    ),
                    const SizedBox(height: 16),
                    _ChoiceRow(
                      text: 'Menaikkan berat badan',
                      selected: selected == TargetChoice.gain,
                      onTap: () => setState(() => selected = TargetChoice.gain),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'Pilih salah satu untuk melanjutkan',
                        style: TextStyle(color: kLightGreyText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======= FOOTER =======
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: HoverButton(
                        text: 'Kembali',
                        onPressed: _backToName,
                        borderColor: kDisabledGrey,
                        hoverColor: kGreen,
                        baseFillColor: kBaseGreyFill,
                        baseTextColor: Colors.black54,
                        enabled: true,
                        filledWhenEnabled: false,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HoverButton(
                        text: 'Lanjut',
                        onPressed: (selected != null) ? _next : () {},
                        borderColor: (selected != null) ? kGreen : kDisabledGrey,
                        hoverColor: (selected != null) ? kGreenLight : kDisabledGrey,
                        baseFillColor: (selected != null) ? kGreen : kBaseGreyFill,
                        baseTextColor: (selected != null) ? Colors.white : Colors.black54,
                        enabled: selected != null,
                        filledWhenEnabled: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======= PANAH BACK (PALING ATAS, agar bisa diklik) =======
            Positioned(
              left: 4,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                tooltip: 'Kembali',
                onPressed: _backToName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PILIHAN CARD
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
    final Color fillColor = selected
        ? kGreen
        : (isHovered ? kGreen.withValues(alpha: 0.08) : Colors.white);
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
          color: fillColor,
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
// HOVER BUTTON (dipakai untuk tombol Kembali / Lanjut)
// ============================================================================
class HoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color hoverColor;
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
    required this.enabled,
    required this.filledWhenEnabled,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool filled = widget.enabled && widget.filledWhenEnabled;
    final Color bg = isHovered
        ? (widget.enabled ? widget.hoverColor : widget.baseFillColor)
        : (filled ? widget.baseFillColor : Colors.white);
    final Color border = isHovered
        ? (widget.enabled ? widget.hoverColor : widget.borderColor)
        : widget.borderColor;
    final Color fg = isHovered
        ? (widget.enabled ? Colors.white : widget.baseTextColor)
        : (filled ? Colors.white : widget.baseTextColor);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          onPressed: widget.onPressed,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
