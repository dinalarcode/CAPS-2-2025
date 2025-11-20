import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Service untuk integrasi dengan Gemini AI untuk estimasi kalori makanan
class GeminiService {
  static const String _apiKey = 'AIzaSyCV7jCiePXjlfqR2vKheSuCUb-7juHwm00';
  static late final GenerativeModel _model;
  
  /// Initialize Gemini model
  static void initialize() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // Correct public model identifier
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 2048,
      ),
    );
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
    try {
      debugPrint('🤖 Gemini AI: Estimating calories for: $foodDescription');
      
      final prompt = '''
Anda adalah ahli gizi ramah yang membantu menghitung kalori makanan Indonesia.

User mendeskripsikan makanan: "$foodDescription"

Tugas Anda:
1. Identifikasi semua item makanan yang disebutkan
2. Estimasi kalori untuk SETIAP item (gunakan porsi standar Indonesia)
3. Berikan breakdown nutrisi (protein, karbohidrat, lemak dalam gram)
4. Response dalam format JSON yang VALID

Format response (HARUS JSON valid, tanpa markdown):
{
  "items": [
    {
      "name": "nama makanan",
      "portion": "ukuran porsi",
      "calories": kalori_angka,
      "protein": protein_gram,
      "carbs": karbo_gram,
      "fats": lemak_gram
    }
  ],
  "totalCalories": total_kalori_angka,
  "summary": "Penjelasan singkat estimasi dalam bahasa natural dan ramah"
}

PENTING:
- Response HARUS JSON valid tanpa backticks atau markdown
- Summary harus natural seperti chatbot ramah (contoh: Wah enak tuh! Kamu sepertinya makan nasi goreng dengan telur ceplok ya. Perkiraan total kalorinya sekitar 540 kkal.)
- JANGAN gunakan tanda bintang atau markdown formatting di summary
- Kalori harus realistis untuk makanan Indonesia
- Gunakan porsi standar: 1 piring nasi = 175g, 1 potong ayam = 100g, dll
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      debugPrint('📥 Gemini Response: $text');
      
      // Parse response menjadi structured data
      return _parseGeminiResponse(text, foodDescription);
    } catch (e) {
      debugPrint('❌ Error estimating calories: $e');
      // Fallback: return basic response
      return {
        'totalCalories': 0,
        'items': [],
        'response': 'Maaf, terjadi kesalahan saat menghitung kalori. Silakan coba lagi.',
        'error': e.toString(),
      };
    }
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
      
      // Simple JSON parsing (fallback jika ada masalah dengan format)
      // Extract totalCalories
      final caloriesMatch = RegExp(r'"totalCalories"\s*:\s*(\d+)').firstMatch(cleanResponse);
      final totalCalories = caloriesMatch != null ? int.parse(caloriesMatch.group(1)!) : 0;
      
      // Extract items (simplified)
      final items = <Map<String, dynamic>>[];
      final itemsMatch = RegExp(r'"items"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(cleanResponse);
      
      if (itemsMatch != null) {
        final itemsStr = itemsMatch.group(1) ?? '';
        final itemMatches = RegExp(r'\{[^}]+\}').allMatches(itemsStr);
        
        for (final match in itemMatches) {
          final itemStr = match.group(0) ?? '';
          final name = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(itemStr)?.group(1) ?? '';
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
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fats': fats,
            });
          }
        }
      }
      
      // Extract summary
      final summaryMatch = RegExp(r'"summary"\s*:\s*"([^"]+)"').firstMatch(cleanResponse);
      final summary = summaryMatch?.group(1) ?? '';
      
      return {
        'totalCalories': totalCalories,
        'items': items,
        'response': summary.isNotEmpty ? summary : response,
        'originalInput': originalInput,
      };
    } catch (e) {
      debugPrint('⚠️ Error parsing Gemini response: $e');
      // Return raw response if parsing fails
      return {
        'totalCalories': 0,
        'items': [],
        'response': response,
        'originalInput': originalInput,
      };
    }
  }
  
  /// Save logged food ke Firestore
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
      
      // Reference to daily log document
      final logRef = FirebaseFirestore.instance
          .collection('daily_food_logs')
          .doc(uid)
          .collection('logs')
          .doc(dateStr);
      
      // Get existing log or create new
      final logDoc = await logRef.get();
      
      // Generate smart title dari items makanan
      final smartTitle = generateFoodTitle(items);
      
      final foodEntry = {
        'description': smartTitle, // Gunakan AI-generated title
        'calories': calories,
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
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new log document
        await logRef.set({
          'date': dateStr,
          'meals': [foodEntry],
          'totalCalories': calories,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      debugPrint('✅ Food log saved: $calories kcal');
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
          .collection('daily_food_logs')
          .doc(uid)
          .collection('logs')
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
