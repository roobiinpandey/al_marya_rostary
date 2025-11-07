# 🔐 Flutter Stripe Integration - Complete Guide

**Status:** ✅ **READY TO USE**  
**Date:** November 4, 2025

---

## ✅ What's Been Set Up

### 1. Package Installation ✅
```yaml
# pubspec.yaml
dependencies:
  flutter_stripe: ^11.2.0
```

### 2. Stripe Initialization ✅
```dart
// lib/main.dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_51SPk8n4lUIhPdRoc...';
  
  runApp(MyApp());
}
```

### 3. Payment Service ✅
**File:** `lib/core/services/payment_service.dart`

Complete service for:
- Creating payment intents
- Presenting Stripe payment sheet
- Processing payments
- Getting payment details

### 4. Payment Screen ✅
**File:** `lib/features/payment/presentation/pages/payment_screen.dart`

Full-screen payment UI with:
- Loading state
- Success dialog
- Error handling
- Retry functionality

### 5. Payment Helper ✅
**File:** `lib/features/payment/presentation/widgets/payment_helper.dart`

Easy-to-use helper for showing payment screens

---

## 🚀 How to Use

### Method 1: Full Screen Payment (Recommended)

```dart
import 'package:qahwat_al_emarat/features/payment/presentation/widgets/payment_helper.dart';

// In your checkout/order confirmation screen:
void _processPayment() async {
  await PaymentHelper.showPaymentScreen(
    context: context,
    orderId: order.id,
    authToken: userToken, // Get from AuthProvider
    amount: order.totalAmount,
    currency: 'AED',
    onSuccess: () {
      // Payment successful! Navigate to success screen
      Navigator.pushReplacementNamed(context, '/order-success');
    },
    onCancel: () {
      // User canceled payment
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment canceled')),
      );
    },
  );
}
```

### Method 2: Bottom Sheet Payment

```dart
void _processPayment() async {
  final success = await PaymentHelper.showPaymentBottomSheet(
    context: context,
    orderId: order.id,
    authToken: userToken,
    amount: order.totalAmount,
    currency: 'AED',
  );

  if (success == true) {
    // Payment successful
    Navigator.pushReplacementNamed(context, '/order-success');
  } else {
    // Payment failed or canceled
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment not completed')),
    );
  }
}
```

### Method 3: Manual Integration (Advanced)

```dart
import 'package:qahwat_al_emarat/core/services/payment_service.dart';

final paymentService = PaymentService();

// Process payment manually
final result = await paymentService.processPayment(
  orderId: order.id,
  authToken: userToken,
  context: context,
);

if (result.success) {
  print('✅ Payment successful!');
  print('Transaction ID: ${result.paymentIntentId}');
  print('Amount: ${result.amount} ${result.currency}');
} else {
  print('❌ Payment failed: ${result.message}');
}
```

---

## 📝 Complete Example: Checkout Flow

