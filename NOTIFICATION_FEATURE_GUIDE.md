# Notification System Implementation Guide

## Overview
A complete notification system has been implemented for the CAPS-2-2025 app to send meal time reminders to users 15 minutes before their scheduled meals.

## Features Implemented

### ✅ FR-4: Send Notifications 15 Minutes Before Meal Time
- Notifications are automatically scheduled 15 minutes before each meal
- Support for all meal types: Sarapan (Breakfast), Makan Siang (Lunch), Makan Malam (Dinner)
- Notifications include meal type, name, and calorie information
- Timezone support for accurate scheduling

### ✅ FR-5: Enable/Disable Notifications Per Meal Type
- Users can toggle notifications for individual meal types
- Preferences are stored in Firestore under `users/{uid}/settings/mealNotifications`
- Each meal type can be independently controlled:
  - `meal_sarapan` (Breakfast notifications)
  - `meal_makan_siang` (Lunch notifications)
  - `meal_makan_malam` (Dinner notifications)

### ✅ FR-6: Show Meal Summary in Notifications
- Notifications display:
  - Meal type (e.g., "⏰ Waktu Makan Sarapan")
  - Message with countdown and meal details (e.g., "15 menit lagi! Nasi Goreng (~450 kkal)")
  - Calorie information

## File Structure

### Core Services
- **`lib/services/notificationService.dart`** - Main notification service with scheduling logic

### User Interface
- **`lib/features/settings/notificationSettingsPage.dart`** - Notification preferences UI
- **`lib/features/profile/profilePage.dart`** - Added default avatar functionality
- **`lib/features/profile/uploadProfilePicturePage.dart`** - Profile picture management

### Configuration
- **`lib/main.dart`** - Initializes NotificationService on app startup
- **`pubspec.yaml`** - Updated dependencies

## Key Classes and Methods

### NotificationService

#### Public Methods

```dart
// Initialize the notification service (called in main.dart)
static Future<void> initialize()

// Schedule a single meal notification
static Future<void> scheduleMealNotification({
  required String mealType,
  required String mealTime,
  required String mealName,
  required int calories,
  required DateTime scheduledDate,
})

// Schedule all notifications for a date
static Future<void> scheduleAllMealNotifications({
  required DateTime date,
  required List<Map<String, dynamic>> meals,
})

// Cancel notification for a meal
static Future<void> cancelMealNotification(String mealType, DateTime date)

// Cancel all notifications for a date
static Future<void> cancelAllNotificationsForDate(DateTime date)

// Set notification preference for meal type
static Future<void> setMealNotificationPreference({
  required String mealType,
  required bool enabled,
})

// Get all notification preferences
static Future<Map<String, bool>> getAllNotificationPreferences()

// Send test notification
static Future<void> sendTestNotification({
  required String title,
  required String message,
})
```

## Usage Examples

### 1. Initialize Notifications (Already done in main.dart)
```dart
await NotificationService.initialize();
```

### 2. Schedule Notifications for a Specific Date
```dart
final meals = [
  {
    'time': 'Sarapan',
    'clock': '07:00 - 08:00',
    'name': 'Nasi Goreng',
    'calories': 450,
  },
  {
    'time': 'Makan Siang',
    'clock': '12:00 - 13:00',
    'name': 'Gado-Gado',
    'calories': 350,
  },
];

await NotificationService.scheduleAllMealNotifications(
  date: tomorrow,
  meals: meals,
);
```

### 3. Toggle Notification for Meal Type
```dart
// Enable breakfast notifications
await NotificationService.setMealNotificationPreference(
  mealType: 'Sarapan',
  enabled: true,
);

// Disable dinner notifications
await NotificationService.setMealNotificationPreference(
  mealType: 'Makan Malam',
  enabled: false,
);
```

### 4. Check Notification Settings
```dart
final preferences = await NotificationService.getAllNotificationPreferences();
print(preferences); 
// Output: {sarapan: true, makan_siang: false, makan_malam: true}
```

### 5. Send Test Notification
```dart
await NotificationService.sendTestNotification(
  title: 'Test Notification',
  message: 'This is a test message',
);
```

## Firestore Schema

### Notification Preferences
```
users/{uid}/settings/mealNotifications/
{
  "meal_sarapan": true,
  "meal_makan_siang": true,
  "meal_makan_malam": false,
  "createdAt": Timestamp
}
```

### Notification Schedules
```
users/{uid}/notificationSchedules/{date}_{mealType}/
{
  "mealType": "Sarapan",
  "notificationId": 123456789,
  "notificationDateTime": Timestamp,
  "scheduledDate": Timestamp,
  "mealName": "Nasi Goreng",
  "calories": 450,
  "createdAt": Timestamp
}
```

## Dependencies Added

```yaml
flutter_local_notifications: ^17.1.2
timezone: ^0.9.4
```

## Platform-Specific Configuration

### Android Setup
- Min SDK: 21
- Notifications use the app's launcher icon
- Channel ID: `meal_notifications`
- Channel Name: `Pengingat Waktu Makan`

### iOS Setup
- Notifications require user permission
- Sound, badge, and alert permissions are requested

## Navigation Integration

To add notification settings to the profile page:

```dart
import 'package:nutrilink/features/settings/notificationSettingsPage.dart';

// Add to profile menu
_buildMenuButton(
  context,
  icon: Icons.notifications_outlined,
  title: 'Pengaturan Notifikasi',
  subtitle: 'Atur notifikasi waktu makan',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsPage(),
      ),
    );
  },
)
```

## Testing

### Test Notification
Use the test button in Notification Settings page to send a test notification:
```
Title: ⏰ Tes Notifikasi
Message: Ini adalah notifikasi ujicoba dari NutriLink
```

### Manual Testing
1. Schedule a meal notification
2. Wait for the notification trigger time
3. Check device notification panel
4. Tap notification to verify it's working

## Troubleshooting

### Notifications Not Appearing
1. Check if notifications are enabled in app settings
2. Verify meal time format is correct: "HH:MM - HH:MM"
3. Ensure notification time is in the future
4. Check device notification settings

### Preferences Not Saving
1. Verify user is logged in
2. Check Firebase connection
3. Ensure Firestore rules allow write access
4. Check console for error messages

## Future Enhancements

1. **Custom Sound Selection** - Allow users to choose notification sounds
2. **Notification Delay** - Let users customize notification time (10, 15, 20 minutes)
3. **Quiet Hours** - Set do-not-disturb periods
4. **Sound on/off Toggle** - Global sound control
5. **Notification History** - Track sent notifications
6. **Push Notifications** - Firebase Cloud Messaging integration

## API Reference

For complete API documentation, see `lib/services/notificationService.dart`

---

**Last Updated:** November 27, 2025
**Version:** 1.0
