import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilink/pages/auth/loginPage.dart'; // Pastikan path ini sesuai

void main() {
  testWidgets('Login Page UI Elements Render Correctly', (WidgetTester tester) async {
    // 1. Render Halaman Login
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // 2. Verifikasi Elemen Email
    // "Email" hanya muncul 1 kali sebagai Label (Hint-nya adalah "contoh@email.com")
    expect(find.text('Email'), findsOneWidget);

    // 3. Verifikasi Elemen Password (PERBAIKAN DISINI)
    // "Password" muncul 2 kali: sebagai Label dan sebagai Hint Text
    expect(find.text('Password'), findsNWidgets(2));

    // 4. Verifikasi Input Field
    // Harus ada 2 kotak input (Email & Password)
    expect(find.byType(TextFormField), findsNWidgets(2));

    // 5. Verifikasi Tombol Masuk
    expect(find.text('Masuk'), findsOneWidget);
  });
}