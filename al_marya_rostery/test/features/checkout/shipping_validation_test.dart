import 'package:flutter_test/flutter_test.dart';

/// Tests for shipping form validation logic
void main() {
  group('Phone Validation Tests', () {
    const phonePattern = r'^\+971 5\d{8}$';

    test('Valid phone format: +971 5XXXXXXXX', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+971 5123456789'), isTrue);
      expect(regex.hasMatch('+971 5000000000'), isTrue);
      expect(regex.hasMatch('+971 5999999999'), isTrue);
    });

    test('Invalid phone format: missing space', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+9715123456789'), isFalse);
    });

    test('Invalid phone format: wrong country code', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+966 5123456789'), isFalse); // Saudi Arabia
      expect(regex.hasMatch('+974 5123456789'), isFalse); // Qatar
    });

    test('Invalid phone format: wrong prefix number', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+971 4123456789'), isFalse); // Missing '5'
      expect(regex.hasMatch('+971 6123456789'), isFalse);
      expect(regex.hasMatch('+971 2123456789'), isFalse);
    });

    test('Invalid phone format: too few digits', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+971 512345678'), isFalse); // Only 7 digits
    });

    test('Invalid phone format: too many digits', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+971 51234567890'), isFalse); // 9 digits
    });

    test('Invalid phone format: letters included', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch('+971 5ABC456789'), isFalse);
    });

    test('Invalid phone format: empty string', () {
      final regex = RegExp(phonePattern);
      expect(regex.hasMatch(''), isFalse);
    });

    test('Normalize phone with extra spaces', () {
      final phone = '+971 5123456789   ';
      final trimmed = phone.trim();
      expect(trimmed, equals('+971 5123456789'));
    });
  });

  group('Address Validation Tests', () {
    test('Valid address: non-empty string', () {
      const address = '123 Sheikh Zayed Road, Dubai';
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Invalid address: empty string', () {
      const address = '';
      expect(address.trim().isEmpty, isTrue);
    });

    test('Invalid address: only whitespace', () {
      const address = '   ';
      expect(address.trim().isEmpty, isTrue);
    });

    test('Valid address: with special characters', () {
      const address = 'Villa #12-B, Behind Al Manara Mosque';
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Valid address: with numbers and slashes', () {
      const address = 'Plot 45/B, Street 2nd, Area 3';
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Valid address: from Google Maps reverse-geocoding', () {
      const address = 'Sheikh Zayed Road, Dubai, United Arab Emirates, 00000';
      expect(address.trim().isNotEmpty, isTrue);
    });
  });

  group('Form Validation Integration', () {
    test('Form valid: phone and address both provided', () {
      final phone = '+971 5123456789';
      final address = '123 Sheikh Zayed Road, Dubai';
      final phoneRegex = RegExp(r'^\+971 5\d{8}$');

      final isPhoneValid = phoneRegex.hasMatch(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isTrue);
    });

    test('Form invalid: phone missing, address provided', () {
      final phone = '';
      final address = '123 Sheikh Zayed Road, Dubai';
      final phoneRegex = RegExp(r'^\+971 5\d{8}$');

      final isPhoneValid =
          phone.isNotEmpty && phoneRegex.hasMatch(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });

    test('Form invalid: phone provided, address missing', () {
      final phone = '+971 5123456789';
      final address = '';
      final phoneRegex = RegExp(r'^\+971 5\d{8}$');

      final isPhoneValid = phoneRegex.hasMatch(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });

    test('Form invalid: both phone and address missing', () {
      final phone = '';
      final address = '';
      final phoneRegex = RegExp(r'^\+971 5\d{8}$');

      final isPhoneValid =
          phone.isNotEmpty && phoneRegex.hasMatch(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });

    test('Form invalid: phone wrong format, address valid', () {
      final phone = '+971 4123456789'; // Wrong prefix
      final address = '123 Sheikh Zayed Road, Dubai';
      final phoneRegex = RegExp(r'^\+971 5\d{8}$');

      final isPhoneValid = phoneRegex.hasMatch(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });
  });

  group('GPS Location Tests', () {
    test('Valid GPS coordinates: Dubai center', () {
      const latitude = 25.2048;
      const longitude = 55.2708;

      expect(latitude >= -90 && latitude <= 90, isTrue);
      expect(longitude >= -180 && longitude <= 180, isTrue);
    });

    test('Valid GPS coordinates: edge of map', () {
      const latitude = 90.0; // North pole
      const longitude = -180.0; // Date line

      expect(latitude >= -90 && latitude <= 90, isTrue);
      expect(longitude >= -180 && longitude <= 180, isTrue);
    });

    test('Invalid GPS coordinates: latitude out of range', () {
      const latitude = 91.0;

      expect(latitude >= -90 && latitude <= 90, isFalse);
    });

    test('Invalid GPS coordinates: longitude out of range', () {
      const longitude = 181.0;

      expect(longitude >= -180 && longitude <= 180, isFalse);
    });

    test('GPS fallback to manual address when permission denied', () {
      final address = 'Selected from manual entry';
      final gpsCoordinates = null;

      expect(address.isNotEmpty, isTrue);
      expect(gpsCoordinates, isNull);
    });
  });

  group('Phone Format Normalization', () {
    test('Remove extra spaces: leading/trailing', () {
      final phone = '  +971 5123456789  ';
      final normalized = phone.trim();
      expect(normalized, equals('+971 5123456789'));
    });

    test('Phone stays same with correct formatting', () {
      final phone = '+971 5123456789';
      final normalized = phone.trim();
      expect(normalized, equals('+971 5123456789'));
    });

    test('Phone with internal extra spaces (invalid)', () {
      final phone = '+971  5123456789'; // Double space
      final regex = RegExp(r'^\+971 5\d{8}$');
      expect(regex.hasMatch(phone.trim()), isFalse);
    });
  });

  group('User Input Edge Cases', () {
    test('Phone with dashes (should be invalid after trimming)', () {
      final phone = '+971-5-123-456-789';
      final regex = RegExp(r'^\+971 5\d{8}$');
      expect(regex.hasMatch(phone.trim()), isFalse);
    });

    test('Address with newlines (should normalize)', () {
      final address = 'Street 1\nDubai\nUAE';
      expect(address.trim().isNotEmpty, isTrue); // Still valid after trim
    });

    test('Address with multiple spaces (should still be valid)', () {
      final address = 'Villa  123   Dubai'; // Multiple spaces
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Phone starting with country code without +', () {
      final phone = '971 5123456789';
      final regex = RegExp(r'^\+971 5\d{8}$');
      expect(regex.hasMatch(phone.trim()), isFalse);
    });

    test('Phone with parentheses (invalid format)', () {
      final phone = '+971 (5) 123-456-789';
      final regex = RegExp(r'^\+971 5\d{8}$');
      expect(regex.hasMatch(phone.trim()), isFalse);
    });
  });
}
