import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';

class TermsAndConditionsDetailPage extends StatelessWidget {
  const TermsAndConditionsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan variabel final (bukan getter di dalam method)
    final TextStyle body = AppTextStyles.bodyMedium.copyWith(
      height: 1.5,
      fontSize: 13,
      color: AppColors.black87,
    );

    final TextStyle heading = body.copyWith(fontWeight: FontWeight.w700);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== HEADER BAR =====
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Syarat & Ketentuan',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            const Divider(height: 1),

            // ===== BODY (SCROLLABLE) =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TITLE BLOCK (center + bold) ---
                        Center(
                          child: Text(
                            'NutriLink x HealthyGo',
                            textAlign: TextAlign.center,
                            style: heading,
                          ),
                        ),
                        Center(
                          child: Text(
                            'Terakhir diperbarui: 28 Oktober 2025',
                            textAlign: TextAlign.center,
                            style: heading,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // --- PARAGRAPH INTRO ---
                        Text(
                          'Selamat datang di NutriLink x HealthyGo, aplikasi rekomendasi nutrisi dan pemesanan makanan sehat. '
                          'Dengan menggunakan aplikasi ini, Anda dianggap telah membaca, memahami, dan menyetujui syarat dan ketentuan berikut.',
                          textAlign: TextAlign.left,
                          style: body,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 1. Definisi
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '1. Definisi\n', style: heading),
                              TextSpan(
                                text:
                                    '- Aplikasi: NutriLink x HealthyGo beserta fitur-fiturnya.\n'
                                    '- Pengguna: individu yang mengunduh, mendaftar, dan menggunakan aplikasi.\n'
                                    '- Mitra HealthyGo: pihak ketiga penyedia layanan katering yang terintegrasi.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 2. Persetujuan Penggunaan Data
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '2. Persetujuan Penggunaan Data\n',
                                  style: heading),
                              TextSpan(
                                text:
                                    'Anda memberi izin kepada kami untuk mengumpulkan, memproses, dan menyimpan data pribadi guna keperluan personalisasi layanan, termasuk:\n'
                                    '- Data pendaftaran (nama, email, telepon).\n'
                                    '- Informasi kesehatan dasar (berat/tinggi, usia, tujuan diet, alergi, preferensi).\n'
                                    '- Aktivitas dalam aplikasi (riwayat pemesanan, log makanan, pilihan rekomendasi).\n'
                                    '- Data lokasi (jika diizinkan) untuk menampilkan layanan terdekat, estimasi pengiriman, dan rekomendasi berbasis wilayah.\n'
                                    'Kami tidak menjual data Anda. Data dapat dibagikan ke HealthyGo hanya untuk kebutuhan pemesanan/pengantaran.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 3. Izin Lokasi (GPS)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '3. Izin Lokasi (GPS)\n', style: heading),
                              TextSpan(
                                text:
                                    'Lokasi digunakan untuk menampilkan katering terdekat, estimasi ongkir, serta fitur pelacakan pengiriman. '
                                    'Izin lokasi bersifat opsional; beberapa fitur mungkin tidak berfungsi tanpa izin tersebut. '
                                    'Izin dapat dinonaktifkan di pengaturan perangkat.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 4. Penggunaan Data Kesehatan
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '4. Penggunaan Data Kesehatan\n',
                                  style: heading),
                              TextSpan(
                                text:
                                    'Data kesehatan ringan dipakai untuk menghitung kebutuhan kalori (TDEE), mempersonalisasi menu, dan menyajikan progres. '
                                    'Aplikasi bukan alat diagnosis medis dan tidak menggantikan saran profesional.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 5. Pemesanan dan Pembayaran
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '5. Pemesanan dan Pembayaran\n',
                                  style: heading),
                              TextSpan(
                                text:
                                    'Transaksi dikelola oleh HealthyGo dan tunduk pada syarat mereka. '
                                    'NutriLink bertindak sebagai penghubung digital; kesalahan pengiriman/kualitas yang berasal dari mitra bukan tanggung jawab kami.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 6. Keamanan Data
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '6. Keamanan Data\n', style: heading),
                              TextSpan(
                                text:
                                    'Kami menerapkan standar keamanan industri. Namun tidak ada sistem yang 100% aman. '
                                    'Jaga kerahasiaan akun/kata sandi Anda.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 7. Hak & Kewajiban Pengguna
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '7. Hak & Kewajiban Pengguna\n',
                                  style: heading),
                              TextSpan(
                                text:
                                    '- Memberikan data yang akurat dan tidak menyesatkan.\n'
                                    '- Tidak menggunakan aplikasi untuk tujuan ilegal/merugikan.\n'
                                    '- Dapat meminta penghapusan data melalui menu “Hapus Akun” atau menghubungi kami.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 8. Hak & Kewajiban Pengembang
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '8. Hak & Kewajiban Pengembang\n',
                                  style: heading),
                              TextSpan(
                                text:
                                    'Kami dapat memperbarui fitur, konten, dan desain tanpa pemberitahuan. '
                                    'Kami dapat mengirim notifikasi terkait pembaruan nutrisi, promosi HealthyGo, atau tips yang relevan dengan profil Anda.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 9. Batasan Tanggung Jawab
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '9. Batasan Tanggung Jawab\n',
                                  style: heading),
                              TextSpan(
                                text:
                                    'Informasi dalam aplikasi bersifat edukatif/umum. Kami tidak bertanggung jawab atas dampak keputusan '
                                    'diet/kesehatan yang diambil berdasarkan rekomendasi aplikasi.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 10. Perubahan Syarat
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: '10. Perubahan Syarat\n', style: heading),
                              TextSpan(
                                text:
                                    'Kami dapat memperbarui dokumen ini sewaktu-waktu. Dengan tetap menggunakan aplikasi setelah pembaruan, Anda menyetujui perubahan tersebut.\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // 11. Kontak
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '11. Kontak\n', style: heading),
                              TextSpan(
                                text:
                                    'mikbalby@gmail.com | (+62) 857-9071-4547\n',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 12),

                        // Closing line with bold phrase
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Dengan menekan ',
                                style: body,
                              ),
                              TextSpan(
                                text: '“Ya, Saya setuju”',
                                style: heading, // BOLD sesuai request
                              ),
                              TextSpan(
                                text:
                                    ', Anda menyatakan telah membaca dan menyetujui Syarat & Ketentuan ini, termasuk pengelolaan data pribadi dan izin lokasi sesuai kebijakan yang berlaku.',
                                style: body,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ===== FOOTER (CLOSE BUTTON) =====
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    'Tutup',
                    style: AppTextStyles.button.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
