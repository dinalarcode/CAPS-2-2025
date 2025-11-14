import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

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

  String _formatBirthDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('d MMM yyyy', 'id').format(date);
  }

  // --- LOGIKA FIREBASE ---
  Future<void> _saveDraftToFirestore() async {
    // Validasi basic
    if (draft.name == null ||
        draft.heightCm == null ||
        draft.weightKg == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Nama, Tinggi, dan Berat harus diisi.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;

      final Timestamp? birthDateTimestamp = draft.birthDate != null
          ? Timestamp.fromDate(draft.birthDate!)
          : null;

      final data = <String, dynamic>{
        'name': draft.name ?? '',
        'target': draft.target ?? '',
        'healthGoal': draft.healthGoal ?? '',
        'challenges': draft.challenges, // diasumsikan non-null
        'heightCm': draft.heightCm,
        'weightKg': draft.weightKg,
        'targetWeightKg': draft.targetWeightKg,
        'birthDate': birthDateTimestamp,
        'sex': draft.sex ?? '',
        'activityLevel': draft.activityLevel ?? '',
        'allergies': draft.allergies, // diasumsikan non-null
        'eatFrequency': draft.eatFrequency,
        'sleepHours': draft.sleepHours,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (user != null) {
        await db
            .collection('users')
            .doc(user.uid)
            .set(
              {
                'profile': data,
                'uid': user.uid,
              },
              SetOptions(merge: true),
            );
      } else {
        await db.collection('onboarding_drafts').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil awal berhasil disimpan. Silakan daftarkan akun Anda.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // lanjut ke halaman register
      Navigator.pushReplacementNamed(context, '/register');
    } catch (e) {
      debugPrint('Gagal menyimpan profil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan profil. Coba lagi.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --- WIDGET HELPER ---
  Widget _kv(String key, String? value) {
    final displayValue =
        value == null || value.isEmpty || value == 'null' ? '-' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              key,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Nama Lengkap', draft.name),
        _kv('Tanggal Lahir', _formatBirthDate(draft.birthDate)),
        _kv('Jenis Kelamin', draft.sex),
        _kv('Tinggi (cm)', draft.heightCm?.toStringAsFixed(1)),
        _kv('Berat Awal (kg)', draft.weightKg?.toStringAsFixed(1)),
      ],
    );
  }

  Widget _buildLifestyleSummary() {
    final String allergiesText =
        draft.allergies.isEmpty ? '-' : draft.allergies.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Aktivitas', draft.activityLevel),
        _kv('Frekuensi Makan', draft.eatFrequency?.toString()),
        _kv('Durasi Tidur (jam)', draft.sleepHours?.toStringAsFixed(1)),
        _kv('Alergi', allergiesText),
      ],
    );
  }

  Widget _buildGoalSummary() {
    final String challengesText =
        draft.challenges.isEmpty ? '-' : draft.challenges.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Target Utama', draft.target),
        _kv('Tujuan Kesehatan', draft.healthGoal),
        _kv('Target Berat (kg)', draft.targetWeightKg?.toStringAsFixed(1)),
        _kv('Tantangan', challengesText),
      ],
    );
  }

  Widget _buildExpansionTile(String title, Widget content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: content,
          ),
        ],
      ),
    );
  }

  // --- BUILD METHOD UTAMA ---
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Summary',
      onBack: _saving ? null : () => back(context, draft),
      onNext: _saving ? null : _saveDraftToFirestore,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Ringkasan Profil',
            style: (Theme.of(context).textTheme.headlineMedium ??
                    const TextStyle())
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan semua data di bawah sudah benar. Setelah ini, Anda akan diarahkan ke halaman pendaftaran akun.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          _buildExpansionTile('Data Pribadi', _buildPersonalDataSummary()),
          _buildExpansionTile('Tujuan dan Target', _buildGoalSummary()),
          _buildExpansionTile('Gaya Hidup', _buildLifestyleSummary()),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Dengan menekan "Simpan & Lanjut ke Daftar", data ini akan disimpan sebagai profil awal Anda. '
            'Setelah itu kamu akan diarahkan ke halaman Pendaftaran Akun.',
            style: TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
