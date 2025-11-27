// 🚀 FULL Revised SchedulePage.dart (Dynamic Menu + Firebase Storage + Date After Today Only)
// Pastikan kamu sudah punya storageHelper.dart dengan buildImageUrl()

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/utils/storageHelper.dart';
import 'package:nutrilink/services/scheduleService.dart';
import 'package:nutrilink/services/notificationService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Dummy data meals yang akan ditampilkan
  List<Map<String, dynamic>> scheduledMeals = [];

  // AI Food Logs untuk tanggal yang dipilih
  List<Map<String, dynamic>> aiFoodLogs = [];

  // ScrollController untuk calendar
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadMealsFromCache();
    loadAIFoodLogs();
    _scheduleNotificationsForLoadedMeals();
    // Scroll ke hari ini setelah widget di-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  // Function untuk scroll ke tanggal hari ini
  void _scrollToToday() {
    final now = DateTime.now();
    if (selectedMonth == now.month && selectedYear == now.year) {
      final dayIndex = now.day - 1; // 0-based index
      final scrollOffset = dayIndex * 60.0; // 60 = width (56) + margin (4*2)

      if (_calendarScrollController.hasClients) {
        _calendarScrollController.animateTo(
          scrollOffset,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Helper function untuk check apakah tanggal = hari ini
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Load meals dari Firestore menggunakan ScheduleService
  Future<void> loadMealsFromCache() async {
    try {
      debugPrint(
          '🔍 Loading meals for: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');

      final meals = await ScheduleService.getScheduleByDate(selectedDate);

      setState(() {
        scheduledMeals = meals;
      });

      if (meals.isEmpty) {
        debugPrint('⚠️ No meals found for this date');
      } else {
        debugPrint('✅ Loaded ${meals.length} meals from Firestore');
        // Debug: Print each meal's clock field
        for (var i = 0; i < meals.length; i++) {
          final meal = meals[i];
          debugPrint(
              '   Meal ${i + 1}: ${meal['name']} - time: ${meal['time']}, clock: ${meal['clock']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading meals: $e');
      if (mounted) {
        setState(() {
          scheduledMeals = [];
        });
      }
    }
  }

  // Load AI Food Logs dari Firestore untuk tanggal yang dipilih
  Future<void> loadAIFoodLogs() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
      debugPrint('🤖 Loading AI food logs for: $dateKey');

      final logDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_food_logs')
          .doc(dateKey)
          .get();

      if (logDoc.exists && mounted) {
        final data = logDoc.data()!;
        final meals =
            (data['meals'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                [];

        setState(() {
          aiFoodLogs = meals;
        });

        debugPrint('✅ Loaded ${meals.length} AI food logs');
      } else {
        if (mounted) {
          setState(() {
            aiFoodLogs = [];
          });
        }
        debugPrint('⚠️ No AI food logs found for this date');
      }
    } catch (e) {
      debugPrint('❌ Error loading AI food logs: $e');
      if (mounted) {
        setState(() {
          aiFoodLogs = [];
        });
      }
    }
  }

  // Function untuk save checklist menggunakan ScheduleService
  Future<void> saveChecklistToFirestore(int index, bool value) async {
    try {
      // Update local state immediately for responsive UI
      setState(() {
        scheduledMeals[index]['isDone'] = value;
      });

      // Save to Firestore
      final success =
          await ScheduleService.markMealAsDone(selectedDate, index, value);

      if (success) {
        debugPrint('✅ Checklist updated successfully');
      } else {
        debugPrint('⚠️ Failed to update checklist');
        // Revert local state if failed
        setState(() {
          scheduledMeals[index]['isDone'] = !value;
        });
      }
    } catch (e) {
      debugPrint('❌ Error saving checklist: $e');
      // Revert local state on error
      setState(() {
        scheduledMeals[index]['isDone'] = !value;
      });
    }
  }

  // Schedule notifications when meals are loaded
  Future<void> _scheduleNotificationsForLoadedMeals() async {
    try {
      debugPrint('🔔 Scheduling notifications for loaded meals');

      // Schedule notifications for tomorrow's meals (since today's won't have time)
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);

      // Try to get tomorrow's meals from Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final scheduleDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('schedule')
            .doc(tomorrowStr)
            .get();

        if (scheduleDoc.exists && scheduleDoc.data()?['meals'] != null) {
          final meals = List<Map<String, dynamic>>.from(
              (scheduleDoc.data()!['meals'] as List<dynamic>)
                  .map((m) => Map<String, dynamic>.from(m)));

          await NotificationService.scheduleAllMealNotifications(
            date: tomorrow,
            meals: meals,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header dengan pemilihan bulan dan kalender
          _buildMonthSelector(),
          _buildCalendarWeek(),
          SizedBox(height: 8),
          // Title Jadwal Makan dengan tombol Hari Ini
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Jadwal Makan",
                  style: AppTextStyles.h2,
                ),
                Row(
                  children: [
                    // Tombol Hari Ini (dinamis)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime.now();
                          selectedMonth = DateTime.now().month;
                          selectedYear = DateTime.now().year;
                          loadMealsFromCache();
                          loadAIFoodLogs();
                        });
                        // Scroll ke hari ini
                        _scrollToToday();
                      },
                      icon: Icon(Icons.today, color: AppColors.green, size: 20),
                      label: Text(
                        _isToday(selectedDate)
                            ? 'Hari Ini'
                            : 'Pergi ke Hari Ini',
                        style: AppTextStyles.buttonSmall
                            .copyWith(color: AppColors.green),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        backgroundColor: AppColors.green.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smallRadius,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // DEBUG: Re-populate button
                    IconButton(
                      onPressed: () async {
                        if (!mounted) return;
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                              content: Text(
                                  '🔄 Re-populating schedules from orders...')),
                        );
                        final success =
                            await ScheduleService.repopulateAllSchedules();
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? '✅ Schedule re-population complete!'
                                : '❌ Failed to re-populate schedules'),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                        if (success) {
                          loadMealsFromCache();
                        }
                      },
                      icon: const Icon(Icons.refresh, color: AppColors.green),
                      tooltip: 'Re-populate schedules',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // List of scheduled meals + AI food logs
          Expanded(
            child: (scheduledMeals.isEmpty && aiFoodLogs.isEmpty)
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxxl * 1.25),
                    child: AppWidgets.emptyState(
                      message: "Belum ada jadwal makan untuk tanggal ini",
                      icon: Icons.calendar_today_outlined,
                    ),
                  )
                : ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    children: [
                      // Regular scheduled meals
                      if (scheduledMeals.isNotEmpty)
                        ...scheduledMeals.asMap().entries.map((entry) {
                          return MealScheduleCard(
                            meal: entry.value,
                            selectedDate: selectedDate,
                            onCheckChanged: (value) {
                              saveChecklistToFirestore(
                                  entry.key, value ?? false);
                            },
                          );
                        }),

                      // AI Food Logs Section
                      if (aiFoodLogs.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        // Header "Makanan Tambahan"
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.md,
                            bottom: AppSpacing.lg,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fastfood,
                                color: AppColors.green,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Makanan Tambahan',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // AI Food Log Cards
                        ...aiFoodLogs.map((log) {
                          return AIFoodLogCard(
                            log: log,
                            selectedDate: selectedDate,
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🟡 MONTH SELECTOR DROPDOWN
  // ===============================
  Widget _buildMonthSelector() {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.green, width: 2),
          borderRadius: AppRadius.mediumRadius,
        ),
        child: DropdownButton<int>(
          value: selectedMonth,
          isExpanded: true,
          underline: const SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.green),
          style: AppTextStyles.h4.copyWith(color: AppColors.black),
          items: List.generate(12, (index) {
            return DropdownMenuItem(
              value: index + 1,
              child: Text(months[index]),
            );
          }),
          onChanged: (value) {
            setState(() {
              selectedMonth = value!;
              selectedDate =
                  DateTime(selectedYear, selectedMonth, selectedDate.day);
            });
            loadMealsFromCache(); // Reload meals for new month
            loadAIFoodLogs(); // Reload AI food logs for new month
          },
        ),
      ),
    );
  }

  // ===============================
  // 🟡 CALENDAR WEEK VIEW
  // ===============================
  Widget _buildCalendarWeek() {
    final daysOfWeek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final now = DateTime.now();
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          // Days grid - Scrollable horizontal dengan nama hari
          SizedBox(
            height: 90,
            child: ListView.builder(
              controller: _calendarScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(selectedYear, selectedMonth, day);
                final isSelected = selectedDate.day == day &&
                    selectedDate.month == selectedMonth &&
                    selectedDate.year == selectedYear;
                final isToday = now.day == day &&
                    now.month == selectedMonth &&
                    now.year == selectedYear;

                // Get nama hari (0=Monday, 6=Sunday)
                final dayOfWeek = date.weekday - 1; // Convert to 0-based index
                final dayName = daysOfWeek[dayOfWeek];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = date;
                    });
                    loadMealsFromCache(); // Reload meals from Firestore for selected date
                    loadAIFoodLogs(); // Reload AI food logs for selected date
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    width: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nama hari
                        Text(
                          dayName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.green
                                : AppColors.lightGreyText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Tanggal dengan circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.green
                                : (isToday
                                    ? AppColors.green.withValues(alpha: 0.2)
                                    : Colors.transparent),
                            shape: BoxShape.circle,
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.green, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: AppTextStyles.h3.copyWith(
                                color: isSelected
                                    ? AppColors.white
                                    : (isToday
                                        ? AppColors.green
                                        : AppColors.black),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Selected date display
          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate),
            style: AppTextStyles.h4,
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🟥 KOTAK KOSONG JIKA BELUM ADA MENU
  // ===============================
  Widget noMealBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.cardWithBorder(),
      child: Text(
        "Belum ada menu untuk tanggal ini",
        style: AppTextStyles.h4.copyWith(color: AppColors.lightGreyText),
      ),
    );
  }
}

// =======================================================
// 🟢 MEAL SCHEDULE CARD (Sesuai UI Design)
// =======================================================
class MealScheduleCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final DateTime selectedDate;
  final Function(bool?) onCheckChanged;

  const MealScheduleCard({
    super.key,
    required this.meal,
    required this.selectedDate,
    required this.onCheckChanged,
  });

  // Check apakah hari ini
  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  // Check apakah tanggal sudah lewat (masa lalu)
  bool _isPastDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return compareDate.isBefore(today);
  }

  // Check apakah tanggal masa depan
  bool _isFutureDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return compareDate.isAfter(today);
  }

  // Check apakah sudah lewat jam makan berdasarkan meal['clock'] personal user
  bool _isPastMealTime() {
    if (!_isToday()) return false;

    final now = TimeOfDay.now();
    final clockRange = meal['clock'] as String? ?? '';

    if (clockRange.isEmpty) return false;

    // Parse end time dari range "07:00 - 08:00"
    try {
      final parts = clockRange.split('-');
      if (parts.length != 2) return false;

      final endTimeStr = parts[1].trim();
      final timeParts = endTimeStr.split(':');
      if (timeParts.length != 2) return false;

      final endHour = int.parse(timeParts[0]);
      final endMinute = int.parse(timeParts[1]);

      // Compare current time dengan end time
      final nowMinutes = now.hour * 60 + now.minute;
      final endMinutes = endHour * 60 + endMinute;

      return nowMinutes >= endMinutes;
    } catch (e) {
      debugPrint('Error parsing meal clock: $clockRange - $e');
      return false;
    }
  }

  // Check apakah sedang dalam rentang waktu makan (bisa centang manual)
  bool _isWithinMealTime() {
    if (!_isToday()) return false;

    final now = TimeOfDay.now();
    final clockRange = meal['clock'] as String? ?? '';

    if (clockRange.isEmpty) return false;

    // Parse start dan end time dari range "07:00 - 08:00"
    try {
      final parts = clockRange.split('-');
      if (parts.length != 2) return false;

      final startTimeStr = parts[0].trim();
      final endTimeStr = parts[1].trim();

      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');

      if (startParts.length != 2 || endParts.length != 2) return false;

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      // Convert to minutes for comparison
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;

      // Check if current time is within range
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } catch (e) {
      debugPrint('Error parsing meal time range: $clockRange - $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = meal['isDone'] ?? false;
    final isToday = _isToday();
    final isPastDate = _isPastDate();
    final isFutureDate = _isFutureDate();
    final isPastMealTime = _isPastMealTime();
    final isWithinMealTime = _isWithinMealTime();

    // Auto-check jika:
    // 1. Sudah lewat tanggal (isPastDate)
    // 2. Hari ini tapi sudah lewat jam makan (isPastMealTime)
    final shouldBeAutoChecked = isPastDate || (isToday && isPastMealTime);
    final shouldBeChecked = isDone || shouldBeAutoChecked;

    // Checkbox enabled hanya jika:
    // 1. Hari ini
    // 2. Sedang dalam rentang waktu makan (belum lewat end time)
    // 3. Belum di-check manual
    final canManuallyCheck = isToday && isWithinMealTime && !isDone;

    // Extract nutritional data from meal - handle both String and num types
    // Function to safely parse nutritional values
    int parseNutrition(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    // Try multiple field name variations for compatibility
    final protein = parseNutrition(meal['protein']);
    final carbohydrate = parseNutrition(
        meal['carbs'] ?? meal['carbohydrate'] ?? meal['totalCarbohydrate']);
    final fat = parseNutrition(meal['fat'] ?? meal['fats'] ?? meal['totalFat']);

    // Debug: Print actual values to verify
    debugPrint(
        '🍽️ [SCHEDULE] Nutritional data for ${meal['name']}: P=$protein, C=$carbohydrate, F=$fat');
    debugPrint(
        '🕐 [SCHEDULE] Clock field for ${meal['name']}: "${meal['clock']}" (type: ${meal['clock'].runtimeType})');

    // Handle image dari Firebase Storage
    String imageUrl = '';
    if (meal['image'] != null && meal['image'] != '') {
      final imagePath = meal['image'] as String;
      debugPrint('🖼️ [SCHEDULE] Building image URL for: $imagePath');

      // Jika sudah URL lengkap, pakai langsung
      if (imagePath.startsWith('http')) {
        imageUrl = imagePath;
        debugPrint(
            '   ✅ [SCHEDULE] Using direct URL (length: ${imageUrl.length})');
      } else {
        // Jika path Firebase Storage, build URL
        imageUrl = buildImageUrl(imagePath);
        debugPrint('   ✅ [SCHEDULE] Built Firebase URL: $imageUrl');
      }
    } else {
      debugPrint('⚠️ [SCHEDULE] No image path found for meal: ${meal['name']}');
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image from Firebase - 1:1 aspect ratio
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.large),
                bottomLeft: Radius.circular(AppRadius.large),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.disabledGrey,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: AppColors.green,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Failed to load image: $imageUrl');
                        debugPrint('   Error: $error');
                        return Container(
                          color: AppColors.disabledGrey,
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: AppColors.lightGreyText,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.disabledGrey,
                      child: Icon(
                        Icons.restaurant,
                        size: 40,
                        color: AppColors.lightGreyText,
                      ),
                    ),
            ),
          ),
          // Meal details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Row 1: Tipe Makanan + Jam + Checkbox
                  Row(
                    children: [
                      // Tipe makanan (Sarapan/Makan Siang/Makan Malam)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: AppRadius.smallRadius,
                        ),
                        child: Text(
                          meal['time'] ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Jam makan
                      if ((meal['clock'] ?? '').toString().isNotEmpty)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 12, color: AppColors.lightGreyText),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  meal['clock'] ?? '',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.greyText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Checkbox logic: tampil untuk hari ini dan masa lalu, hilang untuk masa depan
                      if (!isFutureDate)
                        Checkbox(
                          value: shouldBeChecked,
                          onChanged: canManuallyCheck ? onCheckChanged : null,
                          // Abu-abu untuk past date atau past meal time
                          activeColor: shouldBeAutoChecked
                              ? AppColors.mutedBorderGrey
                              : AppColors.green,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: shouldBeAutoChecked
                                ? AppColors.mutedBorderGrey
                                : AppColors.green,
                            width: 1.5,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Row 2: Nama makanan (max 3 baris)
                  Text(
                    meal['name'] ?? '',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.greyText,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Row 3: Kalori + Makro dalam 1 baris
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: '${meal['calories'] ?? 0} kkal ',
                          style: TextStyle(color: AppColors.green),
                        ),
                        TextSpan(
                          text:
                              '(P: ${protein}g | K: ${carbohydrate}g | L: ${fat}g)',
                          style: TextStyle(color: AppColors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget macroChip(IconData icon, String data) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child:
          Row(children: [Icon(icon, size: 16), SizedBox(width: 4), Text(data)]),
    );
  }
}

// =======================================================
// 🤖 AI FOOD LOG CARD (Makanan Tambahan dari NutriAI)
// =======================================================
class AIFoodLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final DateTime selectedDate;

  const AIFoodLogCard({
    super.key,
    required this.log,
    required this.selectedDate,
  });

  // Safe parse nutrition
  int parseNutrition(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final description = log['description'] ?? 'Makanan';
    final calories = parseNutrition(log['calories']);
    final time = log['time'] ?? '';
    final items =
        (log['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    // Read nutrients with field variations
    final totalProtein = parseNutrition(
        log['protein'] ?? log['proteins'] ?? log['totalProtein']);
    final totalCarbohydrate = parseNutrition(
        log['carbohydrate'] ?? log['carbs'] ?? log['totalCarbohydrate']);
    final totalFat =
        parseNutrition(log['fat'] ?? log['fats'] ?? log['totalFat']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Description + Time (simple, no icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: AppTextStyles.h5.copyWith(
                    color: AppColors.greyText,
                    fontSize: 13,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12, color: AppColors.lightGreyText),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Total nutritional info in one line (like regular meal card)
          Text(
            '$calories kkal (P: ${totalProtein}g | K: ${totalCarbohydrate}g | L: ${totalFat}g)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.green,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Items list (if multiple items) - simple bullet list
          if (items.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.greenLight.withValues(alpha: 0.1),
                borderRadius: AppRadius.smallRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail:',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...items.map((item) {
                    final itemName = item['name'] ?? '';
                    final itemCal = parseNutrition(item['calories']);
                    final itemProtein =
                        parseNutrition(item['protein'] ?? item['proteins']);
                    final itemCarbs =
                        parseNutrition(item['carbohydrate'] ?? item['carbs']);
                    final itemFat = parseNutrition(item['fat'] ?? item['fats']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.green,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              '$itemCal kkal (P: ${itemProtein}g | K: ${itemCarbs}g | L: ${itemFat}g)',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.greyText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =======================================================
// 🟣 SUGGESTED MEALS LIST
// =======================================================
class SuggestedMealsBox extends StatelessWidget {
  final List<Map<String, dynamic>> suggestionMeals;

  const SuggestedMealsBox({super.key, required this.suggestionMeals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Menu Saran", style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: suggestionMeals.length,
          itemBuilder: (context, i) =>
              SuggestionMealItem(meal: suggestionMeals[i]),
        ),
      ],
    );
  }
}

// =======================================================
// 🟡 SUGGESTION MEAL ITEM WIDGET
// =======================================================
class SuggestionMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;

  const SuggestionMealItem({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.large),
              bottomLeft: Radius.circular(AppRadius.large),
            ),
            child: Image.network(
              buildImageUrl(meal['image'] ?? ''),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: AppColors.disabledGrey,
                child: Icon(Icons.restaurant, color: AppColors.lightGreyText),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm * 1.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name']?.toString().isNotEmpty == true
                        ? meal['name']
                        : 'Unknown Menu',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _buildMacro(Icons.monitor_weight_outlined,
                          meal['protein']?.toString() ?? '-'),
                      _buildMacro(Icons.bakery_dining_outlined,
                          meal['carb']?.toString() ?? '-'),
                      _buildMacro(
                          Icons.egg_outlined, meal['fat']?.toString() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs * 1.5),
                  Text(
                    '${meal['calories']?.toString() ?? '-'} kkal',
                    style: AppTextStyles.h5,
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm * 1.25),
            child: AppWidgets.gradientButton(
              text: "Pilih",
              onPressed: () {
                Navigator.pop(context, meal);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14),
        SizedBox(width: 3),
        Text(value),
        SizedBox(width: 8),
      ],
    );
  }
}
