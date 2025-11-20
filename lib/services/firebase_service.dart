import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get userId {
    return _auth.currentUser?.uid ?? 'demo_user';
  }

  // Calculate daily calorie target based on user profile
  static Future<double> calculateDailyCalorieTarget(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;
      
      Map<String, dynamic> profile = userDoc.get('profile');
      double weight = profile['weightKg'] as double;
      double height = profile['heightCm'] as double;
      String sex = profile['sex'] as String;
      String activityLevel = profile['activityLevel'] as String;
      String healthGoal = profile['healthGoal'] as String;
      
      // Calculate BMR using Mifflin-St Jeor Equation
      double bmr;
      if (sex == 'male') {
        bmr = 10 * weight + 6.25 * height - 5 * 25 + 5; // Assuming age 25 for demo
      } else {
        bmr = 10 * weight + 6.25 * height - 5 * 25 - 161;
      }
      
      // Apply activity multiplier
      double activityMultiplier;
      switch (activityLevel) {
        case 'sedentary':
          activityMultiplier = 1.2;
          break;
        case 'light':
          activityMultiplier = 1.375;
          break;
        case 'moderate':
          activityMultiplier = 1.55;
          break;
        case 'active':
          activityMultiplier = 1.725;
          break;
        case 'very_active':
          activityMultiplier = 1.9;
          break;
        default:
          activityMultiplier = 1.55;
      }
      
      double dailyCalories = bmr * activityMultiplier;
      
      // Adjust for health goal
      if (healthGoal == 'lose_weight') {
        dailyCalories -= 500; // Subtract 500 calories for weight loss
      } else if (healthGoal == 'gain_weight') {
        dailyCalories += 500; // Add 500 calories for weight gain
      }
      
      return dailyCalories > 0 ? dailyCalories : 1500; // Minimum 1500 calories
    } catch (e) {
      debugPrint('Error calculating daily calorie target: $e');
      return 2000.0; // Default value
    }
  }

  // Get daily food log for specific date
  static Future<DailyFoodLogData?> getDailyFoodLog(DateTime date) async {
    try {
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      DocumentSnapshot doc = await _firestore
          .collection('daily_food_logs')
          .doc(userId)
          .collection('logs')
          .doc(dateString)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Calculate percentages
        double totalCalories = data['totalCalories'] as double;
        double totalCarbs = data['totalCarbs'] as double;
        double totalProtein = data['totalProtein'] as double;
        double totalFat = data['totalFat'] as double;
        
        double carbPercent = totalCalories > 0 ? (totalCarbs * 4 / totalCalories) * 100 : 0;
        double proteinPercent = totalCalories > 0 ? (totalProtein * 4 / totalCalories) * 100 : 0;
        double fatPercent = totalCalories > 0 ? (totalFat * 9 / totalCalories) * 100 : 0;
        double othersPercent = 100 - carbPercent - proteinPercent - fatPercent;
        
        List<FoodItem> foods = [];
        if (data['foods'] != null) {
          for (var foodData in data['foods'] as List<dynamic>) {
            foods.add(FoodItem(
              menuId: foodData['menuId'] ?? '',
              menuName: foodData['menuName'] ?? '',
              calories: foodData['calories']?.toDouble() ?? 0.0,
              carbs: foodData['carbs']?.toDouble() ?? 0.0,
              protein: foodData['protein']?.toDouble() ?? 0.0,
              fat: foodData['fat']?.toDouble() ?? 0.0,
              mealType: foodData['mealType'] ?? '',
            ));
          }
        }
        
        return DailyFoodLogData(
          totalCalories: totalCalories,
          carbPercent: carbPercent.clamp(0, 100),
          proteinPercent: proteinPercent.clamp(0, 100),
          fatPercent: fatPercent.clamp(0, 100),
          othersPercent: othersPercent.clamp(0, 100),
          foods: foods,
          dailyTarget: data['dailyTarget'] as double,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting daily food log: $e');
      return null;
    }
  }

  // Get monthly food statistics for favorite food
  static Future<MonthlyFoodStats?> getMonthlyFoodStats(DateTime date) async {
    try {
      String yearMonth = DateFormat('yyyy-MM').format(date);
      DocumentSnapshot doc = await _firestore
          .collection('monthly_food_statistics')
          .doc(userId)
          .collection('stats')
          .doc(yearMonth)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        var favoriteFoodData = data['favoriteFood'];
        
        return MonthlyFoodStats(
          totalMeals: data['totalMeals'] as int,
          favoriteFood: FavoriteFood(
            menuId: favoriteFoodData['menuId'],
            menuName: favoriteFoodData['menuName'],
            count: favoriteFoodData['count'] as int,
            percentage: favoriteFoodData['percentage'] as double,
          ),
          foodCounts: Map<String, int>.from(data['foodCounts'] as Map<String, dynamic>),
          nutritionTotals: NutritionTotals(
            totalCalories: data['nutritionTotals']['totalCalories'] as double,
            totalCarbs: data['nutritionTotals']['totalCarbs'] as double,
            totalProtein: data['nutritionTotals']['totalProtein'] as double,
            totalFat: data['nutritionTotals']['totalFat'] as double,
          ),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting monthly food stats: $e');
      return null;
    }
  }

  // Get monthly calorie logs for bar chart
  static Future<Map<int, double>> getMonthlyCalorieLogs(DateTime date) async {
    try {
      String monthYear = DateFormat('yyyy-MM').format(date);
      QuerySnapshot query = await _firestore
          .collection('daily_food_logs')
          .doc(userId)
          .collection('logs')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$monthYear-01')
          .where(FieldPath.documentId, isLessThanOrEqualTo: '$monthYear-31')
          .get();

      Map<int, double> result = {};
      for (var doc in query.docs) {
        String docId = doc.id;
        DateTime docDate = DateTime.parse(docId);
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        result[docDate.day] = (data['totalCalories'] ?? 0).toDouble();
      }
      return result;
    } catch (e) {
      debugPrint('Error getting monthly calorie logs: $e');
      return {};
    }
  }

  // Update or create daily food log
  static Future<void> updateDailyFoodLog(DateTime date, List<FoodItem> foods) async {
    try {
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      double totalCalories = foods.fold(0.0, (total, food) => total + food.calories);
      double totalCarbs = foods.fold(0.0, (total, food) => total + food.carbs);
      double totalProtein = foods.fold(0.0, (total, food) => total + food.protein);
      double totalFat = foods.fold(0.0, (total, food) => total + food.fat);
      
      // Get daily target
      double dailyTarget = await calculateDailyCalorieTarget(userId);
      
      // Create food log document
      await _firestore
          .collection('daily_food_logs')
          .doc(userId)
          .collection('logs')
          .doc(dateString)
          .set({
        'date': FieldValue.serverTimestamp(),
        'totalCalories': totalCalories,
        'totalCarbs': totalCarbs,
        'totalProtein': totalProtein,
        'totalFat': totalFat,
        'foods': foods.map((food) {
          return {
            'menuId': food.menuId,
            'menuName': food.menuName,
            'calories': food.calories,
            'carbs': food.carbs,
            'protein': food.protein,
            'fat': food.fat,
            'mealType': food.mealType,
            'timestamp': FieldValue.serverTimestamp(),
          };
        }).toList(),
        'dailyTarget': dailyTarget,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update monthly statistics
      await updateMonthlyFoodStatistics(date, foods);
    } catch (e) {
      debugPrint('Error updating daily food log: $e');
    }
  }

  // Update monthly food statistics
  static Future<void> updateMonthlyFoodStatistics(DateTime date, List<FoodItem> foods) async {
    try {
      String yearMonth = DateFormat('yyyy-MM').format(date);
      DocumentReference statsRef = _firestore
          .collection('monthly_food_statistics')
          .doc(userId)
          .collection('stats')
          .doc(yearMonth);
      
      // Get existing stats or create new ones
      DocumentSnapshot existingStats = await statsRef.get();
      Map<String, dynamic> statsData = {};
      
      if (existingStats.exists) {
        statsData = existingStats.data() as Map<String, dynamic>;
      } else {
        statsData = {
          'totalMeals': 0,
          'foodCounts': {},
          'nutritionTotals': {
            'totalCalories': 0.0,
            'totalCarbs': 0.0,
            'totalProtein': 0.0,
            'totalFat': 0.0,
          },
        };
      }
      
      // Update food counts
      Map<String, dynamic> foodCounts = statsData['foodCounts'] as Map<String, dynamic>;
      for (var food in foods) {
        if (foodCounts.containsKey(food.menuId)) {
          foodCounts[food.menuId] = (foodCounts[food.menuId] as int) + 1;
        } else {
          foodCounts[food.menuId] = 1;
        }
      }
      
      // Update nutrition totals
      Map<String, dynamic> nutritionTotals = statsData['nutritionTotals'] as Map<String, dynamic>;
      nutritionTotals['totalCalories'] = (nutritionTotals['totalCalories'] as double) + 
        foods.fold(0.0, (total, food) => total + food.calories);
      nutritionTotals['totalCarbs'] = (nutritionTotals['totalCarbs'] as double) + 
        foods.fold(0.0, (total, food) => total + food.carbs);
      nutritionTotals['totalProtein'] = (nutritionTotals['totalProtein'] as double) + 
        foods.fold(0.0, (total, food) => total + food.protein);
      nutritionTotals['totalFat'] = (nutritionTotals['totalFat'] as double) + 
        foods.fold(0.0, (total, food) => total + food.fat);
      
      // Update total meals
      statsData['totalMeals'] = (statsData['totalMeals'] as int) + foods.length;
      statsData['foodCounts'] = foodCounts;
      statsData['nutritionTotals'] = nutritionTotals;
      
      // Find favorite food
      String favoriteMenuId = '';
      int maxCount = 0;
      double favoritePercentage = 0.0;
      String favoriteMenuName = '';
      
      for (var entry in foodCounts.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          favoriteMenuId = entry.key;
          
          // Get menu name from menus collection
          DocumentSnapshot menuDoc = await _firestore.collection('menus').doc(entry.key).get();
          if (menuDoc.exists) {
            favoriteMenuName = menuDoc.get('name') as String;
          }
        }
      }
      
      if (maxCount > 0) {
        favoritePercentage = (maxCount / (statsData['totalMeals'] as int)) * 100;
        statsData['favoriteFood'] = {
          'menuId': favoriteMenuId,
          'menuName': favoriteMenuName,
          'count': maxCount,
          'percentage': favoritePercentage,
        };
      }
      
      // Save updated stats
      await statsRef.set(statsData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating monthly food statistics: $e');
    }
  }
}

// Model classes
class DailyFoodLogData {
  final double totalCalories;
  final double carbPercent;
  final double proteinPercent;
  final double fatPercent;
  final double othersPercent;
  final List<FoodItem> foods;
  final double dailyTarget;

  DailyFoodLogData({
    required this.totalCalories,
    required this.carbPercent,
    required this.proteinPercent,
    required this.fatPercent,
    required this.othersPercent,
    required this.foods,
    required this.dailyTarget,
  });
}

class FoodItem {
  final String menuId;
  final String menuName;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final String mealType;

  FoodItem({
    required this.menuId,
    required this.menuName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.mealType,
  });
}

class MonthlyFoodStats {
  final int totalMeals;
  final FavoriteFood favoriteFood;
  final Map<String, int> foodCounts;
  final NutritionTotals nutritionTotals;

  MonthlyFoodStats({
    required this.totalMeals,
    required this.favoriteFood,
    required this.foodCounts,
    required this.nutritionTotals,
  });
}

class FavoriteFood {
  final String menuId;
  final String menuName;
  final int count;
  final double percentage;

  FavoriteFood({
    required this.menuId,
    required this.menuName,
    required this.count,
    required this.percentage,
  });
}

class NutritionTotals {
  final double totalCalories;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;

  NutritionTotals({
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
  });
}