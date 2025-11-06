import 'package:flutter/material.dart';
import '../constants.dart';

class StandardHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const StandardHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          if (showBackButton)
            SizedBox(
              width: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back),
                color: kAccentGreen,
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                tooltip: 'Kembali',
              ),
            ),
          SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(
              'assets/images/NutriLinkLogo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: kAccentGreen,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
