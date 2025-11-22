// 🚀 FULL Revised SchedulePage.dart (Dynamic Menu + Firebase Storage + Date After Today Only)
// Pastikan kamu sudah punya storage_helper.dart dengan buildImageUrl()

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/utils/storage_helper.dart';
import 'package:nutrilink/services/schedule_service.dart';

const Color kGreen = Color(0xFF75C778);
const Color kLightGreyText = Color(0xFF6B6B6B);
const Color kTextColor = Color(0xFF2C2C2C);

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
  
  // ScrollController untuk calendar
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadMealsFromCache();
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

  // Load meals dari Firestore menggunakan ScheduleService
  Future<void> loadMealsFromCache() async {
    try {
      debugPrint('🔍 Loading meals for: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
      
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
          debugPrint('   Meal ${i+1}: ${meal['name']} - time: ${meal['time']}, clock: ${meal['clock']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading meals: $e');
      setState(() {
        scheduledMeals = [];
      });
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
      final success = await ScheduleService.markMealAsDone(selectedDate, index, value);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header dengan pemilihan bulan dan kalender
          _buildMonthSelector(),
          _buildCalendarWeek(),
          SizedBox(height: 8),
          // Title Jadwal Makan dengan tombol Today
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Jadwal Makan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Tombol Today
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime.now();
                          selectedMonth = DateTime.now().month;
                          selectedYear = DateTime.now().year;
                          loadMealsFromCache();
                        });
                        // Scroll ke hari ini
                        _scrollToToday();
                      },
                      icon: Icon(Icons.today, color: kGreen, size: 20),
                      label: Text(
                        'Today',
                        style: TextStyle(color: kGreen, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: kGreen.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
          // List of scheduled meals
          Expanded(
            child: scheduledMeals.isNotEmpty
                ? ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: scheduledMeals.length,
                    itemBuilder: (context, index) {
                      return MealScheduleCard(
                        meal: scheduledMeals[index],
                        onCheckChanged: (value) {
                          saveChecklistToFirestore(index, value ?? false);
                        },
                      );
                    },
                  )
                : Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: kLightGreyText,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Belum ada jadwal makan",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Buka HomePage untuk generate jadwal makan hari ini",
                            style: TextStyle(
                              color: kLightGreyText,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: kGreen, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButton<int>(
          value: selectedMonth,
          isExpanded: true,
          underline: SizedBox(),
          icon: Icon(Icons.keyboard_arrow_down, color: kGreen),
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
          items: List.generate(12, (index) {
            return DropdownMenuItem(
              value: index + 1,
              child: Text(months[index]),
            );
          }),
          onChanged: (value) {
            setState(() {
              selectedMonth = value!;
              selectedDate = DateTime(selectedYear, selectedMonth, selectedDate.day);
            });
            loadMealsFromCache(); // Reload meals for new month
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
      padding: EdgeInsets.symmetric(horizontal: 20),
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
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nama hari
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? kGreen : kLightGreyText,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Tanggal dengan circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? kGreen : (isToday ? kGreen.withValues(alpha: 0.2) : Colors.transparent),
                            shape: BoxShape.circle,
                            border: isToday && !isSelected ? Border.all(color: kGreen, width: 2) : null,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : (isToday ? kGreen : Colors.black),
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
          SizedBox(height: 12),
          // Selected date display
          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        "Belum ada menu untuk tanggal ini",
        style: TextStyle(fontSize: 16, color: kLightGreyText),
      ),
    );
  }
}

// =======================================================
// 🟢 MEAL SCHEDULE CARD (Sesuai UI Design)
// =======================================================
class MealScheduleCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  final Function(bool?) onCheckChanged;

  const MealScheduleCard({
    super.key,
    required this.meal,
    required this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = meal['isDone'] ?? false;
    
    // Handle image dari Firebase Storage
    String imageUrl = '';
    if (meal['image'] != null && meal['image'] != '') {
      final imagePath = meal['image'] as String;
      debugPrint('🖼️ [SCHEDULE] Building image URL for: $imagePath');
      
      // Jika sudah URL lengkap, pakai langsung
      if (imagePath.startsWith('http')) {
        imageUrl = imagePath;
        debugPrint('   ✅ [SCHEDULE] Using direct URL (length: ${imageUrl.length})');
      } else {
        // Jika path Firebase Storage, build URL
        imageUrl = buildImageUrl(imagePath);
        debugPrint('   ✅ [SCHEDULE] Built Firebase URL: $imageUrl');
      }
    } else {
      debugPrint('⚠️ [SCHEDULE] No image path found for meal: ${meal['name']}');
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context, 
          '/detailMenu',
          arguments: meal,
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Image from Firebase
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(kGreen),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Failed to load image: $imageUrl');
                          debugPrint('   Error: $error');
                          return Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // Meal details
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meal type tag with checkbox
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: kGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                meal['time'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: isDone,
                              onChanged: onCheckChanged,
                              activeColor: kGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Scheduled time
                        if ((meal['clock'] ?? '').toString().isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: kLightGreyText),
                              SizedBox(width: 4),
                              Text(
                                meal['clock'] ?? 'Waktu belum diatur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kLightGreyText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        if ((meal['clock'] ?? '').toString().isNotEmpty)
                          SizedBox(height: 8),
                        SizedBox(height: 8),
                        // Meal name
                        Text(
                          meal['name'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextColor,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Calories at bottom
                    Text(
                      '${meal['calories']} Kalori',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget macroChip(IconData icon, String data) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Row(children: [Icon(icon, size: 16), SizedBox(width: 4), Text(data)]),
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
        Text("Menu Saran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: suggestionMeals.length,
          itemBuilder: (context, i) => SuggestionMealItem(meal: suggestionMeals[i]),
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
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: Image.network(
              buildImageUrl(meal['image'] ?? ''),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[300],
                child: Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name']?.toString().isNotEmpty == true ? meal['name'] : 'Unknown Menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMacro(Icons.monitor_weight_outlined, meal['protein']?.toString() ?? '-'),
                      _buildMacro(Icons.bakery_dining_outlined, meal['carb']?.toString() ?? '-'),
                      _buildMacro(Icons.egg_outlined, meal['fat']?.toString() ?? '-'),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${meal['calories']?.toString() ?? '-'} kkal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, meal);
              },
              child: Text("Pilih"),
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

