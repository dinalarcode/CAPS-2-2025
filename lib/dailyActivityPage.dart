import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class DailyActivityPage extends StatefulWidget {
  const DailyActivityPage({super.key});
  @override
  State<DailyActivityPage> createState() => _DailyActivityPageState();
}

class _DailyActivityPageState extends State<DailyActivityPage> {
  late UserProfileDraft draft;

  // Nilai-nilai yang kamu pakai sebelumnya
  static const List<String> _opts = <String>[
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Athlete',
  ];

  // Helper untuk bikin label pendek di chip/segmen
  String _short(String s) {
    switch (s) {
      case 'Sedentary':
        return 'Sedentary';
      case 'Lightly active':
        return 'Light';
      case 'Moderately active':
        return 'Moderate';
      case 'Very active':
        return 'Very';
      case 'Athlete':
        return 'Athlete';
      default:
        return s;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
  }

  @override
  Widget build(BuildContext context) {
    // Nilai terpilih saat ini (set) — SegmentedButton butuh Set<T>
    final selected = <String>{
      if (draft.activityLevel != null) draft.activityLevel!,
    };

    return StepScaffold(
      title: 'Aktivitas Harian',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih tingkat aktivitas harianmu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // ---- SegmentedButton (Material 3) ----
          SegmentedButton<String>(
            // Semua opsi jadi "segments"
            segments: _opts
                .map(
                  (o) => ButtonSegment<String>(
                    value: o,
                    label: Text(_short(o)),
                    tooltip: o, // tampil lengkap saat hover/long-press
                  ),
                )
                .toList(),
            selected: selected,
            // Saat ganti pilihan, Flutter akan ngasih Set<String> baru dgn 1 elemen
            onSelectionChanged: (newSelection) {
              // enforce single selection: ambil firstOrNull
              final val = newSelection.isEmpty ? null : newSelection.first;
              setState(() => draft.activityLevel = val);
            },
            // Biar bisa dipilih hanya satu
            multiSelectionEnabled: false,
            // Style opsional (biar lega di web/desktop)
            showSelectedIcon: false,
          ),

          const SizedBox(height: 12),
          // Tampilkan deskripsi ringkas dari pilihan
          Text(
            draft.activityLevel == null
                ? 'Tidak ada pilihan'
                : 'Terpilih: ${draft.activityLevel}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
      onBack: () => back(context, draft),
      onNext: () {
        if (draft.activityLevel == null) return;
        next(context, '/allergy', draft);
      },
    );
  }
}
