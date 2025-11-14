import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class TargetWeightInputPage extends StatefulWidget {
  const TargetWeightInputPage({super.key});
  @override
  State<TargetWeightInputPage> createState() => _TargetWeightInputPageState();
}

class _TargetWeightInputPageState extends State<TargetWeightInputPage> {
  late UserProfileDraft draft;
  final _c = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
    _c.text = draft.targetWeightKg == null
        ? ''
        : draft.targetWeightKg!.toStringAsFixed(
            draft.targetWeightKg! % 1 == 0 ? 0 : 1,
          );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _goNext() {
    final raw = _c.text.trim().replaceAll(',', '.');
    final val = double.tryParse(raw);

    if (val == null) {
      _toast('Masukkan angka yang valid, contoh: 65 atau 65.5');
      return;
    }
    if (val <= 0 || val > 500) {
      _toast('Nilai tidak wajar. Isi antara 20–500 kg.');
      return;
    }

    draft.targetWeightKg = val;
    next(context, '/birth-date', draft);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Target Berat (kg)',
      onBack: () => back(context, draft),
      onNext: _goNext,
      nextText: 'Lanjut',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Berapa target berat badan kamu?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _goNext(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
            ],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Contoh: 65 atau 65.5',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tips: Sesuaikan dengan target realistis (0.25–1 kg/minggu).',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
