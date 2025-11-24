import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bmrCalculationPage.dart'; 
import 'tdeeCalculationPage.dart'; // IMPORT FILE BARU TDEE

const Color kGreen = Color(0xFF5F9C3F);

class NutritionNeedsPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NutritionNeedsPage({super.key, required this.userData});

  @override
  State<NutritionNeedsPage> createState() => _NutritionNeedsPageState();
}

class _NutritionNeedsPageState extends State<NutritionNeedsPage> {
  late Map<String, dynamic> currentData;

  @override
  void initState() {
    super.initState();
    // Simpan data awal ke state agar bisa di-update nanti
    currentData = widget.userData; 
  }

  // Fungsi untuk mengambil data terbaru dari Firebase
  // Dipanggil setelah user kembali dari halaman edit BMR/TDEE
  Future<void> _refreshData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            currentData = doc.data()!;
          });
        }
      } catch (e) {
        debugPrint("❌ Gagal refresh data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ekstraksi Data (Support struktur lama & baru)
    final profile = (currentData['profile'] as Map<String, dynamic>?) ?? currentData;
    
    // Data Fisik Dasar
    final double weight = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    final double height = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    final double targetWeight = (profile['targetWeightKg'] as num?)?.toDouble() ?? 0;
    final String sex = (profile['sex'] ?? 'Laki-laki').toString();
    final String name = profile['name'] ?? currentData['name'] ?? 'User';
    final int age = _calculateAge(profile['birthDate']);

    // --- 2. LOGIKA BMR (Manual vs Auto) ---
    // Hitung Auto BMR dulu sebagai baseline
    double calculatedBmr = _calculateBMR(weight, height, age, sex);
    
    double finalBmr = calculatedBmr;
    bool isBmrManual = false;

    // Cek apakah user punya data manualBmr
    if (profile['manualBmr'] != null && (profile['manualBmr'] as num) > 0) {
      finalBmr = (profile['manualBmr'] as num).toDouble();
      isBmrManual = true; // Flag untuk UI Badge
    }

    // --- 3. LOGIKA TDEE (Manual vs Auto) ---
    // Hitung Auto TDEE menggunakan BMR yang sudah FINAL (bisa manual/auto)
    double calculatedTdee = _calculateTDEE(finalBmr, profile['activityLevel']);
    
    double finalTdee = calculatedTdee;
    bool isTdeeManual = false;

    // Cek apakah user punya data manualTdee
    if (profile['manualTdee'] != null && (profile['manualTdee'] as num) > 0) {
      finalTdee = (profile['manualTdee'] as num).toDouble();
      isTdeeManual = true; // Flag untuk UI Badge
    }

    // --- 4. TARGET KALORI ---
    // Target selalu dihitung dari TDEE FINAL + Goal Modifier
    final int dailyCalorieTarget = _calculateGoalCalories(finalTdee, profile['target']);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kebutuhan Nutrisi', 
          style: TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, color: Colors.black87)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- CARD UTAMA: TARGET KALORI ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kGreen, Color(0xFF4C8C32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text("Target Kalori Harian", style: TextStyle(fontFamily: 'Funnel Display', color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(
                    "${dailyCalorieTarget.toStringAsFixed(0)} kkal",
                    style: const TextStyle(fontFamily: 'Funnel Display', color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(_translateGoal(profile['target']), style: const TextStyle(fontFamily: 'Funnel Display', color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // --- SECTION 1: PROFIL RINGKAS ---
            _buildSection(
              title: "Profil & Fisik",
              icon: Icons.person,
              iconColor: Colors.blue,
              children: [
                _buildInfoItem('Nama', name),
                _buildInfoItem('Umur', '$age Tahun'),
                _buildInfoItem('Tinggi / Berat', '${height.toInt()} cm / ${weight.toStringAsFixed(1)} kg'),
                _buildInfoItem('Target Berat', '${targetWeight.toStringAsFixed(1)} kg'),
              ],
            ),

            const SizedBox(height: 15),

            // --- SECTION 2: ANALISIS METABOLISME ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text("Analisis Metabolisme", style: TextStyle(fontFamily: 'Funnel Display', fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // === BARIS BMR ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("BMR", style: TextStyle(fontWeight: FontWeight.bold)),
                              if (isBmrManual) _buildManualBadge()
                            ],
                          ),
                          const Text("Basal Metabolic Rate", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text(
                        "${finalBmr.toStringAsFixed(0)} kkal", 
                        style: const TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                    ],
                  ),
                  // Tombol Navigasi ke Detail BMR
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        // Tunggu user selesai edit, lalu refresh
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => BmrCalculationPage(userData: currentData)));
                        if (result == true) _refreshData();
                      },
                      icon: const Icon(Icons.calculate_outlined, size: 16, color: kGreen),
                      label: const Text("Lihat / Edit Perhitungan", style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerRight),
                    ),
                  ),

                  const Divider(height: 20),

                  // === BARIS TDEE ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("TDEE", style: TextStyle(fontWeight: FontWeight.bold)),
                              if (isTdeeManual) _buildManualBadge()
                            ],
                          ),
                          const Text("Total Daily Energy", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text(
                        "${finalTdee.toStringAsFixed(0)} kkal", 
                        style: const TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                    ],
                  ),
                  
                  // Tombol Navigasi ke Detail TDEE
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TdeeCalculationPage(userData: currentData)));
                        if (result == true) _refreshData();
                      },
                      icon: const Icon(Icons.calculate_outlined, size: 16, color: kGreen),
                      label: const Text("Lihat / Edit Perhitungan", style: TextStyle(fontSize: 12, color: kGreen, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerRight),
                    ),
                  ),

                  const SizedBox(height: 5),
                  if (!isTdeeManual)
                    Text(
                      "Aktivitas: ${_translateActivity(profile['activityLevel'])}", 
                      style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)
                    ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- SECTION 3: MAKRONUTRISI ---
            _buildSection(
              title: "Rekomendasi Makronutrisi",
              icon: Icons.pie_chart,
              iconColor: Colors.purple,
              children: [
                 _buildMacroRow("Karbohidrat (50%)", (dailyCalorieTarget * 0.5 / 4).round(), Colors.orange),
                 _buildMacroRow("Protein (30%)", (dailyCalorieTarget * 0.3 / 4).round(), Colors.green),
                 _buildMacroRow("Lemak (20%)", (dailyCalorieTarget * 0.2 / 9).round(), Colors.blue),
              ],
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildManualBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
      child: const Text("MANUAL", style: TextStyle(fontSize: 9, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children, Color iconColor = kGreen}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 15),
          ...children
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, int grams, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: color),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          Text("$grams g", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  // --- LOGIC HELPERS ---

  int _calculateAge(dynamic birthDateData) {
    if (birthDateData == null) return 25;
    DateTime? birthDate;
    
    // Handle format Timestamp (Firebase) & String
    if (birthDateData is Timestamp) {
      birthDate = birthDateData.toDate();
    } else if (birthDateData is String) {
      birthDate = DateTime.tryParse(birthDateData);
    }
    
    if (birthDate == null) return 25;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }

  double _calculateBMR(double weight, double height, int age, String sex) {
    if (weight == 0 || height == 0) return 0;
    // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    if (sex.toLowerCase().contains('female') || sex.toLowerCase().contains('perempuan') || sex.toLowerCase().contains('wanita')) {
      bmr -= 161;
    } else {
      bmr += 5;
    }
    return bmr > 0 ? bmr : 0;
  }

  double _calculateTDEE(double bmr, String? activityLevel) {
    if (bmr == 0) return 0;
    double multiplier = 1.2;
    switch (activityLevel) {
      case 'sedentary': multiplier = 1.2; break;
      case 'lightly_active': multiplier = 1.375; break;
      case 'moderately_active': multiplier = 1.55; break;
      case 'very_active': multiplier = 1.725; break;
      case 'extremely_active': multiplier = 1.9; break;
    }
    return bmr * multiplier;
  }
  
  int _calculateGoalCalories(double tdee, String? goal) {
    if (tdee == 0) return 2000;
    double target = tdee;
    if (goal == 'lose_weight') target -= 500;
    else if (goal == 'gain_weight' || goal == 'gain_muscle') target += 300;
    return target.round();
  }

  String _translateActivity(String? key) {
    const map = {
      'sedentary': 'Ringan',
      'lightly_active': 'Agak Aktif',
      'moderately_active': 'Cukup Aktif',
      'very_active': 'Sangat Aktif',
      'extremely_active': 'Ekstra Aktif',
    };
    return map[key] ?? 'Normal';
  }

  String _translateGoal(String? key) {
    const map = {
      'lose_weight': 'Turun Berat Badan',
      'maintain_weight': 'Jaga Berat Badan',
      'gain_weight': 'Naik Berat Badan',
      'gain_muscle': 'Membangun Otot',
    };
    return map[key] ?? 'Hidup Sehat';
  }
}