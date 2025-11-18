import 'package:flutter/material.dart';
import 'package:nutrilink/termsAndConditionsDetailPage.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF5F9C3F);
    const Color greenLight = Color(0xFF7BB662);
    const Color gray = Color(0xFFBDBDBD);

    const double baseW = 393.0;
    const double baseH = 850.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final double screenW = c.maxWidth;
            final double screenH = c.maxHeight;

            final double scale =
                (screenW / baseW < screenH / baseH) ? (screenW / baseW) : (screenH / baseH);
            final double canvasW = baseW * scale;
            final double canvasH = baseH * scale;
            final double padLeft = (screenW - canvasW) / 2;
            final double padTop = (screenH - canvasH) / 2;

            double fx(double figLeft) => padLeft + figLeft * scale;
            double fy(double figTop) => padTop + figTop * scale;
            double fw(double figW) => figW * scale;
            double fh(double figH) => figH * scale;

            return Stack(
              children: [
                // Kanvas putih dengan sudut atas membulat
                Positioned(
                  left: padLeft,
                  top: padTop,
                  width: canvasW,
                  height: canvasH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20 * scale),
                        topRight: Radius.circular(20 * scale),
                      ),
                    ),
                  ),
                ),

                // Tombol close (X) -> kembali ke halaman sebelumnya (WelcomePage)
                Positioned(
                  left: fx(334.7),
                  top: fy(10),
                  width: fw(45.23),
                  height: fh(47),
                  child: Align(
                    alignment: Alignment.topRight,
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
                        icon: const Icon(Icons.close, color: Colors.black87, size: 24),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                      ),
                    ),
                  ),
                ),

                // Ilustrasi
                Positioned(
                  left: fx(75.38),
                  top: fy(55),
                  width: fw(241.23),
                  height: fh(125.66),
                  child: Image.asset(
                    'assets/images/Data Privacy Illustration.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // Paragraf
                Positioned(
                  left: fx(51.26),
                  top: fy(206.37),
                  width: fw(290.48),
                  height: fh(438.28),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: const Color(0xFF404040),
                          fontSize: 9 * scale,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Selamat datang di aplikasi NutriLink x HealthyGo!\n\n',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text:
                                'Sebelum Anda melanjutkan, mohon baca Syarat & Ketentuan layanan kami dengan saksama. '
                                'Dengan mendaftar atau menggunakan aplikasi kami, Anda menyatakan bahwa Anda telah membaca, memahami, dan setuju untuk terikat oleh ketentuan ini.\n\n',
                          ),
                          const TextSpan(
                            text: 'Persetujuan Pengelolaan Data Pribadi\n',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text:
                                'Untuk memberikan rekomendasi nutrisi yang personal dan akurat, aplikasi kami akan mengumpulkan dan memproses data pribadi Anda, '
                                'termasuk namun tidak terbatas pada informasi kesehatan (seperti tujuan diet, alergi, dan data biometrik), serta data akun Anda. '
                                'Kami berkomitmen untuk menjaga kerahasiaan dan keamanan data Anda sesuai dengan standar yang berlaku.\n\n',
                          ),
                          const TextSpan(
                            text: 'Layanan dan Rekomendasi\n',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text:
                                'Layanan dan rekomendasi yang diberikan oleh NutriLink x HealthyGo bersifat informasional dan tidak boleh dianggap sebagai pengganti nasihat medis, diagnosis, atau perawatan profesional. '
                                'Selalu konsultasikan dengan dokter atau ahli gizi Anda sebelum memulai atau membuat perubahan signifikan pada program diet Anda.\n\n'
                                'Aplikasi ini terintegrasi dengan layanan katering HealthyGo. Semua proses pemesanan, pembayaran, dan pengiriman makanan diatur oleh Syarat & Ketentuan yang berlaku dari pihak HealthyGo.\n\n'
                                'Kami dapat memperbarui Syarat & Ketentuan ini dari waktu ke waktu. Kami akan memberitahu Anda tentang perubahan apa pun dengan memposting Syarat & Ketentuan baru di halaman ini.\n\n'
                                'Untuk informasi lebih detail tentang ketentuan dan aplikasi kami silakan baca Syarat & Ketentuan kami dibawah ini.\n\n',
                          ),
                          const TextSpan(text: 'Dengan menekan '),
                          const TextSpan(
                            text: '"Ya, Saya setuju"',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(
                            text:
                                ', Anda memberikan persetujuan eksplisit kepada kami untuk mengelola data Anda sesuai dengan tujuan layanan aplikasi.',
                          ),
                        ],
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),

                // Link "Syarat & Ketentuan" → modal detail
                Positioned(
                  left: fx(49.25),
                  top: fy(667.13),
                  width: fw(291.48),
                  height: fh(13.28),
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => const TermsAndConditionsDetailPage(),
                      );
                    },
                    child: Text(
                      'Syarat & Ketentuan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF196DFD),
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                // Garis pemisah
                Positioned(
                  left: fx(20.1),
                  top: fy(688.58),
                  width: fw(351.79),
                  height: fh(1),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),

                // Tombol "YA"
                Positioned(
                  left: fx(69.35),
                  top: fy(728.43),
                  width: fw(253.29),
                  height: fh(31.80),
                  child: GradientHoverButton(
                    text: 'Ya, Saya setuju',
                    onPressed: () {
                      debugPrint('📍 Navigating from Terms to Name-Input');
                      Navigator.pushNamed(
                        context,
                        '/name-input',
                        arguments: UserProfileDraft(),
                      );
                    },
                    idleBorderColor: gray,
                    idleFillColor: Colors.white,
                    idleTextColor: Colors.black,
                    activeGradientColors: const [greenLight, green],
                    activeTextColor: Colors.white,
                  ),
                ),

                // Tombol "TIDAK" -> balik ke halaman sebelumnya
                Positioned(
                  left: fx(69.35),
                  top: fy(769.32),
                  width: fw(253.29),
                  height: fh(31.80),
                  child: GradientHoverButton(
                    text: 'Tidak, Saya tidak setuju',
                    onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
                    idleBorderColor: gray,
                    idleFillColor: Colors.white,
                    idleTextColor: Colors.black,
                    activeGradientColors: const [greenLight, green],
                    activeTextColor: Colors.white,
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

// Tombol Gradient Hover
class GradientHoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  final Color idleBorderColor;
  final Color idleFillColor;
  final Color idleTextColor;

  final List<Color> activeGradientColors;
  final Color activeTextColor;

  final double borderRadius;
  final double borderWidth;
  final double fontSize;
  final FontWeight fontWeight;
  final Duration duration;

  const GradientHoverButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.idleBorderColor = const Color(0xFFBDBDBD),
    this.idleFillColor = Colors.white,
    this.idleTextColor = Colors.black,
    this.activeGradientColors = const [Color(0xFF7BB662), Color(0xFF5F9C3F)],
    this.activeTextColor = Colors.white,
    this.borderRadius = 8,
    this.borderWidth = 2,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w500,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<GradientHoverButton> createState() => _GradientHoverButtonState();
}

class _GradientHoverButtonState extends State<GradientHoverButton> {
  bool _isHovered = false;
  bool _isPressed = false;

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

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onHighlightChanged: (v) => _setPressed(v),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: widget.duration,
          decoration: BoxDecoration(
            color: active ? null : widget.idleFillColor,
            gradient: active
                ? LinearGradient(
                    colors: widget.activeGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: active
                  ? widget.activeGradientColors.first
                  : widget.idleBorderColor,
              width: widget.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
