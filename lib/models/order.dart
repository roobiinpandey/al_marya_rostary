import 'cart.dart';

enum OrderStatus { pending, confirmed, preparing, ready, delivered, cancelled }

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final Map<String, dynamic>? deliveryAddress;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.deliveryAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json, String id) {
    final itemsMap = json['items'] as Map<String, dynamic>? ?? {};
    final items = itemsMap.entries
        .map(
          (entry) => CartItem.fromJson(Map<String, dynamic>.from(entry.value)),
        )
        .toList();

    return Order(
      id: id,
      userId: json['userId'] ?? '',
      items: items,
      total: (json['total'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (s) => s.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
      notes: json['notes'],
      deliveryAddress: json['deliveryAddress'] != null
          ? Map<String, dynamic>.from(json['deliveryAddress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final itemsMap = <String, Map<String, dynamic>>{};
    for (int i = 0; i < items.length; i++) {
      itemsMap[i.toString()] = items[i].toJson();
    }

    return {
      'userId': userId,
      'items': itemsMap,
      'total': total,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'notes': notes,
      'deliveryAddress': deliveryAddress,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    Map<String, dynamic>? deliveryAddress,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}
