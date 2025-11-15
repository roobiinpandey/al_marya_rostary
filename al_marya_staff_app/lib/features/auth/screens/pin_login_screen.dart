import 'package:flutter/material.dart';
import '../../../core/auth/pin_auth_service.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final PinAuthService _authService = PinAuthService();
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Olive gold color
  static const Color oliveGold = Color(0xFFA89A6A);

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      // Allow only 4 digits
      setState(() {
        _pin += number;
        _errorMessage = null;
      });

      // Auto-submit when 4 digits entered
      if (_pin.length == 4) {
        _login();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _login() async {
    if (_pin.length != 4) {
      setState(() {
        _errorMessage = 'Please enter 4-digit PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.loginWithPin(pin: _pin);

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Navigate to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // Show error
        setState(() {
          _pin = '';
          if (result['locked'] == true) {
            _errorMessage = result['error'];
          } else if (result['attemptsRemaining'] != null) {
            _errorMessage =
                '${result['error']}\n${result['attemptsRemaining']} attempts remaining';
          } else {
            _errorMessage = result['error'] ?? 'Login failed';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo/Header
                Container(
                  width: 160,
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/common/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'AL MARYA ROSTERY',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: oliveGold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Staff Login',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                // PIN Display
                const Text(
                  'Enter Your 4-Digit PIN',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 16),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pin.length
                            ? oliveGold
                            : Colors.grey[300],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_errorMessage != null) const SizedBox(height: 24),

                // Loading Indicator
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(oliveGold),
                  ),

                if (_isLoading) const SizedBox(height: 24),

                // Numeric Keypad
                if (!_isLoading) _buildNumericKeypad(),

                const SizedBox(height: 24),

                // QR Scan Option
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/qr-scan');
                  },
                  icon: const Icon(Icons.qr_code_scanner, color: oliveGold),
                  label: const Text(
                    'Scan QR Badge',
                    style: TextStyle(color: oliveGold),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton('Clear', onPressed: _onClear, isSpecial: true),
            const SizedBox(width: 12),
            _buildKeypadButton('0'),
            const SizedBox(width: 12),
            _buildKeypadButton('⌫', onPressed: _onBackspace, isSpecial: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildKeypadButton(number),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(
    String label, {
    VoidCallback? onPressed,
    bool isSpecial = false,
  }) {
    return InkWell(
      onTap: onPressed ?? () => _onNumberPressed(label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: isSpecial ? 80 : 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSpecial ? Colors.grey[200] : oliveGold.withOpacity(0.1),
          shape: isSpecial ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isSpecial ? BorderRadius.circular(12) : null,
          border: Border.all(
            color: isSpecial ? Colors.grey[400]! : oliveGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSpecial ? 18 : 28,
              fontWeight: FontWeight.w500,
              color: isSpecial ? Colors.grey[700] : oliveGold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
