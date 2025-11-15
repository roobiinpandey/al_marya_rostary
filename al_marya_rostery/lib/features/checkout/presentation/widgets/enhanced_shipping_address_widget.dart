import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import 'google_map_location_picker.dart';

/// Enhanced shipping address widget with phone validation and Google Maps integration
class EnhancedShippingAddressWidget extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController emirateController;
  final Function(LocationData?)? onLocationSelected;
  final List<String> emirates;

  const EnhancedShippingAddressWidget({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.emirateController,
    required this.emirates,
    this.onLocationSelected,
  });

  @override
  State<EnhancedShippingAddressWidget> createState() =>
      _EnhancedShippingAddressWidgetState();
}

class _EnhancedShippingAddressWidgetState
    extends State<EnhancedShippingAddressWidget> {
  // Phone validation
  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+971 5#########',
    filter: {"#": RegExp(r'[0-9]')},
  );

  LocationData? _selectedMapLocation;
  String? _phoneError;
  String? _addressError;
  bool _isLoadingMap = false;
  bool _useManualAddress = false;

  // Phone validation regex: +971 5XXXXXXXX (exactly 12 characters)
  static const String _phonePattern = r'^\+971 5\d{8}$';

  @override
  void initState() {
    super.initState();
    widget.phoneController.addListener(_validatePhone);
    widget.addressController.addListener(_validateAddress);
  }

  @override
  void dispose() {
    widget.phoneController.removeListener(_validatePhone);
    widget.addressController.removeListener(_validateAddress);
    super.dispose();
  }

  void _validatePhone() {
    final phone = widget.phoneController.text.trim();
    setState(() {
      if (phone.isEmpty) {
        _phoneError = null;
      } else if (!RegExp(_phonePattern).hasMatch(phone)) {
        _phoneError = 'Enter phone in format +971 5XXXXXXXX';
      } else {
        _phoneError = null;
      }
    });
  }

  void _validateAddress() {
    final address = widget.addressController.text.trim();
    setState(() {
      if (address.isEmpty) {
        _addressError = null;
      } else {
        _addressError = null;
      }
    });
  }

  bool get isPhoneValid {
    final phone = widget.phoneController.text.trim();
    return phone.isNotEmpty && RegExp(_phonePattern).hasMatch(phone);
  }

  bool get isAddressValid {
    final address = widget.addressController.text.trim();
    return address.isNotEmpty;
  }

  bool get isFormValid => isPhoneValid && isAddressValid;

  Future<void> _openMapPicker() async {
    setState(() {
      _isLoadingMap = true;
    });

    try {
      final result = await Navigator.of(context).push<LocationData>(
        MaterialPageRoute(
          builder: (context) => GoogleMapLocationPicker(
            initialLatitude: _selectedMapLocation?.latitude,
            initialLongitude: _selectedMapLocation?.longitude,
          ),
        ),
      );

      if (result != null) {
        setState(() {
          _selectedMapLocation = result;
          widget.addressController.text = result.address;
          _useManualAddress = false;
        });

        widget.onLocationSelected?.call(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Location selected from Google Map'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==================== Full Name ====================
        Text(
          'Full Name',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.nameController,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryBrown,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // ==================== Phone Number ====================
        Text(
          'Phone Number',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [phoneMaskFormatter],
          decoration: InputDecoration(
            hintText: '+971 5XXXXXXXX',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _phoneError != null ? Colors.red : AppTheme.primaryBrown,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            suffixIcon:
                _phoneError == null && widget.phoneController.text.isNotEmpty
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          onChanged: (_) => _validatePhone(),
        ),
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _phoneError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),

        // ==================== City ====================
        Text(
          'City',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.cityController,
          decoration: InputDecoration(
            hintText: 'Enter your city',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryBrown,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your city';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // ==================== Emirate ====================
        Text(
          'Emirate',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.emirateController.text.isEmpty
              ? null
              : widget.emirateController.text,
          decoration: InputDecoration(
            hintText: 'Select emirate',
            prefixIcon: const Icon(Icons.flag),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryBrown,
                width: 2,
              ),
            ),
          ),
          items: widget.emirates.map((emirate) {
            return DropdownMenuItem(value: emirate, child: Text(emirate));
          }).toList(),
          onChanged: (value) {
            setState(() {
              widget.emirateController.text = value ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your emirate';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // ==================== Address Selection ====================
        Text(
          'Delivery Address',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Two-source address options
        Row(
          children: [
            // Google Map button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoadingMap ? null : _openMapPicker,
                icon: _isLoadingMap
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_on),
                label: const Text('Select on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMapLocation != null
                      ? Colors.green[50]
                      : Colors.blue[50],
                  foregroundColor: _selectedMapLocation != null
                      ? Colors.green[700]
                      : Colors.blue[700],
                  side: BorderSide(
                    color: _selectedMapLocation != null
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Manual entry toggle
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _useManualAddress = !_useManualAddress;
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Enter Manually'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _useManualAddress
                      ? AppTheme.primaryBrown
                      : Colors.grey,
                  side: BorderSide(
                    color: _useManualAddress
                        ? AppTheme.primaryBrown
                        : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Show badge if map location selected
        if (_selectedMapLocation != null && !_useManualAddress)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected from Google Map — editable',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Address text field (always editable)
        Text(
          _selectedMapLocation != null && !_useManualAddress
              ? 'Delivery Address'
              : 'Enter Address Manually',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Enter delivery address (house number, street, building name, etc.)',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 50),
              child: Icon(Icons.home),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _addressError != null
                    ? Colors.red
                    : AppTheme.primaryBrown,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          onChanged: (_) => _validateAddress(),
        ),
        if (_addressError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _addressError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 20),

        // Address coordinates if available
        if (_selectedMapLocation != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS Coordinates (for reference):',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lat: ${_selectedMapLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedMapLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Form validation summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFormValid ? Colors.green[50] : Colors.amber[50],
            border: Border.all(
              color: isFormValid ? Colors.green : Colors.amber,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isFormValid ? Icons.check_circle : Icons.info,
                color: isFormValid ? Colors.green : Colors.amber[700],
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isFormValid
                      ? '✅ Ready to proceed'
                      : !isPhoneValid && !isAddressValid
                      ? '⚠️ Phone and address required'
                      : !isPhoneValid
                      ? '⚠️ Valid phone required (+971 5XXXXXXXX)'
                      : '⚠️ Delivery address required',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFormValid ? Colors.green[700] : Colors.amber[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
