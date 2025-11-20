import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

// --- Global Constants ---
const Color kBackgroundColor = Colors.white;
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kLightYellow = Color(0xFFFFFBE0);
const Color kLightGreenBackground = Color(0xFFE5F5E5);
const Color kLightGreyText = Color(0xFF9E9E9E);
const Color kGreen = Color(0xFF5F9C3F);

// ===============================================
// 🎯 KELAS UTAMA: TambahMenuPage (Stateful untuk Stream)
// ===============================================

class TambahMenuPage extends StatefulWidget {
  const TambahMenuPage({super.key});

  @override
  State<TambahMenuPage> createState() => _TambahMenuPageState();
}

class _TambahMenuPageState extends State<TambahMenuPage> {
  // ✅ BASE URL DENGAN PROJECT ID ANDA SUDAH BENAR
  final String baseImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/nutrilink-5f07f.appspot.com/o/menus%2F';
  final String imageSuffix = '?alt=media';

  final Stream<QuerySnapshot> _menuStream =
      FirebaseFirestore.instance.collection('menus').snapshots();

  // Data Dummy untuk Bagian Menu Hari Ini
  final List<Map<String, dynamic>> currentDayMeals = const [
    {
      'type': 'Sarapan',
      'name': 'Roti Ayam Panggang',
      'calories': '250 Kcal',
      'protein': '37g',
      'fat': '43g',
      'carbs': '31g',
      'imageUrl': '1001.png'
    },
    {
      'type': 'Makan Siang',
      'name': 'Ayam Teriyaki brokoli',
      'calories': '550 Kcal',
      'protein': '35g',
      'fat': '55g',
      'carbs': '34g',
      'imageUrl': '1002.png'
    },
    {
      'type': 'Makan Malam',
      'name': 'Salad',
      'calories': '450 Kcal',
      'protein': '28g',
      'fat': '45g',
      'carbs': '25g',
      'imageUrl': '1003.png'
    },
  ];

