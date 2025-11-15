import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/order.dart';
import '../../features/checkout/data/services/order_service.dart';

/// Lightweight polling-based order tracking service.
/// - Polls order details every [interval]
/// - Emits updates via a broadcast stream
/// - Stops automatically when order is delivered or cancelled
/// - Supports manual refresh and simple backoff on repeated failures
class OrderTrackingService {
  final OrderService _orderService = OrderService();
  Timer? _timer;
  final StreamController<Order> _controller =
      StreamController<Order>.broadcast();

  Order? _last;
  String? _orderId;
  Duration _interval = const Duration(seconds: 15);
  int _failures = 0;

  Stream<Order> track(
    String orderId, {
    Duration interval = const Duration(seconds: 15),
  }) {
    // Ensure any previous polling is cancelled
    stop();
    _orderId = orderId;
    _interval = interval;
    _failures = 0;

    // Immediate tick then start periodic polling
    Future<void>.microtask(() => _tick());
    _startTimer();

    return _controller.stream;
  }

  void _startTimer() {
    _timer?.cancel();
    if (_orderId == null) return;
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  Future<void> _tick() async {
    final orderId = _orderId;
    if (orderId == null) return;
    try {
      // Auth token automatically injected by AuthInterceptor
      final data = await _orderService.getOrderDetails(orderId);

      final orderJson = Map<String, dynamic>.from(data);
      final id = orderJson['_id'] as String? ?? orderId;
      final order = Order.fromJson(orderJson, id);

      final statusChanged = _last == null || _last!.status != order.status;
      final timeChanged = _last == null || _last!.updatedAt != order.updatedAt;
      if (statusChanged || timeChanged) {
        _last = order;
        if (!_controller.isClosed) {
          _controller.add(order);
        }
      }

      // Success: reset failures and interval if we had backed off
      if (_failures > 0 && _interval != const Duration(seconds: 15)) {
        _interval = const Duration(seconds: 15);
        _startTimer();
      }
      _failures = 0;

      if (order.status == OrderStatus.delivered ||
          order.status == OrderStatus.cancelled) {
        stop();
      }
    } catch (e) {
      debugPrint('OrderTrackingService error: $e');
      // Backoff on repeated failures: 3->30s, 6->45s
      _failures++;
      if (_failures == 3 && _interval.inSeconds != 30) {
        _interval = const Duration(seconds: 30);
        _startTimer();
      } else if (_failures == 6 && _interval.inSeconds != 45) {
        _interval = const Duration(seconds: 45);
        _startTimer();
      }
    }
  }

  /// Manual immediate refresh. Safe to call anytime.
  Future<void> refreshNow() => _tick();

  void stop() {
    _timer?.cancel();
    _timer = null;
    _orderId = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
