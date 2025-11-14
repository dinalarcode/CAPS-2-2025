// ini file tambahMenuPage.dart
import 'package:flutter/material.dart';

// --- Global Constants (Digunakan untuk konsistensi warna) ---
const Color kBackgroundColor = Colors.white;
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50); // Hijau dari Day Selector
const Color kLightYellow = Color(0xFFFFFBE0); // Kuning muda untuk container utama
const Color kLightGreenBackground = Color(0xFFE5F5E5); // Hijau sangat muda untuk background list

// Data Dummy untuk Bagian Menu Hari Ini
final List<Map<String, dynamic>> currentDayMeals = [
  {
    'type': 'Sarapan',
    'name': 'Roti Ayam Panggang',
    'calories': '250 Kcal',
    'protein': '37g',
    'fat': '43g',
    'carbs': '31g',
    'imageUrl': 'assets/images/roti_ayam_panggang.jpg' // Pastikan path benar
  },
  {
    'type': 'Makan Siang',
    'name': 'Ayam Teriyaki brokoli',
    'calories': '550 Kcal',
    'protein': '35g',
    'fat': '55g',
    'carbs': '34g',
    'imageUrl': 'assets/images/makan_siang.jpg' // Pastikan path benar
  },
  {
    'type': 'Makan Malam',
    'name': 'Salad',
    'calories': '450 Kcal',
    'protein': '28g',
    'fat': '45g',
    'carbs': '25g',
    'imageUrl': 'assets/images/makan_malam.jpg' // Pastikan path benar
  },
];

// Data Dummy untuk Bagian Menu Saran/Camilan
final List<Map<String, dynamic>> suggestionMeals = [
  {
    'name': 'Buah Yogurt',
    'calories': '750 Kcal',
    'protein': '16g',
    'fat': '31g',
    'carbs': '45g',
    'imageUrl': 'assets/images/buah_yogurt.jpg'
  },
  {
    'name': 'Nasi Rendang',
    'calories': '615 Kcal',
    'protein': '37g',
    'fat': '43g',
    'carbs': '31g',
    'imageUrl': 'assets/images/nasi_rendang.jpg'
  },
  {
    'name': 'Ayam Panggang',
    'calories': '400 Kcal',
    'protein': '57g',
    'fat': '41g',
    'carbs': '22g',
    'imageUrl': 'assets/images/ayam_panggang.jpg'
  },
];

// ===============================================
// 🎯 KELAS UTAMA: TambahMenuPage
// ===============================================

class TambahMenuPage extends StatelessWidget {
  const TambahMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // 1. App Bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tambah Menu Makan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      
      // 2. Body Content (Scrollable)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Bagian Atas: Menu Hari Ini ---
            const Text(
              'Menu Hari Senin', // Bisa dibuat dinamis
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 10),
            CurrentDayMealsBox(meals: currentDayMeals),
            
            const SizedBox(height: 25),

            // --- Bagian Bawah: Menu/Camilan Lain ---
            const Text(
              'Tambah Menu/Camilan lain',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 10),
            SuggestedMealsBox(meals: suggestionMeals),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 🟡 Bagian Atas: CurrentDayMealsBox (Kuning)
// ===============================================

class CurrentDayMealsBox extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  const CurrentDayMealsBox({required this.meals, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: kLightYellow, 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kTextColor.withValues(alpha: 0.1), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: meals.map((meal) {
          return CurrentMealItem(meal: meal);
        }).toList(),
      ),
    );
  }
}

class CurrentMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;
  const CurrentMealItem({required this.meal, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gambar (Rasio 1:1)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              meal['imageUrl'],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 15),
          // Detail Makanan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['type'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: kTextColor,
                  ),
                ),
                Text(
                  meal['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Makro & Kalori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildMacroIcon(Icons.monitor_weight_outlined, meal['protein']), // P
                        _buildMacroIcon(Icons.egg_outlined, meal['fat']), // L
                        _buildMacroIcon(Icons.bakery_dining_outlined, meal['carbs']), // K
                      ],
                    ),
                    Text(
                      meal['calories'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor),
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
  
  // Widget Pembantu untuk Item Makro (di dalam CurrentMealItem)
  Widget _buildMacroIcon(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kTextColor.withValues(alpha: 0.7)),
          const SizedBox(width: 2),
          Text(value, style: TextStyle(fontSize: 12, color: kTextColor.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

// ===============================================
// 📦 Bagian Bawah: SuggestedMealsBox (Putih dengan tombol +)
// ===============================================

class SuggestedMealsBox extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  const SuggestedMealsBox({required this.meals, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: meals.map((meal) {
          return SuggestionMealItem(meal: meal);
        }).toList(),
      ),
    );
  }
}

class SuggestionMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;
  const SuggestionMealItem({required this.meal, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gambar (Rasio 1:1)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  meal['imageUrl'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 15),
              // Detail Makanan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Makro (Protein, Carb, Fat)
                    Wrap(
                      spacing: 10,
                      children: [
                        _buildMacroText(meal['protein'], 'P'),
                        _buildMacroText(meal['fat'], 'L'),
                        _buildMacroText(meal['carbs'], 'K'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal['calories'] as String,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Tombol Tambah
              Container(
                decoration: BoxDecoration(
                  color: kAccentGreen, 
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                  },
                ),
              ),
            ],
          ),
        ),
        // Divider pemisah, hanya jika bukan item terakhir
        if (suggestionMeals.indexOf(meal) < suggestionMeals.length - 1)
          Divider(height: 5, color: Colors.grey.shade200, thickness: 1),
      ],
    );
  }
  
  Widget _buildMacroText(String value, String label) {
    return Text(
      '$value $label',
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    );
  }
}