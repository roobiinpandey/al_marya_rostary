/// Staff model matching backend Staff schema

class Staff {
  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String phone;
  final String role; // barista, manager, cashier
  final String status; // active, inactive, on_break
  final String? fcmToken;
  final List<String> assignedOrders;
  final StaffStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.fcmToken,
    required this.assignedOrders,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['_id'] ?? json['id'] ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'barista',
      status: json['status'] ?? 'active',
      fcmToken: json['fcmToken'],
      assignedOrders: List<String>.from(json['assignedOrders'] ?? []),
      stats: StaffStats.fromJson(json['stats'] ?? {}),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'fcmToken': fcmToken,
      'assignedOrders': assignedOrders,
      'stats': stats.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Staff copyWith({
    String? id,
    String? firebaseUid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? fcmToken,
    List<String>? assignedOrders,
    StaffStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      assignedOrders: assignedOrders ?? this.assignedOrders,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StaffStats {
  final int totalOrdersProcessed;
  final int ordersProcessedToday;
  final double averagePreparationTime;
  final DateTime? lastOrderProcessedAt;

  StaffStats({
    this.totalOrdersProcessed = 0,
    this.ordersProcessedToday = 0,
    this.averagePreparationTime = 0.0,
    this.lastOrderProcessedAt,
  });

  factory StaffStats.fromJson(Map<String, dynamic> json) {
    return StaffStats(
      totalOrdersProcessed: json['totalOrdersProcessed'] ?? 0,
      ordersProcessedToday: json['ordersProcessedToday'] ?? 0,
      averagePreparationTime: (json['averagePreparationTime'] ?? 0.0)
          .toDouble(),
      lastOrderProcessedAt: json['lastOrderProcessedAt'] != null
          ? DateTime.parse(json['lastOrderProcessedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrdersProcessed': totalOrdersProcessed,
      'ordersProcessedToday': ordersProcessedToday,
      'averagePreparationTime': averagePreparationTime,
      'lastOrderProcessedAt': lastOrderProcessedAt?.toIso8601String(),
    };
  }
}
