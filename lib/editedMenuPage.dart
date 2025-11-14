import 'package:flutter/material.dart';

// --- Global Constants (Asumsi dari file utama) ---
const Color kBackgroundColor = Color.fromRGBO(255, 255, 255, 1);
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50); 
const Color kAccentGreen2 = Color(0xFFCFFFBA); // Warna Kuning Aksen
const Color kLightAccentGreen = Color(0xFFCFFFBA); // Warna Hijau Muda dari Figma

// ===============================================
// 🎯 KELAS UTAMA: EditedMenuPage
// ===============================================
class EditedMenuPage extends StatelessWidget {
  const EditedMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. App Bar (Header dan Tombol Kembali)
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ubah Menu Makan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      
      // 2. Body Content (Scrollable)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            // --- Kartu Menu Saat Ini (Kuning) ---
            CurrentMealCard(),
            SizedBox(height: 25),

            // --- Daftar Menu Saran (Kotak Putih) ---
            SuggestedMealsBox(),
          ],
        ),
      ),
      
      // 3. Bottom Bar (Asumsi sudah di-handle oleh parent Scaffold atau dihilangkan)
      // Jika halaman ini berdiri sendiri, Anda bisa menambahkan BottomNavigationBar di sini
    );
  }
}

// ===============================================
// 🟡 CurrentMealCard (Menu Sarapan saat ini)
// ===============================================
class CurrentMealCard extends StatelessWidget {
  const CurrentMealCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kAccentGreen2, // Warna kuning mencolok
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kTextColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Sarapan saat ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Placeholder Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade300,
                  // Ganti dengan Image.asset atau Image.network
                ),
                child: const Center(child: Icon(Icons.fastfood, size: 40, color: kTextColor)),
              ),
              const SizedBox(width: 15),
              // Meal Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Roti Ayam Panggang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Makro (Menggunakan Icon Placeholder)
                    Row(
                      children: const [
                        Icon(Icons.restaurant_menu, size: 14), // Protein
                        SizedBox(width: 2),
                        Text('37g', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Icon(Icons.grain, size: 14), // Karbohidrat
                        SizedBox(width: 2),
                        Text('43g', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Icon(Icons.archive, size: 14), // Lemak
                        SizedBox(width: 2),
                        Text('31g', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '250 Kcal', // Kalori
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===============================================
// 📦 SuggestedMealsBox (Wadah Menu Saran)
// ===============================================
class SuggestedMealsBox extends StatelessWidget {
  const SuggestedMealsBox({super.key});

  // Data Dummy untuk daftar menu
  final List<Map<String, dynamic>> suggestionMeals = const [
    {'name': 'Caesar Salad', 'protein': '32g', 'carb': '20g', 'fat': '27g', 'calories': '450 Kcal', 'image': 'assets/caesar.jpg'},
    {'name': 'Ayam Panggang', 'protein': '57g', 'carb': '41g', 'fat': '22g', 'calories': '460 Kcal', 'image': 'assets/ayam.jpg'},
    {'name': 'Salad Belanda', 'protein': '27g', 'carb': '41g', 'fat': '22g', 'calories': '340 Kcal', 'image': 'assets/salad.jpg'},
    {'name': 'Capcay Kuah', 'protein': '17g', 'carb': '31g', 'fat': '12g', 'calories': '490 Kcal', 'image': 'assets/capcay.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Sarapan yang lain',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const Divider(height: 20, color: kLightAccentGreen),
          
          // List Suggestion Meals
          ...suggestionMeals.map((meal) {
            return SuggestionMealItem(meal: meal);
          }),
          
          const SizedBox(height: 20),
          
          // Tombol Explore
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentGreen2,
                foregroundColor: kTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send),
              label: const Text(
                'Explore Menu Lainnya',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================
// 🍴 SuggestionMealItem (Item di daftar saran)
// ===============================================
class SuggestionMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;
  const SuggestionMealItem({required this.meal, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade300,
                  ),
                  child: const Center(child: Icon(Icons.local_dining, size: 30, color: kTextColor)),
                ),
                const SizedBox(width: 15),
                // Meal Details
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
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 12),
                          Text('${meal['protein']} 🍗', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.grain, size: 12),
                          Text('${meal['carb']} 🥖', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.archive, size: 12),
                          Text('${meal['fat']} 🧈', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal['calories'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Divider (menggunakan warna hijau muda)
        Divider(height: 5, color: kLightAccentGreen, thickness: 1), 
      ],
    );
  }
}