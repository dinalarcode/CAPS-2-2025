// lib/birthDatePage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class BirthDatePage extends StatefulWidget {
  const BirthDatePage({super.key});
  @override
  State<BirthDatePage> createState() => _BirthDatePageState();
}
class _BirthDatePageState extends State<BirthDatePage> {
  late final UserProfileDraft draft = getDraft(context);
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Tanggal Lahir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft.birthDate==null ? 'Belum dipilih' : draft.birthDate!.toLocal().toString().split(' ').first),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: draft.birthDate ?? DateTime(now.year-20, now.month, now.day),
                firstDate: DateTime(1900,1,1),
                lastDate: now,
              );
              if (picked != null) setState(() => draft.birthDate = picked);
            },
            child: const Text('Pilih Tanggal'),
          ),
        ],
      ),
      onBack: () => back(context, draft),
      onNext: () {
        if (draft.birthDate == null) return;
        next(context, '/sex', draft);
      },
    );
  }
}
