import 'package:flutter/material.dart';

// --- Constants (for illustrative purposes) ---
const Color kPrimaryColor = Color(0xFF54D3C5); // Example color for highlights/icons
const Color kBackgroundColor = Colors.white;
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kAccentRed = Color(0xFFF44336);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App UI',
      theme: ThemeData(
        primarySwatch: Colors.green, // Can be customized further
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          foregroundColor: kTextColor,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: The prototype uses a custom, non-standard system status bar.
    // In Flutter, you usually let the system handle this or use the
    // AnnotatedRegion<SystemUiOverlayStyle> for deep customization.
    return Scaffold(
      // 1. App Bar (Profile and Weight Info)
      appBar: AppBar(
        // Leading: Profile Icon/Avatar
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: CircleAvatar(
            backgroundColor: kAccentRed, // Placeholder for the avatar background
            // child: Icon(Icons.person, color: Colors.white), // Placeholder for image
            // You would use an Image.asset or NetworkImage here
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'John Cena',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '2384 kcal/day (1130 kcal)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        // Actions: Current Weight, Target Weight
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  '77,0 kg',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Target: 65,0 kg (+12,0 kg)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
        // The prototype seems to use a custom app bar or a body that starts high.
        // For simplicity, we use a standard AppBar and put the rest in the body.
      ),
      
      // 2. Body Content (Scrollable)
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Location
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Lokasi: Surabaya, Jawa Timur',
                  style: TextStyle(color: kAccentGreen, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // BMI Section (IMT)
            const BmiSection(),
            const SizedBox(height: 25),

            // Daily Stats Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Statistik Harian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 15),
            
            // Daily Stats Cards
            const DailyStatsRow(),
            const SizedBox(height: 30),

            // Meal Cards (Horizontal Scroll)
            const MealCardsSection(),
            const SizedBox(height: 30),

            // Upcoming Meals Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Upcoming Meals',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
            // (A list of upcoming meals would go here)
          ],
        ),
      ),

      // 3. Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

// --- Component 1: BMI/IMT Section ---
class BmiSection extends StatelessWidget {
  const BmiSection({super.key});

  @override
  Widget build(BuildContext context) {
    // This part is simplified. A real implementation would use a
    // custom painter or a package like 'sleek_circular_slider' for the gauge.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '26,6',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'IMT saat ini',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Placeholder for the progress bar/gauge
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade200, // Underweight
                  kAccentGreen, // Normal
                  Colors.orange.shade400, // Overweight
                  kAccentRed, // Obese
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Current BMI Marker (26.6 is in the Overweight section)
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.55, // Approximate position for 26.6
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: kTextColor,
                  ),
                ),
                // Text labels (Simplified)
                const Positioned(left: 0, child: Text('Underweight', style: TextStyle(fontSize: 10, color: Colors.white))),
                const Positioned(left: 100, child: Text('Normal', style: TextStyle(fontSize: 10, color: Colors.white))),
                const Positioned(right: 50, child: Text('Obese', style: TextStyle(fontSize: 10, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Description text
          Text(
            'Berat badan sedikit melebihi ideal, berpotensi meningkatkan risiko gangguan metabolik jika tidak dikontrol.',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// --- Component 2: Daily Stats Row ---
class DailyStatsRow extends StatelessWidget {
  const DailyStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          // Stat Card 1: Makan
          Expanded(
            child: StatCard(
              title: 'Makan',
              value: '2/3 kali',
              delta: '',
            ),
          ),
          SizedBox(width: 10),
          // Stat Card 2: Kalori
          Expanded(
            child: StatCard(
              title: 'Kalori',
              value: '1130 kcal',
              delta: '+680 kcal',
            ),
          ),
          SizedBox(width: 10),
          // Stat Card 3: Pengeluaran
          Expanded(
            child: StatCard(
              title: 'Pengeluaran',
              value: 'Rp 82.000',
              delta: '+Rp 42.000',
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String delta;

  const StatCard({
    required this.title,
    required this.value,
    required this.delta,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          if (delta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              delta,
              style: TextStyle(
                fontSize: 10,
                color: title == 'Kalori' ? kAccentRed : kAccentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Component 3: Meal Cards Section (Horizontal Scroll) ---
class MealCardsSection extends StatelessWidget {
  const MealCardsSection({super.key});

  // Dummy data for the meals
  final List<Map<String, dynamic>> meals = const [
    {
      'time': 'Sarapan',
      'name': 'Caesar Salad',
      'tag': 'Sayuran',
      'calories': '450 kcal',
      'price': 'Rp 40.000',
      'imagePath': 'assets/caesar_salad.png', // Placeholder
    },
    {
      'time': 'Makan Siang',
      'name': 'Udang Saos Tiram',
      'tag': 'Udang',
      'calories': '510 kcal',
      'price': 'Rp 42.000',
      'imagePath': 'assets/udang_saos_tiram.png', // Placeholder
    },
    {
      'time': 'Makan Malam',
      'name': 'Sandwich Ayam',
      'tag': 'Ayam',
      'calories': '430 kcal',
      'price': 'Rp 35.000',
      'imagePath': 'assets/sandwich_ayam.png', // Placeholder
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Rekomendasi Menu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 300, // Adjust height based on card size
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              final meal = meals[index];
              return MealCard(meal: meal);
            },
          ),
        ),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealCard({required this.meal, super.key});

  @override
  Widget build(BuildContext context) {
    // A simplified Card to represent the meal item
    return Container(
      width: 150, // Fixed width as per prototype style
      margin: const EdgeInsets.only(right: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Time Label
          Text(
            meal['time'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          // The main Card/Container with Image and Details
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Placeholder
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300], // Placeholder background
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        // Use DecorationImage for the actual image
                        // image: DecorationImage(image: AssetImage(meal['imagePath']), fit: BoxFit.cover),
                      ),
                      // For a real app, replace this with a real image widget
                      child: Center(
                        child: Text(
                          'Image of ${meal['name']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: kTextColor),
                        ),
                      ),
                    ),
                    // Tag/Chip
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kAccentGreen.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meal['tag'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        meal['calories'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(height: 15),
                      Text(
                        meal['price'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: kTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Component 4: Custom Bottom Navigation Bar ---
class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // To show all items
      selectedItemColor: kAccentGreen, // Highlight color for the active item
      unselectedItemColor: Colors.grey,
      currentIndex: 2, // 'Home' is the active item
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Meal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home', // Active item
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Report',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}