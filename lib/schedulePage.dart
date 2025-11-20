// 🚀 FULL Revised SchedulePage.dart (Dynamic Menu + Firebase Storage + Date After Today Only)
// Pastikan kamu sudah punya storage_helper.dart dengan buildImageUrl()

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrilink/utils/storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // Load meals dari SharedPreferences (sama dengan HomePage)
  Future<void> loadMealsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final today = DateFormat('yyyy-MM-dd').format(selectedDate);
      
      debugPrint('🔍 Trying to load meals for: $today (uid: $uid)');
      
      final cached = prefs.getString('cached_upcoming_${uid}_$today');
      if (cached != null) {
        final List<dynamic> decoded = json.decode(cached);
        setState(() {
          scheduledMeals = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        debugPrint('✅ Loaded ${scheduledMeals.length} meals from cache for $today');
        
        // Debug: Check if images are loaded
        for (var meal in scheduledMeals) {
          final imagePreview = meal['image'] != null && meal['image'] != '' 
              ? '${(meal['image'] as String).substring(0, (meal['image'] as String).length > 60 ? 60 : (meal['image'] as String).length)}...'
              : 'NO IMAGE';
          debugPrint('   - ${meal['name']}: image = $imagePreview');
        }
        
        // Jika loaded tapi kosong, coba Firestore
        if (scheduledMeals.isEmpty) {
          debugPrint('⚠️ Cache loaded but empty, trying Firestore');
          await loadFromFirestore();
        }
      } else {
        debugPrint('⚠️ No cached meals found for $today');
        // Coba load dari Firestore sebagai fallback
        await loadFromFirestore();
      }
    } catch (e) {
      debugPrint('❌ Error loading meals from cache: $e');
      await loadFromFirestore();
    }
  }

  // Load dari Firestore sebagai fallback
  Future<void> loadFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('⚠️ User not logged in, loading dummy data');
        loadDummyMeals();
        return;
      }

      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(formattedDate)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data?['meals'] != null) {
          setState(() {
            scheduledMeals = List<Map<String, dynamic>>.from(data!['meals']);
          });
          debugPrint('✅ Loaded ${scheduledMeals.length} meals from Firestore for $formattedDate');
        } else {
          debugPrint('⚠️ No meals in Firestore for $formattedDate, loading dummy data');
          loadDummyMeals();
        }
      } else {
        debugPrint('⚠️ No document in Firestore for $formattedDate, loading dummy data');
        loadDummyMeals();
      }
    } catch (e) {
      debugPrint('❌ Error loading from Firestore: $e');
      loadDummyMeals();
    }
  }

  void loadDummyMeals() {
    // Dummy data berdasarkan UI HomePage - dengan placeholder image
    setState(() {
      scheduledMeals = [
        {
          'name': 'Dimsum Keju Lumer With Chow Mein + Hot & Sour Soup',
          'time': 'Sarapan', // Pakai 'time' bukan 'type' untuk konsistensi dengan HomePage
          'clock': '06:30 - 07:00',
          'calories': 403,
          'protein': '25g',
          'carbs': '45g',
          'fat': '12g',
          'image': 'https://placehold.co/400x300/90EE90/000000/png?text=Dimsum+Keju', // Placeholder image
          'isDone': false,
        },
        {
          'name': 'Creamy Red Curry Chicken Meatballs With Thai Basil Fried Rice + Cashew Tofu',
          'time': 'Makan Malam',
          'clock': '19:00 - 20:00',
          'calories': 488,
          'protein': '30g',
          'carbs': '52g',
          'fat': '18g',
          'image': 'https://placehold.co/400x300/FFB6C1/000000/png?text=Red+Curry', // Placeholder image
          'isDone': false,
        },
      ];
    });
    debugPrint('📝 Loaded dummy meals with placeholder images');
  }

  // Function untuk sync dengan HomePage
  Future<void> syncWithHomePage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // Ambil data dari Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('schedule')
        .doc(formattedDate)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data?['meals'] != null) {
        setState(() {
          scheduledMeals = List<Map<String, dynamic>>.from(data!['meals']);
        });
      }
    }
  }

  // Function untuk save checklist ke Firestore dan SharedPreferences
  Future<void> saveChecklistToFirestore(int index, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    
    // Update local state
    setState(() {
      scheduledMeals[index]['isDone'] = value;
    });

    // Save to SharedPreferences (sync dengan HomePage)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_upcoming_${uid}_$formattedDate', json.encode(scheduledMeals));
      debugPrint('💾 Updated schedule checklist in cache');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('schedule')
        .doc(formattedDate)
        .set({
      'meals': scheduledMeals,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
                    // Tombol Refresh
                    IconButton(
                      onPressed: () {
                        loadMealsFromCache();
                      },
                      icon: Icon(Icons.refresh, color: kGreen, size: 24),
                      tooltip: 'Refresh data',
                    ),
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
                    IconButton(
                      icon: Icon(Icons.add_circle, color: kGreen, size: 28),
                      onPressed: () {
                        Navigator.pushNamed(context, '/tambahMenu');
                      },
                      tooltip: 'Tambah Menu',
                    ),
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
                      loadMealsFromCache(); // Reload meals from cache for selected date
                    });
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
        padding: EdgeInsets.all(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Image from Firebase
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
          ),
          SizedBox(width: 16),
          // Meal details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal type tag with edit icon and checkbox
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
                        meal['time'] ?? '', // Pakai 'time' untuk konsistensi dengan HomePage
                        style: TextStyle(
                          fontSize: 12,
                          color: kGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: kGreen, size: 18),
                          onPressed: () {
                            Navigator.pushNamed(context, '/editedMenu');
                          },
                          tooltip: 'Edit Menu',
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
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
                  ],
                ),
                SizedBox(height: 8),
                // Scheduled time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: kLightGreyText),
                    SizedBox(width: 4),
                    Text(
                      meal['clock'] ?? '', // Pakai 'clock' untuk konsistensi dengan HomePage
                      style: TextStyle(
                        fontSize: 12,
                        color: kLightGreyText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Meal name
                Text(
                  meal['name'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                // Calories
                Text(
                  '${meal['calories']} Kalori',
                  style: TextStyle(
                    fontSize: 13,
                    color: kLightGreyText,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                    meal['name'] ?? 'Unknown Menu',
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

