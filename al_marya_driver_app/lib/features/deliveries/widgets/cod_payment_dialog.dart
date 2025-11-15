import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// COD Payment Confirmation Dialog
/// Shows when driver needs to confirm cash payment
class CodPaymentDialog extends StatefulWidget {
  final String orderNumber;
  final double amount;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CodPaymentDialog({
    super.key,
    required this.orderNumber,
    required this.amount,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<CodPaymentDialog> createState() => _CodPaymentDialogState();
}

class _CodPaymentDialogState extends State<CodPaymentDialog> {
  bool _isConfirming = false;

  void _handleConfirm() async {
    setState(() {
      _isConfirming = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    widget.onConfirm();

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_money,
                size: 32,
                color: Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 16),

            // Title
            const Text(
              'Confirm Cash Payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Order number
            Text(
              'Order #${widget.orderNumber}',
              style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
            ),

            const SizedBox(height: 24),

            // Amount display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.primaryOliveGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryOliveGold.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount Received',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AED ${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOliveGold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Information text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please confirm you received the exact cash amount from the customer.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isConfirming ? null : _handleCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.textMedium),
                      foregroundColor: AppTheme.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm Payment',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

/// Helper function to show COD payment dialog
Future<bool?> showCodPaymentDialog({
  required BuildContext context,
  required String orderNumber,
  required double amount,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CodPaymentDialog(
      orderNumber: orderNumber,
      amount: amount,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}
