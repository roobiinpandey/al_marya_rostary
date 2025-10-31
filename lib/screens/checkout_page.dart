import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/reward_service.dart';
import '../core/theme/app_theme.dart';
import '../features/cart/presentation/providers/cart_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _availablePoints = 0;
  int _pointsToRedeem = 0;
  double _originalTotal = 0.0;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRewardPoints();
    _calculateTotal();
  }

  Future<void> _loadRewardPoints() async {
    setState(() => _isLoading = true);
    try {
      final points = await RewardService.getUserRewardPoints();
      setState(() {
        _availablePoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load reward points: $e');
    }
  }

  void _calculateTotal() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    _originalTotal = cartProvider.totalPrice;
  }

  double get _discountAmount =>
      RewardService.calculateDiscountFromPoints(_pointsToRedeem);
  double get _finalTotal => _originalTotal - _discountAmount;
  int get _maxRedeemablePoints =>
      RewardService.getMaxRedeemablePoints(_originalTotal, _availablePoints);
  int get _pointsToEarn => RewardService.calculatePointsEarned(_finalTotal);

  void _onPointsChanged(double value) {
    setState(() {
      _pointsToRedeem = value.round();
    });
  }

  Future<void> _processCheckout() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      // Process the transaction
      final result = await RewardService.processTransaction(
        originalAmount: _originalTotal,
        pointsToRedeem: _pointsToRedeem,
        transactionId: transactionId,
      );

      if (result['success']) {
        // Clear cart
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.clearCart();

        // Show success dialog
        _showSuccessDialog(result);
      } else {
        _showError(result['error'] ?? 'Transaction failed');
      }
    } catch (e) {
      _showError('Checkout failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your order has been placed successfully.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Original Amount',
                    'AED ${result['originalAmount'].toStringAsFixed(2)}',
                  ),
                  if (result['pointsUsed'] > 0) ...[
                    _buildSummaryRow(
                      'Points Used',
                      '${result['pointsUsed']} points',
                    ),
                    _buildSummaryRow(
                      'Discount',
                      '- AED ${result['discountAmount'].toStringAsFixed(2)}',
                      isDiscount: true,
                    ),
                  ],
                  Divider(),
                  _buildSummaryRow(
                    'Final Amount',
                    'AED ${result['finalAmount'].toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  SizedBox(height: 8),
                  _buildSummaryRow(
                    'Points Earned',
                    '+${result['pointsEarned']} points',
                    isEarned: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isBold = false,
    bool isEarned = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: isDiscount
                  ? Colors.green
                  : isEarned
                  ? Colors.blue
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return Column(
                                children: [
                                  ...cartProvider.items
                                      .map(
                                        (item) => Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${item.name} x${item.quantity}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'AED ${item.totalPrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'AED ${_originalTotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Reward Points Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.stars, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                'Reward Points',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Available Points: $_availablePoints',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.primaryBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Cash Value: AED ${RewardService.calculateDiscountFromPoints(_availablePoints).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),

                          if (_availablePoints > 0 &&
                              _maxRedeemablePoints > 0) ...[
                            SizedBox(height: 16),
                            Text(
                              'Redeem Points:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text('0'),
                                Expanded(
                                  child: Slider(
                                    value: _pointsToRedeem.toDouble(),
                                    min: 0,
                                    max: _maxRedeemablePoints.toDouble(),
                                    divisions: _maxRedeemablePoints > 0
                                        ? _maxRedeemablePoints
                                        : 1,
                                    activeColor: AppTheme.primaryBrown,
                                    onChanged: _onPointsChanged,
                                  ),
                                ),
                                Text('$_maxRedeemablePoints'),
                              ],
                            ),
                            Text(
                              'Using $_pointsToRedeem points (AED ${_discountAmount.toStringAsFixed(2)} discount)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else if (_availablePoints == 0) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'You don\'t have any reward points yet. Complete this purchase to earn $_pointsToEarn points!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Payment Summary Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildSummaryRow(
                            'Original Amount',
                            'AED ${_originalTotal.toStringAsFixed(2)}',
                          ),
                          if (_pointsToRedeem > 0)
                            _buildSummaryRow(
                              'Discount (${_pointsToRedeem} points)',
                              '- AED ${_discountAmount.toStringAsFixed(2)}',
                              isDiscount: true,
                            ),
                          Divider(thickness: 1),
                          _buildSummaryRow(
                            'Final Amount',
                            'AED ${_finalTotal.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'You will earn $_pointsToEarn points from this purchase',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Processing...'),
                              ],
                            )
                          : Text(
                              'Complete Purchase - AED ${_finalTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Terms
                  Center(
                    child: Text(
                      '• 1 point = AED 0.05 when redeemed\n• Points earned: 1 point per AED 1 spent',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
