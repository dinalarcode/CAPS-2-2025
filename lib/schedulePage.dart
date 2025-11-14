import 'package:flutter/material.dart';
import 'editedMenuPage.dart'; // Import EditedMenuPage
import 'tambahMenuPage.dart';

// --- Data Model Sederhana ---
class Meal {
  final String time;
  final String name;
  final String calories;
  final String protein;
  final String fat;
  final String carbs;
  final String imageUrl;

  Meal({
    required this.time,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.imageUrl,
  });
}

// Data dummy (Pastikan path asset di pubspec.yaml sudah benar)
final List<Meal> dummyMeals = [
  Meal(
    time: '06:30',
    name: 'Roti Ayam Panggang',
    calories: '250',
    protein: '37g',
    fat: '43g',
    carbs: '31g',
    imageUrl: 'assets/images/roti_ayam_panggang.jpg', // Contoh path asset
  ),
  Meal(
    time: '14:00',
    name: 'Roti Bakar Telur',
    calories: '250',
    protein: '35g',
    fat: '55g',
    carbs: '34g',
    imageUrl: 'assets/images/makan_siang.jpg', // Contoh path asset
  ),
  Meal(
    time: '19:00',
    name: 'roti bakar telur',
    calories: '240',
    protein: '32g',
    fat: '51g',
    carbs: '32g',
    imageUrl: 'assets/images/makan_malam.jpg', // Contoh path asset
  ),
];

// ===============================================
// 🎯 KELAS UTAMA: SCHEDULEPAGE
// ===============================================

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String _selectedMonthYear = 'April 2025';
  int _selectedDate = 1;

  // Daftar bulan/tahun untuk Dropdown
  final List<String> _monthYears = [
    'April 2025',
    'Maret 2025',
    'Februari 2025',
    'Januari 2025',
  ];

  // Data dummy untuk hari dan tanggal, DITINGKATKAN untuk menyimpan nama hari lengkap
  final List<Map<String, dynamic>> dailySchedule = [
    {'day': 'Senin', 'date': 1, 'isToday': true},
    {'day': 'Selasa', 'date': 2, 'isToday': false},
    {'day': 'Rabu', 'date': 3, 'isToday': false},
    {'day': 'Kamis', 'date': 4, 'isToday': false},
    {'day': 'Jumat', 'date': 5, 'isToday': false},
    {'day': 'Sabtu', 'date': 6, 'isToday': false},
    {'day': 'Minggu', 'date': 7, 'isToday': false},
    {'day': 'Senin', 'date': 8, 'isToday': false},
    {'day': 'Selasa', 'date': 9, 'isToday': false},
    {'day': 'Rabu', 'date': 10, 'isToday': false},
    {'day': 'Kamis', 'date': 11, 'isToday': false},
    {'day': 'Jumat', 'date': 12, 'isToday': false},
    {'day': 'Sabtu', 'date': 13, 'isToday': false},
    {'day': 'Minggu', 'date': 14, 'isToday': false},

  ];

  // Fungsi untuk mendapatkan teks tanggal lengkap
  String _getFullDateText() {
    final selectedDay = dailySchedule.firstWhere(
        (day) => day['date'] == _selectedDate,
        orElse: () => {'day': 'Senin', 'date': 1, 'isToday': true});

    final dayName = selectedDay['day'];
    final date = selectedDay['date'].toString().padLeft(2, '0');
    final monthYear = _selectedMonthYear.replaceAll(' ', ' ');
    return '$dayName, $date $monthYear';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar transparan dan tanpa bayangan
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Bagian Header (Tombol Kembali, Judul)
          _AppBarContent(),

          const SizedBox(height: 10),

          // Pemilih Bulan dan Tahun
          _MonthYearSelector(
            selectedMonthYear: _selectedMonthYear,
            monthYears: _monthYears,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedMonthYear = newValue;
                  // Reset tanggal saat bulan berubah
                  _selectedDate = 1;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Pemilih Hari/Tanggal
          _DayOfWeekSelector(
            selectedDate: _selectedDate,
            dailySchedule: dailySchedule, // Kirim data jadwal
            onDateSelected: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          ),

          const SizedBox(height: 10), // Jarak pemisah

          // TANGGAL LENGKAP & ICON PLUS (DIPINDAHKAN KE SINI)
          _FullDateDisplay(
            fullDateText: _getFullDateText(),
          ),

          const SizedBox(height: 20),

          // Daftar Jadwal Makan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: dummyMeals.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _MealCard(meal: dummyMeals[index]),
                );
              },
            ),
          ),
        ],
      ),
      // bottomNavigationBar di-handle oleh HomeShell
    );
  }
}

