// main.dart

import 'package:flutter/material.dart';
// 1. Import halaman utama aplikasi
import 'homePage.dart'; // Ganti jika perlu
import 'bmr_calculation_clean.dart';
import 'ProfilePage.dart';
import 'constants.dart';
import 'EatHourCalculationPage.dart';

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
        '/profile': (ctx) => const ProfilePage(),
        // TDEE and NutritionRecap pages require parameters and will be navigated to directly
        '/eatHour': (context) => EatHourCalculationPage(
          wakeTime: const TimeOfDay(hour: 6, minute: 0),
          bedTime: const TimeOfDay(hour: 22, minute: 0),
          mealsPerDay: 3,
        ),
      },
    );
  }
}
