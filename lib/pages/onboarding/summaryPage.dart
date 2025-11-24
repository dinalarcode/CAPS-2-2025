// lib/summaryPage.dart

import 'package:flutter/material.dart';
import 'onboardingHelpers.dart';
import '../../models/userProfileDraft.dart';

// ====== Palet warna konsisten dengan ChallengePage ======
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill =
    const Color(0xFF000000).withValues(alpha: 0.04);

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});
  
  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late UserProfileDraft draft;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
  }

  // ====== ALERT (SnackBar) ======
  void _toast(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red[600] : kGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ====== FORMAT HELPERS ======
  String _formatBirthDate(DateTime? date) {
    if (date == null) return '-';
    const hariIndonesia = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const bulanIndonesia = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final hari = hariIndonesia[date.weekday - 1];
    final tanggal = date.day;
    final bulan = bulanIndonesia[date.month - 1];
    final tahun = date.year;
    
    return '$hari, $tanggal $bulan $tahun';
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getActivityLevel(String? activityLevel) {
    const activityMap = {
      'sedentary': 'Level 1 (Sangat Rendah)',
      'lightly_active': 'Level 2 (Rendah)',
      'moderately_active': 'Level 3 (Sedang)',
      'very_active': 'Level 4 (Tinggi)',
      'extremely_active_1': 'Level 5 (Sangat Tinggi)',
      'extremely_active_2': 'Level 6 (Sangat Sangat Tinggi)',
    };
    return activityMap[activityLevel] ?? '-';
  }

  // --- LOGIKA FIREBASE ---
  Future<void> _saveDraftToFirestore() async {
    // Debug: Print draft sebelum dikirim ke RegisterPage
    debugPrint('=== DEBUG: DRAFT BEFORE SENDING TO REGISTER ===');
    debugPrint('name: ${draft.name}');
    debugPrint('target: ${draft.target}');
    debugPrint('healthGoal: ${draft.healthGoal}');
    debugPrint('challenges: ${draft.challenges}');
    debugPrint('heightCm: ${draft.heightCm}');
    debugPrint('weightKg: ${draft.weightKg}');
    debugPrint('targetWeightKg: ${draft.targetWeightKg}');
    debugPrint('birthDate: ${draft.birthDate}');
    debugPrint('sex: ${draft.sex}');
    debugPrint('activityLevel: ${draft.activityLevel}');
    debugPrint('allergies: ${draft.allergies}');
    debugPrint('eatFrequency: ${draft.eatFrequency}');
    debugPrint('wakeTime: ${draft.wakeTime}');
    debugPrint('sleepTime: ${draft.sleepTime}');
    debugPrint('sleepHours: ${draft.sleepHours}');
    debugPrint('===============================================');

    // Validasi basic
    if (draft.name == null ||
        draft.heightCm == null ||
        draft.weightKg == null) {
      _toast('Error: Nama, Tinggi, dan Berat harus diisi.');
      return;
    }

    setState(() => _saving = true);
    
    try {
      // Simpan draft ke local storage untuk digunakan setelah registrasi
      saveDraft(context, draft);
      
      if (!mounted) return;
      
      // PENTING: Kirim draft sebagai arguments agar data onboarding tersimpan di database
      Navigator.pushReplacementNamed(
        context, 
        '/register',
        arguments: draft, // ✅ Kirim draft data!
      );
      
    } catch (e) {
      debugPrint('Error navigating to register: $e');
      _toast('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ====== LOGIKA NEXT / BACK ======
  void _next() {
    if (!_saving) {
      _saveDraftToFirestore();
    }
  }

  void _back() {
    if (!_saving) {
      back(context, draft);
    }
  }

  // --- BUILD METHOD UTAMA ---
  @override
  Widget build(BuildContext context) {
    final bool isInputValid = !_saving;
    final int age = _calculateAge(draft.birthDate);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ====== KONTEN UTAMA ======
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: 'Ringkasan Profil',
                            style: TextStyle(color: kGreen),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pastikan semua data di bawah sudah benar. Setelah ini, Anda akan diarahkan ke halaman pendaftaran akun.',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ====== DATA PRIBADI ======
                    _buildSectionTitle('Data Pribadi'),
                    _buildInfoCard([
                      _buildRow('Nama', draft.name ?? '-'),
                      _buildRow('Tanggal Lahir', _formatBirthDate(draft.birthDate)),
                      _buildRow('Umur', '$age tahun'),
                      _buildRow('Jenis Kelamin', draft.sex ?? '-'),
                      _buildRow('Tinggi', '${draft.heightCm?.toStringAsFixed(1) ?? '-'} cm'),
                      _buildRow('Berat Sekarang', '${draft.weightKg?.toStringAsFixed(1) ?? '-'} kg'),
                    ]),
                    const SizedBox(height: 24),

                    // ====== TUJUAN DAN TARGET ======
                    _buildSectionTitle('Tujuan dan Target'),
                    _buildInfoCard([
                      _buildRow('Target Utama', draft.target ?? '-'),
                      _buildRow('Tujuan Kesehatan', draft.healthGoal ?? '-'),
                      _buildRow('Target Berat', '${draft.targetWeightKg?.toStringAsFixed(1) ?? '-'} kg'),
                      _buildListRow('Tantangan', draft.challenges),
                    ]),
                    const SizedBox(height: 24),

                    // ====== GAYA HIDUP ======
                    _buildSectionTitle('Gaya Hidup'),
                    _buildInfoCard([
                      _buildRow('Aktivitas', _getActivityLevel(draft.activityLevel)),
                      _buildRow('Frekuensi Makan', draft.eatFrequency != null ? '${draft.eatFrequency}x / hari' : '-'),
                      _buildRow('Jam Bangun', _formatTime(draft.wakeTime)),
                      _buildRow('Jam Tidur', _formatTime(draft.sleepTime)),
                      _buildListRow('Alergi', draft.allergies),
                    ]),
                    const SizedBox(height: 24),

                    // ====== INFO BOX ======
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kMutedBorderGrey,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000)
                                .withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: kGreyText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dengan menekan "Simpan & Lanjut", data ini akan disimpan sebagai profil awal Anda untuk pembuatan akun NutriLink.',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: kGreyText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====== BACK BUTTON bulat ======
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 24,
                  ),
                  tooltip: 'Kembali',
                  onPressed: _back,
                ),
              ),
            ),

            // ====== TOMBOL LANJUT ======
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: _saving ? 'Menyimpan...' : 'Simpan & Lanjut',
                  enabled: isInputValid,
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== WIDGET HELPERS ======
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Funnel Display',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kGreen,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: kMutedBorderGrey,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kLightGreyText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListRow(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kLightGreyText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: items.isEmpty
                ? const Text(
                    '-',
                    style: TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kGreen,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontFamily: 'Funnel Display',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ======================= Gradient Button =======================
class GradientButton extends StatefulWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool hover = false;
  bool press = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && (hover || press);

    final gradient = widget.enabled
        ? LinearGradient(
            colors: active
                ? const [kGreen, kGreenLight]
                : const [kGreenLight, kGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() {
        hover = false;
        press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enabled) setState(() => press = true);
        },
        onTapUp: (_) {
          if (widget.enabled) setState(() => press = false);
        },
        onTapCancel: () {
          if (widget.enabled) setState(() => press = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            color: widget.enabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.enabled ? kGreen : kDisabledGrey,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
