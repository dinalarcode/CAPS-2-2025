// lib/birthDatePage.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// PASTIKAN Anda memiliki paket ini di pubspec.yaml
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class BirthDatePage extends StatefulWidget {
  const BirthDatePage({super.key});
  @override
  State<BirthDatePage> createState() => _BirthDatePageState();
}

class _BirthDatePageState extends State<BirthDatePage> {
  late final UserProfileDraft draft = getDraft(context);

  // Tanggal default 20 tahun yang lalu dari hari ini
  DateTime _initialDate(DateTime now) =>
      draft.birthDate ?? DateTime(now.year - 20, now.month, now.day);

  // --- Fungsi Hitung Umur ---
  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    // Mengurangi 1 jika ulang tahun belum tiba tahun ini
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // --- Fungsi untuk membuka Date Picker (HANYA MENGGUNAKAN ROLLER PICKER) ---
  Future<void> _selectDate() async {
    final now = DateTime.now();

    // Hapus logika showDatePicker bawaan

    DatePicker.showDatePicker(
      context,
      // Menyesuaikan format tampilan roller (cth: 01 May 2004)
      dateFormat: 'dd MMMM yyyy',
      // Menggunakan locale Indonesia (pastikan Anda mengimpor DateTimePickerLocale)
      locale: DateTimePickerLocale.id,
      pickerMode: DateTimePickerMode.date,
      initialDateTime: _initialDate(now),
      maxDateTime: now,
      minDateTime: DateTime(1900, 1, 1),
      onConfirm: (pickedDateTime, list) {
        // Hanya update state jika pengguna mengonfirmasi
        if (pickedDateTime != null) {
          setState(() => draft.birthDate = pickedDateTime);
        }
      },
    );
  }

  // --- Fungsi Lanjut (onNext) ---
  void _next() {
    if (draft.birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal lahir terlebih dahulu.')),
      );
      return;
    }

    saveDraft(context, draft);
    next(context, '/sex', draft);
  }

  // --- Fungsi Kembali (onBack) ---
  void _back() {
    saveDraft(context, draft);
    back(context, draft);
  }

  @override
  Widget build(BuildContext context) {
    final baseFillColor = kBaseGreyFill;
    final String dateDisplay = draft.birthDate != null
        ? DateFormat('dd MMM yyyy').format(draft.birthDate!)
        : 'Pilih Tanggal Lahir';
    final int age =
        draft.birthDate != null ? _calculateAge(draft.birthDate!) : 0;

    // Status visual border
    final Color inputBorderColor =
        draft.birthDate != null ? kGreen : Colors.black;

    return StepScaffold(
      title: '',
      onBack: _back,
      onNext: _next,
      nextEnabled: draft.birthDate != null,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // JUDUL (Meniru style halaman sebelumnya)
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              children: [
                const TextSpan(text: 'Kapan '),
                TextSpan(
                  text: 'tanggal lahirmu?',
                  style: TextStyle(color: kGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Subteks
          Text(
            'Kita akan menggunakannya untuk mempersonalisasikan aplikasi NutriLink untuk kamu.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kGreyText,
            ),
          ),
          const SizedBox(height: 24),

          // ==== INPUT DATE BOX (Memanggil Roller Picker) ====
          InkWell(
            onTap: _selectDate,
            child: Container(
              height: 120, // Tinggi yang cukup untuk area roller
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: inputBorderColor,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                dateDisplay,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color:
                      draft.birthDate != null ? Colors.black : kLightGreyText,
                ),
              ),
            ),
          ),

          // UMUR KAMU
          const SizedBox(height: 24),
          Center(
            child: RichText(
              // Menggunakan RichText untuk dua gaya berbeda
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kGreyText, // Gaya default untuk teks abu-abu
                ),
                children: [
                  const TextSpan(text: 'Kamu berumur: '),
                  TextSpan(
                    text: '${age} tahun', // Nilai ${age} dan ' tahun'
                    style: TextStyle(
                      color: kGreen, // Warna Hijau
                      fontWeight: FontWeight.w700, // Tebal (Bold)
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hint Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: baseFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black.withOpacity(0.4),
                style: BorderStyle.solid,
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: kGreyText, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Umur kamu berpengaruh terhadap berapa banyak energi yang dibutuhkan oleh tubuh setiap harinya.',
                    style:
                        TextStyle(color: kGreyText, fontSize: 13, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
