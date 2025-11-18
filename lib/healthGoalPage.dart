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
final Color kBaseGreyFill = const Color(0xFF000000).withValues(alpha: 0.04);

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
  void initState() {
    super.initState();
    otherCtrl.addListener(_onOtherChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    // Restore dari draft.healthGoal bila ada
    final raw = draft.healthGoal;
    final g = (raw ?? '').toLowerCase();

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
      final idx = raw?.indexOf(':') ?? -1;
      if (idx != -1 && idx + 1 < (raw?.length ?? 0)) {
        otherCtrl.text = raw!.substring(idx + 1).trim();
      }
    } else {
      selected = null;
    }
  }

  @override
  void dispose() {
    otherCtrl.removeListener(_onOtherChanged);
    otherCtrl.dispose();
    super.dispose();
  }

  // === NAVIGASI ===
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
        HealthGoalChoice.understandIntake =>
          'Memahami asupan makananku',
        HealthGoalChoice.manageCondition =>
          'Mengelola kondisi medis',
        HealthGoalChoice.improveBody =>
          'Meningkatkan kesehatan tubuh',
        HealthGoalChoice.improveEmotional =>
          'Meningkatkan kesehatan emosional',
        HealthGoalChoice.other =>
          'Lainnya', // nggak kepakai karena case di atas
      };
    }

    saveDraft(context, draft);
    next(context, '/challenge', draft);
  }

  // === Update pilihan + auto-simpan ke draft/Firebase ===
  void _updateSelection(HealthGoalChoice choice) {
    setState(() => selected = choice);

    if (choice == HealthGoalChoice.other) {
      _updateDraftForOther();
    } else {
      draft.healthGoal = switch (choice) {
        HealthGoalChoice.understandIntake =>
          'Memahami asupan makananku',
        HealthGoalChoice.manageCondition =>
          'Mengelola kondisi medis',
        HealthGoalChoice.improveBody =>
          'Meningkatkan kesehatan tubuh',
        HealthGoalChoice.improveEmotional =>
          'Meningkatkan kesehatan emosional',
        HealthGoalChoice.other =>
          'Lainnya',
      };
      saveDraft(context, draft);
    }
  }

  void _updateDraftForOther() {
    final t = otherCtrl.text.trim();
    draft.healthGoal = t.isEmpty ? 'Lainnya' : 'Lainnya: $t';
    saveDraft(context, draft);
  }

  void _onOtherChanged() {
    if (selected == HealthGoalChoice.other) {
      _updateDraftForOther();
      setState(() {}); // supaya tombol "Lanjut" ikut update enabled/disabled
    }
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
            // ===== Konten utama =====
            Positioned.fill(
              child: SingleChildScrollView(
                // samain dengan NameInputPage & TargetSelectionPage
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 130),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul utama (style sama NameInput)
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
                              text: 'tujuan kesehatan utama',
                              style: TextStyle(color: kGreen),
                            ),
                            TextSpan(text: ' kamu?'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Hal ini membantu kami memahami tujuanmu, sehingga kami bisa lebih personal dalam mendukungmu mencapai target.',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: kGreyText,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Pilih tujuan kesehatan utama',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: kLightGreyText,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === Opsi ===
                      _ChoiceTile(
                        text: 'Memahami asupan makananku',
                        selected:
                            selected == HealthGoalChoice.understandIntake,
                        onTap: () =>
                            _updateSelection(HealthGoalChoice.understandIntake),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceTile(
                        text: 'Mengelola kondisi medis',
                        selected:
                            selected == HealthGoalChoice.manageCondition,
                        onTap: () =>
                            _updateSelection(HealthGoalChoice.manageCondition),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceTile(
                        text: 'Meningkatkan kesehatan tubuh',
                        selected: selected == HealthGoalChoice.improveBody,
                        onTap: () =>
                            _updateSelection(HealthGoalChoice.improveBody),
                      ),
                      const SizedBox(height: 16),
                      _ChoiceTile(
                        text: 'Meningkatkan kesehatan emosional',
                        selected:
                            selected == HealthGoalChoice.improveEmotional,
                        onTap: () => _updateSelection(
                            HealthGoalChoice.improveEmotional),
                      ),
                      const SizedBox(height: 16),

                      // === Lainnya + alasan (maks 25) ===
                      _ChoiceTile(
                        text: 'Lainnya',
                        selected: selected == HealthGoalChoice.other,
                        onTap: () =>
                            _updateSelection(HealthGoalChoice.other),
                      ),
                      if (selected == HealthGoalChoice.other) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: otherCtrl,
                          maxLength: 25,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText:
                                'Tulis alasan singkat (maks 25 karakter)',
                            counterText: '',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: kGreen, width: 1.6),
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

            // ===== FOOTER: tombol LANJUT (gradient hijau, konsisten) =====
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: 'Lanjut',
                  enabled: _nextEnabled,
                  onPressed: _goNext,
                ),
              ),
            ),

            // ===== Panah back (posisi sama dengan NameInput / TargetSelection) =====
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
                  onPressed: _goBack,
                ),
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
        duration: const Duration(milliseconds: 160),
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
              style: TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================= Gradient Button (konsisten) =======================
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
