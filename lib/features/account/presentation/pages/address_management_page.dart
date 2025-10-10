import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class Address {
  final String id;
  final String title;
  final String fullName;
  final String phoneNumber;
  final String emirate;
  final String area;
  final String street;
  final String building;
  final String? apartment;
  final String? landmark;
  final bool isDefault;

  Address({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phoneNumber,
    required this.emirate,
    required this.area,
    required this.street,
    required this.building,
    this.apartment,
    this.landmark,
    this.isDefault = false,
  });

  String get formattedAddress {
    final parts = [
      building,
      if (apartment != null && apartment!.isNotEmpty) 'Apt $apartment',
      street,
      area,
      emirate,
    ];
    return parts.join(', ');
  }
}

class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({super.key});

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    // TODO: Load from API
    setState(() {
      _addresses = [
        Address(
          id: '1',
          title: 'Home',
          fullName: 'Ahmed Al Mansouri',
          phoneNumber: '+971 50 123 4567',
          emirate: 'Dubai',
          area: 'Business Bay',
          street: 'Sheikh Zayed Road',
          building: 'Executive Heights, Tower A',
          apartment: '2304',
          landmark: 'Near Metro Station',
          isDefault: true,
        ),
        Address(
          id: '2',
          title: 'Office',
          fullName: 'Ahmed Al Mansouri',
          phoneNumber: '+971 50 123 4567',
          emirate: 'Dubai',
          area: 'DIFC',
          street: 'Gate Avenue',
          building: 'ICD Brookfield Place',
          apartment: '1205',
          isDefault: false,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Addresses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAddress(),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_addresses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Address Count Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundCream,
          child: Text(
            '${_addresses.length} ${_addresses.length == 1 ? 'Address' : 'Addresses'} Saved',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Address List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _addresses.length,
            itemBuilder: (context, index) {
              return _buildAddressCard(_addresses[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: AppTheme.textLight),
            const SizedBox(height: 24),
            Text(
              'No Addresses Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your delivery addresses to make checkout faster and easier.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddAddress(),
              icon: const Icon(Icons.add_location),
              label: const Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Title and Default Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Name and Phone
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppTheme.textMedium),
                const SizedBox(width: 8),
                Text(
                  address.fullName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.phone, size: 16, color: AppTheme.textMedium),
                const SizedBox(width: 8),
                Text(
                  address.phoneNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.textMedium,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.formattedAddress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMedium,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            if (address.landmark != null && address.landmark!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: AppTheme.textMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Landmark: ${address.landmark}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (!address.isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setAsDefault(address),
                      icon: const Icon(Icons.star_border, size: 18),
                      label: const Text('Set as Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBrown,
                        side: const BorderSide(color: AppTheme.primaryBrown),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (!address.isDefault) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEditAddress(address),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBrown,
                      side: const BorderSide(color: AppTheme.primaryBrown),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteAddress(address),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete address',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAddress() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const AddEditAddressPage()),
        )
        .then((result) {
          if (result == true) {
            _loadAddresses(); // Reload addresses after adding
          }
        });
  }

  void _navigateToEditAddress(Address address) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditAddressPage(address: address),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadAddresses(); // Reload addresses after editing
          }
        });
  }

  void _setAsDefault(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set as Default'),
        content: Text('Make "${address.title}" your default delivery address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Remove default from all addresses
                for (int i = 0; i < _addresses.length; i++) {
                  _addresses[i] = Address(
                    id: _addresses[i].id,
                    title: _addresses[i].title,
                    fullName: _addresses[i].fullName,
                    phoneNumber: _addresses[i].phoneNumber,
                    emirate: _addresses[i].emirate,
                    area: _addresses[i].area,
                    street: _addresses[i].street,
                    building: _addresses[i].building,
                    apartment: _addresses[i].apartment,
                    landmark: _addresses[i].landmark,
                    isDefault: _addresses[i].id == address.id,
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${address.title} is now your default address'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Default'),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${address.title}"?'),
            const SizedBox(height: 8),
            Text(
              address.formattedAddress,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textMedium),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _addresses.removeWhere((addr) => addr.id == address.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${address.title} deleted'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _addresses.add(address);
                      });
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Add/Edit Address Page
class AddEditAddressPage extends StatefulWidget {
  final Address? address;

  const AddEditAddressPage({super.key, this.address});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _selectedEmirate = 'Dubai';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddressData();
    }
  }

  void _loadAddressData() {
    final address = widget.address!;
    _titleController.text = address.title;
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phoneNumber;
    _selectedEmirate = address.emirate;
    _areaController.text = address.area;
    _streetController.text = address.street;
    _buildingController.text = address.building;
    _apartmentController.text = address.apartment ?? '';
    _landmarkController.text = address.landmark ?? '';
    _isDefault = address.isDefault;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Address' : 'Add Address',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Label
                _buildTextField(
                  controller: _titleController,
                  label: 'Address Label',
                  icon: Icons.label,
                  hint: 'e.g. Home, Office, etc.',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an address label';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Contact Information Section
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the recipient name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Address Details Section
                _buildSectionHeader('Address Details'),
                const SizedBox(height: 16),

                // Emirate Dropdown
                _buildEmirateDropdown(),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _areaController,
                  label: 'Area/District',
                  icon: Icons.location_city,
                  hint: 'e.g. Business Bay, JLT, etc.',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the area';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _streetController,
                  label: 'Street',
                  icon: Icons.streetview,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the street';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _buildingController,
                  label: 'Building Name/Number',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the building';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _apartmentController,
                  label: 'Apartment/Office Number',
                  icon: Icons.door_front_door,
                  hint: 'Optional',
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: _landmarkController,
                  label: 'Landmark',
                  icon: Icons.place,
                  hint: 'Optional - to help delivery find you',
                ),

                const SizedBox(height: 24),

                // Set as Default
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Set as Default Address',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Use this address for future orders',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value;
                      });
                    },
                    activeColor: AppTheme.primaryBrown,
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEditing ? 'Update Address' : 'Save Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryBrown),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBrown, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundCream,
      ),
    );
  }

  Widget _buildEmirateDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEmirate,
      decoration: InputDecoration(
        labelText: 'Emirate',
        prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryBrown),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBrown, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundCream,
      ),
      items:
          [
            'Dubai',
            'Abu Dhabi',
            'Sharjah',
            'Ajman',
            'Ras Al Khaimah',
            'Fujairah',
            'Umm Al Quwain',
          ].map((emirate) {
            return DropdownMenuItem(value: emirate, child: Text(emirate));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedEmirate = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an emirate';
        }
        return null;
      },
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save address
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address != null
                  ? 'Address updated successfully!'
                  : 'Address saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
