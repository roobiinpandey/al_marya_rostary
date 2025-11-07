import 'package:flutter/material.dart';
import '../pages/payment_screen.dart';

/// Helper class to easily integrate Stripe payments into your app
class PaymentHelper {
  /// Show payment screen for an order
  ///
  /// Usage example:
  /// ```dart
  /// await PaymentHelper.showPaymentScreen(
  ///   context: context,
  ///   orderId: order.id,
  ///   authToken: userToken,
  ///   amount: order.totalAmount,
  ///   currency: 'AED',
  ///   onSuccess: () {
  ///     // Navigate to order confirmation screen
  ///     Navigator.pushReplacementNamed(context, '/order-success');
  ///   },
  ///   onCancel: () {
  ///     // Handle cancellation
  ///     print('Payment was canceled');
  ///   },
  /// );
  /// ```
  static Future<void> showPaymentScreen({
    required BuildContext context,
    required String orderId,
    required String authToken,
    required double amount,
    required String currency,
    required VoidCallback onSuccess,
    VoidCallback? onCancel,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderId: orderId,
          authToken: authToken,
          amount: amount,
          currency: currency,
          onSuccess: onSuccess,
          onCancel: onCancel,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  /// Show payment bottom sheet (alternative UI)
  static Future<bool?> showPaymentBottomSheet({
    required BuildContext context,
    required String orderId,
    required String authToken,
    required double amount,
    required String currency,
  }) async {
    bool? paymentSuccess;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: PaymentScreen(
          orderId: orderId,
          authToken: authToken,
          amount: amount,
          currency: currency,
          onSuccess: () {
            paymentSuccess = true;
            Navigator.of(context).pop();
          },
          onCancel: () {
            paymentSuccess = false;
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    return paymentSuccess;
  }
}
