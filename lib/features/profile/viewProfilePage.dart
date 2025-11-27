// lib/viewProfilePage.dart

import 'package:flutter/material.dart';

// Palet warna (Diambil dari theme aplikasi kamu)
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);

class ViewProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ViewProfilePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // 1. Ekstraksi Data Aman (Defensive Programming)
    final profile = (userData['profile'] as Map<String, dynamic>?) ?? userData;

    final String name = profile['name'] ?? userData['name'] ?? 'Pengguna';
    final String sex = profile['sex'] ?? '-';
    final double height = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    final double weight = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    final double targetWeight =
        (profile['targetWeightKg'] as num?)?.toDouble() ?? 0;

    // Konversi Timestamp/String ke DateTime untuk Umur
    DateTime? birthDate;
    if (profile['birthDate'] != null) {
      if (profile['birthDate'] is String) {
        birthDate = DateTime.tryParse(profile['birthDate']);
      } else if (profile['birthDate'].toString().contains('Timestamp')) {
        // Handle jika formatnya Firestore Timestamp
        // birthDate = (profile['birthDate'] as Timestamp).toDate();
      }
    }

    final int age = _calculateAge(birthDate);
    final double bmi = _calculateBMI(height, weight);
    final String bmiCategory = _getBMICategory(bmi);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Detail Profil',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER KARTU UTAMA (BMI) ===
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kGreen, kGreen.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Indeks Massa Tubuh (BMI)",
                    style: TextStyle(
                      fontFamily: 'Funnel Display',
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bmiCategory,
                      style: const TextStyle(
                        fontFamily: 'Funnel Display',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === DATA FISIK ===
            _buildSectionTitle('Data Fisik'),
            _buildInfoContainer([
              _buildRow('Nama Lengkap', name),
              _buildRow('Jenis Kelamin', sex),
              _buildRow('Umur', age > 0 ? '$age Tahun' : '-'),
              _buildRow('Tinggi Badan', '${height.toStringAsFixed(0)} cm'),
              _buildRow('Berat Badan', '${weight.toStringAsFixed(1)} kg'),
            ]),

            const SizedBox(height: 24),

            // === TARGET & TUJUAN ===
            _buildSectionTitle('Target & Kesehatan'),
            _buildInfoContainer([
              _buildRow('Tujuan Utama', _translateGoal(profile['target'])),
              _buildRow(
                  'Target Berat', '${targetWeight.toStringAsFixed(1)} kg'),
              _buildRow(
                  'Aktivitas', _translateActivity(profile['activityLevel'])),
            ]),

            const SizedBox(height: 24),

            // === PREFERENSI ===
            _buildSectionTitle('Preferensi & Lainnya'),
            _buildInfoContainer([
              _buildRow('Frekuensi Makan',
                  '${profile['eatFrequency'] ?? '-'}x sehari'),
              _buildListRow('Alergi', profile['allergies']),
              _buildListRow('Tantangan', profile['challenges']),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Funnel Display',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kGreen,
        ),
      ),
    );
  }

  Widget _buildInfoContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kMutedBorderGrey.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              color: kLightGreyText,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(String label, dynamic items) {
    List<String> listItems = [];
    if (items is List) {
      listItems = items.map((e) => e.toString()).toList();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              color: kLightGreyText,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: listItems.isEmpty
                ? const Text('-', style: TextStyle(fontWeight: FontWeight.w600))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: listItems
                        .map((item) => Text(
                              item,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double _calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String _getBMICategory(double bmi) {
    if (bmi <= 0) return '-';
    if (bmi < 18.5) return 'Kurang Berat Badan';
    if (bmi < 24.9) return 'Normal';
    if (bmi < 29.9) return 'Kelebihan Berat Badan';
    return 'Obesitas';
  }

  String _translateActivity(String? key) {
    const map = {
      'sedentary': 'Jarang Bergerak',
      'lightly_active': 'Agak Aktif',
      'moderately_active': 'Cukup Aktif',
      'very_active': 'Sangat Aktif',
      'extremely_active': 'Ekstra Aktif',
    };
    return map[key] ?? key ?? '-';
  }

  String _translateGoal(String? key) {
    const map = {
      'lose_weight': 'Menurunkan Berat',
      'maintain_weight': 'Jaga Berat Badan',
      'gain_weight': 'Menambah Berat',
      'gain_muscle': 'Membangun Otot',
    };
    return map[key] ?? key ?? '-';
  }
}
