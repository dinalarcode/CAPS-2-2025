import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart';
import 'package:nutrilink/models/user_profile_draft.dart';

class SleepSchedulePage extends StatefulWidget {
  const SleepSchedulePage({super.key});
  @override
  State<SleepSchedulePage> createState() => _SleepSchedulePageState();
}

class _SleepSchedulePageState extends State<SleepSchedulePage> {
  late UserProfileDraft draft;
  final _controller = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    draft = getDraft(context);
    _controller.text = draft.sleepHours?.toString() ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Durasi Tidur',
      onBack: () => back(context, draft),
      onNext: () {
        final hours = double.tryParse(_controller.text);
        if (hours == null || hours <= 0) return;
        draft.sleepHours = hours;
        next(context, '/register', draft);
      },
      nextText: 'Lanjut ke Registrasi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Berapa jam kamu biasanya tidur setiap hari?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixText: 'jam',
              hintText: 'Contoh: 7.5',
            ),
          ),
        ],
      ),
    );
  }
}
