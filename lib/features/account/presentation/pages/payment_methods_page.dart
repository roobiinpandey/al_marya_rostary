import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String title;
  final String? cardNumber; // Last 4 digits
  final String? expiryDate;
  final String? holderName;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    this.cardNumber,
    this.expiryDate,
    this.holderName,
    this.isDefault = false,
  });

  String get displayInfo {
    switch (type) {
      case PaymentMethodType.creditCard:
      case PaymentMethodType.debitCard:
        return '**** **** **** ${cardNumber ?? '0000'}';
      case PaymentMethodType.cashOnDelivery:
        return 'Pay when you receive your order';
      case PaymentMethodType.digitalWallet:
        return title;
    }
  }

  IconData get icon {
    switch (type) {
      case PaymentMethodType.creditCard:
        return Icons.credit_card;
      case PaymentMethodType.debitCard:
        return Icons.payment;
      case PaymentMethodType.cashOnDelivery:
        return Icons.money;
      case PaymentMethodType.digitalWallet:
        return Icons.wallet;
    }
  }

  Color get color {
    switch (type) {
      case PaymentMethodType.creditCard:
        return Colors.blue;
      case PaymentMethodType.debitCard:
        return Colors.green;
      case PaymentMethodType.cashOnDelivery:
        return Colors.orange;
      case PaymentMethodType.digitalWallet:
        return Colors.purple;
    }
  }
}

