import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kGreen = Color(0xFF5F9C3F);
const Color kOrange = Color(0xFFFF9800);

class BmrCalculationPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const BmrCalculationPage({super.key, required this.userData});

  @override
  State<BmrCalculationPage> createState() => _BmrCalculationPageState();
}

class _BmrCalculationPageState extends State<BmrCalculationPage> {
  final TextEditingController _manualBmrController = TextEditingController();
  bool _isLoading = false;
  
  // Data Fisik
  late double weight, height;
  late int age;
  late String sex;
  
  // Nilai BMR
  late double autoBmr;
  late double activeBmr;
  bool isManual = false;
  
  // Breakdown Rumus
  double valWeight = 0;
  double valHeight = 0;
  double valAge = 0;
  int valConstant = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final profile = widget.userData['profile'] ?? widget.userData;
    
    weight = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    height = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    sex = (profile['sex'] ?? 'Laki-laki').toString();
    
    DateTime? birthDate;
    if (profile['birthDate'] != null) {
      if (profile['birthDate'] is Timestamp) {
        birthDate = (profile['birthDate'] as Timestamp).toDate();
      } else {
        birthDate = DateTime.tryParse(profile['birthDate'].toString());
      }
    }
    age = _calculateAge(birthDate);

    // 1. Hitung Rumus Otomatis (Mifflin-St Jeor)
    valWeight = 10 * weight;
    valHeight = 6.25 * height;
    valAge = 5.0 * age;
    valConstant = (sex.toLowerCase().contains('female') || sex.toLowerCase().contains('wanita') || sex.toLowerCase().contains('perempuan')) ? -161 : 5;

    autoBmr = valWeight + valHeight - valAge + valConstant;
    if (autoBmr < 0) autoBmr = 0;

    // 2. Tentukan Active BMR (Cek Manual)
    if (profile['manualBmr'] != null && (profile['manualBmr'] as num) > 0) {
      activeBmr = (profile['manualBmr'] as num).toDouble();
      isManual = true;
      _manualBmrController.text = activeBmr.toStringAsFixed(0);
    } else {
      activeBmr = autoBmr;
      isManual = false;
    }
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 25;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveManualBmr() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      double? manualVal = double.tryParse(_manualBmrController.text.replaceAll(',', '.'));
      double saveVal = manualVal ?? 0;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profile.manualBmr': saveVal,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(saveVal == 0 ? "BMR dikembalikan ke Otomatis" : "BMR Manual disimpan!")),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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
        title: const Text('Detail Perhitungan BMR', style: TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, color: Colors.black87)),
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
            // 1. INFO HEADER: BMR YANG AKTIF
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isManual ? kOrange.withValues(alpha: 0.1) : kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isManual ? kOrange : kGreen),
              ),
              child: Row(
                children: [
                  Icon(isManual ? Icons.edit : Icons.auto_awesome, color: isManual ? kOrange : kGreen, size: 28),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isManual ? "Anda menggunakan BMR Manual" : "Menggunakan Kalkulasi Otomatis",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isManual ? Colors.deepOrange : kGreen),
                      ),
                      Text(
                        "${activeBmr.toStringAsFixed(0)} kkal",
                        style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 2. CARD RUMUS VISUAL
            const Text(
              "Referensi Rumus (Mifflin-St Jeor)",
              style: TextStyle(fontFamily: 'Funnel Display', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  _buildFormulaRow("Berat Badan", "(10 × $weight kg)", "+ ${valWeight.toStringAsFixed(0)}"),
                  const Divider(),
                  _buildFormulaRow("Tinggi Badan", "(6.25 × $height cm)", "+ ${valHeight.toStringAsFixed(0)}"),
                  const Divider(),
                  _buildFormulaRow("Umur", "(5 × $age th)", "- ${valAge.toStringAsFixed(0)}"),
                  const Divider(),
                  _buildFormulaRow("Jenis Kelamin", sex, valConstant >= 0 ? "+ $valConstant" : "- ${valConstant.abs()}"),
                  const Divider(thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Hasil Kalkulasi Murni", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                      Text(
                        "${autoBmr.toStringAsFixed(0)} kkal",
                        style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. INPUT MANUAL SECTION
            const Text(
              "Edit BMR Manual",
              style: TextStyle(fontFamily: 'Funnel Display', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              "Masukkan angka manual di sini jika Anda memiliki data tes lab yang lebih akurat.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              controller: _manualBmrController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "BMR Manual (Opsional)",
                suffixText: "kkal",
                hintText: autoBmr.toStringAsFixed(0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 2)),
              ),
            ),

            const SizedBox(height: 30),
            
            // 4. TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveManualBmr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
            // Tombol Reset
            if (isManual || _manualBmrController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: () {
                     _manualBmrController.clear();
                     _saveManualBmr(); 
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                  label: const Text("Hapus Manual & Gunakan Otomatis", style: TextStyle(color: Colors.grey)),
                ),
              ),

            // --- 5. NEW: EDUKASI BMR (Notes) ---
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            
            _buildInfoNote(
              title: "Apa itu BMR?",
              content: "BMR (Basal Metabolic Rate) adalah jumlah energi minimum yang dibakar tubuh Anda untuk bertahan hidup saat istirahat total. Ini mencakup energi untuk bernapas, memompa darah, dan fungsi sel dasar.",
            ),
            const SizedBox(height: 16),
            _buildInfoNote(
              title: "Tentang Rumus",
              content: "Aplikasi ini menggunakan Persamaan Mifflin-St Jeor. Rumus ini diperkenalkan pada tahun 1990 dan saat ini dianggap sebagai standar paling akurat oleh American Dietetic Association untuk memperkirakan kebutuhan kalori dasar.",
            ),
            const SizedBox(height: 30), // Padding bawah biar tidak mepet
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Baris Rumus
  Widget _buildFormulaRow(String label, String formula, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(formula, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          Text(value, style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  // Widget Helper untuk Note Edukasi
  Widget _buildInfoNote({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Warna background abu-abu lembut
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
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}