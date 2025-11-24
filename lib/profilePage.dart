import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrilink/welcomePage.dart';
import 'package:nutrilink/services/migrate_schedule_data.dart';
import 'viewProfilePage.dart'; // Pastikan file ini ada!
import 'editProfilePage.dart'; // Wajib ditambahkan!
import 'nutritionNeedsPage.dart';

const Color kGreen = Color(0xFF5F9C3F);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur ini akan segera tersedia!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // 🛠️ LOGIKA TAMPILAN PROFIL
    // ============================================================
    
    final rawProfile = userData?['profile'];
    final profileMap = rawProfile is Map ? rawProfile : null;

    String fullName = profileMap?['name']?.toString() ?? userData?['name']?.toString() ?? 'Pengguna';
    String email = FirebaseAuth.instance.currentUser?.email ?? '';

    // Deteksi Gender untuk Avatar
    String sex = (profileMap?['sex'] ?? userData?['sex'] ?? 'Laki-laki').toString().toLowerCase();
    String assetImage = 'assets/images/Male Avatar.png'; 
    if (sex.contains('female') || sex.contains('perempuan') || sex.contains('wanita')) {
      assetImage = 'assets/images/Female Avatar.png';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // --- HEADER FOTO PROFIL ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kGreen, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: kGreen.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: AssetImage(assetImage),
                            onBackgroundImageError: (exception, stackTrace) {
                               debugPrint("⚠️ Gagal load aset: $assetImage");
                            },
                            child: Image.asset(
                              assetImage,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 60, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- MENU BUTTONS ---
                  _buildMenuButton(
                    context,
                    icon: Icons.person_outline,
                    title: 'Lihat Profil',
                    subtitle: 'Detail data diri & BMI',
                    // ✅ NAVIGASI KE ViewProfilePage
                    onTap: () {
                      if (userData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewProfilePage(userData: userData!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Data profil sedang dimuat..."))
                        );
                      }
                    },
                  ),
                  // 2. TOMBOL EDIT PROFIL (SUDAH AKTIF)
                  _buildMenuButton(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama, berat, & tinggi',
                    onTap: () async {
                      if (userData != null) {
                        // Navigasi ke Edit Page dan TUNGGU hasilnya
                        final bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(userData: userData!),
                          ),
                        );

                        // Jika result == true (berarti user menekan tombol SIMPAN)
                        // Maka reload data profil agar tampilan ter-update
                        if (result == true) {
                          debugPrint("♻️ Data diedit, me-refresh profil...");
                          _loadUserData(); 
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Tunggu data profil termuat dulu."))
                        );
                      }
                    },
                  ),
                  // 3. TOMBOL KEBUTUHAN NUTRISI (SUDAH AKTIF)
                  _buildMenuButton(
                    context,
                    icon: Icons.health_and_safety_outlined,
                    title: 'Kebutuhan Nutrisi',
                    subtitle: 'Lihat target kalori & makronutrisi',
                    onTap: () {
                      if (userData != null) {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NutritionNeedsPage(userData: userData!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Data belum siap."))
                        );
                      }
                    },
                  ),
                  _buildMenuButton(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildMenuButton(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Ganti Password',
                    onTap: () => _showComingSoon(context),
                  ),

                  const SizedBox(height: 30),

                  // --- SYNC & LOGOUT ---
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                         showDialog(
                           context: context, 
                           barrierDismissible: false,
                           builder: (_) => const Center(child: CircularProgressIndicator())
                         );
                         
                         await MigrateScheduleData.migrateAllScheduleData();
                         
                         if(context.mounted) {
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("Data berhasil diperbarui"))
                           );
                         }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.sync, color: Colors.blue.shade700),
                      label: Text("Perbaiki Data (Sync)", style: TextStyle(color: Colors.blue.shade700)),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: const Text(
                        'Keluar Aplikasi',
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  Text(
                    "NutriLink v1.0.0",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: kGreen, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}