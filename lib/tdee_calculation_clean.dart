import 'package:flutter/material.dart';
import 'constants.dart';
import 'NutritionCalculation_ProfileRecap.dart';

class TDEECalculationPage extends StatefulWidget {
  final double bmr;
  const TDEECalculationPage({super.key, required this.bmr});

  @override
  State<TDEECalculationPage> createState() => _TDEECalculationPageState();
}

class _TDEECalculationPageState extends State<TDEECalculationPage> {
  double? tdee;
  int _selectedActivityIndex = -1;

  final List<Map<String, dynamic>> activityLevels = const [
    {'label': 'Sangat Rendah', 'value': 1.2},
    {'label': 'Rendah', 'value': 1.375},
    {'label': 'Sedang', 'value': 1.465},
    {'label': 'Tinggi', 'value': 1.55},
    {'label': 'Sangat Tinggi', 'value': 1.725},
    {'label': 'Sangat Sangat Tinggi', 'value': 1.9},
  ];

  void calculateTDEE() {
    if (_selectedActivityIndex != -1) {
      double activityFactor =
          activityLevels[_selectedActivityIndex]['value'] as double;
      setState(() {
        tdee = widget.bmr * activityFactor;
      });
    }
  }

  Widget _buildFormulaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAccentGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Rumus Mifflin-St Jeor untuk pria:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'BMR Anda: ${widget.bmr.toStringAsFixed(1)} kal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kAccentGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TDEE = BMR × Faktor Aktivitas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityLevels(),
        ],
      ),
    );
  }

  Widget _buildActivityLevels() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Faktor Aktivitas:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            activityLevels.length,
            (index) => _buildActivityLevel(
              activityLevels[index]['label'] as String,
              activityLevels[index]['value'] as double,
              index == _selectedActivityIndex,
              index,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevel(
    String label,
    double value,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedActivityIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kAccentGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kAccentGreen : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? kAccentGreen : Colors.transparent,
                border: Border.all(
                  color: isSelected ? kAccentGreen : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pengali: ${value.toStringAsFixed(3)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kAccentGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Perhitungan TDEE',
          style: TextStyle(color: kAccentGreen, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(),
              const SizedBox(height: 24),
              if (tdee != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kAccentGreen,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Daily Energy Expenditure Anda',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${tdee!.toStringAsFixed(1)} kal',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (_selectedActivityIndex != -1)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tdee == null ? kAccentGreen : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (tdee == null) {
                      calculateTDEE();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NutritionCalculationProfileRecap(
                                bmr: widget.bmr,
                                tdee: tdee!,
                              ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    tdee == null ? 'Hitung TDEE' : 'Lanjutkan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
