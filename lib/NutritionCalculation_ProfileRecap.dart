import 'package:flutter/material.dart';
import 'constants.dart'; // use constants here

class NutritionRecapPage extends StatelessWidget {
  final double? bmr;
  final double? tdee;

  const NutritionRecapPage({super.key, this.bmr, this.tdee});

  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color iconColor = const Color(0xFF7BB662),
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Handle section tap
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: iconColor),
                    ],
                  ),
                  if (children.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...children,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // White header with back button, logo and title
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    // Back button to the left of logo
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back),
                        color: kAccentGreen,
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Kembali',
                      ),
                    ),

                    // Logo
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/images/NutriLinkLogo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title (spans remaining space)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Perhitungan Kebutuhan Kalori dan Gizi',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: kAccentGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Personal Info Section
                    _buildProfileSection(
                      title: 'Informasi Pribadi',
                      icon: Icons.person,
                      children: [_buildInfoItem('Nama', 'John Cena')],
                    ),

                    // Body Measurements Section
                    _buildProfileSection(
                      title: 'Pengukuran Tubuh',
                      icon: Icons.straighten,
                      iconColor: Colors.blue,
                      children: [
                        _buildInfoItem('Tinggi Badan', '170 cm'),
                        _buildInfoItem('Berat Badan', '77 kg'),
                        _buildInfoItem('Target BB', '65 kg'),
                      ],
                    ),

                    // Activity Info Section
                    _buildProfileSection(
                      title: 'Aktivitas & Karakteristik',
                      icon: Icons.directions_run,
                      iconColor: Colors.orange,
                      children: [
                        _buildInfoItem('Umur', '21 Tahun'),
                        _buildInfoItem('Jenis Kelamin', 'Laki-Laki'),
                        _buildInfoItem('Tingkat Aktivitas', 'Rendah'),
                      ],
                    ),

                    // Nutrition Info Section
                    _buildProfileSection(
                      title: 'Informasi Nutrisi',
                      icon: Icons.local_fire_department,
                      iconColor: kAccentGreen,
                      children: [
                        _buildInfoItem(
                          'BMR (Basal Metabolic Rate)',
                          bmr != null
                              ? '${bmr!.toStringAsFixed(1)} kal'
                              : 'Belum dihitung',
                        ),
                        _buildInfoItem(
                          'TDEE (Total Daily Energy Expenditure)',
                          tdee != null
                              ? '${tdee!.toStringAsFixed(1)} kal'
                              : 'Belum dihitung',
                        ),
                      ],
                    ),

                    // Health Info Section
                    _buildProfileSection(
                      title: 'Informasi Kesehatan',
                      icon: Icons.medical_information,
                      iconColor: Colors.red,
                      children: [_buildInfoItem('Alergi', 'Seafood, Ikan')],
                    ),

                    // Meal Schedule Section
                    _buildProfileSection(
                      title: 'Jadwal Makan',
                      icon: Icons.schedule,
                      iconColor: Colors.purple,
                      children: [
                        _buildInfoItem('Intensitas Makan', '2x sehari'),
                        _buildInfoItem('Jam Bangun', '06:00'),
                        _buildInfoItem('Jam Tidur', '22:00'),
                      ],
                    ),

                    // Spacer before button
                    const SizedBox(height: 12),

                    // Calculate BMR/TDEE Button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/bmr');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        bmr == null
                            ? 'Hitung BMR dan TDEE'
                            : 'Hitung Ulang BMR dan TDEE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // (footer removed as requested)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
