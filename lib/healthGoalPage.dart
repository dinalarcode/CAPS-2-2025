// lib/healthGoalPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

// === Palet konsisten ===
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
final  Color kBaseGreyFill = const Color(0xFF000000).withValues(alpha: 0.04);

enum HealthGoalChoice {
  understandIntake,   // Memahami asupan makananku
  manageCondition,    // Mengelola kondisi medis
  improveBody,        // Meningkatkan kesehatan tubuh
  improveEmotional,   // Meningkatkan kesehatan emosional
  other,              // Lainnya (+ alasan max 25)
}

class HealthGoalPage extends StatefulWidget {
  const HealthGoalPage({super.key});
  @override
  State<HealthGoalPage> createState() => _HealthGoalPageState();
}

class _HealthGoalPageState extends State<HealthGoalPage> {
  late UserProfileDraft draft;

  HealthGoalChoice? selected;
  final TextEditingController otherCtrl = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    // Restore dari draft.healthGoal bila ada
    final g = (draft.healthGoal ?? '').toLowerCase();
    if (g.contains('memahami asupan')) {
      selected = HealthGoalChoice.understandIntake;
    } else if (g.contains('mengelola kondisi')) {
      selected = HealthGoalChoice.manageCondition;
    } else if (g.contains('meningkatkan kesehatan tubuh')) {
      selected = HealthGoalChoice.improveBody;
    } else if (g.contains('meningkatkan kesehatan emosional')) {
      selected = HealthGoalChoice.improveEmotional;
    } else if (g.startsWith('lainnya')) {
      selected = HealthGoalChoice.other;
      // ambil alasan setelah "Lainnya: ..."
      final idx = g.indexOf(':');
      if (idx != -1 && idx + 1 < draft.healthGoal!.length) {
        otherCtrl.text = draft.healthGoal!.substring(idx + 1).trim();
      }
    } else {
      selected = null;
    }
  }

  @override
  void dispose() {
    otherCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pushReplacementNamed(context, '/target-selection');
  }

  void _goNext() {
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tujuan kesehatan terlebih dahulu.')),
      );
      return;
    }

    if (selected == HealthGoalChoice.other) {
      if (!formKey.currentState!.validate()) return;
      draft.healthGoal = 'Lainnya: ${otherCtrl.text.trim()}';
    } else {
      draft.healthGoal = switch (selected!) {
        HealthGoalChoice.understandIntake => 'Memahami asupan makananku',
        HealthGoalChoice.manageCondition => 'Mengelola kondisi medis',
        HealthGoalChoice.improveBody => 'Meningkatkan kesehatan tubuh',
        HealthGoalChoice.improveEmotional => 'Meningkatkan kesehatan emosional',
        HealthGoalChoice.other => 'Lainnya', // tak akan kena karena diatas return
      };
    }

    // Lanjut ke step berikutnya (sesuai urutanmu)
    next(context, '/challenge', draft);
  }

  bool get _nextEnabled {
    if (selected == null) return false;
    if (selected == HealthGoalChoice.other) {
      final s = otherCtrl.text.trim();
      return s.isNotEmpty && s.length <= 25;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ===== Konten =====
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 140),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul/lead
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: 'Apa tujuan kesehatan utama kamu',
                              style: TextStyle(color: kGreen),
                            ),
                            TextSpan(text: '?'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hal ini membantu kami memahami tujuanmu, sehingga kami bisa lebih personal dalam mendukungmu mencapai target.',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: kGreyText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // === Opsi ===
                      _ChoiceTile(
                        text: 'Memahami asupan makananku',
                        selected: selected == HealthGoalChoice.understandIntake,
                        onTap: () => setState(() => selected = HealthGoalChoice.understandIntake),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceTile(
                        text: 'Mengelola kondisi medis',
                        selected: selected == HealthGoalChoice.manageCondition,
                        onTap: () => setState(() => selected = HealthGoalChoice.manageCondition),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceTile(
                        text: 'Meningkatkan kesehatan tubuh',
                        selected: selected == HealthGoalChoice.improveBody,
                        onTap: () => setState(() => selected = HealthGoalChoice.improveBody),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceTile(
                        text: 'Meningkatkan kesehatan emosional',
                        selected: selected == HealthGoalChoice.improveEmotional,
                        onTap: () => setState(() => selected = HealthGoalChoice.improveEmotional),
                      ),
                      const SizedBox(height: 16),

                      // === Lainnya + alasan (maks 25) ===
                      _ChoiceTile(
                        text: 'Lainnya',
                        selected: selected == HealthGoalChoice.other,
                        onTap: () => setState(() => selected = HealthGoalChoice.other),
                      ),
                      if (selected == HealthGoalChoice.other) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: otherCtrl,
                          maxLength: 25,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Tulis alasan singkat (maks 25 karakter)',
                            counterText: '',
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: kGreen, width: 1.6),
                            ),
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Alasan tidak boleh kosong';
                            if (s.length > 25) return 'Maksimal 25 karakter';
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (_nextEnabled) _goNext();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ===== Footer (Kembali / Lanjut) =====
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
                        onPressed: _goBack,
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
                        onPressed: _nextEnabled ? _goNext : () {},
                        borderColor: _nextEnabled ? kGreen : kDisabledGrey,
                        hoverColor: _nextEnabled ? kGreenLight : kDisabledGrey,
                        baseFillColor: _nextEnabled ? kGreen : kBaseGreyFill,
                        baseTextColor: _nextEnabled ? Colors.white : Colors.black54,
                        enabled: _nextEnabled,
                        filledWhenEnabled: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Back arrow (paling atas) =====
            Positioned(
              left: 4,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                tooltip: 'Kembali',
                onPressed: _goBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Kartu Pilihan =======================
class _ChoiceTile extends StatefulWidget {
  const _ChoiceTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<_ChoiceTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final Color fill = selected
        ? kGreen
        : (isHovered ? kGreen.withValues(alpha: 0.08) : Colors.white);
    final Color border = selected
        ? kGreen
        : (isHovered ? kGreenLight : const Color(0xFFA9ABAD));
    final Color text = selected ? Colors.white : kLightGreyText;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.4),
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
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================= Tombol Hover Reusable =======================
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