// ===============================================
// 🖼️ WIDGET PENDUKUNG
// ===============================================

// Widget baru untuk menampilkan Tanggal Lengkap dan Icon Plus
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
                  builder: (context) => const TambahMenuPage(), // <--- NAVIGASI KE HALAMAN BARU
                ),
              );
            },
            radius: 20,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.add_circle_outline, // Icon Plus
                color: Color(0xFF4CAF50),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Tombol Kembali
          GestureDetector(
            onTap: () {
              // Jika halaman ini didorong (pushed) ke stack, gunakan pop
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
          // Judul
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
              color: const Color(0xFF4CAF50), // Background hijau muda
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
                dropdownColor: const Color(0xFF4CAF50),
                elevation: 1,
                items: monthYears.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.split(' ')[0]), // Hanya menampilkan Bulan
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
  final int selectedDate;
  final ValueChanged<int> onDateSelected;
  final List<Map<String, dynamic>> dailySchedule; // Tambahkan data jadwal

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
        // Daftar Hari (PADA BAGIAN ATAS)
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: dailySchedule.length,
            itemBuilder: (context, index) {
              final item = dailySchedule[index];
              final isSelected = item['date'] == selectedDate;

              return GestureDetector(
                onTap: () => onDateSelected(item['date']),
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
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
                          item['date'].toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF4CAF50) : Colors.black,
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

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  String _getMealType(String time) {
    // Memecah string waktu "HH:MM" menjadi jam (HH)
    final hour = int.tryParse(time.split(':')[0]) ?? 0;

    if (hour >= 4 && hour <= 10) {
      return 'Sarapan';
    } else if (hour >= 11 && hour <= 16) {
      return 'Makan Siang';
    } else if (hour >= 17 && hour <= 23) {
      return 'Makan Malam';
    } else {
      return 'Camilan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealType = _getMealType(meal.time);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BARIS 1: WAKTU MAKAN & IKON ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${meal.time} $mealType', // Tambah label Sarapan/Makan Siang
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  // Icon Edit
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkResponse(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditedMenuPage(), // Perbaikan nama kelas
                          ),
                        );
                      },
                      radius: 20,
                      splashColor: const Color.fromARGB(
                        255,
                        137,
                        230,
                        98,
                      ).withValues(alpha: 0.2),
                      highlightColor: Colors.transparent,
                      containedInkWell: true,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Icon Notifikasi
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkResponse(
                      onTap: () {
                      },
                      radius: 20,
                      splashColor: const Color.fromARGB(
                        255,
                        137,
                        230,
                        98,
                      ).withValues(alpha: 0.2),
                      highlightColor: Colors.transparent,
                      containedInkWell: true,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.notifications_none,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // --- BARIS 2: GAMBAR MAKANAN (ASPEK RASIO 1:1) ---
          AspectRatio(
            aspectRatio: 1.0, // Memaksa rasio 1:1 (Kotak)
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(meal.imageUrl), // <--- NetworkImage digunakan untuk URL,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // --- BATAS NYATA ---
          const SizedBox(height: 5), // Jarak antara gambar dan detail
          // --- BARIS 3: DETAIL MAKANAN (Makro, Nama & Kalori) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detail Makro
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildMacroItem(meal.protein, 'P', isBlack: true),
                    _buildMacroItem(meal.fat, 'L', isBlack: true),
                    _buildMacroItem(meal.carbs, 'K', isBlack: true),
                  ],
                ),
                const SizedBox(height: 8),

                // Nama Makanan dan Kalori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Item Makro
  Widget _buildMacroItem(String value, String label, {bool isBlack = false}) {
    final color = isBlack ? Colors.black : Colors.white;
    final secondaryColor = isBlack ? Colors.grey : Colors.white70;

    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Row(
        children: [
          // Icon untuk membedakan item (opsional, bisa diganti)
          Icon(Icons.circle, size: 8, color: secondaryColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: secondaryColor, fontSize: 12)),
        ],
      ),
    );
  }
}