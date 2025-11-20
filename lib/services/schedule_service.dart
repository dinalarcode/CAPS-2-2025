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
      final batch = _db.batch();
      mealsByDate.forEach((date, meals) {
        final scheduleRef = _db
            .collection('users')
            .doc(uid)
            .collection('schedule')
            .doc(date);

        batch.set(scheduleRef, {
          'meals': meals,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      await batch.commit();
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
      if (uid == null) return [];

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('schedule')
          .doc(dateStr)
          .get();

      if (!doc.exists || doc.data()?['meals'] == null) {
        return [];
      }

      final meals = doc.data()!['meals'] as List<dynamic>;
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
}
