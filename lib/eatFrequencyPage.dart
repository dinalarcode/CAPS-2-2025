// lib/eatFrequencyPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class EatFrequencyPage extends StatefulWidget {
  const EatFrequencyPage({super.key});
  @override
  State<EatFrequencyPage> createState() => _EatFrequencyPageState();
}
class _EatFrequencyPageState extends State<EatFrequencyPage> {
  late final UserProfileDraft draft = getDraft(context);
  double tmp = 3;
  @override
  void initState(){ super.initState(); tmp = (draft.eatFrequency ?? 3).toDouble(); }
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Frekuensi Makan (kali/hari)',
      child: Column(
        children: [
          Text('${tmp.toInt()}x / hari', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Slider(min: 1, max: 6, divisions: 5, value: tmp, onChanged: (v)=>setState(()=>tmp=v)),
        ],
      ),
      onBack: () => back(context, draft),
      onNext: () { draft.eatFrequency = tmp.toInt(); next(context, '/sleep-schedule', draft); },
    );
  }
}
