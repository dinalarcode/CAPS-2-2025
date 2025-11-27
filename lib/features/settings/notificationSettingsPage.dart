import 'package:flutter/material.dart';
import 'package:nutrilink/config/appTheme.dart';
import 'package:nutrilink/services/notificationService.dart';
import 'package:nutrilink/services/scheduleService.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late Map<String, bool> preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await NotificationService.getAllNotificationPreferences();
      if (mounted) {
        setState(() {
          preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePreference(String mealType, bool value) async {
    setState(() {
      preferences[mealType] = value;
    });

    await NotificationService.setMealNotificationPreference(
      mealType: _formatMealType(mealType),
      enabled: value,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '✅ Notifikasi $mealType diaktifkan'
                : '❌ Notifikasi $mealType dinonaktifkan',
          ),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatMealType(String key) {
    switch (key) {
      case 'sarapan':
        return 'Sarapan';
      case 'makan_siang':
        return 'Makan Siang';
      case 'makan_malam':
        return 'Makan Malam';
      default:
        return key;
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'sarapan':
        return Icons.wb_sunny;
      case 'makan_siang':
        return Icons.wb_sunny_outlined;
      case 'makan_malam':
        return Icons.nights_stay;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            fontFamily: 'Funnel Display',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Anda akan menerima notifikasi 15 menit sebelum waktu makan yang dijadwalkan.',
                              style: TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Settings section
                    Text(
                      'Aktivkan Notifikasi Untuk:',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Meal notification settings
                    ..._buildMealNotificationTiles(),

                    const SizedBox(height: 24),

                    // Pengaturan Umum Section
                    Text(
                      'Pengaturan Umum',
                      style: TextStyle(
                        fontFamily: 'Funnel Display',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Waktu Tenang
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: AppColors.green,
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          'Waktu Tenang',
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: const Text(
                          'Notifikasi tidak akan dikirim pada jam ini',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: const Text(
                          '22:00\n- 05:00',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: 'Funnel Display',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        onTap: () {
                          // Quiet hours settings - future implementation
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Test notification button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Get tomorrow's schedule
                            final tomorrow =
                                DateTime.now().add(const Duration(days: 1));
                            final meals =
                                await ScheduleService.getScheduleByDate(
                                    tomorrow);

                            if (meals.isNotEmpty) {
                              // Get the first meal (Sarapan)
                              final firstMeal = meals.first;
                              final mealName =
                                  firstMeal['name'] as String? ?? 'Makanan';
                              final calories =
                                  firstMeal['calories'] as int? ?? 0;
                              final mealType =
                                  firstMeal['time'] as String? ?? 'Sarapan';

                              await NotificationService.sendTestNotification(
                                title: '⏰ Waktu Makan $mealType',
                                message:
                                    '15 menit lagi!\n$mealName (~$calories kkal)',
                              );
                            } else {
                              // Fallback if no schedule
                              await NotificationService.sendTestNotification(
                                title: '⏰ Tes Notifikasi',
                                message:
                                    'Belum ada jadwal makan untuk besok. Silakan buat pesanan terlebih dahulu.',
                              );
                            }

                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Notifikasi ujicoba dikirim'),
                                  backgroundColor: AppColors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error sending test notification: $e');
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Coba Notifikasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildMealNotificationTiles() {
    return preferences.entries.map((entry) {
      final mealType = entry.key;
      final isEnabled = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getMealIcon(mealType),
                color: AppColors.green,
                size: 24,
              ),
            ),
            title: Text(
              _formatMealType(mealType),
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              isEnabled ? 'Notifikasi aktif' : 'Notifikasi nonaktif',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Switch(
              value: isEnabled,
              onChanged: (value) {
                _updatePreference(mealType, value);
              },
              activeThumbColor: AppColors.green,
              inactiveThumbColor: Colors.grey,
            ),
          ),
        ),
      );
    }).toList();
  }
}
