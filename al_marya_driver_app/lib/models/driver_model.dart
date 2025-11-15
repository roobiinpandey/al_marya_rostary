class Driver {
  final String id;
  final String name;
  final String phone;
  final String status; // 'available', 'on_delivery', 'offline', 'on_break'
  final String? qrBadge;
  final VehicleInfo? vehicle;
  final Location? currentLocation;
  final DriverStats? stats;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.qrBadge,
    this.vehicle,
    this.currentLocation,
    this.stats,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'offline',
      qrBadge: json['qrBadge'],
      vehicle: json['vehicle'] != null
          ? VehicleInfo.fromJson(json['vehicle'])
          : null,
      currentLocation: json['currentLocation'] != null
          ? Location.fromJson(json['currentLocation'])
          : null,
      stats: json['stats'] != null ? DriverStats.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
      'status': status,
      'qrBadge': qrBadge,
      'vehicle': vehicle?.toJson(),
      'currentLocation': currentLocation?.toJson(),
      'stats': stats?.toJson(),
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? status,
    String? qrBadge,
    VehicleInfo? vehicle,
    Location? currentLocation,
    DriverStats? stats,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      qrBadge: qrBadge ?? this.qrBadge,
      vehicle: vehicle ?? this.vehicle,
      currentLocation: currentLocation ?? this.currentLocation,
      stats: stats ?? this.stats,
    );
  }
}

class VehicleInfo {
  final String type;
  final String plateNumber;
  final String? color;
  final String? model;

  VehicleInfo({
    required this.type,
    required this.plateNumber,
    this.color,
    this.model,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      type: json['type'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      color: json['color'],
      model: json['model'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'plateNumber': plateNumber,
      'color': color,
      'model': model,
    };
  }
}

class Location {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  Location({required this.latitude, required this.longitude, this.timestamp});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class DriverStats {
  final int totalDeliveries;
  final int completedToday;
  final double averageRating;
  final double totalEarnings;

  DriverStats({
    required this.totalDeliveries,
    required this.completedToday,
    required this.averageRating,
    required this.totalEarnings,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      totalDeliveries: json['totalDeliveries'] ?? 0,
      completedToday: json['completedToday'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDeliveries': totalDeliveries,
      'completedToday': completedToday,
      'averageRating': averageRating,
      'totalEarnings': totalEarnings,
    };
  }
}
