import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Script untuk migrate data lama di schedule collection
/// Mengubah field name lama (fats, carbohydrate) ke field name baru (fat, carbs)
class MigrateScheduleData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrate semua schedule data untuk user yang sedang login
  static Future<bool> migrateAllScheduleData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      debugPrint('🔄 Starting schedule data migration for user: $uid');

      // Get all schedule documents
      final scheduleSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .get();

      if (scheduleSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No schedule documents found');
        return true;
      }

      debugPrint('📊 Found ${scheduleSnapshot.docs.length} schedule documents');

      int updatedDocs = 0;
      int updatedMealsCount = 0;

      // Process each schedule document
      for (final doc in scheduleSnapshot.docs) {
        final data = doc.data();
        final meals = data['meals'] as List<dynamic>?;

        if (meals == null || meals.isEmpty) {
          debugPrint('   ⏭️ Skipping ${doc.id} - no meals');
          continue;
        }

        bool docNeedsUpdate = false;
        final updatedMeals = meals.map((m) {
          final meal = Map<String, dynamic>.from(m);
          bool mealUpdated = false;

          // Migrate 'fats' to 'fat'
          if (meal.containsKey('fats') && !meal.containsKey('fat')) {
            meal['fat'] = meal['fats'];
            // meal.remove('fats'); // Keep old field for compatibility
            mealUpdated = true;
            debugPrint('      ✓ Migrated fats → fat: ${meal['name']}');
          }

          // Migrate 'carbohydrate' to 'carbs'
          if (meal.containsKey('carbohydrate') && !meal.containsKey('carbs')) {
            meal['carbs'] = meal['carbohydrate'];
            // meal.remove('carbohydrate'); // Keep old field for compatibility
            mealUpdated = true;
            debugPrint('      ✓ Migrated carbohydrate → carbs: ${meal['name']}');
          }

          // Migrate 'carbo' to 'carbs'
          if (meal.containsKey('carbo') && !meal.containsKey('carbs')) {
            meal['carbs'] = meal['carbo'];
            // meal.remove('carbo'); // Keep old field for compatibility
            mealUpdated = true;
            debugPrint('      ✓ Migrated carbo → carbs: ${meal['name']}');
          }

          // Migrate 'karbohidrat' to 'carbs'
          if (meal.containsKey('karbohidrat') && !meal.containsKey('carbs')) {
            meal['carbs'] = meal['karbohidrat'];
            // meal.remove('karbohidrat'); // Keep old field for compatibility
            mealUpdated = true;
            debugPrint('      ✓ Migrated karbohidrat → carbs: ${meal['name']}');
          }

          // Migrate 'protein_g' to 'protein'
          if (meal.containsKey('protein_g') && !meal.containsKey('protein')) {
            meal['protein'] = meal['protein_g'];
            // meal.remove('protein_g'); // Keep old field for compatibility
            mealUpdated = true;
            debugPrint('      ✓ Migrated protein_g → protein: ${meal['name']}');
          }

          // Migrate 'kalori' to 'calories'
          if (meal.containsKey('kalori') && !meal.containsKey('calories')) {
            meal['calories'] = meal['kalori'];
            // meal.remove('kalori'); // Keep old field for compatibility
            mealUpdated = true;
            debugPrint('      ✓ Migrated kalori → calories: ${meal['name']}');
          }

          // Ensure all nutrition fields exist with default values
          meal['protein'] = meal['protein'] ?? 0;
          meal['carbs'] = meal['carbs'] ?? 0;
          meal['fat'] = meal['fat'] ?? 0;
          meal['calories'] = meal['calories'] ?? 0;

          if (mealUpdated) {
            updatedMealsCount++;
            docNeedsUpdate = true;
          }

          return meal;
        }).toList();

        // Update document if any meals were modified
        if (docNeedsUpdate) {
          await doc.reference.update({
            'meals': updatedMeals,
            'migratedAt': FieldValue.serverTimestamp(),
          });
          updatedDocs++;
          debugPrint('   ✅ Updated ${doc.id}');
        } else {
          debugPrint('   ⏭️ Skipped ${doc.id} - already up to date');
        }
      }

      debugPrint('🎉 Migration completed!');
      debugPrint('   📄 Updated documents: $updatedDocs/${scheduleSnapshot.docs.length}');
      debugPrint('   🍽️ Updated meals: $updatedMealsCount');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error migrating schedule data: $e');
      debugPrint('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Migrate single schedule document by date
  static Future<bool> migrateSingleDate(DateTime date) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr);

      final doc = await docRef.get();
      if (!doc.exists) {
        debugPrint('⚠️ No schedule found for $dateStr');
        return false;
      }

      final data = doc.data()!;
      final meals = data['meals'] as List<dynamic>?;

      if (meals == null || meals.isEmpty) {
        debugPrint('⚠️ No meals in $dateStr');
        return true;
      }

      final updatedMeals = meals.map((m) {
        final meal = Map<String, dynamic>.from(m);

        // Migrate all field names
        if (meal.containsKey('fats')) {
          meal['fat'] = meal['fats'];
          meal.remove('fats');
        }
        if (meal.containsKey('carbohydrate')) {
          meal['carbs'] = meal['carbohydrate'];
          meal.remove('carbohydrate');
        }
        if (meal.containsKey('carbo')) {
          meal['carbs'] = meal['carbo'];
          meal.remove('carbo');
        }

        // Ensure defaults
        meal['protein'] = meal['protein'] ?? 0;
        meal['carbs'] = meal['carbs'] ?? 0;
        meal['fat'] = meal['fat'] ?? 0;
        meal['calories'] = meal['calories'] ?? 0;

        return meal;
      }).toList();

      await docRef.update({
        'meals': updatedMeals,
        'migratedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Migrated schedule for $dateStr');
      return true;
    } catch (e) {
      debugPrint('❌ Error migrating single date: $e');
      return false;
    }
  }
}
