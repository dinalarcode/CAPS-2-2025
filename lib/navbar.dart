import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  // Konstanta Warna
  static const Color kSelectedColor = const Color(0xFF4CAF50);
  static const Color kUnselectedColor = Color(0xFFB39B93);
  static const Color kBackgroundColor = Color(0xFFFFF2DF);

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Data List untuk Item Navigasi
  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.access_time, 'label': 'Schedule', 'index': 0},
    {'icon': Icons.local_dining, 'label': 'Meal', 'index': 1},
    {'icon': Icons.home, 'label': 'Home', 'index': 2},
    {'icon': Icons.bar_chart, 'label': 'Report', 'index': 3},
    {'icon': Icons.person, 'label': 'Profil', 'index': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      // Ganti BottomNavigationBar dengan Container dan Row
      child: Container(
        height: 70, // Beri tinggi yang cukup untuk ikon, teks, dan indikator
        decoration: const BoxDecoration(
          color: kBackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _navItems.map((item) {
            return Expanded(
              child: InkWell(
                onTap: () => onTap(item['index'] as int),
                child: _buildNavItem(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  index: item['index'] as int,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = index == currentIndex;
    final Color itemColor = isSelected ? kSelectedColor : kUnselectedColor;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Icon
          Icon(
            icon,
            color: itemColor,
            size: 24,
          ),
          // 2. Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: itemColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          // 3. Indikator Garis
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 3,
              width: 40, // Lebar disesuaikan agar tidak terlalu panjang
              decoration: const BoxDecoration(
                color: kSelectedColor,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
            ),
        ],
      ),
    );
  }
}