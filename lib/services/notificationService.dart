import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize notification service
  static Future<void> initialize() async {
    debugPrint('🔔 Initializing notification service...');

    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('✅ Notification service initialized');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📲 Notification tapped: ${response.payload}');
    // Handle notification action if needed
  }

  /// Schedule meal time notification (15 minutes before)
  static Future<void> scheduleMealNotification({
    required String mealType, // Sarapan, Makan Siang, Makan Malam
    required String mealTime, // "07:00 - 08:00"
    required String mealName, // Menu name
    required int calories,
    required DateTime scheduledDate,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      // Parse meal time to get the start time
      final startTime = _parseStartTime(mealTime);
      if (startTime == null) {
        debugPrint('❌ Could not parse meal time: $mealTime');
        return;
      }

      // Calculate notification time (15 minutes before)
      final notificationDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        startTime.hour,
        startTime.minute,
      ).subtract(const Duration(minutes: 15));

      // Check if notification time is in the future
      if (notificationDateTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Notification time is in the past, skipping');
        return;
      }

      // Check if user has enabled notifications for this meal type
      final isEnabled = await _isMealNotificationEnabled(mealType);
      if (!isEnabled) {
        debugPrint('⚠️ Notifications disabled for $mealType');
        return;
      }

      // Create notification ID (unique per meal per date)
      final notificationId = _generateNotificationId(mealType, scheduledDate);

      // Schedule notification
      final tzDateTime = tz.TZDateTime.from(notificationDateTime, tz.local);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '⏰ Waktu Makan $mealType',
        '15 menit lagi!\n$mealName (~$calories kkal)',
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_notifications',
            'Pengingat Waktu Makan',
            channelDescription: 'Notifikasi pengingat waktu makan',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
          '✅ Meal notification scheduled for $mealType at $notificationDateTime');

      // Save notification schedule to Firestore
      await _saveNotificationSchedule(
        uid,
        mealType,
        notificationId,
        notificationDateTime,
        scheduledDate,
        mealName,
        calories,
      );
    } catch (e) {
      debugPrint('❌ Error scheduling meal notification: $e');
    }
  }

  /// Schedule all meal notifications for a given date
  static Future<void> scheduleAllMealNotifications({
    required DateTime date,
    required List<Map<String, dynamic>> meals,
  }) async {
    try {
      debugPrint(
          '🔔 Scheduling notifications for ${meals.length} meals on $date');

      for (var meal in meals) {
        final mealType = meal['time'] as String?;
        final clock = meal['clock'] as String?;
        final name = meal['name'] as String?;
        final calories = meal['calories'] as int? ?? 0;

        if (mealType != null && clock != null && name != null) {
          await scheduleMealNotification(
            mealType: mealType,
            mealTime: clock,
            mealName: name,
            calories: calories,
            scheduledDate: date,
          );
        }
      }

      debugPrint('✅ All meal notifications scheduled');
    } catch (e) {
      debugPrint('❌ Error scheduling all notifications: $e');
    }
  }

  /// Cancel notification for specific meal
  static Future<void> cancelMealNotification(
    String mealType,
    DateTime date,
  ) async {
    try {
      final notificationId = _generateNotificationId(mealType, date);
      await _flutterLocalNotificationsPlugin.cancel(notificationId);

      debugPrint('✅ Cancelled notification for $mealType on $date');

      // Update Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('notificationSchedules')
            .doc('${date.toIso8601String()}_$mealType')
            .delete();
      }
    } catch (e) {
      debugPrint('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications for a date
  static Future<void> cancelAllNotificationsForDate(DateTime date) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Get all notification schedules for this date
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('notificationSchedules')
          .where('scheduledDate',
              isEqualTo:
                  Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
          .get();

      for (var doc in snapshot.docs) {
        final notificationId = doc.get('notificationId') as int?;
        if (notificationId != null) {
          await _flutterLocalNotificationsPlugin.cancel(notificationId);
        }
      }

      debugPrint('✅ Cancelled all notifications for $date');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Enable/Disable notifications for specific meal type
  static Future<void> setMealNotificationPreference({
    required String mealType, // Sarapan, Makan Siang, Makan Malam
    required bool enabled,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('mealNotifications')
          .update({
        'meal_${mealType.toLowerCase()}': enabled,
      }).catchError((_) async {
        // Create if doesn't exist
        await _db
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('mealNotifications')
            .set({
          'meal_${mealType.toLowerCase()}': enabled,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint(
          '✅ Meal notification preference updated: $mealType = $enabled');
    } catch (e) {
      debugPrint('❌ Error setting notification preference: $e');
    }
  }

  /// Get notification preference for meal type
  static Future<bool> isMealNotificationEnabled(String mealType) async {
    return await _isMealNotificationEnabled(mealType);
  }

  /// Get all notification preferences
  static Future<Map<String, bool>> getAllNotificationPreferences() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        // Default: all enabled when no user
        return {
          'sarapan': true,
          'makan_siang': true,
          'makan_malam': true,
        };
      }

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('mealNotifications')
          .get();

      if (!doc.exists) {
        // Default: all enabled
        return {
          'sarapan': true,
          'makan_siang': true,
          'makan_malam': true,
        };
      }

      final data = doc.data() ?? {};
      return {
        'sarapan': data['meal_sarapan'] ?? true,
        'makan_siang': data['meal_makan_siang'] ?? true,
        'makan_malam': data['meal_makan_malam'] ?? true,
      };
    } catch (e) {
      debugPrint('❌ Error getting notification preferences: $e');
      // Return defaults on error instead of empty map
      return {
        'sarapan': true,
        'makan_siang': true,
        'makan_malam': true,
      };
    }
  }

  /// Send manual notification (test)
  static Future<void> sendTestNotification({
    required String title,
    required String message,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        99, // Unique ID for test
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_notifications',
            'Pengingat Waktu Makan',
            channelDescription: 'Notifikasi pengingat waktu makan',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  // ===== PRIVATE HELPER METHODS =====

  static TimeOfDay? _parseStartTime(String mealTime) {
    try {
      // Parse "07:00 - 08:00" format
      final parts = mealTime.split('-');
      if (parts.isEmpty) return null;

      final startStr = parts[0].trim();
      final timeParts = startStr.split(':');

      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('❌ Error parsing meal time: $e');
      return null;
    }
  }

  static Future<bool> _isMealNotificationEnabled(String mealType) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return true; // Default to enabled

      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('mealNotifications')
          .get();

      if (!doc.exists) return true;

      final key = 'meal_${mealType.toLowerCase()}';
      return doc.get(key) ?? true;
    } catch (e) {
      debugPrint('❌ Error checking notification preference: $e');
      return true;
    }
  }

  static int _generateNotificationId(String mealType, DateTime date) {
    // Generate unique ID based on meal type and date
    final dateStr = DateFormat('yyyyMMdd').format(date);
    final mealCode = mealType.toLowerCase().hashCode;
    return (dateStr + mealCode.toString()).hashCode.abs() % 2147483647;
  }

  static Future<void> _saveNotificationSchedule(
    String uid,
    String mealType,
    int notificationId,
    DateTime notificationDateTime,
    DateTime scheduledDate,
    String mealName,
    int calories,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notificationSchedules')
          .doc('${scheduledDate.toIso8601String()}_$mealType')
          .set({
        'mealType': mealType,
        'notificationId': notificationId,
        'notificationDateTime': Timestamp.fromDate(notificationDateTime),
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'mealName': mealName,
        'calories': calories,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error saving notification schedule: $e');
    }
  }
}
