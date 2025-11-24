import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutrilink/config/appTheme.dart';

class FilterFoodPopup extends StatefulWidget {
  final Set<String> initialFilters;
  final Function(Set<String>) onFiltersChanged;

  const FilterFoodPopup({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterFoodPopup> createState() => _FilterFoodPopupState();
}

class _FilterFoodPopupState extends State<FilterFoodPopup> {
  // Tags loaded dynamically from Firestore `menus` collection (tag1/tag2/tag3 or 'tags' field)
  List<String> _allTags = [];
  bool _loadingTags = true;

  late Set<String> _selectedFilters;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // INISIALISASI DENGAN FILTER YANG DITERIMA DARI PARENT
    _selectedFilters = Set<String>.from(widget.initialFilters);
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final Set<String> tagSet = {};
      final snap = await FirebaseFirestore.instance.collection('menus').get();
      for (var doc in snap.docs) {
        final data = doc.data();
        // field 'tags' could be String (CSV) or List
        final tagsRaw = data['tags'];
        if (tagsRaw is String) {
          for (var t in tagsRaw.split(',')) {
            final v = t.toString().trim();
            if (v.isNotEmpty) tagSet.add(v);
          }
        } else if (tagsRaw is List) {
          for (var t in tagsRaw) {
            final v = t.toString().trim();
            if (v.isNotEmpty) tagSet.add(v);
          }
        }

        // also check tag1/tag2/tag3 fields if present
        for (var k in ['tag1', 'tag2', 'tag3']) {
          final v = data[k];
          if (v is String && v.trim().isNotEmpty) tagSet.add(v.trim());
        }
      }

      final tagsList = tagSet.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _allTags = tagsList;
        _loadingTags = false;
      });
    } catch (e) {
      setState(() {
        _allTags = [];
        _loadingTags = false;
      });
    }
  }

  void _toggleFilter(String tag) {
    debugPrint('🔴 Toggle filter: $tag');
    setState(() {
      if (_selectedFilters.contains(tag)) {
        _selectedFilters.remove(tag);
        debugPrint('  ❌ Removed: $tag, remaining: $_selectedFilters');
      } else {
        _selectedFilters.add(tag);
        debugPrint('  ✅ Added: $tag, total: $_selectedFilters');
      }
    });
    // SYNC IMMEDIATELY to parent - don't wait for apply button
    debugPrint('📤 Calling onFiltersChanged with: $_selectedFilters');
    widget.onFiltersChanged(_selectedFilters);
  }

  void _applyFilters() {
    // State already synced via _toggleFilter, just close the sheet
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilters.clear();
    });
    // SYNC IMMEDIATELY to parent - clear filters in real time
    widget.onFiltersChanged(_selectedFilters);
  }

  List<String> get _filteredTags {
    if (_searchQuery.isEmpty) return _allTags;
    final q = _searchQuery.toLowerCase();
    return _allTags.where((t) => t.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green.withValues(alpha: 0.1), AppColors.greenLight.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered title
                const Center(
                  child: Text(
                    'Filter Makanan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.greyText),
                  ),
                ),
                // Left and right buttons positioned absolutely
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear_all, color: Color(0xFFE53935), size: 18),
                      label: const Text('Hapus', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.greyText),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input Pencarian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade50, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Cari tag (misal: Ayam, Ikan, dll)',
                  hintStyle: TextStyle(color: AppColors.lightGreyText, fontSize: 14),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppColors.green, size: 22),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filter yang Sudah Diterapkan (Active Filters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Aktif',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.greyText),
                    ),
                    if (_selectedFilters.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.green, AppColors.greenLight],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedFilters.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _selectedFilters.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Belum ada filter yang dipilih',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _selectedFilters.map((tag) => Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              tag,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11, height: 1.0),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _toggleFilter(tag),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.grey.shade200),
          // Daftar Filter (All unique tags from DB)
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.category, color: AppColors.greyText, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Semua Tag (${_filteredTags.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.greyText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loadingTags
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.green),
                        const SizedBox(height: 16),
                        Text('Memuat tag...', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : _filteredTags.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada tag yang sesuai',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Coba kata kunci lain',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        children: [
                          Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: _filteredTags.map((tag) {
                              final isSelected = _selectedFilters.contains(tag);
                              return GestureDetector(
                                onTap: () => _toggleFilter(tag),
                                child: Container(
                                  height: 26,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.green : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: isSelected ? AppColors.green : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (isSelected)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6),
                                          child: Icon(Icons.check_circle, color: Colors.white, size: 14),
                                        ),
                                      Text(
                                        tag,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.greyText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
          ),
          const SizedBox(height: 12),

          // Tombol Apply Filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: _selectedFilters.isNotEmpty
                  ? LinearGradient(
                      colors: [AppColors.green, AppColors.greenLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: _selectedFilters.isEmpty ? AppColors.disabledGrey : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedFilters.isNotEmpty ? [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _applyFilters,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _selectedFilters.isEmpty ? 'Pilih Filter' : 'Terapkan ${_selectedFilters.length} Filter',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
