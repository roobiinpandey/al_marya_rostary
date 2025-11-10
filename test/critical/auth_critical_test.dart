import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qahwat_al_emarat/data/datasources/firebase_auth_service.dart';
import 'package:qahwat_al_emarat/data/repositories/firebase_auth_repository_impl.dart';

import 'auth_critical_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  group('Authentication Critical Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;
    late FirebaseAuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();
      authService = FirebaseAuthService(auth: mockFirebaseAuth);
    });

    group('Email/Password Sign In', () {
      test('successful sign in returns user', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'password123';

        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn(testEmail);
        when(mockUser.displayName).thenReturn('Test User');
        when(mockUserCredential.user).thenReturn(mockUser);

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, equals('test-uid'));
        expect(result?.email, equals(testEmail));
        verify(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).called(1);
      });

      test('sign in with invalid credentials throws error', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = 'wrongpassword';

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('sign in with non-existent user throws error', () async {
        // Arrange
        const testEmail = 'nonexistent@example.com';
        const testPassword = 'password123';

        when(
          mockFirebaseAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        expect(
          () => authService.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Email/Password Registration', () {
      test('successful registration returns user', () async {
        // Arrange
        const testEmail = 'newuser@example.com';
        const testPassword = 'password123';
        const testName = 'New User';

        when(mockUser.uid).thenReturn('new-uid');
        when(mockUser.email).thenReturn(testEmail);
        when(mockUser.displayName).thenReturn(testName);
        when(mockUserCredential.user).thenReturn(mockUser);

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.registerWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
          name: testName,
        );

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, equals('new-uid'));
        expect(result?.email, equals(testEmail));
        verify(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).called(1);
      });

      test('registration with existing email throws error', () async {
        // Arrange
        const testEmail = 'existing@example.com';
        const testPassword = 'password123';
        const testName = 'Existing User';

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        // Act & Assert
        expect(
          () => authService.registerWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
            name: testName,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });

      test('registration with weak password throws error', () async {
        // Arrange
        const testEmail = 'test@example.com';
        const testPassword = '123'; // Too short
        const testName = 'Test User';

        when(
          mockFirebaseAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act & Assert
        expect(
          () => authService.registerWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
            name: testName,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Sign Out', () {
      test('successful sign out completes', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('Current User', () {
      test('returns current user when authenticated', () {
        // Arrange
        when(mockUser.uid).thenReturn('current-uid');
        when(mockUser.email).thenReturn('current@example.com');
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, equals('current-uid'));
        expect(result?.email, equals('current@example.com'));
      });

      test('returns null when not authenticated', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('Password Reset', () {
      test('successful password reset sends email', () async {
        // Arrange
        const testEmail = 'test@example.com';
        when(
          mockFirebaseAuth.sendPasswordResetEmail(email: testEmail),
        ).thenAnswer((_) async => {});

        // Act
        await authService.sendPasswordResetEmail(email: testEmail);

        // Assert
        verify(
          mockFirebaseAuth.sendPasswordResetEmail(email: testEmail),
        ).called(1);
      });

      test('password reset with invalid email throws error', () async {
        // Arrange
        const testEmail = 'invalid@example.com';
        when(
          mockFirebaseAuth.sendPasswordResetEmail(email: testEmail),
        ).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        expect(
          () => authService.sendPasswordResetEmail(email: testEmail),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('Auth State Changes', () {
      test('auth state stream emits user changes', () async {
        // Arrange
        final controller = StreamController<User?>();
        when(
          mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => controller.stream);

        // Act
        final stream = mockFirebaseAuth.authStateChanges();

        // Assert
        expect(stream, emits(null)); // Initially null
        controller.add(null);

        expect(stream, emits(mockUser)); // User signs in
        controller.add(mockUser);

        expect(stream, emits(null)); // User signs out
        controller.add(null);

        controller.close();
      });
    });
  });
}
