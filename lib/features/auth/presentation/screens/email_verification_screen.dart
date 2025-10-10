import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/routes/routes.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              final email = user?.email ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Icon and Title
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: AppConfig.primaryColor,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Verify Your Email',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'We\'ve sent a verification email to:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConfig.textColor.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConfig.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppConfig.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your email and click the verification link to complete your registration.',
                          style: TextStyle(
                            color: AppConfig.primaryColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Check if verified button
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : _checkVerification,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: authProvider.isLoading
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
                            'I\'ve Verified My Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Resend verification email
                  OutlinedButton(
                    onPressed: (_isResending || authProvider.isLoading)
                        ? null
                        : _resendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend Verification Email'),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (authProvider.hasError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppConfig.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConfig.errorColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppConfig.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage ?? 'An error occurred',
                              style: TextStyle(
                                color: AppConfig.errorColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Continue without verification (for testing)
                  TextButton(
                    onPressed: () => _skipVerification(),
                    child: Text(
                      'Continue without verification (Not recommended)',
                      style: TextStyle(
                        color: AppConfig.textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign out and try different email
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Wrong email? ',
                        style: TextStyle(
                          color: AppConfig.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: _signOut,
                        child: const Text('Sign out and try again'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerification() async {
    final authProvider = context.read<AuthProvider>();

    // Clear any previous errors
    authProvider.clearError();

    // Check current user verification status
    if (authProvider.isEmailVerified) {
      // Already verified
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      // Show message that email is not verified yet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Email not verified yet. Please check your inbox and click the verification link.',
            ),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
    });

    final authProvider = context.read<AuthProvider>();

    // Clear any previous errors
    authProvider.clearError();

    try {
      await authProvider.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification email: $e'),
            backgroundColor: AppConfig.errorColor,
          ),
        );
      }
    }

    setState(() {
      _isResending = false;
    });
  }

  void _skipVerification() {
    // Navigate to home without verification (for testing purposes)
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Future<void> _signOut() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
}
