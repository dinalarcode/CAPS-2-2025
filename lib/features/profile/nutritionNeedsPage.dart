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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            currentData = doc.data()!;
          });
        }
      } catch (e) {
        debugPrint("Γ¥î Gagal refresh data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ekstraksi Data (Support struktur lama & baru)
    final profile =
        (currentData['profile'] as Map<String, dynamic>?) ?? currentData;

    // Data Fisik Dasar
    final double weight = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    final double height = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    final double targetWeight =
        (profile['targetWeightKg'] as num?)?.toDouble() ?? 0;
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
    int dailyCalorieTarget =
        _calculateGoalCalories(finalTdee, profile['target']);

    // Jika ada manualTargetCalories, gunakan itu (tidak ditambah goal modifier)
    if (profile['manualTargetCalories'] != null &&
        (profile['manualTargetCalories'] as num) > 0) {
      dailyCalorieTarget = (profile['manualTargetCalories'] as num).toInt();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kebutuhan Nutrisi',
            style: TextStyle(
                fontFamily: 'Funnel Display',
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
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
                  BoxShadow(
                      color: kGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Text("Target Kalori Harian",
                      style: TextStyle(
                          fontFamily: 'Funnel Display',
                          color: Colors.white70,
                          fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(
                    "${dailyCalorieTarget.toStringAsFixed(0)} kkal",
                    style: const TextStyle(
                        fontFamily: 'Funnel Display',
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Text(_translateGoal(profile['target']),
                            style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                color: Colors.white,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          "(TDEE: ${finalTdee.toStringAsFixed(0)} kkal)",
                          style: const TextStyle(
                              fontFamily: 'Funnel Display',
                              color: Colors.white70,
                              fontSize: 10),
                        ),
                      ],
                    ),
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
                _buildInfoItem('Tinggi / Berat',
                    '${height.toInt()} cm / ${weight.toStringAsFixed(1)} kg'),
                _buildInfoItem(
                    'Target Berat', '${targetWeight.toStringAsFixed(1)} kg'),
              ],
            ),

            const SizedBox(height: 15),

            // --- SECTION 2: ANALISIS METABOLISME ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text("Analisis Metabolisme",
                          style: TextStyle(
                              fontFamily: 'Funnel Display',
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
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
                              const Text("BMR",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              if (isBmrManual) _buildManualBadge()
                            ],
                          ),
                          const Text("Basal Metabolic Rate",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text("${finalBmr.toStringAsFixed(0)} kkal",
                          style: const TextStyle(
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                  // Tombol Navigasi ke Detail BMR
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        // Tunggu user selesai edit, lalu refresh
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    BmrCalculationPage(userData: currentData)));
                        if (result == true) _refreshData();
                      },
                      icon: const Icon(Icons.calculate_outlined,
                          size: 16, color: kGreen),
                      label: const Text("Lihat / Edit Perhitungan",
                          style: TextStyle(
                              fontSize: 12,
                              color: kGreen,
                              fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerRight),
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
                              const Text("TDEE",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              if (isTdeeManual) _buildManualBadge()
                            ],
                          ),
                          const Text("Total Daily Energy",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Text("${finalTdee.toStringAsFixed(0)} kkal",
                          style: const TextStyle(
                              fontFamily: 'Funnel Display',
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),

                  // Tombol Navigasi ke Detail TDEE
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TdeeCalculationPage(
                                    userData: currentData)));
                        if (result == true) _refreshData();
                      },
                      icon: const Icon(Icons.calculate_outlined,
                          size: 16, color: kGreen),
                      label: const Text("Lihat / Edit Perhitungan",
                          style: TextStyle(
                              fontSize: 12,
                              color: kGreen,
                              fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerRight),
                    ),
                  ),

                  const SizedBox(height: 5),
                  if (!isTdeeManual)
                    Text(
                        "Aktivitas: ${_translateActivity(profile['activityLevel'])}",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic)),
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
                _buildMacroRow("Karbohidrat (50%)",
                    (dailyCalorieTarget * 0.5 / 4).round(), Colors.orange),
                _buildMacroRow("Protein (30%)",
                    (dailyCalorieTarget * 0.3 / 4).round(), Colors.green),
                _buildMacroRow("Lemak (20%)",
                    (dailyCalorieTarget * 0.2 / 9).round(), Colors.blue),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MacroCalculationDetailPage(
                            dailyCalorieTarget: dailyCalorieTarget,
                            target: profile['target'] ?? 'maintain_weight',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Lihat Perhitungan Detail'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
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
      decoration: BoxDecoration(
          color: Colors.orange[100], borderRadius: BorderRadius.circular(4)),
      child: const Text("MANUAL",
          style: TextStyle(
              fontSize: 9,
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required List<Widget> children,
      Color iconColor = kGreen}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
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
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87)),
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
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          Text("$grams g",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
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
    if (today.month < birthDate.month ||
        // ignore: curly_braces_in_flow_control_structures
        (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }

  double _calculateBMR(double weight, double height, int age, String sex) {
    if (weight == 0 || height == 0) return 0;
    // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    if (sex.toLowerCase().contains('female') ||
        sex.toLowerCase().contains('perempuan') ||
        sex.toLowerCase().contains('wanita')) {
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
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'lightly_active':
        multiplier = 1.375;
        break;
      case 'moderately_active':
        multiplier = 1.55;
        break;
      case 'very_active':
        multiplier = 1.725;
        break;
      case 'extremely_active':
        multiplier = 1.9;
        break;
    }
    return bmr * multiplier;
  }

  int _calculateGoalCalories(double tdee, String? goal) {
    if (tdee == 0) {
      return 2000;
    }

    double target = tdee;

    if (goal == 'lose_weight') {
      target -= 500;
    } else if (goal == 'gain_weight' || goal == 'gain_muscle') {
      target += 300;
    }

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

// === MACRO CALCULATION DETAIL PAGE ===
class MacroCalculationDetailPage extends StatefulWidget {
  final int dailyCalorieTarget;
  final String target; // "lose_weight", "maintain_weight", "gain_weight"

  const MacroCalculationDetailPage({
    super.key,
    required this.dailyCalorieTarget,
    required this.target,
  });

  @override
  State<MacroCalculationDetailPage> createState() =>
      _MacroCalculationDetailPageState();
}

class _MacroCalculationDetailPageState
    extends State<MacroCalculationDetailPage> {
  late double carbCalories;
  late double proteinCalories;
  late double fatCalories;
  late double carbGrams;
  late double proteinGrams;
  late double fatGrams;

  @override
  void initState() {
    super.initState();
    _calculateMacros();
  }

  void _calculateMacros() {
    // Alokasi kalori per nutrisi
    carbCalories = widget.dailyCalorieTarget * 0.50; // 50%
    proteinCalories = widget.dailyCalorieTarget * 0.30; // 30%
    fatCalories = widget.dailyCalorieTarget * 0.20; // 20%

    // Konversi ke gram (1g protein = 4 cal, 1g carbs = 4 cal, 1g fat = 9 cal)
    carbGrams = carbCalories / 4;
    proteinGrams = proteinCalories / 4;
    fatGrams = fatCalories / 9;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Perhitungan Makro',
            style: TextStyle(
                fontFamily: 'Funnel Display',
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
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
            // === STEP 1: TARGET KALORI ===
            _buildStepCard(
              step: '1',
              title: 'Target Kalori Harian',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Kalori Target',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.dailyCalorieTarget} kkal/hari',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Target Kalori = TDEE + Goal Modifier (${_getGoalModifier(widget.target)})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === STEP 2: ALOKASI KALORI PER MACRO ===
            _buildStepCard(
              step: '2',
              title: 'Alokasi Kalori Per Makronutrisi',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembagian kalori berdasarkan kebutuhan nutrisi optimal:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMacroAllocationRow(
                    'Karbohidrat',
                    '50%',
                    carbCalories,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildMacroAllocationRow(
                    'Protein',
                    '30%',
                    proteinCalories,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildMacroAllocationRow(
                    'Lemak',
                    '20%',
                    fatCalories,
                    Colors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === STEP 3: KONVERSI KE GRAM ===
            _buildStepCard(
              step: '3',
              title: 'Konversi ke Gram',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menggunakan konversi kalori per gram untuk menghitung jumlah gram yang dibutuhkan:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFormulaRowWithExplanation(
                    'Karbohidrat',
                    '4 kkal/gram',
                    '${carbCalories.toStringAsFixed(0)} ÷ 4 = ${carbGrams.toStringAsFixed(1)}g',
                    'Setiap gram karbohidrat mengandung 4 kalori energi',
                  ),
                  const SizedBox(height: 12),
                  _buildFormulaRowWithExplanation(
                    'Protein',
                    '4 kkal/gram',
                    '${proteinCalories.toStringAsFixed(0)} ÷ 4 = ${proteinGrams.toStringAsFixed(1)}g',
                    'Setiap gram protein mengandung 4 kalori energi',
                  ),
                  const SizedBox(height: 12),
                  _buildFormulaRowWithExplanation(
                    'Lemak',
                    '9 kkal/gram',
                    '${fatCalories.toStringAsFixed(0)} ÷ 9 = ${fatGrams.toStringAsFixed(1)}g',
                    'Setiap gram lemak mengandung 9 kalori energi (lebih padat energi)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === HASIL AKHIR ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade100, Colors.green.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Rekomendasi Makro Harian',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMacroResultRow(
                    'Karbohidrat',
                    '${carbGrams.toStringAsFixed(1)}g',
                    Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  _buildMacroResultRow(
                    'Protein',
                    '${proteinGrams.toStringAsFixed(1)}g',
                    Colors.red,
                  ),
                  const SizedBox(height: 10),
                  _buildMacroResultRow(
                    'Lemak',
                    '${fatGrams.toStringAsFixed(1)}g',
                    Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Kalori',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.dailyCalorieTarget} kkal',
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === TIPS ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Tips Praktis',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipRow(
                    '🥩 Protein: Daging, telur, kacang-kacangan, susu',
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(
                    '🍚 Karbohidrat: Nasi, roti, pasta, buah-buahan',
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow(
                    '🥑 Lemak: Minyak zaitun, kacang, alpukat, ikan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Funnel Display',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroAllocationRow(
    String label,
    String percent,
    double calories,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                percent,
                style: TextStyle(
                  fontFamily: 'Funnel Display',
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${calories.toStringAsFixed(0)} kkal',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Funnel Display',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaRowWithExplanation(
    String macro,
    String conversion,
    String formula,
    String explanation,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            macro,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            conversion,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Funnel Display',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Funnel Display',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow(String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _getGoalModifier(String target) {
    switch (target) {
      case 'lose_weight':
        return '-500 kkal';
      case 'gain_weight':
      case 'gain_muscle':
        return '+300 kkal';
      default:
        return '±0 kkal';
    }
  }
}
