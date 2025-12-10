import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:nutrilink/services/firebaseService.dart'; 

void main() {
  group('Report Page Widgets Test', () {
    
    // Test Case 1: Kartu Target Harian
    testWidgets('DailyTargetCard displays correct calorie progress', (WidgetTester tester) async {
      final dummyLog = DailyFoodLogData(
        totalCalories: 1500,
        dailyTarget: 2000,
        carbPercent: 50, 
        proteinPercent: 30, 
        fatPercent: 20, 
        othersPercent: 0,
        foods: [], 
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TestableDailyTargetCard(dailyLog: dummyLog), 
        ),
      ));

      expect(find.text('Target Harian'), findsOneWidget);
      expect(find.text('1500 / 2000 kcal'), findsOneWidget);
      expect(find.text('Target tercapai! 🎉'), findsNothing);
      expect(find.textContaining('Masih 500 kcal lagi'), findsOneWidget);
    });

    // Test Case 2: Kartu Monitor Nutrisi (Pie Chart)
    testWidgets('NutritionMonitorCard displays macro percentages', (WidgetTester tester) async {
      final dummyLog = DailyFoodLogData(
        totalCalories: 2000,
        dailyTarget: 2000,
        carbPercent: 50,    
        proteinPercent: 30, 
        fatPercent: 20,     
        othersPercent: 0,
        foods: [],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TestableNutritionMonitorCard(dailyLog: dummyLog),
        ),
      ));

      expect(find.text('Monitor Makanan'), findsOneWidget);
      expect(find.text('Karbohidrat'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget); 
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget); 
    });
  });
}

// ==========================================================================
// MOCK WIDGETS (Testable Classes)
// ==========================================================================

class TestableDailyTargetCard extends StatelessWidget {
  final DailyFoodLogData? dailyLog;

  // PERBAIKAN: Menambahkan key ke constructor
  const TestableDailyTargetCard({super.key, required this.dailyLog});

  @override
  Widget build(BuildContext context) {
    final double totalCalories = dailyLog?.totalCalories ?? 0;
    final double dailyTarget = dailyLog?.dailyTarget ?? 2000;
    final double progress = dailyTarget > 0 ? (totalCalories / dailyTarget) * 100 : 0;
    final bool isCompleted = progress >= 100;

    return SizedBox(
      height: 180,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Harian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${totalCalories.toInt()} / ${dailyTarget.toInt()} kcal',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ],
                ),
                const SizedBox(height: 16),
                if (isCompleted)
                  const Text(
                    'Target tercapai! 🎉',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    'Masih ${((dailyTarget - totalCalories).toInt())} kcal lagi!',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TestableNutritionMonitorCard extends StatelessWidget {
  final DailyFoodLogData? dailyLog;

  // PERBAIKAN: Menambahkan key ke constructor
  const TestableNutritionMonitorCard({super.key, required this.dailyLog});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitor Makanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 2,
                    child: _buildPieChart(context),
                  ),
                  // List Makro
                  Expanded(
                    flex: 3,
                    child: _buildMacroList(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final double totalCalories = dailyLog?.totalCalories ?? 0;
    final double carbPercent = dailyLog?.carbPercent ?? 0;
    final double proteinPercent = dailyLog?.proteinPercent ?? 0;
    final double fatPercent = dailyLog?.fatPercent ?? 0;
    final double othersPercent = dailyLog?.othersPercent ?? 0;

    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                totalCalories.toInt().toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Total kcal',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(value: carbPercent, color: Colors.blue, radius: 20, showTitle: false),
                PieChartSectionData(value: proteinPercent, color: Colors.green, radius: 20, showTitle: false),
                PieChartSectionData(value: fatPercent, color: Colors.orange, radius: 20, showTitle: false),
                PieChartSectionData(value: othersPercent, color: Colors.purple, radius: 20, showTitle: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroList(BuildContext context) {
    final double carbPercent = dailyLog?.carbPercent ?? 0;
    final double proteinPercent = dailyLog?.proteinPercent ?? 0;
    final double fatPercent = dailyLog?.fatPercent ?? 0;
    final double othersPercent = dailyLog?.othersPercent ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MacroRow(color: Colors.blue, title: 'Karbohidrat', percent: carbPercent),
        const SizedBox(height: 8),
        _MacroRow(color: Colors.green, title: 'Protein', percent: proteinPercent),
        const SizedBox(height: 8),
        _MacroRow(color: Colors.orange, title: 'Lemak', percent: fatPercent),
        const SizedBox(height: 8),
        _MacroRow(color: Colors.purple, title: 'Lainnya', percent: othersPercent),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final Color color;
  final String title;
  final double percent;

  const _MacroRow({required this.color, required this.title, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}