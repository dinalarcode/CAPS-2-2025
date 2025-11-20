// lib/meal/meal_rec.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// ===============================================
// 📐 NUTRITION CALCULATOR
// ===============================================
/// Menghitung kebutuhan kalori dan macro (Protein, Carbs, Fat)
/// berdasarkan data user dan target weight
class NutritionCalculator {
  /// Hitung kalori harian berdasarkan TDEE dan target
  ///
  /// [tdee]: Total Daily Energy Expenditure (dari BMR + activity)
  /// [target]: Target weight - "Mempertahankan berat badan", "Menurunkan berat badan", atau "Menaikkan berat badan"
  ///
  /// Returns: Kalori harian yang direkomendasikan
  static double calculateDailyCalories({
    required double tdee,
    required String target,
  }) {
    debugPrint('📊 Calculating daily calories: TDEE=$tdee, target=$target');
    
    if (target.toLowerCase().contains('menurun')) {
      // Deficit 15% untuk menurun berat badan
      final deficit = tdee * 0.85;
      debugPrint('   → Turun BB: deficit 15% = $deficit cal');
      return deficit;
    } else if (target.toLowerCase().contains('naik')) {
      // Surplus 10% untuk naik berat badan
      final surplus = tdee * 1.10;
      debugPrint('   → Naik BB: surplus 10% = $surplus cal');
      return surplus;
    }
    // Maintenance untuk mempertahankan
    debugPrint('   → Maintenance: $tdee cal');
    return tdee;
  }

  /// Hitung macro split (Protein, Carbs, Fats) berdasarkan kalori dan target
  /// 
  /// Returns: Map dengan keys 'protein', 'carbs', 'fats' (dalam gram)
  static Map<String, double> calculateMacros({
    required double dailyCalories,
    required String target,
  }) {
    debugPrint('🥗 Calculating macros: $dailyCalories calories, target=$target');
    
    double proteinPercent, carbPercent, fatPercent;
    
    if (target.toLowerCase().contains('menurun')) {
      // High protein untuk preserve muscle saat deficit
      proteinPercent = 0.35; // 35%
      carbPercent = 0.45;    // 45%
      fatPercent = 0.20;     // 20%
      debugPrint('   → Menurun: P=35%, C=45%, F=20% (high protein)');
    } else if (target.toLowerCase().contains('naik')) {
      // Lebih banyak carbs & fat untuk surplus
      proteinPercent = 0.25; // 25%
      carbPercent = 0.55;    // 55%
      fatPercent = 0.20;     // 20%
      debugPrint('   → Naik: P=25%, C=55%, F=20% (high carbs)');
    } else {
      // Balanced untuk maintenance
      proteinPercent = 0.25; // 25%
      carbPercent = 0.50;    // 50%
      fatPercent = 0.25;     // 25%
      debugPrint('   → Maintenance: P=25%, C=50%, F=25% (balanced)');
    }
    
    // Konversi ke gram (1g protein = 4 cal, 1g carbs = 4 cal, 1g fat = 9 cal)
    final proteinGrams = (dailyCalories * proteinPercent) / 4;
    final carbGrams = (dailyCalories * carbPercent) / 4;
    final fatGrams = (dailyCalories * fatPercent) / 9;
    
    debugPrint('   → Result: P=${proteinGrams.toStringAsFixed(1)}g, '
        'C=${carbGrams.toStringAsFixed(1)}g, F=${fatGrams.toStringAsFixed(1)}g');
    
    return {
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fats': fatGrams,
    };
  }

