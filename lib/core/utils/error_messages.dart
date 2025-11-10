import 'package:flutter/material.dart';

/// User-friendly error messages for production
class ErrorMessages {
  // ============================================================================
  // AUTHENTICATION ERRORS
  // ============================================================================

  static const String authEmailAlreadyInUse =
      'This email is already registered. Please sign in or use a different email.';
  static const String authInvalidEmail = 'Please enter a valid email address.';
  static const String authWeakPassword =
      'Please choose a stronger password (at least 6 characters).';
  static const String authWrongPassword =
      'Incorrect password. Please try again.';
  static const String authUserNotFound =
      'No account found with this email. Please sign up first.';
  static const String authUserDisabled =
      'This account has been disabled. Please contact support.';
  static const String authTooManyRequests =
      'Too many login attempts. Please try again later.';
  static const String authOperationNotAllowed =
      'This sign-in method is not enabled. Please contact support.';
  static const String authInvalidCredential =
      'Invalid credentials. Please check your information and try again.';
  static const String authAccountExistsWithDifferentCredential =
      'An account already exists with this email using a different sign-in method.';
  static const String authNetworkRequestFailed =
      'Network error. Please check your internet connection.';
  static const String authGeneric = 'Sign-in failed. Please try again.';

  // ============================================================================
  // NETWORK ERRORS
  // ============================================================================

  static const String networkNoConnection =
      'No internet connection. Please check your network and try again.';
  static const String networkTimeout = 'Request timed out. Please try again.';
  static const String networkServerError =
      'Server error. Please try again later.';
  static const String networkBadRequest = 'Invalid request. Please try again.';
  static const String networkUnauthorized =
      'Session expired. Please sign in again.';
  static const String networkForbidden =
      'Access denied. You don\'t have permission for this action.';
  static const String networkNotFound = 'Resource not found. Please try again.';
  static const String networkGeneric =
      'Something went wrong. Please try again.';

  // ============================================================================
  // PAYMENT ERRORS
  // ============================================================================

  static const String paymentCardDeclined =
      'Your card was declined. Please use a different payment method.';
  static const String paymentInsufficientFunds =
      'Insufficient funds. Please use a different card.';
  static const String paymentInvalidCard =
      'Invalid card information. Please check and try again.';
  static const String paymentExpiredCard =
      'Your card has expired. Please use a different card.';
  static const String paymentProcessingError =
      'Payment processing failed. Please try again.';
  static const String paymentCancelled = 'Payment was cancelled.';
  static const String paymentGeneric =
      'Payment failed. Please try again or use a different payment method.';

  // ============================================================================
  // ORDER ERRORS
  // ============================================================================

  static const String orderCreationFailed =
      'Failed to create order. Please try again.';
  static const String orderNotFound =
      'Order not found. Please check your order history.';
  static const String orderCancellationFailed =
      'Failed to cancel order. Please contact support.';
  static const String orderUpdateFailed =
      'Failed to update order. Please try again.';

  // ============================================================================
  // PRODUCT ERRORS
  // ============================================================================

  static const String productNotFound =
      'Product not found or no longer available.';
  static const String productOutOfStock =
      'This product is currently out of stock.';
  static const String productLoadFailed =
      'Failed to load products. Please try again.';

  // ============================================================================
  // CART ERRORS
  // ============================================================================

  static const String cartUpdateFailed =
      'Failed to update cart. Please try again.';
  static const String cartEmpty =
      'Your cart is empty. Add some items to continue.';

  // ============================================================================
  // WISHLIST ERRORS
  // ============================================================================

  static const String wishlistAddFailed =
      'Failed to add to wishlist. Please try again.';
  static const String wishlistRemoveFailed =
      'Failed to remove from wishlist. Please try again.';
  static const String wishlistLoadFailed =
      'Failed to load wishlist. Please try again.';

  // ============================================================================
  // ADDRESS ERRORS
  // ============================================================================

  static const String addressSaveFailed =
      'Failed to save address. Please try again.';
  static const String addressLoadFailed =
      'Failed to load addresses. Please try again.';
  static const String addressDeleteFailed =
      'Failed to delete address. Please try again.';
  static const String locationPermissionDenied =
      'Location permission denied. Please enable it in settings.';
  static const String locationServiceDisabled =
      'Location services are disabled. Please enable them in settings.';

  // ============================================================================
  // SUBSCRIPTION ERRORS
  // ============================================================================

  static const String subscriptionCreateFailed =
      'Failed to create subscription. Please try again.';
  static const String subscriptionCancelFailed =
      'Failed to cancel subscription. Please contact support.';
  static const String subscriptionUpdateFailed =
      'Failed to update subscription. Please try again.';

  // ============================================================================
  // FILE UPLOAD ERRORS
  // ============================================================================

  static const String fileUploadFailed =
      'Failed to upload file. Please try again.';
  static const String fileTooBig =
      'File is too large. Please choose a smaller file.';
  static const String invalidFileType =
      'Invalid file type. Please choose a different file.';

  // ============================================================================
  // VALIDATION ERRORS
  // ============================================================================

  static const String validationRequired = 'This field is required.';
  static const String validationInvalidEmail =
      'Please enter a valid email address.';
  static const String validationInvalidPhone =
      'Please enter a valid phone number.';
  static const String validationPasswordTooShort =
      'Password must be at least 6 characters.';
  static const String validationPasswordMismatch = 'Passwords do not match.';

  // ============================================================================
  // GENERIC ERRORS
  // ============================================================================

  static const String genericError = 'Something went wrong. Please try again.';
  static const String maintenanceMode =
      'We\'re currently performing maintenance. Please try again later.';
  static const String sessionExpired =
      'Your session has expired. Please sign in again.';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get user-friendly message for Firebase Auth error codes
  static String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return authEmailAlreadyInUse;
      case 'invalid-email':
        return authInvalidEmail;
      case 'weak-password':
        return authWeakPassword;
      case 'wrong-password':
        return authWrongPassword;
      case 'user-not-found':
        return authUserNotFound;
      case 'user-disabled':
        return authUserDisabled;
      case 'too-many-requests':
        return authTooManyRequests;
      case 'operation-not-allowed':
        return authOperationNotAllowed;
      case 'invalid-credential':
        return authInvalidCredential;
      case 'account-exists-with-different-credential':
        return authAccountExistsWithDifferentCredential;
      case 'network-request-failed':
        return authNetworkRequestFailed;
      default:
        return authGeneric;
    }
  }

  /// Get user-friendly message for HTTP status codes
  static String getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return networkBadRequest;
      case 401:
        return networkUnauthorized;
      case 403:
        return networkForbidden;
      case 404:
        return networkNotFound;
      case 408:
        return networkTimeout;
      case 500:
      case 502:
      case 503:
      case 504:
        return networkServerError;
      default:
        return networkGeneric;
    }
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
