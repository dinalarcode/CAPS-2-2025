// lib/weightInputPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class WeightInputPage extends StatefulWidget {
  const WeightInputPage({super.key});
  @override
  State<WeightInputPage> createState() => _WeightInputPageState();
}
class _WeightInputPageState extends State<WeightInputPage> {
  late final UserProfileDraft draft = getDraft(context);
  final _c = TextEditingController();
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _c.text = (draft.weightKg?.toString() ?? ''); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Berat Badan (kg)',
      child: TextField(
        controller: _c, keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'kg'),
      ),
      onBack: () => back(context, draft),
      onNext: () {
        draft.weightKg = double.tryParse(_c.text.replaceAll(',', '.'));
        if (draft.weightKg == null) return;
        next(context, '/target-weight', draft);
      },
    );
  }
}
