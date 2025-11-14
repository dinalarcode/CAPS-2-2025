import 'package:flutter/material.dart';
import 'models/user_profile_draft.dart';

UserProfileDraft getDraft(BuildContext ctx) =>
    (ModalRoute.of(ctx)!.settings.arguments as UserProfileDraft?) ?? UserProfileDraft();

Future<void> next(BuildContext ctx, String route, UserProfileDraft draft) async {
  await Navigator.pushNamed(ctx, route, arguments: draft);
}

void back(BuildContext ctx, UserProfileDraft draft) {
  Navigator.pop(ctx, draft);
}

class StepScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String nextText;
  const StepScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onNext,
    this.onBack,
    this.nextText = 'Lanjut',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: child),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: onBack, child: const Text('Kembali'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: onNext, child: Text(nextText))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
