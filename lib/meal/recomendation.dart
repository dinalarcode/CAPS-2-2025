import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrilink/meal/filter_popup.dart';
import 'package:nutrilink/meal/food_detail_popup.dart';
import 'package:nutrilink/meal/meal_rec.dart';
import 'package:nutrilink/meal/cart_page.dart';
import 'package:intl/intl.dart';

// Local color constants to match homepage styling (do not import homepage.dart to avoid circular dependency)
const Color kGreen = Color(0xFF75C778); // from HomePage: Color.fromRGBO(117,199,120,1)
const Color kGreenLight = Color(0xFF7BB662);
const Color kGreyText = Color(0xFF494949);

// Inilah layar utama untuk fitur Rekomendasi Makanan
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  Set<String> _selectedFilters = {};
  MealRecommendationResult? _recommendationResult;
  MealRecommendationResult? _fullRecommendationResult;
  bool _isLoading = true;
  String? _errorMessage;
  // User allergies cache (used to filter tags shown)
  Set<String> _userAllergies = {};

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  /// Load rekomendasi dari Firebase
  Future<void> _loadRecommendations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User tidak terautentikasi';
          _isLoading = false;
        });
        return;
      }

      // Ambil user profile dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'Profil pengguna tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};

      // Ambil data yang diperlukan
      final allergies = List<String>.from(profile['allergies'] as List? ?? []);
      // Cache user allergies in state for tag filtering
      _userAllergies = Set<String>.from(allergies.map((e) => e.toString().toLowerCase()));
      final heightCm = (profile['heightCm'] as num?)?.toDouble() ?? 170;
      final weightKg = (profile['weightKg'] as num?)?.toDouble() ?? 70;
      final sex = profile['sex'] as String? ?? 'Laki-laki';
      final birthDate = (profile['birthDate'] as Timestamp?)?.toDate();
      final activityLevel = profile['activityLevel'] as String? ?? 'lightly_active';
      final target = profile['target'] as String? ?? 'Mempertahankan berat badan';

      // Hitung TDEE
      final tdee = _calculateTDEE(
        weightKg: weightKg,
        heightCm: heightCm,
        sex: sex,
        age: birthDate != null ? DateTime.now().year - birthDate.year : 25,
        activityLevel: activityLevel,
      );

      debugPrint('📊 User TDEE calculated: $tdee');
      debugPrint('🚨 User allergies: $allergies');
      debugPrint('🎯 User target: $target');

      // Get rekomendasi
      final recommendations = await MealRecommendationEngine.getRecommendations(
        userId: user.uid,
        allergies: allergies,
        tdee: tdee,
        target: target,
      );

      final result = MealRecommendationResult.fromMap(recommendations);

      // Keep a copy of the full result so we can apply tag filters locally
      _fullRecommendationResult = result;

      setState(() {
        _isLoading = false;
      });

      // Apply any active tag filters to immediately filter displayed lists
      _applyTagFilters();
    } catch (e) {
      debugPrint('❌ Error loading recommendations: $e');
      setState(() {
        _errorMessage = 'Gagal memuat rekomendasi: $e';
        _isLoading = false;
      });
    }
  }

  void _applyTagFilters() {
    if (_fullRecommendationResult == null) return;

    if (_selectedFilters.isEmpty) {
      setState(() {
        _recommendationResult = _fullRecommendationResult;
      });
      return;
    }

    // Helper to check if an item contains any of selected tags
    bool matchesTags(Map<String, dynamic> item) {
      final tagsRaw = item['tags'];
      final List<String> tags = [];
      if (tagsRaw is String) {
        tags.addAll(tagsRaw.split(',').map((s) => s.trim()));
      } else if (tagsRaw is List) {
        tags.addAll(tagsRaw.map((e) => e.toString()));
      }
      // also check tag1/tag2/tag3 fields
      for (var k in ['tag1', 'tag2', 'tag3']) {
        final v = item[k];
        if (v is String && v.isNotEmpty) tags.add(v.trim());
      }

      final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
      for (final f in _selectedFilters) {
        if (lowerTags.any((t) => t.contains(f.toLowerCase()))) return true;
      }
      return false;
    }

    List<Map<String, dynamic>> filterList(List<Map<String, dynamic>> list) {
      return list.where((it) => matchesTags(it)).toList();
    }

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

  /// Hitung TDEE (copy dari firebase_service.dart)
  double _calculateTDEE({
    required double weightKg,
    required double heightCm,
    required String sex,
    required int age,
    required String activityLevel,
  }) {
    // Hitung BMR menggunakan Mifflin-St Jeor
    double bmr;
    if (sex == 'Laki-laki' || sex == 'Male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    // Hitung TDEE dengan activity multiplier
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
            setState(() {
              _selectedFilters = newFilters;
            });
            // Apply tag filters locally without re-fetching
            _applyTagFilters();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
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
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Profil Pengguna dan Target
            _UserProfileHeader(onFilterPressed: () => _showFilter(context)),
            const SizedBox(height: 16),
            // 2. Filter Tag yang Aktif
            _TagFilterSection(selectedFilters: _selectedFilters, onFilterPressed: () => _showFilter(context)),
            const SizedBox(height: 16),

            // 4. Daftar Rekomendasi Makanan - Sarapan
            if (_recommendationResult != null)
              _FoodRecommendationList(
                title: 'Sarapan',
                items: _recommendationResult!.sarapan,
                userAllergies: _userAllergies,
              ),
            // 5. Daftar Rekomendasi Makanan - Makan Siang
            if (_recommendationResult != null)
              _FoodRecommendationList(
                title: 'Makan Siang',
                items: _recommendationResult!.makanSiang,
                userAllergies: _userAllergies,
              ),
            // 6. Daftar Rekomendasi Makanan - Makan Malam
            if (_recommendationResult != null)
              _FoodRecommendationList(
                title: 'Makan Malam',
                items: _recommendationResult!.makanMalam,
                userAllergies: _userAllergies,
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              ).then((_) => setState(() {})); // Refresh when returning from cart
            },
            backgroundColor: const Color(0xFFE57373),
            shape: const CircleBorder(),
            child: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          if (CartManager.getItemCount() > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '${CartManager.getItemCount()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// --- Semua Widget Pendukung Lainnya ---

class _UserProfileHeader extends StatelessWidget {
  final VoidCallback onFilterPressed;
  const _UserProfileHeader({required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    // ... (Implementasi Row, CircleAvatar, Text, dan Icon yang sama)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header left intentionally minimal; Tag filter icon moved into TagFilterSection
          // to align with the "Tag Filter" label as requested.
        ],
      ),
    );
  }
}

class _TagFilterSection extends StatelessWidget {
  final Set<String> selectedFilters;
  final VoidCallback onFilterPressed;

  const _TagFilterSection({required this.selectedFilters, required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    final List<String> activeTags = selectedFilters.toList();
    // Show filter icon inline with the label. Icon and label change color when filters active.
    final Color headerColor = selectedFilters.isNotEmpty ? kGreen : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onFilterPressed,
                child: Icon(Icons.filter_list, color: headerColor, size: 22),
              ),
              const SizedBox(width: 8),
              Text(
                'Tag Filter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: headerColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: activeTags.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Chip(
                  label: Text(activeTags[index]),
                  backgroundColor: const Color(0xFFC8E6C9),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FoodRecommendationList extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Set<String> userAllergies;

  const _FoodRecommendationList({required this.title, required this.items, required this.userAllergies});

  @override
  State<_FoodRecommendationList> createState() => _FoodRecommendationListState();
}

class _FoodRecommendationListState extends State<_FoodRecommendationList> {
  int _currentPage = 0;
  static const int _itemsPerPage = 3; // Show 3 items per expansion
  
  // Track recently shown items for variety
  static final Map<String, Set<String>> _recentlyShown = {};
  static const int _maxRecentItems = 9; // Track last 9 shown per meal type

  @override
  void initState() {
    super.initState();
    // Initialize recent tracking for this meal type
    _recentlyShown[widget.title] ??= <String>{};
  }

  List<Map<String, dynamic>> _getVariedItems() {
    final recentSet = _recentlyShown[widget.title]!;
    final items = List<Map<String, dynamic>>.from(widget.items);
    
    // Sort: non-recent items first, then by personal score if available
    items.sort((a, b) {
      final aRecent = recentSet.contains(a['docId']) ? 1 : 0;
      final bRecent = recentSet.contains(b['docId']) ? 1 : 0;
      
      if (aRecent != bRecent) return aRecent.compareTo(bRecent);
      
      // If both recent or both new, sort by personal score if available
      final aScore = (a['personalScore'] as double?) ?? 50.0;
      final bScore = (b['personalScore'] as double?) ?? 50.0;
      return bScore.compareTo(aScore);
    });
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final variedItems = _getVariedItems();
    final maxItems = (_currentPage + 1) * _itemsPerPage;
    final displayItems = variedItems.take(maxItems).toList();
    final hasMore = variedItems.length > maxItems;
    
    // Track shown items for variety
    final recentSet = _recentlyShown[widget.title]!;
    for (var item in displayItems) {
      recentSet.add(item['docId'] ?? '');
    }
    
    // Keep recent list manageable
    if (recentSet.length > _maxRecentItems) {
      final excess = recentSet.length - _maxRecentItems;
      final toRemove = recentSet.take(excess).toList();
      recentSet.removeAll(toRemove);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        SizedBox(
          height: 286,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: displayItems.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (hasMore && index == displayItems.length) {
                return _ExpandButton(
                  onTap: () => setState(() => _currentPage++),
                  remainingCount: variedItems.length - displayItems.length,
                );
              }
              final item = displayItems[index];
              return _FoodCard(item: item, userAllergies: widget.userAllergies);
            },
          ),
        ),
      ],
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final VoidCallback onTap;
  final int remainingCount;

  const _ExpandButton({required this.onTap, required this.remainingCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward, size: 40, color: Color(0xFF5F9C3F)),
              const SizedBox(height: 12),
              Text(
                '+$remainingCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lainnya',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Set<String> userAllergies;

  const _FoodCard({required this.item, required this.userAllergies});

  @override
  Widget build(BuildContext context) {
    // Handle tags dari berbagai format (String atau List)
    final tagsRaw = item['tags'];
    final List<String> tags = [];
    if (tagsRaw is String) {
      tags.addAll(tagsRaw.split(', '));
    } else if (tagsRaw is List) {
      tags.addAll(tagsRaw.map((e) => e.toString()));
    }

    // Filter tags: jangan tampilkan tag yang user alergi
    final displayTags = tags.where((t) {
      final tagLower = t.toString().toLowerCase();
      return !userAllergies.any((a) => tagLower.contains(a.toString().toLowerCase()) || a.toString().toLowerCase().contains(tagLower));
    }).toList();

    final name = item['name'] as String? ?? 'Unknown';
    final calories = item['calories'] as num? ?? 0;
    final priceRaw = item['price'];
    // format price as `Rp xx.xxx` and color it green like homepage
    String formatRupiah(dynamic v) {
      if (v == null) return 'N/A';
      if (v is num) {
        // use intl formatter for id locale
        try {
          final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          return fmt.format(v.toInt());
        } catch (_) {
          final n = v.toInt();
          return 'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
        }
      }
      return v.toString();
    }
    final price = formatRupiah(priceRaw);
    final imageUrl = item['imageUrl'] as String? ?? '';
    final firstTag = displayTags.isNotEmpty ? displayTags[0] : '';

    return GestureDetector(
      onTap: () {
        // Debug: print the item passed to the popup so we can verify fields
        debugPrint('🔎 Opening detail popup for item: ${item.toString()}');
        // Pass the full item map so the popup can display all fields
        // and optionally fetch/update from Firestore if needed.
        showFoodDetailPopup(context, Map<String, dynamic>.from(item));
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE + TAG
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  children: [
                    _buildMealImage(imageUrl),
                    // TAG (top-left)
                    if (firstTag.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kGreenLight, kGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            firstTag,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
                    // TEXT CONTENT
              Padding(
                // match homepage card padding (slightly more breathing room)
                padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Calories
                    Text(
                      '${calories.toInt()} kkal',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                    ),
                    const SizedBox(height: 2),
                    // Price (green, formatted)
                    Text(
                      price,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: kGreen,
                        ),
                    ),
                    const SizedBox(height: 6),
                    // Small tag row (show up to 3 tags that are not allergen)
                    if (displayTags.isNotEmpty)
                      SizedBox(
                        height: 18,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayTags.length > 3 ? 3 : displayTags.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                displayTags[i],
                                style: const TextStyle(fontSize: 9, color: Colors.black87),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build meal image with fallback handling
  Widget _buildMealImage(String imageUrl) {
    final name = item['name'] as String? ?? 'Unknown';
    
    // If image URL provided from Firebase, use it
    if (imageUrl.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 1.0, // 1:1 ratio
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 480,
          cacheHeight: 480,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: Center(
                    child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                    color: kGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(name),
        ),
      );
    }
    
    // Fallback: show placeholder
    return _buildFallbackImage(name);
  }
  
  /// Build fallback image when network fails
  Widget _buildFallbackImage(String name) {
    return AspectRatio(
      aspectRatio: 1.0, // 1:1 ratio
      child: Container(
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.restaurant, size: 30, color: Colors.grey[400]),
        ),
      ),
    );
  }
}