  /// Alokasikan macro per meal type (Sarapan 25%, Siang 40%, Malam 35%)
  /// 
  /// Returns: Map dengan keys 'sarapan', 'makanSiang', 'makanMalam'
  ///         Setiap berisi 'protein', 'carbs', 'fats', 'calories'
  static Map<String, Map<String, double>> calculateMealMacros({
    required Map<String, double> dailyMacros,
  }) {
    debugPrint('🍽️ Allocating macros per meal type');
    
    final proteinDaily = dailyMacros['protein']!;
    final carbsDaily = dailyMacros['carbs']!;
    final fatsDaily = dailyMacros['fats']!;
    
    // Hitung kalori total
    final caloriesTotal = (proteinDaily * 4) + (carbsDaily * 4) + (fatsDaily * 9);
    
    final sarapan = {
      'protein': proteinDaily * 0.25,
      'carbs': carbsDaily * 0.25,
      'fats': fatsDaily * 0.25,
      'calories': caloriesTotal * 0.25,
    };
    
    final makanSiang = {
      'protein': proteinDaily * 0.40,
      'carbs': carbsDaily * 0.40,
      'fats': fatsDaily * 0.40,
      'calories': caloriesTotal * 0.40,
    };
    
    final makanMalam = {
      'protein': proteinDaily * 0.35,
      'carbs': carbsDaily * 0.35,
      'fats': fatsDaily * 0.35,
      'calories': caloriesTotal * 0.35,
    };
    
    debugPrint('   Sarapan: ${sarapan['calories']!.toStringAsFixed(0)} cal');
    debugPrint('   Makan Siang: ${makanSiang['calories']!.toStringAsFixed(0)} cal');
    debugPrint('   Makan Malam: ${makanMalam['calories']!.toStringAsFixed(0)} cal');
    
    return {
      'sarapan': sarapan,
      'makanSiang': makanSiang,
      'makanMalam': makanMalam,
    };
  }
}

// ===============================================
// 🎯 MEAL RECOMMENDATION ENGINE
// ===============================================
/// Engine untuk merekomendasikan menu berdasarkan kebutuhan user
class MealRecommendationEngine {
  static const double _calorieTolerancePercent = 0.15; // ±15% tolerance

