// lib/models/meal_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MealModel {
  final String id;
  final String name;
  final int calories;
  final String imageUrl;
  final List<String> ingredients;

  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.imageUrl,
    required this.ingredients,
  });

  factory MealModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealModel(
      id: doc.id,
      name: data['name'] ?? '',
      calories: data['calories'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
    );
  }
}
