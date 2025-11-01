class SubscriptionModel {
  final String id;
  final String planId;
  final String planName;
  final String productId;
  final String productName;
  final String productSize;
  final String frequency;
  final String frequencyDisplay;
  final int quantity;
  final double originalPrice;
  final double discountPercentage;
  final double subscriptionPrice;
  final String currency;
  final DateTime startDate;
  final DateTime nextDelivery;
  final String status;
  final String userEmail;
  final String userName;
  final SubscriptionDeliveryAddress? deliveryAddress;
  final String? deliveryInstructions;
  final List<SubscriptionDelivery> deliveries;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.planId,
    required this.planName,
    required this.productId,
    required this.productName,
    required this.productSize,
    required this.frequency,
    required this.frequencyDisplay,
    required this.quantity,
    required this.originalPrice,
    required this.discountPercentage,
    required this.subscriptionPrice,
    required this.currency,
    required this.startDate,
    required this.nextDelivery,
    required this.status,
    required this.userEmail,
    required this.userName,
    this.deliveryAddress,
    this.deliveryInstructions,
    required this.deliveries,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] ?? json['id'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productSize: json['productSize'] ?? '',
      frequency: json['frequency'] ?? '',
      frequencyDisplay: json['frequencyDisplay'] ?? '',
      quantity: (json['quantity'] ?? 1).toInt(),
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      subscriptionPrice: (json['subscriptionPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'AED',
      startDate: DateTime.parse(json['startDate']),
      nextDelivery: DateTime.parse(json['nextDelivery']),
      status: json['status'] ?? 'active',
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? '',
      deliveryAddress: json['deliveryAddress'] != null
          ? SubscriptionDeliveryAddress.fromJson(json['deliveryAddress'])
          : null,
      deliveryInstructions: json['deliveryInstructions'],
      deliveries:
          (json['deliveries'] as List<dynamic>?)
              ?.map((e) => SubscriptionDelivery.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'productId': productId,
      'productName': productName,
      'productSize': productSize,
      'frequency': frequency,
      'frequencyDisplay': frequencyDisplay,
      'quantity': quantity,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'subscriptionPrice': subscriptionPrice,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'nextDelivery': nextDelivery.toIso8601String(),
      'status': status,
      'userEmail': userEmail,
      'userName': userName,
      'deliveryAddress': deliveryAddress?.toJson(),
      'deliveryInstructions': deliveryInstructions,
      'deliveries': deliveries.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get totalSavings => originalPrice - subscriptionPrice;

  String get formattedPrice =>
      '$currency ${subscriptionPrice.toStringAsFixed(2)}';

  String get formattedOriginalPrice =>
      '$currency ${originalPrice.toStringAsFixed(2)}';

  int get daysUntilNextDelivery =>
      nextDelivery.difference(DateTime.now()).inDays;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';
}

class SubscriptionDeliveryAddress {
  final String name;
  final String phone;
  final String street;
  final String city;
  final String emirate;
  final String area;
  final String? building;
  final String? apartment;
  final String? landmark;
  final bool isDefault;

  const SubscriptionDeliveryAddress({
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.emirate,
    required this.area,
    this.building,
    this.apartment,
    this.landmark,
    required this.isDefault,
  });

  factory SubscriptionDeliveryAddress.fromJson(Map<String, dynamic> json) {
    return SubscriptionDeliveryAddress(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      emirate: json['emirate'] ?? '',
      area: json['area'] ?? '',
      building: json['building'],
      apartment: json['apartment'],
      landmark: json['landmark'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'emirate': emirate,
      'area': area,
      'building': building,
      'apartment': apartment,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    final parts = [street, area, city, emirate].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }
}

class SubscriptionDelivery {
  final String id;
  final DateTime scheduledDate;
  final DateTime? deliveredDate;
  final String status;
  final String? trackingNumber;
  final String? notes;

  const SubscriptionDelivery({
    required this.id,
    required this.scheduledDate,
    this.deliveredDate,
    required this.status,
    this.trackingNumber,
    this.notes,
  });

  factory SubscriptionDelivery.fromJson(Map<String, dynamic> json) {
    return SubscriptionDelivery(
      id: json['_id'] ?? json['id'] ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate']),
      deliveredDate: json['deliveredDate'] != null
          ? DateTime.parse(json['deliveredDate'])
          : null,
      status: json['status'] ?? 'pending',
      trackingNumber: json['trackingNumber'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduledDate': scheduledDate.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'status': status,
      'trackingNumber': trackingNumber,
      'notes': notes,
    };
  }

  bool get isPending => status == 'pending';
  bool get isInTransit => status == 'in_transit';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String description;
  final String frequency;
  final double discountPercentage;
  final int minQuantity;
  final int maxQuantity;
  final bool isActive;
  final List<String> features;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.discountPercentage,
    required this.minQuantity,
    required this.maxQuantity,
    required this.isActive,
    required this.features,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? '',
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      minQuantity: (json['minQuantity'] ?? 1).toInt(),
      maxQuantity: (json['maxQuantity'] ?? 10).toInt(),
      isActive: json['isActive'] ?? true,
      features: List<String>.from(json['features'] ?? []),
      currency: json['currency'] ?? 'AED',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency,
      'discountPercentage': discountPercentage,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'isActive': isActive,
      'features': features,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedDiscount => '${discountPercentage.toStringAsFixed(0)}%';
}
