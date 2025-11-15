import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/product_management_service.dart';

class ProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductManagementService();
  late TabController _tabController;

  // Form Controllers - Basic
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Coffee Attributes
  final _altitudeController = TextEditingController();
  final _varietyController = TextEditingController();
  final _harvestYearController = TextEditingController();
  final _cuppingNotesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _slugController = TextEditingController();

  // Variant Controllers - 250gm
  final _variant250PriceController = TextEditingController(text: '45.00');
  final _variant250StockController = TextEditingController(text: '100');
  final _variant250DescEnController = TextEditingController(
    text: 'Perfect for trying new flavors',
  );
  final _variant250DescArController = TextEditingController(
    text: 'مثالية لتجربة النكهات الجديدة',
  );
  final _variant250SkuController = TextEditingController();

  // Variant Controllers - 500gm
  final _variant500PriceController = TextEditingController(text: '85.00');
  final _variant500StockController = TextEditingController(text: '100');
  final _variant500DescEnController = TextEditingController(
    text: 'Perfect for regular consumption',
  );
  final _variant500DescArController = TextEditingController(
    text: 'مثالية للاستهلاك المنتظم',
  );
  final _variant500SkuController = TextEditingController();

  // Variant Controllers - 1kg
  final _variant1kgPriceController = TextEditingController(text: '155.00');
  final _variant1kgStockController = TextEditingController(text: '50');
  final _variant1kgDescEnController = TextEditingController(
    text: 'Best value for coffee enthusiasts',
  );
  final _variant1kgDescArController = TextEditingController(
    text: 'أفضل قيمة لعشاق القهوة',
  );
  final _variant1kgSkuController = TextEditingController();

  // Dropdown selections
  String? _selectedOrigin;
  String? _selectedProcessMethod;
  String? _selectedRoastLevel;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isPremium = false;
  bool _isLoading = false;

  // Variants active status
  bool _variant250Active = true;
  bool _variant500Active = true;
  bool _variant1kgActive = true;

  // Selected categories and flavor profiles
  List<String> _selectedCategories = [];
  List<String> _selectedFlavorProfiles = [];

  // Constants
  final List<String> _categories = [
    'Espresso Blend',
    'Single Origin',
    'Signature Blend',
    'Decaf',
    'Premium',
    'Specialty',
  ];
  final List<String> _origins = [
    'Ethiopia',
    'Kenya',
    'Tanzania',
    'Rwanda',
    'Burundi',
    'Colombia',
    'Brazil',
    'Guatemala',
    'Costa Rica',
    'Honduras',
    'Peru',
    'El Salvador',
    'Indonesia',
    'India',
    'Vietnam',
    'Papua New Guinea',
    'Yemen',
    'Multi-Origin',
  ];
  final List<String> _processMethods = [
    'Washed',
    'Natural',
    'Honey',
    'Semi-Washed',
    'Anaerobic',
  ];
  final List<String> _roastLevels = ['Light', 'Medium', 'Medium-Dark', 'Dark'];
  final List<String> _flavorProfiles = [
    'Chocolate',
    'Nutty',
    'Fruity',
    'Floral',
    'Spicy',
    'Caramel',
    'Citrus',
    'Berry',
    'Earthy',
    'Sweet',
    'Smoky',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _nameController.text = product['name']?['en'] ?? product['name'] ?? '';
    _nameArController.text = product['name']?['ar'] ?? product['nameAr'] ?? '';
    _descriptionController.text =
        product['description']?['en'] ?? product['description'] ?? '';
    _descriptionArController.text =
        product['description']?['ar'] ?? product['descriptionAr'] ?? '';
    _imageUrlController.text = product['image'] ?? product['imageUrl'] ?? '';

    _selectedOrigin = product['origin'];
    _selectedRoastLevel = product['roastLevel'];
    _selectedProcessMethod =
        product['processingMethod'] ?? product['processMethod'];

    _isActive = product['isActive'] ?? true;
    _isFeatured = product['isFeatured'] ?? false;
    _isPremium = product['isPremium'] ?? false;

    // Load advanced attributes
    if (product['altitude'] != null) {
      _altitudeController.text = product['altitude'].toString();
    }
    _varietyController.text = product['variety'] ?? '';
    if (product['harvestYear'] != null) {
      _harvestYearController.text = product['harvestYear'].toString();
    }
    _cuppingNotesController.text = product['cuppingNotes'] ?? '';
    _slugController.text = product['slug'] ?? '';

    // Load tags
    if (product['tags'] != null && product['tags'] is List) {
      _tagsController.text = (product['tags'] as List).join(', ');
    }

    // Load categories
    if (product['categories'] != null && product['categories'] is List) {
      _selectedCategories = List<String>.from(product['categories']);
    }

    // Load flavor profiles
    if (product['flavorProfile'] != null && product['flavorProfile'] is List) {
      _selectedFlavorProfiles = List<String>.from(product['flavorProfile']);
    }

    // Load variants
    if (product['variants'] != null && product['variants'] is List) {
      final variants = product['variants'] as List;
      for (var variant in variants) {
        final size = variant['size'];
        if (size == '250gm') {
          _variant250PriceController.text = (variant['price'] ?? 45.0)
              .toString();
          _variant250StockController.text = (variant['stock'] ?? 100)
              .toString();
          _variant250DescEnController.text =
              variant['description']?['en'] ?? 'Perfect for trying new flavors';
          _variant250DescArController.text =
              variant['description']?['ar'] ?? 'مثالية لتجربة النكهات الجديدة';
          _variant250SkuController.text = variant['sku'] ?? '';
          _variant250Active = variant['isActive'] ?? true;
        } else if (size == '500gm') {
          _variant500PriceController.text = (variant['price'] ?? 85.0)
              .toString();
          _variant500StockController.text = (variant['stock'] ?? 100)
              .toString();
          _variant500DescEnController.text =
              variant['description']?['en'] ??
              'Perfect for regular consumption';
          _variant500DescArController.text =
              variant['description']?['ar'] ?? 'مثالية للاستهلاك المنتظم';
          _variant500SkuController.text = variant['sku'] ?? '';
          _variant500Active = variant['isActive'] ?? true;
        } else if (size == '1kg') {
          _variant1kgPriceController.text = (variant['price'] ?? 155.0)
              .toString();
          _variant1kgStockController.text = (variant['stock'] ?? 50).toString();
          _variant1kgDescEnController.text =
              variant['description']?['en'] ??
              'Best value for coffee enthusiasts';
          _variant1kgDescArController.text =
              variant['description']?['ar'] ?? 'أفضل قيمة لعشاق القهوة';
          _variant1kgSkuController.text = variant['sku'] ?? '';
          _variant1kgActive = variant['isActive'] ?? true;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _imageUrlController.dispose();
    _altitudeController.dispose();
    _varietyController.dispose();
    _harvestYearController.dispose();
    _cuppingNotesController.dispose();
    _tagsController.dispose();
    _slugController.dispose();
    // Dispose variant controllers
    _variant250PriceController.dispose();
    _variant250StockController.dispose();
    _variant250DescEnController.dispose();
    _variant250DescArController.dispose();
    _variant250SkuController.dispose();
    _variant500PriceController.dispose();
    _variant500StockController.dispose();
    _variant500DescEnController.dispose();
    _variant500DescArController.dispose();
    _variant500SkuController.dispose();
    _variant1kgPriceController.dispose();
    _variant1kgStockController.dispose();
    _variant1kgDescEnController.dispose();
    _variant1kgDescArController.dispose();
    _variant1kgSkuController.dispose();
    super.dispose();
  }

  void _autoGenerateSlug() {
    if (_nameController.text.isNotEmpty && _slugController.text.isEmpty) {
      final slug = _nameController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      _slugController.text = slug;
    }
  }

  void _autoGenerateSKU() {
    if (_selectedOrigin != null && _selectedRoastLevel != null) {
      // Generate base SKU: COF-{ORIGIN}-{ROAST}
      final originCode = _selectedOrigin!.substring(0, 3).toUpperCase();
      final roastCode = _selectedRoastLevel!
          .replaceAll('-', '')
          .substring(0, 3)
          .toUpperCase();
      final baseSKU = 'COF-$originCode-$roastCode';

      // Generate variant SKUs
      _variant250SkuController.text = '$baseSKU-250';
      _variant500SkuController.text = '$baseSKU-500';
      _variant1kgSkuController.text = '$baseSKU-1KG';
    }
  }

  bool _isLowStock(String stockText, int threshold) {
    final stock = int.tryParse(stockText);
    return stock != null && stock > 0 && stock <= threshold;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Auto-generate slug if empty
    _autoGenerateSlug();

    // Build variants array
    final List<Map<String, dynamic>> variants = [];

    if (_variant250Active) {
      variants.add({
        'size': '250gm',
        'sku': _variant250SkuController.text.trim(),
        'price': double.tryParse(_variant250PriceController.text) ?? 45.0,
        'stock': int.tryParse(_variant250StockController.text) ?? 100,
        'description': {
          'en': _variant250DescEnController.text.trim(),
          'ar': _variant250DescArController.text.trim(),
        },
        'isActive': true,
      });
    }

    if (_variant500Active) {
      variants.add({
        'size': '500gm',
        'sku': _variant500SkuController.text.trim(),
        'price': double.tryParse(_variant500PriceController.text) ?? 85.0,
        'stock': int.tryParse(_variant500StockController.text) ?? 100,
        'description': {
          'en': _variant500DescEnController.text.trim(),
          'ar': _variant500DescArController.text.trim(),
        },
        'isActive': true,
      });
    }

    if (_variant1kgActive) {
      variants.add({
        'size': '1kg',
        'sku': _variant1kgSkuController.text.trim(),
        'price': double.tryParse(_variant1kgPriceController.text) ?? 155.0,
        'stock': int.tryParse(_variant1kgStockController.text) ?? 50,
        'description': {
          'en': _variant1kgDescEnController.text.trim(),
          'ar': _variant1kgDescArController.text.trim(),
        },
        'isActive': true,
      });
    }

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable at least one variant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Parse tags
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final productData = {
      'productType': 'Coffee', // Backend requires this to determine model
      'nameEn': _nameController.text.trim(),
      'nameAr': _nameArController.text.trim(),
      'descriptionEn': _descriptionController.text.trim(),
      'descriptionAr': _descriptionArController.text.trim(),
      'origin': _selectedOrigin ?? 'Unknown',
      'roastLevel': _selectedRoastLevel ?? 'Medium',
      'processingMethod': _selectedProcessMethod,
      'altitude': int.tryParse(_altitudeController.text),
      'variety': _varietyController.text.trim(),
      'harvestYear': int.tryParse(_harvestYearController.text),
      'cuppingNotes': _cuppingNotesController.text.trim(),
      'slug': _slugController.text.trim(),
      'tags': tags,
      'categories': _selectedCategories,
      'flavorProfile': _selectedFlavorProfiles,
      'variants': variants,
      'price': variants.first['price'], // Default price from first variant
      'stock': variants.fold(
        0,
        (sum, variant) => sum + (variant['stock'] as int),
      ),
      'image': _imageUrlController.text.trim(),
      'isActive': _isActive,
      'isFeatured': _isFeatured,
      'isPremium': _isPremium,
    };

    final result = widget.product == null
        ? await _productService.createProduct(productData)
        : await _productService.updateProduct(
            widget.product!['_id'],
            productData,
          );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product created successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Operation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
        backgroundColor: const Color(0xFF8B4513),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Basic Info'),
            Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
            Tab(icon: Icon(Icons.tune), text: 'Advanced'),
          ],
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildPricingTab(),
            _buildAdvancedTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            isEdit ? 'Update Product' : 'Create Product',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Product Name'),
        _buildTextField(
          controller: _nameController,
          label: 'Name (English)',
          required: true,
          onChanged: (_) => _autoGenerateSlug(),
        ),
        _buildTextField(
          controller: _nameArController,
          label: 'Name (Arabic)',
          required: true,
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Description'),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description (English)',
          maxLines: 3,
          required: true,
        ),
        _buildTextField(
          controller: _descriptionArController,
          label: 'Description (Arabic)',
          maxLines: 3,
          required: true,
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Coffee Details'),
        _buildDropdown(
          label: 'Origin Country *',
          value: _selectedOrigin,
          items: _origins,
          onChanged: (value) {
            setState(() => _selectedOrigin = value);
            _autoGenerateSKU();
          },
        ),
        _buildDropdown(
          label: 'Roast Level *',
          value: _selectedRoastLevel,
          items: _roastLevels,
          onChanged: (value) {
            setState(() => _selectedRoastLevel = value);
            _autoGenerateSKU();
          },
        ),
        _buildDropdown(
          label: 'Process Method',
          value: _selectedProcessMethod,
          items: _processMethods,
          onChanged: (value) => setState(() => _selectedProcessMethod = value),
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Categories'),
        _buildCategorySelection(),

        const SizedBox(height: 20),
        _buildSectionTitle('Flavor Profile'),
        _buildFlavorProfileSelection(),

        const SizedBox(height: 20),
        _buildSectionTitle('Media'),
        _buildTextField(
          controller: _imageUrlController,
          label: 'Image URL',
          required: true,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Status'),
        SwitchListTile(
          title: const Text('Active'),
          subtitle: const Text('Product visible to customers'),
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
        SwitchListTile(
          title: const Text('Featured'),
          subtitle: const Text('Show in featured products section'),
          value: _isFeatured,
          onChanged: (value) => setState(() => _isFeatured = value),
        ),
        SwitchListTile(
          title: const Text('Premium'),
          subtitle: const Text('Mark as premium product'),
          value: _isPremium,
          onChanged: (value) => setState(() => _isPremium = value),
        ),
      ],
    );
  }

  Widget _buildPricingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Product Variants'),
        const Text(
          'Enable and configure variants for different package sizes',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // 250gm Variant
        _buildVariantCard(
          title: '250gm',
          isActive: _variant250Active,
          onToggle: (value) => setState(() => _variant250Active = value!),
          priceController: _variant250PriceController,
          stockController: _variant250StockController,
          descEnController: _variant250DescEnController,
          descArController: _variant250DescArController,
          skuController: _variant250SkuController,
        ),

        const SizedBox(height: 16),

        // 500gm Variant
        _buildVariantCard(
          title: '500gm',
          isActive: _variant500Active,
          onToggle: (value) => setState(() => _variant500Active = value!),
          priceController: _variant500PriceController,
          stockController: _variant500StockController,
          descEnController: _variant500DescEnController,
          descArController: _variant500DescArController,
          skuController: _variant500SkuController,
        ),

        const SizedBox(height: 16),

        // 1kg Variant
        _buildVariantCard(
          title: '1kg',
          isActive: _variant1kgActive,
          onToggle: (value) => setState(() => _variant1kgActive = value!),
          priceController: _variant1kgPriceController,
          stockController: _variant1kgStockController,
          descEnController: _variant1kgDescEnController,
          descArController: _variant1kgDescArController,
          skuController: _variant1kgSkuController,
        ),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Coffee Attributes'),
        _buildTextField(
          controller: _altitudeController,
          label: 'Altitude (meters)',
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _varietyController,
          label: 'Coffee Variety',
        ),
        _buildTextField(
          controller: _harvestYearController,
          label: 'Harvest Year',
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          controller: _cuppingNotesController,
          label: 'Cupping Notes',
          maxLines: 3,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('SEO & Tags'),
        _buildTextField(
          controller: _slugController,
          label: 'URL Slug',
          helperText: 'Auto-generated from product name if left empty',
        ),
        _buildTextField(
          controller: _tagsController,
          label: 'Tags (comma separated)',
          helperText: 'e.g. organic, fair-trade, premium',
        ),
      ],
    );
  }

  Widget _buildVariantCard({
    required String title,
    required bool isActive,
    required Function(bool?) onToggle,
    required TextEditingController priceController,
    required TextEditingController stockController,
    required TextEditingController descEnController,
    required TextEditingController descArController,
    required TextEditingController skuController,
  }) {
    final isLowStock = _isLowStock(stockController.text, 20);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            value: isActive,
            onChanged: onToggle,
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: priceController,
                          label: 'Price (OMR)',
                          keyboardType: TextInputType.number,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: stockController,
                              label: 'Stock',
                              keyboardType: TextInputType.number,
                              required: true,
                              onChanged: (_) =>
                                  setState(() {}), // Refresh to update warning
                            ),
                            if (isLowStock)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Low stock warning!',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildTextField(
                    controller: skuController,
                    label: 'SKU (auto-generated)',
                    helperText: 'Generated from origin and roast level',
                  ),
                  _buildTextField(
                    controller: descEnController,
                    label: 'Description (English)',
                  ),
                  _buildTextField(
                    controller: descArController,
                    label: 'Description (Arabic)',
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
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
          selectedColor: const Color(0xFF8B4513).withOpacity(0.3),
          checkmarkColor: const Color(0xFF8B4513),
        );
      }).toList(),
    );
  }

  Widget _buildFlavorProfileSelection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _flavorProfiles.map((flavor) {
        final isSelected = _selectedFlavorProfiles.contains(flavor);
        return FilterChip(
          label: Text(flavor),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedFlavorProfiles.add(flavor);
              } else {
                _selectedFlavorProfiles.remove(flavor);
              }
            });
          },
          selectedColor: Colors.brown.withOpacity(0.3),
          checkmarkColor: Colors.brown,
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B4513),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    String? helperText,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: textDirection,
        onChanged: onChanged,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
