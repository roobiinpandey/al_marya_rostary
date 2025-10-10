import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import 'order_confirmation_page.dart';

/// PaymentPage handles payment processing for orders
class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const PaymentPage({super.key, required this.orderData});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  // Cash on delivery
  final _cashNoteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Methods
                    _buildPaymentMethods(),

                    const SizedBox(height: 24),

                    // Payment Form
                    if (_selectedPaymentMethod == 'card')
                      _buildCardPaymentForm()
                    else if (_selectedPaymentMethod == 'cash')
                      _buildCashOnDeliveryForm()
                    else
                      _buildDigitalWalletForm(),

                    const SizedBox(height: 24),

                    // Order Summary
                    _buildOrderSummary(),
                  ],
                ),
              ),
            ),
          ),

          // Payment Button
          _buildPaymentButton(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Credit/Debit Card
        _buildPaymentMethodTile(
          'card',
          'Credit/Debit Card',
          Icons.credit_card,
          'Visa, Mastercard, American Express',
        ),

        // Cash on Delivery
        _buildPaymentMethodTile(
          'cash',
          'Cash on Delivery',
          Icons.money,
          'Pay when your order arrives',
        ),

        // Apple Pay (iOS only)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          _buildPaymentMethodTile(
            'apple_pay',
            'Apple Pay',
            Icons.apple,
            'Pay with Touch ID or Face ID',
          ),

        // Google Pay (Android only)
        if (Theme.of(context).platform == TargetPlatform.android)
          _buildPaymentMethodTile(
            'google_pay',
            'Google Pay',
            Icons.android,
            'Pay with your Google account',
          ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
          });
        },
        title: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBrown : AppTheme.textMedium,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryBrown : AppTheme.textDark,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
        ),
        activeColor: AppTheme.primaryBrown,
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),

        // Card Holder Name
        TextFormField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBrown),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Card Number
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Card Number',
            prefixIcon: const Icon(Icons.credit_card),
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBrown),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Please enter valid card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            // Expiry Date
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBrown),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter expiry date';
                  }
                  if (value.length < 5) {
                    return 'Invalid expiry date';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),

            // CVV
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBrown),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter CVV';
                  }
                  if (value.length < 3) {
                    return 'Invalid CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Security Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security,
                color: AppTheme.primaryBrown,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your payment information is encrypted and secure',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryBrown),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashOnDeliveryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentAmber),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: AppTheme.accentAmber),
                  const SizedBox(width: 8),
                  Text(
                    'Cash on Delivery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'You will pay when your order is delivered. Please have the exact amount ready.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Optional note
        TextFormField(
          controller: _cashNoteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Special Instructions (Optional)',
            hintText: 'Any special delivery instructions...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryBrown),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalWalletForm() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryLightBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                _selectedPaymentMethod == 'apple_pay'
                    ? Icons.apple
                    : Icons.android,
                size: 48,
                color: AppTheme.primaryBrown,
              ),
              const SizedBox(height: 16),
              Text(
                _selectedPaymentMethod == 'apple_pay'
                    ? 'Pay with Apple Pay'
                    : 'Pay with Google Pay',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Fast, secure payment with biometric authentication',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMedium),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = widget.orderData['subtotal'] as double;
    final deliveryFee = widget.orderData['deliveryFee'] as double;
    final total = widget.orderData['total'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(
                  '${AppConstants.currencySymbol}${subtotal.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text(
                  deliveryFee == 0
                      ? 'Free'
                      : '${AppConstants.currencySymbol}${deliveryFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: deliveryFee == 0 ? AppTheme.accentAmber : null,
                    fontWeight: deliveryFee == 0 ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),

            if (_selectedPaymentMethod == 'cash') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('COD Fee'),
                  Text(
                    '${AppConstants.currencySymbol}5.00',
                    style: const TextStyle(color: AppTheme.textMedium),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${AppConstants.currencySymbol}${(_selectedPaymentMethod == 'cash' ? total + 5 : total).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBrown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final total = widget.orderData['total'] as double;
    final finalTotal = _selectedPaymentMethod == 'cash' ? total + 5 : total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBrown,
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
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Pay ${AppConstants.currencySymbol}${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == 'card' &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Create order data with payment info
    final orderData = Map<String, dynamic>.from(widget.orderData);
    orderData['paymentMethod'] = _selectedPaymentMethod;
    orderData['orderNumber'] = _generateOrderNumber();
    orderData['status'] = 'confirmed';
    orderData['createdAt'] = DateTime.now().toIso8601String();

    if (_selectedPaymentMethod == 'card') {
      orderData['cardLast4'] = _cardNumberController.text.substring(
        _cardNumberController.text.length - 4,
      );
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderConfirmationPage(orderData: orderData),
        ),
      );
    }
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    return 'QAE${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _cashNoteController.dispose();
    super.dispose();
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.length > 16) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != newText.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (newText.length > 4) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if (i == 1 && newText.length > 2) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
