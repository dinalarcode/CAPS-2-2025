// lib/heightInputPage.dart

import 'package:flutter/material.dart';
// Sesuaikan path import ini sesuai struktur proyek Anda
import '../_onb_helpers.dart'; 
import '../models/user_profile_draft.dart';

class HeightInputPage extends StatefulWidget {
  const HeightInputPage({super.key});
  @override
  State<HeightInputPage> createState() => _HeightInputPageState();
}

class _HeightInputPageState extends State<HeightInputPage> {
  // Pastikan draft dimuat dengan benar
  late final UserProfileDraft draft = getDraft(context);
  final _c = TextEditingController();

  // --- INISIALISASI & DISPOSE ---

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Isi controller dengan nilai draft yang ada
    _c.text = (draft.heightCm != null && draft.heightCm! > 0)
        ? draft.heightCm!.toStringAsFixed(draft.heightCm! % 1 == 0 ? 0 : 1)
        : '';
    // Tambahkan listener untuk memaksa rebuild saat teks berubah (opsional, tapi bagus untuk real-time feedback)
    _c.addListener(_onTextChanged); 
  }

  void _onTextChanged() {
    setState(() {}); // Memaksa UI (misalnya border input) untuk update jika ada state lain yang bergantung pada teks.
  }

  @override
  void dispose() {
    _c.removeListener(_onTextChanged);
    _c.dispose();
    super.dispose();
  }

  // --- LOGIKA VALIDASI DAN ALERT ---

  void _toast(String msg) {
    if (!mounted) return;
    // Menggunakan ScaffoldMessenger untuk menampilkan SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3), // Durasi tampil 3 detik
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _next() {
    final rawHeight = _c.text.replaceAll(',', '.').trim();
    draft.heightCm = double.tryParse(rawHeight);
    
    // 1. Cek apakah input kosong atau tidak valid (bukan angka)
    if (draft.heightCm == null) {
      _toast('Tinggi badan tidak boleh kosong atau tidak valid.');
      return;
    }
    
    // 2. Cek apakah tinggi badan di luar batas wajar (misalnya 50 cm - 250 cm)
    const double minHeight = 50.0;
    const double maxHeight = 250.0;
    
    if (draft.heightCm! < minHeight || draft.heightCm! > maxHeight) {
      // 🔥 ALERT (SnackBar) jika tinggi badan di luar batas wajar
      _toast('Tinggi badan tidak wajar. Isi antara $minHeight cm sampai $maxHeight cm.');
      return;
    }
    
    // 3. Jika valid: Lanjut ke halaman berikutnya
    saveDraft(context, draft); // Simpan perubahan tinggi
    next(context, '/weight-input', draft); // Ganti dengan rute yang sesuai
  }

  void _back() {
    back(context, draft);
  }
  
  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final baseFillColor = kBaseGreyFill; 
    
    // Status validasi dasar untuk feedback visual (tidak digunakan untuk tombol "enabled")
    final bool isInputValid = draft.heightCm != null && draft.heightCm! >= 50 && draft.heightCm! <= 250;
    final Color inputBorderColor = isInputValid ? kGreen : Colors.black;

    return StepScaffold(
      title: '',
      onBack: _back,
      onNext: _next,
      
      // Tombol SELALU AKTIF (true) agar fungsi _next selalu dijalankan 
      // dan dapat memicu alert.
      nextEnabled: true, 

      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // JUDUL
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              children: [
                const TextSpan(text: 'Berapa '),
                TextSpan(
                  text: 'tinggi badanmu?',
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

          // ==== INPUT BERGAYA CARD ====
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: inputBorderColor, // Feedback visual dari validasi
                      width: 2.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: TextFormField(
                      controller: _c,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Masukkan tinggi badan',
                        hintStyle: TextStyle(
                          color: kLightGreyText.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      // Menggunakan onChanged untuk memicu setState
                      onChanged: (text) {
                        final parsed = double.tryParse(text.replaceAll(',', '.'));
                        setState(() {
                          // Update draft secara real-time untuk feedback visual
                          draft.heightCm = parsed; 
                        });
                      },
                      onFieldSubmitted: (_) => _next(), // Trigger next saat submit keyboard
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Unit "cm"
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: baseFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'cm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
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
                    'Tinggi badanmu berperan dalam menentukan seberapa banyak energi yang dibutuhkan setiap harinya.',
                    style: TextStyle(color: kGreyText, fontSize: 13, height: 1.3),
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