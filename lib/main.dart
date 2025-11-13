// main.dart

import 'package:flutter/material.dart';
// 1. Import halaman utama aplikasi
import 'package:nutrilink/homePage.dart'; // Ganti 'nutrilink' sesuai nama folder project kamu
// import 'package:firebase_core/firebase_core.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
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
      home: const HomePage(), // Pastikan ada class HomeScreen di homepage.dart
    );
  }
}
