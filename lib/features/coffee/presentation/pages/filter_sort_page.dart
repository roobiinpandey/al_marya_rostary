import 'package:flutter/material.dart';

class FilterSortPage extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const FilterSortPage({super.key, this.initialFilters});

  @override
  State<FilterSortPage> createState() => _FilterSortPageState();
}

class _FilterSortPageState extends State<FilterSortPage> {
  // Filter state
  RangeValues _priceRange = const RangeValues(0, 100);
  String _selectedRoastLevel = 'All';
  List<String> _selectedCategories = [];
  double _minRating = 0;
  bool _inStockOnly = false;

  // Sort state
  String _sortBy = 'name';
  bool _sortAscending = true;

  final List<String> _roastLevels = [
    'All',
    'Light',
    'Medium',
    'Dark',
    'Extra Dark',
  ];

  final List<String> _availableCategories = [
    'Espresso',
    'Arabica',
    'Robusta',
    'Specialty',
    'Organic',
    'Fair Trade',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _loadInitialFilters(widget.initialFilters!);
    }
  }

  void _loadInitialFilters(Map<String, dynamic> filters) {
    setState(() {
      if (filters['priceRange'] != null) {
        _priceRange = filters['priceRange'] as RangeValues;
      }
      if (filters['roastLevel'] != null) {
        _selectedRoastLevel = filters['roastLevel'] as String;
      }
      if (filters['categories'] != null) {
        _selectedCategories = List<String>.from(filters['categories']);
      }
      if (filters['minRating'] != null) {
        _minRating = filters['minRating'] as double;
      }
      if (filters['inStockOnly'] != null) {
        _inStockOnly = filters['inStockOnly'] as bool;
      }
      if (filters['sortBy'] != null) {
        _sortBy = filters['sortBy'] as String;
      }
      if (filters['sortAscending'] != null) {
        _sortAscending = filters['sortAscending'] as bool;
      }
    });
  }

  Map<String, dynamic> _buildFilters() {
    return {
      'priceRange': _priceRange,
      'roastLevel': _selectedRoastLevel,
      'categories': _selectedCategories,
      'minRating': _minRating,
      'inStockOnly': _inStockOnly,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
    };
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 100);
      _selectedRoastLevel = 'All';
      _selectedCategories = [];
      _minRating = 0;
      _inStockOnly = false;
      _sortBy = 'name';
      _sortAscending = true;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, _buildFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter & Sort'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Price Range
          _buildSection(
            'Price Range',
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${_priceRange.start.toStringAsFixed(0)}'),
                    Text('\$${_priceRange.end.toStringAsFixed(0)}'),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  labels: RangeLabels(
                    '\$${_priceRange.start.toStringAsFixed(0)}',
                    '\$${_priceRange.end.toStringAsFixed(0)}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Roast Level
          _buildSection(
            'Roast Level',
            Wrap(
              spacing: 8,
              children: _roastLevels.map((level) {
                final isSelected = _selectedRoastLevel == level;
                return ChoiceChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedRoastLevel = level;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // Categories
          _buildSection(
            'Categories',
            Wrap(
              spacing: 8,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(),

          // Rating
          _buildSection(
            'Minimum Rating',
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _minRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    Text('${_minRating.toStringAsFixed(1)} & up'),
                  ],
                ),
                Slider(
                  value: _minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _minRating = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Stock
          _buildSection(
            'Availability',
            SwitchListTile(
              title: const Text('In Stock Only'),
              value: _inStockOnly,
              onChanged: (value) {
                setState(() {
                  _inStockOnly = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(),

          // Sort By
          _buildSection(
            'Sort By',
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'name', label: Text('Name')),
                ButtonSegment(value: 'price', label: Text('Price')),
                ButtonSegment(value: 'rating', label: Text('Rating')),
                ButtonSegment(value: 'date', label: Text('Newest')),
              ],
              selected: {_sortBy},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _sortBy = selected.first;
                });
              },
            ),
          ),
          const Divider(),

          // Sort Order
          _buildSection(
            'Sort Order',
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Ascending'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Descending'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_sortAscending},
              onSelectionChanged: (Set<bool> selected) {
                setState(() {
                  _sortAscending = selected.first;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
