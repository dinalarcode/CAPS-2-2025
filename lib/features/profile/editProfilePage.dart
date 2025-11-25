import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kGreen = Color(0xFF5F9C3F);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _targetWeightController;

  // Dropdown Values
  String? _selectedActivityLevel;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    
    // 1. Ambil data dari Root (luar) dan Profile (dalam) agar aman
    final rootData = widget.userData; 
    final profileData = (rootData['profile'] as Map<String, dynamic>?) ?? {};

    // 2. Logika "Cari Data Sampai Dapat" (Fallback Logic)
    // Mencari nama di profile['name'], kalau null cari di root['name']
    String initName = profileData['name'] ?? rootData['name'] ?? '';
    
    // Mencari tinggi (bisa 'height', 'heightCm', atau string/number)
    var initHeight = profileData['heightCm'] ?? profileData['height'] ?? rootData['heightCm'] ?? rootData['height'] ?? 0;
    
    // Mencari berat
    var initWeight = profileData['weightKg'] ?? profileData['weight'] ?? rootData['weightKg'] ?? rootData['weight'] ?? 0;
    
    // Mencari target berat
    var initTarget = profileData['targetWeightKg'] ?? profileData['targetWeight'] ?? rootData['targetWeightKg'] ?? rootData['targetWeight'] ?? 0;

    // 3. Masukkan ke Controller
    _nameController = TextEditingController(text: initName);
    
    // Trik: Jika nilainya 0, kosongkan textfield agar user enak ngetiknya (tidak perlu hapus angka 0)
    _heightController = TextEditingController(text: initHeight.toString() == '0' ? '' : initHeight.toString());
    _weightController = TextEditingController(text: initWeight.toString() == '0' ? '' : initWeight.toString());
    _targetWeightController = TextEditingController(text: initTarget.toString() == '0' ? '' : initTarget.toString());

    // 4. Dropdown (Pastikan value sesuai opsi yang ada)
    _selectedActivityLevel = profileData['activityLevel'] ?? rootData['activityLevel'];
    _selectedGoal = profileData['target'] ?? rootData['target'] ?? profileData['healthGoal']; 
    
    // Validasi nilai dropdown (cegah error crash jika value di database tidak ada di list item)
    const validActivities = ['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'];
    if (!validActivities.contains(_selectedActivityLevel)) _selectedActivityLevel = null;
    
    const validGoals = ['lose_weight', 'maintain_weight', 'gain_weight', 'gain_muscle'];
    if (!validGoals.contains(_selectedGoal)) _selectedGoal = null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Konversi input ke tipe data yang benar (double/int)
      final double height = double.tryParse(_heightController.text) ?? 0;
      final double weight = double.tryParse(_weightController.text) ?? 0;
      final double targetWeight = double.tryParse(_targetWeightController.text) ?? 0;

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(), // Update nama di root level juga jika perlu
        'profile.name': _nameController.text.trim(),
        'profile.heightCm': height,
        'profile.weightKg': weight,
        'profile.targetWeightKg': targetWeight,
        'profile.activityLevel': _selectedActivityLevel,
        'profile.target': _selectedGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
        // Kembali ke halaman sebelumnya dengan sinyal 'true' agar direfresh
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("SIMPAN", style: TextStyle(color: kGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Nama Lengkap"),
              _buildTextField(_nameController, "Nama Anda"),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       _buildLabel("Tinggi (cm)"),
                       _buildNumberField(_heightController, "cm"),
                    ],
                  )),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       _buildLabel("Berat (kg)"),
                       _buildNumberField(_weightController, "kg"),
                    ],
                  )),
                ],
              ),

              const SizedBox(height: 20),
              _buildLabel("Target Berat (kg)"),
              _buildNumberField(_targetWeightController, "Target kg"),

              const SizedBox(height: 20),
              _buildLabel("Aktivitas Harian"),
              _buildDropdownActivity(),

              const SizedBox(height: 20),
              _buildLabel("Tujuan Utama"),
              _buildDropdownGoal(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Funnel Display', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
    );
  }

  Widget _buildNumberField(TextEditingController controller, String suffix) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Wajib';
        if (double.tryParse(val) == null) return 'Angka!';
        return null;
      },
    );
  }

  Widget _buildDropdownActivity() {
    return DropdownButtonFormField<String>(
      value: _selectedActivityLevel,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'sedentary', child: Text("Jarang Bergerak")),
        DropdownMenuItem(value: 'lightly_active', child: Text("Agak Aktif")),
        DropdownMenuItem(value: 'moderately_active', child: Text("Cukup Aktif")),
        DropdownMenuItem(value: 'very_active', child: Text("Sangat Aktif")),
        DropdownMenuItem(value: 'extremely_active', child: Text("Ekstra Aktif")),
      ],
      onChanged: (val) => setState(() => _selectedActivityLevel = val),
    );
  }

  Widget _buildDropdownGoal() {
    return DropdownButtonFormField<String>(
      value: _selectedGoal,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'lose_weight', child: Text("Menurunkan Berat")),
        DropdownMenuItem(value: 'maintain_weight', child: Text("Jaga Berat Badan")),
        DropdownMenuItem(value: 'gain_weight', child: Text("Menambah Berat")),
        DropdownMenuItem(value: 'gain_muscle', child: Text("Membangun Otot")),
      ],
      onChanged: (val) => setState(() => _selectedGoal = val),
    );
  }
}