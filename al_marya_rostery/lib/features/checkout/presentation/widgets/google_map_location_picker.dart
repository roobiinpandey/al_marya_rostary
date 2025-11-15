import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../../../core/theme/app_theme.dart';

/// Model to hold location data
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, address: $address)';
}

/// Google Map location picker screen
class GoogleMapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const GoogleMapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<GoogleMapLocationPicker> createState() =>
      _GoogleMapLocationPickerState();
}

class _GoogleMapLocationPickerState extends State<GoogleMapLocationPicker> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = true;
  bool _isReverseGeocoding = false;
  String? _error;

  // Dubai coordinates as default center
  static const LatLng _defaultCenter = LatLng(25.2048, 55.2708);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if initial location provided
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        final location = LatLng(
          widget.initialLatitude!,
          widget.initialLongitude!,
        );
        await _reverseGeocodeLocation(location);
        if (mounted) {
          setState(() {
            _selectedLocation = location;
            _isLoading = false;
          });
        }
        return;
      }

      // Try to get current location
      final position = await _getCurrentLocation();
      if (position != null) {
        final location = LatLng(position.latitude, position.longitude);
        await _reverseGeocodeLocation(location);
        if (mounted) {
          setState(() {
            _selectedLocation = location;
            _isLoading = false;
          });
        }
      } else {
        // Fall back to Dubai center
        if (mounted) {
          setState(() {
            _selectedLocation = _defaultCenter;
            _selectedAddress = 'Dubai, UAE';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize location: $e';
          _selectedLocation = _defaultCenter;
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested != LocationPermission.whileInUse &&
            requested != LocationPermission.always) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  Future<void> _reverseGeocodeLocation(LatLng location) async {
    try {
      if (mounted) {
        setState(() {
          _isReverseGeocoding = true;
        });
      }

      final placemarks = await geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String?>[
          place.street,
          place.thoroughfare,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].whereType<String>().where((e) => e.isNotEmpty).toList();

        final address = addressParts.join(', ');

        if (mounted) {
          setState(() {
            _selectedAddress = address.isNotEmpty
                ? address
                : '${location.latitude}, ${location.longitude}';
            _isReverseGeocoding = false;
          });
        }
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = '${location.latitude}, ${location.longitude}';
          _isReverseGeocoding = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });
    await _reverseGeocodeLocation(location);

    // Animate camera to new location
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 16),
      ),
    );
  }

  void _onConfirm() {
    if (_selectedLocation != null && _selectedAddress.isNotEmpty) {
      Navigator.of(context).pop(
        LocationData(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          address: _selectedAddress,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _defaultCenter,
                    zoom: 16,
                  ),
                  onTap: _onMapTapped,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected-location'),
                            position: _selectedLocation!,
                            infoWindow: InfoWindow(
                              title: 'Selected Location',
                              snippet: _selectedAddress,
                            ),
                          ),
                        }
                      : {},
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: true,
                ),

                // Center crosshair indicator
                Center(
                  child: Semantics(
                    label: 'Map center indicator',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBrown,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppTheme.primaryBrown,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Error message at top
                if (_error != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                // Address display and confirm button at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address label
                        const Text(
                          'Selected Address:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),

                        // Address display
                        if (_isReverseGeocoding)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Getting address...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Lat: ${_selectedLocation?.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation?.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Confirm button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isReverseGeocoding ? null : _onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBrown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
