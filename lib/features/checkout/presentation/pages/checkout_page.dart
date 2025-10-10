import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'payment_page.dart';

import '../widgets/order_summary_widget.dart';

/// CheckoutPage handles the complete checkout process
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Address form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _emirateController = TextEditingController();

  // Delivery options
  String _selectedDeliveryMethod = 'standard';
  DateTime? _selectedDeliveryDate;
  String? _selectedDeliveryTime;

  final List<String> _deliveryTimes = [
    '9:00 AM - 12:00 PM',
    '12:00 PM - 3:00 PM',
    '3:00 PM - 6:00 PM',
    '6:00 PM - 9:00 PM',
  ];

  final List<String> _emirates = [
    'Abu Dhabi',
    'Dubai',
    'Sharjah',
    'Ajman',
    'Umm Al Quwain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nameController.text = user.name;
      // Load saved address if available from user preferences
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(),

              // Checkout Steps
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildShippingStep(cartProvider),
                    _buildDeliveryStep(cartProvider),
                    _buildReviewStep(cartProvider),
                  ],
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigation(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some coffee to start checkout',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMedium),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceWhite,
      child: Row(
        children: [
          _buildProgressStep(0, 'Shipping', _currentStep >= 0),
          Expanded(child: _buildProgressLine(_currentStep >= 1)),
          _buildProgressStep(1, 'Delivery', _currentStep >= 1),
          Expanded(child: _buildProgressLine(_currentStep >= 2)),
          _buildProgressStep(2, 'Review', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? AppTheme.primaryBrown : AppTheme.textLight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildShippingStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person),
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
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: const Icon(Icons.phone),
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
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Street Address *',
                prefixIcon: const Icon(Icons.home),
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
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // City
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City *',
                prefixIcon: const Icon(Icons.location_city),
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
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Emirate Dropdown
            DropdownButtonFormField<String>(
              value: _emirateController.text.isEmpty
                  ? null
                  : _emirateController.text,
              decoration: InputDecoration(
                labelText: 'Emirate *',
                prefixIcon: const Icon(Icons.flag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryBrown),
                ),
              ),
              items: _emirates.map((emirate) {
                return DropdownMenuItem(value: emirate, child: Text(emirate));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _emirateController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your emirate';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Options',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Methods
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Standard Delivery'),
                  subtitle: const Text('3-5 business days - Free'),
                  value: 'standard',
                  groupValue: _selectedDeliveryMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Express Delivery'),
                  subtitle: const Text('1-2 business days - AED 15'),
                  value: 'express',
                  groupValue: _selectedDeliveryMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryMethod = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Same Day Delivery'),
                  subtitle: const Text('Today - AED 25'),
                  value: 'same_day',
                  groupValue: _selectedDeliveryMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryMethod = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Date
          Text(
            'Preferred Delivery Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDeliveryDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.textLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppTheme.primaryBrown,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDeliveryDate == null
                        ? 'Select delivery date'
                        : '${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}',
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Delivery Time
          Text(
            'Preferred Time Slot',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _deliveryTimes.map((time) {
              final isSelected = _selectedDeliveryTime == time;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDeliveryTime = time;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBrown
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBrown
                          : AppTheme.textLight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDark,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Review',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Order Summary
          OrderSummaryWidget(cartProvider: cartProvider),

          const SizedBox(height: 16),

          // Shipping Address Summary
          _buildAddressSummary(),

          const SizedBox(height: 16),

          // Delivery Summary
          _buildDeliverySummary(),
        ],
      ),
    );
  }

  Widget _buildAddressSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_nameController.text),
            Text(_phoneController.text),
            Text(_addressController.text),
            Text('${_cityController.text}, ${_emirateController.text}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySummary() {
    String deliveryTitle = '';
    String deliveryPrice = '';

    switch (_selectedDeliveryMethod) {
      case 'standard':
        deliveryTitle = 'Standard Delivery';
        deliveryPrice = 'Free';
        break;
      case 'express':
        deliveryTitle = 'Express Delivery';
        deliveryPrice = 'AED 15';
        break;
      case 'same_day':
        deliveryTitle = 'Same Day Delivery';
        deliveryPrice = 'AED 25';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(deliveryTitle),
                Text(
                  deliveryPrice,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_selectedDeliveryDate != null)
              Text(
                'Date: ${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}',
              ),
            if (_selectedDeliveryTime != null)
              Text('Time: $_selectedDeliveryTime'),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(CartProvider cartProvider) {
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryBrown),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _handleNext(cartProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 2 ? 'Proceed to Payment' : 'Next',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext(CartProvider cartProvider) {
    if (_currentStep == 0) {
      // Validate shipping form
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (_currentStep == 1) {
      // Validate delivery options
      if (_selectedDeliveryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery date')),
        );
        return;
      }
      if (_selectedDeliveryTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery time')),
        );
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 2) {
      // Proceed to payment
      _proceedToPayment(cartProvider);
    }
  }

  void _proceedToPayment(CartProvider cartProvider) {
    // Calculate final total including delivery charges
    double deliveryFee = 0;
    switch (_selectedDeliveryMethod) {
      case 'express':
        deliveryFee = 15;
        break;
      case 'same_day':
        deliveryFee = 25;
        break;
    }

    final orderData = {
      'items': cartProvider.items,
      'subtotal': cartProvider.totalPrice,
      'deliveryFee': deliveryFee,
      'total': cartProvider.totalPrice + deliveryFee,
      'shippingAddress': {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'emirate': _emirateController.text,
      },
      'delivery': {
        'method': _selectedDeliveryMethod,
        'date': _selectedDeliveryDate,
        'time': _selectedDeliveryTime,
      },
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentPage(orderData: orderData),
      ),
    );
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBrown,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emirateController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
