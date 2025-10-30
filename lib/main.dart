// main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
// 1. Import halaman utama aplikasi
import 'homePage.dart'; // Ganti 'nutrilink' sesuai nama folder project kamu
import 'reportPage.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // Jalankan aplikasi Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLink x HealthyGo',
      debugShowCheckedModeBanner: false,

      // Tema global aplikasi
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Funnel Display', // opsional, agar konsisten dengan Figma
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),

      // 2. Ganti 'home' dengan halaman awal aplikasi
      home: const ReportScreen(), // Pastikan ada class ReportScreen di reportScreen.dart
    );
  }
}
