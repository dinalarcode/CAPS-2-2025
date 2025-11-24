import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutrilink/services/orderService.dart';
import 'package:nutrilink/services/scheduleService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrilink/pages/main/homePage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilink/utils/storageHelper.dart';
import 'dart:convert';
import 'package:nutrilink/config/appTheme.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String location = 'Memuat lokasi...';

  @override
  void initState() {
    super.initState();
    _loadCart();
    _getCurrentLocation();
  }

  Future<void> _loadCart() async {
    await CartManager.loadCart();
    if (mounted) setState(() {});
  }

  // Daftar kota yang diizinkan menggunakan aplikasi
  static const List<String> _allowedCities = [
    'Jakarta', 'Depok', 'Bogor', 'Tangerang', 'Bekasi', 'Surabaya',
    'Bandung', 'Pekanbaru', 'Medan', 'Palembang', 'Malang', 'Lampung',
    'Yogyakarta', 'Pontianak', 'Solo', 'Semarang', 'Makassar', 'Manado',
    'Bali', 'Batam', 'Balikpapan', 'Samarinda', 'Banjarmasin', 'Lombok',
    // Variations
    'DKI Jakarta', 'Kota Jakarta', 'South Jakarta', 'North Jakarta', 
    'East Jakarta', 'West Jakarta', 'Central Jakarta',
    'Kota Surabaya', 'Kota Bandung', 'Kota Medan', 'Kota Semarang',
    'Denpasar', 'Kota Denpasar', 'Badung',
    'Surakarta', 'Kota Surakarta',
    'Kota Yogyakarta', 'Sleman', 'Bantul',
    'Kota Malang', 'Kota Pontianak', 'Kota Balikpapan',
    'Kota Samarinda', 'Kota Banjarmasin', 'Kota Makassar',
    'Kota Manado', 'Kota Batam', 'Kota Pekanbaru',
    'Kota Palembang', 'Kota Lampung', 'Bandar Lampung',
    'Mataram', 'Kota Mataram',
  ];

  // Translate province names dari English ke Bahasa Indonesia
  String _translateProvince(String province) {
    final translations = {
      'East Java': 'Jawa Timur',
      'West Java': 'Jawa Barat',
      'Central Java': 'Jawa Tengah',
      'Special Region of Yogyakarta': 'DI Yogyakarta',
      'DI Yogyakarta': 'DI Yogyakarta',
      'Jakarta': 'DKI Jakarta',
      'DKI Jakarta': 'DKI Jakarta',
      'Banten': 'Banten',
      'North Sumatra': 'Sumatera Utara',
      'West Sumatra': 'Sumatera Barat',
      'South Sumatra': 'Sumatera Selatan',
      'Riau': 'Riau',
      'Riau Islands': 'Kepulauan Riau',
      'Lampung': 'Lampung',
      'Bali': 'Bali',
      'West Kalimantan': 'Kalimantan Barat',
      'East Kalimantan': 'Kalimantan Timur',
      'South Kalimantan': 'Kalimantan Selatan',
      'North Kalimantan': 'Kalimantan Utara',
      'Central Kalimantan': 'Kalimantan Tengah',
      'South Sulawesi': 'Sulawesi Selatan',
      'North Sulawesi': 'Sulawesi Utara',
      'Central Sulawesi': 'Sulawesi Tengah',
      'Southeast Sulawesi': 'Sulawesi Tenggara',
      'West Sulawesi': 'Sulawesi Barat',
      'Gorontalo': 'Gorontalo',
      'West Nusa Tenggara': 'Nusa Tenggara Barat',
      'East Nusa Tenggara': 'Nusa Tenggara Timur',
    };
    return translations[province] ?? province;
  }

  // Check apakah kota diizinkan
  bool _isCityAllowed(String city) {
    return _allowedCities.any((allowedCity) => 
      city.toLowerCase().contains(allowedCity.toLowerCase()) ||
      allowedCity.toLowerCase().contains(city.toLowerCase())
    );
  }

  // Show dialog untuk lokasi tidak diizinkan
  void _showLocationNotAllowedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Lokasi Tidak Tersedia', style: AppTextStyles.h3),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maaf, layanan kami saat ini hanya tersedia di:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Jakarta, Depok, Bogor, Tangerang, Bekasi, Surabaya, Bandung, Pekanbaru, Medan, Palembang, Malang, Lampung, Yogyakarta, Pontianak, Solo, Semarang, Makassar, Manado, Bali, Batam, Balikpapan, Samarinda, Banjarmasin, dan Lombok.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.greyText),
            ),
            const SizedBox(height: 12),
            Text(
              'Kami akan segera hadir di kota Anda!',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Back to previous page
            },
            child: Text('Kembali', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => location = 'Lokasi tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => location = 'Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => location = 'Izin lokasi ditolak permanen');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final city = place.subAdministrativeArea?.isNotEmpty == true 
            ? place.subAdministrativeArea! 
            : (place.locality?.isNotEmpty == true ? place.locality! : 'Unknown');
        final provinceEn = place.administrativeArea?.isNotEmpty == true 
            ? place.administrativeArea! 
            : 'Unknown';
        
        // Translate province ke Bahasa Indonesia
        final provinceId = _translateProvince(provinceEn);
        
        // Check if city is allowed
        if (!_isCityAllowed(city)) {
          debugPrint('❌ Location not allowed: $city, $provinceId');
          if (mounted) {
            setState(() {
              location = '$city, $provinceId (Tidak Tersedia)';
            });
            _showLocationNotAllowedDialog();
          }
          return;
        }
        
        if (mounted) {
          setState(() {
            location = '$city, $provinceId';
          });
          debugPrint('✅ Location allowed: $location');
        }
      } else {
        if (mounted) setState(() => location = 'Lokasi tidak ditemukan');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) setState(() => location = 'Gagal mendapatkan lokasi');
    }
  }

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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        const TextSpan(
                          text: 'Sudah termasuk ongkir ke daerah ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextSpan(
                          text: location,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 200,
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
              fontFamily: 'Funnel Display',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
        ),
      );

      // Meal sections for this date
      for (final mealType in ['Sarapan', 'Makan Siang', 'Makan Malam']) {
        final item = dateItems[mealType];
        
        // Only show meal type section if there's an item
        if (item != null) {
          widgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                mealType,
                style: const TextStyle(
                  fontFamily: 'Funnel Display',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyText,
                ),
              ),
            ),
          );
          
          widgets.add(_buildCartItemCard(item, dateKey, mealType));
          widgets.add(const SizedBox(height: 12));
        }
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu image with loading
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl.startsWith('http') ? item.imageUrl : buildImageUrl(item.imageUrl),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
                            ),
                          ),
                        ),
                      );
                    },
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
                    color: AppColors.greyText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.calories} kkal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightGreyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '| P: ${item.fullData['protein'] ?? '-'}g',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.lightGreyText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'K: ${item.fullData['carbohydrate'] ?? '-'}g',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.lightGreyText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'L: ${item.fullData['fat'] ?? '-'}g',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.lightGreyText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.green,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.greyText),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$itemName" dari keranjang?',
          style: const TextStyle(fontSize: 14, color: AppColors.greyText),
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
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              await CartManager.removeItem(dateKey, mealType);
              if (!mounted) return;
              setState(() {});
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Item dihapus dari keranjang'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600)),
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
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Konfirmasi Pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.greyText),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total item: $itemCount menu',
              style: const TextStyle(fontSize: 14, color: AppColors.greyText),
            ),
            const SizedBox(height: 8),
            Text(
              'Total harga: ${_formatPrice(totalPrice)}',
              style: const TextStyle(
                fontFamily: 'Funnel Display',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan akan dikirim sesuai dengan tanggal dan waktu makan yang dipilih.',
              style: TextStyle(fontSize: 13, color: AppColors.lightGreyText),
            ),
          ],
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
            onPressed: () => _processCheckout(),
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
                child: const Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processCheckout() async {
    // Close confirmation dialog
    Navigator.pop(context);
    
    // Validate meal frequency before processing
    final frequencyValidation = await CartManager.validateMealFrequency();
    if (frequencyValidation != null) {
      // Show frequency violation error
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Peringatan Frekuensi Makan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(frequencyValidation),
              const SizedBox(height: 16),
              const Text(
                'Silakan hapus beberapa menu dari keranjang agar sesuai dengan frekuensi makan yang Anda pilih.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
        ),
      ),
    );

    try {
      // Get cart data
      final cartItems = CartManager.getCartItems();
      final totalPrice = CartManager.getTotalPrice();
      
      // Convert CartItem objects to Map for order service
      Map<String, Map<String, dynamic>> orderData = {};
      cartItems.forEach((dateKey, meals) {
        orderData[dateKey] = {};
        meals.forEach((mealType, cartItem) {
          orderData[dateKey]![mealType] = {
            'name': cartItem.name,
            'price': cartItem.price,
            'calories': cartItem.calories,
            'protein': cartItem.fullData['protein'] ?? '',
            'carbohydrate': cartItem.fullData['carbohydrate'] ?? '',
            'fat': cartItem.fullData['fat'] ?? '',
            'image': cartItem.imageUrl,
            'clock': cartItem.fullData['clock'] ?? '',
          };
        });
      });

      // Create order in Firestore
      final orderId = await OrderService.createOrder(
        cartItems: orderData,
        totalPrice: totalPrice,
        paymentMethod: 'pending',
      );

      if (orderId == null) {
        // Close loading
        if (!mounted) return;
        Navigator.pop(context);
        
        // Show error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat pesanan. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Simulate payment processing (dalam production, ini akan integrate dengan payment gateway)
      await Future.delayed(const Duration(seconds: 1));
      
      // Mark order as paid
      final paymentSuccess = await OrderService.markOrderAsPaid(orderId);
      
      if (!paymentSuccess) {
        // Close loading
        if (!mounted) return;
        Navigator.pop(context);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran gagal. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Populate schedule dari order yang sudah dibayar
      final schedulePopulated = await ScheduleService.populateScheduleFromOrder(orderId);
      
      if (!schedulePopulated) {
        // Close loading
        if (!mounted) return;
        Navigator.pop(context);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat, tapi gagal menambahkan ke jadwal. Silakan refresh jadwal.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Clear cart after successful order
      await CartManager.clearCart();
      
      // Close loading
      if (!mounted) return;
      Navigator.pop(context);
      
      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan berhasil! Order ID: $orderId'),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh HomePage recommendations after successful checkout
      try {
        final state = HomePage.homeContentKey.currentState;
        if (state != null) {
          (state as dynamic).refreshRecommendations();
          debugPrint('✅ Triggered HomePage refresh after checkout');
        }
      } catch (e) {
        debugPrint('⚠️ Could not refresh HomePage: $e');
      }
      
      // Refresh the page and navigate back
      if (!mounted) return;
      setState(() {});
      if (!mounted) return;
      Navigator.pop(context);
      
    } catch (e) {
      // Close loading if still open
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
  static final List<VoidCallback> _listeners = [];
  static const String _storageKey = 'cart_items';
  static const int maxCartItems = 10;

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Map<String, Map<String, CartItem>> getCartItems() => _cartItems;

  /// Load cart from SharedPreferences
  static Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_storageKey);
      
      if (cartJson != null) {
        final Map<String, dynamic> cartData = json.decode(cartJson);
        _cartItems.clear();
        
        cartData.forEach((dateKey, mealsData) {
          _cartItems[dateKey] = {};
          (mealsData as Map<String, dynamic>).forEach((mealType, itemData) {
            _cartItems[dateKey]![mealType] = CartItem.fromJson(itemData as Map<String, dynamic>);
          });
        });
        
        debugPrint('✅ Cart loaded: ${getItemCount()} items');
      }
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
    }
  }

  /// Save cart to SharedPreferences
  static Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert cart to JSON-serializable format
      final Map<String, dynamic> cartData = {};
      _cartItems.forEach((dateKey, meals) {
        cartData[dateKey] = {};
        meals.forEach((mealType, item) {
          cartData[dateKey][mealType] = item.toJson();
        });
      });
      
      await prefs.setString(_storageKey, json.encode(cartData));
      debugPrint('💾 Cart saved: ${getItemCount()} items');
    } catch (e) {
      debugPrint('❌ Error saving cart: $e');
    }
  }

  /// Get user's eat frequency from Firestore
  static Future<int> getUserEatFrequency() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 3; // Default to 3 if not authenticated

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) return 3;

      final userData = userDoc.data() as Map<String, dynamic>;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final eatFrequency = profile['eatFrequency'] as int? ?? 3;

      return eatFrequency;
    } catch (e) {
      debugPrint('❌ Error getting eat frequency: $e');
      return 3; // Default to 3 on error
    }
  }

  /// Validate if adding a meal would violate frequency for a specific date
  /// Checks BOTH ordered meals (from schedule) AND cart items
  static Future<bool> canAddMealForDate(String dateKey) async {
    final eatFrequency = await getUserEatFrequency();
    final cartMealsForDate = _cartItems[dateKey]?.length ?? 0;
    
    // Also check meals already ordered (in schedule) for this date
    final date = DateTime.parse(dateKey);
    final orderedMeals = await OrderService.checkOrderedMeals(date);
    final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
    
    final totalMeals = cartMealsForDate + orderedMealsCount;
    
    debugPrint('🔍 Can add meal check: Date=$dateKey, Cart=$cartMealsForDate, Ordered=$orderedMealsCount, Total=$totalMeals, Limit=$eatFrequency');
    return totalMeals < eatFrequency;
  }

  /// Validate entire cart against meal frequency limits
  /// Checks BOTH ordered meals (from schedule) AND cart items
  /// Returns error message if validation fails, null if valid
  static Future<String?> validateMealFrequency() async {
    final eatFrequency = await getUserEatFrequency();
    
    // Check each date in cart
    for (final entry in _cartItems.entries) {
      final dateKey = entry.key;
      final mealsForDate = entry.value;
      final cartMealCount = mealsForDate.length;
      
      // Also check meals already ordered for this date
      final date = DateTime.parse(dateKey);
      final orderedMeals = await OrderService.checkOrderedMeals(date);
      final orderedMealsCount = orderedMeals.values.where((ordered) => ordered).length;
      
      final totalMeals = cartMealCount + orderedMealsCount;
      
      if (totalMeals > eatFrequency) {
        final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(date);
        final mealTypes = mealsForDate.keys.join(', ');
        
        return 'Anda sudah memiliki $orderedMealsCount menu yang dipesan dan $cartMealCount menu di keranjang ($mealTypes) untuk tanggal $formattedDate. Total: $totalMeals menu, tetapi frekuensi makan Anda adalah $eatFrequency kali per hari.';
      }
    }
    
    debugPrint('✅ Meal frequency validation passed');
    return null; // Validation passed
  }

  static Future<bool> addItem(String dateKey, String mealType, CartItem item) async {
    // Check if cart is full (max 10 items)
    if (getItemCount() >= maxCartItems) {
      debugPrint('⚠️ Cart is full (max $maxCartItems items)');
      return false;
    }

    // Check if item already exists for this date and meal type
    if (_cartItems[dateKey]?[mealType] != null) {
      // Item exists, return false to show confirmation dialog
      return false;
    }

    // Add item to cart
    _cartItems[dateKey] ??= {};
    _cartItems[dateKey]![mealType] = item;
    await _saveCart();
    _notifyListeners();
    return true;
  }

  static Future<void> replaceItem(String dateKey, String mealType, CartItem item) async {
    _cartItems[dateKey] ??= {};
    _cartItems[dateKey]![mealType] = item;
    await _saveCart();
    _notifyListeners();
  }

  static Future<void> removeItem(String dateKey, String mealType) async {
    _cartItems[dateKey]?.remove(mealType);
    if (_cartItems[dateKey]?.isEmpty == true) {
      _cartItems.remove(dateKey);
    }
    await _saveCart();
    _notifyListeners();
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

  static Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
    _notifyListeners();
  }
}
