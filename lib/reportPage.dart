import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// --- Model Data (Untuk simulasi data dari Backend) ---
// Ini adalah data yang nantinya akan Anda dapatkan dari Firebase/BLoC

// Model untuk data di Pie Chart
class DailyReportData {
  final double totalKcal;
  final double carbPercent;
  final double proteinPercent;
  final double fatPercent;
  final double othersPercent;

  DailyReportData({
    required this.totalKcal,
    required this.carbPercent,
    required this.proteinPercent,
    required this.fatPercent,
    required this.othersPercent,
  });
}

// Model untuk data log berat badan di pop-up
class WeightLog {
  final DateTime date;
  final double weight;

  WeightLog({required this.date, required this.weight});
}

// ---------------------------------------------------
// --- HALAMAN UTAMA (FITUR 5) ---
// ---------------------------------------------------

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // --- DUMMY DATA STATE ---
  // Nantinya, data ini akan datang dari State Management (BLoC/Riverpod)
  
  // Tanggal yang sedang dilihat (default-nya hari ini)// Tanggal yang sedang dilihat (default-nya hari ini)
  DateTime _selectedDate = DateTime(2025, 4, 15);

  // Data untuk kalori harian (tetap sama)
  final Map<int, double> _monthlyCalorieLogs = {
    7: 1560, 8: 1200, 9: 1400, 10: 1300, 11: 1500, 12: 1450, 13: 1350,
    14: 1850, // Data untuk tanggal 14
    15: 1240, // data hari ini
  };

  // 1. "DATABASE" DUMMY UNTUK PIE CHART
  // Kunci (int) adalah hari, Value adalah data nutrisinya.
  final Map<int, DailyReportData> _monthlyReportData = {
    14: DailyReportData( // Data untuk tanggal 14
      totalKcal: 1850,
      carbPercent: 50,
      proteinPercent: 20,
      fatPercent: 25,
      othersPercent: 5,
    ),
    15: DailyReportData( // Data untuk tanggal 15
      totalKcal: 1240,
      carbPercent: 45,
      proteinPercent: 25,
      fatPercent: 20,
      othersPercent: 10,
    ),
  };

  // Data default jika tidak ada log di tanggal tersebut
  final DailyReportData _defaultReportData = DailyReportData(
    totalKcal: 0, carbPercent: 0, proteinPercent: 0, fatPercent: 0, othersPercent: 0,
  );

  // 2. UBAH VARIABEL STATE MENJADI TIDAK FINAL
  // Ini adalah variabel yang akan kita update dan akan ditampilkan di UI.
  late DailyReportData _selectedReportData;
  late double _selectedWeight;

  // Data untuk pop-up chart berat badan (tetap sama)
  final List<WeightLog> _monthlyWeightLogs = [
    WeightLog(date: DateTime(2025, 4, 10), weight: 77.0),
    WeightLog(date: DateTime(2025, 4, 11), weight: 76.5),
    WeightLog(date: DateTime(2025, 4, 12), weight: 75.5),
    WeightLog(date: DateTime(2025, 4, 13), weight: 76.5),
    WeightLog(date: DateTime(2025, 4, 14), weight: 76.0),
    WeightLog(date: DateTime(2025, 4, 15), weight: 75.0),
  ];

  // Data Makanan Favorit (tetap sama)
  final String _favoriteFoodImageUrl = "https://placeholder.images/600x400";
  final String _favoriteFoodName = "Roti Lapis Keju";
  
  // 3. INISIALISASI STATE AWAL
  @override
  void initState() {
    super.initState();
    // Saat screen pertama kali dimuat, panggil fungsi untuk set data awal
    _updateSelectedData(_selectedDate.day);
  }

  // Fungsi helper untuk mengambil data berdasarkan hari
  void _updateSelectedData(int day) {
    // Ambil data dari "database" dummy. Jika tidak ada, gunakan data default.
    _selectedReportData = _monthlyReportData[day] ?? _defaultReportData;
    
    // Ambil data berat badan untuk hari yang dipilih
    // 'firstWhere' akan error jika tidak ada, 'firstWhereOrNull' (dari package collection) lebih aman
    _selectedWeight = _monthlyWeightLogs
        .firstWhere(
            (log) => log.date.day == day,
            orElse: () => WeightLog(date: _selectedDate, weight: 0.0) // fallback
        ).weight;
  }

  // --- END DUMMY DATA ---

  // Fungsi untuk menampilkan pop-up (Item 4)
  void _showWeightPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _WeightChartDialog(
        logs: _monthlyWeightLogs,
        highlightDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inisialisasi format tanggal (membutuhkan package intl)
    final DateFormat dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    
    // Hitung jumlah hari di bulan ini
    final int daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);

    return Scaffold(
      // 1. Informasi Hari/Tanggal (AppBar)
      appBar: AppBar(
        title: Text(
          dateFormat.format(_selectedDate),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Chart Monitor Kalori Harian (Scrollable)
            SizedBox(
              height: 150, // Memberi tinggi tetap untuk chart
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Scroll ke tanggal yang dipilih saat build
                controller: ScrollController(
                  initialScrollOffset: (_selectedDate.day - 1) * 40.0, // Perkiraan offset
                ),
                child: Row(
                  children: List.generate(daysInMonth, (index) {
                    final int day = index + 1;
                    final bool isHighlighted = day == _selectedDate.day;
                    final double calorie = _monthlyCalorieLogs[day] ?? 0;

                    return _CalorieBar(
                      day: day,
                      calorie: calorie,
                      maxCalorie: 2000, // Asumsi max kalori untuk tinggi bar
                      isHighlighted: isHighlighted,
                      onTap: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            day,
                          );
                          // 4. PANGGIL FUNGSI UNTUK UPDATE DATA
                          _updateSelectedData(day);
                        });
                      },
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Dashboard Pie Chart (Monitor Makanan)
            _NutritionMonitorCard(data: _selectedReportData), // <-- DIUBAH
            const SizedBox(height: 16),

            // 4 & 5. Kartu Berat Badan dan Makanan Favorit
            Row(
              children: [
                // 4. Kartu Berat Badan (Kiri Bawah)
                Expanded(
                  child: _WeightCard(
                    weight: _selectedWeight,
                    onTap: () => _showWeightPopup(context),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 5. Kartu Makanan Favorit (Kanan Bawah)
                Expanded(
                  child: _FavoriteFoodCard(
                    imageUrl: _favoriteFoodImageUrl,
                    foodName: _favoriteFoodName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      
      // 6. Navigation Bar (Placeholder)
      // Ini akan menjadi bagian dari Scaffold utama aplikasi Anda,
      // bukan hanya di ReportScreen.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Set index "Report"
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Meal'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// --- WIDGET KOMPONEN (Bisa dipisah ke file lain) ---
// ---------------------------------------------------

// Widget untuk Item 2: Bar Kalori Harian
class _CalorieBar extends StatelessWidget {
  final int day;
  final double calorie;
  final double maxCalorie;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _CalorieBar({
    required this.day,
    required this.calorie,
    required this.maxCalorie,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double barHeight = (calorie / maxCalorie) * 100; // Tinggi bar 0-100
    final Color barColor = isHighlighted ? Colors.green : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30, // Lebar bar
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Label kalori di atas (opsional, ada di desain)
            if (calorie > 0)
              Text(
                calorie.toInt().toString(),
                style: TextStyle(
                  fontSize: 8,
                  color: isHighlighted ? Colors.green : Colors.grey,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            const SizedBox(height: 4),
            // Bar
            Container(
              height: barHeight.clamp(5, 100), // Min height 5
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 4),
            // Label Hari
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk Item 3: Kartu Monitor Makanan
class _NutritionMonitorCard extends StatelessWidget {
  final DailyReportData data;

  const _NutritionMonitorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monitor Makanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: _buildPieChart(context),
                ),
                // List Makro
                Expanded(
                  flex: 3,
                  child: _buildMacroList(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk Pie Chart (Item 3)
  Widget _buildPieChart(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Teks di tengah
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data.totalKcal.toInt().toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Total kcal',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          // Chart
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40, // Ini yang membuatnya jadi Donut Chart
              sections: [
                PieChartSectionData(
                  value: data.carbPercent,
                  color: Colors.blue.shade400,
                  title: '', // Sembunyikan label di chart
                  radius: 20,
                ),
                PieChartSectionData(
                  value: data.proteinPercent,
                  color: Colors.green.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: data.fatPercent,
                  color: Colors.orange.shade400,
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  value: data.othersPercent,
                  color: Colors.purple.shade400,
                  title: '',
                  radius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk List Makro (Item 3)
  Widget _buildMacroList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MacroRow(
          color: Colors.blue.shade400,
          title: 'Karbohidrat',
          percent: data.carbPercent,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.green.shade400,
          title: 'Protein',
          percent: data.proteinPercent,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.orange.shade400,
          title: 'Lemak',
          percent: data.fatPercent,
        ),
        const SizedBox(height: 8),
        _MacroRow(
          color: Colors.purple.shade400,
          title: 'Lainnya',
          percent: data.othersPercent,
        ),
      ],
    );
  }
}

// Helper untuk baris makro (Karbohidrat 45%)
class _MacroRow extends StatelessWidget {
  final Color color;
  final String title;
  final double percent;

  const _MacroRow({
    required this.color,
    required this.title,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(title),
        const Spacer(),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Widget untuk Item 4: Kartu Berat Badan
class _WeightCard extends StatelessWidget {
  final double weight;
  final VoidCallback onTap;

  const _WeightCard({required this.weight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // Samakan tinggi dengan kartu favorit
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Berat badan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    '${weight.toStringAsFixed(1)}kg',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget untuk Item 5: Kartu Makanan Favorit
class _FavoriteFoodCard extends StatelessWidget {
  final String imageUrl;
  final String foodName;

  const _FavoriteFoodCard({required this.imageUrl, required this.foodName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180, // Samakan tinggi dengan kartu berat
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias, // Untuk memotong gambar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder untuk gambar
            Expanded(
              child: Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ),
                // Jika sudah ada URL:
                // child: Image.network(
                //   imageUrl,
                //   fit: BoxFit.cover,
                //   width: double.infinity,
                // ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                foodName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                'Makanan Favorit Bulan Ini',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------
// --- WIDGET POP-UP (Untuk Item 4) ---
// ---------------------------------------------------

class _WeightChartDialog extends StatelessWidget {
  final List<WeightLog> logs;
  final DateTime highlightDate;

  const _WeightChartDialog({required this.logs, required this.highlightDate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Berat badan per hari'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Format bulan (e.g., "April 2025")
              DateFormat('MMMM yyyy', 'id_ID').format(highlightDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200, // Tinggi chart
              child: _buildBarChart(context), // Menggunakan BarChart dari fl_chart
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  // Helper untuk Bar Chart Pop-up (fl_chart)
  Widget _buildBarChart(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        // Sembunyikan grid dan border
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        
        // Sumbu Y (Berat)
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Tampilkan label berat (75, 76, 77)
                if (value == 75 || value == 76 || value == 77) {
                  return Text('${value.toInt()}kg', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          
          // Sumbu X (Tanggal)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // 'value' di sini adalah index dari list 'logs'
                final int index = value.toInt();
                if (index >= 0 && index < logs.length) {
                  return Text(
                    logs[index].date.day.toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),

        // Data Bar
        barGroups: List.generate(logs.length, (index) {
          final log = logs[index];
          final bool isHighlighted = DateUtils.isSameDay(log.date, highlightDate);
          
          return BarChartGroupData(
            x: index, // Index sebagai ID
            barRods: [
              BarChartRodData(
                toY: log.weight, // Nilai berat badan
                color: isHighlighted ? Colors.orange : Colors.orange.shade200,
                width: 15,
                borderRadius: BorderRadius.circular(4),
                // Label di atas bar
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    log.weight,
                    isHighlighted ? Colors.orange : Colors.orange.shade200,
                    // Widget kustom untuk label di atas bar
                    // Sayangnya fl_chart tidak langsung support ini di 'rodStackItems'
                    // Kita bisa gunakan 'BarTouchData' untuk tooltip
                  ),
                ],
              ),
            ],
            // Menampilkan nilai di atas bar (menggunakan BarTouchData)
            showingTooltipIndicators: isHighlighted ? [0] : [],
          );
        }),
        
        // Menampilkan nilai di atas bar (Tooltip)
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData group) => Colors.transparent,
            tooltipMargin: -10, // Posisikan di atas bar
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY}kg', // Teks (e.g., 75.5kg)
                const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        
        // Set min/max Y agar chart terlihat bagus
        minY: logs.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 1, // 1kg di bawah min
        maxY: logs.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 1, // 1kg di atas max
      ),
    );
  }
}