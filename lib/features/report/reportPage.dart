import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/services/firebaseService.dart';

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
      debugPrint('Error loading data: $e');
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
      return AppWidgets.loading();
    }

    return SingleChildScrollView( // Remove Scaffold and just return content
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Your app bar should be in HomePage, not here
          // Remove this section if you want to keep the date in HomePage
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              dateFormat.format(_selectedDate),
              style: AppTextStyles.h3,
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
    final Color barColor = isHighlighted ? AppColors.green : AppColors.disabledGrey;

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
                style: AppTextStyles.bodySmall.copyWith(
                  color: isHighlighted ? AppColors.green : AppColors.lightGreyText,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              height: barHeight.clamp(5, 100),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: AppRadius.smallRadius,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              day.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: Container(
        decoration: AppDecorations.card(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitor Makanan',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                style: AppTextStyles.h2,
              ),
              Text(
                'Total kcal',
                style: AppTextStyles.bodySmall,
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
        const SizedBox(width: AppSpacing.sm),
        Text(title),
        const Spacer(),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: AppTextStyles.h5,
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
        child: Container(
          decoration: AppDecorations.card(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target Harian',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: AppSpacing.lg),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppColors.disabledGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? AppColors.green : AppColors.blue,
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      '${totalCalories.toInt()} / ${dailyTarget.toInt()} kcal',
                      style: AppTextStyles.h5,
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Icon(Icons.check_circle, color: AppColors.green, size: 24),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isCompleted)
                  Text(
                    'Target tercapai! 🎉',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    'Masih ${((dailyTarget - totalCalories).toInt())} kcal lagi!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.lightGreyText,
                    ),
                  ),
              ],
            ),
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: AppDecorations.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                child: Container(
                  color: AppColors.disabledGrey,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.image, size: 50, color: AppColors.lightGreyText),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  foodName,
                  style: AppTextStyles.h5,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                child: Text(
                  'Dipilih $count kali ($percentage% dari total)',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
