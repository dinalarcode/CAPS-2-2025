import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate unique order ID dengan format: ORD-YYYYMMDD-XXX
  static String _generateOrderId() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final timeStr = DateFormat('HHmmss').format(now);
    return 'ORD-$dateStr-$timeStr';
  }

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

  /// Create order baru di Firestore
  /// Returns orderId jika berhasil, null jika gagal
  static Future<String?> createOrder({
    required Map<String, Map<String, dynamic>> cartItems,
    required num totalPrice,
    String paymentMethod = 'pending',
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final orderId = _generateOrderId();
      
      // Fetch user's sleep schedule for clock calculation
      String wakeTime = '06:00';
      String sleepTime = '22:00';
      try {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final sleepSchedule = data?['sleepSchedule'] as Map<String, dynamic>?;
          wakeTime = sleepSchedule?['wakeTime'] as String? ?? '06:00';
          sleepTime = sleepSchedule?['sleepTime'] as String? ?? '22:00';
          debugPrint('⏰ [ORDER] User sleep schedule: wake=$wakeTime, sleep=$sleepTime');
        }
      } catch (e) {
        debugPrint('⚠️ [ORDER] Could not fetch sleep schedule, using defaults: $e');
      }
      
      // Convert cart items to order items array
      List<Map<String, dynamic>> orderItems = [];
      cartItems.forEach((dateKey, meals) {
        meals.forEach((mealType, itemData) {
          // Calculate clock time for this meal type
          final calculatedClock = _calculateMealTime(mealType, wakeTime, sleepTime);
          
          final orderItem = {
            'date': dateKey,
            'mealType': mealType,
            'menuData': itemData,
            'price': itemData['price'] ?? 0,
            'name': itemData['name'] ?? '',
            'calories': itemData['calories'] ?? 0,
            // Map carbohydrate → carbs for consistency
            'protein': itemData['protein'] ?? 0,
            'carbs': itemData['carbs'] ?? itemData['carbohydrate'] ?? 0,
            'fat': itemData['fat'] ?? 0,
            'image': itemData['image'] ?? '',
            'clock': calculatedClock, // Use calculated time instead of empty string
          };
          
          debugPrint('📦 [ORDER] Adding item: ${orderItem['name']} - ${orderItem['mealType']} at $calculatedClock');
          orderItems.add(orderItem);
        });
      });

      // Create order document
      await _db.collection('users').doc(uid).collection('orders').doc(orderId).set({
        'orderId': orderId,
        'status': 'pending', // pending, paid, preparing, delivered, cancelled
        'totalPrice': totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'items': orderItems,
      });

      debugPrint('✅ Order created: $orderId with ${orderItems.length} items');
      return orderId;
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      return null;
    }
  }

  /// Get all orders untuk user saat ini
  static Future<List<Map<String, dynamic>>> getOrders({
    int limit = 20,
    String? status,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      Query query = _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('❌ Error getting orders: $e');
      return [];
    }
  }

  /// Get single order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(orderId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('❌ Error getting order: $e');
      return null;
    }
  }

  /// Update order status (e.g., dari pending ke paid)
  static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Order $orderId status updated to $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      return false;
    }
  }

  /// Cancel order
  static Future<bool> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'cancelled');
  }

  /// Mark order as paid dan populate schedule
  static Future<bool> markOrderAsPaid(String orderId) async {
    try {
      final success = await updateOrderStatus(orderId, 'paid');
      if (!success) return false;

      // Import schedule service untuk populate schedule
      final order = await getOrderById(orderId);
      if (order != null && order['items'] != null) {
        // Populate schedule akan dilakukan di schedule_service
        debugPrint('✅ Order marked as paid, ready for schedule population');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error marking order as paid: $e');
      return false;
    }
  }

  /// Delete order (admin only / testing purpose)
  static Future<bool> deleteOrder(String orderId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .doc(orderId)
          .delete();

      debugPrint('✅ Order $orderId deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting order: $e');
      return false;
    }
  }

  /// Check if user has ordered for specific date and meal types
  /// Returns `Map<String, bool>` with meal types as keys (e.g., {"Sarapan": true, "Makan Siang": false})
  static Future<Map<String, bool>> checkOrderedMeals(DateTime date) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return {};

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // Query orders yang statusnya paid atau lebih tinggi
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('orders')
          .where('status', whereIn: ['paid', 'preparing', 'delivered'])
          .get();

      final orderedMeals = <String, bool>{
        'Sarapan': false,
        'Makan Siang': false,
        'Makan Malam': false,
      };

      for (var doc in snapshot.docs) {
        final orderData = doc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];
        
        for (var item in items) {
          final itemDate = item['date'] as String?;
          final mealType = item['mealType'] as String?;
          
          if (itemDate == dateStr && mealType != null) {
            orderedMeals[mealType] = true;
          }
        }
      }

      debugPrint('📋 Ordered meals for $dateStr: $orderedMeals');
      return orderedMeals;
    } catch (e) {
      debugPrint('❌ Error checking ordered meals: $e');
      return {};
    }
  }
}
