import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final cartItems = CartManager.getCartItems();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Keranjang kosong',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tambahkan menu dari halaman rekomendasi',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _buildCartSections(cartItems),
            ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatPrice(CartManager.getTotalPrice()),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF75C778),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showCheckoutConfirmation(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF75C778),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  List<Widget> _buildCartSections(Map<String, Map<String, CartItem>> cartItems) {
    final widgets = <Widget>[];
    final sortedDates = cartItems.keys.toList()..sort();

    for (int i = 0; i < sortedDates.length; i++) {
      final dateKey = sortedDates[i];
      final dateItems = cartItems[dateKey]!;
      final date = DateTime.parse(dateKey);
      
      // Date header
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Text(
            DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF75C778),
            ),
          ),
        ),
      );

      // Meal sections for this date
      for (final mealType in ['Sarapan', 'Makan Siang', 'Makan Malam']) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Text(
              mealType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        );

        final item = dateItems[mealType];
        if (item != null) {
          widgets.add(_buildCartItemCard(item, dateKey, mealType));
        } else {
          widgets.add(
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade300,
            ),
          );
        }

        widgets.add(const SizedBox(height: 12));
      }

      // Add spacing between dates
      if (i < sortedDates.length - 1) {
        widgets.add(const SizedBox(height: 24));
      }
    }

    return widgets;
  }

  Widget _buildCartItemCard(CartItem item, String dateKey, String mealType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          // Menu details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.calories} kkal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF75C778),
                  ),
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            onPressed: () => _showRemoveConfirmation(dateKey, mealType, item.name),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(String dateKey, String mealType, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Apakah Anda yakin ingin menghapus "$itemName" dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              CartManager.removeItem(dateKey, mealType);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item dihapus dari keranjang')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutConfirmation() {
    final totalPrice = CartManager.getTotalPrice();
    final itemCount = CartManager.getItemCount();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total item: $itemCount menu'),
            const SizedBox(height: 8),
            Text(
              'Total harga: ${_formatPrice(totalPrice)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF75C778),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan akan dikirim sesuai dengan tanggal dan waktu makan yang dipilih.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _processCheckout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF75C778),
            ),
            child: const Text(
              'Konfirmasi Pesanan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _processCheckout() {
    // Close confirmation dialog
    Navigator.pop(context);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pesanan berhasil dibuat! Tim kami akan menghubungi Anda segera.'),
        backgroundColor: Color(0xFF75C778),
        duration: Duration(seconds: 3),
      ),
    );

    // Clear cart after successful order
    CartManager.clearCart();
    
    // Refresh the page
    setState(() {});
    
    // Navigate back to previous screen
    Navigator.pop(context);
  }

  String _formatPrice(num price) {
    try {
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return fmt.format(price.toInt());
    } catch (_) {
      return 'Rp ${price.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
    }
  }
}

// Cart item model
class CartItem {
  final String name;
  final num price;
  final num calories;
  final String imageUrl;
  final Map<String, dynamic> fullData;

  CartItem({
    required this.name,
    required this.price,
    required this.calories,
    required this.imageUrl,
    required this.fullData,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'calories': calories,
    'imageUrl': imageUrl,
    'fullData': fullData,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    name: json['name'] ?? '',
    price: json['price'] ?? 0,
    calories: json['calories'] ?? 0,
    imageUrl: json['imageUrl'] ?? '',
    fullData: json['fullData'] ?? {},
  );
}

// Cart manager for state management
class CartManager {
  static final Map<String, Map<String, CartItem>> _cartItems = {};

  static Map<String, Map<String, CartItem>> getCartItems() => _cartItems;

  static Future<bool> addItem(String dateKey, String mealType, CartItem item) async {
    // Check if item already exists for this date and meal type
    if (_cartItems[dateKey]?[mealType] != null) {
      // Item exists, return false to show confirmation dialog
      return false;
    }

    // Add item to cart
    _cartItems[dateKey] ??= {};
    _cartItems[dateKey]![mealType] = item;
    return true;
  }

  static void replaceItem(String dateKey, String mealType, CartItem item) {
    _cartItems[dateKey] ??= {};
    _cartItems[dateKey]![mealType] = item;
  }

  static void removeItem(String dateKey, String mealType) {
    _cartItems[dateKey]?.remove(mealType);
    if (_cartItems[dateKey]?.isEmpty == true) {
      _cartItems.remove(dateKey);
    }
  }

  static num getTotalPrice() {
    num total = 0;
    for (final dateItems in _cartItems.values) {
      for (final item in dateItems.values) {
        total += item.price;
      }
    }
    return total;
  }

  static int getItemCount() {
    int count = 0;
    for (final dateItems in _cartItems.values) {
      count += dateItems.length;
    }
    return count;
  }

  static void clearCart() {
    _cartItems.clear();
  }
}