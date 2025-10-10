import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'utils/app_router.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/providers/admin_user_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'data/repositories/firebase_auth_repository_impl.dart';
import 'data/datasources/firebase_auth_service.dart';
import 'features/coffee/presentation/providers/coffee_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'core/providers/language_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    // Firebase initialization failed - continue without Firebase features
    print('❌ Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(FirebaseAuthRepositoryImpl(FirebaseAuthService())),
        ),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => AdminProvider()),
        ChangeNotifierProvider(create: (context) => AdminUserProvider()),
        ChangeNotifierProvider(create: (context) => CoffeeProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          if (languageProvider.isLoading) {
            return MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'Qahwat Al Emarat',
            theme: AppTheme.lightTheme,
            locale: languageProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageProvider.supportedLocales,
            localeResolutionCallback: LanguageProvider.localeResolutionCallback,
            home: Directionality(
              textDirection: languageProvider.textDirection,
              child: const SplashPage(),
            ),
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.textDirection,
                child: child ?? Container(),
              );
            },
          );
        },
      ),
    );
  }
}
