// lib/homePage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nutrilink/schedulePage.dart';
import 'package:nutrilink/navbar.dart';
import 'package:nutrilink/profilePage.dart';
import 'package:nutrilink/reportPage.dart';
import 'package:nutrilink/meal/recomendation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ====== Palet warna konsisten dengan aplikasi ======
// const Color kGreen = Color(0xFF5F9C3F);
const Color kGreen = Color.fromRGBO(117, 199, 120, 1);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
const Color kYellow = Color(0xFFFFA726);
const Color kOrange = Color(0xFFFF7043);
const Color kRed = Color(0xFFE53935);
const Color kBlue = Color(0xFF42A5F5);

// class ReportPage extends StatelessWidget {
//   const ReportPage({super.key});

//   @override
//   Widget build(BuildContext context) =>
//       const Center(child: Text('Halaman Report (Index 3)'));
// }

// ===============================================
// 🎯 KELAS UTAMA: HOMEPAGE (MENANGANI NAVIGASI)
// ===============================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Index awal disetel ke Home (Index 2) sesuai desain bottom bar
  int _currentIndex = 2;

  // Daftar halaman yang akan ditampilkan sesuai urutan navbar
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _buildPages() {
    _pages = [
      SchedulePage(),
      const RecommendationScreen(),
      HomePageContent(
        onNavigateToProfile: () => setState(() => _currentIndex = 4),
        onNavigateToReport: () => setState(() => _currentIndex = 3),
        onNavigateToMeal: () => setState(() => _currentIndex = 1),
        onNavigateToSchedule: () => setState(() => _currentIndex = 0),
      ),
      const ReportScreen(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// ===============================================
// 🏡 KELAS KONTEN: HOMEPAGECONTENT (Isi Halaman Home)
// ===============================================
class HomePageContent extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToReport;
  final VoidCallback onNavigateToMeal;
  final VoidCallback onNavigateToSchedule;
  
  const HomePageContent({
    super.key,
    required this.onNavigateToProfile,
    required this.onNavigateToReport,
    required this.onNavigateToMeal,
    required this.onNavigateToSchedule,
  });

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  Map<String, dynamic>? userData;
  String location = 'Mengambil lokasi...';
  bool isLoading = true;
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> upcomingMeals = [];
  String? cachedDate;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _loadMeals() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    final userId = currentUserId ?? '';
    
    final cachedMealsJson = prefs.getString('cached_meals_${userId}_$today');
    final cachedUpcomingJson = prefs.getString('cached_upcoming_${userId}_$today');
    
    if (cachedMealsJson != null && cachedUpcomingJson != null) {
      debugPrint('✅ Loading meals from cache for $today');
      
      final List<dynamic> cachedMealsList = json.decode(cachedMealsJson);
      final List<dynamic> cachedUpcomingList = json.decode(cachedUpcomingJson);
      
      if (cachedUpcomingList.isNotEmpty) {
        final firstMeal = cachedUpcomingList[0] as Map<String, dynamic>;
        if (!firstMeal.containsKey('calories')) {
          debugPrint('⚠️ Old cache format detected, clearing cache...');
          await prefs.remove('cached_meals_${userId}_$today');
          await prefs.remove('cached_upcoming_${userId}_$today');
        } else {
          if (mounted) {
            setState(() {
              meals = cachedMealsList.cast<Map<String, dynamic>>();
              upcomingMeals = cachedUpcomingList.cast<Map<String, dynamic>>();
              cachedDate = today;
            });
          }
          return;
        }
      } else {
        if (mounted) {
          setState(() {
            meals = cachedMealsList.cast<Map<String, dynamic>>();
            upcomingMeals = cachedUpcomingList.cast<Map<String, dynamic>>();
            cachedDate = today;
          });
        }
        return;
      }
    }
    
    debugPrint('📥 No cache found for $today, loading from Firestore...');
    
    final profile = userData?['profile'] as Map<String, dynamic>?;
    final eatFrequency = profile?['eatFrequency'] ?? 3;

    final snapshot = await FirebaseFirestore.instance
        .collection('menus')
        .get();

    debugPrint('Total menus fetched: ${snapshot.docs.length}');

    final allMeals = await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data();
      
      try {
        String imageUrl = '';
        final imageField = data['image'];
        
        String? imagePath;
        if (imageField is List && imageField.isNotEmpty) {
          imagePath = imageField[0]?.toString();
        } else if (imageField is String) {
          imagePath = imageField;
        }
        
        if (imagePath != null && imagePath.isNotEmpty) {
          try {
            String storagePath = imagePath.contains('/') 
                ? imagePath
                : 'menus/$imagePath';
            
            final ref = FirebaseStorage.instance.ref(storagePath);
            imageUrl = await ref.getDownloadURL();
            debugPrint('✅ Got image URL for ${data['name']}: ${imageUrl.substring(0, 50)}...');
          } catch (e) {
            debugPrint('❌ Failed to get download URL for ${data['name']}: $e');
          }
        }

        return {
          'id': doc.id,
          'name': data['name']?.toString() ?? '',
          'type': data['type']?.toString() ?? '',
          'tag1': (data['tags'] is List && (data['tags'] as List).isNotEmpty) 
              ? (data['tags'] as List)[0].toString() 
              : '',
          'tag2': (data['tags'] is List && (data['tags'] as List).length > 1) 
              ? (data['tags'] as List)[1].toString() 
              : '',
          'tag3': (data['tags'] is List && (data['tags'] as List).length > 2) 
              ? (data['tags'] as List)[2].toString() 
              : '',
          'calories': data['calories'] as int? ?? 0,
          'price': data['price'] as int? ?? 0,
          'image': imageUrl, // ✅ Simpan URL lengkap
          'description': data['description']?.toString() ?? '',
        };
      } catch (e, stackTrace) {
        debugPrint('❌ Error processing menu ${doc.id}: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    }));

    final mealsWithImages = allMeals.where((meal) {
      return meal['image'] != null && (meal['image'] as String).isNotEmpty;
    }).toList();

    debugPrint('Meals with valid download URLs: ${mealsWithImages.length}');

    final sarapan = mealsWithImages.where((m) => m['type'] == 'Sarapan').toList();
    final makanSiang = mealsWithImages.where((m) => m['type'] == 'Makan Siang').toList();
    final makanMalam = mealsWithImages.where((m) => m['type'] == 'Makan Malam').toList();

    sarapan.shuffle();
    makanSiang.shuffle();
    makanMalam.shuffle();

    List<Map<String, dynamic>> selectedMeals = [];
    List<Map<String, dynamic>> upcomingMealsList = [];
    
    if (eatFrequency == 2) {
      if (sarapan.length >= 2) {
        selectedMeals.add(sarapan[0]);
        upcomingMealsList.add(sarapan[1]);
      } else if (sarapan.isNotEmpty) {
        selectedMeals.add(sarapan[0]);
      }
      
      if (makanMalam.length >= 2) {
        selectedMeals.add(makanMalam[0]);
        upcomingMealsList.add(makanMalam[1]);
      } else if (makanMalam.isNotEmpty) {
        selectedMeals.add(makanMalam[0]);
      }
    } else {
      if (sarapan.length >= 2) {
        selectedMeals.add(sarapan[0]);
        upcomingMealsList.add(sarapan[1]);
      } else if (sarapan.isNotEmpty) {
        selectedMeals.add(sarapan[0]);
      }
      
      if (makanSiang.length >= 2) {
        selectedMeals.add(makanSiang[0]);
        upcomingMealsList.add(makanSiang[1]);
      } else if (makanSiang.isNotEmpty) {
        selectedMeals.add(makanSiang[0]);
      }
      
      if (makanMalam.length >= 2) {
        selectedMeals.add(makanMalam[0]);
        upcomingMealsList.add(makanMalam[1]);
      } else if (makanMalam.isNotEmpty) {
        selectedMeals.add(makanMalam[0]);
      }
    }

    final sleepSchedule = profile?['sleepSchedule'] as Map<String, dynamic>?;
    final wakeTime = sleepSchedule?['wakeTime'] as String? ?? '06:00';
    final sleepTime = sleepSchedule?['sleepTime'] as String? ?? '22:00';
    
    // ✅ PENTING: Simpan URL gambar ke upcomingMeals
    final upcomingWithTime = upcomingMealsList.map((meal) {
      return {
        'time': meal['type'],
        'clock': _calculateMealTime(meal['type'], wakeTime, sleepTime),
        'name': meal['name'],
        'calories': meal['calories'],
        'image': meal['image'], // ✅ Tambahkan field image
        'isDone': false,
      };
    }).toList();
    
    // Debug: Cek apakah image URL tersimpan
    debugPrint('🔍 Upcoming meals to be cached:');
    for (var meal in upcomingWithTime) {
      debugPrint('  - ${meal['name']}: image = ${meal['image']}');
    }
    
    // ✅ BARU: Simpan jadwal ke Firestore schedule collection
    await _saveScheduleToFirestore(selectedMeals, upcomingWithTime, today);
    
    await prefs.setString('cached_meals_${userId}_$today', json.encode(selectedMeals));
    await prefs.setString('cached_upcoming_${userId}_$today', json.encode(upcomingWithTime));
    
    final keys = prefs.getKeys();
    for (final key in keys) {
      if ((key.startsWith('cached_meals_') || key.startsWith('cached_upcoming_'))) {
        if (!key.contains('_${userId}_') || !key.endsWith(today)) {
          await prefs.remove(key);
          debugPrint('🗑️ Removed old cache: $key');
        }
      }
    }
    
    debugPrint('💾 Saved meals to cache for $today');
    
    if (mounted) {
      setState(() {
        meals = selectedMeals;
        upcomingMeals = upcomingWithTime;
        cachedDate = today;
      });
    }
  } catch (e) {
    debugPrint('Error loading meals: $e');
  }
}

  // Hitung jam makan berdasarkan waktu bangun dan tidur (rentang waktu)
  String _calculateMealTime(String mealType, String wakeTime, String sleepTime) {
    try {
      final wake = TimeOfDay(
        hour: int.parse(wakeTime.split(':')[0]),
        minute: int.parse(wakeTime.split(':')[1]),
      );
      final sleep = TimeOfDay(
        hour: int.parse(sleepTime.split(':')[0]),
        minute: int.parse(sleepTime.split(':')[1]),
      );

      int wakeMinutes = wake.hour * 60 + wake.minute;
      int sleepMinutes = sleep.hour * 60 + sleep.minute;
      if (sleepMinutes < wakeMinutes) sleepMinutes += 24 * 60; // Next day

      final activeHours = (sleepMinutes - wakeMinutes) / 60;

      String formatTime(int minutes) {
        final hour = (minutes ~/ 60) % 24;
        final min = minutes % 60;
        return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }

      if (mealType == 'Sarapan') {
        // 30-60 menit setelah bangun
        final startMinutes = wakeMinutes + 30;
        final endMinutes = wakeMinutes + 60;
        return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
      } else if (mealType == 'Makan Siang') {
        // Pertengahan jam aktif ± 30 menit
        final midMinutes = wakeMinutes + (activeHours / 2 * 60).round();
        final startMinutes = midMinutes - 30;
        final endMinutes = midMinutes + 30;
        return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
      } else {
        // 2-3 jam sebelum tidur
        final startMinutes = sleepMinutes - 180; // 3 jam sebelum
        final endMinutes = sleepMinutes - 120;  // 2 jam sebelum
        return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
      }
    } catch (e) {
      // Fallback jika parsing gagal
      return mealType == 'Sarapan' ? '07:00 - 08:00' : 
            mealType == 'Makan Siang' ? '12:00 - 13:00' : '18:00 - 19:00';
    }
  }

  void _toggleMealDone(int index) {
    setState(() {
      upcomingMeals[index]['isDone'] = !upcomingMeals[index]['isDone'];
    });
    
    // Save updated isDone status to cache
    _saveUpcomingMealsToCache();
  }
  
  Future<void> _saveUpcomingMealsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toString().split(' ')[0];
      final userId = currentUserId ?? '';
      await prefs.setString('cached_upcoming_${userId}_$today', json.encode(upcomingMeals));
      debugPrint('💾 Updated upcoming meals cache with isDone status');
    } catch (e) {
      debugPrint('Error saving upcoming meals cache: $e');
    }
  }
  
  // ✅ BARU: Fungsi untuk menyimpan jadwal ke Firestore
  Future<void> _saveScheduleToFirestore(
    List<Map<String, dynamic>> selectedMeals,
    List<Map<String, dynamic>> upcomingMeals,
    String date,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Simpan semua meals dalam satu document dengan array
      final scheduleData = {
        'meals': upcomingMeals.map((meal) => {
          'name': meal['name'] ?? '',
          'calories': meal['calories'] ?? 0,
          'image': meal['image'] ?? '',
          'type': meal['time'] ?? '',
          'scheduledTime': meal['clock'] ?? '',
          'isDone': meal['isDone'] ?? false,
        }).toList(),
        'scheduledDate': date,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'scheduled',
        'source': 'auto_generated',
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('schedule')
          .doc(date)
          .set(scheduleData, SetOptions(merge: true));
      
      debugPrint('✅ Saved ${upcomingMeals.length} meals to Firestore for date: $date');
    } catch (e) {
      debugPrint('❌ Error saving schedule to Firestore: $e');
    }
  }
  
  int _calculateConsumedCalories() {
    int totalCalories = 0;
    debugPrint('🔍 Calculating consumed calories from ${upcomingMeals.length} meals');
    
    for (var meal in upcomingMeals) {
      final isDone = meal['isDone'] == true;
      final calories = (meal['calories'] as int?) ?? 0;
      debugPrint('  - ${meal['name']}: isDone=$isDone, calories=$calories');
      
      if (isDone) {
        totalCalories += calories;
      }
    }
    
    debugPrint('📊 Total consumed calories: $totalCalories');
    return totalCalories;
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user changed
      if (currentUserId != null && currentUserId != user.uid) {
        // Clear cache from previous user
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith('cached_meals_') || key.startsWith('cached_upcoming_')) {
            await prefs.remove(key);
            debugPrint('🗑️ Cleared cache from previous user: $key');
          }
        }
      }
      
      currentUserId = user.uid;
      debugPrint('👤 Current user ID: $currentUserId');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        if (mounted) {
          setState(() {
            userData = doc.data();
            isLoading = false;
          });
        }
        // Load meals after user data is loaded
        await _loadMeals();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => location = 'Lokasi tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => location = 'Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => location = 'Izin lokasi ditolak permanen');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        // Fix: Handle null values properly
        final city = place.subAdministrativeArea?.isNotEmpty == true 
            ? place.subAdministrativeArea 
            : (place.locality?.isNotEmpty == true ? place.locality : 'Unknown');
        final province = place.administrativeArea?.isNotEmpty == true 
            ? place.administrativeArea 
            : 'Unknown';
        if (mounted) {
          setState(() {
            location = '$city, $province';
          });
        }
      } else {
        if (mounted) setState(() => location = 'Lokasi tidak ditemukan');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) setState(() => location = 'Gagal mendapatkan lokasi');
    }
  }

  // Hitung BMI
  double _calculateBMI() {
    final profile = userData?['profile'] as Map<String, dynamic>?;
    if (profile == null) return 0;

    final heightCm = profile['heightCm'] as num?;
    final weightKg = profile['weightKg'] as num?;

    if (heightCm == null || weightKg == null || heightCm == 0) return 0;

    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // Kategori BMI
  Map<String, dynamic> _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return {
        'category': 'Underweight',
        'color': kBlue,
        'description': 'Berat badan kurang dari ideal, dapat meningkatkan risiko kekurangan nutrisi dan menurunkan sistem imun tubuh.',
      };
    } else if (bmi < 25) {
      return {
        'category': 'Normal',
        'color': kGreen,
        'description': 'Berat badan ideal dengan risiko penyakit metabolik yang rendah, pertahankan pola makan sehat dan olahraga teratur.',
      };
    } else if (bmi < 30) {
      return {
        'category': 'Overweight',
        'color': kOrange,
        'description': 'Berat badan sedikit melebihi ideal, berpotensi meningkatkan risiko gangguan metabolik jika tidak dikontrol.',
      };
    } else {
      return {
        'category': 'Obese',
        'color': kRed,
        'description': 'Berat badan jauh melebihi ideal dengan risiko tinggi terhadap penyakit jantung, diabetes, dan gangguan kesehatan serius lainnya.',
      };
    }
  }

  // Hitung BMR (Basal Metabolic Rate)
  double _calculateBMR() {
    final profile = userData?['profile'] as Map<String, dynamic>?;
    if (profile == null) return 0;

    final weightKg = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    final heightCm = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    final sex = profile['sex'] as String?;
    final birthDate = (profile['birthDate'] as Timestamp?)?.toDate();

    if (birthDate == null) return 0;

    final age = DateTime.now().year - birthDate.year;

    // Mifflin-St Jeor Equation
    if (sex == 'Laki-laki' || sex == 'Male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  // Hitung TDEE (Total Daily Energy Expenditure)
  double _calculateTDEE() {
    final bmr = _calculateBMR();
    final profile = userData?['profile'] as Map<String, dynamic>?;
    final activityLevel = profile?['activityLevel'] as String?;

    const activityMultipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extremely_active_1': 1.9,
      'extremely_active_2': 2.0,
    };

    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  // Singkat nama jika lebih dari 3 kata
  String _shortenName(String fullName) {
    final words = fullName.trim().split(' ');
    if (words.length <= 2) {
      return fullName;
    }
    
    // Ambil 2 kata pertama, singkat kata ke-3 dan seterusnya
    final result = StringBuffer();
    result.write('${words[0]} ${words[1]}');
    
    for (int i = 2; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        result.write(' ${words[i][0].toUpperCase()}.');
      }
    }
    
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kGreen),
        ),
      );
    }

    final profile = userData?['profile'] as Map<String, dynamic>?;
    final fullName = profile?['name'] ?? 'User';
    final name = _shortenName(fullName);
    final profilePicture = profile?['profilePicture'] ?? 'assets/images/Male Avatar.png';
    final weightKg = (profile?['weightKg'] as num?)?.toDouble() ?? 0;
    final targetWeightKg = (profile?['targetWeightKg'] as num?)?.toDouble() ?? 0;
    final eatFrequency = profile?['eatFrequency'] ?? 3;
    
    final weightDiff = weightKg - targetWeightKg;
    final weightDiffText = weightDiff > 0 
        ? '+${weightDiff.toStringAsFixed(1)} kg'
        : '${weightDiff.toStringAsFixed(1)} kg';

    final tdee = _calculateTDEE();
    final bmi = _calculateBMI();
    final bmiCategory = _getBMICategory(bmi);
    final consumedCalories = _calculateConsumedCalories();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        // 1. MELEBARKAN APPBAR: Tambah tinggi (misalnya 8.0 atas + 8.0 bawah = 16.0)
        preferredSize: const Size.fromHeight(kToolbarHeight + 14.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kGreenLight, kGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                // FIX: Menggunakan withOpacity
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          // 2. MENAMBAHKAN PADDING ATAS & BAWAH di sekitar AppBar
          child: Padding(
            padding: const EdgeInsets.only(top: 7.0, bottom: 7.0),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: InkWell(
                onTap: widget.onNavigateToProfile,
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(profilePicture),
                    // FIX: Menggunakan withOpacity
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onNavigateToProfile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Konsumsi: $consumedCalories / ${tdee.toStringAsFixed(0)} kcal',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 12,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              titleSpacing: 12,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${weightKg.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Target: ${targetWeightKg.toStringAsFixed(1)} kg ($weightDiffText)',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 12,
                          // FIX: Menggunakan withOpacity
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [kGreenLight, kGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // BMI Section
            BmiSection(
              bmi: bmi,
              category: bmiCategory['category'],
              color: bmiCategory['color'],
              description: bmiCategory['description'],
            ),
            const SizedBox(height: 30),

            // Daily Stats Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: InkWell(
                onTap: widget.onNavigateToReport,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Statistik Harian',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: kLightGreyText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Daily Stats Cards
            DailyStatsRow(
              eatFrequency: eatFrequency,
              tdee: tdee,
            ),
            const SizedBox(height: 30),

            // Meal Cards (Horizontal Scroll)
            MealCardsSection(
              meals: meals,
              onNavigateToMeal: widget.onNavigateToMeal,
            ),
            const SizedBox(height: 15),

            // Upcoming Meals Header & List
            UpcomingMealsList(
              upcomingMeals: upcomingMeals,
              onNavigateToSchedule: widget.onNavigateToSchedule,
              onToggleMealDone: _toggleMealDone,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 📈 KOMPONEN: BMI SECTION
// ===============================================
class BmiSection extends StatelessWidget {
  final double bmi;
  final String category;
  final Color color;
  final String description;

  const BmiSection({
    super.key,
    required this.bmi,
    required this.category,
    required this.color,
    required this.description,
  });

  double _getIndicatorPosition(double screenWidth) {
    // BMI ranges: <18.5, 18.5-25, 25-30, >30
    // Position percentages: 0-25%, 25-50%, 50-75%, 75-100%
    if (bmi < 18.5) {
      return (bmi / 18.5) * 0.25 * (screenWidth - 32);
    } else if (bmi < 25) {
      return (0.25 + ((bmi - 18.5) / 6.5) * 0.25) * (screenWidth - 32);
    } else if (bmi < 30) {
      return (0.50 + ((bmi - 25) / 5) * 0.25) * (screenWidth - 32);
    } else {
      final position = 0.75 + ((bmi - 30) / 10) * 0.25;
      return (position > 1.0 ? 1.0 : position) * (screenWidth - 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kMutedBorderGrey, width: 1.4),
          boxShadow: [
            BoxShadow(
              // FIX: Menggunakan withOpacity
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'IMT saat ini',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 14,
                          color: kLightGreyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          // FIX: Menggunakan withOpacity
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // BMI Bar dengan indicator
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    // FIX: Menggunakan withOpacity
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          kBlue,
                          kGreen,
                          kOrange,
                          kRed,
                        ],
                        stops: [0.0, 0.25, 0.50, 0.75],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Labels dengan angka
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Under',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '<18.5',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (screenWidth - 32) * 0.25 + 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Normal',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '18.5-25',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (screenWidth - 32) * 0.50 + 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Over',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '25-30',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Obese',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '>30',
                            style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              // FIX: Menggunakan withOpacity
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Indicator hitam transparan (40% opacity)
                  Positioned(
                    left: _getIndicatorPosition(screenWidth),
                    top: -5,
                    bottom: -5,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        // FIX: Menggunakan withOpacity
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            // FIX: Menggunakan withOpacity
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                color: kGreyText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 📊 KOMPONEN: DAILY STATS ROW & STAT CARD
// ===============================================
class DailyStatsRow extends StatelessWidget {
  final int eatFrequency;
  final double tdee;

  const DailyStatsRow({
    super.key,
    required this.eatFrequency,
    required this.tdee,
  });

  @override
  Widget build(BuildContext context) {
    final bmr = tdee / 1.375;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: StatCard(
              title: 'Makan',
              value: '$eatFrequency',
              delta: 'kali/hari',
              icon: Icons.restaurant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: 'BMR',
              value: bmr.toStringAsFixed(0),
              delta: 'kcal/hari',
              icon: Icons.favorite,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: 'TDEE',
              value: tdee.toStringAsFixed(0),
              delta: 'kcal/hari',
              icon: Icons.local_fire_department,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDelta = delta.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // FIX: Menggunakan withOpacity
          color: kMutedBorderGrey.withValues(alpha: 0.3), 
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            // FIX: Menggunakan withOpacity
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kGreenLight.withValues(alpha: 0.2),
                      kGreen.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [kGreenLight, kGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Icon(
                    icon,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 10,
                    color: kLightGreyText,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (hasDelta) ...[
            const SizedBox(height: 2),
            Text(
              delta,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 10,
                color: kLightGreyText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===============================================
// 🍽️ MEAL CARDS SECTION (Horizontal Scroll)
// ===============================================

class MealCardsSection extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final VoidCallback onNavigateToMeal;

  const MealCardsSection({
    super.key,
    required this.meals,
    required this.onNavigateToMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: InkWell(
            onTap: onNavigateToMeal,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rekomendasi Menu',
                  style: TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: kLightGreyText),
              ],
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Empty state
        if (meals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tidak ada rekomendasi menu yang tersedia saat ini (periksa data Firestore/Storage).',
              style: TextStyle(
                fontFamily: 'Funnel Display',
                color: kLightGreyText,
                fontSize: 12,
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: meals.length,
              itemBuilder: (context, i) => _MealCard(meal: meals[i]),
            ),
          ),
      ],
    );
  }
}

// ===============================================
// 🍱 MEAL CARD ITEM
// ===============================================

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final mealType = meal['type'] ?? '';
    final mealName = meal['name'] ?? '';
    final tag1 = meal['tag1'] ?? '';
    final calories = meal['calories'] ?? 0;
    final price = meal['price'] ?? 0;
    final imageUrl = meal['image'] ?? '';

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Type
          Text(
            mealType,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 6),

          // Card Wrapper
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE + TAG
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Stack(
                    children: [
                      _buildMealImage(imageUrl),

                      // TAG
                      if (tag1.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kGreenLight, kGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag1,
                              style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // TEXT CONTENT
                Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealName,
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.black87,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      Text(
                        '$calories kcal',
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 9,
                          color: kLightGreyText,
                        ),
                      ),

                      const SizedBox(height: 1),

                      Text(
                        'Rp ${_formatRupiah(price)}',
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // 🔧 Helper: Image Loader
  // =======================================================
  Widget _buildMealImage(String url) {
    if (url.isEmpty) {
      return _placeholderImage();
    }

    return Image.network(
      url,
      height: 150,
      width: 150,
      fit: BoxFit.cover,
      cacheWidth: 450,
      cacheHeight: 450,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          height: 150,
          width: 150,
          color: Colors.grey[200],
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
                color: kGreen,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error');
        return _placeholderImage();
      },
    );
  }

  // Placeholder untuk gambar gagal
  Widget _placeholderImage() {
    return Container(
      height: 150,
      width: 150,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  // Helper format harga
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}


// ===============================================
// 📅 KOMPONEN: UPCOMING MEALS LIST
// ===============================================
class UpcomingMealsList extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingMeals;
  final VoidCallback onNavigateToSchedule;
  final Function(int) onToggleMealDone;
  
  const UpcomingMealsList({
    super.key,
    required this.upcomingMeals,
    required this.onNavigateToSchedule,
    required this.onToggleMealDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onNavigateToSchedule,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Makan Hari Ini',
                  style: TextStyle(
                    fontFamily: 'Funnel Display',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: kLightGreyText),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Column(
            children: upcomingMeals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              final isLast = index == upcomingMeals.length - 1;
              
              return MealListItem(
                time: meal['time'] as String,
                clock: meal['clock'] as String,
                name: meal['name'] as String,
                isDone: meal['isDone'] as bool,
                isLast: isLast,
                onToggle: () => onToggleMealDone(index),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class MealListItem extends StatelessWidget {
  final String time;
  final String clock;
  final String name;
  final bool isDone;
  final bool isLast;
  final VoidCallback onToggle;

  const MealListItem({
    required this.time,
    required this.clock,
    required this.name,
    required this.isDone,
    this.isLast = false,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              // Checkbox Icon - Clickable
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDone ? kGreen : kMutedBorderGrey,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: isDone ? kGreen : Colors.white,
                  ),
                  child: isDone
                      ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Meal Time and Clock
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Funnel Display',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: kLightGreyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          clock,
                          style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 12,
                            color: kLightGreyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Meal Name (Aligned Right)
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Funnel Display',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            // FIX: Menggunakan withOpacity
            color: kMutedBorderGrey.withValues(alpha: 0.3),
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }
}