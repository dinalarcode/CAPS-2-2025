import 'package:flutter/material.dart';
import '../constants.dart';

class NavigationButtons extends StatelessWidget {
  final String nextText;
  final String backText;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool showBackButton;

  const NavigationButtons({
    super.key,
    this.nextText = 'Lanjutkan',
    this.backText = 'Kembali',
    required this.onNext,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentGreen,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            nextText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (showBackButton && onBack != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: Text(
              backText,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
        ],
      ],
    );
  }
}
