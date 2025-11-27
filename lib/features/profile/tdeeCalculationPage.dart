import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kGreen = Color(0xFF5F9C3F);
const Color kOrange = Color(0xFFFF9800);

class TdeeCalculationPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const TdeeCalculationPage({super.key, required this.userData});

  @override
  State<TdeeCalculationPage> createState() => _TdeeCalculationPageState();
}

class _TdeeCalculationPageState extends State<TdeeCalculationPage> {
  final TextEditingController _manualTdeeController = TextEditingController();
  bool _isLoading = false;

  // Data Hitungan
  late double bmr;
  String _selectedActivity = 'sedentary'; // Default activity

  // Nilai TDEE
  late double autoTdee;
  late double activeTdee;
  bool isManual = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final profile = widget.userData['profile'] ?? widget.userData;

    // 1. Ambil BMR (Prioritaskan Manual BMR jika ada di database)
    double rawBmr = _calculateAutoBMR(profile);
    if (profile['manualBmr'] != null && (profile['manualBmr'] as num) > 0) {
      bmr = (profile['manualBmr'] as num).toDouble();
    } else {
      bmr = rawBmr;
    }

    // 2. Set Aktivitas Awal dari Database (agar radio button sesuai pilihan terakhir)
    _selectedActivity = profile['activityLevel'] ?? 'sedentary';

    // 3. Hitung Nilai Awal
    _calculateValues();