enum PaymentMethodType { creditCard, debitCard, digitalWallet, cashOnDelivery }

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  void _loadPaymentMethods() {
    // TODO: Load from API
    setState(() {
      _paymentMethods = [
        PaymentMethod(
          id: '1',
          type: PaymentMethodType.creditCard,
          title: 'Emirates NBD Credit Card',
          cardNumber: '1234',
          expiryDate: '12/26',
          holderName: 'Ahmed Al Mansouri',
          isDefault: true,
        ),
        PaymentMethod(
          id: '2',
          type: PaymentMethodType.debitCard,
          title: 'ADCB Debit Card',
          cardNumber: '5678',
          expiryDate: '08/25',
          holderName: 'Ahmed Al Mansouri',
          isDefault: false,
        ),
        PaymentMethod(
          id: '3',
          type: PaymentMethodType.cashOnDelivery,
          title: 'Cash on Delivery',
          isDefault: false,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBrown),
            )
          : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPaymentMethod(),
        backgroundColor: AppTheme.primaryBrown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Security Notice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBrown.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryBrown.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security,
                color: AppTheme.primaryBrown,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Payments',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Your payment information is encrypted and secure',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Payment Methods List
        if (_paymentMethods.isEmpty)
          _buildEmptyState()
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                return _buildPaymentMethodCard(_paymentMethods[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 80, color: AppTheme.textLight),
              const SizedBox(height: 24),
              Text(
                'No Payment Methods',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add a payment method to make checkout faster and more secure.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddPaymentMethod(),
                icon: const Icon(Icons.add_card),
                label: const Text('Add Payment Method'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon and Default Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(method.icon, color: method.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                      Text(
                        method.displayInfo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (method.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Card Details (for cards only)
            if (method.type == PaymentMethodType.creditCard ||
                method.type == PaymentMethodType.debitCard) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (method.holderName != null) ...[
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      method.holderName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                  if (method.expiryDate != null) ...[
                    const Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expires ${method.expiryDate}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (!method.isDefault &&
                    method.type != PaymentMethodType.cashOnDelivery)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setAsDefault(method),
                      icon: const Icon(Icons.star_border, size: 18),
                      label: const Text('Set Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBrown,
                        side: const BorderSide(color: AppTheme.primaryBrown),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (!method.isDefault &&
                    method.type != PaymentMethodType.cashOnDelivery)
                  const SizedBox(width: 12),
                if (method.type != PaymentMethodType.cashOnDelivery)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToEditPaymentMethod(method),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBrown,
                        side: const BorderSide(color: AppTheme.primaryBrown),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (method.type != PaymentMethodType.cashOnDelivery)
                  const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: method.type != PaymentMethodType.cashOnDelivery
                        ? () => _deletePaymentMethod(method)
                        : null,
                    icon: Icon(
                      Icons.delete,
                      color: method.type != PaymentMethodType.cashOnDelivery
                          ? Colors.red
                          : Colors.grey,
                    ),
                    tooltip: 'Delete payment method',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddPaymentMethod() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditPaymentMethodPage(),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadPaymentMethods();
          }
        });
  }

  void _navigateToEditPaymentMethod(PaymentMethod method) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AddEditPaymentMethodPage(paymentMethod: method),
          ),
        )
        .then((result) {
          if (result == true) {
            _loadPaymentMethods();
          }
        });
  }

  void _setAsDefault(PaymentMethod method) {
    setState(() {
      for (int i = 0; i < _paymentMethods.length; i++) {
        _paymentMethods[i] = PaymentMethod(
          id: _paymentMethods[i].id,
          type: _paymentMethods[i].type,
          title: _paymentMethods[i].title,
          cardNumber: _paymentMethods[i].cardNumber,
          expiryDate: _paymentMethods[i].expiryDate,
          holderName: _paymentMethods[i].holderName,
          isDefault: _paymentMethods[i].id == method.id,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method.title} is now your default payment method'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deletePaymentMethod(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete "${method.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _paymentMethods.removeWhere((pm) => pm.id == method.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${method.title} deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Add/Edit Payment Method Page
class AddEditPaymentMethodPage extends StatefulWidget {
  final PaymentMethod? paymentMethod;

  const AddEditPaymentMethodPage({super.key, this.paymentMethod});

  @override
  State<AddEditPaymentMethodPage> createState() =>
      _AddEditPaymentMethodPageState();
}

class _AddEditPaymentMethodPageState extends State<AddEditPaymentMethodPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _titleController = TextEditingController();

  PaymentMethodType _selectedType = PaymentMethodType.creditCard;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod != null) {
      _loadPaymentMethodData();
    }
  }

  void _loadPaymentMethodData() {
    final method = widget.paymentMethod!;
    _selectedType = method.type;
    _titleController.text = method.title;
    _cardNumberController.text = method.cardNumber ?? '';
    _holderNameController.text = method.holderName ?? '';
    _expiryController.text = method.expiryDate ?? '';
    _isDefault = method.isDefault;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.paymentMethod != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Payment Method' : 'Add Payment Method',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Method Type Selection
                _buildSectionHeader('Payment Method Type'),
                const SizedBox(height: 16),
                _buildTypeSelector(),

                const SizedBox(height: 24),

                // Method Title
                _buildTextField(
                  controller: _titleController,
                  label: 'Payment Method Name',
                  icon: Icons.label,
                  hint: 'e.g. My Emirates NBD Card',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for this payment method';
                    }
                    return null;
                  },
                ),

                // Card Details (only for card types)
                if (_selectedType == PaymentMethodType.creditCard ||
                    _selectedType == PaymentMethodType.debitCard) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Card Details'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _cardNumberController,
                    label: 'Card Number',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    validator: (value) {
                      if (value == null ||
                          value.replaceAll(' ', '').length < 13) {
                        return 'Please enter a valid card number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _holderNameController,
                    label: 'Cardholder Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the cardholder name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: _expiryController,
                          label: 'Expiry Date',
                          icon: Icons.calendar_month,
                          hint: 'MM/YY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryDateFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.length != 5) {
                              return 'Enter MM/YY';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _cvvController,
                          label: 'CVV',
                          icon: Icons.security,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return 'Invalid CVV';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Set as Default
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Set as Default Payment Method',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Use this payment method for future orders',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value;
                      });
                    },
                    activeColor: AppTheme.primaryBrown,
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePaymentMethod,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEditing
                                ? 'Update Payment Method'
                                : 'Save Payment Method',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: PaymentMethodType.values
          .map((type) {
            if (type == PaymentMethodType.cashOnDelivery) return Container();

            final isSelected = _selectedType == type;
            final title = type == PaymentMethodType.creditCard
                ? 'Credit Card'
                : 'Debit Card';
            final icon = type == PaymentMethodType.creditCard
                ? Icons.credit_card
                : Icons.payment;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isSelected ? 3 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryBrown
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primaryBrown
                      : AppTheme.textMedium,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryBrown
                        : AppTheme.textDark,
                  ),
                ),
                trailing: Radio<PaymentMethodType>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  activeColor: AppTheme.primaryBrown,
                ),
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
              ),
            );
          })
          .where((widget) => widget is! Container)
          .toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryBrown),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.textLight.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBrown, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundCream,
      ),
    );
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save payment method
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.paymentMethod != null
                  ? 'Payment method updated successfully!'
                  : 'Payment method saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save payment method: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Input Formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
