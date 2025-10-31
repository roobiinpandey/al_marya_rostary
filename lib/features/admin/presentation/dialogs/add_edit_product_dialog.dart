import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/coffee_product_model.dart';
import '../providers/product_provider.dart';

/// Add/Edit Product Dialog with full form validation and image upload
class AddEditProductDialog extends StatefulWidget {
  final CoffeeProductModel? product; // null for Add, existing for Edit

  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controllers
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _priceController;
  late TextEditingController _originController;
  late TextEditingController _stockController;

  // State
  File? _selectedImage;
  String? _roastLevel;
  List<String> _selectedCategories = [];
  bool _isActive = true;
  bool _isLoading = false;

  // Available options
  final List<String> _roastLevels = [
    'Light',
    'Medium-Light',
    'Medium',
    'Medium-Dark',
    'Dark',
  ];

  final List<String> _availableCategories = [
    'Premium',
    'Specialty',
    'Single Origin',
    'Blend',
    'Organic',
    'Fair Trade',
    'Limited Edition',
    'Best Seller',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data or empty
    final p = widget.product;
    _nameEnController = TextEditingController(text: p?.name ?? '');
    _nameArController = TextEditingController(
      text: p?.name ?? '',
    ); // Use same as English for now
    _descriptionEnController = TextEditingController(
      text: p?.description ?? '',
    );
    _descriptionArController = TextEditingController(
      text: p?.description ?? '',
    ); // Use same as English for now
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _originController = TextEditingController(text: p?.origin ?? '');
    _stockController = TextEditingController(
      text: p?.stock.toString() ?? '100',
    );

    if (p != null) {
      _roastLevel = p.roastLevel;
      _selectedCategories = List<String>.from(p.categories);
      _isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    _originController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.product != null;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_roastLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a roast level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);

      if (_isEditMode) {
        // Update existing product
        await provider.updateProduct(
          productId: widget.product!.id,
          nameEn: _nameEnController.text.trim(),
          nameAr: _nameArController.text.trim(),
          descriptionEn: _descriptionEnController.text.trim(),
          descriptionAr: _descriptionArController.text.trim(),
          price: double.parse(_priceController.text),
          origin: _originController.text.trim(),
          roastLevel: _roastLevel!,
          stock: int.parse(_stockController.text),
          categories: _selectedCategories,
          imageFile: _selectedImage,
          isActive: _isActive,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new product
        await provider.createProduct(
          nameEn: _nameEnController.text.trim(),
          nameAr: _nameArController.text.trim(),
          descriptionEn: _descriptionEnController.text.trim(),
          descriptionAr: _descriptionArController.text.trim(),
          price: double.parse(_priceController.text),
          origin: _originController.text.trim(),
          roastLevel: _roastLevel!,
          stock: int.parse(_stockController.text),
          categories: _selectedCategories,
          imageFile: _selectedImage,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: Container(
        width: isMobile ? screenWidth - 32 : 800,
        height: screenHeight * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBrown,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Edit Product' : 'Add New Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker
                      _buildImagePicker(),

                      const SizedBox(height: 24),

                      // English Name
                      TextFormField(
                        controller: _nameEnController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name (English) *',
                          hintText: 'e.g., Ethiopian Yirgacheffe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.coffee),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name in English';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Arabic Name
                      TextFormField(
                        controller: _nameArController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name (Arabic) *',
                          hintText: 'e.g., قهوة إثيوبية يرجاتشيف',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.coffee),
                        ),
                        textDirection: TextDirection.rtl,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name in Arabic';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Price and Origin Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price (AED) *',
                                hintText: '50.00',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter price';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Please enter a valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _originController,
                              decoration: const InputDecoration(
                                labelText: 'Origin *',
                                hintText: 'e.g., Ethiopia',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.public),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter origin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Roast Level and Stock Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _roastLevel,
                              decoration: const InputDecoration(
                                labelText: 'Roast Level *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.local_fire_department),
                              ),
                              items: _roastLevels.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _roastLevel = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select roast level';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity *',
                                hintText: '100',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter stock quantity';
                                }
                                final stock = int.tryParse(value);
                                if (stock == null || stock < 0) {
                                  return 'Please enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // English Description
                      TextFormField(
                        controller: _descriptionEnController,
                        decoration: const InputDecoration(
                          labelText: 'Description (English) *',
                          hintText: 'Detailed product description...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description in English';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Arabic Description
                      TextFormField(
                        controller: _descriptionArController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Arabic) *',
                          hintText: 'وصف تفصيلي للمنتج...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        textDirection: TextDirection.rtl,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description in Arabic';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Categories
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableCategories.map((category) {
                          final isSelected = _selectedCategories.contains(
                            category,
                          );
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
                            selectedColor: AppTheme.primaryBrown.withOpacity(
                              0.2,
                            ),
                            checkmarkColor: AppTheme.primaryBrown,
                          );
                        }).toList(),
                      ),

                      if (_isEditMode) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Active Product'),
                          subtitle: const Text('Product visible to customers'),
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: AppTheme.primaryBrown,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProduct,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_isEditMode ? Icons.save : Icons.add),
                    label: Text(
                      _isLoading
                          ? 'Saving...'
                          : (_isEditMode ? 'Update Product' : 'Create Product'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : widget.product?.imageUrl.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product!.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: Text(
                _selectedImage != null ||
                        widget.product?.imageUrl.isNotEmpty == true
                    ? 'Change Image'
                    : 'Select Image',
              ),
            ),
            if (_selectedImage != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                icon: const Icon(Icons.clear, color: Colors.red),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap to select product image',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }
}
