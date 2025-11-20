// This is a debug file to check Firestore menus data
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MealDebugger {
  static Future<void> checkAllMenus() async {
    try {
      debugPrint('🔍 CHECKING ALL MENUS IN FIRESTORE...');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('menus')
          .get();
      
      debugPrint('📊 Total menus found: ${snapshot.docs.length}');
      
      // Group by type
      Map<String, List<String>> mealsByType = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'Unknown';
        final name = data['name'] as String? ?? 'No name';
        final calories = data['calories'] as num? ?? 0;
        final image = data['image'] as String? ?? 'No image';
        
        if (!mealsByType.containsKey(type)) {
          mealsByType[type] = [];
        }
        mealsByType[type]!.add('$name ($calories cal)');
        
        debugPrint('  ✓ $type | $name | $calories cal | Image: ${image.isEmpty ? '❌ MISSING' : '✅ HAS'}');
      }
      
      debugPrint('\n📈 SUMMARY BY TYPE:');
      mealsByType.forEach((type, meals) {
        debugPrint('  $type: ${meals.length} meals');
        for (var meal in meals) {
          debugPrint('    - $meal');
        }
      });
      
      // Check for specific types
      debugPrint('\n🔎 LOOKING FOR SPECIFIC TYPES:');
      debugPrint('  Sarapan: ${mealsByType['Sarapan']?.length ?? 0} meals');
      debugPrint('  Makan Siang: ${mealsByType['Makan Siang']?.length ?? 0} meals');
      debugPrint('  Makan Malam: ${mealsByType['Makan Malam']?.length ?? 0} meals');
      
    } catch (e) {
      debugPrint('❌ Error checking menus: $e');
    }
  }
}
