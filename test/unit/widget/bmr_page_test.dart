import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilink/features/profile/bmrCalculationPage.dart';

void main() {
  // Data dummy Laki-laki, 80kg, 180cm, 25th -> BMR Mifflin = 1805 kkal
  final mockUserData = {
    'profile': {
      'weightKg': 80,
      'heightCm': 180,
      'sex': 'Laki-laki',
      'birthDate': '2000-01-01 00:00:00',
      'manualBmr': 0,
    }
  };

  testWidgets('BMR Page calculates Mifflin-St Jeor correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(375, 812)),
        child: BmrCalculationPage(userData: mockUserData),
      ),
    ));

    // Validasi: Cari angka 1805 kkal
    // Kita gunakan findsNWidgets(2) karena angka muncul di Header & Detail Rumus
    expect(find.text('1805 kkal'), findsNWidgets(2));
    expect(find.text('Detail Perhitungan BMR'), findsOneWidget);
  });
}