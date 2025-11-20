// lib/detailMenuPage.dart
import 'package:flutter/material.dart';
import 'utils/storage_helper.dart'; // <-- for buildImageUrl()

const Color kGreen = Color(0xFF75C778);
const Color kLightGreyText = Color(0xFF9E9E9E);

class DetailMenuPage extends StatelessWidget {
  final Map meal;

  const DetailMenuPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final String imageFile =
        meal["imageFileName"] ?? meal["image"] ?? meal["imageUrl"] ?? "";
    final String imageUrl = imageFile.isEmpty ? "" : buildImageUrl(imageFile);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          meal["name"] ?? "Detail Menu",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 Image Section
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              meal["name"] ?? "No Name",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            if ((meal["description"] ?? "").toString().isNotEmpty)
              Text(
                meal["description"],
                style: const TextStyle(
                  fontSize: 15,
                  color: kLightGreyText,
                  height: 1.4,
                ),
              ),

            const SizedBox(height: 25),

            const Text(
              "Nutrition Facts",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _buildNutritionCard(meal),

            const SizedBox(height: 35),

            // Button Edit Menu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/editMenu", arguments: meal);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Edit Menu",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  //
  // ░░░ IMAGE PLACEHOLDER ░░░
  //
  Widget _placeholderImage() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.restaurant,
        size: 80,
        color: Colors.grey[400],
      ),
    );
  }

  //
  // ░░░ NUTRITION SECTION ░░░
  //
  Widget _buildNutritionCard(Map meal) {
    final calories = meal["calories"] ?? meal["kalori"] ?? "-";
    final carbs = meal["carbs"] ?? meal["karbohidrat"] ?? "-";
    final protein = meal["protein"] ?? meal["protein_g"] ?? "-";
    final fat = meal["fat"] ?? meal["lemak"] ?? "-";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildNutriRow("Calories", "$calories kcal"),
          _divider(),
          _buildNutriRow("Carbs", "$carbs g"),
          _divider(),
          _buildNutriRow("Protein", "$protein g"),
          _divider(),
          _buildNutriRow("Fat", "$fat g"),
        ],
      ),
    );
  }

  Widget _buildNutriRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 20,
      thickness: 1,
      color: Colors.grey[300],
    );
  }
}
