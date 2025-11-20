import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    setState(() {
      if (_selectedFilters.contains(tag)) {
        _selectedFilters.remove(tag);
      } else {
        _selectedFilters.add(tag);
      }
    });
  }

  void _applyFilters() {
    // KIRIM FILTER BARU KE PARENT (RECOMMENDATION SCREEN)
    widget.onFiltersChanged(_selectedFilters);
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilters.clear();
    });
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dan Tombol Clear
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Input Pencarian
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari Tag...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 15),

          // Filter yang Sudah Diterapkan (Active Filters)
          const Text('Filter Sudah Diterapkan', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _selectedFilters.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              onDeleted: () => _toggleFilter(tag),
              deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
            )).toList(),
          ),
          const Divider(height: 30),
          // Daftar Filter (All unique tags from DB)
          Expanded(
            child: _loadingTags
                ? const Center(child: CircularProgressIndicator())
                : _filteredTags.isEmpty
                    ? const Center(child: Text('Tidak ada tag yang sesuai dengan pencarian'))
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _filteredTags.map((tag) {
                                final isSelected = _selectedFilters.contains(tag);
                                return ActionChip(
                                  label: Text(tag),
                                  backgroundColor: isSelected ? Colors.green.shade100 : Colors.grey.shade200,
                                  side: BorderSide(
                                    color: isSelected ? Colors.green : Colors.grey.shade400,
                                  ),
                                  onPressed: () => _toggleFilter(tag),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
          ),

          // Tombol Apply Filter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedFilters.isNotEmpty ? Colors.green : Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Apply Filter',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}