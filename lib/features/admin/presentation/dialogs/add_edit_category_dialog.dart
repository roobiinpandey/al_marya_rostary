import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/category_model.dart';
import '../providers/category_provider.dart';

/// Add/Edit Category Dialog
/// Handles both creating new categories and editing existing ones
class AddEditCategoryDialog extends StatefulWidget {
  final CategoryModel? category; // null for Add, non-null for Edit
  final CategoryProvider provider;

  const AddEditCategoryDialog({
    super.key,
    this.category,
    required this.provider,
  });

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nameEnController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionEnController;
  late TextEditingController _descriptionArController;
  late TextEditingController _displayOrderController;

  // Form state
  Color _selectedColor = const Color(0xFF8B4513); // Brown default
  String? _selectedParentId;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    if (_isEditMode) {
      final category = widget.category!;
      _nameEnController = TextEditingController(
        text: category.name['en'] ?? '',
      );
      _nameArController = TextEditingController(
        text: category.name['ar'] ?? '',
      );
      _descriptionEnController = TextEditingController(
        text: category.description['en'] ?? '',
      );
      _descriptionArController = TextEditingController(
        text: category.description['ar'] ?? '',
      );
      _displayOrderController = TextEditingController(
        text: category.displayOrder.toString(),
      );
      _selectedColor = _parseColor(category.color);
      _selectedParentId = category.parentId;
      _isActive = category.isActive;
    } else {
      _nameEnController = TextEditingController();
      _nameArController = TextEditingController();
      _descriptionEnController = TextEditingController();
      _descriptionArController = TextEditingController();
      _displayOrderController = TextEditingController(text: '1');
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 750, maxWidth: 750),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: _buildForm(),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBrown, AppTheme.accentBrown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEditMode ? Icons.edit_rounded : Icons.add_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Edit Category' : 'Create New Category',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditMode
                      ? 'Update category information'
                      : 'Add a new coffee category',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English Name
          _buildSectionTitle('English Information'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameEnController,
            decoration: const InputDecoration(
              labelText: 'Category Name (English) *',
              hintText: 'e.g., Hot Coffee',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'English name is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // English Description
          TextFormField(
            controller: _descriptionEnController,
            decoration: const InputDecoration(
              labelText: 'Description (English) *',
              hintText: 'Brief description of the category',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'English description is required';
              }
              if (value.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Arabic Name
          _buildSectionTitle('Arabic Information (معلومات بالعربية)'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameArController,
            decoration: const InputDecoration(
              labelText: 'Category Name (Arabic) *',
              hintText: 'مثال: قهوة ساخنة',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            textDirection: TextDirection.rtl,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Arabic name is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
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
              hintText: 'وصف موجز للفئة',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            textDirection: TextDirection.rtl,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Arabic description is required';
              }
              if (value.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Display Order and Color
          _buildSectionTitle('Display Settings'),
          const SizedBox(height: 12),
          Row(
            children: [
              // Display Order
              Expanded(
                child: TextFormField(
                  controller: _displayOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Display Order *',
                    hintText: '1',
                    prefixIcon: Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(),
                    helperText: 'Lower numbers appear first',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Display order is required';
                    }
                    final order = int.tryParse(value);
                    if (order == null || order < 1) {
                      return 'Must be a positive number';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Color Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category Color *',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showColorPicker,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.color_lens, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _colorToHex(_selectedColor),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to change color',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Parent Category (Optional)
          _buildSectionTitle('Hierarchy (Optional)'),
          const SizedBox(height: 12),
          _buildParentCategoryDropdown(),

          const SizedBox(height: 24),

          // Active Status (Edit mode only)
          if (_isEditMode) ...[
            _buildSectionTitle('Status'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: Text(
                _isActive
                    ? 'Category is visible to customers'
                    : 'Category is hidden from customers',
              ),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
              activeColor: AppTheme.primaryBrown,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBrown,
      ),
    );
  }

  Widget _buildParentCategoryDropdown() {
    final topLevelCategories = widget.provider.getTopLevelCategories();

    // Filter out current category if editing
    final availableCategories = _isEditMode
        ? topLevelCategories.where((c) => c.id != widget.category!.id).toList()
        : topLevelCategories;

    return DropdownButtonFormField<String?>(
      value: _selectedParentId,
      decoration: const InputDecoration(
        labelText: 'Parent Category (Optional)',
        hintText: 'None - Top Level Category',
        prefixIcon: Icon(Icons.account_tree),
        border: OutlineInputBorder(),
        helperText: 'Leave empty for top-level category',
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('None - Top Level Category'),
        ),
        ...availableCategories.map((category) {
          return DropdownMenuItem<String?>(
            value: category.id,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _parseColor(category.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(category.name['en'] ?? 'Unnamed'),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() => _selectedParentId = value);
      },
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSubmit,
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
                  : (_isEditMode ? 'Update Category' : 'Add Category'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _showColorPicker() {
    // Predefined category colors
    final colors = [
      const Color(0xFF8B4513), // Saddle Brown
      const Color(0xFF4682B4), // Steel Blue
      const Color(0xFF2F1B14), // Dark Brown
      const Color(0xFFD2B48C), // Tan
      const Color(0xFFCD853F), // Peru
      const Color(0xFF228B22), // Forest Green
      const Color(0xFFDC143C), // Crimson
      const Color(0xFF9370DB), // Medium Purple
      const Color(0xFFFF8C00), // Dark Orange
      const Color(0xFF20B2AA), // Light Sea Green
      const Color(0xFFB8860B), // Dark Goldenrod
      const Color(0xFF4B0082), // Indigo
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedColor = color);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? Colors.black
                          : Colors.grey[300]!,
                      width: _selectedColor == color ? 3 : 1,
                    ),
                  ),
                  child: _selectedColor == color
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool success;
      if (_isEditMode) {
        success = await widget.provider.updateCategory(
          categoryId: widget.category!.id,
          nameEn: _nameEnController.text.trim(),
          nameAr: _nameArController.text.trim(),
          descriptionEn: _descriptionEnController.text.trim(),
          descriptionAr: _descriptionArController.text.trim(),
          color: _colorToHex(_selectedColor),
          displayOrder: int.parse(_displayOrderController.text),
          parentId: _selectedParentId,
          isActive: _isActive,
        );
      } else {
        success = await widget.provider.createCategory(
          nameEn: _nameEnController.text.trim(),
          nameAr: _nameArController.text.trim(),
          descriptionEn: _descriptionEnController.text.trim(),
          descriptionAr: _descriptionArController.text.trim(),
          color: _colorToHex(_selectedColor),
          displayOrder: int.parse(_displayOrderController.text),
          parentId: _selectedParentId,
          isActive: true,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Category updated successfully'
                    : 'Category created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.provider.errorMessage ??
                    'Failed to ${_isEditMode ? 'update' : 'create'} category',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== UTILITIES ====================

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      final colorValue = int.parse(
        hexColor.length == 6 ? 'FF$hexColor' : hexColor,
        radix: 16,
      );
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF8B4513); // Brown fallback
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
