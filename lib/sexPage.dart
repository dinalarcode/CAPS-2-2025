import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class SexPage extends StatefulWidget {
  const SexPage({super.key});
  @override
  State<SexPage> createState() => _SexPageState();
}

class _SexPageState extends State<SexPage> {
  late UserProfileDraft draft;

  static const List<String> _options = ['Laki-laki', 'Perempuan'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
  }

  @override
  Widget build(BuildContext context) {
    final selected = <String>{
      if (draft.sex != null) draft.sex!,
    };

    return StepScaffold(
      title: 'Jenis Kelamin',
      onBack: () => back(context, draft),
      onNext: () {
        if (draft.sex == null) return;
        next(context, '/daily-activity', draft);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih jenis kelamin kamu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // ✅ Versi baru tanpa deprecated RadioListTile
          SegmentedButton<String>(
            segments: _options
                .map(
                  (opt) => ButtonSegment<String>(
                    value: opt,
                    label: Text(opt),
                    icon: Icon(
                      opt == 'Laki-laki' ? Icons.male : Icons.female,
                    ),
                  ),
                )
                .toList(),
            selected: selected,
            onSelectionChanged: (newSet) {
              final value = newSet.isEmpty ? null : newSet.first;
              setState(() => draft.sex = value);
            },
            multiSelectionEnabled: false,
            showSelectedIcon: false,
            // --- KUNCI: MENGIZINKAN SET KOSONG SAAT INITAL LOAD ---
            emptySelectionAllowed: true, 
            // ------------------------------------
          ),

          const SizedBox(height: 12),
          Text(
            draft.sex == null ? 'Belum dipilih' : 'Kamu memilih: ${draft.sex}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}