// main.dart

import 'package:flutter/material.dart';
// 1. Impor file homepage.dart
import 'package:nutrilink/home_page.dart'; // Ganti 'nutrilink' jika nama project Anda berbeda

void main() {
  // Pastikan Anda memanggil class MyApp yang akan menampung MaterialApp
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App UI',
      debugShowCheckedModeBanner: false,
      // Tambahkan tema dasar agar sesuai dengan desain
      theme: ThemeData(
        primarySwatch: Colors.green,
        // Sesuaikan warna latar belakang
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      // 2. Ganti 'home' dengan widget HomeScreen
      home: const HomeScreen(), 
      // Pastikan class HomeScreen sudah dibuat di homepage.dart
    );
  }
}