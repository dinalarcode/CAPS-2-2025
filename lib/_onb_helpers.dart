// File: _onb_helpers.dart

import 'package:flutter/material.dart';
import 'models/user_profile_draft.dart'; // Pastikan path ini benar

// --- Palet Warna ---
const kGreen = Color(0xFF5F9C3F);
const kGreenLight = Color(0xFF7BB662);
const kGreyText = Color(0xFF494949);
const kLightGreyText = Color(0xFF888888);
const kDisabledGrey = Color(0xFFBDBDBD);
const kBaseGreyFill = Color(0xFFF3F3F5);

// --- Fungsi Helper Navigasi dan Draft ---

UserProfileDraft getDraft(BuildContext ctx) =>
    (ModalRoute.of(ctx)!.settings.arguments as UserProfileDraft?) ?? UserProfileDraft();

Future<void> next(BuildContext ctx, String route, UserProfileDraft draft) async {
  await Navigator.pushNamed(ctx, route, arguments: draft);
}

void back(BuildContext ctx, UserProfileDraft draft) {
  Navigator.pop(ctx, draft);
}

void saveDraft(BuildContext ctx, UserProfileDraft draft) {
  debugPrint('Draft di-update sebelum navigasi maju.');
}

// --- Widget Gradient Button ---

class GradientButton extends StatefulWidget {
  final String text;
  final bool enabled;
  final VoidCallback? onPressed; 
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.text,
    this.enabled = true,
    this.onPressed,
    this.height = 48,
    this.borderRadius = 24,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool hover = false;
  bool press = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled && widget.onPressed != null;
    final bool isActive = isEnabled && (hover || press);

    final gradient = isEnabled
        ? LinearGradient(
            colors: isActive
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
        onTap: isEnabled ? widget.onPressed : null,
        onTapDown: (_) { if (isEnabled) setState(() => press = true); },
        onTapUp: (_) { if (isEnabled) setState(() => press = false); },
        onTapCancel: () { if (isEnabled) setState(() => press = false); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: gradient,
            color: isEnabled ? null : kBaseGreyFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isEnabled ? kGreen : kDisabledGrey,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Widget StepScaffold (DITAMBAHKAN parameter nextEnabled) ---

class StepScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String nextText;
  final bool nextEnabled; 

  const StepScaffold({
    super.key,
    required this.title,
    required this.child, 
    this.onNext,
    this.onBack,
    this.nextText = 'Lanjut',
    this.nextEnabled = true, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: child),
                  Row(
                    children: [
                      // Tombol Lanjut (GradientButton)
                      Expanded(
                        child: GradientButton(
                          text: nextText,
                          height: 48,
                          borderRadius: 8, 
                          enabled: nextEnabled && onNext != null, 
                          onPressed: onNext,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Widget TermsButton ---
// (Dihapus dari sini karena tidak dibutuhkan oleh halaman utama)