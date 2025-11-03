
                          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: kAccentGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: kAccentGreen.withOpacity(0.14))), child: Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_fire_department, color: Colors.orange, size: 26), const SizedBox(width: 12), Text(_bmrValue.toStringAsFixed(0), style: TextStyle(color: kAccentGreen, fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(width: 8), Text('kalori', style: TextStyle(color: kAccentGreen.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600))]), const SizedBox(height: 10), Text('Target harian minimal Anda', style: TextStyle(color: Colors.grey[700]))]),
                        ]),
                      ),

                      const SizedBox(height: 18),

                      _infoCard('Apa itu BMR?', 'BMR adalah jumlah kalori yang diperlukan tubuh untuk fungsi dasar saat istirahat.'),

                      const SizedBox(height: 12),

                      Row(children: [
                        Expanded(child: SizedBox(height: 56, child: OutlinedButton(onPressed: () => Navigator.of(context).maybePop(), style: OutlinedButton.styleFrom(side: BorderSide(color: kAccentGreen.withOpacity(0.9), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_back_rounded, color: kAccentGreen), const SizedBox(width: 8), const Text('Kembali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]))),
                        const SizedBox(width: 12),
                        Expanded(child: SizedBox(height: 56, child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/tdee'), style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded)])))),
                      ]),

                      const SizedBox(height: 18),
                    ]),
                  ),
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
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'constants.dart';

/// Clean, single-definition BMR calculation page.
class BMRCalculationPage extends StatefulWidget {
  const BMRCalculationPage({Key? key}) : super(key: key);

  @override
  State<BMRCalculationPage> createState() => _BMRCalculationPageState();
}

class _BMRCalculationPageState extends State<BMRCalculationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _triangleDown(Color color, {double width = 120, double height = 36}) {
    return CustomPaint(
      size: Size(width, height),
      painter: _TrianglePainter(color),
    );
  }

  Widget _infoCard(String title, String body) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _showInfo = !_showInfo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: kAccentGreen, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            if (_showInfo) ...[
              const SizedBox(height: 8),
              Text(body, style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  import 'package:flutter/material.dart';

                  import 'constants.dart';

                  /// Clean, single implementation of the BMR calculation page.
                  class BMRCalculationPage extends StatefulWidget {
                    const BMRCalculationPage({Key? key}) : super(key: key);

                    @override
                    State<BMRCalculationPage> createState() => _BMRCalculationPageState();
                  }

                  class _BMRCalculationPageState extends State<BMRCalculationPage>
                      with SingleTickerProviderStateMixin {
                    late final AnimationController _ctrl;
                    late final Animation<double> _fade;
                    late final Animation<Offset> _slide;
                    bool _showInfo = false;

                    // Example result value. The UI shows the value — calculation wiring is out of scope.
                    final double _bmrValue = 1733;

                    @override
                    void initState() {
                      super.initState();
                      _ctrl = AnimationController(
                        vsync: this,
                        duration: const Duration(milliseconds: 650),
                      );
                      _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
                      _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
                        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                      );
                      _ctrl.forward();
                    }

                    @override
                    void dispose() {
                      _ctrl.dispose();
                      super.dispose();
                    }

                    Widget _triangleDown(Color color, {double width = 120, double height = 36}) {
                      return CustomPaint(
                        size: Size(width, height),
                        painter: _TrianglePainter(color),
                      );
                    }

                    Widget _infoCard(String title, String body) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _showInfo = !_showInfo),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: kAccentGreen, size: 18),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Apa itu BMR?',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              if (_showInfo) ...[
                                const SizedBox(height: 8),
                                Text(body, style: TextStyle(color: Colors.grey[700], height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    @override
                    Widget build(BuildContext context) {
                      final mq = MediaQuery.of(context);

                      return Scaffold(
                        backgroundColor: Colors.grey[50],
                        body: SafeArea(
                          child: Column(
                            children: [
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.arrow_back_ios_new),
                                        color: kAccentGreen,
                                        onPressed: () => Navigator.of(context).maybePop(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Image.asset('assets/images/NutriLinkLogo.png', fit: BoxFit.contain),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Perhitungan BMR',
                                        style: TextStyle(
                                          color: kAccentGreen,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  child: FadeTransition(
                                    opacity: _fade,
                                    child: SlideTransition(
                                      position: _slide,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [kAccentGreen.withOpacity(0.12), Colors.white],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Perhitungan Kebutuhan Energi',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: kAccentGreen,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'BMR (Basal Metabolic Rate)',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 18),

                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 6),
                                                )
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: kAccentGreen.withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Icon(Icons.calculate, color: kAccentGreen),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Rumus Mifflin-St Jeor (contoh)',
                                                        style: TextStyle(color: kAccentGreen, fontWeight: FontWeight.w700),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: kAccentGreen.withOpacity(0.08)),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.functions, size: 18, color: kAccentGreen),
                                                          const SizedBox(width: 8),
                                                          Text('Formula', style: TextStyle(color: kAccentGreen, fontWeight: FontWeight.w600)),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Pria: 10 × berat(kg) + 6.25 × tinggi(cm) - 5 × usia + 5\nWanita: 10 × berat(kg) + 6.25 × tinggi(cm) - 5 × usia - 161',
                                                        style: TextStyle(color: Colors.grey[800]),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '* Gunakan data profil untuk hasil akurat',
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(height: 14),

                                                Center(
                                                  child: _triangleDown(kAccentGreen.withOpacity(0.95), width: mq.size.width * 0.5, height: 36),
                                                ),

                                                const SizedBox(height: 12),

                                                const Text('Hasil Perhitungan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),

                                                const SizedBox(height: 10),

                                                Container(
                                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                                  decoration: BoxDecoration(
                                                    color: kAccentGreen,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          const Text('Kebutuhan Kalori (BMR)', style: TextStyle(color: Colors.white70)),
                                                          const SizedBox(height: 6),
                                                          Text('${_bmrValue.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                                        ],
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kAccentGreen),
                                                        onPressed: () => Navigator.of(context).pushNamed('/tdee'),
                                                        child: const Text('Lanjut ke TDEE'),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(height: 12),

                                                _infoCard('Apa itu BMR?', 'BMR adalah jumlah kalori yang diperlukan tubuh untuk fungsi dasar saat istirahat.'),

                                                const SizedBox(height: 8),

                                                _infoCard('Catatan', 'Hasil adalah estimasi. Gunakan data profil (berat, tinggi, usia, jenis kelamin) untuk hasil yang valid.'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                      final path = Path()..moveTo(0, 0)..lineTo(size.width / 2, size.height)..lineTo(size.width, 0)..close();
                      canvas.drawPath(path, paint);
                    }

                    @override
                    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
                  }

                                onPressed: () => Navigator.pushNamed(context, '/tdee'),
                                style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded)]),
                              ),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
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
import 'package:flutter/material.dart';
import 'constants.dart';

class BMRCalculationPage extends StatefulWidget {
  const BMRCalculationPage({Key? key}) : super(key: key);

  @override
  State<BMRCalculationPage> createState() => _BMRCalculationPageState();
}

class _BMRCalculationPageState extends State<BMRCalculationPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _showInfo = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _triangleDown(Color color, {double width = 120, double height = 40}) {
    return CustomPaint(
      size: Size(width, height),
      painter: _TrianglePainter(color),
    );
  }

  Widget _buildCalculationStep(String step, String text, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isLast ? kAccentGreen : kAccentGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: isLast ? Colors.white : kAccentGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isLast ? kAccentGreen : Colors.grey[800],
              height: 1.4,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _showInfo = !_showInfo);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: kAccentGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_showInfo) ...[
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: kAccentGreen,
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Kembali',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.asset(
                        'assets/images/NutriLinkLogo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Perhitungan BMR',
                        style: TextStyle(
                          color: kAccentGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Hero(
                      tag: 'bmr_title',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                kAccentGreen.withOpacity(0.15),
                                kAccentGreen.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Perhitungan Kebutuhan Energi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kAccentGreen.withOpacity(0.95),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'BMR (Basal Metabolic Rate)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: kAccentGreen.withOpacity(0.03),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: kAccentGreen.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kAccentGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calculate,
                                  color: kAccentGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Rumus Mifflin-St Jeor untuk pria',
                                  style: TextStyle(
                                    color: kAccentGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kAccentGreen.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.functions,
                                      size: 18,
                                      color: kAccentGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Formula BMR',
                                      style: TextStyle(
                                        color: kAccentGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'BMR = (10 × berat badan dalam kg) + (6,25 × tinggi badan dalam cm) – (5 × usia dalam tahun) + 5',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '* Formula Mifflin-St Jeor yang direkomendasikan oleh ahli gizi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          Center(
                            child: _triangleDown(
                              kAccentGreen.withOpacity(0.95),
                              width: mq.size.width * 0.45,
                              height: 40,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Hasil Perhitungan',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  kAccentGreen.withOpacity(0.08),
                                  Colors.grey[50]!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kAccentGreen.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calculate_outlined,
                                      size: 18,
                                      color: kAccentGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Kalkulasi',
                                      style: TextStyle(
                                        color: kAccentGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildCalculationStep(
                                            '1',
                                            'BMR = (10 × 77) + (6,25 × 170) – (5 × 21) + 5',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildCalculationStep(
                                            '2',
                                            'BMR = 770 + 1062,5 – 105 + 5',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildCalculationStep(
                                            '3',
                                            'BMR = 1732,5 kal',
                                            isLast: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          Center(
                            child: Text(
                              'Jadi, BMR Anda adalah',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: kAccentGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: kAccentGreen.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kAccentGreen.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orange,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '1733',
                                        style: TextStyle(
                                          color: kAccentGreen,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'kalori',
                                        style: TextStyle(
                                          color: kAccentGreen.withOpacity(0.8),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '🎯',
                                        style: TextStyle(
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Target harian minimal Anda',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    _buildInfoCard(
                      'Apa itu BMR?',
                      'BMR (Basal Metabolic Rate) adalah jumlah kalori minimum yang dibutuhkan tubuh untuk menjalankan fungsi vital seperti pernapasan, sirkulasi darah, dan pemeliharaan organ saat istirahat total.',
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: kAccentGreen.withOpacity(0.9),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back_rounded,
                                    color: kAccentGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Kembali',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/tdee'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccentGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: kAccentGreen.withOpacity(0.25),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Lanjutkan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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

