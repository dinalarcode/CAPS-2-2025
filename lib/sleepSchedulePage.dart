// File: SleepSchedulePage.dart

import 'package:flutter/material.dart';
import 'package:nutrilink/_onb_helpers.dart'; // Mengandung getDraft, back, saveDraft, next, dan StepScaffold
import 'package:nutrilink/models/user_profile_draft.dart';

class SleepSchedulePage extends StatefulWidget {
  const SleepSchedulePage({super.key});
  @override
  State<SleepSchedulePage> createState() => _SleepSchedulePageState();
}

class _SleepSchedulePageState extends State<SleepSchedulePage> {
  late UserProfileDraft draft;
  late TimeOfDay wakeTime;
  late TimeOfDay sleepTime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mendapatkan draft dari helper
    draft = getDraft(context); 
    
    // Inisialisasi dari draft atau nilai default (Jam 7 pagi dan 11 malam/23:00)
    wakeTime = draft.wakeTime ?? const TimeOfDay(hour: 7, minute: 0);
    sleepTime = draft.sleepTime ?? const TimeOfDay(hour: 23, minute: 0);
  }

  // --- Helpers ---

  // Helper untuk menambah/mengurangi jam atau menit
  TimeOfDay _adjustTime(TimeOfDay original, {int hour = 0, int minute = 0}) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, original.hour, original.minute)
        .add(Duration(hours: hour, minutes: minute));
    return TimeOfDay.fromDateTime(dt);
  }

  // Fungsi untuk menghitung durasi tidur dalam jam (double)
  double _calculateSleepHours(TimeOfDay sleep, TimeOfDay wake) {
    final sleepMinutes = sleep.hour * 60 + sleep.minute;
    final wakeMinutes = wake.hour * 60 + wake.minute;

    double durationMinutes;
    if (sleepMinutes > wakeMinutes) {
      // Tidur melintasi tengah malam: (Menit dari tidur sampai tengah malam) + (Menit dari tengah malam sampai bangun)
      durationMinutes = (24 * 60 - sleepMinutes) + wakeMinutes.toDouble();
    } else {
      // Perbaikan Error 1: memastikan hasilnya double
      durationMinutes = (wakeMinutes - sleepMinutes).toDouble(); 
    }
    
    return durationMinutes / 60.0;
  }

  // Widget untuk menampilkan dan mengontrol Jam (dipertahankan)
  Widget _buildTimeControl(
      String title, TimeOfDay time, Function(TimeOfDay) onChanged) {
    
    void adjustTime(int hour, int minute) {
      final newTime = _adjustTime(time, hour: hour, minute: minute);
      onChanged(newTime);
    }

    const buttonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: WidgetStatePropertyAll(Size(40, 40)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final textStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).primaryColor,
    );
    
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F9C3F),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kontrol Jam
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 30),
                  onPressed: () => setState(() => adjustTime(1, 0)),
                  style: buttonStyle,
                ),
                Text(time.hourOfPeriod.toString().padLeft(2, '0'), style: textStyle),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                  onPressed: () => setState(() => adjustTime(-1, 0)),
                  style: buttonStyle,
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(':', style: textStyle),
            ),
            
            // Kontrol Menit
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 30),
                  onPressed: () => setState(() => adjustTime(0, 5)),
                  style: buttonStyle,
                ),
                Text(time.minute.toString().padLeft(2, '0'), style: textStyle),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                  onPressed: () => setState(() => adjustTime(0, -5)),
                  style: buttonStyle,
                ),
              ],
            ),
            
            // AM/PM Indikator
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10), // Offset
                Text(
                  time.period == DayPeriod.am ? 'AM' : 'PM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10), // Offset
              ],
            )
          ],
        ),
      ],
    );
  }
    
  // Helper untuk Kotak Peringatan (Hint Box) (dipertahankan)
  Widget _buildHintBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF0),  
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E0D0)),  
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Color(0xFF5F9C3F), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kamu bisa mengedit jadwal tidur kamu di pengaturan profil nanti.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  // --- Navigasi ---
  void _goToSummary() {
    // 1. Hitung durasi tidur dalam jam
    final sleepDuration = _calculateSleepHours(sleepTime, wakeTime);

    // 2. Simpan waktu dan durasi ke draft
    draft.wakeTime = wakeTime;
    draft.sleepTime = sleepTime;
    // Perbaikan Error 2: Simpan sebagai double
    draft.sleepHours = sleepDuration; 
    
    // 3. Simpan draft yang diperbarui
    saveDraft(context, draft); // Error 3 hilang

    // 4. Navigasi ke halaman Ringkasan menggunakan helper `next`
    next(context, '/summary', draft); 
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final currentDuration = _calculateSleepHours(sleepTime, wakeTime);
    
    return StepScaffold(
      title: 'Jadwal Tidur',
      onBack: () => back(context, draft),
      onNext: _goToSummary, 
      nextText: 'Lanjut',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Text(
            'Pilih jam bangun dan tidur kamu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F9C3F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kami akan mempersonalisasikan jadwal makan yang disesuaikan dengan pola tidur kamu.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          _buildHintBox(),

          // Kontrol Jam Bangun
          _buildTimeControl(
            'Pilih Jam Bangun kamu',
            wakeTime,
            (newTime) => setState(() {
              wakeTime = newTime;
            }),
          ),
          const SizedBox(height: 40),

          // Kontrol Jam Tidur
          _buildTimeControl(
            'Pilih Jam Tidur kamu',
            sleepTime,
            (newTime) => setState(() {
              sleepTime = newTime;
            }),
          ),
          const SizedBox(height: 20),
          
          // Durasi Tidur yang Dihitung
          Center(
            child: Text(
              'Durasi Tidur: ${currentDuration.toStringAsFixed(1)} jam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          )
        ],
      ),
    );
  }
}