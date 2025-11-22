import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MealScheduleStorage {
  static const String key = "upcomingMeals";

  static Future<List<dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    return data != null ? json.decode(data) : [];
  }

  static Future<void> save(List meals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(meals));
  }

  static Future<void> addMeal(Map meal) async {
    final current = await load();
    current.add(meal);
    await save(current);
  }
}
