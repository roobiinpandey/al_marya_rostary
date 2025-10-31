import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/almaryah_theme.dart';
import 'utils/app_router.dart';
import 'features/cart/presentation/providers/cart_provider.dart';
import 'features/admin/presentation/providers/admin_provider.dart';
import 'features/admin/presentation/providers/admin_user_provider.dart';
import 'features/admin/presentation/providers/firebase_user_provider.dart';
import 'features/admin/presentation/providers/product_provider.dart';
import 'features/admin/presentation/providers/category_provider.dart';
import 'features/admin/presentation/providers/slider_provider.dart';
import 'features/admin/presentation/providers/quick_category_provider.dart';
import 'features/admin/presentation/providers/user_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'data/repositories/firebase_auth_repository_impl.dart';
import 'data/datasources/firebase_auth_service.dart';
import 'features/coffee/presentation/providers/coffee_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'core/providers/language_provider.dart';
import 'core/services/product_api_service.dart';
import 'core/services/category_api_service.dart';
import 'core/services/slider_api_service.dart';
import 'core/services/user_api_service.dart';
import 'core/services/gift_set_api_service.dart';
import 'providers/location_provider.dart';
import 'providers/address_provider.dart';
import 'providers/gift_set_provider.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Don't crash the app - some features will be limited without Firebase
    // but the app should still work for browsing products, etc.
  }

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;

  const MyApp({super.key, this.firebaseInitialized = true});

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
        ChangeNotifierProvider(create: (context) => FirebaseUserProvider()),
        ChangeNotifierProvider(create: (context) => CoffeeProvider()),
        ChangeNotifierProvider(
          create: (context) => ProductProvider(ProductApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryProvider(categoryApiService: CategoryApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              SliderProvider(sliderApiService: SliderApiService()),
        ),
        ChangeNotifierProvider(create: (context) => QuickCategoryProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProvider(userApiService: UserApiService()),
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => AddressProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => GiftSetProvider(GiftSetApiService()),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          if (languageProvider.isLoading) {
            return MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'ALMARYAH ROSTERY',
            theme: AlmaryahTheme.light,
            darkTheme: AlmaryahTheme.dark,
            themeMode: ThemeMode.system,
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
