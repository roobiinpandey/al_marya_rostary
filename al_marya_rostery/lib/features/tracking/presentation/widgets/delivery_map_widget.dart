import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/delivery_tracking_model.dart';

/// Widget displaying Google Maps with delivery route
class DeliveryMapWidget extends StatefulWidget {
  final LocationData? pickupLocation;
  final LocationData? deliveryLocation;
  final DriverLocation? driverLocation;
  final String? routePolyline;

  const DeliveryMapWidget({
    super.key,
    this.pickupLocation,
    this.deliveryLocation,
    this.driverLocation,
    this.routePolyline,
  });

  @override
  State<DeliveryMapWidget> createState() => _DeliveryMapWidgetState();
}

class _DeliveryMapWidgetState extends State<DeliveryMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Default center (Dubai) if no location data
  static const LatLng _defaultCenter = LatLng(25.2048, 55.2708);

  @override
  void initState() {
    super.initState();
    _updateMapData();
  }

  @override
  void didUpdateWidget(DeliveryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverLocation != widget.driverLocation ||
        oldWidget.pickupLocation != widget.pickupLocation ||
        oldWidget.deliveryLocation != widget.deliveryLocation) {
      _updateMapData();
    }
  }

  void _updateMapData() {
    _markers.clear();
    _polylines.clear();

    // Add pickup marker (Restaurant/Roastery)
    if (widget.pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLocation!.toLatLng(),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '🍴 Al Marya Rostery',
            snippet: widget.pickupLocation!.address,
          ),
        ),
      );
    }

    // Add delivery marker (Destination)
    if (widget.deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: widget.deliveryLocation!.toLatLng(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🏠 Delivery Address',
            snippet: widget.deliveryLocation!.address,
          ),
        ),
      );
    }

    // Add driver marker (Live Location)
    if (widget.driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverLocation!.toLatLng(),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: '🏍️ Driver',
            snippet: 'On the way',
          ),
          rotation: widget.driverLocation!.heading ?? 0.0,
        ),
      );
    }

    // Draw polyline route
    if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
      // Decode polyline (you'll need to implement or use a package like flutter_polyline_points)
      // For now, draw simple line between driver and delivery
      if (widget.driverLocation != null && widget.deliveryLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              widget.driverLocation!.toLatLng(),
              widget.deliveryLocation!.toLatLng(),
            ],
            color: AppTheme.primaryBrown,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    } else {
      // Simple line from pickup to delivery if no route polyline
      if (widget.pickupLocation != null && widget.deliveryLocation != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('simple_route'),
            points: [
              widget.pickupLocation!.toLatLng(),
              widget.deliveryLocation!.toLatLng(),
            ],
            color: AppTheme.primaryBrown.withOpacity(0.5),
            width: 3,
            patterns: [PatternItem.dot, PatternItem.gap(10)],
          ),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _recenterMap() {
    if (_mapController == null) return;

    // Calculate bounds to show all markers
    if (_markers.isEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_defaultCenter, 12),
      );
      return;
    }

    final positions = _markers.map((m) => m.position).toList();

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100 padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition =
        widget.driverLocation?.toLatLng() ??
        widget.deliveryLocation?.toLatLng() ??
        widget.pickupLocation?.toLatLng() ??
        _defaultCenter;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (controller) {
            _mapController = controller;
            // Recenter after map is created
            Future.delayed(const Duration(milliseconds: 500), _recenterMap);
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),

        // Recenter/Refresh button (bottom-right)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _recenterMap,
            child: const Icon(Icons.my_location, color: AppTheme.primaryBrown),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
