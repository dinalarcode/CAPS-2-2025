// main.dart

import 'package:flutter/material.dart';
// 1. Import halaman utama aplikasi
import 'homePage.dart'; // Ganti jika perlu
import 'tdee_calculation.dart';
import 'NutritionCalculation_ProfileRecap.dart';
import 'bmr_calculation_clean.dart';
import 'ProfilePage.dart';
import 'constants.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'Funnel Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/bmr': (ctx) => const BMRCalculationCleanPage(),
        '/tdee': (ctx) => const TDEECalculationPage(),
        '/nutritionRecap': (ctx) => const NutritionRecapPage(),
        '/profile': (ctx) => const ProfilePage(),
        // tambahkan route lain jika perlu
      },
    );
  }
}
