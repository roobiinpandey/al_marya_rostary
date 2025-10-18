import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WriteReviewPage extends StatefulWidget {
  final String? productId;
  final String? productName;

  const WriteReviewPage({super.key, this.productId, this.productName});

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Go back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: authProvider.isGuest
          ? _buildGuestMessage()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Product name
                  if (widget.productName != null) ...[
                    Text(
                      widget.productName!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Rating
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                final starIndex = index + 1;
                                return IconButton(
                                  iconSize: 40,
                                  icon: Icon(
                                    starIndex <= _rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _rating = starIndex.toDouble();
                                    });
                                  },
                                );
                              }),
                            ),
                          ),
                          if (_rating > 0)
                            Center(
                              child: Text(
                                _getRatingText(_rating),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Review text
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _reviewController,
                            maxLines: 6,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText:
                                  'Share your thoughts about this coffee...',
                              border: OutlineInputBorder(),
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please write a review';
                              }
                              if (value.trim().length < 10) {
                                return 'Review must be at least 10 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
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
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Guidelines
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Review Guidelines',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildGuideline(
                            'Focus on the product and your experience',
                          ),
                          _buildGuideline('Be respectful and constructive'),
                          _buildGuideline('Minimum 10 characters required'),
                          _buildGuideline(
                            'Reviews are moderated before publishing',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGuestMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Sign in to write a review',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You need to be logged in to share your product reviews',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Replace entire stack with login page for clean navigation
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Replace entire stack with register page for clean navigation
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil('/register', (route) => false);
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
