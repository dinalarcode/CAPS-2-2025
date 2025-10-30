import 'package:flutter/material.dart';
import 'constants.dart';

class BMRCalculationPage extends StatelessWidget {
  const BMRCalculationPage({super.key});

  Widget _triangleDown(Color color, {double width = 120, double height = 40}) {
    return CustomPaint(
      size: Size(width, height),
      painter: _TrianglePainter(color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header: same style as other pages (back, logo, left title)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back),
                        color: kAccentGreen,
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Kembali',
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/images/NutriLinkLogo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Perhitungan Kebutuhan Energi BMR (Basal Metabolic Rate)',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: kAccentGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Big Title
                    Text(
                      'Perhitungan\nKebutuhan Energi\nBMR (Basal Metabolic Rate)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kAccentGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Card with border and inner content
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kAccentGreen, width: 2),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rumus Mifflin-St Jeor untuk pria:',
                              style: TextStyle(
                                color: kAccentGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'BMR = (10 × berat badan dalam kg) +\n(6,25 × tinggi badan dalam cm) –\n(5 × usia dalam tahun) + 5',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Decorative triangle
                          Center(
                            child: _triangleDown(
                              kAccentGreen,
                              width: 160,
                              height: 50,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Hasil Perhitungan',
                              style: TextStyle(
                                color: kAccentGreen,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'BMR = (10 × 77) + (6,25 × 170) – (5 × 21) + 5\nBMR = 770 + 1062,5 – 105 + 5\nBMR = 1732,5 kal',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Center(
                            child: _triangleDown(
                              kAccentGreen,
                              width: 160,
                              height: 50,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Jadi, BMR Anda adalah\n1733 kalori 🎉',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kAccentGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/tdee');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: kAccentGreen, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kembali',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
