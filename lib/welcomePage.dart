import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Brand colors
    const Color green = Color(0xFF5F9C3F);
    const Color greenLight = Color(0xFF7BB662);
    const Color gray = Color(0xFFBDBDBD);

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 393,
          height: 850,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              Positioned(
                left: 130,
                top: 840,
                child: SizedBox(
                  width: 134,
                  height: 5,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 134,
                          height: 5,
                          decoration: ShapeDecoration(
                            color: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
<<<<<<< recommendation
              ),
              Positioned(
                left: 86,
                top: 111,
                child: SizedBox(
                  width: 220,
                  height: 210,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 220,
                          height: 210,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage("https://placehold.co/220x210"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 2,
                top: 0,
                child: SizedBox(
                  width: 390,
                  height: 38,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: SizedBox(
                          width: 390,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 38,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 30,
                                      top: 7,
                                      child: Container(
                                        width: 54,
                                        height: 21,
                                        decoration: ShapeDecoration(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 0,
                                              top: 1,
                                              child: SizedBox(
                                                width: 54,
                                                height: 20,
                                                child: Text(
                                                  '9:41',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: const Color(0xFF010101),
                                                    fontSize: 17,
                                                    fontFamily: 'SF Pro Text',
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.29,
                                                    letterSpacing: -0.41,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                    ],
=======

                // ===== LOGO NUTRILINK (atas) =====
                Positioned(
                  left: fx(86),
                  top: fy(111),
                  width: fw(220),
                  height: fh(210),
                  child: Image.asset(
                    'assets/images/Logo NutriLink.png',
                    fit: BoxFit.contain,
>>>>>>> master
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
