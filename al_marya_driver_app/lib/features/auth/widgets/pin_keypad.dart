import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Custom numeric keypad widget for PIN entry
/// Provides large touch targets for mobile-friendly PIN entry
class PinKeypad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;

  const PinKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 1, 2, 3
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 8),
          // Row 2: 4, 5, 6
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 8),
          // Row 3: 7, 8, 9
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 8),
          // Row 4: Clear, 0, Backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Clear button (optional)
              if (onClear != null)
                _buildSpecialButton(
                  icon: Icons.clear,
                  onPressed: onClear!,
                  label: 'Clear',
                )
              else
                const SizedBox(width: 70),

              // 0 button
              _buildDigitButton('0'),

              // Backspace button
              _buildSpecialButton(
                icon: Icons.backspace_outlined,
                onPressed: onBackspace,
                label: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildDigitButton(digit)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onDigitPressed(digit);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryOliveGold,
          elevation: 2,
          shadowColor: AppTheme.primaryOliveGold.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightOliveGold, width: 1.5),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
  }) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightOliveGold.withOpacity(0.3),
          foregroundColor: AppTheme.darkOliveGold,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.lightOliveGold, width: 1.5),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 26),
      ),
    );
  }
}
