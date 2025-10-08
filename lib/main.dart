import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'utils/app_router.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/providers/admin_user_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/coffee/presentation/providers/coffee_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => AdminUserProvider()),
        ChangeNotifierProvider(create: (context) => CoffeeProvider()),
      ],
      child: MaterialApp(
        title: 'Qahwat Al Emarat',
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
        onGenerateRoute: AppRouter.generateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
