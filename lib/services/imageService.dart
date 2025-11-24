import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service untuk handle image loading dari Firebase Storage
/// dengan proper timeout, retry, dan caching
class ImageService {
  static final Map<String, String> _imageCache = {};
  static const Duration _timeout = Duration(seconds: 5);
  static const int _maxRetries = 2;

  /// Get image URL dengan caching dan timeout
  /// 
  /// Returns: URL string atau empty string jika gagal
  static Future<String> getImageUrl(String imageFileName) async {
    if (imageFileName.isEmpty) {
      return '';
    }

    // Check cache first
    if (_imageCache.containsKey(imageFileName)) {
      debugPrint('🖼️ Cache HIT: $imageFileName');
      return _imageCache[imageFileName]!;
    }

    // Try to fetch from Firebase Storage with retry
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint('🔄 Loading image (attempt $attempt/$_maxRetries): $imageFileName');
        
        final url = await FirebaseStorage.instance
            .ref('menus/$imageFileName')
            .getDownloadURL()
            .timeout(_timeout);
        
        // Cache successful result
        _imageCache[imageFileName] = url;
        debugPrint('✅ Image loaded: $imageFileName');
        return url;
        
      } on FirebaseException catch (e) {
        debugPrint('⚠️ Firebase error loading $imageFileName (attempt $attempt): ${e.code} - ${e.message}');
        
        // Don't retry on certain errors
        if (e.code == 'object-not-found' || e.code == 'unauthorized') {
          debugPrint('❌ Fatal error - stopping retries for $imageFileName');
          break;
        }
        
        // Wait before retry (except on last attempt)
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
        
      } catch (e) {
        debugPrint('⚠️ Error loading $imageFileName (attempt $attempt): $e');
        
        // Wait before retry (except on last attempt)
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    // All retries failed
    debugPrint('❌ Failed to load image after $_maxRetries attempts: $imageFileName');
    return '';
  }

  /// Batch load multiple images (untuk preload)
  static Future<Map<String, String>> batchLoadImages(List<String> imageFileNames) async {
    final results = <String, String>{};
    
    // Process in parallel with limit
    const batchSize = 5;
    for (int i = 0; i < imageFileNames.length; i += batchSize) {
      final batch = imageFileNames.skip(i).take(batchSize);
      final futures = batch.map((fileName) => getImageUrl(fileName));
      final urls = await Future.wait(futures);
      
      for (int j = 0; j < batch.length; j++) {
        results[batch.elementAt(j)] = urls[j];
      }
    }
    
    return results;
  }

  /// Clear cache
  static void clearCache() {
    _imageCache.clear();
    debugPrint('🧹 Image cache cleared');
  }

  /// Get cache size
  static int getCacheSize() {
    return _imageCache.length;
  }
}
