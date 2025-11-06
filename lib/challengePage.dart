// lib/challengePage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});
  @override
  State<ChallengePage> createState() => _ChallengePageState();
}
class _ChallengePageState extends State<ChallengePage> {
  late final UserProfileDraft draft = getDraft(context);
  final opts = const [
    'Tidak ada waktu','Nafsu makan tinggi','Dukungan yang rendah','Perencanaan jadwal makan',
    'Isu kesehatan','Tidak ada partner dalam diet','Kurangnya informasi','Tidak percaya diri',
    'Merasa tetap termotivasi','Lainnya'
  ];
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Tantangan',
      child: ListView(
        children: opts.map((o) => CheckboxListTile(
          title: Text(o),
          value: draft.challenges.contains(o),
          onChanged: (v){
            setState(() {
              if (v == true) { if (!draft.challenges.contains(o)) draft.challenges.add(o); }
              else { draft.challenges.remove(o); }
            });
          },
        )).toList(),
      ),
      onBack: () => back(context, draft),
      onNext: () => next(context, '/height-input', draft),
    );
  }
}
