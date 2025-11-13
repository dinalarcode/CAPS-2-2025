// lib/heightInputPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class HeightInputPage extends StatefulWidget {
  const HeightInputPage({super.key});
  @override
  State<HeightInputPage> createState() => _HeightInputPageState();
}
class _HeightInputPageState extends State<HeightInputPage> {
  late final UserProfileDraft draft = getDraft(context);
  final _c = TextEditingController();
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _c.text = (draft.heightCm?.toString() ?? ''); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Tinggi Badan (cm)',
      child: TextField(
        controller: _c,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: 'cm'),
      ),
      onBack: () => back(context, draft),
      onNext: () {
        draft.heightCm = double.tryParse(_c.text.replaceAll(',', '.'));
        if (draft.heightCm == null) return;
        next(context, '/weight-input', draft);
      },
    );
  }
}
