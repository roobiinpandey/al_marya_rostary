import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';

/// A wrapper widget that ensures the user has verified their email
/// before accessing protected content
class EmailVerificationGuard extends StatelessWidget {
  final Widget child;
  final bool requireVerification;

  const EmailVerificationGuard({
    super.key,
    required this.child,
    this.requireVerification = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If not authenticated, show child (auth pages should handle this)
        if (!authProvider.isAuthenticated) {
          return child;
        }

        // If guest user, allow access
        if (authProvider.isGuest) {
          return child;
        }

        // If verification not required, show child
        if (!requireVerification) {
          return child;
        }

        // If email is verified, show child
        if (authProvider.isEmailVerified) {
          return child;
        }

        // If email needs verification, show verification screen
        return const EmailVerificationScreen();
      },
    );
  }
}
