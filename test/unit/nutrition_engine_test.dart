// File: test/unit/nutrition_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilink/features/meal/mealRecommendationEngine.dart'; 

void main() {
  group('Nutrition Calculator Logic Tests', () {
    // Skenario 1: Menurunkan Berat Badan (Defisit)
    test('Calculates Deficit Correctly (Weight Loss)', () {
      const tdee = 2000.0;
      const target = 'Menurunkan berat badan';
      
      final result = NutritionCalculator.calculateDailyCalories(tdee: tdee, target: target);
      
      // Harapan: 2000 * 0.85 = 1700
      expect(result, 1700.0);
    });

    // Skenario 2: Menaikkan Berat Badan (Surplus)
    test('Calculates Surplus Correctly (Weight Gain)', () {
      const tdee = 2000.0;
      const target = 'Menaikkan berat badan';
      
      final result = NutritionCalculator.calculateDailyCalories(tdee: tdee, target: target);
      
      // Harapan: 2000 * 1.10 = 2200
      expect(result, 2200.0);
    });

    // Skenario 3: Macro Split untuk Weight Loss (High Protein)
    test('Macro Split is correct for Weight Loss', () {
      final macros = NutritionCalculator.calculateMacros(
        dailyCalories: 2000, 
        target: 'Menurunkan berat badan'
      );
      
      // Harapan: Protein 35%, Carbs 45%, Fat 20%
      // 2000 * 0.35 / 4 = 175g Protein
      expect(macros['protein'], 175.0);
      expect(macros['fats'], closeTo(44.4, 0.1)); // 2000*0.20/9
    });
  });
}