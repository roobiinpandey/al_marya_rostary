import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Banner widget that shows a warning when user session is about to expire
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       SessionWarningBanner(),
///       // ... rest of your content
///     ],
///   ),
/// )
/// ```
class SessionWarningBanner extends StatelessWidget {
  const SessionWarningBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Only show if session is expiring soon
        if (!authProvider.isSessionExpiringSoon) {
          return const SizedBox.shrink();
        }

        final remainingMinutes = authProvider.remainingSessionMinutes ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.orange.shade100,
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your session will expire in $remainingMinutes minute${remainingMinutes != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Proactively refresh the session
                  final success = await authProvider.ensureAuthenticated();
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session refreshed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: Text(
                  'Extend Session',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
