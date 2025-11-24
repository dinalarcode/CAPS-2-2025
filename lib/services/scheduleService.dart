import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ScheduleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calculate meal time based on user's sleep schedule
  static String _calculateMealTime(String mealType, String wakeTime, String sleepTime) {
    try {
      int wakeHour = int.parse(wakeTime.split(':')[0]);
      int wakeMinute = int.parse(wakeTime.split(':')[1]);
      int sleepHour = int.parse(sleepTime.split(':')[0]);
      int sleepMinute = int.parse(sleepTime.split(':')[1]);

      int wakeMinutes = wakeHour * 60 + wakeMinute;
      int sleepMinutes = sleepHour * 60 + sleepMinute;
      if (sleepMinutes < wakeMinutes) sleepMinutes += 24 * 60; // Next day

      final activeHours = (sleepMinutes - wakeMinutes) / 60;

      String formatTime(int minutes) {
        final hour = (minutes ~/ 60) % 24;
        final min = minutes % 60;
        return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
      }

      if (mealType == 'Sarapan') {
        // 30-60 menit setelah bangun
        final startMinutes = wakeMinutes + 30;
        final endMinutes = wakeMinutes + 60;
        return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
      } else if (mealType == 'Makan Siang') {
        // Pertengahan jam aktif ± 30 menit
        final midMinutes = wakeMinutes + (activeHours / 2 * 60).round();
        final startMinutes = midMinutes - 30;
        final endMinutes = midMinutes + 30;
        return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
      } else {
        // 2-3 jam sebelum tidur
        final startMinutes = sleepMinutes - 180; // 3 jam sebelum
        final endMinutes = sleepMinutes - 120;  // 2 jam sebelum
        return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
      }
    } catch (e) {
      // Fallback jika parsing gagal
      return mealType == 'Sarapan' ? '07:00 - 08:00' : 
            mealType == 'Makan Siang' ? '12:00 - 13:00' : '18:00 - 19:00';
    }
  }

  /// Populate schedule dari order yang sudah dibayar
  static Future<bool> populateScheduleFromOrder(String orderId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      // Get user's sleep schedule
      final userDoc = await _db.collection('users').doc(uid).get();
      String wakeTime = '06:00';
      String sleepTime = '22:00';
      
      if (userDoc.exists && userDoc.data()?['sleepSchedule'] != null) {
        final sleepSchedule = userDoc.data()!['sleepSchedule'] as Map<String, dynamic>;
        wakeTime = sleepSchedule['wakeTime'] ?? '06:00';
        sleepTime = sleepSchedule['sleepTime'] ?? '22:00';
        debugPrint('👤 [SCHEDULE] User sleep schedule: Wake=$wakeTime Sleep=$sleepTime');
      } else {
        debugPrint('⚠️ [SCHEDULE] No sleep schedule found, using defaults');
      }

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
        
        // Get nutritional data from item or fallback to menuData
        final menuData = item['menuData'] as Map<String, dynamic>?;
        final protein = item['protein'] ?? menuData?['protein'] ?? 0;
        final carbs = item['carbs'] ?? item['carbohydrate'] ?? menuData?['carbs'] ?? menuData?['carbohydrate'] ?? 0;
        final fat = item['fat'] ?? menuData?['fat'] ?? 0;
        final mealType = item['mealType'] as String;
        
        // Calculate clock time based on meal type and sleep schedule
        final calculatedClock = _calculateMealTime(mealType, wakeTime, sleepTime);
        
        debugPrint('📊 [SCHEDULE] Item: ${item['name']} - Type:$mealType Clock:$calculatedClock P:$protein C:$carbs F:$fat');
        
        mealsByDate[date]!.add({
          'orderId': orderId,
          'name': item['name'],
          'time': mealType,
          'clock': calculatedClock, // Use calculated clock instead of stored value
          'calories': item['calories'],
          'protein': protein,
          // Store both for compatibility
          'carbs': carbs,
          'carbohydrate': carbs,
          'fat': fat,
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
      
      // Validate each meal's orderId still exists
      final validMeals = <Map<String, dynamic>>[];
      
      for (var i = 0; i < meals.length; i++) {
        final meal = Map<String, dynamic>.from(meals[i]);
        final orderId = meal['orderId'] as String?;
        
        if (orderId == null || orderId.isEmpty) {
          debugPrint('   ⚠️ ${i+1}. ${meal['time']}: ${meal['name']} - No orderId, skipping');
          continue;
        }
        
        // Check if order still exists
        final orderDoc = await _db
            .collection('users')
            .doc(uid)
            .collection('orders')
            .doc(orderId)
            .get();
        
        if (!orderDoc.exists) {
          debugPrint('   ❌ ${i+1}. ${meal['time']}: ${meal['name']} - Order $orderId not found, skipping');
          continue;
        }
        
        debugPrint('   ✅ ${i+1}. ${meal['time']}: ${meal['name']} - Valid order');
        validMeals.add(meal);
      }
      
      debugPrint('🔍 [ScheduleService] Validated ${validMeals.length}/${meals.length} meals');
      
      // If some meals were filtered out, update the document to remove invalid entries
      if (validMeals.length < meals.length) {
        debugPrint('🧹 [ScheduleService] Cleaning up ${meals.length - validMeals.length} invalid meals from schedule');
        await _db
            .collection('users')
            .doc(uid)
            .collection('schedule')
            .doc(dateStr)
            .update({'meals': validMeals});
      }
      
      return validMeals;
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

  /// Re-populate all schedules from all existing orders
  /// Useful for fixing nutritional data after schema changes
  static Future<bool> repopulateAllSchedules() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('❌ No user logged in');
        return false;
      }

      debugPrint('🔄 [SCHEDULE] Starting re-population of all schedules...');

      // Get all orders
      final ordersSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        debugPrint('⚠️ [SCHEDULE] No orders found to re-populate');
        return true;
      }

      int successCount = 0;
      int failCount = 0;

      // Re-populate from each order
      for (var orderDoc in ordersSnapshot.docs) {
        final orderId = orderDoc.id;
        debugPrint('  📦 Re-populating from order: $orderId');
        
        final success = await populateScheduleFromOrder(orderId);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      debugPrint('✅ [SCHEDULE] Re-population complete: $successCount succeeded, $failCount failed');
      return failCount == 0;
    } catch (e) {
      debugPrint('❌ Error re-populating schedules: $e');
      return false;
    }
  }
}
