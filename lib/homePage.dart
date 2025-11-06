import 'package:flutter/material.dart';

const Color kBackgroundColor = Colors.white;
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50);
const Color kAccentRed = Color(0xFFF44336);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: CircleAvatar(backgroundColor: kAccentRed),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('John Cena', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 2),
            Text('2384 kcal/day (1130 kcal)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('77,0 kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Target: 65,0 kg (+12,0 kg)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Lokasi: Surabaya, Jawa Timur',
                    style: TextStyle(color: kAccentGreen, fontSize: 13)),
              ),
            ),
            SizedBox(height: 15),
            BmiSection(),
            SizedBox(height: 25),
            _Header(title: 'Statistik Harian'),
            SizedBox(height: 15),
            DailyStatsRow(),
            SizedBox(height: 30),
            MealCardsSection(),
            SizedBox(height: 30),
            _Header(title: 'Upcoming Meals'),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor)),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class BmiSection extends StatelessWidget {
  const BmiSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('26,6', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: kTextColor)),
              SizedBox(width: 5),
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('IMT saat ini', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, kAccentGreen, Colors.orangeAccent, kAccentRed],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.55,
                  top: 0, bottom: 0,
                  child: Container(width: 4, color: kTextColor),
                ),
                const Positioned(left: 4, top: 2, child: Text('Underweight', style: TextStyle(fontSize: 10, color: Colors.white))),
                const Positioned(left: 100, top: 2, child: Text('Normal', style: TextStyle(fontSize: 10, color: Colors.white))),
                const Positioned(right: 50, top: 2, child: Text('Obese', style: TextStyle(fontSize: 10, color: Colors.white))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Berat badan sedikit melebihi ideal, berpotensi meningkatkan risiko gangguan metabolik jika tidak dikontrol.',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class DailyStatsRow extends StatelessWidget {
  const DailyStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String value, String delta, {bool danger = false}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextColor)),
              if (delta.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 10,
                    color: danger ? kAccentRed : kAccentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          card('Makan', '2/3 kali', ''),
          const SizedBox(width: 10),
          card('Kalori', '1130 kcal', '+680 kcal', danger: true),
          const SizedBox(width: 10),
          card('Pengeluaran', 'Rp 82.000', '+Rp 42.000'),
        ],
      ),
    );
  }
}

class MealCardsSection extends StatelessWidget {
  const MealCardsSection({super.key});

  final List<Map<String, String>> meals = const [
    {'time': 'Sarapan', 'name': 'Caesar Salad', 'tag': 'Sayuran', 'calories': '450 kcal', 'price': 'Rp 40.000'},
    {'time': 'Makan Siang', 'name': 'Udang Saos Tiram', 'tag': 'Udang', 'calories': '510 kcal', 'price': 'Rp 42.000'},
    {'time': 'Makan Malam', 'name': 'Sandwich Ayam', 'tag': 'Ayam', 'calories': '430 kcal', 'price': 'Rp 35.000'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Rekomendasi Menu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: meals.length,
            itemBuilder: (context, i) => _MealCard(meal: meals[i]),
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, String> meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meal['time']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // placeholder image
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Center(
                        child: Text('Image of ${meal['name']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: kTextColor)),
                      ),
                    ),
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: kAccentGreen.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
                        child: Text(meal['tag']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Text(meal['calories']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(height: 15),
                      Text(meal['price']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextColor)),
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

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kAccentGreen,
      unselectedItemColor: Colors.grey,
      currentIndex: 2,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Meal'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
