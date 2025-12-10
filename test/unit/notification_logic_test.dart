import 'package:flutter_test/flutter_test.dart';

// Fungsi logika murni dari NotificationService untuk diuji
DateTime calculateNotificationTime(DateTime scheduledDate, String mealTimeRange) {
  // Parsing logika yang sama dengan service
  // Input misal: "07:00 - 08:00"
  final parts = mealTimeRange.split('-');
  final startStr = parts[0].trim(); // "07:00"
  final timeParts = startStr.split(':');
  
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);

  // Gabungkan tanggal jadwal dengan jam makan
  final mealDateTime = DateTime(
    scheduledDate.year,
    scheduledDate.month,
    scheduledDate.day,
    hour,
    minute,
  );

  // Kurangi 15 menit
  return mealDateTime.subtract(const Duration(minutes: 15));
}

void main() {
  group('Notification Logic Tests', () {
    test('Notification is scheduled exactly 15 minutes before meal start', () {
      // Skenario: Makan Siang jam 12:30
      final mealDate = DateTime(2025, 12, 10); // 10 Des 2025
      final mealRange = "12:30 - 13:30";

      final notifTime = calculateNotificationTime(mealDate, mealRange);

      // Harapan: Notifikasi jam 12:15 pada tanggal yang sama
      expect(notifTime.year, 2025);
      expect(notifTime.month, 12);
      expect(notifTime.day, 10);
      expect(notifTime.hour, 12);
      expect(notifTime.minute, 15);
    });

    test('Notification calculation handles hour rollover correctly', () {
      // Skenario: Sarapan jam 07:05
      // 15 menit sebelumnya harusnya jam 06:50
      final mealDate = DateTime(2025, 12, 10);
      final mealRange = "07:05 - 08:00";

      final notifTime = calculateNotificationTime(mealDate, mealRange);

      expect(notifTime.hour, 6);
      expect(notifTime.minute, 50);
    });
  });
}