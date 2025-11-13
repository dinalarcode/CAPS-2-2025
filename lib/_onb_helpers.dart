// File: _onb_helpers.dart

import 'package:flutter/material.dart';
import 'models/user_profile_draft.dart'; // Pastikan path ini benar

// --- Fungsi Helper Navigasi dan Draft ---

// Mengambil Draft Profile dari argumen rute.
UserProfileDraft getDraft(BuildContext ctx) =>
    (ModalRoute.of(ctx)!.settings.arguments as UserProfileDraft?) ?? UserProfileDraft();

// Melanjutkan ke rute berikutnya dengan membawa draft sebagai argumen.
Future<void> next(BuildContext ctx, String route, UserProfileDraft draft) async {
  // Menggunakan pushNamed dengan arguments untuk membawa draft terbaru
  await Navigator.pushNamed(ctx, route, arguments: draft);
}

// Kembali ke halaman sebelumnya.
void back(BuildContext ctx, UserProfileDraft draft) {
  // pop dengan draft sebagai result (data yang diubah)
  Navigator.pop(ctx, draft);
}

// **Fungsi saveDraft yang hilang (Ditambahkan untuk menghilangkan error)**
// Dalam konteks Onboarding ini, ini hanya mencatat bahwa draft telah diperbarui 
// secara lokal sebelum navigasi maju.
void saveDraft(BuildContext ctx, UserProfileDraft draft) {
  debugPrint('Draft di-update sebelum navigasi maju.');
  // Jika Anda memiliki service state management, logika penyimpanan akan berada di sini.
}

// --- Widget StepScaffold ---

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
                      // Tombol Kembali
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onBack, 
                          child: const Text('Kembali')
                        )
                      ),
                      const SizedBox(width: 12),
                      // Tombol Lanjut
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onNext, 
                          child: Text(nextText)
                        )
                      ),
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