  /// Get rekomendasi menu untuk semua meal type
  /// 
  /// [userId]: Firebase user ID
  /// [allergies]: List alergi user (e.g., ["Seafood", "Udang"])
  /// [tdee]: Total Daily Energy Expenditure
  /// [target]: Target weight goal
  /// 
  /// Returns: Map dengan rekomendasi per meal type
  static Future<Map<String, List<Map<String, dynamic>>>> getRecommendations({
    required String userId,
    required List<String> allergies,
    required double tdee,
    required String target,
  }) async {
    debugPrint('🚀 Getting meal recommendations for user: $userId');
    
    try {
      // 0. Check cache first - jika ada dan masih fresh (< 24 jam), gunakan cache
      final cacheDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recommendationCache')
          .doc('latest')
          .get();
      
      if (cacheDoc.exists) {
        final cacheData = cacheDoc.data()!;
        final cacheTime = (cacheData['cachedAt'] as Timestamp?)?.toDate();
        final cacheAllergies = List<String>.from(cacheData['allergies'] ?? []);
        
        // Cache valid jika < 24 jam dan allergies sama
        if (cacheTime != null && 
            DateTime.now().difference(cacheTime).inHours < 24 &&
            _allergiesMatch(cacheAllergies, allergies)) {
          debugPrint('✅ Using cached recommendations (${DateTime.now().difference(cacheTime).inMinutes} min old)');
          
          return {
            'sarapan': List<Map<String, dynamic>>.from(cacheData['sarapan'] ?? []),
            'makanSiang': List<Map<String, dynamic>>.from(cacheData['makanSiang'] ?? []),
            'makanMalam': List<Map<String, dynamic>>.from(cacheData['makanMalam'] ?? []),
            'dailyStats': List<Map<String, dynamic>>.from(cacheData['dailyStats'] ?? []),
          };
        } else {
          debugPrint('⚠️ Cache expired or allergies changed, fetching fresh data');
        }
      }
      
      // 1. Hitung kebutuhan kalori & macro
      final dailyCalories = NutritionCalculator.calculateDailyCalories(
        tdee: tdee,
        target: target,
      );
      
      final dailyMacros = NutritionCalculator.calculateMacros(
        dailyCalories: dailyCalories,
        target: target,
      );
      
      final mealMacros = NutritionCalculator.calculateMealMacros(
        dailyMacros: dailyMacros,
      );
      
      // 2. Get rekomendasi per meal type
      final sarapanRecs = await _getMealRecommendations(
        mealType: 'Sarapan',
        targetCalories: mealMacros['sarapan']!['calories']!,
        targetMacros: mealMacros['sarapan']!,
        allergies: allergies,
        target: target,
      );
      
      final makanSiangRecs = await _getMealRecommendations(
        mealType: 'Makan Siang',
        targetCalories: mealMacros['makanSiang']!['calories']!,
        targetMacros: mealMacros['makanSiang']!,
        allergies: allergies,
        target: target,
      );
      
      final makanMalamRecs = await _getMealRecommendations(
        mealType: 'Makan Malam',
        targetCalories: mealMacros['makanMalam']!['calories']!,
        targetMacros: mealMacros['makanMalam']!,
        allergies: allergies,
        target: target,
      );
      
      debugPrint('✅ Recommendations ready');
      
      final result = {
        'sarapan': sarapanRecs,
        'makanSiang': makanSiangRecs,
        'makanMalam': makanMalamRecs,
        'dailyStats': [
          {
            'dailyCalories': dailyCalories,
            'protein': dailyMacros['protein'],
            'carbs': dailyMacros['carbs'],
            'fats': dailyMacros['fats'],
          }
        ],
      };
      
      // Cache hasil untuk performa di masa depan
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('recommendationCache')
            .doc('latest')
            .set({
          'sarapan': sarapanRecs,
          'makanSiang': makanSiangRecs,
          'makanMalam': makanMalamRecs,
          'dailyStats': result['dailyStats'],
          'allergies': allergies,
          'cachedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('💾 Recommendations cached for future use');
      } catch (e) {
        debugPrint('⚠️ Failed to cache recommendations: $e');
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ Error getting recommendations: $e');
      rethrow;
    }
  }

  /// Get rekomendasi untuk satu meal type dengan filter alergi & kalori
  static Future<List<Map<String, dynamic>>> _getMealRecommendations({
    required String mealType,
    required double targetCalories,
    required Map<String, double> targetMacros,
    required List<String> allergies,
    required String target,
  }) async {
    debugPrint('   Fetching $mealType (target: ${targetCalories.toStringAsFixed(0)} cal)...');
    
    try {
      // Query based on mealType using ID range
      // Sarapan: 1000-1999, Makan Siang: 2000-2999, Makan Malam: 3000-3999
      QuerySnapshot menus;
      if (mealType == 'Sarapan') {
        menus = await FirebaseFirestore.instance
            .collection('menus')
            .where('id', isGreaterThanOrEqualTo: 1000)
            .where('id', isLessThan: 2000)
            .get();
      } else if (mealType == 'Makan Siang') {
        menus = await FirebaseFirestore.instance
            .collection('menus')
            .where('id', isGreaterThanOrEqualTo: 2000)
            .where('id', isLessThan: 3000)
            .get();
      } else if (mealType == 'Makan Malam') {
        menus = await FirebaseFirestore.instance
            .collection('menus')
            .where('id', isGreaterThanOrEqualTo: 3000)
            .where('id', isLessThan: 4000)
            .get();
      } else {
        // Fallback: query by type field
        menus = await FirebaseFirestore.instance
            .collection('menus')
            .where('type', isEqualTo: mealType)
            .get();
      }
      
      debugPrint('   Found ${menus.docs.length} total menus for $mealType');
      
      // Filter berdasarkan alergi SAJA (tidak filter kalori dulu)
      final filtered = <Map<String, dynamic>>[];
      
      for (var doc in menus.docs) {
        final menu = doc.data() as Map<String, dynamic>;
        menu['docId'] = doc.id;
        
        // Check alergi - jika menu mengandung alergen user, skip
        if (_hasAllergen(menu, allergies)) {
          debugPrint('   ⚠️ Menu "${menu['name']}" mengandung alergen user - SKIP');
          continue;
        }
        
        // Generate image URL from Firebase Storage if image field exists
        final imageFileName = menu['image'] as String?;
        if (imageFileName != null && imageFileName.isNotEmpty) {
          try {
            final imageUrl = await FirebaseStorage.instance
                .ref('menus/$imageFileName')
                .getDownloadURL();
            menu['imageUrl'] = imageUrl;
            debugPrint('   ✅ Image OK: ${menu['name']}');
          } catch (e) {
            debugPrint('   ⚠️ Image FAIL for $imageFileName: $e');
            menu['imageUrl'] = '';
          }
        } else {
          menu['imageUrl'] = '';
        }
        
        // Calculate personalized score based on user target and nutrition
        final calories = (menu['calories'] as num?)?.toDouble() ?? 0;
        final protein = (menu['protein'] as num?)?.toDouble() ?? 0;
        final carbs = (menu['carbohydrate'] as num?)?.toDouble() ?? 0;
        final fats = (menu['fat'] as num?)?.toDouble() ?? 0;
        
        menu['matchScore'] = _calculateMatchScore(
          menuCalories: calories,
          targetCalories: targetCalories,
        );
        
        // Add personalized scoring based on user target
        menu['personalScore'] = _calculatePersonalizedScore(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
          target: target,
          targetCalories: targetCalories,
        );
        
        filtered.add(menu);
      }
      
      debugPrint('   ✅ After alergi filter: ${filtered.length} menus pass');
      
      // Sort by personalized score (descending) - makanan paling sesuai target user di depan
      filtered.sort((a, b) => (b['personalScore'] as double).compareTo(a['personalScore'] as double));
      
      debugPrint('   📊 Sorted by personalized score:');
      for (var menu in filtered.take(5)) {
        final cals = (menu['calories'] as num).toInt();
        final personalScore = (menu['personalScore'] as double).toStringAsFixed(1);
        final matchScore = (menu['matchScore'] as double).toStringAsFixed(1);
        debugPrint('      • ${menu['name']} ($cals cal, personal: $personalScore%, match: $matchScore%)');
      }
      
      return filtered;
    } catch (e) {
      debugPrint('❌ Error fetching $mealType: $e');
      rethrow;
    }
  }

  /// Check if two allergy lists are equal (for cache validation)
  static bool _allergiesMatch(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aSet = a.map((e) => e.toLowerCase()).toSet();
    final bSet = b.map((e) => e.toLowerCase()).toSet();
    return aSet.difference(bSet).isEmpty && bSet.difference(aSet).isEmpty;
  }
  
  /// Check apakah menu mengandung alergen user
  static bool _hasAllergen(Map<String, dynamic> menu, List<String> allergies) {
    if (allergies.isEmpty) return false;

    // Normalize allergies to lowercase for substring matching
    final lowerAllergies = allergies.map((a) => a.toString().toLowerCase()).toList();

    // Check in ingredients and allergens fields (if present)
    final ingredients = (menu['ingredients'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
    final allergens = (menu['allergens'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];

    // Also check tags (could be String or List) and the menu name/description
    List<String> tags = [];
    final tagsRaw = menu['tags'];
    if (tagsRaw is String) {
      tags = tagsRaw.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
    } else if (tagsRaw is List) {
      tags = tagsRaw.map((e) => e.toString().toLowerCase()).toList();
    }

    final name = (menu['name'] as String? ?? '').toLowerCase();
    final description = (menu['description'] as String? ?? '').toLowerCase();

    for (var allergen in lowerAllergies) {
      // ingredients
      for (var ing in ingredients) {
        if (ing.contains(allergen)) return true;
      }
      // explicit allergens field
      for (var alg in allergens) {
        if (alg.contains(allergen)) return true;
      }
      // tags
      for (var t in tags) {
        if (t.contains(allergen)) return true;
      }
      // name and description
      if (name.contains(allergen) || description.contains(allergen)) return true;
    }

    return false;
  }

  /// Hitung match score untuk menu (0-100)
  /// Semakin dekat dengan target kalori, semakin tinggi score
  static double _calculateMatchScore({
    required double menuCalories,
    required double targetCalories,
  }) {
    final diff = (menuCalories - targetCalories).abs();
    final tolerance = targetCalories * _calorieTolerancePercent;
    
    // Score: 100 jika exact match, 0 jika di edge tolerance
    final score = ((1 - (diff / tolerance)).clamp(0.0, 1.0)) * 100;
    return score;
  }
  
  /// Hitung personalized score berdasarkan target user (0-100)
  static double _calculatePersonalizedScore({
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
    required String target,
    required double targetCalories,
  }) {
    double score = 50.0; // Base score
    
    debugPrint('   Calculating personal score for: $calories cal, target: $target');
    
    if (target.toLowerCase().contains('menurun')) {
      // Target menurunkan berat badan - prefer lower calories, higher protein
      debugPrint('   → Weight loss target detected');
      
      // Calorie preference
      if (calories < targetCalories * 0.9) {
        score += 25;
      } else if (calories > targetCalories * 1.1) {
        score -= 20;
      }
      
      // High protein bonus (untuk preserve muscle)
      if (protein > 25) {
        score += 20;
      } else if (protein < 15) {
        score -= 10;
      }
      
      // Lower fat preference
      if (fats < 15) {
        score += 15;
      } else if (fats > 25) {
        score -= 10;
      }
      
      // Moderate carbs
      if (carbs >= 30 && carbs <= 45) {
        score += 10;
      }
      
    } else if (target.toLowerCase().contains('naik')) {
      // Target menaikkan berat badan - prefer higher calories, balanced macros
      debugPrint('   → Weight gain target detected');
      
      // Higher calorie preference
      if (calories > targetCalories * 1.1) {
        score += 25;
      } else if (calories < targetCalories * 0.9) {
        score -= 20;
      }
      
      // Good protein for muscle building
      if (protein >= 20 && protein <= 35) {
        score += 15;
      }
      
      // Higher carbs for energy
      if (carbs > 45) {
        score += 20;
      } else if (carbs < 30) {
        score -= 10;
      }
      
      // Moderate healthy fats
      if (fats >= 15 && fats <= 25) {
        score += 10;
      }
      
    } else {
      // Target menjaga berat badan - balanced approach
      debugPrint('   → Weight maintain target detected');
      
      // Balanced calories
      if (calories >= targetCalories * 0.95 && calories <= targetCalories * 1.05) {
        score += 20;
      } else if (calories < targetCalories * 0.8 || calories > targetCalories * 1.2) {
        score -= 15;
      }
      
      // Balanced protein
      if (protein >= 20 && protein <= 30) {
        score += 15;
      }
      
      // Balanced carbs
      if (carbs >= 35 && carbs <= 50) {
        score += 15;
      }
      
      // Balanced fats
      if (fats >= 12 && fats <= 20) {
        score += 15;
      }
    }
    
    final finalScore = score.clamp(0.0, 100.0);
    debugPrint('   → Final personal score: ${finalScore.toStringAsFixed(1)}');
    
    return finalScore;
  }

  /// Get single menu dengan detail lengkap
  static Future<Map<String, dynamic>?> getMenuDetail(String menuId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('menus')
          .doc(menuId)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting menu detail: $e');
      return null;
    }
  }
}

// ===============================================
// 🎯 MODEL: RECOMMENDATION RESULT
// ===============================================
/// Model untuk hasil rekomendasi
class MealRecommendationResult {
  final List<Map<String, dynamic>> sarapan;
  final List<Map<String, dynamic>> makanSiang;
  final List<Map<String, dynamic>> makanMalam;
  final double dailyCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatsGrams;

  MealRecommendationResult({
    required this.sarapan,
    required this.makanSiang,
    required this.makanMalam,
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatsGrams,
  });

  /// Convert dari map result ke model
  factory MealRecommendationResult.fromMap(Map<String, dynamic> map) {
    final dailyStats = (map['dailyStats'] as List).first as Map<String, dynamic>;
    
    return MealRecommendationResult(
      sarapan: List<Map<String, dynamic>>.from(map['sarapan'] ?? []),
      makanSiang: List<Map<String, dynamic>>.from(map['makanSiang'] ?? []),
      makanMalam: List<Map<String, dynamic>>.from(map['makanMalam'] ?? []),
      dailyCalories: dailyStats['dailyCalories'] ?? 0,
      proteinGrams: dailyStats['protein'] ?? 0,
      carbsGrams: dailyStats['carbs'] ?? 0,
      fatsGrams: dailyStats['fats'] ?? 0,
    );
  }

  /// Convert ke map untuk storage/passing
  Map<String, dynamic> toMap() => {
    'sarapan': sarapan,
    'makanSiang': makanSiang,
    'makanMalam': makanMalam,
    'dailyCalories': dailyCalories,
    'protein': proteinGrams,
    'carbs': carbsGrams,
    'fats': fatsGrams,
  };
}

// ===============================================
// 📝 EXAMPLE USAGE (untuk dokumentasi)
// ===============================================
/*
// Di halaman rekomendasi:

final recommendations = await MealRecommendationEngine.getRecommendations(
  userId: userId,
  allergies: userProfile['allergies'] ?? [],
  tdee: calculateTDEE(), // dari firebase_service.dart
  target: userProfile['target'] ?? 'Mempertahankan berat badan',
);

final result = MealRecommendationResult.fromMap(recommendations);

// Sekarang punya:
// result.sarapan → List menu untuk sarapan
// result.makanSiang → List menu untuk makan siang
// result.makanMalam → List menu untuk makan malam
// result.dailyCalories → Total kalori harian
// result.proteinGrams → Protein target (gram)
// result.carbsGrams → Carbs target (gram)
// result.fatsGrams → Fats target (gram)
*/
