import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Brand colors
    const Color green = Color(0xFF5F9C3F);
    const Color greenLight = Color(0xFF7BB662);
    const Color gray = Color(0xFFBDBDBD);

    // Kanvas Figma asli
    const double baseW = 393.0;
    const double baseH = 850.0;

    // Dimensi tombol dari desain Figma
    const double btnWFig = 313.0;
    const double btnHFig = 46.22;
    const double btnLeftFig = 40.0;

    // Di Figma: login di bawah, register di atasnya
    const double loginTopFig = 606.43;
    const double gapFig = 13.2; // jarak di Figma antara 2 tombol (biar rapat)
    final double registerTopFig = loginTopFig - btnHFig - gapFig;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final double screenW = c.maxWidth;
            final double screenH = c.maxHeight;

            // Skala proporsional terhadap kanvas Figma
            final double scale =
                (screenW / baseW < screenH / baseH) ? (screenW / baseW) : (screenH / baseH);

            // Ukuran kanvas terskala + center di layar
            final double canvasW = baseW * scale;
            final double canvasH = baseH * scale;
            final double padLeft = (screenW - canvasW) / 2;
            final double padTop = (screenH - canvasH) / 2;

            // Helper konversi koordinat Figma → layar
            double fx(double figLeft) => padLeft + figLeft * scale;
            double fy(double figTop) => padTop + figTop * scale;
            double fw(double figW) => figW * scale;
            double fh(double figH) => figH * scale;

            // Shadow lembut (gunakan withValues, bukan withOpacity yang deprecated)
            final List<BoxShadow> softShadow = [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.12),
                offset: const Offset(0, 6),
                blurRadius: 12,
              ),
            ];

            return Stack(
              children: [
                // Latar putih (kanvas)
                Positioned(
                  left: padLeft,
                  top: padTop,
                  width: canvasW,
                  height: canvasH,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white),
                  ),
                ),

                // ===== FOOTER TEXT (2 baris, center) =====
                Positioned(
                  left: fx(0),
                  top: fy(796),
                  width: canvasW,
                  child: Column(
                    children: [
                      Text(
                        'Version 1.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.50),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By Kelompok 3 SI Capstone C',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.50),
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== TOMBOL REGISTER (atas) =====
                Positioned(
                  left: fx(btnLeftFig),
                  top: fy(registerTopFig),
                  width: fw(btnWFig),
                  height: fh(btnHFig),
                  child: InteractiveButton(
                    text: 'Saya pengguna baru',
                    onPressed: () => Navigator.pushNamed(context, '/terms'),
                    // state idle -> putih + abu
                    idleFillColor: Colors.white,
                    idleBorderColor: gray,
                    idleTextColor: Colors.black,
                    // state aktif -> hijau sekunder
                    activeColor: greenLight,
                    activeTextColor: Colors.white,
                    borderRadius: 8.87 * scale,
                    borderWidth: 2 * scale,
                    fontSize: 17.73 * scale,
                    fontWeight: FontWeight.w500,
                    padding: EdgeInsets.zero,
                    duration: const Duration(milliseconds: 120),
                    boxShadow: softShadow,
                  ),
                ),

                // ===== TOMBOL LOGIN (bawah, rapat) =====
                Positioned(
                  left: fx(btnLeftFig),
                  top: fy(loginTopFig),
                  width: fw(btnWFig),
                  height: fh(btnHFig),
                  child: InteractiveButton(
                    text: 'Saya sudah punya akun',
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    // idle -> putih + abu
                    idleFillColor: Colors.white,
                    idleBorderColor: gray,
                    idleTextColor: Colors.black,
                    // aktif -> hijau utama outline & fill
                    activeColor: green,
                    activeTextColor: Colors.white,
                    borderRadius: 8.87 * scale,
                    borderWidth: 2.66 * scale,
                    fontSize: 17.73 * scale,
                    fontWeight: FontWeight.w500,
                    padding: EdgeInsets.zero,
                    duration: const Duration(milliseconds: 120),
                    boxShadow: softShadow,
                  ),
                ),

                // ===== LOGO HEALTHY GO (bawah judul) =====
                Positioned(
                  left: fx(120),
                  top: fy(368),
                  width: fw(159),
                  height: fh(95),
                  child: Image.asset(
                    'assets/images/Logo HealthyGo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // ===== JUDUL =====
                Positioned(
                  left: fx(86),
                  top: fy(330),
                  width: fw(220),
                  child: Text(
                    'NutriLink x',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: green,
                      fontSize: 32 * scale,
                      fontWeight: FontWeight.w700,
                      height: 0.94,
                      letterSpacing: 1 * scale,
                    ),
                  ),
                ),

                // ===== LOGO NUTRILINK (atas) =====
                Positioned(
                  left: fx(86),
                  top: fy(111),
                  width: fw(220),
                  height: fh(210),
                  child: Image.asset(
                    'assets/images/Logo NutriLink.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tombol interaktif: desktop (hover) & mobile (press)
/// - Idle: putih + border abu + teks hitam
/// - Active (hover/press): hijau (fill & border) + teks putih
class InteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  // Idle state
  final Color idleBorderColor;
  final Color idleFillColor;
  final Color idleTextColor;

  // Active (hover/press)
  final Color activeColor; // untuk fill & border
  final Color activeTextColor;

  final double borderRadius;
  final double borderWidth;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final Duration duration;
  final List<BoxShadow>? boxShadow;

  const InteractiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.idleBorderColor = const Color(0xFFBDBDBD),
    this.idleFillColor = Colors.white,
    this.idleTextColor = Colors.black,
    this.activeColor = const Color(0xFF7BB662),
    this.activeTextColor = Colors.white,
    this.borderRadius = 8,
    this.borderWidth = 2,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.duration = const Duration(milliseconds: 120),
    this.boxShadow,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton> {
  bool _isHovered = false; // desktop/web
  bool _isPressed = false; // mobile/touch (highlight)

  void _setHovered(bool v) {
    if (_isHovered != v) setState(() => _isHovered = v);
  }

  void _setPressed(bool v) {
    if (_isPressed != v) setState(() => _isPressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;

    final Color fillColor = active ? widget.activeColor : widget.idleFillColor;
    final Color borderColor = active ? widget.activeColor : widget.idleBorderColor;
    final Color textColor = active ? widget.activeTextColor : widget.idleTextColor;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onHighlightChanged: (v) => _setPressed(v), // mobile press
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: widget.duration,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: borderColor, width: widget.borderWidth),
            boxShadow: widget.boxShadow ??
                [
                  if (active)
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
