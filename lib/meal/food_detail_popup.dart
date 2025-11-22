import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutrilink/meal/cart_page.dart';

// Color constant to match app theme
const Color kGreen = Color(0xFF75C778);

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

      // Resolve image URL: prefer `imageUrl` (already a download URL), otherwise try to resolve `image` filename
      final imageField = _item['imageUrl'] ?? _item['image'];
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-width image (no left/right padding), 1:1, top corners rounded only
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _resolvedImageUrl != null && _resolvedImageUrl!.isNotEmpty
                    ? Image.network(
                        _resolvedImageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (c, e, st) => Container(
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.broken_image, color: Colors.grey[400])),
                        ),
                      )
                    : Image.network(
                        'https://placehold.co/600x600?text=${Uri.encodeComponent(item['name']?.toString() ?? '')}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['name']?.toString() ?? 'Nama tidak tersedia',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    calText.isNotEmpty ? calText : '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Tags (first tag green, others grey)
                  Wrap(
                    spacing: 6,
                    children: List.generate(tags.length, (i) {
                      final tag = tags[i];
                      final Color color = i == 0 ? Colors.green : Colors.grey;
                      return Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: color,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Kandungan Nutrisi
                  const Text(
                    'Kandungan Nutrisi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _NutrisiCard(
                        label: 'Protein',
                        value: proteinDisplay,
                        color: Colors.blueAccent,
                      ),
                      _NutrisiCard(
                        label: 'Karbohidrat',
                        value: carbsDisplay,
                        color: const Color(0xFFFCBA03), // #FCBA03
                      ),
                      _NutrisiCard(
                        label: 'Lemak',
                        value: fatsDisplay,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Harga + tombol keranjang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceText.isNotEmpty ? priceText : 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Color(0xFF75C778), // match recommendation card green
                            ),
                          ),
                          const Text(
                            'Sudah termasuk ongkir',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Use the passed date and meal type, or fallback to calendar if not provided
                          if (widget.selectedDate != null && widget.mealType != null) {
                            // Auto-detected meal type from recommendation page
                            await _addToCart(context, widget.selectedDate!, widget.mealType!, _item);
                          } else {
                            // Fallback: show calendar picker (for other entry points)
                            _showCalendarPopup(context, _item);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(14),
                        ),
                        child: const Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  if (_loading) const SizedBox(height: 8),
                  if (_loading) const LinearProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutrisiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrisiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
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
  
  final cartItem = CartItem(
    name: menuItem['name']?.toString() ?? 'Unknown',
    price: menuItem['price'] ?? 0,
    calories: menuItem['calories'] ?? 0,
    imageUrl: menuItem['imageUrl']?.toString() ?? '',
    fullData: menuItem,
  );

  final success = await CartManager.addItem(dateKey, mealType, cartItem);
  
  if (!success) {
    // Item already exists, show confirmation dialog
    if (context.mounted) {
      _showReplaceConfirmation(context, date, mealType, cartItem, dateKey);
    }
  } else {
    // Item added successfully - check if this violates meal frequency
    final eatFrequency = await CartManager.getUserEatFrequency();
    final currentMealsForDate = CartManager.getCartItems()[dateKey]?.length ?? 0;
    
    if (context.mounted) {
      if (currentMealsForDate > eatFrequency) {
        // Remove the just-added item since it violates frequency
        CartManager.removeItem(dateKey, mealType);
        
        // Show frequency limit warning
        _showFrequencyLimitDialog(context, date, eatFrequency, currentMealsForDate - 1);
      } else {
        // Show success dialog
        _showSuccessDialog(context, cartItem.name, eatFrequency, currentMealsForDate);
      }
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
                      color: kGreen,
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
                color: currentMeals >= eatFrequency ? Colors.orange.shade50 : kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: currentMeals >= eatFrequency ? Colors.orange : kGreen,
                  width: 1.5,
                ),
              ),
              child: Text(
                '$currentMeals / $eatFrequency menu hari ini',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentMeals >= eatFrequency ? Colors.orange.shade700 : kGreen,
                ),
              ),
            ),
            if (currentMeals >= eatFrequency) ...[
              const SizedBox(height: 8),
              Text(
                'Anda sudah mencapai batas frekuensi makan untuk tanggal ini',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
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
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Batas Frekuensi Makan',
              style: TextStyle(fontSize: 18),
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
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frekuensi makan Anda: $eatFrequency kali per hari',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
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
          child: const Text('Mengerti'),
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
      title: const Text('Ganti Menu?'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kamu sudah memilih menu untuk $mealType pada $formattedDate:',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: existingItem.imageUrl.isNotEmpty
                        ? Image.network(
                            existingItem.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.restaurant, size: 20, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingItem.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${existingItem.calories} kkal • ${formatPrice(existingItem.price)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            CartManager.replaceItem(dateKey, mealType, newItem);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Menu $mealType untuk $formattedDate berhasil diganti'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('Ganti Menu', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
