import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late UserProfileDraft draft;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
  }

  Future<void> _saveDraftToFirestore() async {
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;

      final data = <String, dynamic>{
        'name': draft.name ?? '',
        'target': draft.target ?? '',
        'healthGoal': draft.healthGoal ?? '',
        'challenges': draft.challenges,
        'heightCm': draft.heightCm,
        'weightKg': draft.weightKg,
        'targetWeightKg': draft.targetWeightKg,
        'birthDate': draft.birthDate,
        'sex': draft.sex ?? '',
        'activityLevel': draft.activityLevel ?? '',
        'allergies': draft.allergies,
        'eatFrequency': draft.eatFrequency,
        'sleepHours': draft.sleepHours,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (user != null) {
        // Jika sudah login (anon/sign-in lain), simpan ke users/{uid}
        await db
            .collection('users')
            .doc(user.uid)
            .set({'profile': data, 'uid': user.uid}, SetOptions(merge: true));
      } else {
        // Belum login → simpan ke koleksi sementara
        await db.collection('onboarding_drafts').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil awal tersimpan.')),
      );

      // Selesai onboarding → arahkan ke Login
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Registrasi',
      onBack: () => back(context, draft),
      onNext: _saving ? null : _saveDraftToFirestore,
      nextText: _saving ? 'Menyimpan…' : 'Simpan & Lanjut ke Login',
      child: ListView(
        children: [
          const Text(
            'Ringkasan Profil',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _kv('Nama', draft.name),
          _kv('Target', draft.target),
          _kv('Tujuan Kesehatan', draft.healthGoal),
          _kv('Tantangan',
              draft.challenges.isEmpty ? '-' : draft.challenges.join(', ')),
          _kv('Tinggi (cm)', draft.heightCm?.toStringAsFixed(1)),
          _kv('Berat (kg)', draft.weightKg?.toStringAsFixed(1)),
          _kv('Target Berat (kg)', draft.targetWeightKg?.toStringAsFixed(1)),
          _kv('Tanggal Lahir', draft.birthDate?.toIso8601String()),
          _kv('Jenis Kelamin', draft.sex),
          _kv('Aktivitas', draft.activityLevel),
          _kv('Alergi',
              draft.allergies.isEmpty ? '-' : draft.allergies.join(', ')),
          _kv('Frekuensi Makan (x/hari)', draft.eatFrequency?.toString()),
          _kv('Durasi Tidur (jam)', draft.sleepHours?.toStringAsFixed(1)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Untuk melanjutkan, data ini akan disimpan sebagai profil awal. '
            'Setelah itu kamu akan diarahkan ke halaman Masuk.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              key,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value == null || value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }
}
