// lib/sleepSchedulePage.dart

import 'package:flutter/material.dart';
import 'onboardingHelpers.dart';
import '../../models/userProfileDraft.dart';

// ====== Palet warna konsisten dengan ChallengePage ======
const Color kGreen = Color(0xFF5F9C3F);
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);
const Color kLightGreyText = Color(0xFF888888);
const Color kDisabledGrey = Color(0xFFBDBDBD);
const Color kMutedBorderGrey = Color(0xFFA9ABAD);
final Color kBaseGreyFill =
    const Color(0xFF000000).withValues(alpha: 0.04);

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
    draft = getDraft(context);
    
    // Inisialisasi dari draft atau nilai default (Jam 5 pagi dan 9 malam/21:00)
    wakeTime = draft.wakeTime ?? const TimeOfDay(hour: 5, minute: 0);
    sleepTime = draft.sleepTime ?? const TimeOfDay(hour: 21, minute: 0);
  }

  // ====== LOGIKA NEXT / BACK ======
  void _next() {
    // Hitung durasi tidur dalam jam
    final sleepDuration = _calculateSleepHours(sleepTime, wakeTime);

    // Simpan waktu dan durasi ke draft
    draft.wakeTime = wakeTime;
    draft.sleepTime = sleepTime;
    draft.sleepHours = sleepDuration;

    saveDraft(context, draft);
    next(context, '/summary', draft);
  }

  void _back() {
    back(context, draft);
  }

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
      durationMinutes = (24 * 60 - sleepMinutes) + wakeMinutes.toDouble();
    } else {
      durationMinutes = (wakeMinutes - sleepMinutes).toDouble();
    }
    
    return durationMinutes / 60.0;
  }

  // Widget untuk arrow button dengan state (gray default, black on press)
  Widget _buildArrowButton(IconData icon, VoidCallback onPressed, ButtonStyle style) {
    bool isPressed = false;
    
    return StatefulBuilder(
      builder: (context, setButtonState) {
        return GestureDetector(
          onTapDown: (_) {
            setButtonState(() => isPressed = true);
          },
          onTapUp: (_) {
            setButtonState(() => isPressed = false);
            onPressed();
          },
          onTapCancel: () {
            setButtonState(() => isPressed = false);
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 30,
              color: isPressed ? Colors.black87 : kLightGreyText,
            ),
          ),
        );
      },
    );
  }

  // Widget untuk menampilkan dan mengontrol Jam
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

    const textStyle = TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      color: kGreen,
    );
    
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Funnel Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Kontrol Jam (format 24 jam)
            Column(
              children: [
                _buildArrowButton(
                  Icons.keyboard_arrow_up,
                  () => setState(() => adjustTime(1, 0)),
                  buttonStyle,
                ),
                Text(time.hour.toString().padLeft(2, '0'), style: textStyle),
                _buildArrowButton(
                  Icons.keyboard_arrow_down,
                  () => setState(() => adjustTime(-1, 0)),
                  buttonStyle,
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
                _buildArrowButton(
                  Icons.keyboard_arrow_up,
                  () => setState(() => adjustTime(0, 5)),
                  buttonStyle,
                ),
                Text(time.minute.toString().padLeft(2, '0'), style: textStyle),
                _buildArrowButton(
                  Icons.keyboard_arrow_down,
                  () => setState(() => adjustTime(0, -5)),
                  buttonStyle,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isInputValid = true; // Selalu valid karena ada default value
    final currentDuration = _calculateSleepHours(sleepTime, wakeTime);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ====== KONTEN UTAMA ======
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul ala ChallengePage
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Funnel Display',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(text: 'Pilih jam '),
                          TextSpan(
                            text: 'bangun dan tidur kamu',
                            style: TextStyle(color: kGreen),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kami akan mempersonalisasikan jadwal makan yang disesuaikan dengan pola tidur kamu.',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreyText,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ====== KONTROL JAM BANGUN ======
                    _buildTimeControl(
                      'Pilih Jam Bangun kamu',
                      wakeTime,
                      (newTime) => setState(() {
                        wakeTime = newTime;
                      }),
                    ),
                    const SizedBox(height: 32),

                    // ====== KONTROL JAM TIDUR ======
                    _buildTimeControl(
                      'Pilih Jam Tidur kamu',
                      sleepTime,
                      (newTime) => setState(() {
                        sleepTime = newTime;
                      }),
                    ),
                    const SizedBox(height: 24),

                    // ====== DURASI TIDUR (centered) ======
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: kGreyText,
                          ),
                          children: [
                            const TextSpan(text: 'Durasi Tidur: '),
                            TextSpan(
                              text: '${currentDuration.toStringAsFixed(1)} jam',
                              style: const TextStyle(
                                color: kGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ====== INFO BOX ala ChallengePage (di bawah) ======
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: kMutedBorderGrey,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000)
                                .withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: kGreyText,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kamu bisa mengedit jadwal tidur kamu di pengaturan profil nanti.',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: kGreyText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====== BACK BUTTON bulat ala ChallengePage ======
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                    size: 24,
                  ),
                  tooltip: 'Kembali',
                  onPressed: _back,
                ),
              ),
            ),

            // ====== TOMBOL LANJUT (gradient hijau, sama seperti ChallengePage) ======
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GradientButton(
                  text: 'Lanjut',
                  enabled: isInputValid,
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================= Gradient Button (copas dari ChallengePage) =======================
class GradientButton extends StatefulWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool hover = false;
  bool press = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && (hover || press);

    final gradient = widget.enabled
        ? LinearGradient(
            colors: active
                ? const [kGreen, kGreenLight]
                : const [kGreenLight, kGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() {
        hover = false;
        press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enabled) setState(() => press = true);
        },
        onTapUp: (_) {
          if (widget.enabled) setState(() => press = false);
        },
        onTapCancel: () {
          if (widget.enabled) setState(() => press = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            color: widget.enabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.enabled ? kGreen : kDisabledGrey,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.enabled ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
