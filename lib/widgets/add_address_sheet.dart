import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/address_provider.dart';
import '../services/location_service.dart';
import '../models/saved_address.dart';

class AddAddressSheet extends StatefulWidget {
  const AddAddressSheet({super.key});

  @override
  State<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<AddAddressSheet> {
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  AddressType _selectedType = AddressType.home;
  bool _setAsDefault = false;

  @override
  void initState() {
    super.initState();
    _initializeWithCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _initializeWithCurrentLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // Get address for the current location
      await _onMapTap(_selectedLocation!);
    } catch (e) {
      // If location fails, use a default location (Dubai, UAE)
      setState(() {
        _selectedLocation = const LatLng(25.2048, 55.2708);
        _selectedAddress = 'Dubai, UAE';
      });
    }
  }

  Future<void> _onMapTap(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          if (placemark.street?.isNotEmpty == true) placemark.street,
          if (placemark.subLocality?.isNotEmpty == true) placemark.subLocality,
          if (placemark.locality?.isNotEmpty == true) placemark.locality,
          if (placemark.administrativeArea?.isNotEmpty == true)
            placemark.administrativeArea,
          if (placemark.country?.isNotEmpty == true) placemark.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Location selected';
        _isLoadingAddress = false;
      });
      // Log error in debug mode only
      assert(() {
        print('Error getting address: $e');
        return true;
      }());
    }
  }

  Future<void> _saveAddress() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this address')),
      );
      return;
    }

    final address = SavedAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      fullAddress: _selectedAddress,
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      buildingDetails: _buildingController.text.trim().isNotEmpty
          ? _buildingController.text.trim()
          : null,
      landmark: _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : null,
      type: _selectedType,
      createdAt: DateTime.now(),
      isDefault: _setAsDefault,
    );

    final success = await context.read<AddressProvider>().addAddress(address);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AddressProvider>().error ?? 'Failed to save address',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
                const Text(
                  'Add New Address',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedLocation != null ? _saveAddress : null,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Color(0xFFA89A6A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map section
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedLocation != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation!,
                          zoom: 16,
                        ),
                        onTap: _onMapTap,
                        markers: _selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: _selectedLocation!,
                                  draggable: true,
                                  onDragEnd: _onMapTap,
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapToolbarEnabled: false,
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),

          // Address display
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingAddress
                      ? const Text('Getting address...')
                      : Text(
                          _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : 'Tap on the map to select location',
                          style: TextStyle(
                            color: _selectedAddress.isNotEmpty
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Form section
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Address Name *',
                      hintText: 'e.g., Home, Office, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFA89A6A)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Building details
                  TextField(
                    controller: _buildingController,
                    decoration: InputDecoration(
                      labelText: 'Building/Apartment Details',
                      hintText: 'Building name, floor, apartment number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFA89A6A)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Landmark
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      labelText: 'Nearby Landmark',
                      hintText: 'Help delivery find you easier',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFA89A6A)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Address type
                  const Text(
                    'Address Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: AddressType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedType = type;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFFA89A6A,
                                      ).withValues(alpha: 0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFA89A6A)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 20,
                                    color: isSelected
                                        ? const Color(0xFFA89A6A)
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    type.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFA89A6A)
                                          : Colors.grey[600],
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Set as default
                  Row(
                    children: [
                      Checkbox(
                        value: _setAsDefault,
                        onChanged: (value) {
                          setState(() {
                            _setAsDefault = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFA89A6A),
                      ),
                      const Text('Set as default address'),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
