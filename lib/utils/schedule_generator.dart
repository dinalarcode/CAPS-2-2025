// lib/utils/schedule_generator.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutrilink/models/meal_models.dart';
import 'dart:developer' as developer;

final FirebaseFirestore _db = FirebaseFirestore.instance;

/// ------------------------------------------------------------
/// GENERATE MENU UNTUK HARI INI (RANDOM + FILTER ALERGI)
/// ------------------------------------------------------------
Future<void> generateMenuForToday({
  required List<String> mealTimes,        // contoh: ["Breakfast", "Lunch", "Dinner"]
  required List<String> userAllergies,    // contoh: ["seafood", "nuts"]
}) async {

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final today = DateTime.now();
  final todayKey = "${today.year}-${today.month}-${today.day}";

  // Cek apakah schedule hari ini sudah ada
  final existing = await _db
      .collection("users")
      .doc(uid)
      .collection("dailySchedules")
      .doc(todayKey)
      .get();

  if (existing.exists) {
    developer.log("Schedule hari ini sudah ada → tidak generate ulang.");
    return;
  }

  // Ambil semua menu dari Firestore
  final mealsSnapshot = await _db.collection("meals").get();

  List<MealModel> allMeals = mealsSnapshot.docs
      .map((doc) => MealModel.fromFirestore(doc))
      .toList();

  // Filter alergi
  List<MealModel> safeMeals = allMeals.where((meal) {
    for (var allergy in userAllergies) {
      if (meal.ingredients.contains(allergy.toLowerCase())) {
        return false; // skip jika mengandung alergi
      }
    }
    return true;
  }).toList();

  if (safeMeals.isEmpty) {
    developer.log("⚠ Tidak ada makanan yang aman dari alergi user!");
    return;
  }

  // Generate random menu untuk setiap jadwal makan
  Map<String, dynamic> generated = {};

  for (var time in mealTimes) {
    safeMeals.shuffle();
    final chosen = safeMeals.first;

    generated[time] = {
      "mealId": chosen.id,
      "name": chosen.name,
      "calories": chosen.calories,
      "imageUrl": chosen.imageUrl,
      "ingredients": chosen.ingredients,
      "timestamp": Timestamp.now(),
    };
  }

  // Simpan ke Firestore
  await _db
      .collection("users")
      .doc(uid)
      .collection("dailySchedules")
      .doc(todayKey)
      .set({
    "date": todayKey,
    "meals": generated,
  });

  developer.log("✅ Jadwal makan berhasil digenerate untuk hari ini!");
}