  // Helper Statis untuk Makro (Protein, Fat, Carbs)
  static Widget _buildMacroIcon(IconData icon, String value) {
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

  static Widget _buildMacroText(String value, String label) {
    return Text(
      '$value $label',
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tambah Menu Makan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Menu Hari Ini ---
            const Text(
              'Menu Hari Senin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 10),
            CurrentDayMealsBox(
                meals: currentDayMeals,
                baseImageUrl: baseImageUrl,
                imageSuffix: imageSuffix),

            const SizedBox(height: 25),

            // --- Menu/Camilan Lain ---
            const Text(
              'Tambah Menu/Camilan lain',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 10),
            SuggestedMealsBox(
              menuStream: _menuStream,
              baseImageUrl: baseImageUrl,
              imageSuffix: imageSuffix,
              // ✅ NAVIGASI KE RECOMMENDATION SCREEN
              onViewAll: () {
                Navigator.pushNamed(context, '/recommendation');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 🟡 Bagian Atas: CurrentDayMealsBox
// ===============================================

class CurrentDayMealsBox extends StatelessWidget {
  final List<Map<String, dynamic>> meals;
  final String baseImageUrl;
  final String imageSuffix;
  const CurrentDayMealsBox(
      {required this.meals,
      required this.baseImageUrl,
      required this.imageSuffix,
      super.key});

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
        children: meals.asMap().entries.map((entry) {
          final i = entry.key;
          final meal = entry.value;

          return Column(
            children: [
              CurrentMealItem(
                meal: meal,
                baseImageUrl: baseImageUrl,
                imageSuffix: imageSuffix,
              ),
              if (i < meals.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child:
                      Divider(height: 1, color: Colors.black12, thickness: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class CurrentMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String baseImageUrl;
  final String imageSuffix;
  const CurrentMealItem(
      {required this.meal,
      required this.baseImageUrl,
      required this.imageSuffix,
      super.key});

  @override
  Widget build(BuildContext context) {
    // URL ENCODING: Menggabungkan base URL, nama file yang di-encode, dan suffix
    final String imageFileName = meal['imageUrl'] as String? ?? '';
    final String encodedFileName = Uri.encodeComponent(imageFileName);
    final String imageUrl = '$baseImageUrl$encodedFileName$imageSuffix';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gambar (Rasio 1:1)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade300,
                child: const Center(
                    child: Icon(Icons.error_outline, color: kTextColor)),
              ),
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
                        _TambahMenuPageState._buildMacroIcon(
                            Icons.monitor_weight_outlined,
                            meal['protein']), // P
                        _TambahMenuPageState._buildMacroIcon(
                            Icons.egg_outlined, meal['fat']), // L
                        _TambahMenuPageState._buildMacroIcon(
                            Icons.bakery_dining_outlined, meal['carbs']), // K
                      ],
                    ),
                    Text(
                      meal['calories'],
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextColor),
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
}

// ===============================================
// 📦 SuggestedMealsBox (Batasi 4 Menu + Navigasi)
// ===============================================

class SuggestedMealsBox extends StatelessWidget {
  final Stream<QuerySnapshot> menuStream;
  final String baseImageUrl;
  final String imageSuffix;
  final VoidCallback onViewAll;

  const SuggestedMealsBox({
    required this.menuStream,
    required this.baseImageUrl,
    required this.imageSuffix,
    required this.onViewAll,
    super.key,
  });

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
      child: StreamBuilder<QuerySnapshot>(
        stream: menuStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada menu saran.'));
          }

          // Batasi tampilan hanya 4 menu teratas
          final allMeals = snapshot.data!.docs;
          final displayedMeals = allMeals.take(4).toList();
          final bool hasMore = allMeals.length > 4;

          return Column(
            children: [
              ...displayedMeals.asMap().entries.map((entry) {
                final i = entry.key;
                final data = entry.value.data()! as Map<String, dynamic>;

                final mealData = {
                  'name': data['name'],
                  // Pastikan konversi ke String untuk Kcal, g
                  'calories': '${data['calories'].toString()} Kcal',
                  'protein': '${data['protein'].toString()}g',
                  'fat': '${data['fat'].toString()}g',
                  'carbs': '${data['carbohydrate'].toString()}g',
                  'imageUrl': data['image'], // Nama file dari Firestore
                };

                return Column(
                  children: [
                    SuggestionMealItem(
                      meal: mealData,
                      baseImageUrl: baseImageUrl,
                      imageSuffix: imageSuffix,
                    ),
                    if (i < displayedMeals.length - 1)
                      Divider(
                          height: 5, color: Colors.grey.shade200, thickness: 1),
                  ],
                );
              }),

              // Tombol Lihat Semua Menu
              if (hasMore) ...[
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton(
                    onPressed:
                        onViewAll, // Memicu Navigator.pushNamed('/recommendation')
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kAccentGreen,
                      side: BorderSide(color: kAccentGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Lihat Semua Menu'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class SuggestionMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;
  final String baseImageUrl;
  final String imageSuffix;
  const SuggestionMealItem(
      {required this.meal,
      required this.baseImageUrl,
      required this.imageSuffix,
      super.key});

  @override
  Widget build(BuildContext context) {
    // URL ENCODING
    final String imageFileName = meal['imageUrl'] as String? ?? '';
    final String encodedFileName = Uri.encodeComponent(imageFileName);
    final String imageUrl = imageFileName.isNotEmpty
        ? '$baseImageUrl$encodedFileName$imageSuffix'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gambar (Rasio 1:1)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade300,
                child: const Center(
                    child: Icon(Icons.error_outline, color: kTextColor)),
              ),
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
                    _TambahMenuPageState._buildMacroText(meal['protein'], 'P'),
                    _TambahMenuPageState._buildMacroText(meal['fat'], 'L'),
                    _TambahMenuPageState._buildMacroText(meal['carbs'], 'K'),
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
                onPressed: () async {
                  print("=== ADD BUTTON PRESSED ===");

                  final now = DateTime.now();
                  final todayKey = "${now.year}-${now.month}-${now.day}";

                  // convert meal into correct format
                  final menuToSave = {
                    "name": meal['name'],
                    "imageUrl": meal['imageUrl'],
                    "calories": int.tryParse(meal['calories']
                            .toString()
                            .replaceAll(" Kcal", "")) ??
                        0,
                    "protein": int.tryParse(
                            meal['protein'].toString().replaceAll("g", "")) ??
                        0,
                    "carbs": int.tryParse(
                            meal['carbs'].toString().replaceAll("g", "")) ??
                        0,
                    "fat": int.tryParse(
                            meal['fat'].toString().replaceAll("g", "")) ??
                        0,
                    "isDone": false,
                  };

                  print("Saving menu:");
                  print(menuToSave);

                  // load old data
                  final prefs = await SharedPreferences.getInstance();
                  final existing = prefs.getString(todayKey);

                  List meals = [];

                  if (existing != null) {
                    final decoded = jsonDecode(existing);
                    meals = decoded["meals"];
                  }

                  // add new meal
                  meals.add(menuToSave);

                  final finalData = {
                    "date": todayKey,
                    "meals": meals,
                  };

                  // save it
                  await prefs.setString(todayKey, jsonEncode(finalData));

                  print("=== SAVED ===");
                  print(jsonEncode(finalData));

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("${meal['name']} ditambahkan ke jadwal")),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
