import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/pages/register_page.dart';
import 'package:qahwat_al_emarat/features/auth/presentation/providers/auth_provider.dart';
import 'package:qahwat_al_emarat/core/theme/app_theme.dart';
import '../../helpers/mocks.mocks.dart';

void main() {
  // late MockAuthProvider mockAuthProvider; // Uncomment after running build_runner

  // setUp(() {
  //   mockAuthProvider = MockAuthProvider();
  // });

  // Helper to reduce repeated stubbing in tests.
  // void stubAuthProvider(MockAuthProvider provider) { // Uncomment after running build_runner
  //   when(provider.state).thenReturn(AuthState.initial);
  //   when(provider.isLoading).thenReturn(false);
  //   when(provider.hasError).thenReturn(false);
  //   when(provider.errorMessage).thenReturn(null);
  //   when(provider.isGuest).thenReturn(false);
  // }

  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: SizedBox(
        height: 1200, // Larger height to prevent render overflow in tests
        child: const RegisterPage(),
      ),
    );
  }

  group('RegisterPage Widget Tests', () {
    testWidgets('should display register form elements', (
      WidgetTester tester,
    ) async {
      // stubAuthProvider(mockAuthProvider);

      await tester.pumpWidget(createTestWidget());

      // Check header elements
      expect(
        find.text('Create Account'),
        findsNWidgets(2),
      ); // Title and button text
      expect(find.text('Join our coffee community'), findsOneWidget);

      // Check form fields exist
      expect(
        find.byType(TextFormField),
        findsNWidgets(5),
      ); // name, email, phone, password, confirm password

      // Check back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Check header icon
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should have terms and conditions checkbox', (
      WidgetTester tester,
    ) async {
      // stubAuthProvider(mockAuthProvider);

      await tester.pumpWidget(createTestWidget());

      // Check terms checkbox exists
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('should have create account button', (
      WidgetTester tester,
    ) async {
      // stubAuthProvider(mockAuthProvider);

      await tester.pumpWidget(createTestWidget());

      // Check button exists (find by ElevatedButton, not text since text appears twice)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display login link', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check login link exists
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should have password visibility toggles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Should have two visibility toggles (password and confirm password)
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
    });

    testWidgets('should show error message when auth provider has error', (
      WidgetTester tester,
    ) async {
      // Stub the mock provider to be in an error state
      // when(mockAuthProvider.hasError).thenReturn(true);
      // when(mockAuthProvider.errorMessage).thenReturn('Registration failed');
      // when(mockAuthProvider.isLoading).thenReturn(false);
      // when(mockAuthProvider.isGuest).thenReturn(false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SizedBox(height: 1200, child: const RegisterPage()),
        ),
      );

      // Should show error message
      expect(find.text('Registration failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
