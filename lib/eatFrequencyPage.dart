import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class EatFrequencyPage extends StatefulWidget {
  const EatFrequencyPage({super.key});

  @override
  State<EatFrequencyPage> createState() => _EatFrequencyPageState();
}

class _EatFrequencyPageState extends State<EatFrequencyPage> {
  late UserProfileDraft draft;
  int? _selected; // jumlah makan / hari

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);

    // gunakan nilai dari draft kalau ada (pakai ??= untuk tutup warning prefer_conditional_assignment)
    _selected ??= draft.eatFrequency;
  }

  void _onSelect(int value) {
    setState(() {
      _selected = value;
    });
  }

  void goNext() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih frekuensi makan terlebih dahulu.'),
        ),
      );
      return;
    }

    draft.eatFrequency = _selected;
    next(context, '/sleep-schedule', draft);
  }

  @override
  Widget build(BuildContext context) {
    const options = [2, 3];

    return StepScaffold(
      title: 'Frekuensi Makan',
      onBack: () => back(context, draft),
      onNext: goNext,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Seberapa sering kamu biasanya makan dalam sehari?',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Termasuk makan besar (sarapan, makan siang, makan malam) dan snack berat. '
            'Jawaban ini membantu kami menyusun pola jadwal makan yang realistis buatmu.',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // List pilihan radio
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ...options.map((opt) {
                    return RadioListTile<int>(
                      value: opt,
                      // ignore: deprecated_member_use
                      groupValue: _selected,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        if (val != null) _onSelect(val);
                      },
                      title: Text(
                        '$opt kali / hari',
                        style: const TextStyle(fontSize: 15),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      dense: true,
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hint kecil di bawah
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tenang, kamu masih bisa mengubah pengaturan ini nanti di profil. '
                  'Untuk sekarang, pilih yang paling mendekati kebiasaanmu sehari-hari.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
