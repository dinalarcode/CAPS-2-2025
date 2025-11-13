import 'package:flutter/material.dart';
import 'package:nutrilink/meal/filter_popup.dart'; // Import Pop-up Filter yang akan kita buat
import 'package:nutrilink/meal/food_detail_popup.dart';

// Inilah layar utama untuk fitur Rekomendasi Makanan
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  Set<String> _selectedFilters = {};

  final List<Map<String, String>> breakfastItems = const [
    {'name': 'Caesar Salad', 'cal': '450 kkal', 'price': 'Rp 40.000', 'tags': 'Sayuran, Ayam'},
    {'name': 'Spaghetti Bolognese', 'cal': '525 kkal', 'price': 'Rp 41.000', 'tags': 'Sapi'},
    {'name': 'Nasi Goreng', 'cal': '470 kkal', 'price': 'Rp 38.000', 'tags': 'Ayam'},
  ];

  final List<Map<String, String>> lunchItems = const [
    {'name': 'Dada Ayam Panggang', 'cal': '420 kkal', 'price': 'Rp 45.000', 'tags': 'Ayam'},
    {'name': 'Udang Saos Tiram', 'cal': '550 kkal', 'price': 'Rp 42.000', 'tags': 'Udang'},
    {'name': 'Steak Ayam', 'cal': '630 kkal', 'price': 'Rp 47.000', 'tags': 'Ayam, Sapi'},
  ];
  
  final List<Map<String, String>> dinnerItems = const [
    {'name': 'Salmon Panggang', 'cal': '480 kkal', 'price': 'Rp 55.000', 'tags': 'Ikan'},
    {'name': 'Tuna Salad', 'cal': '390 kkal', 'price': 'Rp 35.000', 'tags': 'Ikan, Sayuran'},
  ];

 void _showFilter(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return FilterFoodPopup(
        initialFilters: _selectedFilters,
        onFiltersChanged: (newFilters) {
          setState(() {
            _selectedFilters = newFilters;
          });
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dikosongkan agar header profil bisa naik
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Profil Pengguna dan Target
            _UserProfileHeader(onFilterPressed: () => _showFilter(context)),
            const SizedBox(height: 16),
            // 2. Filter Tag yang Aktif
            _TagFilterSection(selectedFilters: _selectedFilters),
            const SizedBox(height: 16),
            // 3. Daftar Rekomendasi Makanan - Sarapan
            _FoodRecommendationList(
              title: 'Sarapan',
              items: breakfastItems,
            ),
            // 4. Daftar Rekomendasi Makanan - Makan Siang
            _FoodRecommendationList(
              title: 'Makan Siang',
              items: lunchItems,
            ),
            // 5. Daftar Rekomendasi Makanan - Makan Malam
            _FoodRecommendationList(
              title: 'Makan Malam',
              items: dinnerItems,
            ),
            const SizedBox(height: 100), 
          ],
        ),
      ),
      bottomNavigationBar: const _CustomBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFE57373),
        shape: const CircleBorder(),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// --- Semua Widget Pendukung Lainnya ---

class _UserProfileHeader extends StatelessWidget {
  final VoidCallback onFilterPressed;
  const _UserProfileHeader({required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    // ... (Implementasi Row, CircleAvatar, Text, dan Icon yang sama)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            // Ganti dengan placeholder atau assets yang sesuai
            backgroundColor: Colors.blueGrey,
            child: Text('JC', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'John Cena',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Text('2384 kkal/day (1130 kkal)'),
                    SizedBox(width: 8),
                    Icon(Icons.circle, size: 5, color: Colors.red),
                    SizedBox(width: 8),
                    Text('77.0 kg'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Target: 65.0 kg (+12.0 kg)', style: TextStyle(color: Colors.green)),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const Text('Surabaya, Jawa Timur', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFilterPressed, // Panggil fungsi _showFilter
            icon: const Icon(Icons.filter_list, color: Colors.black, size: 30),
          ),
        ],
      ),
    );
  }
}

class _TagFilterSection extends StatelessWidget {
  final Set<String> selectedFilters;

  const _TagFilterSection({required this.selectedFilters});

  @override
  Widget build(BuildContext context) {
    final List<String> activeTags = selectedFilters.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Tag Filter',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: activeTags.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Chip(
                  label: Text(activeTags[index]),
                  backgroundColor: Colors.green.shade100,
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodRecommendationList extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;

  const _FoodRecommendationList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _FoodCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Map<String, String> item;

  const _FoodCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final tags = item['tags']!.split(', ');
    return GestureDetector(
      onTap: () => showFoodDetailPopup(context, item),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Image.network(
                    'https://placehold.co/150x100/90EE90/000?text=${item['name']}', // Placeholder gambar
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: Center(child: Text(item['name']!, textAlign: TextAlign.center)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags di Card
                    Row(
                      children: tags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _SmallTag(
                            label: tag, 
                            color: tag == 'Ayam' ? Colors.red : Colors.green),
                      )).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(item['cal']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item['price']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  const _CustomBottomNavBar();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> navItems = [
      {'icon': Icons.calendar_today, 'label': 'Schedule'},
      {'icon': Icons.restaurant_menu, 'label': 'Meal'},
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.bar_chart, 'label': 'Report'},
      {'icon': Icons.person, 'label': 'Profile'},
    ];

    return BottomAppBar(
      height: 70,
      color: Colors.white,
      elevation: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.map((item) {
          return InkWell(
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: item['label'] == 'Home' ? Colors.green : Colors.grey,
                ),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: item['label'] == 'Home' ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
