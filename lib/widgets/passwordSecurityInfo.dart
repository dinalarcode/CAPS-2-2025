import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';

class PasswordSecurityInfo extends StatelessWidget {
  const PasswordSecurityInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips Keamanan Password',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildSecurityTip(
          icon: Icons.check_circle,
          title: 'Gunakan kombinasi huruf, angka, dan simbol',
          isPositive: true,
        ),
        const SizedBox(height: 8),
        _buildSecurityTip(
          icon: Icons.check_circle,
          title: 'Minimal 8 karakter untuk keamanan maksimal',
          isPositive: true,
        ),
        const SizedBox(height: 8),
        _buildSecurityTip(
          icon: Icons.error,
          title: 'Jangan gunakan informasi pribadi (nama, tanggal lahir)',
          isPositive: false,
        ),
        const SizedBox(height: 8),
        _buildSecurityTip(
          icon: Icons.error,
          title: 'Jangan bagikan password dengan siapa pun',
          isPositive: false,
        ),
      ],
    );
  }

  Widget _buildSecurityTip({
    required IconData icon,
    required String title,
    required bool isPositive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isPositive ? AppColors.green : Colors.orange,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
