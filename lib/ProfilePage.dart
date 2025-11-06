import 'package:flutter/material.dart';
import 'widgets/bottom_navbar.dart';
import 'NutritionCalculation_ProfileRecap.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Widget _buildProfileOption({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFF7BB662),
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and Edit Profile Button
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Cena',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Profile Options
              _buildProfileOption(
                title: 'Profil Kebutuhan Nutrisi',
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NutritionRecapPage(),
                    ),
                  );
                },
              ),

              _buildProfileOption(
                title: 'Edit Profil',
                icon: Icons.edit,
                onTap: () {
                  // Handle navigation
                },
              ),

              _buildProfileOption(
                title: 'Notifikasi',
                icon: Icons.notifications_outlined,
                onTap: () {
                  // Handle navigation
                },
              ),

              _buildProfileOption(
                title: 'Ganti Password',
                icon: Icons.lock_outline,
                onTap: () {
                  // Handle navigation
                },
              ),

              _buildProfileOption(
                title: 'Keluar',
                icon: Icons.logout,
                iconColor: Colors.red,
                onTap: () {
                  // Handle logout
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }
}
