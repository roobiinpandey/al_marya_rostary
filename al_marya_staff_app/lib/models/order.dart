/// Order model for Staff App (simplified from customer app)

class Order {
  final String id;
  final String orderNumber;
  final String status;
  final String deliveryMethod; // delivery, pickup, dine_in
  final double totalAmount;
  final List<OrderItem> items;
  final Customer? user;
  final DeliveryAddress? deliveryAddress;
  final String? assignedStaff;
  final String? assignedDriver;
  final PreparationTime? preparationTime;
  final DeliveryTime? deliveryTime;
  final StatusTimestamps statusTimestamps;
  final String? staffNotes;
  final String? driverNotes;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.deliveryMethod,
    required this.totalAmount,
    required this.items,
    this.user,
    this.deliveryAddress,
    this.assignedStaff,
    this.assignedDriver,
    this.preparationTime,
    this.deliveryTime,
    required this.statusTimestamps,
    this.staffNotes,
    this.driverNotes,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      status: json['status'] ?? 'pending',
      deliveryMethod: json['deliveryMethod'] ?? 'pickup',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      user: json['user'] != null ? Customer.fromJson(json['user']) : null,
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddress.fromJson(json['deliveryAddress'])
          : null,
      assignedStaff: json['assignedStaff']?['_id'] ?? json['assignedStaff'],
      assignedDriver: json['assignedDriver']?['_id'] ?? json['assignedDriver'],
      preparationTime: json['preparationTime'] != null
          ? PreparationTime.fromJson(json['preparationTime'])
          : null,
      deliveryTime: json['deliveryTime'] != null
          ? DeliveryTime.fromJson(json['deliveryTime'])
          : null,
      statusTimestamps: StatusTimestamps.fromJson(
        json['statusTimestamps'] ?? {},
      ),
      staffNotes: json['staffNotes'],
      driverNotes: json['driverNotes'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  bool get isAssignedToStaff => assignedStaff != null;
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isPending => status == 'pending';
}

class OrderItem {
  final String coffeeId;
  final String name;
  final int quantity;
  final double price;
  final String? size;
  final Map<String, dynamic>? customizations;

  OrderItem({
    required this.coffeeId,
    required this.name,
    required this.quantity,
    required this.price,
    this.size,
    this.customizations,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final coffee = json['coffee'] is Map ? json['coffee'] : null;

    return OrderItem(
      coffeeId: json['coffee']?['_id'] ?? json['coffeeId'] ?? '',
      name: coffee?['name'] ?? json['name'] ?? 'Unknown Item',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? coffee?['price'] ?? 0).toDouble(),
      size: json['size'],
      customizations: json['customizations'],
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;

  Customer({required this.id, required this.name, this.email, this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Customer',
      email: json['email'],
      phone: json['phone'],
    );
  }
}

class DeliveryAddress {
  final String? fullAddress;
  final String? street;
  final String? building;
  final String? area;

  DeliveryAddress({this.fullAddress, this.street, this.building, this.area});

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      fullAddress: json['fullAddress'],
      street: json['street'],
      building: json['building'],
      area: json['area'],
    );
  }

  String get displayAddress => fullAddress ?? '$building, $street, $area';
}

class PreparationTime {
  final int estimatedMinutes;
  final int? actualMinutes;

  PreparationTime({required this.estimatedMinutes, this.actualMinutes});

  factory PreparationTime.fromJson(Map<String, dynamic> json) {
    return PreparationTime(
      estimatedMinutes: json['estimatedMinutes'] ?? 15,
      actualMinutes: json['actualMinutes'],
    );
  }
}

class DeliveryTime {
  final int estimatedMinutes;
  final int? actualMinutes;

  DeliveryTime({required this.estimatedMinutes, this.actualMinutes});

  factory DeliveryTime.fromJson(Map<String, dynamic> json) {
    return DeliveryTime(
      estimatedMinutes: json['estimatedMinutes'] ?? 30,
      actualMinutes: json['actualMinutes'],
    );
  }
}

class StatusTimestamps {
  final DateTime? placed;
  final DateTime? confirmed;
  final DateTime? acceptedByStaff;
  final DateTime? preparationStarted;
  final DateTime? preparationCompleted;
  final DateTime? markedReady;
  final DateTime? acceptedByDriver;
  final DateTime? pickedUpByDriver;
  final DateTime? outForDelivery;
  final DateTime? delivered;
  final DateTime? cancelled;

  StatusTimestamps({
    this.placed,
    this.confirmed,
    this.acceptedByStaff,
    this.preparationStarted,
    this.preparationCompleted,
    this.markedReady,
    this.acceptedByDriver,
    this.pickedUpByDriver,
    this.outForDelivery,
    this.delivered,
    this.cancelled,
  });

  factory StatusTimestamps.fromJson(Map<String, dynamic> json) {
    return StatusTimestamps(
      placed: json['placed'] != null ? DateTime.parse(json['placed']) : null,
      confirmed: json['confirmed'] != null
          ? DateTime.parse(json['confirmed'])
          : null,
      acceptedByStaff: json['acceptedByStaff'] != null
          ? DateTime.parse(json['acceptedByStaff'])
          : null,
      preparationStarted: json['preparationStarted'] != null
          ? DateTime.parse(json['preparationStarted'])
          : null,
      preparationCompleted: json['preparationCompleted'] != null
          ? DateTime.parse(json['preparationCompleted'])
          : null,
      markedReady: json['markedReady'] != null
          ? DateTime.parse(json['markedReady'])
          : null,
      acceptedByDriver: json['acceptedByDriver'] != null
          ? DateTime.parse(json['acceptedByDriver'])
          : null,
      pickedUpByDriver: json['pickedUpByDriver'] != null
          ? DateTime.parse(json['pickedUpByDriver'])
          : null,
      outForDelivery: json['outForDelivery'] != null
          ? DateTime.parse(json['outForDelivery'])
          : null,
      delivered: json['delivered'] != null
          ? DateTime.parse(json['delivered'])
          : null,
      cancelled: json['cancelled'] != null
          ? DateTime.parse(json['cancelled'])
          : null,
    );
  }
}
