// lib/challengePage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/pages/onboarding/onboardingHelpers.dart' show getDraft, saveDraft, next;
import 'package:nutrilink/models/userProfileDraft.dart';

// Palet konsisten
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill =
    const Color(0xFF000000).withValues(alpha: 0.04);

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  late UserProfileDraft draft;

  final List<String> _options = const [
    'Tidak ada waktu',
    'Nafsu makan tidak teratur',
    'Dukungan yang rendah',
    'Perencanaan jadwal makan',
    'Isu kesehatan',
    'Tidak ada partner dalam diet',
    'Kurangnya informasi',
    'Merasa tidak percaya diri pada tubuh',
    'Merasa tetap termotivasi',
    'Lainnya',
  ];

  // set lokal biar gampang toggle
  final Set<String> _selected = {};

  // Mendapatkan teks target yang dinamis
  String get _targetText {
    final target = (draft.target ?? '').toLowerCase();
    if (target.contains('menurunkan') || target == 'lose') {
      return 'menurunkan berat badan';
    } else if (target.contains('menaikkan') || target == 'gain') {
      return 'menaikkan berat badan';
    } else {
      return 'menjaga berat badan';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    // Restore dari draft.challenges (hanya yang masih ada di options)
    _selected
      ..clear()
      ..addAll(
        draft.challenges.where((c) => _options.contains(c)),
      );
  }

  void _toggleOption(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        if (_selected.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Kamu hanya bisa memilih maksimal 3 tantangan.'),
            ),
          );
          return;
        }
        _selected.add(label);
      }

      // simpan sementara di draft (belum push ke server)
      draft.challenges
        ..clear()
        ..addAll(_selected);
    });
  }

  void _goBack() {
    // simpan sementara sebelum balik
    saveDraft(context, draft);
    Navigator.pushReplacementNamed(context, '/health-goal');
  }

  void _goNext() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 tantangan terlebih dahulu.'),
        ),
      );
      return;
    }

    // simpan sementara sebelum lanjut
    saveDraft(context, draft);
    next(context, '/height-input', draft);
  }

  bool get _nextEnabled => _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ====== KONTEN ======
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul: ukuran sama seperti targetSelectionPage,
                    // dengan target yang dinamis
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(text: 'Apa yang membuat kamu '),
                          TextSpan(
                            text: 'kesulitan $_targetText',
                            style: const TextStyle(color: kGreen),
                          ),
                          const TextSpan(text: '?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pilih 3 yang paling relevan untuk kamu.',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List pilihan
                    ..._options.map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ChallengeOptionTile(
                          text: o,
                          selected: _selected.contains(o),
                          onTap: () => _toggleOption(o),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Hint bubble di bawah list
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
                              'Hal ini membantu kami memahami tantanganmu, sehingga kami bisa lebih personal dalam mendukungmu mencapai target.',
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

            // ====== PANAH BACK (atas kiri, dengan background putih) ======
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

            // ====== TOMBOL LANJUT (bawah, tidak transparan) ======
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
          ],
        ),
      ),
    );
  }
}

// ======================= Kartu Pilihan Challenge =======================
class _ChallengeOptionTile extends StatefulWidget {
  const _ChallengeOptionTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ChallengeOptionTile> createState() => _ChallengeOptionTileState();
}

class _ChallengeOptionTileState extends State<_ChallengeOptionTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool sel = widget.selected;

    final bool useGradient = sel;

    final Color fallbackFill = isHovered
        ? kGreen.withValues(alpha: 0.04)
        : Colors.white;

    final Color borderColor = sel
        ? kGreen
        : (isHovered ? kGreenLight : kMutedBorderGrey);

    final Color textColor = sel ? Colors.white : kLightGreyText;

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
          border: Border.all(
            color: borderColor,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                fontSize: 16, // disamakan dengan page lain
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

// ======================= Gradient Button (Lanjut) =======================
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
