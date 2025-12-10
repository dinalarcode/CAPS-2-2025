import 'package:flutter_test/flutter_test.dart';

// Kita duplikasi logika _calculateMealTime dari ScheduleService untuk pengujian unit
// karena method aslinya bersifat private (_). 
// Dalam skripsi, ini disebut "White Box Testing - Algorithm Validation".
String calculateMealTimeLogic(String mealType, String wakeTime, String sleepTime) {
  int wakeHour = int.parse(wakeTime.split(':')[0]);
  int wakeMinute = int.parse(wakeTime.split(':')[1]);
  int sleepHour = int.parse(sleepTime.split(':')[0]);
  int sleepMinute = int.parse(sleepTime.split(':')[1]);

  int wakeMinutes = wakeHour * 60 + wakeMinute;
  int sleepMinutes = sleepHour * 60 + sleepMinute;
  if (sleepMinutes < wakeMinutes) sleepMinutes += 24 * 60; 

  final activeHours = (sleepMinutes - wakeMinutes) / 60;

  String formatTime(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final min = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  if (mealType == 'Sarapan') {
    // Logika: 30-60 menit setelah bangun
    final startMinutes = wakeMinutes + 30;
    final endMinutes = wakeMinutes + 60;
    return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
  } else if (mealType == 'Makan Siang') {
    // Logika: Pertengahan jam aktif ± 30 menit
    final midMinutes = wakeMinutes + (activeHours / 2 * 60).round();
    final startMinutes = midMinutes - 30;
    final endMinutes = midMinutes + 30;
    return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
  } else {
    // Logika: 2-3 jam sebelum tidur
    final startMinutes = sleepMinutes - 180; 
    final endMinutes = sleepMinutes - 120; 
    return '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';
  }
}

void main() {
  group('ScheduleService - Dynamic Meal Time Calculation', () {
    // Skenario 1: User Normal (Bangun 06:00, Tidur 22:00)
    test('Calculates Sarapan time correctly based on Wake Time', () {
      // Input: Bangun jam 06:00
      // Harapan: Sarapan jam 06:30 - 07:00
      final result = calculateMealTimeLogic('Sarapan', '06:00', '22:00');
      expect(result, '06:30 - 07:00');
    });

    test('Calculates Makan Malam time correctly based on Sleep Time', () {
      // Input: Tidur jam 22:00
      // Harapan: Makan malam 3 jam s/d 2 jam sebelum tidur (19:00 - 20:00)
      final result = calculateMealTimeLogic('Makan Malam', '06:00', '22:00');
      expect(result, '19:00 - 20:00');
    });

    // Skenario 2: User Begadang (Bangun 10:00, Tidur 02:00 besoknya)
    test('Calculates Schedule correctly for late sleepers', () {
      // Input: Bangun 10:00, Tidur 02:00
      // Harapan Sarapan: 10:30 - 11:00
      final sarapan = calculateMealTimeLogic('Sarapan', '10:00', '02:00');
      expect(sarapan, '10:30 - 11:00');
      
      // Harapan Malam: 23:00 - 00:00 (3 jam sebelum jam 02:00)
      final malam = calculateMealTimeLogic('Makan Malam', '10:00', '02:00');
      expect(malam, '23:00 - 00:00');
    });
  });
}