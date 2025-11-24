import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nutrilink/features/meal/cartPage.dart';
import 'package:nutrilink/pages/main/homePage.dart';
import 'package:nutrilink/services/orderService.dart';
import 'package:nutrilink/config/appTheme.dart';

void showFoodDetailPopup(
  BuildContext context,
  Map<String, dynamic> item, {
  DateTime? selectedDate,
  String? mealType,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => _FoodDetailContent(
      item: item,
      selectedDate: selectedDate,
      mealType: mealType,
    ),
  );
}

class _FoodDetailContent extends StatefulWidget {
  final Map<String, dynamic> item;
  final DateTime? selectedDate;
  final String? mealType;

  const _FoodDetailContent({required this.item, this.selectedDate, this.mealType});

  @override
  State<_FoodDetailContent> createState() => _FoodDetailContentState();
}

class _FoodDetailContentState extends State<_FoodDetailContent> {
  late Map<String, dynamic> _item;
  String? _resolvedImageUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _loadFullData();
  }

  Future<void> _loadFullData() async {
    setState(() => _loading = true);

    try {
      // If an `id` is available and other fields are missing, try to fetch fresh data
      // Prefer fetching by Firestore document id if available (stored earlier as 'docId')
      final docId = _item['docId'] as String?;
      if (docId != null && docId.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance.collection('menus').doc(docId).get();
          if (doc.exists) {
            try {
              try {
                _item.addAll(Map<String, dynamic>.from(doc.data() as Map));
              } catch (_) {
                // ignore structure mismatch or null
              }
            } catch (_) {
              // ignore if the doc data is unexpected or null
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to fetch menu by docId $docId: $e');
        }
      } else {
        final idVal = _item['id'];
        if (idVal != null) {
          try {
            final q = await FirebaseFirestore.instance
                .collection('menus')
                .where('id', isEqualTo: idVal)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              try {
                try {
                  _item.addAll(Map<String, dynamic>.from(q.docs.first.data() as Map));
                } catch (_) {
                  // ignore unexpected structure or null
                }
              } catch (_) {
                // ignore unexpected structure
              }
            }
          } catch (e) {
            debugPrint('⚠️ Failed to fetch menu by id $idVal: $e');
          }
        }
      }

      // Resolve image URL from 'image' field (either filename or full URL)
      final imageField = _item['image'];
      debugPrint('ℹ️ Popup loading menu: name=${_item['name']}, imageField=$imageField, tags=${_item['tags']}');
      if (imageField != null && imageField is String && imageField.isNotEmpty) {
        if (imageField.startsWith('http')) {
          _resolvedImageUrl = imageField;
        } else {
          // try to resolve from Firebase Storage under `menus/<filename>`
          try {
            final ref = FirebaseStorage.instance.ref().child('menus').child(imageField);
            final url = await ref.getDownloadURL();
            _resolvedImageUrl = url;
          } catch (_) {
            // leave null; UI will show placeholder
            _resolvedImageUrl = null;
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item; // local alias

    // parse tags from possible formats (String or List)
    final tagsRaw = item['tags'];
    List<String> tags = [];
    if (tagsRaw is String) {
      tags = tagsRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (tagsRaw is List) {
      tags = tagsRaw.map((e) => e.toString()).toList();
    }

    // calories display
    String calText = '';
    if (item['cal'] != null) {
      calText = item['cal'].toString();
    } else if (item['calories'] != null) {
      final c = item['calories'];
      if (c is num) {
        calText = '${c.toInt()} kkal';
      } else {
        calText = c.toString();
      }
    }

    // price formatting: use Indonesian format `Rp xx.xxx`
    String priceText = '';
    final priceRaw = item['price'];
    String formatRupiah(dynamic v) {
      if (v == null) return 'N/A';
      if (v is num) {
        try {
          final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          return fmt.format(v.toInt());
        } catch (_) {
          final n = v.toInt();
          return 'Rp ${n.toString().replaceAllMapped(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), (m) => '.')}';
        }
      }
      return v.toString();
    }

    priceText = formatRupiah(priceRaw);

    // nutrients - try to read numeric values, fallback to placeholders
    String fmtGram(dynamic v) {
      if (v == null) return '—';
      if (v is num) return '${v.toInt()}g';
      final parsed = double.tryParse(v.toString());
      if (parsed != null) return '${parsed.toInt()}g';
      return v.toString();
    }

    final proteinDisplay = fmtGram(item['protein'] ?? item['proteinGrams']);
    final carbsDisplay = fmtGram(item['carbohydrate'] ?? item['carbs'] ?? item['carbsGrams']);
    final fatsDisplay = fmtGram(item['fat'] ?? item['fats'] ?? item['fatsGrams']);

    final description = item['description'] as String? ?? 'Deskripsi tidak tersedia untuk menu ini.';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Fixed image with back button overlay (not scrollable)
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _resolvedImageUrl != null && _resolvedImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _resolvedImageUrl!,
                          cacheKey: _resolvedImageUrl!.split('?').first.split('/').last,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheWidth: 600,
                          memCacheHeight: 600,
                          maxWidthDiskCache: 600,
                          maxHeightDiskCache: 600,
                          fadeInDuration: const Duration(milliseconds: 200),
                          errorListener: (error) {
                            debugPrint('Image cache error (suppressed): $error');
                          },
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (c, url, e) => Container(
                            color: Colors.grey[200],
                            child: Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400])),
                        ),
                ),
              ),
              // Back button overlay
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
          
          // Scrollable content below image
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Name and calories
                    Text(
                      item['name']?.toString() ?? 'Nama tidak tersedia',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 12),
                    
                    // Tags with gradient green for all - tappable to filter
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            // Clear semua navigation stack sampai root
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            
                            // Push fresh HomePage dengan tag filter (replace root)
                            // Gunakan unique key untuk force rebuild RecommendationScreen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(
                                  key: ValueKey('filter_$tag'),
                                  initialTabIndex: 1,
                                  initialFilter: tag,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.greenLight, AppColors.green],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Kandungan Nutrisi heading with calories on the same row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Kandungan Nutrisi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          calText.isNotEmpty ? calText : '—',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _NutrientIconCard(
                            icon: Icons.fitness_center,
                            label: 'Protein',
                            value: proteinDisplay,
                          ),
                          _NutrientIconCard(
                            icon: Icons.rice_bowl,
                            label: 'Karbo',
                            value: carbsDisplay,
                          ),
                          _NutrientIconCard(
                            icon: Icons.water_drop,
                            label: 'Lemak',
                            value: fatsDisplay,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    Text(
                      description,
                      style: const TextStyle(color: Colors.black87, height: 1.4, fontSize: 14),
                      textAlign: TextAlign.justify,
                    ),
                    // Bottom padding to prevent content hidden by fixed footer
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 120),
                  ],
                ),
              ),
            ),
            
            // Fixed footer at bottom with price and cart button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  28,
                  16,
                  28,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            priceText.isNotEmpty ? priceText : 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: AppColors.green,
                            ),
                          ),
                          const Text(
                            'Sudah termasuk ongkir',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.greenLight, AppColors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        iconSize: 24,
                        padding: const EdgeInsets.all(14),
                        onPressed: () async {
                          if (widget.selectedDate != null && widget.mealType != null) {
                            await _addToCart(context, widget.selectedDate!, widget.mealType!, _item);
                          } else {
                            _showCalendarPopup(context, _item);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_loading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.green, AppColors.greenLight, AppColors.green],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: const LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                    backgroundColor: Colors.transparent,
                  ),
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

class _NutrientIconCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NutrientIconCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.green),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _detectMealType(Map<String, dynamic> menuItem) {
  // Get meal type directly from database 'type' field
  final type = menuItem['type'];
  if (type != null && type is String && type.isNotEmpty) {
    // Ensure consistent format
    final normalizedType = type.trim();
    if (normalizedType == 'Sarapan' || normalizedType == 'Makan Siang' || normalizedType == 'Makan Malam') {
      return normalizedType;
    }
  }
  
