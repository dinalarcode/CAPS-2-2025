import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showFoodDetailPopup(BuildContext context, Map<String, String> item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => _FoodDetailContent(item: item),
  );
}

class _FoodDetailContent extends StatelessWidget {
  final Map<String, String> item;

  const _FoodDetailContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final tags = item['tags']!.split(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://placehold.co/600x300?text=${item['name']}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            // Nama + kalori
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  item['cal']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tags
            Wrap(
              spacing: 6,
              children: tags.map((tag) {
                Color color = Colors.green;
                if (tag == 'Ayam') color = Colors.redAccent;
                if (tag == 'Ikan') color = Colors.blueAccent;
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: color,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Kandungan Nutrisi
            const Text(
              'Kandungan Nutrisi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                _NutrisiCard(
                  label: 'Protein',
                  value: '32g',
                  color: Colors.blueAccent,
                ),
                _NutrisiCard(
                  label: 'Karbohidrat',
                  value: '50g',
                  color: Colors.amberAccent,
                ),
                _NutrisiCard(
                  label: 'Lemak',
                  value: '27g',
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deskripsi (dummy)
            const Text(
              'Caesar Salad adalah salad klasik berbasis sayuran segar '
              'yang umumnya menggunakan daun selada romaine, disajikan dengan '
              'potongan dada ayam panggang, crouton renyah, parmessan cheese, dan saus creamy. '
              'Salad ini menawarkan rasa gurih, segar, dan seimbang — cocok untuk sarapan ringan '
              'atau menu sehat tinggi protein.',
              style: TextStyle(color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Harga + tombol keranjang
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['price']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      'Sudah termasuk ongkir',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _showCalendarPopup(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child:
                      const Icon(Icons.shopping_cart, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrisiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrisiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showCalendarPopup(BuildContext context) async {
  // 🔹 Ambil messenger di awal, sebelum async gap
  final messenger = ScaffoldMessenger.of(context);

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 30)),
    builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.green,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final formattedDate = DateFormat('dd MMM yyyy').format(picked);
    // 🔹 Pakai messenger, bukan lagi context langsung
    messenger.showSnackBar(
      SnackBar(
        content: Text('Pesanan dijadwalkan untuk $formattedDate'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
