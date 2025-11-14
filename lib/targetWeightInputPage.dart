import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrilink/_onb_helpers.dart'; // Mengandung StepScaffold, kGreen, dll.
import 'package:nutrilink/models/user_profile_draft.dart';

class TargetWeightInputPage extends StatefulWidget {
  const TargetWeightInputPage({super.key});
  @override
  State<TargetWeightInputPage> createState() => _TargetWeightInputPageState();
}

class _TargetWeightInputPageState extends State<TargetWeightInputPage> {
  late UserProfileDraft draft;
  final _c = TextEditingController();

  // --- INISIALISASI & DISPOSE ---

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
    _c.text = draft.targetWeightKg == null
        ? ''
        : draft.targetWeightKg!.toStringAsFixed(
              draft.targetWeightKg! % 1 == 0 ? 0 : 1,
            );
    _c.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // Memaksa UI (misalnya border input) untuk update
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isInputValid(double? val) {
    // Validasi Dasar: Cek rentang wajar
    return val != null && val >= 20.0 && val <= 500.0;
  }

  String? _checkGoalValidation(double targetWeight) {
    final currentWeight = draft.weightKg;
    final goal = draft.target;

    if (currentWeight == null) {
      return 'Data berat badan saat ini tidak ditemukan. Silakan kembali dan isi berat badan Anda.';
    }

    if (goal == 'Menurunkan berat badan' && targetWeight >= currentWeight) {
      return 'Target harus LEBIH RENDAH dari berat badan Anda saat ini (${currentWeight} kg).';
    } else if (goal == 'Menaikkan berat badan' && targetWeight <= currentWeight) {
      return 'Target harus LEBIH TINGGI dari berat badan Anda saat ini (${currentWeight} kg).';
    } else if (goal == 'Menjaga berat badan' && targetWeight != currentWeight) {
      // Izinkan sedikit toleransi jika Anda mau, tapi untuk kode ini kita pakai sama persis
      return 'Target harus SAMA dengan berat badan Anda saat ini (${currentWeight} kg).';
    }
    return null; // Validasi sukses
  }

  void _goNext() {
    final raw = _c.text.trim().replaceAll(',', '.');
    final val = double.tryParse(raw);

    // 1. Validasi Dasar (Input Wajar)
    if (val == null) {
      _toast('Masukkan angka yang valid, contoh: 65 atau 65.5');
      return;
    }
    if (!_isInputValid(val)) {
      _toast('Nilai tidak wajar. Isi antara 20–500 kg.');
      return;
    }

    // 2. Validasi Tujuan (Goal Check)
    final validationError = _checkGoalValidation(val);
    if (validationError != null) {
      _toast(validationError);
      return;
    }

    // 3. Jika valid: Simpan & Lanjut
    draft.targetWeightKg = val;
    saveDraft(context, draft);
    next(context, '/birth-date', draft);
  }

  void _back() {
    back(context, draft);
  }

  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final baseFillColor = kBaseGreyFill;
    final currentInput = double.tryParse(_c.text.replaceAll(',', '.'));
    
    // Status validasi visual
    final bool isInputVisuallyValid = _isInputValid(currentInput);
    final Color inputBorderColor = isInputVisuallyValid ? kGreen : Colors.black;

    // Ambil string goal untuk ditampilkan
    final String goalString = draft.target ?? 'Target belum dipilih';

    return StepScaffold(
      title: '',
      onBack: _back,
      onNext: _goNext,
      nextEnabled: true, // Tombol selalu aktif untuk memicu alert/validasi

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
                  text: 'target berat badanmu?',
                  style: TextStyle(color: kGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Deskripsi Goal
          Text(
            'Target saat ini: ${goalString}. Target Anda harus konsisten dengan tujuan ini.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kGreyText,
            ),
          ),
          const SizedBox(height: 24),

          // ==== INPUT BERGAYA CARD (Sama seperti Weight/Height Input) ====
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
                      color: inputBorderColor, 
                      width: 2.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: TextFormField(
                      controller: _c,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Contoh: 65 atau 65.5',
                        hintStyle: TextStyle(
                          color: kLightGreyText.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
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
          const SizedBox(height: 12),

          // Tips Hint Box
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
                    'Tips: Target harus realistis dan konsisten dengan tujuan Anda. Anda tidak dapat menetapkan target yang lebih rendah saat tujuan Anda menaikkan berat badan.',
                    style: TextStyle(color: kGreyText, fontSize: 13, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}