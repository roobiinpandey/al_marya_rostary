import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../models/delivery_tracking_model.dart';

/// Service for real-time delivery tracking
class DeliveryTrackingService {
  Timer? _pollingTimer;
  StreamController<DeliveryTrackingData>? _trackingController;

  /// Start tracking an order with real-time updates
  Stream<DeliveryTrackingData> trackOrder(String orderId) {
    _trackingController = StreamController<DeliveryTrackingData>.broadcast();

    // Initial fetch
    _fetchTrackingData(orderId);

    // Poll every 10 seconds for updates
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchTrackingData(orderId),
    );

    return _trackingController!.stream;
  }

  /// Fetch current tracking data from backend
  Future<void> _fetchTrackingData(String orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId/tracking'),
            headers: {
              'Content-Type': 'application/json',
              // Add auth token if needed
              // 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final trackingData = DeliveryTrackingData.fromJson(data);
        _trackingController?.add(trackingData);
      } else {
        _trackingController?.addError(
          'Failed to fetch tracking data: ${response.statusCode}',
        );
      }
    } catch (e) {
      _trackingController?.addError('Error fetching tracking data: $e');
    }
  }

  /// Stop tracking and cleanup
  void stopTracking() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _trackingController?.close();
    _trackingController = null;
  }

  /// Fetch tracking data once (no polling)
  Future<DeliveryTrackingData> getTrackingData(String orderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId/tracking'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DeliveryTrackingData.fromJson(data);
      } else {
        throw Exception('Failed to load tracking data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading tracking data: $e');
    }
  }

  /// Update receiver details
  Future<bool> updateReceiverDetails(
    String orderId,
    ReceiverDetails receiverDetails,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId/receiver'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(receiverDetails.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update delivery instructions
  Future<bool> updateDeliveryInstructions(
    String orderId,
    String instructions,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse(
              '${AppConstants.baseUrl}/api/orders/$orderId/instructions',
            ),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'instructions': instructions}),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
