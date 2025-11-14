// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class AllergyPage extends StatefulWidget {
  const AllergyPage({super.key});
  @override
  State<AllergyPage> createState() => _AllergyPageState();
}

class _AllergyPageState extends State<AllergyPage> {
  // Menggunakan late final karena getDraft(context) perlu context
  late UserProfileDraft draft;

  // Daftar Opsi Alergi dengan placeholder gambar (gunakan assets/images/ di proyek Anda)
  static const List<Map<String, String>> _allergyOptions = [
    {'name': 'Seafood', 'image': 'assets/images/Seafood.png'},
    {'name': 'Ikan', 'image': 'assets/images/Fish.png'},
    {'name': 'Udang', 'image': 'assets/images/Shrimp.png'},
    {'name': 'Sapi', 'image': 'assets/images/Beef.png'},
    {'name': 'Ayam', 'image': 'assets/images/Chicken.png'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inisialisasi draft di sini
    draft = getDraft(context);
  }

  // --- Widget Kustom untuk Pilihan Alergi ---
  Widget _buildAllergyOption(Map<String, String> option) {
    final name = option['name']!;
    final isSelected = draft.allergies.contains(name);
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              // Hapus alergi
              draft.allergies.remove(name);
            } else {
              // Tambah alergi
              draft.allergies.add(name);
            }
          });
        },
        // Tombol Pilihan Gaya Kartu
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // Border tebal jika terpilih
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFBDBDBD),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isSelected ? 0.15 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bagian Gambar (25% lebar)
              Container(
                width: 80,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                  image: DecorationImage(
                    image: AssetImage(option['image']!),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    // Menggelapkan gambar jika tidak terpilih agar teks lebih jelas
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: isSelected ? 0.0 : 0.2),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              // Bagian Label Teks
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Alergi Makanan',
      onBack: () => back(context, draft),
      // MENGHILANGKAN PARAMETER 'footer' YANG ERROR
      onNext: () {
        // Navigasi ke halaman selanjutnya
        next(context, '/eat-frequency', draft);
      },
      
      // CHILD MENGANDUNG SEMUA KOMPONEN
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apa saja alergi kamu?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F9C3F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kami akan mempersonalisasikan menu makanan yang tidak mengandung alergi kamu.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Daftar Pilihan Alergi
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _allergyOptions.map((opt) => _buildAllergyOption(opt)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}