// lib/weightInputPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart'; // Mengandung StepScaffold, kGreen, dll.
import 'package:nutrilink/models/user_profile_draft.dart';

class WeightInputPage extends StatefulWidget {
  const WeightInputPage({super.key});
  @override
  State<WeightInputPage> createState() => _WeightInputPageState();
}

class _WeightInputPageState extends State<WeightInputPage> {
  late final UserProfileDraft draft = getDraft(context);
  final _c = TextEditingController();

  // --- INISIALISASI & DISPOSE ---
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Isi controller dengan nilai draft yang ada
    _c.text = (draft.weightKg != null && draft.weightKg! > 0)
        ? draft.weightKg!.toStringAsFixed(draft.weightKg! % 1 == 0 ? 0 : 1)
        : '';
    _c.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // Memaksa UI untuk update (misalnya border input)
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
    // Menggunakan ScaffoldMessenger untuk menampilkan SnackBar (Alert)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _next() {
    final rawWeight = _c.text.replaceAll(',', '.').trim();
    draft.weightKg = double.tryParse(rawWeight);
    
    // 1. Cek apakah input kosong atau tidak valid (bukan angka)
    if (draft.weightKg == null) {
      _toast('Berat badan tidak boleh kosong atau tidak valid.');
      return;
    }
    
    // 2. Cek apakah berat badan di luar batas wajar (20 kg - 500 kg)
    const double minWeight = 20.0;
    const double maxWeight = 200.0;
    
    if (draft.weightKg! < minWeight || draft.weightKg! > maxWeight) {
      // Alert jika berat badan di luar batas wajar
      _toast('Berat badan tidak wajar. Isi antara $minWeight kg sampai $maxWeight kg.');
      return;
    }
    
    // 3. Jika valid: Lanjut ke halaman berikutnya
    saveDraft(context, draft);
    next(context, '/target-weight', draft); // Ganti dengan rute yang sesuai
  }

  void _back() {
    back(context, draft);
  }
  
  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final baseFillColor = kBaseGreyFill; 
    
    // Status validasi dasar untuk feedback visual
    final bool isInputValid = draft.weightKg != null && draft.weightKg! >= 20 && draft.weightKg! <= 500;
    final Color inputBorderColor = isInputValid ? kGreen : Colors.black;

    return StepScaffold(
      title: 'Berat Badan (kg)',
      onBack: _back,
      onNext: _next,
      // Tombol SELALU AKTIF agar fungsi _next selalu dijalankan dan dapat memicu alert.
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
                  text: 'berat badanmu?',
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

          // ==== INPUT BERGAYA CARD (Sama seperti Height Input Page) ====
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
                      color: inputBorderColor, // Feedback visual
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
                        hintText: 'Masukkan berat badan',
                        hintStyle: TextStyle(
                          color: kLightGreyText.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) {
                        final parsed = double.tryParse(text.replaceAll(',', '.'));
                        setState(() {
                          draft.weightKg = parsed; 
                        });
                      },
                      onFieldSubmitted: (_) => _next(),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Unit "kg"
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: baseFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'kg',
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
                Icon(Icons.info_outline, color: kGreyText, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berat badan berperan penting dalam menghitung Indeks Massa Tubuh (IMT) Anda dan kebutuhan nutrisi harian.',
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