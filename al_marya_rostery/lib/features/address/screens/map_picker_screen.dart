import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const MapPickerScreen({super.key, this.initialPosition, this.initialAddress});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _selectedPosition;
  String _selectedAddress = 'Fetching address...';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  String? _error;

  // Default location: Riyadh, Saudi Arabia
  static const LatLng _defaultLocation = LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? _defaultLocation;
    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
    } else {
      _getAddressFromLatLng(_selectedPosition!);
    }
  }

  // Request location permission
  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _error = null;
      });

      // Check permission
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Location permission denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedPosition = newPosition;
        _isLoadingLocation = false;
      });

      // Move camera to current location
      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16.0));

      // Get address for current location
      await _getAddressFromLatLng(newPosition);
    } catch (e) {
      setState(() {
        _error = 'Failed to get current location: $e';
        _isLoadingLocation = false;
      });
      debugPrint('❌ Error getting current location: $e');
    }
  }

  // Get address from coordinates using reverse geocoding
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      setState(() {
        _isLoadingAddress = true;
        _selectedAddress = 'Fetching address...';
      });

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String>[];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        setState(() {
          _selectedAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Address not found';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _selectedAddress = 'Address not found';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Failed to get address';
        _isLoadingAddress = false;
      });
      debugPrint('❌ Error getting address: $e');
    }
  }

  // Handle map tap
  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
    _getAddressFromLatLng(position);
  }

  // Confirm location selection
  void _confirmLocation() {
    if (_selectedPosition != null) {
      Navigator.pop(context, {
        'position': _selectedPosition,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition ?? _defaultLocation,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              _mapController.complete(controller);
            },
            onTap: _onMapTapped,
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedPosition!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedPosition = newPosition;
                        });
                        _getAddressFromLatLng(newPosition);
                      },
                    ),
                  }
                : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // Address display card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey[850] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isLoadingAddress
                        ? Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Fetching address...'),
                            ],
                          )
                        : Text(
                            _selectedAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ),
          ),

          // Current location button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              backgroundColor: isDark ? Colors.grey[850] : Colors.white,
              foregroundColor: theme.primaryColor,
              elevation: 4,
              child: _isLoadingLocation
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Error message
          if (_error != null)
            Positioned(
              bottom: 160,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.red[700],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _error = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Confirm button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _selectedPosition != null && !_isLoadingAddress
                  ? _confirmLocation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Confirm Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}
