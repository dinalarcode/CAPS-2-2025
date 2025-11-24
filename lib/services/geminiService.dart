import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/config/apiKeys.dart';

/// Service untuk integrasi dengan Gemini AI untuk estimasi kalori makanan
class GeminiService {
  // API key now loaded from secure config file (not committed to git)
  static String get _apiKey => ApiKeys.geminiApiKey;
  static late final GenerativeModel _model;
  
  /// Initialize Gemini model
  static void initialize() {
    final apiKey = _apiKey;
    debugPrint('🔑 Initializing Gemini...');
    debugPrint('   API Key length: ${apiKey.length}');
    debugPrint('   API Key starts with: ${apiKey.substring(0, min(20, apiKey.length))}...');
    
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp', // Use latest experimental model
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 2048,
      ),
    );
    debugPrint('✅ Gemini model initialized successfully');
  }
  
  /// Estimasi kalori dari deskripsi makanan
  /// Returns Map dengan format:
  /// {
  ///   'totalCalories': 540,
  ///   'items': [
  ///     {'name': 'Nasi goreng', 'calories': 450, 'protein': 12, 'carbs': 65, 'fats': 15},
  ///     {'name': 'Telur ceplok', 'calories': 90, 'protein': 7, 'carbs': 1, 'fats': 6}
  ///   ],
  ///   'response': 'Estimasi kalori untuk makanan Anda...'
  /// }
  static Future<Map<String, dynamic>> estimateCalories(String foodDescription) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🤖 Gemini AI: Estimating calories for: $foodDescription (Attempt $attempt/$maxRetries)');
        
        // Determine current meal time context
        final now = DateTime.now();
        final hour = now.hour;
        final minute = now.minute;
        final timeInMinutes = hour * 60 + minute;
        
        String mealContext;
        if (timeInMinutes >= 181 && timeInMinutes <= 600) {
          // 03:01 - 10:00 = Sarapan
          mealContext = 'sarapan (pukul ${DateFormat('HH:mm').format(now)})';
        } else if (timeInMinutes >= 601 && timeInMinutes <= 1020) {
          // 10:01 - 17:00 = Makan Siang
          mealContext = 'makan siang (pukul ${DateFormat('HH:mm').format(now)})';
        } else {
          // 17:01 - 03:00 = Makan Malam
          mealContext = 'makan malam (pukul ${DateFormat('HH:mm').format(now)})';
        }
        
        final prompt = '''
Anda adalah ahli gizi yang membantu menghitung kalori makanan dan minuman Indonesia.

User mendeskripsikan: "$foodDescription"
Konteks waktu makan: $mealContext

IMPORTANT: You MUST respond with VALID JSON only. No markdown, no explanations outside JSON.

🔍 STEP 1 - VALIDATE INPUT:
If input is NOT about food/drink (e.g., greetings, questions, etc.), respond:
{
  "isFood": false,
  "summary": "Maaf, saya hanya bisa membantu menghitung kalori makanan dan minuman. Silakan ceritakan makanan atau minuman apa yang kamu konsumsi! 😊"
}

🍽️ STEP 2 - IF FOOD/DRINK:
1. Identify ALL food/drink items mentioned
2. Estimate calories for EACH item (use standard Indonesian portions)
3. Provide nutrient breakdown (protein, carbs, fats in grams)
4. Response in VALID JSON format

Required JSON format (NO markdown, NO backticks):
{
  "isFood": true,
  "items": [
    {
      "name": "Rawon",
      "portion": "1 porsi",
      "calories": 450,
      "protein": 25,
      "carbs": 35,
      "fats": 20
    },
    {
      "name": "Es jeruk",
      "portion": "1 gelas",
      "calories": 140,
      "protein": 1,
      "carbs": 35,
      "fats": 0
    }
  ],
  "totalCalories": 590,
  "totalProtein": 26,
  "totalCarbohydrate": 70,
  "totalFat": 20,
  "summary": "Wah, menu yang cocok untuk makan siang! Untuk 1 porsi rawon dan es jeruk manis, perkiraan total kalorinya sekitar 590 kkal."
}

RULES:
- Output MUST be valid JSON with NO markdown formatting
- Each item MUST have: name, portion, calories, protein, carbs, fats (use 0 if nutrient is negligible)
- ALL nutrients (protein, carbs, fats) are REQUIRED - use 0 for minimal amounts, NEVER null
- Calories must be realistic for Indonesian food
- Standard portions: 1 plate rice = 175g, 1 piece chicken = 100g
- Drinks count too: sweet iced tea ~100 kcal, milk coffee ~150 kcal
- For drinks/water with 0 nutrients, still include protein: 0, carbs: 0, fats: 0
- Summary should be friendly and natural in Indonesian
''';

        final content = [Content.text(prompt)];
        final response = await _model.generateContent(content);
        final text = response.text ?? '';
        
        debugPrint('📥 Gemini Raw Response: $text');
        debugPrint('📏 Response length: ${text.length} chars');
        
        // Parse response menjadi structured data
        final parsed = _parseGeminiResponse(text, foodDescription);
        
        debugPrint('✅ Parsed result: calories=${parsed['totalCalories']}, items=${parsed['items']?.length ?? 0}');
        
        return parsed;
        
      } catch (e) {
        debugPrint('❌ Error estimating calories: $e');
        debugPrint('   Error type: ${e.runtimeType}');
        debugPrint('   Full error: ${e.toString()}');
        
        final isServerError = e.toString().contains('503') || 
                            e.toString().contains('overloaded') ||
                            e.toString().contains('UNAVAILABLE');
        
        if (isServerError && attempt < maxRetries) {
          // Exponential backoff: 2s, 4s, 8s
          final delay = baseDelay * (1 << (attempt - 1));
          debugPrint('⏳ Server overloaded, retrying in ${delay.inSeconds}s... (Attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          continue; // Retry
        }
        
        // Final attempt failed or non-retryable error
        debugPrint('❌ Error estimating calories: $e');
        
        final errorMessage = isServerError
            ? 'Server AI sedang sibuk. Silakan coba lagi dalam beberapa saat. 🙏'
            : 'Maaf, terjadi kesalahan saat menghitung kalori. Silakan coba lagi.';
        
        return {
          'totalCalories': 0,
          'items': [],
          'response': errorMessage,
          'error': e.toString(),
          'isRetryable': isServerError,
        };
      }
    }
    
    // Should never reach here, but just in case
    return {
      'totalCalories': 0,
      'items': [],
      'response': 'Gagal menghubungi server AI setelah $maxRetries percobaan. Silakan coba lagi nanti.',
      'error': 'Max retries exceeded',
    };
  }
  
  /// Parse Gemini response ke format structured
  static Map<String, dynamic> _parseGeminiResponse(String response, String originalInput) {
    try {
      // Remove markdown code blocks if any
      String cleanResponse = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      // Try to find JSON object in response
      final jsonStart = cleanResponse.indexOf('{');
      final jsonEnd = cleanResponse.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1) {
        cleanResponse = cleanResponse.substring(jsonStart, jsonEnd + 1);
      }
      
      // Try to parse as proper JSON first
      try {
        // Use Dart's built-in JSON decoder
        final Map<String, dynamic> jsonData = json.decode(cleanResponse);
        
        // Add originalInput for saving
        jsonData['originalInput'] = originalInput;
        
        // Ensure required fields exist
        jsonData['totalCalories'] ??= 0;
        jsonData['items'] ??= [];
        
        debugPrint('✅ Successfully parsed JSON response');
        return jsonData;
      } catch (e) {
        debugPrint('⚠️ JSON parse failed, using regex fallback: $e');
      }
      
      // Fallback: Use regex parsing
      // Extract isFood
      final isFoodMatch = RegExp(r'"isFood"\s*:\s*(true|false)', caseSensitive: false).firstMatch(cleanResponse);
      final isFood = isFoodMatch?.group(1)?.toLowerCase() == 'true';
      
      // Extract totalCalories
      final caloriesMatch = RegExp(r'"totalCalories"\s*:\s*(\d+)').firstMatch(cleanResponse);
      final totalCalories = caloriesMatch != null ? int.parse(caloriesMatch.group(1)!) : 0;
      
      // Extract totalProtein, totalCarbohydrate, totalFat
      final proteinMatch = RegExp(r'"totalProtein"\s*:\s*(\d+\.?\d*)').firstMatch(cleanResponse);
      final totalProtein = proteinMatch != null ? double.parse(proteinMatch.group(1)!) : 0.0;
      
      final carbsMatch = RegExp(r'"totalCarbohydrate"\s*:\s*(\d+\.?\d*)').firstMatch(cleanResponse);
      final totalCarbohydrate = carbsMatch != null ? double.parse(carbsMatch.group(1)!) : 0.0;
      
      final fatsMatch = RegExp(r'"totalFat"\s*:\s*(\d+\.?\d*)').firstMatch(cleanResponse);
      final totalFat = fatsMatch != null ? double.parse(fatsMatch.group(1)!) : 0.0;
      
      // Extract items (simplified)
      final items = <Map<String, dynamic>>[];
      final itemsMatch = RegExp(r'"items"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(cleanResponse);
      
      if (itemsMatch != null) {
        final itemsStr = itemsMatch.group(1) ?? '';
        final itemMatches = RegExp(r'\{[^}]+\}').allMatches(itemsStr);
        
        for (final match in itemMatches) {
          final itemStr = match.group(0) ?? '';
          final name = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(itemStr)?.group(1) ?? '';
          final portion = RegExp(r'"portion"\s*:\s*"([^"]+)"').firstMatch(itemStr)?.group(1) ?? '';
          final calories = int.tryParse(
            RegExp(r'"calories"\s*:\s*(\d+)').firstMatch(itemStr)?.group(1) ?? '0'
          ) ?? 0;
          final protein = double.tryParse(
            RegExp(r'"protein"\s*:\s*(\d+\.?\d*)').firstMatch(itemStr)?.group(1) ?? '0'
          ) ?? 0.0;
          final carbs = double.tryParse(
            RegExp(r'"carbs"\s*:\s*(\d+\.?\d*)').firstMatch(itemStr)?.group(1) ?? '0'
          ) ?? 0.0;
          final fats = double.tryParse(
            RegExp(r'"fats"\s*:\s*(\d+\.?\d*)').firstMatch(itemStr)?.group(1) ?? '0'
          ) ?? 0.0;
          
          if (name.isNotEmpty && calories > 0) {
            items.add({
              'name': name,
              'portion': portion,
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fats': fats,
            });
          }
        }
      }
      
      // FALLBACK 1: If no items parsed but we have calories, create synthetic item from input
      if (items.isEmpty && totalCalories > 0 && isFood) {
        debugPrint('⚠️ No items array found, creating synthetic item from description');
        items.add({
          'name': originalInput,
          'portion': '1 porsi',
          'calories': totalCalories,
          'protein': totalProtein.round(),
          'carbohydrate': totalCarbohydrate.round(),
          'fat': totalFat.round(),
        });
      }
      
      // FALLBACK 2: If still no items and looks like food response, extract from narrative text
      if (items.isEmpty && cleanResponse.contains('590')) {
        debugPrint('⚠️ FALLBACK 2: Extracting from narrative text');
        // Try to extract calorie number from text like "590 kkal"
        final narrativeCalMatch = RegExp(r'(\d+)\s*kkal').firstMatch(cleanResponse);
        if (narrativeCalMatch != null) {
          final extractedCal = int.parse(narrativeCalMatch.group(1)!);
          items.add({
            'name': originalInput,
            'portion': '1 porsi',
            'calories': extractedCal,
            'protein': (extractedCal * 0.15 / 4).round(), // Estimate: 15% protein
            'carbs': (extractedCal * 0.55 / 4).round(),   // Estimate: 55% carbs  
            'fats': (extractedCal * 0.30 / 9).round(),    // Estimate: 30% fats
          });
          debugPrint('✅ Extracted $extractedCal kkal from narrative');
        }
      }
      
      // Extract summary
      final summaryMatch = RegExp(r'"summary"\s*:\s*"([^"]+)"', dotAll: true).firstMatch(cleanResponse);
      final summary = summaryMatch?.group(1)?.replaceAll(r'\n', '\n') ?? '';
      
      debugPrint('✅ Regex parsing successful: $totalCalories kcal, ${items.length} items');
      
      return {
        'isFood': isFood,
        'totalCalories': totalCalories,
        'totalProtein': totalProtein.round(),
        'totalCarbohydrate': totalCarbohydrate.round(),
        'totalFat': totalFat.round(),
        'items': items,
        'summary': summary.isNotEmpty ? summary : response,
        'originalInput': originalInput,
      };
    } catch (e) {
      debugPrint('❌ Error parsing Gemini response: $e');
      // Return raw response if parsing fails
      return {
        'isFood': true,
        'totalCalories': 0,
        'items': [],
        'summary': response,
        'originalInput': originalInput,
        'error': e.toString(),
      };
    }
  }
  
  /// Simple manual JSON parser for basic objects

  
  /// Save logged food ke Firestore dengan macronutrients
  static Future<bool> saveFoodLog({
    required int calories,
    required String foodDescription,
    required List<Map<String, dynamic>> items,
    String mealType = 'Lainnya',
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('❌ User not authenticated');
        return false;
      }
      
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('HH:mm').format(now);
      
      // Calculate total macronutrients
      double totalProtein = 0;
      double totalCarbohydrate = 0;
      double totalFat = 0;
      
      for (final item in items) {
        // Support multiple field name variations
        totalProtein += (item['protein'] as num?)?.toDouble() ?? (item['proteins'] as num?)?.toDouble() ?? 0;
        totalCarbohydrate += (item['carbohydrate'] as num?)?.toDouble() ?? (item['carbs'] as num?)?.toDouble() ?? 0;
        totalFat += (item['fat'] as num?)?.toDouble() ?? (item['fats'] as num?)?.toDouble() ?? 0;
        
        debugPrint('  Item: ${item['name']} - P:${item['protein'] ?? item['proteins']}, C:${item['carbohydrate'] ?? item['carbs']}, F:${item['fat'] ?? item['fats']}');
      }
      
      debugPrint('📊 Total macros calculated: P=${totalProtein.round()}g, C=${totalCarbohydrate.round()}g, F=${totalFat.round()}g');
      
      // Reference to daily log document
      final logRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_food_logs')
          .doc(dateStr);
      
      // Get existing log or create new
      final logDoc = await logRef.get();
      
      // Generate smart title dari items makanan
      final smartTitle = generateFoodTitle(items);
      
      final foodEntry = {
        'description': smartTitle, // Gunakan AI-generated title
        'calories': calories,
        'protein': totalProtein.round(),
        'carbohydrate': totalCarbohydrate.round(),
        'fat': totalFat.round(),
        'items': items,
        'mealType': mealType,
        'time': timeStr,
        'addedAt': Timestamp.now(),
        'source': 'ai_chatbot',
      };
      
      if (logDoc.exists) {
        // Append to existing meals array
        await logRef.update({
          'meals': FieldValue.arrayUnion([foodEntry]),
          'totalCalories': FieldValue.increment(calories),
          'totalProtein': FieldValue.increment(totalProtein.round()),
          'totalCarbohydrate': FieldValue.increment(totalCarbohydrate.round()),
          'totalFat': FieldValue.increment(totalFat.round()),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new log document
        await logRef.set({
          'date': dateStr,
          'meals': [foodEntry],
          'totalCalories': calories,
          'totalProtein': totalProtein.round(),
          'totalCarbohydrate': totalCarbohydrate.round(),
          'totalFat': totalFat.round(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('✅ Food log saved: $calories kcal | P: ${totalProtein.round()}g | C: ${totalCarbohydrate.round()}g | F: ${totalFat.round()}g');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving food log: $e');
      return false;
    }
  }
  
  /// Get today's total calories
  static Future<int> getTodayCalories() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 0;
      
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final logDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_food_logs')
          .doc(dateStr)
          .get();
      
      if (logDoc.exists) {
        final data = logDoc.data()!;
        return (data['totalCalories'] as num?)?.toInt() ?? 0;
      }
      
      return 0;
    } catch (e) {
      debugPrint('❌ Error getting today calories: $e');
      return 0;
    }
  }
  
  /// Generate food title dari items menggunakan AI logic
  static String generateFoodTitle(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return 'Makanan';
    
    // Jika hanya 1 item, langsung return nama item
    if (items.length == 1) {
      return items[0]['name'] ?? 'Makanan';
    }
    
    // Jika 2 item, gabung dengan "dan"
    if (items.length == 2) {
      return '${items[0]['name']} dan ${items[1]['name']}';
    }
    
    // Jika lebih dari 2 item, ambil 2 item dengan kalori tertinggi + sisanya
    final sortedItems = List<Map<String, dynamic>>.from(items)
      ..sort((a, b) => (b['calories'] as int).compareTo(a['calories'] as int));
    
    final firstTwo = sortedItems.take(2).map((item) => item['name']).join(', ');
    final remaining = items.length - 2;
    
    return '$firstTwo, +$remaining lainnya';
  }
}