Here's a complete example of integrating payment into your checkout:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/features/payment/presentation/widgets/payment_helper.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.orderId,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isProcessing = false;

  void _handlePayment() async {
    // Get auth token from provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userToken = authProvider.token;

    if (userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await PaymentHelper.showPaymentScreen(
        context: context,
        orderId: widget.orderId,
        authToken: userToken,
        amount: widget.totalAmount,
        currency: 'AED',
        onSuccess: () {
          // Payment successful!
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-success',
            (route) => route.isFirst,
            arguments: {'orderId': widget.orderId},
          );
        },
        onCancel: () {
          // User canceled payment
          setState(() => _isProcessing = false);
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID:'),
                        Text(
                          widget.orderId.substring(0, 8) + '...',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.totalAmount.toStringAsFixed(2)} AED',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA89A6A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Payment button
            ElevatedButton(
              onPressed: _isProcessing ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA89A6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Pay with Card',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Payment info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Secure payment powered by Stripe',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing

### Test Cards

Use these test card numbers in the Stripe payment sheet:

#### ✅ Successful Payment
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/34)
CVC: Any 3 digits (e.g., 123)
ZIP: Any 5 digits (e.g., 12345)
```

#### ❌ Declined Payment
```
Card Number: 4000 0000 0000 0002
Expiry: Any future date
CVC: Any 3 digits
```

#### 🔐 Requires 3D Secure
```
Card Number: 4000 0027 6000 3184
Expiry: Any future date
CVC: Any 3 digits
```

### Test Flow

1. **Create an order** (via your existing order creation flow)
2. **Get the order ID** from the response
3. **Call payment** using `PaymentHelper.showPaymentScreen()`
4. **Enter test card details** in the Stripe payment sheet
5. **Verify success** - order should be marked as paid in backend

---

## 🎯 Payment Flow Diagram

```
User clicks "Pay Now"
         ↓
PaymentHelper.showPaymentScreen() called
         ↓
PaymentScreen shown
         ↓
PaymentService.createPaymentIntent() 
  → POST /api/payment/create-intent
         ↓
Backend creates Stripe PaymentIntent
         ↓
Backend returns clientSecret
         ↓
Stripe.instance.initPaymentSheet() called
         ↓
Stripe payment UI shown
         ↓
User enters card details
         ↓
Stripe processes payment
         ↓
Payment successful!
         ↓
Success dialog shown
         ↓
onSuccess() callback fired
         ↓
Navigate to order confirmation
         ↓
[Backend webhook automatically updates order status]
```

---

## 🔒 Security Best Practices

### ✅ Do's
- ✅ Always use HTTPS in production
- ✅ Keep publishable key in app (it's safe)
- ✅ Get auth token from secure storage
- ✅ Validate order ownership on backend
- ✅ Use Stripe's built-in payment UI
- ✅ Handle all error cases gracefully

### ❌ Don'ts
- ❌ Never store credit card numbers
- ❌ Never put secret key in the app
- ❌ Never bypass backend validation
- ❌ Never trust client-side payment status
- ❌ Never log sensitive payment data

---

## 🐛 Troubleshooting

### Error: "Invalid publishable key"
**Solution:** Check that publishable key in `main.dart` is correct

### Error: "Unable to connect to backend"
**Solution:** Verify `AppConstants.baseUrl` is correct and server is running

### Error: "Order not found"
**Solution:** Make sure order was created successfully before payment

### Payment sheet doesn't show
**Solution:** Check console for errors, verify `clientSecret` was returned

### Payment succeeds but order not updated
**Solution:** Check backend webhook is configured correctly

---

## 📱 Platform-Specific Setup

### iOS

Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

### Android

Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Stripe requires minimum SDK 21
    }
}
```

---

## 🎨 Customization

### Change Payment Sheet Colors

Edit `payment_service.dart`:
```dart
appearance: PaymentSheetAppearance(
  colors: PaymentSheetAppearanceColors(
    primary: const Color(0xFFA89A6A), // Your brand color
    background: Colors.white,
    componentBackground: Colors.grey[100],
  ),
),
```

### Custom Loading UI

Edit `payment_screen.dart` to customize the loading state

### Custom Success Dialog

Modify `_showSuccessDialog()` in `payment_screen.dart`

---

## 📊 Monitoring

### View Payments in Stripe Dashboard
https://dashboard.stripe.com/test/payments

### Check Payment Status
```dart
final paymentService = PaymentService();
final details = await paymentService.getPaymentDetails(
  orderId: orderId,
  authToken: authToken,
);

print('Payment Status: ${details?['order']['paymentStatus']}');
print('Stripe Status: ${details?['stripeDetails']['status']}');
```

---

## 🚀 Going to Production

### Checklist

- [ ] Switch to live Stripe keys in `main.dart`
- [ ] Update `AppConstants.baseUrl` to production URL
- [ ] Set `_useProduction = true` in `app_constants.dart`
- [ ] Create production webhook in Stripe Dashboard
- [ ] Test with real cards (then refund)
- [ ] Verify email notifications work
- [ ] Monitor Stripe Dashboard for issues
- [ ] Set up fraud detection rules
- [ ] Configure payment receipts

### Update Publishable Key for Production

```dart
// lib/main.dart
Stripe.publishableKey = 'pk_live_YOUR_LIVE_KEY_HERE';
```

---

## 📞 Support

### Stripe Documentation
- Main Docs: https://stripe.com/docs
- Flutter SDK: https://stripe.dev/stripe-flutter/
- Test Cards: https://stripe.com/docs/testing

### Your Setup
- **Backend:** https://almaryarostary.onrender.com
- **Stripe Dashboard:** https://dashboard.stripe.com/

---

## ✅ Quick Start Checklist

- [x] ✅ Install `flutter_stripe` package
- [x] ✅ Initialize Stripe in `main.dart`
- [x] ✅ Create `PaymentService`
- [x] ✅ Create `PaymentScreen`
- [x] ✅ Create `PaymentHelper`
- [ ] ⏳ Integrate into your checkout flow
- [ ] ⏳ Test with test cards
- [ ] ⏳ Handle success/failure cases
- [ ] ⏳ Test end-to-end flow
- [ ] ⏳ Deploy to production

---

**🎉 Your Flutter app is now ready to accept payments!**

**Need help integrating this into a specific screen?** Just ask! 💬
