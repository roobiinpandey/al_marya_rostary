class Order {
  final String id;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final CustomerInfo customer;
  final DeliveryAddress? deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final String? driverId;
  final String? driverName;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.customer,
    this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    this.driverId,
    this.driverName,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle customer data from different formats
    Map<String, dynamic> customerData;
    if (json['user'] != null && json['user'] is Map) {
      customerData = json['user'];
    } else if (json['customer'] != null && json['customer'] is Map) {
      customerData = json['customer'];
    } else {
      // Customer data is directly in the order (customerName, customerPhone, etc.)
      customerData = {
        '_id': json['userId'] ?? '',
        'name': json['customerName'] ?? 'Customer',
        'phone': json['customerPhone'] ?? '',
        'email': json['customerEmail'],
      };
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      customer: CustomerInfo.fromJson(customerData),
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddress.fromJson(json['deliveryAddress'])
          : null,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      driverId: json['driver']?['_id'] ?? json['driverId'],
      driverName: json['driver']?['name'] ?? json['driverName'],
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderNumber': orderNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'customer': customer.toJson(),
      'deliveryAddress': deliveryAddress?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'driverId': driverId,
      'driverName': driverName,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? status,
    DateTime? createdAt,
    CustomerInfo? customer,
    DeliveryAddress? deliveryAddress,
    List<OrderItem>? items,
    double? totalAmount,
    String? driverId,
    String? driverName,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      customer: customer ?? this.customer,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}

class CustomerInfo {
  final String id;
  final String name;
  final String phone;
  final String? email;

  CustomerInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Customer',
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'phone': phone, 'email': email};
  }
}

class DeliveryAddress {
  final String street;
  final String? building;
  final String? apartment;
  final String? city;
  final String? area;
  final double? latitude;
  final double? longitude;
  final String? instructions;

  DeliveryAddress({
    required this.street,
    this.building,
    this.apartment,
    this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.instructions,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      street: json['street'] ?? json['fullAddress'] ?? '',
      building: json['building'],
      apartment: json['apartment'],
      city: json['city'],
      area: json['area'],
      latitude:
          json['coordinates']?['latitude']?.toDouble() ??
          json['latitude']?.toDouble(),
      longitude:
          json['coordinates']?['longitude']?.toDouble() ??
          json['longitude']?.toDouble(),
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'building': building,
      'apartment': apartment,
      'city': city,
      'area': area,
      'latitude': latitude,
      'longitude': longitude,
      'instructions': instructions,
    };
  }

  String get fullAddress {
    // If street already contains the full address (from backend's fullAddress field)
    // and no other fields are set, just return it
    if (street.isNotEmpty &&
        (building == null || building!.isEmpty) &&
        (apartment == null || apartment!.isEmpty) &&
        (area == null || area!.isEmpty) &&
        (city == null || city!.isEmpty)) {
      return street;
    }

    // Otherwise, build the address from components
    final parts = <String>[];
    if (apartment != null && apartment!.isNotEmpty) {
      parts.add('Apt $apartment');
    }
    if (building != null && building!.isNotEmpty) {
      parts.add('Bldg $building');
    }
    if (street.isNotEmpty) {
      parts.add(street);
    }
    if (area != null && area!.isNotEmpty) {
      parts.add(area!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    return parts.join(', ');
  }
}

class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? size;
  final List<String>? addons;
  final String? notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.size,
    this.addons,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Safely parse addons
    List<String>? addonsList;
    if (json['addons'] != null) {
      try {
        if (json['addons'] is List) {
          addonsList = (json['addons'] as List)
              .map((e) => e.toString())
              .toList();
        } else if (json['addOns'] != null && json['addOns'] is List) {
          // Handle both 'addons' and 'addOns' (camelCase)
          addonsList = (json['addOns'] as List)
              .map((e) => e.toString())
              .toList();
        }
      } catch (e) {
        print('Error parsing addons: $e');
        addonsList = null;
      }
    }

    return OrderItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['product']?['name'] ?? json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      size: json['size'],
      addons: addonsList,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'size': size,
      'addons': addons,
      'notes': notes,
    };
  }

  double get totalPrice => price * quantity;
}
