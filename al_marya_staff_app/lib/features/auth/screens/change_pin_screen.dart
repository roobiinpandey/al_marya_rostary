import 'package:flutter/material.dart';
import '../../../core/auth/pin_auth_service.dart';

/// Screen for changing staff PIN
/// Used for both first-time PIN change (required) and user-initiated changes
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final PinAuthService _authService = PinAuthService();

  // Olive gold theme color
  static const Color oliveGold = Color(0xFFA89A6A);

  // PIN states
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';

  // UI states
  PinInputStep _currentStep = PinInputStep.current;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirstLogin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if this is a first-time login (required PIN change)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['firstLogin'] == true) {
      setState(() {
        _isFirstLogin = true;
      });
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = null;

      switch (_currentStep) {
        case PinInputStep.current:
          if (_currentPin.length < 4) {
            _currentPin += number;
            if (_currentPin.length == 4) {
              // Auto-advance to new PIN after 500ms
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _currentStep = PinInputStep.newPin;
                  });
                }
              });
            }
          }
          break;

        case PinInputStep.newPin:
          if (_newPin.length < 4) {
            _newPin += number;
            if (_newPin.length == 4) {
              // Validate new PIN
              if (_newPin == _currentPin) {
                _errorMessage = 'New PIN must be different from current PIN';
                _newPin = '';
              } else if (_newPin == '0000' ||
                  _newPin == '1234' ||
                  _newPin == '1111' ||
                  _newPin == '2222') {
                _errorMessage = 'Please choose a more secure PIN';
                _newPin = '';
              } else {
                // Auto-advance to confirm after 500ms
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _currentStep = PinInputStep.confirm;
                    });
                  }
                });
              }
            }
          }
          break;

        case PinInputStep.confirm:
          if (_confirmPin.length < 4) {
            _confirmPin += number;
            if (_confirmPin.length == 4) {
              // Auto-submit after 500ms
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _submitPinChange();
                }
              });
            }
          }
          break;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;

      switch (_currentStep) {
        case PinInputStep.current:
          if (_currentPin.isNotEmpty) {
            _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          }
          break;
        case PinInputStep.newPin:
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
          }
          break;
        case PinInputStep.confirm:
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
          break;
      }
    });
  }

  void _onClear() {
    setState(() {
      _errorMessage = null;

      switch (_currentStep) {
        case PinInputStep.current:
          _currentPin = '';
          break;
        case PinInputStep.newPin:
          _newPin = '';
          break;
        case PinInputStep.confirm:
          _confirmPin = '';
          break;
      }
    });
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;

      switch (_currentStep) {
        case PinInputStep.current:
          // Can't go back from first step
          break;
        case PinInputStep.newPin:
          _currentStep = PinInputStep.current;
          _newPin = '';
          break;
        case PinInputStep.confirm:
          _currentStep = PinInputStep.newPin;
          _confirmPin = '';
          break;
      }
    });
  }

  Future<void> _submitPinChange() async {
    // Validate confirm PIN matches new PIN
    if (_confirmPin != _newPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _currentStep = PinInputStep.newPin;
        _newPin = '';
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.changePin(
        currentPin: _currentPin,
        newPin: _newPin,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PIN changed successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to home
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to change PIN';
          // Reset to current PIN step
          _currentStep = PinInputStep.current;
          _currentPin = '';
          _newPin = '';
          _confirmPin = '';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection error. Please try again.';
        _currentStep = PinInputStep.current;
        _currentPin = '';
        _newPin = '';
        _confirmPin = '';
      });
    }
  }

  String _getCurrentStepTitle() {
    switch (_currentStep) {
      case PinInputStep.current:
        return 'Enter Current PIN';
      case PinInputStep.newPin:
        return 'Enter New PIN';
      case PinInputStep.confirm:
        return 'Confirm New PIN';
    }
  }

  String _getCurrentPin() {
    switch (_currentStep) {
      case PinInputStep.current:
        return _currentPin;
      case PinInputStep.newPin:
        return _newPin;
      case PinInputStep.confirm:
        return _confirmPin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation if this is a required first-time PIN change
      canPop: !_isFirstLogin,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Change PIN'),
          backgroundColor: oliveGold,
          foregroundColor: Colors.white,
          // Hide back button if first login (required change)
          automaticallyImplyLeading: !_isFirstLogin,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 6,
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

                  // Title
                  Text(
                    _getCurrentStepTitle(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle (if first login)
                  if (_isFirstLogin)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'For security reasons, please change your default PIN',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Step Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(1, _currentStep.index >= 0),
                      Container(
                        width: 40,
                        height: 2,
                        color: _currentStep.index >= 1
                            ? oliveGold
                            : Colors.grey[300],
                      ),
                      _buildStepIndicator(2, _currentStep.index >= 1),
                      Container(
                        width: 40,
                        height: 2,
                        color: _currentStep.index >= 2
                            ? oliveGold
                            : Colors.grey[300],
                      ),
                      _buildStepIndicator(3, _currentStep.index >= 2),
                    ],
                  ),

                  const SizedBox(height: 32),

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
                          color: index < _getCurrentPin().length
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

                  // Back Button (for step navigation)
                  if (_currentStep != PinInputStep.current && !_isLoading)
                    TextButton.icon(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back, color: oliveGold),
                      label: const Text(
                        'Go Back',
                        style: TextStyle(color: oliveGold),
                      ),
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? oliveGold : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 16),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 16),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 16),
        _buildKeypadRow(['C', '0', '⌫']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((number) {
        return _buildKeypadButton(number);
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (value == '⌫') {
              _onBackspace();
            } else if (value == 'C') {
              _onClear();
            } else {
              _onNumberPressed(value);
            }
          },
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: value == '⌫' ? 24 : 28,
                  fontWeight: FontWeight.w500,
                  color: value == 'C' ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enum for PIN input steps
enum PinInputStep {
  current, // Enter current PIN
  newPin, // Enter new PIN
  confirm, // Confirm new PIN
}
