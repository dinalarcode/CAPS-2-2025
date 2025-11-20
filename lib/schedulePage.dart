// 🚀 FULL Revised SchedulePage.dart (Dynamic Menu + Firebase Storage + Date After Today Only)
// Pastikan kamu sudah punya storage_helper.dart dengan buildImageUrl()

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/utils/storage_helper.dart'; // buildImageUrl(fileName)

const Color kGreen = Color(0xFF75C778);
const Color kLightGreyText = Color(0xFF6B6B6B);
const Color kTextColor = Color(0xFF2C2C2C);

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? currentMeal;
  List<Map<String, dynamic>> suggestionMeals = [];

  @override
  void initState() {
    super.initState();
    fetchMeals();
  }

  Future<void> fetchMeals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('schedule')
        .doc(formattedDate)
        .get();

    if (doc.exists) {
      setState(() {
        currentMeal = doc.data()?['currentMeal'];
        suggestionMeals = List<Map<String, dynamic>>.from(doc.data()?['suggestions'] ?? []);
      });
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(), // ⛔ hanya bisa pilih tanggal setelah hari ini
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDate: selectedDate,
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      fetchMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Schedule"),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            datePickerButton(),
            SizedBox(height: 20),
            currentMeal != null ? CurrentMealCard(meal: currentMeal!) : noMealBox(),
            SizedBox(height: 25),
            SuggestedMealsBox(suggestionMeals: suggestionMeals),
          ],
        ),
      ),
    );
  }

  // ===============================
  // 🟡 TOMBOL PILIH TANGGAL
  // ===============================
  Widget datePickerButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('dd MMMM yyyy').format(selectedDate),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
          onPressed: pickDate,
          child: Text("Ganti Tanggal"),
        ),
      ],
    );
  }

  // ===============================
  // 🟥 KOTAK KOSONG JIKA BELUM ADA MENU
  // ===============================
  Widget noMealBox() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        "Belum ada menu untuk tanggal ini",
        style: TextStyle(fontSize: 16, color: kLightGreyText),
      ),
    );
  }
}

// =======================================================
// 🟢 CURRENT MEAL CARD
// =======================================================
class CurrentMealCard extends StatelessWidget {
  final Map<String, dynamic> meal;

  const CurrentMealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: Image.network(
              buildImageUrl(meal['image'] ?? ''),
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal['name'] ?? '-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(children: [
                  macroChip(Icons.monitor_weight_outlined, meal['protein'] ?? '-'),
                  macroChip(Icons.bakery_dining_outlined, meal['carb'] ?? '-'),
                  macroChip(Icons.egg_outlined, meal['fat'] ?? '-'),
                ]),
                SizedBox(height: 8),
                Text(
                  meal['calories'] ?? '-',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextColor),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget macroChip(IconData icon, String data) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Row(children: [Icon(icon, size: 16), SizedBox(width: 4), Text(data)]),
    );
  }
}

// =======================================================
// 🟣 SUGGESTED MEALS LIST
// =======================================================
class SuggestedMealsBox extends StatelessWidget {
  final List<Map<String, dynamic>> suggestionMeals;

  const SuggestedMealsBox({super.key, required this.suggestionMeals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Menu Saran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: suggestionMeals.length,
          itemBuilder: (context, i) => SuggestionMealItem(meal: suggestionMeals[i]),
        ),
      ],
    );
  }
}

// =======================================================
// 🟡 SUGGESTION MEAL ITEM WIDGET
// =======================================================
class SuggestionMealItem extends StatelessWidget {
  final Map<String, dynamic> meal;

  const SuggestionMealItem({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: Image.network(
              buildImageUrl(meal['image'] ?? ''),
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[300],
                child: Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'] ?? 'Unknown Menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      _buildMacro(Icons.monitor_weight_outlined, meal['protein']?.toString() ?? '-'),
                      _buildMacro(Icons.bakery_dining_outlined, meal['carb']?.toString() ?? '-'),
                      _buildMacro(Icons.egg_outlined, meal['fat']?.toString() ?? '-'),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${meal['calories']?.toString() ?? '-'} kkal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, meal);
              },
              child: Text("Pilih"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14),
        SizedBox(width: 3),
        Text(value),
        SizedBox(width: 8),
      ],
    );
  }
}

