import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/pin_auth_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/screens/pin_login_screen.dart';
import 'features/deliveries/screens/deliveries_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  try {
    await NotificationService().initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('⚠️ Failed to initialize notifications: $e');
    // Continue without notifications - don't block app startup
  }

  runApp(const AlMaryaDriverApp());
}

class AlMaryaDriverApp extends StatelessWidget {
  const AlMaryaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Al Marya Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.driverTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = PinAuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Give a brief delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    final isAuthenticated = await _authService.initialize();

    if (mounted) {
      if (isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DeliveriesListScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PinLoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOliveGold,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping,
                size: 60,
                color: AppTheme.primaryOliveGold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Almaryah - Delivery',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
