// lib/schedulePage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'editedMenuPage.dart'; // Import EditedMenuPage
import 'tambahMenuPage.dart';

// Import warna (untuk konsistensi dengan homePage.dart)
const Color kGreen = Color(0xFF75C778);
const Color kLightGreyText = Color(0xFF888888);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
const Color kYellow = Color(0xFFFFA726);

// --- Data Model Real (untuk referensi Meal Card) ---
class Meal {
  final String time; // Sarapan/Makan Siang/Makan Malam
  final String clock; // 07:00 - 08:00
  final String name;
  final int calories;
  final String imageUrl;
  final bool isDone;
  final String protein; 
  final String fat;
  final String carbs;

  Meal({
    required this.time,
    required this.clock,
    required this.name,
    required this.calories,
    required this.imageUrl,
    this.isDone = false,
    this.protein = '?',
    this.fat = '?',
    this.carbs = '?',
  });
}

// ===============================================
// 🎯 KELAS UTAMA: SCHEDULEPAGE
// ===============================================

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> upcomingMeals = [];
  bool isLoading = true;

  // --- REVISI 1: TANGGAL AWAL DITETAPKAN SECARA DINAMIS ---
  late DateTime _selectedDate;
  late String _selectedMonthYear;
  
  final List<String> _monthYears = [];
  List<Map<String, dynamic>> dailySchedule = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initMonthYears();
    
    _selectedMonthYear = '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
    _calculateDailySchedule(_selectedDate);

    _loadUpcomingMeals(); 
  }
  
  String _getMonthName(int month) {
    const names = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return names[month];
  }
  
  String _getDayName(int weekday) {
    const names = [
      '', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return names[weekday];
  }

  void _calculateDailySchedule(DateTime date) {
    final startOfMonth = DateTime(date.year, date.month, 1);
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final daysInMonth = nextMonth.difference(startOfMonth).inDays;
    
    final List<Map<String, dynamic>> calculatedSchedule = [];
    
    for (int i = 0; i < daysInMonth; i++) {
      final currentDay = startOfMonth.add(Duration(days: i));
      calculatedSchedule.add({
        'day': _getDayName(currentDay.weekday),
        'date': currentDay.day,
        'isToday': currentDay.year == DateTime.now().year && 
                   currentDay.month == DateTime.now().month && 
                   currentDay.day == DateTime.now().day,
        'fullDate': currentDay,
      });
    }

    // Hanya panggil setState jika widget masih mounted
    if (mounted) {
      setState(() {
        dailySchedule = calculatedSchedule;
      });
    }
  }
  
  void _initMonthYears() {
    final now = DateTime.now();
    final List<String> list = [];
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      list.add('${_getMonthName(date.month)} ${date.year}');
    }
    _monthYears.addAll(list.toSet().toList());
  }

  String _getFullDateText() {
    final dayName = _getDayName(_selectedDate.weekday);
    final date = _selectedDate.day.toString().padLeft(2, '0');
    final monthYear = _selectedMonthYear;
    return '$dayName, $date $monthYear';
  }
  
  Future<void> _loadUpcomingMeals() async {
    final selectedIsToday = _selectedDate.year == DateTime.now().year &&
                            _selectedDate.month == DateTime.now().month &&
                            _selectedDate.day == DateTime.now().day;
    
    if (!selectedIsToday) {
      if (mounted) {
        setState(() {
          upcomingMeals = [];
          isLoading = false;
        });
      }
      return;
    }
    
    if (mounted) setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = DateTime.now().toString().split(' ')[0];
      final cachedUpcomingJson = prefs.getString('cached_upcoming_$todayKey');

      if (cachedUpcomingJson != null) {
        final List<dynamic> cachedUpcomingList = json.decode(cachedUpcomingJson);
        if (mounted) {
          setState(() {
            upcomingMeals = cachedUpcomingList.cast<Map<String, dynamic>>();
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('SchedulePage Error loading meals: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveUpcomingMealsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toString().split(' ')[0];
      await prefs.setString('cached_upcoming_$today', json.encode(upcomingMeals));
    } catch (e) {
      debugPrint('SchedulePage Error saving upcoming meals cache: $e');
    }
  }

  void _onMonthYearChanged(String? newValue) {
    if (newValue != null) {
      final parts = newValue.split(' ');
      final monthName = parts[0];
      final year = int.tryParse(parts[1]) ?? DateTime.now().year;
      
      final month = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ].indexOf(monthName) + 1;
      
      final newSelectedDate = DateTime(year, month, 1);

      if (mounted) {
        setState(() {
          _selectedMonthYear = newValue;
          _selectedDate = newSelectedDate;
          _calculateDailySchedule(newSelectedDate);
        });
      }
      _loadUpcomingMeals();
    }
  }
  
  void _onDateSelected(DateTime newFullDate) {
    if (mounted) {
      setState(() {
        _selectedDate = newFullDate;
      });
    }
    _loadUpcomingMeals();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          const _AppBarContent(), // FIX: Dipanggil sebagai const widget

          const SizedBox(height: 10),

          // Pemilih Bulan dan Tahun
          _MonthYearSelector(
            selectedMonthYear: _selectedMonthYear,
            monthYears: _monthYears,
            onChanged: _onMonthYearChanged,
          ),

          const SizedBox(height: 16),

          // Pemilih Hari/Tanggal (semua tanggal bulan ini)
          _DayOfWeekSelector(
            selectedDate: _selectedDate,
            dailySchedule: dailySchedule,
            onDateSelected: _onDateSelected,
          ),

          const SizedBox(height: 10), 

          // TANGGAL LENGKAP & ICON PLUS
          _FullDateDisplay(
            fullDateText: _getFullDateText(),
          ),

          const SizedBox(height: 20),

          // Daftar Jadwal Makan
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: kGreen))
                : upcomingMeals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        _selectedDate.day == DateTime.now().day
                            ? 'Tidak ada jadwal makan hari ini. Kembali ke Home untuk memuat rekomendasi.'
                            : 'Tidak ada jadwal makan yang tersimpan untuk tanggal ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kLightGreyText),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: upcomingMeals.length,
                    itemBuilder: (context, index) {
                      final mealMap = upcomingMeals[index];
                      final meal = Meal(
                        time: mealMap['time'] as String? ?? 'N/A', 
                        clock: mealMap['clock'] as String? ?? '00:00',
                        name: mealMap['name'] as String? ?? 'Menu',
                        calories: mealMap['calories'] as int? ?? 0,
                        imageUrl: mealMap['image'] as String? ?? '', 
                        isDone: mealMap['isDone'] as bool? ?? false,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _MealCard(
                          meal: meal, 
                          onToggleDone: (bool value) {
                            if (mounted) {
                              setState(() {
                                upcomingMeals[index]['isDone'] = value;
                              });
                            }
                            _saveUpcomingMealsToCache();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ===============================================
// 🖼️ WIDGET PENDUKUNG
// ===============================================

class _AppBarContent extends StatelessWidget {
  const _AppBarContent(); // Tambahkan const constructor
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Jadwal Makan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthYearSelector extends StatelessWidget {
  final String selectedMonthYear;
  final List<String> monthYears;
  final ValueChanged<String?> onChanged;

  const _MonthYearSelector({
    required this.selectedMonthYear,
    required this.monthYears,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0.5),
            decoration: BoxDecoration(
              color: kGreen, 
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonthYear,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color.fromARGB(255, 254, 254, 254)),
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                dropdownColor: kGreen,
                elevation: 1,
                items: monthYears.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.split(' ')[0]),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayOfWeekSelector extends StatelessWidget {
  final DateTime selectedDate; 
  final ValueChanged<DateTime> onDateSelected;
  final List<Map<String, dynamic>> dailySchedule; 

  const _DayOfWeekSelector({
    required this.selectedDate,
    required this.onDateSelected,
    required this.dailySchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dailySchedule.length,
            itemBuilder: (context, index) {
              final item = dailySchedule[index];
              final dateNumber = item['date'] as int;
              final fullDate = item['fullDate'] as DateTime;
              
              final isSelected = fullDate.day == selectedDate.day && 
                                 fullDate.month == selectedDate.month && 
                                 fullDate.year == selectedDate.year;

              return GestureDetector(
                onTap: () => onDateSelected(fullDate),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? kGreen : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? kGreen : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['day'].substring(0, 1),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          dateNumber.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? kGreen : Colors.black,
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
      ],
    );
  }
}

class _FullDateDisplay extends StatelessWidget {
  final String fullDateText;
  const _FullDateDisplay({required this.fullDateText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fullDateText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          InkResponse(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TambahMenuPage(),
                ),
              );
            },
            radius: 20,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.add_circle_outline, 
                color: kGreen, 
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  final ValueChanged<bool> onToggleDone;

  const _MealCard({required this.meal, required this.onToggleDone});

  String _getMealTimeRange(String time) {
    return meal.clock;
  }
  
  // Widget Pembantu untuk Item Makro (Revisi agar label/value lebih jelas)
  Widget _buildMacroItem(String title, String value, {Color color = Colors.black}) {
    final secondaryColor = Colors.grey[600];
    
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Row(
        children: [
          Text(
            title, 
            style: TextStyle(color: secondaryColor, fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            value, 
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIconAction({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        splashColor: kGreen.withOpacity(0.2),
        highlightColor: Colors.transparent,
        containedInkWell: true,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final mealTimeRange = _getMealTimeRange(meal.clock);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BARIS 1: WAKTU MAKAN, ICON EDIT, DONE/PENDING ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.time, // Tipe Makan: Sarapan/Siang/Malam
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: kLightGreyText),
                      const SizedBox(width: 4),
                      Text(
                        mealTimeRange, // Jam makan spesifik
                        style: const TextStyle(
                          fontSize: 12,
                          color: kLightGreyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Icon Edit
                  _buildIconAction(
                    icon: Icons.edit_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditedMenuPage(),
                        ),
                      );
                    },
                    color: Colors.black,
                  ),
                  const SizedBox(width: 10),
                  // Tombol Done/Pending
                  InkWell(
                    onTap: () => onToggleDone(!meal.isDone),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: meal.isDone ? kGreen : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: meal.isDone ? kGreen : kMutedBorderGrey,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            meal.isDone ? Icons.check_circle_outline : Icons.pending_actions,
                            size: 18,
                            color: meal.isDone ? Colors.white : kYellow,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            meal.isDone ? 'Selesai' : 'Tandai Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: meal.isDone ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // --- BARIS 2: GAMBAR MAKANAN (ASPEK RASIO 1:1) ---
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.0, 
              child: meal.imageUrl.isNotEmpty
                  ? Image.network(
                      meal.imageUrl, 
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: kGreen,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.restaurant, size: 50, color: Colors.grey[400]),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.restaurant_menu, size: 50, color: Colors.grey[400]),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 15),

          // --- BARIS 3: DETAIL MAKANAN (Makro, Nama & Kalori) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Detail Makro
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildMacroItem('Protein', meal.protein, color: Colors.black),
                  _buildMacroItem('Lemak', meal.fat, color: Colors.black),
                  _buildMacroItem('Karbo', meal.carbs, color: Colors.black),
                ],
              ),
              const SizedBox(height: 8),

              // Nama Makanan dan Kalori
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${meal.calories} kalori',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}