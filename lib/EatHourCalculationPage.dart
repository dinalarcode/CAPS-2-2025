import 'package:flutter/material.dart';
import 'constants.dart';
import 'NutritionCalculation_ProfileRecap.dart';

class EatHourCalculationPage extends StatelessWidget {
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  final int mealsPerDay;

  const EatHourCalculationPage({
    super.key,
    this.wakeTime = const TimeOfDay(hour: 6, minute: 0),
    this.bedTime = const TimeOfDay(hour: 22, minute: 0),
    this.mealsPerDay = 3,
  });

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildTimeCard(String title, String time, {Color? highlightColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlightColor?.withOpacity(0.1) ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightColor?.withOpacity(0.3) ?? Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: highlightColor ?? Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              color: highlightColor ?? kAccentGreen,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate active hours
    final activeHours = (bedTime.hour - wakeTime.hour + 24) % 24;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back),
                        color: kAccentGreen,
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Kembali',
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/images/NutriLinkLogo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Perhitungan Jam Makan',
                        style: TextStyle(
                          color: kAccentGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Wake & Sleep Times
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeCard(
                                  'Jam Bangun',
                                  _formatTimeOfDay(wakeTime),
                                  highlightColor: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeCard(
                                  'Jam Tidur',
                                  _formatTimeOfDay(bedTime),
                                  highlightColor: Colors.indigo,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Active Hours
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kAccentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: kAccentGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jam Aktif',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '$activeHours jam',
                                      style: TextStyle(
                                        color: kAccentGreen,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Meal Schedule
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: kAccentGreen.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.restaurant, color: kAccentGreen),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Jadwal Makan ($mealsPerDay kali sehari)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildMealTime(
                                  'Sarapan',
                                  '06:30 - 07:00',
                                  'Ideal: 30 menit - 1 jam setelah bangun',
                                ),
                                _buildMealTime(
                                  'Makan Siang',
                                  '14:00',
                                  'Tengah hari aktif',
                                ),
                                _buildMealTime(
                                  'Makan Malam',
                                  '19:00 - 20:00',
                                  '2-3 jam sebelum tidur',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Navigation Buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NutritionRecapPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Kembali',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTime(String meal, String time, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kAccentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.schedule, color: kAccentGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: kAccentGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
