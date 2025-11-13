import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> filterGroups = [
    {
      'title': 'Kambing', 
      'tags': ['Daging', 'Sate', 'Gulai', 'Sop', 'Tongseng', 'Krengsengan', 'Nasi Goreng Kambing']
    },
    {
      'title': 'Sapi', 
      'tags': ['Rendang', 'Asem-Asem', 'Gepuk', 'Rawon', 'Empal']
    },
    {
      'title': 'Ayam', 
      'tags': ['Goreng', 'Bakar', 'Panggang', 'Kukus', 'Betutu', 'Opor']
    },
    {
      'title': 'Sayuran',
      'tags': ['Salad', 'Tumis', 'Rebus', 'Goreng', 'Kukus']
    },
    {
      'title': 'Ikan',
      'tags': ['Bakar', 'Goreng', 'Panggang', 'Kukus', 'Asam Manis']
    },
    {
      'title': 'Udang', 
      'tags': ['Bakar', 'Goreng', 'Panggang', 'Asam Manis', 'Saos Tiram']
    },
  ];

  late Set<String> _selectedFilters;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // INISIALISASI DENGAN FILTER YANG DITERIMA DARI PARENT
    _selectedFilters = Set<String>.from(widget.initialFilters);
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

  List<Map<String, dynamic>> get _filteredGroups {
    if (_searchQuery.isEmpty) {
      return filterGroups;
    }
    
    return filterGroups.map((group) {
      final filteredTags = (group['tags'] as List<String>)
          .where((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      
      return {
        'title': group['title'],
        'tags': filteredTags,
      };
    }).where((group) => (group['tags'] as List).isNotEmpty).toList();
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

          // Daftar Filter Berdasarkan Kategori
          Expanded(
            child: _filteredGroups.isEmpty
                ? const Center(
                    child: Text('Tidak ada tag yang sesuai dengan pencarian'),
                  )
                : ListView(
                    children: _filteredGroups.map((group) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: (group['tags'] as List<String>).map((tag) {
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
                          const Divider(height: 30),
                        ],
                      );
                    }).toList(),
                  ),
          ),

          // Tombol Apply Filter
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Apply Filter',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}