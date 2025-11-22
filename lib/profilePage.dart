import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrilink/homePage.dart'; // Digunakan untuk konstanta warna
import 'package:nutrilink/welcomePage.dart'; // Asumsikan file ini ada untuk halaman tujuan
import 'package:nutrilink/services/migrate_schedule_data.dart'; // Migration service

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Placeholder untuk konten profil lainnya di sini...
              const Text(
                'Coming Soon',
                style: TextStyle(fontSize: 16, color: kLightGreyText),
              ),
              const SizedBox(height: 30),

              // Tombol Migrate Schedule Data
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    // Run migration
                    final success = await MigrateScheduleData.migrateAllScheduleData();

                    if (context.mounted) {
                      Navigator.of(context).pop(); // Close loading

                      // Show result
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '✅ Data berhasil diperbarui! Silakan cek jadwal makan Anda.'
                                : '❌ Gagal memperbarui data. Silakan coba lagi.',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync, color: Colors.white),
                  label: const Text(
                    'Perbaiki Data Nutrisi',
                    style: TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Sign Out
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Keluar (Sign Out)',
                    style: TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRed, // Gunakan warna merah untuk tindakan keluar
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
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