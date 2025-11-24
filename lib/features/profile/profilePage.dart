import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/pages/auth/welcomePage.dart'; // Asumsikan file ini ada untuk halaman tujuan

// ===============================================
// 🎯 KELAS UTAMA: PROFILEPAGE
// ===============================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Fungsi untuk menangani proses Sign Out
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigasi ke WelcomePage/Login Page dan hapus semua rute sebelumnya.
      // Asumsikan WelcomePageStub adalah halaman awal (login/welcome).
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Menampilkan pesan error jika proses Sign Out gagal
      debugPrint('❌ Error signing out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal keluar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarBuilder.build(
        title: 'Profil Pengguna',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Placeholder untuk konten profil lainnya di sini...
              Text(
                'Coming Soon',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.lightGreyText),
              ),
              const SizedBox(height: AppSpacing.xxxl * 1.5),

              // Tombol Sign Out
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: AppDecorations.roundedButton(color: AppColors.red),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.xxlargeRadius,
                      onTap: () => _signOut(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, color: AppColors.white),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Keluar (Sign Out)', style: AppTextStyles.button),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
