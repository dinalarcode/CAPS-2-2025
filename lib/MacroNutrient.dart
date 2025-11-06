import 'package:flutter/material.dart';
import 'constants.dart';
import 'EatHourCalculationPage.dart';

class MacroNutrientCalculationPage extends StatelessWidget {
  final double bmr;
  final double tdee;

  const MacroNutrientCalculationPage({
    super.key,
    required this.bmr,
    required this.tdee,
  });

  Widget _buildMacroCard(
    String title,
    String value,
    String range,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
              child: Text(
                'g',
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(range, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black54),
            onPressed: () {
              // TODO: Show help dialog
            },
          ),
        ],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/NutriLinkLogo.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'Perhitungan Makro Nutrisi',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Berdasarkan data Anda, target makronutrien untuk mendukung tujuan Anda adalah:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kAccentGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildMacroCard(
                            'Protein',
                            '${(tdee * 0.3 / 4).round()}',
                            '(${(tdee * 0.25 / 4).round()} - ${(tdee * 0.35 / 4).round()}g)',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMacroCard(
                            'Karbohidrat',
                            '${(tdee * 0.5 / 4).round()}',
                            '(${(tdee * 0.45 / 4).round()} - ${(tdee * 0.65 / 4).round()}g)',
                            kAccentGreen,
                          ),
                        ),
                        Expanded(
                          child: _buildMacroCard(
                            'Lemak',
                            '${(tdee * 0.2 / 9).round()}',
                            '(${(tdee * 0.15 / 9).round()} - ${(tdee * 0.25 / 9).round()}g)',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Per hari',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EatHourCalculationPage(
                        wakeTime: const TimeOfDay(hour: 6, minute: 0),
                        bedTime: const TimeOfDay(hour: 22, minute: 0),
                        mealsPerDay: 3,
                        bmr: bmr,
                        tdee: tdee,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentGreen,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lanjutkan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Kembali',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
