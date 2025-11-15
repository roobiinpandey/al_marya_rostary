import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/delivery_tracking_model.dart';

/// Widget for selecting receiver details
class ReceiverDetailsWidget extends StatefulWidget {
  final ReceiverDetails? initialReceiverDetails;
  final Function(ReceiverDetails) onReceiverDetailsChanged;
  final String currentUserName;

  const ReceiverDetailsWidget({
    super.key,
    this.initialReceiverDetails,
    required this.onReceiverDetailsChanged,
    required this.currentUserName,
  });

  @override
  State<ReceiverDetailsWidget> createState() => _ReceiverDetailsWidgetState();
}

class _ReceiverDetailsWidgetState extends State<ReceiverDetailsWidget> {
  late bool _isCurrentUser;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Phone mask formatter: +971 5XXXXXXXX
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+971 5########',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.initialReceiverDetails?.isCurrentUser ?? true;
    if (!_isCurrentUser) {
      _nameController.text = widget.initialReceiverDetails?.receiverName ?? '';
      _phoneController.text =
          widget.initialReceiverDetails?.receiverPhone ?? '';
    }
  }

  void _notifyChange() {
    if (_isCurrentUser) {
      widget.onReceiverDetailsChanged(ReceiverDetails(isCurrentUser: true));
    } else {
      widget.onReceiverDetailsChanged(
        ReceiverDetails(
          isCurrentUser: false,
          receiverName: _nameController.text.trim(),
          receiverPhone: _phoneController.text.trim(),
        ),
      );
    }
  }

  bool _validatePhone(String phone) {
    final phonePattern = r'^\+971 5\d{8}$';
    return RegExp(phonePattern).hasMatch(phone.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receiver Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),

          const SizedBox(height: 16),

          // Current user option
          InkWell(
            onTap: () {
              setState(() {
                _isCurrentUser = true;
                _notifyChange();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isCurrentUser
                      ? AppTheme.primaryBrown
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _isCurrentUser
                    ? AppTheme.primaryLightBrown.withOpacity(0.05)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    _isCurrentUser
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _isCurrentUser
                        ? AppTheme.primaryBrown
                        : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentUserName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Someone else option
          InkWell(
            onTap: () {
              setState(() {
                _isCurrentUser = false;
                _notifyChange();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: !_isCurrentUser
                      ? AppTheme.primaryBrown
                      : Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: !_isCurrentUser
                    ? AppTheme.primaryLightBrown.withOpacity(0.05)
                    : Colors.transparent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        !_isCurrentUser
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: !_isCurrentUser
                            ? AppTheme.primaryBrown
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Someone else will receive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),

                  // Show input fields if "Someone else" is selected
                  if (!_isCurrentUser) ...[
                    const SizedBox(height: 16),

                    // Receiver Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Receiver Name',
                        hintText: 'Enter receiver\'s name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      onChanged: (_) => _notifyChange(),
                    ),

                    const SizedBox(height: 12),

                    // Receiver Phone
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_phoneMaskFormatter],
                      decoration: InputDecoration(
                        labelText: 'Receiver Phone',
                        hintText: '+971 5XXXXXXXX',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        errorText:
                            _phoneController.text.isNotEmpty &&
                                !_validatePhone(_phoneController.text)
                            ? 'Invalid phone format'
                            : null,
                      ),
                      onChanged: (_) {
                        setState(() {
                          _notifyChange();
                        });
                      },
                    ),

                    // Validation hint
                    if (_phoneController.text.isNotEmpty &&
                        _validatePhone(_phoneController.text))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Valid phone number',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
