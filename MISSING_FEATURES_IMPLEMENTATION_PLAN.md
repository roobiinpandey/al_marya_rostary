# 🎯 Missing Features - Complete Implementation Plan

**Date:** November 7, 2025  
**Status:** Ready to Implement  
**Duration:** 6-8 weeks (120-160 hours)  
**Priority:** Complete Core Features Before Deployment

---

## 📊 Executive Summary

This document provides a detailed, step-by-step implementation plan for all missing features across Customer, Staff, Driver apps and Admin Panel. Each feature includes:
- ✅ Backend API endpoints with code
- ✅ Flutter implementation with code
- ✅ Database schema changes
- ✅ Dependencies required
- ✅ Testing checklist

---

## 📋 Table of Contents

1. [Customer App Features](#customer-app-features) (22 tasks)
2. [Staff App Features](#staff-app-features) (18 tasks)
3. [Driver App Features](#driver-app-features) (20 tasks)
4. [Admin Panel Features](#admin-panel-features) (15 tasks)
5. [Timeline & Roadmap](#timeline--roadmap)
6. [Dependencies](#dependencies)

---

# Customer App Features

## Feature 1: Order Cancellation ⭐ HIGH PRIORITY

### Overview
Allow customers to cancel orders within 15 minutes of placing them. Includes refund processing if paid.

### Backend Implementation

#### 1.1 Database Schema Updates
```javascript
// backend/models/Order.js
// Add to Order schema:

cancellation: {
  isCancelled: {
    type: Boolean,
    default: false
  },
  reason: String,
  cancelledAt: Date,
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  refundStatus: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed'],
    default: null
  },
  refundAmount: Number,
  refundTransactionId: String,
  refundedAt: Date
}
```

#### 1.2 API Endpoint
```javascript
// backend/routes/orderRoutes.js

/**
 * @route   POST /api/orders/:id/cancel
 * @desc    Cancel an order (within 15 min of placement)
 * @access  Private
 */
router.post('/orders/:id/cancel', protect, async (req, res) => {
  try {
    const { reason } = req.body;
    
    const order = await Order.findById(req.params.id);
    
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Check ownership
    if (order.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to cancel this order' });
    }
    
    // Check if already cancelled
    if (order.cancellation?.isCancelled) {
      return res.status(400).json({ message: 'Order is already cancelled' });
    }
    
    // Check status - can only cancel pending/preparing orders
    if (!['pending', 'preparing'].includes(order.status)) {
      return res.status(400).json({ 
        message: `Cannot cancel order with status: ${order.status}` 
      });
    }
    
    // Check time limit (15 minutes)
    const minutesSinceOrder = (Date.now() - order.createdAt) / 1000 / 60;
    if (minutesSinceOrder > 15) {
      return res.status(400).json({ 
        message: 'Cancellation window expired. Orders can only be cancelled within 15 minutes.' 
      });
    }
    
    // Update order
    order.status = 'cancelled';
    order.cancellation = {
      isCancelled: true,
      reason: reason || 'Customer requested cancellation',
      cancelledAt: new Date(),
      cancelledBy: req.user._id
    };
    
    // Process refund if payment was made
    if (order.paymentStatus === 'paid' && order.paymentMethod === 'card') {
      try {
        const refund = await processStripeRefund(order);
        order.cancellation.refundStatus = 'completed';
        order.cancellation.refundAmount = order.totalAmount;
        order.cancellation.refundTransactionId = refund.id;
        order.cancellation.refundedAt = new Date();
      } catch (refundError) {
        order.cancellation.refundStatus = 'failed';
        console.error('Refund failed:', refundError);
      }
    }
    
    await order.save();
    
    // Notify staff/driver if assigned
    await sendCancellationNotifications(order);
    
    res.json({
      success: true,
      message: 'Order cancelled successfully',
      order,
      refund: order.cancellation.refundStatus === 'completed' ? {
        amount: order.cancellation.refundAmount,
        status: 'completed',
        transactionId: order.cancellation.refundTransactionId
      } : null
    });
    
  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({ message: 'Server error while cancelling order' });
  }
});

/**
 * Helper: Process Stripe refund
 */
async function processStripeRefund(order) {
  const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
  
  // Get the payment intent from order
  const paymentIntentId = order.stripePaymentIntentId;
  
  if (!paymentIntentId) {
    throw new Error('No payment intent found for refund');
  }
  
  // Create refund
  const refund = await stripe.refunds.create({
    payment_intent: paymentIntentId,
    reason: 'requested_by_customer'
  });
  
  return refund;
}

/**
 * Helper: Send cancellation notifications
 */
async function sendCancellationNotifications(order) {
  // Notify staff if order was being prepared
  if (order.assignedStaff) {
    // Send FCM to staff app
    await sendPushNotification(order.assignedStaff, {
      title: 'Order Cancelled',
      body: `Order ${order.orderNumber} has been cancelled by customer`,
      data: { orderId: order._id, type: 'order_cancelled' }
    });
  }
  
  // Notify driver if order was assigned for delivery
  if (order.assignedDriver) {
    // Send FCM to driver app
    await sendPushNotification(order.assignedDriver, {
      title: 'Delivery Cancelled',
      body: `Delivery for order ${order.orderNumber} has been cancelled`,
      data: { orderId: order._id, type: 'delivery_cancelled' }
    });
  }
}
```

### Flutter Implementation

#### 1.3 Add Cancellation Service
```dart
// lib/core/services/order_cancellation_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class OrderCancellationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/orders/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }
  
  bool canCancelOrder(DateTime orderCreatedAt, String orderStatus) {
    // Check status
    if (!['pending', 'preparing'].contains(orderStatus)) {
      return false;
    }
    
    // Check time (15 minutes)
    final minutesSinceOrder = DateTime.now().difference(orderCreatedAt).inMinutes;
    return minutesSinceOrder <= 15;
  }
  
  int getRemainingMinutes(DateTime orderCreatedAt) {
    final minutesSinceOrder = DateTime.now().difference(orderCreatedAt).inMinutes;
    return (15 - minutesSinceOrder).clamp(0, 15);
  }
}
```

#### 1.4 Update Order Details UI
```dart
// lib/pages/orders_page.dart
// Add cancel button to order details sheet

Widget _buildCancelButton(Order order) {
  final cancellationService = OrderCancellationService();
  
  if (!cancellationService.canCancelOrder(order.createdAt, order.status)) {
    return const SizedBox.shrink();
  }
  
  final remainingMinutes = cancellationService.getRemainingMinutes(order.createdAt);
  
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'You can cancel within $remainingMinutes minutes',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _showCancelDialog(order),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    ),
  );
}

Future<void> _showCancelDialog(Order order) async {
  final reasons = [
    'Changed my mind',
    'Ordered by mistake',
    'Delivery time too long',
    'Found a better option',
    'Other',
  ];
  
  String? selectedReason;
  String? customReason;
  
  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Cancel Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please tell us why you\'re cancelling:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: selectedReason,
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                    if (value != 'Other') {
                      customReason = null;
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => customReason = value,
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 16),
              if (order.paymentStatus == 'paid')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment of ${order.totalAmount.toStringAsFixed(2)} AED will be refunded within 5-7 business days.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    final reason = selectedReason == 'Other' 
                        ? (customReason ?? 'Other')
                        : selectedReason!;
                    Navigator.pop(context, reason);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    ),
  );
  
  if (result != null && mounted) {
    await _processCancellation(order, result);
  }
}

Future<void> _processCancellation(Order order, String reason) async {
  // Show loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );
  
  try {
    final cancellationService = OrderCancellationService();
    final result = await cancellationService.cancelOrder(order.id, reason);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close order details
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Order cancelled successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh orders list
      _loadOrders();
    }
  } catch (e) {
    if (mounted) {
      Navigator.pop(context); // Close loading
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
```

### Testing Checklist
- [ ] Order can be cancelled within 15 minutes
- [ ] Cannot cancel after 15 minutes
- [ ] Cannot cancel orders with status "ready", "out-for-delivery", "delivered"
- [ ] Refund processed for paid orders
- [ ] Staff receives cancellation notification
- [ ] Driver receives cancellation notification (if assigned)
- [ ] Order status changes to "cancelled"
- [ ] Cancellation shows in order history with reason

---

## Feature 2: Real-time Order Tracking ⭐ HIGH PRIORITY

### Overview
Customer can see live order status updates and driver location on a map.

### Backend Implementation

#### 2.1 Add Firebase Real-time Updates
```javascript
// backend/utils/realtimeNotifications.js

const admin = require('firebase-admin');

/**
 * Send real-time order update via Firebase
 */
async function sendRealtimeOrderUpdate(userId, orderId, updateData) {
  try {
    const firestore = admin.firestore();
    
    // Update order status in Firestore for real-time sync
    await firestore.collection('orderUpdates').doc(orderId).set({
      userId: userId.toString(),
      orderId: orderId.toString(),
      status: updateData.status,
      statusTimestamps: updateData.statusTimestamps || {},
      assignedDriver: updateData.assignedDriver || null,
      driverLocation: updateData.driverLocation || null,
      estimatedDeliveryTime: updateData.estimatedDeliveryTime || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
    console.log(`Real-time update sent for order ${orderId}`);
  } catch (error) {
    console.error('Error sending real-time update:', error);
  }
}

module.exports = { sendRealtimeOrderUpdate };
```

#### 2.2 Update Order Status Endpoints
```javascript
// backend/routes/staffOrders.js
// Modify status update endpoints to include real-time notifications

const { sendRealtimeOrderUpdate } = require('../utils/realtimeNotifications');

// After any status change:
await sendRealtimeOrderUpdate(order.user, order._id, {
  status: order.status,
  statusTimestamps: order.statusTimestamps,
  assignedDriver: order.assignedDriver
});
```

### Flutter Implementation

#### 2.3 Add Firebase Stream Listener
```dart
// lib/core/services/order_tracking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OrderTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _orderSubscription;
  
  /// Listen to real-time order updates
  Stream<Map<String, dynamic>?> trackOrder(String orderId) {
    return _firestore
        .collection('orderUpdates')
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }
  
  /// Start tracking with callback
  void startTracking(String orderId, Function(Map<String, dynamic>) onUpdate) {
    _orderSubscription = trackOrder(orderId).listen((data) {
      if (data != null) {
        onUpdate(data);
      }
    });
  }
  
  /// Stop tracking
  void stopTracking() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }
}
```

#### 2.4 Update Order Tracking Page
```dart
// lib/features/checkout/presentation/pages/order_tracking_page_v2.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/order_tracking_service.dart';
import '../../../../core/theme/app_theme.dart';

class OrderTrackingPageV2 extends StatefulWidget {
  final String orderNumber;
  final String orderId;

  const OrderTrackingPageV2({
    super.key,
    required this.orderNumber,
    required this.orderId,
  });

  @override
  State<OrderTrackingPageV2> createState() => _OrderTrackingPageV2State();
}

class _OrderTrackingPageV2State extends State<OrderTrackingPageV2> {
  final OrderTrackingService _trackingService = OrderTrackingService();
  GoogleMapController? _mapController;
  
  Map<String, dynamic>? _orderData;
  LatLng? _driverLocation;
  LatLng? _deliveryLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  @override
  void initState() {
    super.initState();
    _startTracking();
  }
  
  @override
  void dispose() {
    _trackingService.stopTracking();
    _mapController?.dispose();
    super.dispose();
  }
  
  void _startTracking() {
    _trackingService.startTracking(widget.orderId, (data) {
      setState(() {
        _orderData = data;
        
        // Update driver location if available
        if (data['driverLocation'] != null) {
          _driverLocation = LatLng(
            data['driverLocation']['latitude'],
            data['driverLocation']['longitude'],
          );
          _updateMapMarkers();
        }
      });
    });
  }
  
  void _updateMapMarkers() {
    _markers.clear();
    
    // Add driver marker
    if (_driverLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Driver Location'),
      ));
    }
    
    // Add delivery location marker
    if (_deliveryLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery Location'),
      ));
    }
    
    // Draw polyline if both locations exist
    if (_driverLocation != null && _deliveryLocation != null) {
      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: [_driverLocation!, _deliveryLocation!],
        color: AppTheme.primaryBrown,
        width: 3,
      ));
    }
    
    // Animate camera to show both markers
    if (_driverLocation != null && _deliveryLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _driverLocation!.latitude < _deliveryLocation!.latitude
                  ? _driverLocation!.latitude
                  : _deliveryLocation!.latitude,
              _driverLocation!.longitude < _deliveryLocation!.longitude
                  ? _driverLocation!.longitude
                  : _deliveryLocation!.longitude,
            ),
            northeast: LatLng(
              _driverLocation!.latitude > _deliveryLocation!.latitude
                  ? _driverLocation!.latitude
                  : _deliveryLocation!.latitude,
              _driverLocation!.longitude > _deliveryLocation!.longitude
                  ? _driverLocation!.longitude
                  : _deliveryLocation!.longitude,
            ),
          ),
          100, // padding
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${widget.orderNumber}'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: _orderData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map View
                if (_orderData!['status'] == 'out-for-delivery' && 
                    _driverLocation != null)
                  Expanded(
                    flex: 2,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _driverLocation!,
                        zoom: 14,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _updateMapMarkers();
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                  ),
                
                // Order Status Timeline
                Expanded(
                  flex: 1,
                  child: _buildStatusTimeline(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatusTimeline() {
    final statuses = ['pending', 'preparing', 'ready', 'out-for-delivery', 'delivered'];
    final currentStatus = _orderData!['status'];
    final currentIndex = statuses.indexOf(currentStatus);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.primaryBrown : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 50,
                    color: isCompleted ? AppTheme.primaryBrown : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusTitle(status),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppTheme.textDark : Colors.grey,
                    ),
                  ),
                  if (isCompleted)
                    Text(
                      _getStatusTime(status),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'preparing':
        return 'Being Prepared';
      case 'ready':
        return 'Ready for Pickup';
      case 'out-for-delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }
  
  String _getStatusTime(String status) {
    final timestamps = _orderData!['statusTimestamps'] as Map<String, dynamic>?;
    if (timestamps == null) return '';
    
    final timestamp = timestamps[status];
    if (timestamp == null) return '';
    
    final time = DateTime.parse(timestamp.toString());
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
```

### Dependencies Required
```yaml
# Add to al_marya_rostery/pubspec.yaml
dependencies:
  google_maps_flutter: ^2.9.0  # Already exists
  cloud_firestore: ^5.5.2      # Already exists
```

### Testing Checklist
- [ ] Customer receives real-time status updates
- [ ] Map shows driver location when out-for-delivery
- [ ] Timeline updates automatically
- [ ] Route polyline draws between driver and customer
- [ ] Camera animates to show both markers
- [ ] Works when app is in background

---

## Feature 3: Push Notifications ⭐ HIGH PRIORITY

### Overview
Send push notifications for order status changes across all apps.

### Backend Implementation

#### 3.1 Install Firebase Admin SDK
```bash
cd backend
npm install firebase-admin
```

#### 3.2 Initialize Firebase Admin
```javascript
// backend/config/firebase-admin.js

const admin = require('firebase-admin');

// Initialize with service account
const serviceAccount = require('../firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

module.exports = admin;
```

#### 3.3 Add FCM Token Management
```javascript
// backend/models/User.js
// Add to User schema:

fcmToken: {
  type: String,
  default: null
},
fcmTokens: [{
  token: String,
  device: String,
  addedAt: { type: Date, default: Date.now }
}]
```

```javascript
// backend/routes/authRoutes.js

/**
 * @route   POST /api/auth/fcm-token
 * @desc    Save FCM token for push notifications
 * @access  Private
 */
router.post('/fcm-token', protect, async (req, res) => {
  try {
    const { token, device } = req.body;
    
    const user = await User.findById(req.user._id);
    
    // Remove old token if exists
    user.fcmTokens = user.fcmTokens.filter(t => t.token !== token);
    
    // Add new token
    user.fcmTokens.push({
      token,
      device: device || 'unknown',
      addedAt: new Date()
    });
    
    // Keep only last 3 tokens per user
    if (user.fcmTokens.length > 3) {
      user.fcmTokens = user.fcmTokens.slice(-3);
    }
    
    await user.save();
    
    res.json({ success: true, message: 'FCM token saved' });
  } catch (error) {
    console.error('Save FCM token error:', error);
    res.status(500).json({ message: 'Failed to save FCM token' });
  }
});
```

#### 3.4 Add Notification Service
```javascript
// backend/services/notificationService.js

const admin = require('../config/firebase-admin');
const User = require('../models/User');
const Staff = require('../models/Staff');
const Driver = require('../models/Driver');

/**
 * Send push notification to customer
 */
async function sendNotificationToCustomer(userId, notification) {
  try {
    const user = await User.findById(userId);
    
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
      console.log('No FCM tokens found for user:', userId);
      return;
    }
    
    const tokens = user.fcmTokens.map(t => t.token);
    
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: notification.data || {},
      tokens: tokens,
    };
    
    const response = await admin.messaging().sendMulticast(message);
    console.log(`Sent ${response.successCount} notifications to customer ${userId}`);
    
    // Remove invalid tokens
    if (response.failureCount > 0) {
      const tokensToRemove = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          tokensToRemove.push(tokens[idx]);
        }
      });
      
      user.fcmTokens = user.fcmTokens.filter(t => !tokensToRemove.includes(t.token));
      await user.save();
    }
  } catch (error) {
    console.error('Error sending notification to customer:', error);
  }
}

/**
 * Send notification for order status change
 */
async function sendOrderStatusNotification(order, newStatus) {
  const messages = {
    'preparing': {
      title: 'Order Preparing! 👨‍🍳',
      body: `Your order #${order.orderNumber} is being prepared`,
    },
    'ready': {
      title: 'Order Ready! ✅',
      body: `Your order #${order.orderNumber} is ready for delivery`,
    },
    'out-for-delivery': {
      title: 'On the Way! 🚗',
      body: `Your order #${order.orderNumber} is on the way`,
    },
    'delivered': {
      title: 'Delivered! 🎉',
      body: `Your order #${order.orderNumber} has been delivered. Enjoy your coffee!`,
    },
    'cancelled': {
      title: 'Order Cancelled',
      body: `Your order #${order.orderNumber} has been cancelled`,
    },
  };
  
  const notification = messages[newStatus];
  
  if (!notification) return;
  
  await sendNotificationToCustomer(order.user, {
    ...notification,
    data: {
      orderId: order._id.toString(),
      orderNumber: order.orderNumber,
      status: newStatus,
      type: 'order_status'
    }
  });
}

module.exports = {
  sendNotificationToCustomer,
  sendOrderStatusNotification,
};
```

#### 3.5 Update Status Change Endpoints
```javascript
// backend/routes/staffOrders.js
// Add after status changes:

const { sendOrderStatusNotification } = require('../services/notificationService');

// After order.save():
await sendOrderStatusNotification(order, order.status);
```

### Flutter Implementation

#### 3.6 Add Firebase Messaging
```yaml
# al_marya_rostery/pubspec.yaml
dependencies:
  firebase_messaging: ^15.1.5
```

#### 3.7 Configure FCM Service
```dart
// lib/core/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

// Top-level function for background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted permission');
      return;
    }
    
    // Configure local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }
    
    // Listen to token refresh
    _messaging.onTokenRefresh.listen(_sendTokenToServer);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    _initialized = true;
  }
  
  Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await _storage.read(key: 'auth_token');
      if (authToken == null) return;
      
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'token': token,
          'device': 'flutter',
        }),
      );
      
      print('FCM token sent to server');
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }
  
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
    
    // Show local notification
    const androidDetails = AndroidNotificationDetails(
      'orders_channel',
      'Orders',
      channelDescription: 'Order status updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: json.encode(message.data),
    );
  }
  
  void _handleMessageTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    _navigateToScreen(message.data);
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _navigateToScreen(data);
    }
  }
  
  void _navigateToScreen(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'order_status':
        // Navigate to order details
        final orderId = data['orderId'];
        // Use your navigation service to go to order details
        break;
      case 'order_cancelled':
        // Navigate to orders page
        break;
      default:
        break;
    }
  }
}
```

#### 3.8 Initialize in Main
```dart
// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM
  await FCMService().initialize();
  
  runApp(MyApp());
}
```

### Testing Checklist
- [ ] User receives notification when order status changes
- [ ] Tapping notification opens order details
- [ ] Notifications work when app is in background
- [ ] Notifications work when app is closed
- [ ] FCM token sent to backend on login
- [ ] Token refreshes automatically

---

**[Document continues with remaining features...]**

Due to character limit, I'll create this as a comprehensive document. Would you like me to:

1. Continue with the remaining Customer App features (Enhanced Order Details, Rate Order/Driver)?
2. Move to Staff App features?
3. Or create this as a structured file and continue?

Let me know and I'll complete the full implementation plan!
