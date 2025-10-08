import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/pages/login_page.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';
import 'package:qahwat_al_emarat/core/theme/app_theme.dart';
// import 'package:qahwat_al_emarat/domain/repositories/auth_repository.dart';
import '../../helpers/mocks.mocks.dart';

// If MockAuthProvider is not generated, add this below your imports:
import 'package:mockito/annotations.dart';
// import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';

// Import the generated mock file
// import 'login_page_test.mocks.dart'; // Uncomment after running build_runner

@GenerateMocks([AuthProvider])
void main() {
  // NOTE: Generated mocks are not available until build_runner runs.
  // Uncomment the following line after generating mocks:
  // late MockAuthProvider mockAuthProvider;
  late MockAuthRepository mockAuthRepository;

  // setUp(() {
  //   mockAuthProvider = MockAuthProvider();
  // });

  // Helper to reduce repeated stubbing in tests.
  // void stubAuthProvider(MockAuthProvider provider) {
  //   when(provider.state).thenReturn(AuthState.initial);
  //   when(provider.isLoading).thenReturn(false);
  //   when(provider.hasError).thenReturn(false);
  //   when(provider.errorMessage).thenReturn(null);
  //   when(provider.isAuthenticated).thenReturn(false);
  //   when(provider.isGuest).thenReturn(false);
  // }

  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: SizedBox(
        height: 1200, // Larger height to fit all form elements
        child: const LoginPage(),
      ),
    );
  }

  group('LoginPage Widget Tests', () {
    testWidgets('should display login form elements', (
      WidgetTester tester,
    ) async {
      // stubAuthProvider(mockAuthProvider);

      await tester.pumpWidget(createTestWidget());

      // Check header elements
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);

      // Check form fields
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
      ); // email and password

      // Check buttons and links
      expect(find.byType(ElevatedButton), findsOneWidget); // Sign In button
      expect(
        find.byType(TextButton),
        findsAtLeastNWidgets(2),
      ); // Forgot password and sign up
      expect(find.byType(Checkbox), findsOneWidget); // Remember me

      // Check icons
      expect(find.byIcon(Icons.coffee), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should have sign up navigation link', (
      WidgetTester tester,
    ) async {
      // stubAuthProvider(mockAuthProvider);

      await tester.pumpWidget(createTestWidget());

      // Check sign up link exists
      expect(find.byType(TextButton), findsAtLeastNWidgets(2));
    });

    testWidgets('should show error message when auth provider has error', (
      WidgetTester tester,
    ) async {
      // when(mockAuthProvider.state).thenReturn(AuthState.error);
      // when(mockAuthProvider.isLoading).thenReturn(false);
      // when(mockAuthProvider.hasError).thenReturn(true);
      // when(mockAuthProvider.errorMessage).thenReturn('Login failed');
      // when(mockAuthProvider.isAuthenticated).thenReturn(false);
      // when(mockAuthProvider.isGuest).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SizedBox(height: 1200, child: const LoginPage()),
        ),
      );

      // Should show error message
      expect(find.text('Login failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('LoginPage renders correctly from widget_test.dart', (
      WidgetTester tester,
    ) async {
      mockAuthRepository = MockAuthRepository();
      // STUB: Stub the repository methods BEFORE the provider is created.
      // This is crucial because the AuthProvider runs initialization logic in its constructor.
      when(mockAuthRepository.isLoggedIn()).thenAnswer((_) async => false);
      // when(
      //   mockAuthRepository.loadUserFromStorage(),
      // ).thenAnswer((_) async => null);

      // Set up the providers needed for the LoginPage.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) =>
                  AuthProvider(mockAuthRepository, skipInitialization: false),
            ),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pumpAndSettle(); // allow time for async constructor
    });
  });
}
