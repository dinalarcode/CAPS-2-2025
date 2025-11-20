import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ScheduleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Populate schedule dari order yang sudah dibayar
  static Future<bool> populateScheduleFromOrder(String orderId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      // Get order data
      final orderDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        debugPrint('❌ Order not found: $orderId');
        return false;
      }

      final orderData = orderDoc.data()!;
      final items = orderData['items'] as List<dynamic>;

      // Group items by date
      Map<String, List<Map<String, dynamic>>> mealsByDate = {};
      for (var item in items) {
        final date = item['date'] as String;
        if (!mealsByDate.containsKey(date)) {
          mealsByDate[date] = [];
        }
        
        mealsByDate[date]!.add({
          'orderId': orderId,
          'name': item['name'],
          'time': item['mealType'],
          'clock': item['clock'],
          'calories': item['calories'],
          'protein': item['protein'],
          'carbs': item['carbs'],
          'fat': item['fat'],
          'image': item['image'],
          'isDone': false,
        });
      }

      // Save to schedule collection for each date
      // ✅ IMPORTANT: Merge with existing meals, don't overwrite!
      for (var entry in mealsByDate.entries) {
        final date = entry.key;
        final newMeals = entry.value;
        
        final scheduleRef = _db
            .collection('users')
            .doc(uid)
            .collection('schedule')
            .doc(date);

        // Get existing meals first
        final existingDoc = await scheduleRef.get();
        Map<String, Map<String, dynamic>> mealsByType = {};
        
        // Load existing meals and organize by meal type
        if (existingDoc.exists && existingDoc.data()?['meals'] != null) {
          final existingMeals = List<Map<String, dynamic>>.from(
            (existingDoc.data()!['meals'] as List<dynamic>).map((m) => Map<String, dynamic>.from(m))
          );
          
          for (var meal in existingMeals) {
            final mealType = meal['time'] as String? ?? '';
            if (mealType.isNotEmpty) {
              mealsByType[mealType] = meal;
            }
          }
        }
        
        // Add/Replace new meals by type (won't overwrite different meal types)
        for (var newMeal in newMeals) {
          final mealType = newMeal['time'] as String? ?? '';
          if (mealType.isNotEmpty) {
            mealsByType[mealType] = newMeal; // Replace if same type, add if new type
            debugPrint('  📝 Updated $mealType for $date: ${newMeal['name']}');
          }
        }
        
        // Convert back to list and sort by meal type order
        final mealOrder = {'Sarapan': 1, 'Makan Siang': 2, 'Makan Malam': 3};
        final allMeals = mealsByType.values.toList();
        allMeals.sort((a, b) {
          final aOrder = mealOrder[a['time']] ?? 99;
          final bOrder = mealOrder[b['time']] ?? 99;
          return aOrder.compareTo(bOrder);
        });
        
        debugPrint('  ✅ Final meals for $date: ${allMeals.map((m) => m['time']).join(', ')}');
        
        // Save merged and sorted meals
        await scheduleRef.set({
          'meals': allMeals,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('✅ Schedule populated for ${mealsByDate.length} dates from order $orderId');
      return true;
    } catch (e) {
      debugPrint('❌ Error populating schedule: $e');
      return false;
    }
  }

  /// Get meals untuk tanggal tertentu
  static Future<List<Map<String, dynamic>>> getScheduleByDate(DateTime date) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('❌ No user logged in');
        return [];
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      debugPrint('🔍 [ScheduleService] Fetching meals for date: $dateStr, uid: $uid');
      
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .get();

      if (!doc.exists || doc.data()?['meals'] == null) {
        debugPrint('⚠️ [ScheduleService] No schedule document found for $dateStr');
        return [];
      }

      final meals = doc.data()!['meals'] as List<dynamic>;
      debugPrint('✅ [ScheduleService] Found ${meals.length} meals for $dateStr');
      
      // Debug: print meal names and times
      for (var i = 0; i < meals.length; i++) {
        final meal = meals[i];
        debugPrint('   ${i+1}. ${meal['time']}: ${meal['name']}');
      }
      
      return meals.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('❌ Error getting schedule: $e');
      return [];
    }
  }

  /// Mark meal as done/undone
  static Future<bool> markMealAsDone(DateTime date, int mealIndex, bool isDone) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .get();

      if (!doc.exists) return false;

      final meals = List<Map<String, dynamic>>.from(
        (doc.data()!['meals'] as List<dynamic>).map((m) => Map<String, dynamic>.from(m))
      );

      if (mealIndex >= meals.length) return false;

      meals[mealIndex]['isDone'] = isDone;

      await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .update({
        'meals': meals,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Meal marked as ${isDone ? "done" : "undone"}');
      return true;
    } catch (e) {
      debugPrint('❌ Error marking meal: $e');
      return false;
    }
  }

  /// Add single meal to schedule (untuk tambah manual)
  static Future<bool> addMealToSchedule(DateTime date, Map<String, dynamic> mealData) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final scheduleRef = _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr);

      final doc = await scheduleRef.get();
      
      List<Map<String, dynamic>> meals = [];
      if (doc.exists && doc.data()?['meals'] != null) {
        meals = List<Map<String, dynamic>>.from(
          (doc.data()!['meals'] as List<dynamic>).map((m) => Map<String, dynamic>.from(m))
        );
      }

      meals.add(mealData);

      await scheduleRef.set({
        'meals': meals,
        'addedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Meal added to schedule for $dateStr');
      return true;
    } catch (e) {
      debugPrint('❌ Error adding meal to schedule: $e');
      return false;
    }
  }

  /// Remove meal from schedule
  static Future<bool> removeMealFromSchedule(DateTime date, int mealIndex) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .get();

      if (!doc.exists) return false;

      final meals = List<Map<String, dynamic>>.from(
        (doc.data()!['meals'] as List<dynamic>).map((m) => Map<String, dynamic>.from(m))
      );

      if (mealIndex >= meals.length) return false;

      meals.removeAt(mealIndex);

      await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .update({
        'meals': meals,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Meal removed from schedule');
      return true;
    } catch (e) {
      debugPrint('❌ Error removing meal: $e');
      return false;
    }
  }

  /// Get all scheduled dates (untuk calendar view)
  static Future<List<String>> getScheduledDates({int limit = 30}) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error getting scheduled dates: $e');
      return [];
    }
  }

  /// Clear all meals for a specific date
  static Future<bool> clearScheduleForDate(DateTime date) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .delete();

      debugPrint('✅ Cleared all meals for $dateStr');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing schedule: $e');
      return false;
    }
  }
}
