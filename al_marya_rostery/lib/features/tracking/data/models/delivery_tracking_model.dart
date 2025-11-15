import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model for delivery tracking information
class DeliveryTrackingData {
  final String orderId;
  final String orderNumber;
  final String status;
  final DateTime? estimatedArrivalStart;
  final DateTime? estimatedArrivalEnd;
  final LocationData? pickupLocation;
  final LocationData? deliveryLocation;
  final DriverLocation? driverLocation;
  final List<DeliveryStep> steps;
  final String? routePolyline;
  final RestaurantInfo restaurantInfo;
  final DeliveryAddress deliveryAddress;
  final ReceiverDetails? receiverDetails;

  DeliveryTrackingData({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    this.estimatedArrivalStart,
    this.estimatedArrivalEnd,
    this.pickupLocation,
    this.deliveryLocation,
    this.driverLocation,
    required this.steps,
    this.routePolyline,
    required this.restaurantInfo,
    required this.deliveryAddress,
    this.receiverDetails,
  });

  factory DeliveryTrackingData.fromJson(Map<String, dynamic> json) {
    return DeliveryTrackingData(
      orderId: json['_id'] ?? json['id'],
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      estimatedArrivalStart: json['estimatedArrivalStart'] != null
          ? DateTime.parse(json['estimatedArrivalStart'])
          : null,
      estimatedArrivalEnd: json['estimatedArrivalEnd'] != null
          ? DateTime.parse(json['estimatedArrivalEnd'])
          : null,
      pickupLocation: json['pickupLocation'] != null
          ? LocationData.fromJson(json['pickupLocation'])
          : null,
      deliveryLocation: json['deliveryAddress']?['gps'] != null
          ? LocationData(
              latitude: json['deliveryAddress']['gps']['latitude'],
              longitude: json['deliveryAddress']['gps']['longitude'],
              address: json['deliveryAddress']['address'] ?? '',
            )
          : null,
      driverLocation: json['driverTracking']?['currentLocation'] != null
          ? DriverLocation.fromJson(json['driverTracking']['currentLocation'])
          : null,
      steps: _generateSteps(json),
      routePolyline: json['driverTracking']?['routePolyline'],
      restaurantInfo: RestaurantInfo.fromJson(json),
      deliveryAddress: DeliveryAddress.fromJson(json['deliveryAddress'] ?? {}),
      receiverDetails: json['receiverDetails'] != null
          ? ReceiverDetails.fromJson(json['receiverDetails'])
          : null,
    );
  }

  static List<DeliveryStep> _generateSteps(Map<String, dynamic> json) {
    final status = json['status'] ?? 'pending';
    final timestamps = json['statusTimestamps'] ?? {};

    return [
      DeliveryStep(
        title: 'Order Placed',
        description: 'Your order has been confirmed',
        icon: 'order_placed',
        isCompleted: true,
        timestamp: timestamps['placed'] != null
            ? DateTime.parse(timestamps['placed'])
            : null,
      ),
      DeliveryStep(
        title: 'Preparing',
        description: 'We\'re preparing your order',
        icon: 'preparing',
        isCompleted: [
          'preparing',
          'ready',
          'assigned',
          'out-for-delivery',
          'delivered',
        ].contains(status),
        timestamp: timestamps['preparing'] != null
            ? DateTime.parse(timestamps['preparing'])
            : null,
      ),
      DeliveryStep(
        title: 'Out for Delivery',
        description: 'Driver is on the way',
        icon: 'out_for_delivery',
        isCompleted: ['out-for-delivery', 'delivered'].contains(status),
        timestamp: timestamps['outForDelivery'] != null
            ? DateTime.parse(timestamps['outForDelivery'])
            : null,
      ),
      DeliveryStep(
        title: 'Delivered',
        description: 'Order successfully delivered',
        icon: 'delivered',
        isCompleted: status == 'delivered',
        timestamp: timestamps['delivered'] != null
            ? DateTime.parse(timestamps['delivered'])
            : null,
      ),
    ];
  }

  String getStatusBadge() {
    if (status == 'delivered') return 'DELIVERED';

    if (estimatedArrivalEnd == null) return 'ON TIME';

    final now = DateTime.now();
    if (now.isAfter(estimatedArrivalEnd!)) {
      return 'DELAYED';
    } else if (now.isAfter(
      estimatedArrivalEnd!.subtract(const Duration(minutes: 10)),
    )) {
      return 'ON TIME';
    } else {
      return 'ON TIME';
    }
  }

  String getEtaDisplay() {
    if (estimatedArrivalStart == null || estimatedArrivalEnd == null) {
      return 'Calculating...';
    }

    final start = _formatTime(estimatedArrivalStart!);
    final end = _formatTime(estimatedArrivalEnd!);
    return '$start – $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Location data with coordinates and address
class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
    );
  }

  LatLng toLatLng() => LatLng(latitude, longitude);
}

/// Driver's current location with tracking info
class DriverLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime? updatedAt;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.updatedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  LatLng toLatLng() => LatLng(latitude, longitude);
}

/// Step in the delivery process
class DeliveryStep {
  final String title;
  final String description;
  final String icon;
  final bool isCompleted;
  final DateTime? timestamp;

  DeliveryStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.isCompleted,
    this.timestamp,
  });
}

/// Restaurant/Roastery information
class RestaurantInfo {
  final String name;
  final String phone;
  final String? supportPhone;

  RestaurantInfo({required this.name, required this.phone, this.supportPhone});

  factory RestaurantInfo.fromJson(Map<String, dynamic> json) {
    return RestaurantInfo(
      name: 'Al Marya Rostery', // Default
      phone: '+971 4 XXX XXXX', // Replace with actual
      supportPhone: '+971 50 XXX XXXX', // Replace with actual
    );
  }
}

/// Delivery address details
class DeliveryAddress {
  final String fullAddress;
  final String? instructions;
  final String? phone;

  DeliveryAddress({required this.fullAddress, this.instructions, this.phone});

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullAddress: json['address'] ?? '',
      instructions: json['instructions'] ?? json['specialInstructions'],
      phone: json['phone'],
    );
  }
}

/// Receiver details (current user or someone else)
class ReceiverDetails {
  final bool isCurrentUser;
  final String? receiverName;
  final String? receiverPhone;

  ReceiverDetails({
    required this.isCurrentUser,
    this.receiverName,
    this.receiverPhone,
  });

  factory ReceiverDetails.fromJson(Map<String, dynamic> json) {
    return ReceiverDetails(
      isCurrentUser: json['isCurrentUser'] ?? true,
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCurrentUser': isCurrentUser,
      if (receiverName != null) 'receiverName': receiverName,
      if (receiverPhone != null) 'receiverPhone': receiverPhone,
    };
  }
}