  // Fallback - show manual selection if type field is not available
  return '';
}

void _showCalendarPopup(BuildContext context, Map<String, dynamic> menuItem) async {
  // For meal prep, users can only select from tomorrow onwards
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: tomorrow,
    firstDate: tomorrow,
    lastDate: DateTime.now().add(const Duration(days: 30)),
    builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.green,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null && context.mounted) {
    // Try to auto-detect meal type
    final detectedMealType = _detectMealType(menuItem);
    
    if (detectedMealType.isNotEmpty) {
      // Auto-detected, add directly to cart
      await _addToCart(context, picked, detectedMealType, menuItem);
    } else {
      // Can't detect, show manual selection
      _showMealTypeSelection(context, picked, menuItem);
    }
  }
}

void _showMealTypeSelection(BuildContext context, DateTime selectedDate, Map<String, dynamic> menuItem) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Waktu Makan',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(selectedDate),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ...['Sarapan', 'Makan Siang', 'Makan Malam'].map((mealType) => 
            ListTile(
              leading: Icon(
                mealType == 'Sarapan' ? Icons.wb_sunny :
                mealType == 'Makan Siang' ? Icons.wb_sunny_outlined :
                Icons.nights_stay,
                color: const Color(0xFF75C778),
              ),
              title: Text(mealType),
              onTap: () async {
                Navigator.pop(context);
                await _addToCart(context, selectedDate, mealType, menuItem);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

Future<void> _addToCart(BuildContext context, DateTime date, String mealType, Map<String, dynamic> menuItem) async {
  final dateKey = DateFormat('yyyy-MM-dd').format(date);
  
  // VALIDASI FREKUENSI MAKAN SEBELUM ADD TO CART
  final eatFrequency = await CartManager.getUserEatFrequency();
  
  // Cek meals yang sudah ordered (di schedule)
  final orderedMeals = await OrderService.checkOrderedMeals(date);
  final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
  
  // Cek meals yang sudah di cart
  final cartItems = CartManager.getCartItems();
  final cartMealsCount = cartItems[dateKey]?.length ?? 0;
  
  // Total meals = ordered + cart
  final totalMeals = orderedMealsCount + cartMealsCount;
  
  debugPrint('🔍 Add to cart validation: Date=$dateKey, Ordered=$orderedMealsCount, Cart=$cartMealsCount, Total=$totalMeals, Limit=$eatFrequency');
  
  // Jika sudah mencapai limit, tolak add to cart
  if (totalMeals >= eatFrequency) {
    if (context.mounted) {
      _showFrequencyLimitDialog(context, date, eatFrequency, totalMeals);
    }
    return;
  }
  
  final cartItem = CartItem(
    name: menuItem['name']?.toString() ?? 'Unknown',
    price: menuItem['price'] ?? 0,
    calories: menuItem['calories'] ?? 0,
    imageUrl: menuItem['image']?.toString() ?? '',
    fullData: menuItem,
  );

  // Check if cart is full
  if (CartManager.getItemCount() >= CartManager.maxCartItems && CartManager.getCartItems()[dateKey]?[mealType] == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keranjang penuh! Maksimal ${CartManager.maxCartItems} item. Hapus beberapa item terlebih dahulu.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return;
  }

  final success = await CartManager.addItem(dateKey, mealType, cartItem);
  
  if (!success) {
    // Item already exists, show confirmation dialog
    if (context.mounted) {
      _showReplaceConfirmation(context, date, mealType, cartItem, dateKey);
    }
  } else {
    // Item added successfully - show success
    final currentMealsForDate = CartManager.getCartItems()[dateKey]?.length ?? 0;
    
    if (context.mounted) {
      // Show success dialog
      _showSuccessDialog(context, cartItem.name, eatFrequency, currentMealsForDate);
    }
  }
}

void _showSuccessDialog(BuildContext context, String itemName, int eatFrequency, int currentMeals) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated checkmark
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Berhasil Ditambahkan!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Meal frequency indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: currentMeals >= eatFrequency 
                  ? LinearGradient(
                      colors: [AppColors.green.withValues(alpha:0.15), AppColors.greenLight.withValues(alpha:0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [AppColors.green.withValues(alpha:0.1), AppColors.greenLight.withValues(alpha:0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.green,
                  width: 1.5,
                ),
              ),
              child: Text(
                '$currentMeals / $eatFrequency menu hari ini',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ),
            if (currentMeals >= eatFrequency) ...[
              const SizedBox(height: 8),
              const Text(
                'Anda sudah mencapai batas frekuensi makan untuk tanggal ini',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.green,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  );
  
  // Auto close after 1.5 seconds
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  });
}

void _showFrequencyLimitDialog(BuildContext context, DateTime date, int eatFrequency, int currentMeals) {
  final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Batas Frekuensi Makan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anda sudah memilih $currentMeals menu untuk tanggal $formattedDate.',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green.withValues(alpha:0.1), AppColors.greenLight.withValues(alpha:0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withValues(alpha:0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Frekuensi makan Anda: $eatFrequency kali per hari',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Silakan hapus salah satu menu dari keranjang jika ingin menambahkan menu ini.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

void _showReplaceConfirmation(BuildContext context, DateTime date, String mealType, CartItem newItem, String dateKey) {
  final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);
  final existingItem = CartManager.getCartItems()[dateKey]?[mealType];
  
  if (existingItem == null) return;

  // Format price function
  String formatPrice(num price) {
    try {
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return fmt.format(price.toInt());
    } catch (_) {
      return 'Rp ${price.toInt().toString().replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (m) => '.')}';
    }
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ganti Menu?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.greyText),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kamu sudah memilih menu untuk $mealType pada $formattedDate:',
              style: const TextStyle(fontSize: 14, color: AppColors.lightGreyText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green.withValues(alpha: 0.1), AppColors.greenLight.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: existingItem.imageUrl.isNotEmpty
                        ? Image.network(
                            existingItem.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.fastfood, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingItem.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.greyText),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${existingItem.calories} kkal • ${formatPrice(existingItem.price)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightGreyText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apakah kamu ingin menggantinya dengan menu yang baru dipilih?',
              style: TextStyle(fontSize: 14, color: AppColors.greyText),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text('Batal', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ),
        ElevatedButton(
          onPressed: () async {
            await CartManager.replaceItem(dateKey, mealType, newItem);
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Menu berhasil diganti!'),
                backgroundColor: AppColors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green, AppColors.greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Text('Ganti Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    ),
  );
}
