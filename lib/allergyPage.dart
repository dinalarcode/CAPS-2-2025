// lib/allergyPage.dart
import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class AllergyPage extends StatefulWidget {
  const AllergyPage({super.key});
  @override
  State<AllergyPage> createState() => _AllergyPageState();
}
class _AllergyPageState extends State<AllergyPage> {
  late final UserProfileDraft draft = getDraft(context);
  final _c = TextEditingController();
  @override
  void dispose(){ _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Alergi Makanan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: draft.allergies.map((a)=>Chip(
              label: Text(a),
              onDeleted: (){ setState(()=>draft.allergies.remove(a)); },
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _c, decoration: const InputDecoration(hintText: 'Tambah alergi...', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: (){
                final t = _c.text.trim();
                if (t.isEmpty) return;
                setState((){ draft.allergies.add(t); _c.clear(); });
              }, child: const Text('Tambah')),
            ],
          ),
        ],
      ),
      onBack: () => back(context, draft),
      onNext: () => next(context, '/eat-frequency', draft),
    );
  }
}
