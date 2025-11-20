import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nutrilink/meal/cart_page.dart';

void showFoodDetailPopup(BuildContext context, Map<String, dynamic> item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => _FoodDetailContent(item: item),
  );
}

class _FoodDetailContent extends StatefulWidget {
  final Map<String, dynamic> item;

  const _FoodDetailContent({required this.item});

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
                        onPressed: () => _showCalendarPopup(context, _item),
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
    // Item added successfully
    if (context.mounted) {
      final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cartItem.name} ditambahkan ke keranjang untuk $mealType, $formattedDate'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
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
