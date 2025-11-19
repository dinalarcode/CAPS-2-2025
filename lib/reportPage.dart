import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/services/firebase_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<int, double> _monthlyCalorieLogs = {};
  DailyFoodLogData? _selectedDailyLog;
  MonthlyFoodStats? _monthlyStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load monthly data
      _monthlyCalorieLogs = await FirebaseService.getMonthlyCalorieLogs(_selectedDate);
      
      // Load selected date data
      _selectedDailyLog = await FirebaseService.getDailyFoodLog(_selectedDate);
      
      // Load monthly statistics for favorite food
      _monthlyStats = await FirebaseService.getMonthlyFoodStats(_selectedDate);
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _loadData(); // Reload data for new date
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final int daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator()); // Remove Scaffold
    }

    return SingleChildScrollView( // Remove Scaffold and just return content
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Your app bar should be in HomePage, not here
          // Remove this section if you want to keep the date in HomePage
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              dateFormat.format(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        
          // Section 1: Monthly Calorie Progress Graph
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(daysInMonth, (index) {
                  final int day = index + 1;
                  final bool isHighlighted = day == _selectedDate.day;
                  final double calorie = _monthlyCalorieLogs[day] ?? 0;

                  return _CalorieBar(
                    day: day,
                    calorie: calorie,
                    maxCalorie: 2000,
                    isHighlighted: isHighlighted,
                    onTap: () {
                      _updateSelectedDate(DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        day,
                      ));
                    },
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Nutrition Monitor with Pie Chart
          _NutritionMonitorCard(dailyLog: _selectedDailyLog),
          const SizedBox(height: 16),

          // Section 3 & 4: Daily Calorie Target and Favorite Food
          Row(
            children: [
              // Section 3: Daily Calorie Target
              Expanded(
                child: _DailyTargetCard(
                  dailyLog: _selectedDailyLog,
                ),
              ),
              const SizedBox(width: 16),
            
              // Section 4: Favorite Food
              Expanded(
                child: _FavoriteFoodCard(
                  monthlyStats: _monthlyStats,
                ),
              ),
            ],
          ),
        ],
      ),
    );  
  }
}

// Widget for Section 1: Calorie Bar
class _CalorieBar extends StatelessWidget {
  final int day;
  final double calorie;
  final double maxCalorie;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _CalorieBar({
    required this.day,
    required this.calorie,
    required this.maxCalorie,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double barHeight = (calorie / maxCalorie) * 100;
    final Color barColor = isHighlighted ? Colors.green : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (calorie > 0)
              Text(
                calorie.toInt().toString(),
                style: TextStyle(
                  fontSize: 8,
                  color: isHighlighted ? Colors.green : Colors.grey,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              height: barHeight.clamp(5, 100),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Section 2: Nutrition Monitor Card
class _NutritionMonitorCard extends StatelessWidget {
  final DailyFoodLogData? dailyLog;

  const _NutritionMonitorCard({required this.dailyLog});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monitor Makanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: carbPercent,
                  color: Colors.blue.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: proteinPercent,
                  color: Colors.green.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: fatPercent,
                  color: Colors.orange.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: othersPercent,
                  color: Colors.purple.shade400,
                  title: '',
                  radius: 20,
                ),
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
        _MacroRow(
          color: Colors.blue.shade400,
          title: 'Karbohidrat',
          percent: carbPercent,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.green.shade400,
          title: 'Protein',
          percent: proteinPercent,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.orange.shade400,
          title: 'Lemak',
          percent: fatPercent,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.purple.shade400,
          title: 'Lainnya',
          percent: othersPercent,
        ),
      ],
    );
  }
}

// Helper for macro row
class _MacroRow extends StatelessWidget {
  final Color color;
  final String title;
  final double percent;

  const _MacroRow({
    required this.color,
    required this.title,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(title),
        const Spacer(),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Widget for Section 3: Daily Calorie Target
class _DailyTargetCard extends StatelessWidget {
  final DailyFoodLogData? dailyLog;

  const _DailyTargetCard({required this.dailyLog});

  @override
  Widget build(BuildContext context) {
    final double totalCalories = dailyLog?.totalCalories ?? 0;
    final double dailyTarget = dailyLog?.dailyTarget ?? 2000;
    final double progress = dailyTarget > 0 ? (totalCalories / dailyTarget) * 100 : 0;
    final bool isCompleted = progress >= 100;

    return SizedBox(
      height: 180,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Target Harian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 16),
              if (isCompleted)
                const Text(
                  'Target tercapai! 🎉',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
    );
  }
}

// Widget for Section 4: Favorite Food
class _FavoriteFoodCard extends StatelessWidget {
  final MonthlyFoodStats? monthlyStats;

  const _FavoriteFoodCard({required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    final String foodName = monthlyStats?.favoriteFood.menuName ?? "Belum ada makanan favorit";
    final int count = monthlyStats?.favoriteFood.count ?? 0;
    final double percentage = monthlyStats?.favoriteFood.percentage ?? 0;
    final String imageUrl = "https://via.placeholder.com/300x200"; // Replace with actual image URL

    return SizedBox(
      height: 180,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                foodName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Dipilih $count kali ($percentage% dari total)',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}