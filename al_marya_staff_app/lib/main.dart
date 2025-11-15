import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_constants.dart';
import 'core/auth/token_storage.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/pin_login_screen.dart';
import 'features/auth/screens/qr_scanner_screen.dart';
import 'features/auth/screens/change_pin_screen.dart';
import 'features/orders/screens/orders_list_screen.dart';
import 'features/products/product_list_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (for future auth/messaging integration)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local storage
  await TokenStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Olive gold color matching main user app
    const Color oliveGold = Color(0xFFA89A6A);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: oliveGold,
        colorScheme: ColorScheme.fromSeed(
          seedColor: oliveGold,
          primary: oliveGold,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: oliveGold,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: oliveGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const PinLoginScreen(),
        '/qr-scan': (context) => const QrScannerScreen(),
        '/change-pin': (context) => const ChangePinScreen(),
        '/home': (context) => const OrdersListScreen(),
        '/products': (context) => const ProductListPage(),
      },
    );
  }
}
