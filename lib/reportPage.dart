import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/services/schedule_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  double _userTDEE = 2000;
  bool _warningShown = false;
  late ScrollController _chartScrollController;

  @override
  void initState() {
    super.initState();
    _chartScrollController = ScrollController();
    _checkWarningPreference();
    _loadUserTDEE();
    _loadData();
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  // FIX 4: Check if user wants to see warning again
  Future<void> _checkWarningPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShowAgain = prefs.getBool('report_warning_dont_show_again') ?? false;

    if (!dontShowAgain && mounted) {
      _showWarningDialog();
    }
  }

  // FIX 4: Show warning popup with "Don't show again" option
  void _showWarningDialog() {
    if (!_warningShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bool dontShowAgain = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text(
                '⚠️ Informasi Penting',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halaman Laporan ini menampilkan statistik berdasarkan menu yang Anda rencanakan di halaman Jadwal.\n\n'
                    'Menu lain di luar jadwal (seperti makanan yang dicatat via AI Kalori) tidak akan tercermin di sini.\n\n'
                    'Pastikan menu Anda sudah dijadwalkan di halaman Jadwal untuk hasil yang akurat.',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        dontShowAgain = !dontShowAgain;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: dontShowAgain,
                          onChanged: (value) {
                            setDialogState(() {
                              dontShowAgain = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF75C778),
                        ),
                        const Text(
                          'Jangan tampilkan lagi',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (dontShowAgain) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('report_warning_dont_show_again', true);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() => _warningShown = true);
                    }
                  },
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(
                      color: Color(0xFF75C778),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  // FIX 3: Load TDEE from user profile
  Future<void> _loadUserTDEE() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final profile = userDoc.data()?['profile'] as Map<String, dynamic>?;
        if (profile != null) {
          final heightCm = (profile['heightCm'] as num?)?.toDouble() ?? 170;
          final weightKg = (profile['weightKg'] as num?)?.toDouble() ?? 70;
          final sex = profile['sex'] as String? ?? 'Laki-laki';
          final birthDate = (profile['birthDate'] as Timestamp?)?.toDate();
          final activityLevel = profile['activityLevel'] as String? ?? 'lightly_active';

          if (birthDate != null) {
            final age = DateTime.now().difference(birthDate).inDays ~/ 365;

            double bmr;
            if (sex == 'Laki-laki' || sex == 'Male') {
              bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
            } else {
              bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
            }

            const activityMultipliers = {
              'sedentary': 1.2,
              'lightly_active': 1.375,
              'moderately_active': 1.55,
              'very_active': 1.725,
              'extremely_active': 1.9,
            };

            final multiplier = activityMultipliers[activityLevel] ?? 1.375;
            final tdee = bmr * multiplier;

            if (mounted) {
              setState(() {
                _userTDEE = tdee;
              });
            }

            debugPrint('✅ Loaded TDEE from profile: ${tdee.toStringAsFixed(0)} kcal');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user TDEE: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _monthlyCalorieLogs = await _getMonthlyCalorieLogs(_selectedDate);
      _selectedDailyLog = await _getDailyFoodLog(_selectedDate);
      _monthlyStats = await _getMonthlyFoodStats(_selectedDate);
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    setState(() {
      _isLoading = false;
    });

    // FIX 2: Scroll to today's chart after data loads
    _scrollToToday();
  }

  // FIX 2: Scroll to today in the chart
  void _scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScrollController.hasClients) {
        final today = DateTime.now().day;
        final scrollOffset = (today - 1) * 64.0; // 64 = bar width (30) + margins (8*2) + spacing
        _chartScrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<Map<int, double>> _getMonthlyCalorieLogs(DateTime date) async {
    Map<int, double> calorieLogs = {};
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;

    try {
      final futures = <Future<MapEntry<int, double>>>[];

      for (int day = 1; day <= daysInMonth; day++) {
        final targetDate = DateTime(date.year, date.month, day);
        futures.add(
          ScheduleService.getScheduleByDate(targetDate).then((meals) {
            double totalCalories = 0;
            for (var meal in meals) {
              if (meal['isDone'] == true) {
                totalCalories += (meal['calories'] as num?)?.toDouble() ?? 0;
              }
            }
            return MapEntry(day, totalCalories);
          }),
        );
      }

      final results = await Future.wait(futures);
      for (var entry in results) {
        calorieLogs[entry.key] = entry.value;
      }
    } catch (e) {
      debugPrint('Error loading monthly calories: $e');
    }

    return calorieLogs;
  }

  // FIX 1: Ensure macro percentages are calculated correctly
  Future<DailyFoodLogData?> _getDailyFoodLog(DateTime date) async {
    try {
      debugPrint('📊 Loading daily food log for: ${DateFormat('yyyy-MM-dd').format(date)}');

      final meals = await ScheduleService.getScheduleByDate(date);
      final consumedMeals = meals.where((meal) => meal['isDone'] == true).toList();

      debugPrint('   Found ${consumedMeals.length} consumed meals');

      if (consumedMeals.isEmpty) {
        debugPrint('   No consumed meals found, returning empty log');
        return DailyFoodLogData(
          totalCalories: 0,
          dailyTarget: _userTDEE,
          protein: 0,
          carbs: 0,
          fat: 0,
          proteinPercent: 0,
          carbPercent: 0,
          fatPercent: 0,
        );
      }

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var meal in consumedMeals) {
        totalCalories += (meal['calories'] as num?)?.toDouble() ?? 0;
        totalProtein += (meal['protein'] as num?)?.toDouble() ?? 0;
        totalCarbs += (meal['carbs'] as num?)?.toDouble() ?? 0;
        totalFat += (meal['fat'] as num?)?.toDouble() ?? 0;
      }


      // FIX 1: Calculate percentages correctly based on calories
      // Macronutrient calories: Protein & Carbs = 4 kcal/g, Fat = 9 kcal/g
      double proteinCalories = totalProtein * 4;
      double carbCalories = totalCarbs * 4;
      double fatCalories = totalFat * 9;
      double totalMacroCalories = proteinCalories + carbCalories + fatCalories;

      double proteinPercent = totalMacroCalories > 0
          ? (proteinCalories / totalMacroCalories) * 100
          : 0;
      double carbPercent = totalMacroCalories > 0
          ? (carbCalories / totalMacroCalories) * 100
          : 0;
      double fatPercent = totalMacroCalories > 0
          ? (fatCalories / totalMacroCalories) * 100
          : 0;

      debugPrint(
          '   TOTALS - Cal: $totalCalories, P: $totalProtein (${proteinPercent.toStringAsFixed(1)}%), C: $totalCarbs (${carbPercent.toStringAsFixed(1)}%), F: $totalFat (${fatPercent.toStringAsFixed(1)}%)');

      return DailyFoodLogData(
        totalCalories: totalCalories,
        dailyTarget: _userTDEE,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        proteinPercent: proteinPercent,
        carbPercent: carbPercent,
        fatPercent: fatPercent,
      );
    } catch (e) {
      debugPrint('Error loading daily food log: $e');
      return null;
    }
  }

  Future<MonthlyFoodStats?> _getMonthlyFoodStats(DateTime date) async {
    try {
      final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
      Map<String, int> foodCountMap = {};

      final futures = <Future<void>>[];

      for (int day = 1; day <= daysInMonth; day++) {
        final targetDate = DateTime(date.year, date.month, day);
        futures.add(
          ScheduleService.getScheduleByDate(targetDate).then((meals) {
            for (var meal in meals) {
              if (meal['isDone'] == true) {
                final foodName = meal['name'] as String? ?? 'Unknown';
                foodCountMap[foodName] = (foodCountMap[foodName] ?? 0) + 1;
              }
            }
          }),
        );
      }

      await Future.wait(futures);

      if (foodCountMap.isEmpty) {
        return MonthlyFoodStats(
          favoriteFood: FavoriteFoodData(
            menuName: 'Belum ada makanan favorit',
            count: 0,
            percentage: 0,
          ),
        );
      }

      String favoriteFoodName = '';
      int maxCount = 0;
      int totalCount = 0;

      for (var entry in foodCountMap.entries) {
        totalCount += entry.value;
        if (entry.value > maxCount) {
          maxCount = entry.value;
          favoriteFoodName = entry.key;
        }
      }

      final percentage = totalCount > 0 ? (maxCount / totalCount) * 100 : 0.0;

      return MonthlyFoodStats(
        favoriteFood: FavoriteFoodData(
          menuName: favoriteFoodName,
          count: maxCount,
          percentage: percentage,
        ),
      );
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
      return null;
    }
  }

  void _updateSelectedDate(DateTime newDate) {
    debugPrint(
        '📅 Updating selected date to: ${DateFormat('yyyy-MM-dd').format(newDate)}');
    setState(() {
      _selectedDate = newDate;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final int daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              controller: _chartScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(daysInMonth, (index) {
                  final int day = index + 1;
                  final bool isHighlighted = day == _selectedDate.day;
                  final double calorie = _monthlyCalorieLogs[day] ?? 0;

                  return _CalorieBar(
                    day: day,
                    calorie: calorie,
                    maxCalorie: _userTDEE,
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
              Expanded(
                child: _DailyTargetCard(
                  dailyLog: _selectedDailyLog,
                  tdee: _userTDEE,
                ),
              ),
              const SizedBox(width: 16),
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

// Widget for Calorie Bar (Section 1)
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
    final double heightPercent = (calorie / maxCalorie).clamp(0, 1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              calorie.toInt().toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 80 * heightPercent,
              decoration: BoxDecoration(
                color: isHighlighted ? Colors.green : Colors.blue.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day.toString(),
              style: const TextStyle(fontSize: 10),
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
                Expanded(
                  flex: 2,
                  child: _buildPieChart(context),
                ),
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
                  value: carbPercent > 0 ? carbPercent : 0.1,
                  color: Colors.blue.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: proteinPercent > 0 ? proteinPercent : 0.1,
                  color: Colors.green.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: fatPercent > 0 ? fatPercent : 0.1,
                  color: Colors.orange.shade400,
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
    final double carbGrams = dailyLog?.carbs ?? 0;
    final double proteinGrams = dailyLog?.protein ?? 0;
    final double fatGrams = dailyLog?.fat ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MacroRow(
          color: Colors.blue.shade400,
          title: 'Karbohidrat',
          percent: carbPercent,
          grams: carbGrams,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.green.shade400,
          title: 'Protein',
          percent: proteinPercent,
          grams: proteinGrams,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.orange.shade400,
          title: 'Lemak',
          percent: fatPercent,
          grams: fatGrams,
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
  final double grams;

  const _MacroRow({
    required this.color,
    required this.title,
    required this.percent,
    required this.grams,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                '${grams.toStringAsFixed(1)}g',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}

// Widget for Section 3: Daily Calorie Target
class _DailyTargetCard extends StatelessWidget {
  final DailyFoodLogData? dailyLog;
  final double tdee;

  const _DailyTargetCard({
    required this.dailyLog,
    required this.tdee,
  });

  @override
  Widget build(BuildContext context) {
    final double totalCalories = dailyLog?.totalCalories ?? 0;
    final double dailyTarget = tdee;
    final double progress =
        dailyTarget > 0 ? (totalCalories / dailyTarget) * 100 : 0;
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
                value: (progress / 100).clamp(0, 1),
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
                    '${totalCalories.toInt()} / ${dailyTarget.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                      color: Colors.green, fontWeight: FontWeight.bold),
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
    final String foodName =
        monthlyStats?.favoriteFood.menuName ?? "Belum ada makanan favorit";
    final int count = monthlyStats?.favoriteFood.count ?? 0;
    final double percentage = monthlyStats?.favoriteFood.percentage ?? 0;

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
                'Makanan Favorit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      foodName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dipilih $count kali',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}% dari total',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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

// Data Models
class DailyFoodLogData {
  final double totalCalories;
  final double dailyTarget;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinPercent;
  final double carbPercent;
  final double fatPercent;

  DailyFoodLogData({
    required this.totalCalories,
    required this.dailyTarget,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinPercent,
    required this.carbPercent,
    required this.fatPercent,
  });
}

class MonthlyFoodStats {
  final FavoriteFoodData favoriteFood;

  MonthlyFoodStats({required this.favoriteFood});
}

class FavoriteFoodData {
  final String menuName;
  final int count;
  final double percentage;

  FavoriteFoodData({
    required this.menuName,
    required this.count,
    required this.percentage,
  });
}