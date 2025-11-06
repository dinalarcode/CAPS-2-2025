import 'package:flutter/material.dart';
import 'package:nutrilink/navbar.dart';
// Ganti import ini menjadi impor file yang mendefinisikan SchedulePage yang asli
import 'package:nutrilink/schedulePage.dart';

// --- Constants ---
const Color kPrimaryColor = Color(0xFF54D3C5); 
const Color kBackgroundColor = Colors.white;
const Color kTextColor = Colors.black;
const Color kAccentGreen = Color(0xFF4CAF50); // Hijau untuk highlight
const Color kAccentRed = Color(0xFFF44336); // Merah untuk delta negatif/avatar

// Untuk menghindari error, kita harus mendefinisikan semua halaman yang dipanggil di _pages.


class MealPage extends StatelessWidget {
  const MealPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Halaman Meal (Index 2)'));
}

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Halaman Report (Index 3)'));
}
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Halaman Profile (Index 4)'));
}

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
        primarySwatch: Colors.teal, // Menggunakan teal yang mendekati kPrimaryColor
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          foregroundColor: kTextColor,
        ),
      ),
      // Memulai aplikasi dari widget HomePage (yang sekarang menangani navigasi)
      home: const HomePage(), 
    );
  }
}

// ===============================================
// 🎯 KELAS UTAMA: HOMEPAGE (MENANGANI NAVIGASI)
// ===============================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Index awal disetel ke Home (Index 2) sesuai desain Bottom Bar
  int _currentIndex = 2; 

  // Daftar halaman yang akan ditampilkan sesuai urutan navbar di CustomNavbar
  final List<Widget> _pages = [
    const SchedulePage(), // Index 0: Schedule
    const MealPage(),     // Index 1: Meal (Menggantikan NutrisiPage/ResepkuPage)
    const HomePageContent(), // Index 2: Home (Konten utama)
    const ReportPage(),   // Index 3: Report (Menggantikan BookmarkPage)
    const ProfilePage(),  // Index 4: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan konten halaman yang sedang aktif
      body: _pages[_currentIndex], 
      
      // Menggunakan CustomNavbar yang dinamis
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Update state untuk mengganti halaman
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// ===============================================
// 🏡 KELAS KONTEN: HOMEPAGECONTENT
// ===============================================
// Ini adalah konten yang sebelumnya ada di dalam HomePage.build()
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: CircleAvatar(
            backgroundColor: kAccentRed, 
          ),
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
        actions: [
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
            const SizedBox(height: 30),

            // BMI Section (IMT)
            const BmiSection(),
            const SizedBox(height: 30),

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
            const SizedBox(height: 15),

            // Upcoming Meals Header
            const UpcomingMealsList(),
            const SizedBox(height: 30),
            // (A list of upcoming meals would go here)
          ],
          
        ),
        
      ),
      // bottomNavigationBar dihapus karena sudah di-handle oleh HomePage (StatefulWidget)
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
                colors: [
                  Colors.blue.shade200, 
                  kAccentGreen, 
                  Colors.orange.shade400, 
                  kAccentRed, 
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.55 - 16, // Approximate position for 26.6
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: kTextColor,
                  ),
                ),
                const Positioned(left: 0, child: Padding(padding: EdgeInsets.all(5), child: Text('Underweight', style: TextStyle(fontSize: 10, color: Colors.white)))),
                const Positioned(left: 100, child: Padding(padding: EdgeInsets.all(5), child: Text('Normal', style: TextStyle(fontSize: 10, color: Colors.white)))),
                const Positioned(right: 0, child: Padding(padding: EdgeInsets.all(5), child: Text('Obese', style: TextStyle(fontSize: 10, color: Colors.white)))),
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

// --- Component 2: Daily Stats Row & StatCard ---
class DailyStatsRow extends StatelessWidget {
  const DailyStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Expanded(
            child: StatCard(
              title: 'Makan',
              value: '2/3 kali',
              delta: '',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: 'Kalori',
              value: '1130 kcal',
              delta: '+680 kcal',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: StatCard(
              title: 'Pengeluaran',
              value: 'Rp 82.000',
              delta: '+Rp 42.000',
            ),
          ),
        ),
      );
    }

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                // Menggunakan kAccentRed untuk Kalori, kAccentGreen untuk Pengeluaran (sesuai logika umum)
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

// --- Component 3: Meal Cards Section (Horizontal Scroll) & MealCard ---
class MealCardsSection extends StatelessWidget {
  const MealCardsSection({super.key});

  final List<Map<String, dynamic>> meals = const [
    {
      'time': 'Sarapan',
      'name': 'Caesar Salad',
      'tag': 'Sayuran',
      'calories': '450 kcal',
      'price': 'Rp 47.000',
      'imagePath': 'assets/caesar_salad.png', 
    },
    {
      'time': 'Makan Siang',
      'name': 'Udang Saos Tiram',
      'tag': 'Udang',
      'calories': '510 kcal',
      'price': 'Rp 42.000',
      'imagePath': 'assets/udang_saos_tiram.png', 
    },
    {
      'time': 'Makan Malam',
      'name': 'Sandwich Ayam',
      'tag': 'Ayam',
      'calories': '430 kcal',
      'price': 'Rp 35.000',
      'imagePath': 'assets/sandwich_ayam.png', 
    },
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
                      decoration: BoxDecoration(
                        color: Colors.grey[300], 
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
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

// --- NEW Component: Upcoming Meals List ---
class UpcomingMealsList extends StatelessWidget {
  const UpcomingMealsList({super.key});

  final List<Map<String, dynamic>> upcomingMeals = const [
    {'time': 'Sarapan', 'clock': '08:00', 'name': 'Caesar Salad', 'isDone': true},
    {'time': 'Makan Siang', 'clock': '13:00', 'name': 'Udang Saos Tiram', 'isDone': true},
    {'time': 'Makan Malam', 'clock': '19:00', 'name': 'Sandwich Ayam', 'isDone': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
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
          const SizedBox(height: 15),
          
          // List of Meals
          Column(
            children: upcomingMeals.map((meal) {
              return MealListItem(
                time: meal['time'] as String,
                clock: meal['clock'] as String,
                name: meal['name'] as String,
                isDone: meal['isDone'] as bool,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class MealListItem extends StatelessWidget {
  final String time;
  final String clock;
  final String name;
  final bool isDone;

  const MealListItem({
    required this.time,
    required this.clock,
    required this.name,
    required this.isDone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDone ? Colors.transparent : Colors.grey,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: isDone ? kAccentGreen : Colors.white,
                ),
                child: isDone
                    ? const Icon(
                        Icons.check,
                        size: 20,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Meal Time and Clock
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: kTextColor,
                      ),
                    ),
                    Text(
                      clock,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Meal Name (Aligned Right)
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          if (time != 'Makan Malam') // Tambahkan Divider, kecuali di item terakhir
            Divider(
              color: Colors.grey[300],
              height: 16,
              thickness: 1,
              indent: 44, // Jarak dari kiri agar tidak menutupi checkbox
            ),
        ],
      ),
    );
  }
}

// --- Component 4: Custom Bottom Navigation Bar ---
class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavbar({required this.currentIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, 
      selectedItemColor: const Color(0xFF4CAF50), 
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex, 
      onTap: onTap,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time), // Mengganti ke ikon yang lebih umum untuk Schedule
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Meal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
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
