import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Responsive scaling helper methods (kalau mau di-scale nanti)
  double fw(double width) => width; // figure width
  double fh(double height) => height; // figure height
  double fx(double x) => x; // figure x position
  double fy(double y) => y; // figure y position

  // Layout constants
  final double padLeft = 0;
  final double padTop = 0;
  final double canvasW = 390;
  final double canvasH = 844;

  // Posisi tombol (sudah dinaikkan ke bawah logo HealthyGo)
  final double btnLeftFig = 45;
  final double registerTopFig = 520; // dulu 696
  final double loginTopFig = 580; // dulu 749

  final double btnWFig = 300;
  final double btnHFig = 48;

  final List<BoxShadow> softShadow = const [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Brand colors
    const Color green = Color(0xFF5F9C3F);
    const Color greenLight = Color(0xFF7BB662);
    const Color gray = Color(0xFFBDBDBD);
    final double scale = 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: canvasW,
          height: canvasH,
          child: Stack(
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

              // (Subtitle dihapus sesuai request)

              // ===== TOMBOL REGISTER (atas) =====
              Positioned(
                left: fx(btnLeftFig),
                top: fy(registerTopFig),
                width: fw(btnWFig),
                height: fh(btnHFig),
                child: InteractiveButton(
                  text: 'Saya pengguna baru',
                  onPressed: () => Navigator.pushNamed(context, '/terms'),
                  // idle -> putih + abu
                  idleFillColor: Colors.white,
                  idleBorderColor: gray,
                  idleTextColor: Colors.black,
                  // aktif -> gradient hijau halus
                  activeColor: greenLight,
                  activeGradientColors: const [greenLight, green],
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
                  // aktif -> gradient hijau halus
                  activeColor: green,
                  activeGradientColors: const [green, greenLight],
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

              // ===== FOOTER TEXT (2 baris, center) =====
              Positioned(
                left: fx(0),
                top: fy(796),
                width: canvasW,
                child: Column(
                  children: [
                    Text(
                      'Version 1.2',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.50),
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By Kelompok 2 SI Capstone C',
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
            ],
          ),
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
  final Color activeColor; // fallback untuk fill & border
  final List<Color>? activeGradientColors;
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
    this.activeGradientColors,
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

    final Color textColor =
        active ? widget.activeTextColor : widget.idleTextColor;

    final bool useGradient =
        active && widget.activeGradientColors != null;

    // Untuk border: gunakan warna pertama dari gradient jika aktif
    final Color borderColor = active
        ? (widget.activeGradientColors?.first ?? widget.activeColor)
        : widget.idleBorderColor;

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
            gradient: useGradient
                ? LinearGradient(
                    colors: widget.activeGradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: useGradient ? null : (active ? widget.activeColor : widget.idleFillColor),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: borderColor,
              width: widget.borderWidth,
            ),
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
