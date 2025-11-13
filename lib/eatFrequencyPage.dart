import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class EatFrequencyPage extends StatefulWidget {
  const EatFrequencyPage({super.key});
  @override
  State<EatFrequencyPage> createState() => _EatFrequencyPageState();
}

class _EatFrequencyPageState extends State<EatFrequencyPage> {
  late UserProfileDraft draft;

  // Mendefinisikan opsi frekuensi makan
  static const List<Map<String, dynamic>> _frequencyOptions = [
    {
      'label': 'Dua Kali',
      'desc': '(Sarapan dan Makan Malam)',
      'value': 2,
    },
    {
      'label': 'Tiga Kali',
      'desc': '(Sarapan, Makan Siang, dan Makan Malam)',
      'value': 3,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
    // Jika draft.eatFrequency masih null, set default ke 3x
    if (draft.eatFrequency == null) {
      draft.eatFrequency = 3;
    }
  }

  // Helper untuk Tombol Pilihan Vertikal
  Widget _buildFrequencyOption(
    BuildContext context,
    Map<String, dynamic> option,
  ) {
    final isSelected = draft.eatFrequency == option['value'];
    final primaryColor = Theme.of(context).primaryColor;
    
    final color = isSelected ? primaryColor : Colors.white;
    final labelColor = isSelected ? Colors.white : Colors.black87;
    final borderColor = isSelected ? primaryColor : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          setState(() {
            draft.eatFrequency = option['value'] as int;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option['label'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option['desc'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: labelColor.withOpacity(0.8),
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
          Icon(Icons.lightbulb_outline, color: Color(0xFF5F9C3F), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ini akan mempengaruhi rencana nutrisi harianmu.',
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
      title: 'Frekuensi Makan',
      onBack: () => back(context, draft),
      onNext: () {
        if (draft.eatFrequency == null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih intensitas makan Anda terlebih dahulu.')),
          );
          return;
        }
        // Navigasi ke halaman selanjutnya
        next(context, '/sleep-schedule', draft);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih intensitas makan kamu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F9C3F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih jam bangun dan tidur kamu Kami akan mempersonalisasikan menu makanan yang disesuaikan dengan pola tidur kamu.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          _buildHintBox(),

          // List Pilihan Frekuensi (Vertical Buttons)
          ..._frequencyOptions
              .map((opt) => _buildFrequencyOption(context, opt))
              .toList(),
        ],
      ),
    );
  }
}