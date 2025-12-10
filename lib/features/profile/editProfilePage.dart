import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kGreen = Color(0xFF5F9C3F);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
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
  late TextEditingController _wakeTimeController;
  late TextEditingController _sleepTimeController;

  // Dropdown Values
  String? _selectedActivityLevel;
  String? _selectedGoal;
  String? _selectedGender;
  int? _selectedEatFrequency;
  DateTime? _selectedBirthDate;
  Set<String> _selectedAllergies = {};

  // Allergy Options
  final List<String> allergyOptions = [
    'Tidak Ada Alergi',
    'Seafood',
    'Ikan',
    'Udang',
    'Sapi',
    'Ayam',
  ];

  @override
  void initState() {
    super.initState();

    final rootData = widget.userData;
    final profileData = (rootData['profile'] as Map<String, dynamic>?) ?? {};

    String initName = profileData['name'] ?? rootData['name'] ?? '';

    var initHeight = profileData['heightCm'] ??
        profileData['height'] ??
        rootData['heightCm'] ??
        rootData['height'] ??
        0;

    var initWeight = profileData['weightKg'] ??
        profileData['weight'] ??
        rootData['weightKg'] ??
        rootData['weight'] ??
        0;

    var initTarget = profileData['targetWeightKg'] ??
        profileData['targetWeight'] ??
        rootData['targetWeightKg'] ??
        rootData['targetWeight'] ??
        0;

    _nameController = TextEditingController(text: initName);
    _heightController = TextEditingController(
        text: initHeight.toString() == '0' ? '' : initHeight.toString());
    _weightController = TextEditingController(
        text: initWeight.toString() == '0' ? '' : initWeight.toString());
    _targetWeightController = TextEditingController(
        text: initTarget.toString() == '0' ? '' : initTarget.toString());

    // Birth date
    if (profileData['birthDate'] != null) {
      if (profileData['birthDate'] is String) {
        _selectedBirthDate = DateTime.tryParse(profileData['birthDate']);
      }
    }

    // Gender
    _selectedGender = profileData['sex'] ?? rootData['sex'];

    // Activity Level - Updated to new activity levels
    _selectedActivityLevel =
        profileData['activityLevel'] ?? rootData['activityLevel'];
    const validActivities = [
      'very_low',
      'low',
      'medium',
      'high',
      'very_high',
      'extremely_high'
    ];
    if (!validActivities.contains(_selectedActivityLevel)) {
      _selectedActivityLevel = null;
    }

    // Goal - Updated to 3 options only
    _selectedGoal = profileData['target'] ??
        rootData['target'] ??
        profileData['healthGoal'];
    const validGoals = ['lose_weight', 'maintain_weight', 'gain_weight'];
    if (!validGoals.contains(_selectedGoal)) {
      _selectedGoal = null;
    }

    // Eat Frequency
    _selectedEatFrequency = (profileData['eatFrequency'] as num?)?.toInt() ?? 3;

    // Wake and Sleep Time
    var wakeTime = profileData['wakeTime'] ?? '06:00';
    var sleepTime = profileData['sleepTime'] ?? '22:00';
    _wakeTimeController = TextEditingController(text: wakeTime.toString());
    _sleepTimeController = TextEditingController(text: sleepTime.toString());

    // Allergies
    if (profileData['allergies'] is List) {
      _selectedAllergies = Set<String>.from(profileData['allergies'] as List);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _wakeTimeController.dispose();
    _sleepTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final double height = double.tryParse(_heightController.text) ?? 0;
      final double weight = double.tryParse(_weightController.text) ?? 0;
      final double targetWeight =
          double.tryParse(_targetWeightController.text) ?? 0;

      // Update Firestore dengan semua field baru
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'profile.name': _nameController.text.trim(),
        'profile.heightCm': height,
        'profile.weightKg': weight,
        'profile.targetWeightKg': targetWeight,
        'profile.activityLevel': _selectedActivityLevel,
        'profile.target': _selectedGoal,
        'profile.sex': _selectedGender,
        'profile.birthDate': _selectedBirthDate?.toIso8601String(),
        'profile.eatFrequency': _selectedEatFrequency,
        'profile.allergies': _selectedAllergies.toList(),
        'profile.wakeTime': _wakeTimeController.text,
        'profile.sleepTime': _sleepTimeController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Profil berhasil diperbarui!"),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Gagal update: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = (widget.userData['profile'] as Map<String, dynamic>?) ??
        widget.userData;

    final double height = (profile['heightCm'] as num?)?.toDouble() ?? 0;
    final double weight = (profile['weightKg'] as num?)?.toDouble() ?? 0;
    final double bmi = _calculateBMI(height, weight);
    final String bmiCategory = _getBMICategory(bmi);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
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
        child: Form(
          key: _formKey,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
              _buildEditContainer([
                _buildEditRow('Nama Lengkap', _nameController, 'Nama Anda'),
                _buildEditRow('Tinggi Badan', _heightController, 'cm',
                    isNumeric: true),
                const SizedBox(height: 8),
                // Berat dan Target Berat di 1 baris
                Row(
                  children: [
                    Expanded(
                      child: _buildEditRowCompact(
                          'Berat Badan', _weightController, 'kg',
                          isNumeric: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEditRowCompact(
                          'Target Berat', _targetWeightController, 'kg',
                          isNumeric: true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDropdownRow('Tanggal Lahir', _buildDatePickerButton()),
                _buildDropdownRow('Kelamin', _buildGenderDropdown()),
              ]),

              const SizedBox(height: 24),

              // === TARGET & TUJUAN ===
              _buildSectionTitle('Target & Kesehatan'),
              _buildEditContainer([
                _buildDropdownRow('Tujuan Utama', _buildDropdownGoal()),
                _buildDropdownRow('Aktivitas Harian', _buildDropdownActivity()),
              ]),

              const SizedBox(height: 24),

              // === ALERGI ===
              _buildSectionTitle('Alergi'),
              _buildAllergyCheckboxes(),

              const SizedBox(height: 24),

              // === POLA MAKAN ===
              _buildSectionTitle('Pola Makan'),
              _buildEditContainer([
                _buildDropdownRow(
                    'Intensitas Makan', _buildEatFrequencyDropdown()),
                _buildDropdownRow(
                    'Jam Bangun', _buildTimePickerButton('wakeTime')),
                _buildDropdownRow(
                    'Jam Tidur', _buildTimePickerButton('sleepTime')),
              ]),

              const SizedBox(height: 24),

              // === BUTTON SIMPAN DI BAWAH ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Profil',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildEditContainer(List<Widget> children) {
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

  Widget _buildEditRow(
      String label, TextEditingController controller, String hint,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              color: kLightGreyText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              suffixText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kMutedBorderGrey),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Wajib diisi';
              }
              if (isNumeric && double.tryParse(val) == null) {
                return 'Masukkan angka';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, Widget dropdown) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Funnel Display',
              color: kLightGreyText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          dropdown,
        ],
      ),
    );
  }

  Widget _buildDropdownActivity() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedActivityLevel,
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'very_low', child: Text("Sangat Rendah")),
        DropdownMenuItem(value: 'low', child: Text("Rendah")),
        DropdownMenuItem(value: 'medium', child: Text("Sedang")),
        DropdownMenuItem(value: 'high', child: Text("Tinggi")),
        DropdownMenuItem(value: 'very_high', child: Text("Sangat Tinggi")),
        DropdownMenuItem(
            value: 'extremely_high', child: Text("Sangat Sangat Tinggi")),
      ],
      onChanged: (val) => setState(() => _selectedActivityLevel = val),
    );
  }

  Widget _buildDropdownGoal() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGoal,
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(
            value: 'lose_weight', child: Text("Menurunkan Berat Badan")),
        DropdownMenuItem(
            value: 'maintain_weight', child: Text("Menjaga Berat Badan")),
        DropdownMenuItem(
            value: 'gain_weight', child: Text("Menaikkan Berat Badan")),
      ],
      onChanged: (val) => setState(() => _selectedGoal = val),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'Laki-laki', child: Text("Laki-laki")),
        DropdownMenuItem(value: 'Perempuan', child: Text("Perempuan")),
      ],
      onChanged: (val) => setState(() => _selectedGender = val),
    );
  }

  Widget _buildEatFrequencyDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedEatFrequency,
      decoration: InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kMutedBorderGrey)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 2, child: Text("2x Sehari")),
        DropdownMenuItem(value: 3, child: Text("3x Sehari")),
      ],
      onChanged: (val) => setState(() => _selectedEatFrequency = val),
    );
  }

  Widget _buildDatePickerButton() {
    final dateStr = _selectedBirthDate == null
        ? 'Pilih Tanggal'
        : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _selectedBirthDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: kMutedBorderGrey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateStr,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.calendar_today, color: kGreen, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerButton(String type) {
    final controller =
        type == 'wakeTime' ? _wakeTimeController : _sleepTimeController;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
              DateTime.parse('2024-01-01 ${controller.text}')),
        );
        if (picked != null) {
          setState(() {
            controller.text =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: kMutedBorderGrey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.text,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.access_time, color: kGreen, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildEditRowCompact(
      String label, TextEditingController controller, String hint,
      {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Funnel Display',
            color: kLightGreyText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            suffixText: hint,
            suffixStyle: const TextStyle(fontSize: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kMutedBorderGrey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(
            fontFamily: 'Funnel Display',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'Wajib diisi';
            if (isNumeric && double.tryParse(val) == null) return 'Angka!';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAllergyCheckboxes() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allergyOptions.map((allergy) {
          final isSelected = _selectedAllergies.contains(allergy);
          return CheckboxListTile(
            title: Text(
              allergy,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  // Jika "Tidak Ada Alergi" dipilih, hapus yang lain
                  if (allergy == 'Tidak Ada Alergi') {
                    _selectedAllergies.clear();
                    _selectedAllergies.add(allergy);
                  } else {
                    _selectedAllergies.remove('Tidak Ada Alergi');
                    _selectedAllergies.add(allergy);
                  }
                } else {
                  _selectedAllergies.remove(allergy);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }).toList(),
      ),
    );
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
}
