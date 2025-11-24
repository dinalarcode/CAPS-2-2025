import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service untuk caching rekomendasi makanan harian
/// Cache disimpan selama 7 hari ke depan untuk konsistensi
class RecommendationCacheService {
  static const String _cachePrefix = 'meal_recommendation_';
  static const int _cacheDurationDays = 7;

  /// Simpan rekomendasi ke cache untuk tanggal tertentu
  static Future<void> saveRecommendation(
    DateTime date,
    Map<String, dynamic> recommendation,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final cacheKey = '$_cachePrefix$dateKey';
      
      final cacheData = {
        'date': dateKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': recommendation,
      };
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
      debugPrint('💾 Saved recommendation cache for $dateKey');
    } catch (e) {
      debugPrint('❌ Error saving recommendation cache: $e');
    }
  }

  /// Ambil rekomendasi dari cache untuk tanggal tertentu
  static Future<Map<String, dynamic>?> getRecommendation(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final cacheKey = '$_cachePrefix$dateKey';
      
      final cached = prefs.getString(cacheKey);
      if (cached == null) return null;
      
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final cacheTimestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Cache valid selama 7 hari
      final cacheAge = Duration(milliseconds: now - cacheTimestamp);
      if (cacheAge.inDays >= _cacheDurationDays) {
        debugPrint('🗑️ Cache expired for $dateKey (${cacheAge.inDays} days old)');
        await prefs.remove(cacheKey);
        return null;
      }
      
      debugPrint('✅ Loaded recommendation cache for $dateKey (${cacheAge.inHours}h old)');
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error loading recommendation cache: $e');
      return null;
    }
  }

  /// Clear cache untuk tanggal tertentu
  static Future<void> clearRecommendation(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final cacheKey = '$_cachePrefix$dateKey';
      await prefs.remove(cacheKey);
      debugPrint('🗑️ Cleared recommendation cache for $dateKey');
    } catch (e) {
      debugPrint('❌ Error clearing recommendation cache: $e');
    }
  }

  /// Clear semua cache rekomendasi
  static Future<void> clearAllRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix)).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      debugPrint('🗑️ Cleared ${cacheKeys.length} recommendation caches');
    } catch (e) {
      debugPrint('❌ Error clearing all recommendation caches: $e');
    }
  }

  /// Hapus cache yang sudah expired (lebih dari 7 hari)
  static Future<void> cleanupExpiredCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Clean recommendation caches
      final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix)).toList();
      
      // Clean old menu_order caches (from old implementation)
      final menuOrderKeys = keys.where((k) => k.startsWith('menu_order_')).toList();
      
      final now = DateTime.now().millisecondsSinceEpoch;
      int cleanedCount = 0;
      
      for (final key in cacheKeys) {
        final cached = prefs.getString(key);
        if (cached == null) continue;
        
        try {
          final cacheData = jsonDecode(cached) as Map<String, dynamic>;
          final cacheTimestamp = cacheData['timestamp'] as int;
          final cacheAge = Duration(milliseconds: now - cacheTimestamp);
          
          if (cacheAge.inDays >= _cacheDurationDays) {
            await prefs.remove(key);
            cleanedCount++;
          }
        } catch (e) {
          // Invalid cache data, remove it
          await prefs.remove(key);
          cleanedCount++;
        }
      }
      
      // Remove all old menu_order caches
      for (final key in menuOrderKeys) {
        await prefs.remove(key);
        cleanedCount++;
      }
      
      if (cleanedCount > 0) {
        debugPrint('🧹 Cleaned up $cleanedCount caches (${menuOrderKeys.length} old menu_order)');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up caches: $e');
    }
  }

  /// Generate seed untuk deterministic shuffle berdasarkan tanggal
  /// Seed yang sama akan menghasilkan urutan yang sama
  static int generateDailySeed(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    // Convert date string to integer seed
    return dateKey.hashCode;
  }

  /// Shuffle list secara deterministic berdasarkan seed
  static List<T> deterministicShuffle<T>(List<T> list, int seed) {
    final shuffled = List<T>.from(list);
    final random = _SeededRandom(seed);
    
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    
    return shuffled;
  }
}

/// Simple seeded random number generator untuk deterministic shuffle
class _SeededRandom {
  int _seed;

  _SeededRandom(this._seed);

  int nextInt(int max) {
    // Linear congruential generator (LCG)
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return _seed % max;
  }
}
