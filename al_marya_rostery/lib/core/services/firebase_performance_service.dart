import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Performance Monitoring
/// Tracks app performance metrics, network calls, and custom traces
class FirebasePerformanceService {
  static final FirebasePerformanceService _instance =
      FirebasePerformanceService._internal();
  factory FirebasePerformanceService() => _instance;
  FirebasePerformanceService._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;
  final Map<String, Trace> _traces = {};

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      await _performance.setPerformanceCollectionEnabled(true);
      if (kDebugMode) {
        print('✅ Firebase Performance Monitoring initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Performance Monitoring Error - Initialize: $e');
      }
    }
  }

  // ============================================================================
  // APP STARTUP TRACE
  // ============================================================================

  /// Start app initialization trace
  Trace? startAppStartTrace() {
    return _startTrace('app_start');
  }

  /// Stop app initialization trace
  Future<void> stopAppStartTrace() async {
    await _stopTrace('app_start');
  }

  // ============================================================================
  // SCREEN LOAD TRACES
  // ============================================================================

  /// Start screen load trace
  Trace? startScreenTrace(String screenName) {
    return _startTrace('screen_${screenName.toLowerCase()}');
  }

  /// Stop screen load trace
  Future<void> stopScreenTrace(String screenName) async {
    await _stopTrace('screen_${screenName.toLowerCase()}');
  }

  // ============================================================================
  // API CALL TRACES
  // ============================================================================

  /// Start API call trace
  Trace? startApiTrace(String endpoint) {
    final traceName = 'api_${endpoint.replaceAll('/', '_')}';
    return _startTrace(traceName);
  }

  /// Stop API call trace with status
  Future<void> stopApiTrace(
    String endpoint, {
    int? statusCode,
    int? responseSize,
    String? errorMessage,
  }) async {
    final traceName = 'api_${endpoint.replaceAll('/', '_')}';
    final trace = _traces[traceName];

    if (trace != null) {
      try {
        if (statusCode != null) {
          trace.setMetric('status_code', statusCode);
        }
        if (responseSize != null) {
          trace.setMetric('response_size_bytes', responseSize);
        }
        if (errorMessage != null) {
          trace.putAttribute('error', errorMessage);
        }
        trace.putAttribute(
          'success',
          (statusCode == null || statusCode < 400).toString(),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Performance Error - Set API metrics: $e');
        }
      }
    }

    await _stopTrace(traceName);
  }

  // ============================================================================
  // AUTHENTICATION TRACES
  // ============================================================================

  /// Start login trace
  Trace? startLoginTrace(String method) {
    final trace = _startTrace('auth_login');
    trace?.putAttribute('method', method);
    return trace;
  }

  /// Stop login trace
  Future<void> stopLoginTrace({bool success = true}) async {
    final trace = _traces['auth_login'];
    trace?.putAttribute('success', success.toString());
    await _stopTrace('auth_login');
  }

  /// Start signup trace
  Trace? startSignupTrace(String method) {
    final trace = _startTrace('auth_signup');
    trace?.putAttribute('method', method);
    return trace;
  }

  /// Stop signup trace
  Future<void> stopSignupTrace({bool success = true}) async {
    final trace = _traces['auth_signup'];
    trace?.putAttribute('success', success.toString());
    await _stopTrace('auth_signup');
  }

  // ============================================================================
  // CHECKOUT TRACES
  // ============================================================================

  /// Start checkout trace
  Trace? startCheckoutTrace() {
    return _startTrace('checkout_flow');
  }

  /// Stop checkout trace
  Future<void> stopCheckoutTrace({
    bool success = true,
    int? itemCount,
    double? totalAmount,
  }) async {
    final trace = _traces['checkout_flow'];

    if (trace != null) {
      try {
        trace.putAttribute('success', success.toString());
        if (itemCount != null) {
          trace.setMetric('item_count', itemCount);
        }
        if (totalAmount != null) {
          trace.setMetric('total_amount_cents', (totalAmount * 100).toInt());
        }
      } catch (e) {
        if (kDebugMode) {
          print('Performance Error - Set checkout metrics: $e');
        }
      }
    }

    await _stopTrace('checkout_flow');
  }

  /// Start payment processing trace
  Trace? startPaymentTrace(String paymentMethod) {
    final trace = _startTrace('payment_processing');
    trace?.putAttribute('method', paymentMethod);
    return trace;
  }

  /// Stop payment processing trace
  Future<void> stopPaymentTrace({bool success = true}) async {
    final trace = _traces['payment_processing'];
    trace?.putAttribute('success', success.toString());
    await _stopTrace('payment_processing');
  }

  // ============================================================================
  // DATABASE TRACES
  // ============================================================================

  /// Start database read trace
  Trace? startDatabaseReadTrace(String collection) {
    final trace = _startTrace('db_read_$collection');
    trace?.putAttribute('collection', collection);
    return trace;
  }

  /// Stop database read trace
  Future<void> stopDatabaseReadTrace(
    String collection, {
    int? documentCount,
  }) async {
    final traceName = 'db_read_$collection';
    final trace = _traces[traceName];

    if (trace != null && documentCount != null) {
      try {
        trace.setMetric('document_count', documentCount);
      } catch (e) {
        if (kDebugMode) {
          print('Performance Error - Set DB metrics: $e');
        }
      }
    }

    await _stopTrace(traceName);
  }

  /// Start database write trace
  Trace? startDatabaseWriteTrace(String collection) {
    final trace = _startTrace('db_write_$collection');
    trace?.putAttribute('collection', collection);
    return trace;
  }

  /// Stop database write trace
  Future<void> stopDatabaseWriteTrace(
    String collection, {
    bool success = true,
  }) async {
    final traceName = 'db_write_$collection';
    final trace = _traces[traceName];
    trace?.putAttribute('success', success.toString());
    await _stopTrace(traceName);
  }

  // ============================================================================
  // IMAGE LOADING TRACES
  // ============================================================================

  /// Start image load trace
  Trace? startImageLoadTrace(String imageUrl) {
    final imageId = imageUrl.hashCode.toString();
    return _startTrace('image_load_$imageId');
  }

  /// Stop image load trace
  Future<void> stopImageLoadTrace(
    String imageUrl, {
    bool success = true,
    int? imageSize,
  }) async {
    final imageId = imageUrl.hashCode.toString();
    final traceName = 'image_load_$imageId';
    final trace = _traces[traceName];

    if (trace != null) {
      try {
        trace.putAttribute('success', success.toString());
        if (imageSize != null) {
          trace.setMetric('size_bytes', imageSize);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Performance Error - Set image metrics: $e');
        }
      }
    }

    await _stopTrace(traceName);
  }

  // ============================================================================
  // CUSTOM TRACES
  // ============================================================================

  /// Start a custom trace
  Trace? startCustomTrace(String name) {
    return _startTrace(name);
  }

  /// Stop a custom trace
  Future<void> stopCustomTrace(
    String name, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final trace = _traces[name];

    if (trace != null) {
      try {
        attributes?.forEach((key, value) {
          trace.putAttribute(key, value);
        });

        metrics?.forEach((key, value) {
          trace.setMetric(key, value);
        });
      } catch (e) {
        if (kDebugMode) {
          print('Performance Error - Set custom metrics: $e');
        }
      }
    }

    await _stopTrace(name);
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Start a trace
  Trace? _startTrace(String name) {
    try {
      final trace = _performance.newTrace(name);
      trace.start();
      _traces[name] = trace;
      return trace;
    } catch (e) {
      if (kDebugMode) {
        print('Performance Error - Start trace ($name): $e');
      }
      return null;
    }
  }

  /// Stop a trace
  Future<void> _stopTrace(String name) async {
    try {
      final trace = _traces.remove(name);
      if (trace != null) {
        await trace.stop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Performance Error - Stop trace ($name): $e');
      }
    }
  }

  /// Stop all active traces (useful for cleanup)
  Future<void> stopAllTraces() async {
    final traceNames = _traces.keys.toList();
    for (final name in traceNames) {
      await _stopTrace(name);
    }
  }
}
