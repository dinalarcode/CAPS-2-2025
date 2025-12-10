// File: test/unit/user_profile_test.dart

import 'package:flutter_test/flutter_test.dart';
// GANTI 'nutrilink' DENGAN NAMA PACKAGE PROYEKMU (cek di pubspec.yaml bagian name:)
import 'package:nutrilink/models/userProfileDraft.dart'; 

void main() {
  group('UserProfileDraft Model Tests', () {
    // Test Case 1: Memastikan inisialisasi awal list kosong
    test('Initial properties should be null or empty', () {
      final profile = UserProfileDraft();
      expect(profile.name, isNull);
      expect(profile.challenges, isEmpty);
      expect(profile.allergies, isEmpty);
    });

    // Test Case 2: Memastikan fungsi copy() bekerja (Deep Copy)
    test('copy() method creates a distinct instance with same data', () {
      final original = UserProfileDraft();
      original.name = "Iqbal";
      original.weightKg = 70.0;
      original.allergies.add("Shrimp");

      final copy = original.copy();

      // Pastikan data sama
      expect(copy.name, "Iqbal");
      expect(copy.weightKg, 70.0);
      expect(copy.allergies, contains("Shrimp"));

      // Pastikan instance berbeda (tidak merujuk ke memori yang sama)
      expect(identical(original, copy), isFalse);
      
      // Pastikan list juga terpisah (bukan referensi)
      copy.allergies.add("Peanut");
      expect(original.allergies.length, 1); // Original tidak boleh berubah
      expect(copy.allergies.length, 2);
    });
  });
}