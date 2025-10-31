import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/slider_provider.dart';
import '../../../../data/models/slider_model.dart';

/// Add/Edit Slider Dialog
/// Form dialog for creating or editing sliders/banners
class AddEditSliderDialog extends StatefulWidget {
  final SliderModel? slider;

  const AddEditSliderDialog({Key? key, this.slider}) : super(key: key);

  @override
  State<AddEditSliderDialog> createState() => _AddEditSliderDialogState();
}

class _AddEditSliderDialogState extends State<AddEditSliderDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _buttonTextController;
  late TextEditingController _buttonLinkController;
  late TextEditingController _backgroundColorController;
  late TextEditingController _textColorController;
  late TextEditingController _displayOrderController;
  late TextEditingController _altTextController;

  // Form state
  File? _imageFile;
  File? _mobileImageFile;
  String? _position;
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _targetAudience = [];
  List<String> _categories = [];
  List<String> _tags = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.slider?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.slider?.description ?? '',
    );
    _buttonTextController = TextEditingController(
      text: widget.slider?.buttonText ?? '',
    );
    _buttonLinkController = TextEditingController(
      text: widget.slider?.buttonLink ?? '',
    );
    _backgroundColorController = TextEditingController(
      text: widget.slider?.backgroundColor ?? '#A89A6A',
    );
    _textColorController = TextEditingController(
      text: widget.slider?.textColor ?? '#FFFFFF',
    );
    _displayOrderController = TextEditingController(
      text: widget.slider?.displayOrder.toString() ?? '0',
    );
    _altTextController = TextEditingController(
      text: widget.slider?.altText ?? '',
    );

    // Initialize state
    if (widget.slider != null) {
      _position = widget.slider!.position;
      _isActive = widget.slider!.isActive;
      _startDate = widget.slider!.startDate;
      _endDate = widget.slider!.endDate;
      _targetAudience = List.from(widget.slider!.targetAudience);
      _categories = List.from(widget.slider!.categories);
      _tags = List.from(widget.slider!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _buttonTextController.dispose();
    _buttonLinkController.dispose();
    _backgroundColorController.dispose();
    _textColorController.dispose();
    _displayOrderController.dispose();
    _altTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicFields(),
                      const SizedBox(height: 24),
                      _buildImageFields(),
                      const SizedBox(height: 24),
                      _buildButtonFields(),
                      const SizedBox(height: 24),
                      _buildStylingFields(),
                      const SizedBox(height: 24),
                      _buildSchedulingFields(),
                      const SizedBox(height: 24),
                      _buildAdvancedFields(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF6D4C3D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.view_carousel, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            widget.slider == null ? 'Add Slider' : 'Edit Slider',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ==================== BASIC FIELDS ====================

  Widget _buildBasicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: _inputDecoration('Title *', Icons.title),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Title is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: _inputDecoration('Description', Icons.description),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _displayOrderController,
                decoration: _inputDecoration('Display Order', Icons.reorder),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== IMAGE FIELDS ====================

  Widget _buildImageFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Images'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildImagePicker('Desktop Image *', _imageFile, (file) {
                setState(() => _imageFile = file);
              }, widget.slider?.image),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildImagePicker('Mobile Image', _mobileImageFile, (
                file,
              ) {
                setState(() => _mobileImageFile = file);
              }, widget.slider?.mobileImage),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _altTextController,
          decoration: _inputDecoration('Alt Text (SEO)', Icons.accessibility),
        ),
      ],
    );
  }

  Widget _buildImagePicker(
    String label,
    File? file,
    Function(File?) onSelected,
    String? existingUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
            );
            if (image != null) {
              onSelected(File(image.path));
            }
          },
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : existingUrl != null && existingUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(existingUrl, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select image',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
        if (file != null || (existingUrl != null && existingUrl.isNotEmpty))
          TextButton.icon(
            onPressed: () => onSelected(null),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
      ],
    );
  }

  // ==================== BUTTON FIELDS ====================

  Widget _buildButtonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Call-to-Action Button'),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buttonTextController,
          decoration: _inputDecoration('Button Text', Icons.smart_button),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _buttonLinkController,
          decoration: _inputDecoration('Button Link (URL)', Icons.link),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final uri = Uri.tryParse(value);
              if (uri == null || (!uri.hasScheme)) {
                return 'Please enter a valid URL';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  // ==================== STYLING FIELDS ====================

  Widget _buildStylingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Styling'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildColorPicker(
                'Background Color',
                _backgroundColorController,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildColorPicker('Text Color', _textColorController),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _position,
          decoration: _inputDecoration(
            'Content Position',
            Icons.align_horizontal_left,
          ),
          items: const [
            DropdownMenuItem(value: 'left', child: Text('Left')),
            DropdownMenuItem(value: 'center', child: Text('Center')),
            DropdownMenuItem(value: 'right', child: Text('Right')),
          ],
          onChanged: (value) => setState(() => _position = value),
        ),
      ],
    );
  }

  Widget _buildColorPicker(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _parseColor(controller.text),
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
            return 'Invalid color format (use #RRGGBB)';
          }
        }
        return null;
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  // ==================== SCHEDULING FIELDS ====================

  Widget _buildSchedulingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Scheduling'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker('Start Date', _startDate, (date) {
                setState(() => _startDate = date);
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker('End Date', _endDate, (date) {
                setState(() => _endDate = date);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    Function(DateTime?) onSelected,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onSelected(picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(label, Icons.calendar_today),
        child: Text(
          date != null ? '${date.year}-${date.month}-${date.day}' : 'Not set',
          style: TextStyle(color: date != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }

  // ==================== ADVANCED FIELDS ====================

  Widget _buildAdvancedFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Advanced Options'),
        const SizedBox(height: 12),
        _buildChipInput('Target Audience', _targetAudience, (list) {
          setState(() => _targetAudience = list);
        }),
        const SizedBox(height: 16),
        _buildChipInput('Categories', _categories, (list) {
          setState(() => _categories = list);
        }),
        const SizedBox(height: 16),
        _buildChipInput('Tags', _tags, (list) {
          setState(() => _tags = list);
        }),
      ],
    );
  }

  Widget _buildChipInput(
    String label,
    List<String> items,
    Function(List<String>) onChanged,
  ) {
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (items.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final newList = List<String>.from(items)..remove(item);
                  onChanged(newList);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: _inputDecoration('Add $label', Icons.add),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              color: const Color(0xFF6D4C3D),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final newList = List<String>.from(items)
                    ..add(controller.text);
                  onChanged(newList);
                  controller.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // ==================== FOOTER ====================

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D4C3D),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.slider == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6D4C3D),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // ==================== SUBMIT ====================

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate image for new slider
    if (widget.slider == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a desktop image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate date range
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<SliderProvider>();
    bool success;

    if (widget.slider == null) {
      // Create
      success = await provider.createSlider(
        title: _titleController.text,
        imagePath: _imageFile!.path,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        mobileImagePath: _mobileImageFile?.path,
        buttonText: _buttonTextController.text.isEmpty
            ? null
            : _buttonTextController.text,
        buttonLink: _buttonLinkController.text.isEmpty
            ? null
            : _buttonLinkController.text,
        backgroundColor: _backgroundColorController.text,
        textColor: _textColorController.text,
        position: _position,
        displayOrder: int.tryParse(_displayOrderController.text),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        targetAudience: _targetAudience.isEmpty ? null : _targetAudience,
        categories: _categories.isEmpty ? null : _categories,
        tags: _tags.isEmpty ? null : _tags,
        altText: _altTextController.text.isEmpty
            ? null
            : _altTextController.text,
      );
    } else {
      // Update
      success = await provider.updateSlider(
        id: widget.slider!.id,
        title: _titleController.text,
        imagePath: _imageFile?.path,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        mobileImagePath: _mobileImageFile?.path,
        buttonText: _buttonTextController.text.isEmpty
            ? null
            : _buttonTextController.text,
        buttonLink: _buttonLinkController.text.isEmpty
            ? null
            : _buttonLinkController.text,
        backgroundColor: _backgroundColorController.text,
        textColor: _textColorController.text,
        position: _position,
        displayOrder: int.tryParse(_displayOrderController.text),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        targetAudience: _targetAudience.isEmpty ? null : _targetAudience,
        categories: _categories.isEmpty ? null : _categories,
        tags: _tags.isEmpty ? null : _tags,
        altText: _altTextController.text.isEmpty
            ? null
            : _altTextController.text,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.slider == null ? 'Slider created' : 'Slider updated',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save slider'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
