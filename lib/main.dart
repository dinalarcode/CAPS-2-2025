// main.dart

import 'package:flutter/material.dart';
// 1. Import halaman utama aplikasi
// import 'package:nutrilink/homePage.dart'; // Ganti 'nutrilink' sesuai nama folder project kamu
import 'package:nutrilink/meal/recomendation.dart';

void main() {
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
      // home: const HomeScreen(), // Pastikan ada class HomeScreen di homepage.dart
      home: const RecommendationScreen(),
    
    );
  }
}
