import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart'; // Digunakan untuk format harga 

// --- Global Constants (Diadaptasi dari kode Anda) ---
const Color kBackgroundColor = Color.fromRGBO(255, 255, 255, 1);
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kAccentGreen2 = Color(0xFFCFFFBA); // Warna Kuning Aksen (Digunakan sebagai warna latar)
const Color kLightAccentGreen = Color(0xFFCFFFBA); // Warna Hijau Muda
const Color kLightGreyText = Color(0xFF9E9E9E); // Tambahan: Warna abu-abu terang
const Color kGreen = Color(0xFF5F9C3F); // Tambahan: Warna Hijau Utama

// ===============================================
// 🎯 KELAS UTAMA: EditedMenuPage
// ===============================================
class EditedMenuPage extends StatelessWidget {
  const EditedMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ID Menu yang akan ditampilkan (Menu Saat Ini)
    const String currentMealId = '1001'; 
    
    // Data Dummy untuk daftar menu saran (Jika Firestore belum terintegrasi untuk daftar)
    final List<Map<String, dynamic>> suggestionMeals = [
      {'name': 'Caesar Salad', 'protein': '32g', 'carb': '20g', 'fat': '27g', 'calories': '450 Kcal', 'image': 'assets/caesar.jpg'},
      {'name': 'Ayam Panggang', 'protein': '57g', 'carb': '41g', 'fat': '22g', 'calories': '460 Kcal', 'image': 'assets/ayam.jpg'},
      {'name': 'Salad Belanda', 'protein': '27g', 'carb': '41g', 'fat': '22g', 'calories': '340 Kcal', 'image': 'assets/salad.jpg'},
      {'name': 'Capcay Kuah', 'protein': '17g', 'carb': '31g', 'fat': '12g', 'calories': '490 Kcal', 'image': 'assets/capcay.jpg'},
    ];


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ubah Menu Makan', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Kartu Menu Saat Ini (Menggunakan StreamBuilder untuk Firestore) ---
            CurrentMealCard(mealId: currentMealId),
            const SizedBox(height: 25),

            // --- Daftar Menu Saran (Menggunakan data dummy, tapi siap diubah ke Firestore) ---
            SuggestedMealsBox(suggestionMeals: suggestionMeals),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 🟡 CurrentMealCard (Mengambil data Menu 1001 dari Firestore)
// ===============================================
class CurrentMealCard extends StatelessWidget {
  final String mealId;
  const CurrentMealCard({required this.mealId, super.key});

  // URL dasar gambar Firebase Storage
  final String baseImageUrl = 'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT_ID.appspot.com/o/menus%2F';
  final String imageSuffix = '?alt=media'; // Ganti YOUR_PROJECT_ID dengan ID proyek Anda

  @override
  Widget build(BuildContext context) {
    // 1. Mengambil data dari Firestore menggunakan FutureBuilder
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('menus').doc(mealId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error memuat data: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Menu tidak ditemukan.');
        }

        final data = snapshot.data!.data()!;
        
        // Parsing data dari Firestore (sesuai screenshot Anda)
        final name = data['name'] as String? ?? 'N/A';
        final calories = data['calories'] as int? ?? 0;
        final protein = data['protein'] as int? ?? 0;
        final carbohydrate = data['carbohydrate'] as int? ?? 0;
        final fat = data['fat'] as int? ?? 0;
        final imageFileName = data['image'] as String? ?? ''; 
        final imageUrl = imageFileName.isNotEmpty 
                          ? '$baseImageUrl$imageFileName$imageSuffix' 
                          : null;

        // Tampilan Kartu setelah data berhasil dimuat
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: kAccentGreen2,
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
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, st) => 
                                  const Center(child: Icon(Icons.error, size: 40)),
                            )
                          : const Center(child: Icon(Icons.fastfood, size: 40, color: kTextColor)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Meal Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name, // Nama dari Firestore
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Makro
                        Row(
                          children: [
                            const Icon(Icons.restaurant_menu, size: 14),
                            const SizedBox(width: 2),
                            Text('${protein}g', style: const TextStyle(fontSize: 14)), // Protein
                            const SizedBox(width: 8),
                            const Icon(Icons.grain, size: 14),
                            const SizedBox(width: 2),
                            Text('${carbohydrate}g', style: const TextStyle(fontSize: 14)), // Karbohidrat
                            const SizedBox(width: 8),
                            const Icon(Icons.archive, size: 14),
                            const SizedBox(width: 2),
                            Text('${fat}g', style: const TextStyle(fontSize: 14)), // Lemak
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$calories Kcal', // Kalori dari Firestore
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===============================================
// 📦 SuggestedMealsBox (Wadah Menu Saran)
// ===============================================
class SuggestedMealsBox extends StatelessWidget {
  final List<Map<String, dynamic>> suggestionMeals;
  const SuggestedMealsBox({required this.suggestionMeals, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1), // Menggunakan withOpacity
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
          const Divider(height: 20, color: kLightAccentGreen, thickness: 1),
          
          // List Suggestion Meals
          ...suggestionMeals.map((meal) {
            return SuggestionMealItem(meal: meal);
          }),
          
          const SizedBox(height: 20),
          
          // Tombol Explore
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Tambahkan navigasi ke halaman eksplorasi menu
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
    // Helper untuk format harga (jika data saran diubah ke int)

    return Column(
      children: [
        InkWell(
          onTap: () {
            // Logika untuk memilih menu saran
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Image (Ganti dengan Image.network jika ada URL)
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
                          const Icon(Icons.restaurant_menu, size: 12, color: kLightGreyText),
                          Text('${meal['protein']} 🍗', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.grain, size: 12, color: kLightGreyText),
                          Text('${meal['carb']} 🥖', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.archive, size: 12, color: kLightGreyText),
                          Text('${meal['fat']} 🧈', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal['calories'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextColor),
                      ),
                      // Opsional: Tambahkan harga di sini
                      // Text(priceFormatter.format(meal['price']), style: TextStyle(fontSize: 10, color: kGreen)),
                    ],
                  ),
                ),
                // Tombol 'Pilih Menu' di sini jika diperlukan
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