    // 4. Cek Manual TDEE untuk mengisi Form Input (jika user pernah override)
    if (profile['manualTdee'] != null && (profile['manualTdee'] as num) > 0) {
      double manualVal = (profile['manualTdee'] as num).toDouble();
      _manualTdeeController.text = manualVal.toStringAsFixed(0);
      isManual = true;
      activeTdee = manualVal;
    } else {
      isManual = false;
      activeTdee = autoTdee;
    }
  }

  // Fungsi hitung ulang real-time saat user ganti radio button
  void _calculateValues() {
    double multiplier = _getMultiplier(_selectedActivity);
    setState(() {
      autoTdee = bmr * multiplier;
      // Jika user TIDAK sedang dalam mode manual, update TDEE aktif secara real-time
      if (!isManual) {
        activeTdee = autoTdee;
      }
    });
  }

  // Helper hitung BMR Auto (Fallback jika tidak ada data BMR)
  double _calculateAutoBMR(Map<String, dynamic> profile) {
    double weight = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    double height = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    String sex = (profile['sex'] ?? 'Laki-laki').toString();

    DateTime? birthDate;
    if (profile['birthDate'] is Timestamp) {
      birthDate = (profile['birthDate'] as Timestamp).toDate();
    } else {
      birthDate = DateTime.tryParse(profile['birthDate'].toString());
    }
    int age = _calculateAge(birthDate);

    if (weight == 0 || height == 0) return 0;
    double val = (10 * weight) + (6.25 * height) - (5 * age);
    return (sex.toLowerCase().contains('female') ||
            sex.toLowerCase().contains('wanita') ||
            sex.toLowerCase().contains('perempuan'))
        ? val - 161
        : val + 5;
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 25;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double _getMultiplier(String level) {
    switch (level) {
      case 'sedentary':
        return 1.2;
      case 'lightly_active':
        return 1.375;
      case 'moderately_active':
        return 1.55;
      case 'very_active':
        return 1.725;
      case 'extremely_active':
        return 1.9;
      default:
        return 1.2;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      double? manualVal =
          double.tryParse(_manualTdeeController.text.replaceAll(',', '.'));
      double saveManualTdee = manualVal ?? 0;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profile.manualTdee': saveManualTdee,
        'profile.activityLevel': _selectedActivity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Data TDEE & Aktivitas berhasil diperbarui!"),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 🔄 Return true untuk trigger reload
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Perhitungan TDEE',
            style: TextStyle(
                fontFamily: 'Funnel Display',
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. INFO HEADER (Status Aktif)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isManual
                    ? kOrange.withValues(alpha: 0.1)
                    : kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isManual ? kOrange : kGreen),
              ),
              child: Row(
                children: [
                  Icon(isManual ? Icons.edit : Icons.directions_run,
                      color: isManual ? kOrange : kGreen, size: 28),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isManual
                            ? "Anda menggunakan TDEE Manual"
                            : "Menggunakan Kalkulasi Otomatis",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isManual ? Colors.deepOrange : kGreen),
                      ),
                      Text(
                        "${activeTdee.toStringAsFixed(0)} kkal",
                        style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 2. PILIHAN AKTIVITAS (INTERAKTIF)
            const Text(
              "Pilih Tingkat Aktivitas",
              style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildActivityOption(
                    value: 'sedentary',
                    title: 'Sedentary (Jarang Gerak)',
                    subtitle: 'Bekerja duduk, tidak ada olahraga.',
                    multiplier: 'x 1.2',
                  ),
                  const Divider(height: 1),
                  _buildActivityOption(
                    value: 'lightly_active',
                    title: 'Lightly Active (Ringan)',
                    subtitle: 'Olahraga ringan / jalan santai 1-3 hari/minggu.',
                    multiplier: 'x 1.375',
                  ),
                  const Divider(height: 1),
                  _buildActivityOption(
                    value: 'moderately_active',
                    title: 'Moderately Active (Sedang)',
                    subtitle: 'Olahraga sedang 3-5 hari/minggu.',
                    multiplier: 'x 1.55',
                  ),
                  const Divider(height: 1),
                  _buildActivityOption(
                    value: 'very_active',
                    title: 'Very Active (Berat)',
                    subtitle: 'Olahraga berat 6-7 hari/minggu.',
                    multiplier: 'x 1.725',
                  ),
                  const Divider(height: 1),
                  _buildActivityOption(
                    value: 'extremely_active',
                    title: 'Extremely Active (Ekstra)',
                    subtitle: 'Fisik sangat berat, latihan 2x sehari.',
                    multiplier: 'x 1.9',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // HASIL KALKULASI RUMUS (Live Update)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Hasil Rumus (BMR x Aktivitas)",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      Text(
                          "${bmr.toStringAsFixed(0)} x ${_getMultiplier(_selectedActivity)}",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Text(
                    "${autoTdee.toStringAsFixed(0)} kkal",
                    style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. INPUT MANUAL
            const Text(
              "Override Manual (Opsional)",
              style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "Punya data dari Smartwatch yang lebih akurat? Masukkan di sini.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _manualTdeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                // Realtime: jika user ketik, switch ke mode manual
                setState(() {
                  isManual = val.isNotEmpty;
                  if (val.isNotEmpty) {
                    activeTdee = double.tryParse(val) ?? autoTdee;
                  } else {
                    activeTdee = autoTdee;
                  }
                });
              },
              decoration: InputDecoration(
                labelText: "Input TDEE Manual",
                suffixText: "kkal",
                hintText: autoTdee.toStringAsFixed(0),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kGreen, width: 2)),
              ),
            ),

            const SizedBox(height: 30),

            // 4. TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan & Update Profil",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),

            // Tombol Reset
            if (_manualTdeeController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: () {
                    _manualTdeeController.clear();
                    setState(() {
                      isManual = false;
                      activeTdee = autoTdee; // Kembalikan ke nilai rumus
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                  label: const Text("Hapus Manual & Gunakan Rumus",
                      style: TextStyle(color: Colors.grey)),
                ),
              ),

            // --- 5. NOTES EDUKASI TDEE ---
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),

            _buildInfoNote(
              title: "Apa itu TDEE?",
              content:
                  "TDEE (Total Daily Energy Expenditure) adalah total kalori yang Anda bakar dalam 24 jam. Ini mencakup BMR (energi istirahat) ditambah semua aktivitas fisik seperti berjalan, bekerja, dan berolahraga.",
            ),
            const SizedBox(height: 16),
            _buildInfoNote(
              title: "Kenapa Ini Penting?",
              content:
                  "TDEE adalah angka 'Maintenance'. Makan di bawah angka ini akan membakar lemak (defisit), dan makan di atas angka ini akan menambah berat badan (surplus).",
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget Opsi Radio Button
  Widget _buildActivityOption({
    required String value,
    required String title,
    required String subtitle,
    required String multiplier,
  }) {
    bool isSelected = _selectedActivity == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedActivity = value;
          _calculateValues(); // Hitung ulang TDEE saat opsi berubah
        });
      },
      child: Container(
        color: isSelected ? kGreen.withValues(alpha: 0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Selection indicator: replace deprecated Radio API with tappable Icon
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? kGreen : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(multiplier,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Note Edukasi
  Widget _buildInfoNote({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Colors.black54)),
        ],
      ),
    );
  }
}
