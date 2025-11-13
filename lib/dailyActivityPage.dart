import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class DailyActivityPage extends StatefulWidget {
  const DailyActivityPage({super.key});
  @override
  State<DailyActivityPage> createState() => _DailyActivityPageState();
}

class _DailyActivityPageState extends State<DailyActivityPage> {
  late UserProfileDraft draft;

  // Mendefinisikan opsi lengkap dengan label panjang dan nilai (value) yang digunakan.
  static const List<Map<String, dynamic>> _activityOptions = [
    {
      'label': 'Sangat Rendah (Sedentary lifestyle)',
      'value': 'sedentary',
      'icon': Icons.self_improvement,
    },
    {
      'label': 'Rendah (1-3x Olahraga per minggu)',
      'value': 'lightly_active',
      'icon': Icons.run_circle_outlined,
    },
    {
      'label': 'Sedang (4-5x Olahraga per Minggu)',
      'value': 'moderately_active',
      'icon': Icons.sports_gymnastics,
    },
    {
      'label': 'Tinggi (Olahraga tiap hari/Olahraga intens 3-4x per minggu)',
      'value': 'very_active',
      'icon': Icons.fitness_center,
    },
    {
      'label': 'Sangat Tinggi (Olahraga intens 6-7x per minggu)',
      'value': 'extremely_active_1',
      'icon': Icons.directions_run,
    },
    {
      'label': 'Sangat Sangat Tinggi (Olahraga intens tiap hari/pekerjaan fisik)',
      'value': 'extremely_active_2',
      'icon': Icons.construction,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
  }

  // Helper untuk Tombol Pilihan Vertikal
  Widget _buildActivityOption(
    BuildContext context,
    Map<String, dynamic> option,
  ) {
    final isSelected = draft.activityLevel == option['value'];
    final primaryColor = Theme.of(context).primaryColor;
    
    // Warna untuk tombol yang dipilih dan tidak dipilih
    final color = isSelected ? primaryColor : Colors.white;
    final labelColor = isSelected ? Colors.white : Colors.black87;
    final iconColor = isSelected ? Colors.white : primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          setState(() {
            // Set nilai ke draft
            draft.activityLevel = option['value'] as String;
            // Di sini Anda juga bisa mengatur activityFactor jika diperlukan
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.5), width: isSelected ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(option['icon'] as IconData, color: iconColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk Kotak Peringatan (Hint Box)
  Widget _buildHintBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF0), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E0D0)), 
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning_amber, color: Color(0xFF5F9C3F), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Jika kamu tidak yakin opsi mana untuk dipilih, lebih baik pilih opsi paling rendah untuk menghindari kebutuhan kalori yang berlebihan.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Aktivitas Harian',
      onBack: () => back(context, draft),
      onNext: () {
        if (draft.activityLevel == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih tingkat aktivitas harian Anda terlebih dahulu.')),
          );
          return;
        }
        // Navigasi ke halaman selanjutnya
        next(context, '/allergy', draft);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seberapa tinggi tingkat aktivitas harianmu?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F9C3F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tingkat aktivitasmu akan membantu kita menentukan berapa banyaknya kalori yang dibutuhkan tiap hari.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          _buildHintBox(),

          // List Pilihan Aktivitas (Vertical Buttons)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _activityOptions
                  .map((opt) => _buildActivityOption(context, opt))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}