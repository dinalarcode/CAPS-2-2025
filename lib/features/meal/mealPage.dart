import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilink/features/meal/filterPopup.dart';
import 'package:nutrilink/features/meal/foodDetailPopup.dart';
import 'package:nutrilink/features/meal/mealRecommendationEngine.dart';
import 'package:nutrilink/features/meal/cartPage.dart';
import 'package:nutrilink/services/orderService.dart';
import 'package:nutrilink/services/recommendationCacheService.dart';
import 'package:nutrilink/utils/storageHelper.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/config/appTheme.dart';

class RecommendationScreen extends StatefulWidget {
  final String? initialFilter;
  
  const RecommendationScreen({super.key, this.initialFilter});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  // === STATE VARIABLES ===
  final Set<String> _selectedFilters = {}; // Filter yang aktif
  MealRecommendationResult? _recommendationResult; // Hasil filter
  MealRecommendationResult? _fullRecommendationResult; // Data full tanpa filter
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _userAllergies = {};
  late DateTime _selectedDate;
  Map<String, bool> _orderedMeals = {};
  int _eatFrequency = 3;
  int _cartMealsCount = 0;

  // Cart listener callback
  void _onCartChanged() {
    if (!mounted) return;
    setState(() {
      // Force rebuild untuk update badge
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    
    // PENTING: JANGAN persist filter dari sesi sebelumnya
    _selectedFilters.clear();
    
    // HANYA apply initial filter jika ada dan tidak kosong
    if (widget.initialFilter != null && widget.initialFilter!.trim().isNotEmpty) {
      _selectedFilters.add(widget.initialFilter!);
    }
    
    // Cleanup old caches on init
    RecommendationCacheService.cleanupExpiredCaches();
    
    // Add cart listener untuk auto-update badge
    CartManager.addListener(_onCartChanged);
    
    _loadRecommendations();
  }

  @override
  void dispose() {
    // Remove cart listener
    CartManager.removeListener(_onCartChanged);
    _selectedFilters.clear(); // Clear saat dispose
    super.dispose();
  }

  /// Load rekomendasi dari Firebase
  Future<void> _loadRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'User tidak terautentikasi';
          _isLoading = false;
        });
        return;
      }

      // STEP 1: Cek cache terlebih dahulu
      final cachedRecommendation = await RecommendationCacheService.getRecommendation(_selectedDate);
      
      if (cachedRecommendation != null) {
        // Cache hit - gunakan data cached
        final result = MealRecommendationResult.fromMap(cachedRecommendation);
        _fullRecommendationResult = result;

        final orderedMeals = await OrderService.checkOrderedMeals(_selectedDate);
        final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final cartItems = CartManager.getCartItems();
        final cartMealsCount = cartItems[dateKey]?.length ?? 0;
        final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
        final totalMeals = orderedMealsCount + cartMealsCount;

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _orderedMeals = orderedMeals;
          _eatFrequency = (cachedRecommendation['eatFrequency'] as int?) ?? 3;
          _cartMealsCount = totalMeals;
        });

        _applyTagFilters();
        return;
      }

      // STEP 2: Cache miss - load dari database & generate
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Profil pengguna tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};

      final allergies = List<String>.from(profile['allergies'] as List? ?? []);
      _userAllergies = Set<String>.from(allergies.map((e) => e.toString().toLowerCase()));
      final heightCm = (profile['heightCm'] as num?)?.toDouble() ?? 170;
      final weightKg = (profile['weightKg'] as num?)?.toDouble() ?? 70;
      final sex = profile['sex'] as String? ?? 'Laki-laki';
      final birthDate = (profile['birthDate'] as Timestamp?)?.toDate();
      final activityLevel = profile['activityLevel'] as String? ?? 'lightly_active';
      final target = profile['target'] as String? ?? 'Mempertahankan berat badan';
      final eatFrequency = profile['eatFrequency'] as int? ?? 3;

      final tdee = _calculateTDEE(
        weightKg: weightKg,
        heightCm: heightCm,
        sex: sex,
        age: birthDate != null ? DateTime.now().year - birthDate.year : 25,
        activityLevel: activityLevel,
      );

      final recommendations = await MealRecommendationEngine.getRecommendations(
        userId: user.uid,
        allergies: allergies,
        tdee: tdee,
        target: target,
      );

      // STEP 3: Apply deterministic shuffle berdasarkan tanggal
      final seed = RecommendationCacheService.generateDailySeed(_selectedDate);
      final shuffledSarapan = RecommendationCacheService.deterministicShuffle(
        recommendations['sarapan'] as List<Map<String, dynamic>>,
        seed,
      );
      final shuffledMakanSiang = RecommendationCacheService.deterministicShuffle(
        recommendations['makanSiang'] as List<Map<String, dynamic>>,
        seed + 1, // Different seed for variety
      );
      final shuffledMakanMalam = RecommendationCacheService.deterministicShuffle(
        recommendations['makanMalam'] as List<Map<String, dynamic>>,
        seed + 2,
      );

      final shuffledRecommendations = {
        'sarapan': shuffledSarapan,
        'makanSiang': shuffledMakanSiang,
        'makanMalam': shuffledMakanMalam,
        'calories': recommendations['calories'],
        'protein': recommendations['protein'],
        'carbohydrate': recommendations['carbohydrate'],
        'fat': recommendations['fat'],
        'eatFrequency': eatFrequency,
      };

      // STEP 4: Simpan ke cache
      await RecommendationCacheService.saveRecommendation(_selectedDate, shuffledRecommendations);

      final result = MealRecommendationResult.fromMap(shuffledRecommendations);
      _fullRecommendationResult = result;

      final orderedMeals = await OrderService.checkOrderedMeals(_selectedDate);
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final cartItems = CartManager.getCartItems();
      final cartMealsCount = cartItems[dateKey]?.length ?? 0;
      final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
      final totalMeals = orderedMealsCount + cartMealsCount;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _orderedMeals = orderedMeals;
        _eatFrequency = eatFrequency;
        _cartMealsCount = totalMeals;
      });

      _applyTagFilters();
      
      // Cleanup old menu_order caches (tidak dipakai lagi)
      _cleanupOldMenuOrderCaches();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat rekomendasi: $e';
        _isLoading = false;
      });
    }
  }

  /// Cleanup old menu_order caches (tidak dipakai lagi setelah pakai deterministic shuffle)
  Future<void> _cleanupOldMenuOrderCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final menuOrderKeys = keys.where((k) => k.startsWith('menu_order_')).toList();
      
      for (final key in menuOrderKeys) {
        await prefs.remove(key);
      }
      
      if (menuOrderKeys.isNotEmpty) {
        debugPrint('🧹 Cleaned ${menuOrderKeys.length} old menu_order caches');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning menu_order caches: $e');
    }
  }

  /// Update cart count (called from child widgets)
  void _updateCartCount(int count) {
    if (!mounted) return;
    setState(() {
      _cartMealsCount = count;
    });
  }

  /// Apply filter ke data
  void _applyTagFilters() {
    if (_fullRecommendationResult == null) return;

    // Helper function to sort by personalScore descending
    List<Map<String, dynamic>> sortByScore(List<Map<String, dynamic>> list) {
      final sorted = List<Map<String, dynamic>>.from(list);
      sorted.sort((a, b) => ((b['personalScore'] ?? 0) as num).compareTo((a['personalScore'] ?? 0) as num));
      return sorted;
    }

    // Jika tidak ada filter, tampilkan semua TAPI tetap sort by personalScore
    // Ini memastikan menu paling kiri = menu dengan score tertinggi (konsisten dengan homePage)
    if (_selectedFilters.isEmpty) {
      if (!mounted) return;
      setState(() {
        _recommendationResult = MealRecommendationResult(
          sarapan: sortByScore(_fullRecommendationResult!.sarapan),
          makanSiang: sortByScore(_fullRecommendationResult!.makanSiang),
          makanMalam: sortByScore(_fullRecommendationResult!.makanMalam),
          dailyCalories: _fullRecommendationResult!.dailyCalories,
          proteinGrams: _fullRecommendationResult!.proteinGrams,
          carbsGrams: _fullRecommendationResult!.carbsGrams,
          fatsGrams: _fullRecommendationResult!.fatsGrams,
        );
      });
      return;
    }

    // Filter data berdasarkan tag yang dipilih
    bool matchesTags(Map<String, dynamic> item) {
      final tagsRaw = item['tags'];
      final List<String> tags = [];
      
      if (tagsRaw is String) {
        tags.addAll(tagsRaw.split(',').map((s) => s.trim()));
      } else if (tagsRaw is List) {
        tags.addAll(tagsRaw.map((e) => e.toString()));
      }
      
      for (var k in ['tag1', 'tag2', 'tag3']) {
        final v = item[k];
        if (v is String && v.isNotEmpty) tags.add(v.trim());
      }

      final lowerTags = tags.map((t) => t.toLowerCase().trim()).toSet();
      
      // EXACT MATCH ONLY
      for (final filterTag in _selectedFilters) {
        if (lowerTags.contains(filterTag.toLowerCase().trim())) {
          return true;
        }
      }
      return false;
    }

    List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> list) {
      final filtered = list.where((it) => matchesTags(it)).toList();
      // Sort by personalScore descending - menu terbaik di posisi pertama (paling kiri)
      filtered.sort((a, b) => ((b['personalScore'] ?? 0) as num).compareTo((a['personalScore'] ?? 0) as num));
      return filtered;
    }

    if (!mounted) return;
    setState(() {
      _recommendationResult = MealRecommendationResult(
        sarapan: filterList(_fullRecommendationResult!.sarapan),
        makanSiang: filterList(_fullRecommendationResult!.makanSiang),
        makanMalam: filterList(_fullRecommendationResult!.makanMalam),
        dailyCalories: _fullRecommendationResult!.dailyCalories,
        proteinGrams: _fullRecommendationResult!.proteinGrams,
        carbsGrams: _fullRecommendationResult!.carbsGrams,
        fatsGrams: _fullRecommendationResult!.fatsGrams,
      );
    });
  }

  double _calculateTDEE({
    required double weightKg,
    required double heightCm,
    required String sex,
    required int age,
    required String activityLevel,
  }) {
    double bmr;
    if (sex == 'Laki-laki' || sex == 'Male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    const activityMultipliers = {
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
      'extra_active': 1.9,
    };

    final multiplier = activityMultipliers[activityLevel] ?? 1.375;
    return bmr * multiplier;
  }

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _loadRecommendations();
    }
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return FilterFoodPopup(
          initialFilters: _selectedFilters,
          onFiltersChanged: (newFilters) {
            if (!mounted) return;
            setState(() {
              _selectedFilters.clear();
              _selectedFilters.addAll(newFilters);
            });
            _applyTagFilters(); // LANGSUNG APPLY FILTER
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.white, elevation: 0),
        body: AppWidgets.loading(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRecommendations,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.white, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Date Picker
              _DatePickerSection(
                selectedDate: _selectedDate,
                onTap: _pickDate,
              ),
              
              const SizedBox(height: 16),
              
              // Meal Frequency Indicator
              if (_cartMealsCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _MealFrequencyIndicator(
                    currentMeals: _cartMealsCount,
                    maxMeals: _eatFrequency,
                  ),
                ),
              
              if (_cartMealsCount > 0) const SizedBox(height: 16),
              
              // Filter Section
              _FilterSection(
                selectedFilters: _selectedFilters,
                onFilterPressed: () => _showFilter(context),
              ),
              
              const SizedBox(height: 24),
              
              // Meal Lists (SPACING DISESUAIKAN)
              if (_recommendationResult != null) ...[
                _MealSection(
                  title: 'Sarapan',
                  items: _recommendationResult!.sarapan,
                  userAllergies: _userAllergies,
                  selectedDate: _selectedDate,
                  isOrdered: _orderedMeals['Sarapan'] ?? false,
                ),
                const SizedBox(height: 24),
                _MealSection(
                  title: 'Makan Siang',
                  items: _recommendationResult!.makanSiang,
                  userAllergies: _userAllergies,
                  selectedDate: _selectedDate,
                  isOrdered: _orderedMeals['Makan Siang'] ?? false,
                ),
                const SizedBox(height: 24),
                _MealSection(
                  title: 'Makan Malam',
                  items: _recommendationResult!.makanMalam,
                  userAllergies: _userAllergies,
                  selectedDate: _selectedDate,
                  isOrdered: _orderedMeals['Makan Malam'] ?? false,
                ),
              ],
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCartButton() {
    return Stack(
      children: [
        FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
            if (!mounted) return;
            final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final cartItems = CartManager.getCartItems();
            final cartMealsCount = cartItems[dateKey]?.length ?? 0;
            final orderedMeals = await OrderService.checkOrderedMeals(_selectedDate);
            final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
            setState(() {
              _cartMealsCount = orderedMealsCount + cartMealsCount;
            });
          },
          backgroundColor: AppColors.green,
          shape: const CircleBorder(),
          child: const Icon(Icons.shopping_cart, color: AppColors.white),
        ),
        if (CartManager.getItemCount() > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: AppRadius.smallRadius,
                border: Border.all(color: AppColors.white, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                '${CartManager.getItemCount()}',
                style: AppTextStyles.caption.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// === DATE PICKER SECTION ===
class _DatePickerSection extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _DatePickerSection({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.green.withValues(alpha: 0.15), AppColors.greenLight.withValues(alpha: 0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Meal Prep', style: TextStyle(fontSize: 12, color: AppColors.greyText, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.green),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.green, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// === MEAL FREQUENCY INDICATOR ===
class _MealFrequencyIndicator extends StatelessWidget {
  final int currentMeals;
  final int maxMeals;

  const _MealFrequencyIndicator({required this.currentMeals, required this.maxMeals});

  @override
  Widget build(BuildContext context) {
    final isAtLimit = currentMeals >= maxMeals;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAtLimit 
            ? [Colors.orange.shade50, Colors.orange.shade100]
            : [AppColors.green.withValues(alpha: 0.1), AppColors.green.withValues(alpha: 0.15)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAtLimit ? Colors.orange : AppColors.green, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAtLimit ? Colors.orange : AppColors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAtLimit ? Icons.warning_amber_rounded : Icons.restaurant_menu,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frekuensi Makan Hari Ini',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isAtLimit ? Colors.orange.shade900 : AppColors.greyText),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$currentMeals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isAtLimit ? Colors.orange.shade700 : AppColors.green)),
                    Text(' / $maxMeals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isAtLimit ? Colors.orange.shade600 : Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Text('menu', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === FILTER SECTION ===
class _FilterSection extends StatelessWidget {
  final Set<String> selectedFilters;
  final VoidCallback onFilterPressed;

  const _FilterSection({required this.selectedFilters, required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedFilters.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onFilterPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: hasFilters
                    ? LinearGradient(
                        colors: [AppColors.green.withValues(alpha: 0.15), AppColors.greenLight.withValues(alpha: 0.1)],
                      )
                    : null,
                  color: hasFilters ? null : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hasFilters ? AppColors.green.withValues(alpha: 0.4) : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, color: hasFilters ? AppColors.green : Colors.grey, size: 20),
                    const SizedBox(width: 6),
                    Text('Filter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: hasFilters ? AppColors.green : Colors.grey)),
                    if (hasFilters) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(10)),
                        child: Text('${selectedFilters.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedFilters.length,
                itemBuilder: (context, index) {
                  final tag = selectedFilters.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(15)),
                      child: Center(
                        child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.0)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// === MEAL SECTION (REDESIGN TOTAL - STYLING HOMEPAGE.DART) ===
class _MealSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Set<String> userAllergies;
  final DateTime selectedDate;
  final bool isOrdered;

  const _MealSection({
    required this.title,
    required this.items,
    required this.userAllergies,
    required this.selectedDate,
    required this.isOrdered,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.greyText)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade500, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tidak ada menu ${title.toLowerCase()} dengan filter yang dipilih',
                      style: TextStyle(fontFamily: 'Funnel Display', fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: const TextStyle(fontFamily: 'Funnel Display', fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.greyText)),
        ),
        const SizedBox(height: 10),
        if (isOrdered)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green.withValues(alpha: 0.12), AppColors.green.withValues(alpha: 0.04)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anda sudah memesan ${title.toLowerCase()} untuk tanggal ${DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate)}',
                      style: TextStyle(fontFamily: 'Funnel Display', fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!isOrdered)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: items.length > 10 ? 10 : items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _FoodCard(
                    item: items[index],
                    userAllergies: userAllergies,
                    selectedDate: selectedDate,
                    mealType: title,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// === FOOD CARD (REDESIGN TOTAL - EXACT HOMEPAGE.DART STYLING + HD IMAGE OPTIMIZATION) ===
class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Set<String> userAllergies;
  final DateTime selectedDate;
  final String mealType;

  const _FoodCard({
    required this.item,
    required this.userAllergies,
    required this.selectedDate,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    final tagsRaw = item['tags'];
    final List<String> tags = [];
    
    if (tagsRaw is String) {
      tags.addAll(tagsRaw.split(',').map((s) => s.trim()));
    } else if (tagsRaw is List) {
      tags.addAll(tagsRaw.map((e) => e.toString()));
    }

    for (var k in ['tag1', 'tag2', 'tag3']) {
      final v = item[k];
      if (v is String && v.isNotEmpty) tags.add(v.trim());
    }

    final displayTags = tags.where((t) {
      final tagLower = t.toLowerCase();
      return !userAllergies.any((a) => tagLower.contains(a.toLowerCase()));
    }).toList();

    final name = item['name'] as String? ?? 'Unknown';
    final calories = item['calories'] as num? ?? 0;
    final price = item['price'] as num? ?? 0;
    final image = item['image'] as String? ?? '';

    return GestureDetector(
      onTap: () {
        showFoodDetailPopup(
          context,
          Map<String, dynamic>.from(item),
          selectedDate: selectedDate,
          mealType: mealType,
        );
        // Refresh cart counter with a short delay
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (!context.mounted) return;
          final state = context.findAncestorStateOfType<_RecommendationScreenState>();
          if (state != null) {
            final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
            final cartItems = CartManager.getCartItems();
            final cartMealsCount = cartItems[dateKey]?.length ?? 0;
            final orderedMeals = await OrderService.checkOrderedMeals(selectedDate);
            final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
            state._updateCartCount(orderedMealsCount + cartMealsCount);
          }
        });
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // IMAGE SECTION - ASPECT RATIO 1:1 DENGAN OPTIMASI HD
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image.startsWith('http') ? image : buildImageUrl(image),
                          cacheKey: image.split('?').first.split('/').last,
                          fit: BoxFit.cover,
                          memCacheWidth: 450,
                          memCacheHeight: 450,
                          maxWidthDiskCache: 450,
                          maxHeightDiskCache: 450,
                          fadeInDuration: const Duration(milliseconds: 200),
                          fadeOutDuration: const Duration(milliseconds: 100),
                          useOldImageOnUrlChange: false,
                          filterQuality: FilterQuality.medium,
                          errorListener: (error) {
                            // Suppress PathNotFoundException errors
                            debugPrint('Image cache error (suppressed): $error');
                          },
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Gambar tidak tersedia',
                                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text(
                                'Gambar tidak tersedia',
                                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                  ),
                  // TAGS OVERLAY - SHOW ALL 3 TAGS
                  if (displayTags.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      right: 6,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: displayTags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.greenLight, AppColors.green],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontFamily: 'Funnel Display',
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            // TEXT CONTENT
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.black87,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${calories.toInt()} kcal',
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontSize: 9,
                      color: AppColors.lightGreyText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Rp ${_formatRupiah(price)}',
                    style: const TextStyle(
                      fontFamily: 'Funnel Display',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(dynamic v) {
    if (v == null) return '0';
    final number = (v is num) ? v.toInt() : 0;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
