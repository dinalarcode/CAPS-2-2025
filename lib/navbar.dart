import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  // Konstanta Warna
  // static const Color kSelectedColor = Color(0xFF5F9C3F); // kGreen dari homePage
  static const Color kSelectedColor = Color(0xFF75C778);
  static const Color kUnselectedColor = Color(0xFF888888); // kLightGreyText dari homePage
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
    {'icon': Icons.person, 'label': 'Profile', 'index': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _navItems.map((item) {
              return InkWell(
                onTap: () => onTap(item['index'] as int),
                child: _buildNavItem(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  index: item['index'] as int,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }  Widget _buildNavItem({
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