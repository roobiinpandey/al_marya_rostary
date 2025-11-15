import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class SettingsApiService {
  final String baseUrl = AppConstants.baseUrl;

  /// Fetch public settings from backend
  Future<Map<String, dynamic>> fetchPublicSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/settings?includePrivate=false'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'Failed to load settings');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('fetching public settings: $e');
      throw Exception('Failed to fetch settings: $e');
    }
  }

  /// Get a specific setting value
  Future<dynamic> getSettingValue(String key, {dynamic defaultValue}) async {
    try {
      final settings = await fetchPublicSettings();

      // Settings are grouped by category, so we need to search through them
      for (final category in settings.values) {
        if (category is Map && category.containsKey(key)) {
          return category[key]['value'] ?? defaultValue;
        }
      }

      return defaultValue;
    } catch (e) {
      AppLogger.error('getting setting value for $key: $e');
      return defaultValue;
    }
  }

  /// Get contact information settings
  Future<ContactInfo> getContactInfo() async {
    try {
      final settings = await fetchPublicSettings();

      // Extract general and business settings
      final general = settings['general'] as Map<String, dynamic>? ?? {};
      final business = settings['business'] as Map<String, dynamic>? ?? {};
      final social = settings['social'] as Map<String, dynamic>? ?? {};

      return ContactInfo(
        email: _extractValue(
          general,
          'contact_email',
          'info@almaryarostery.ae',
        ),
        phone: _extractValue(general, 'contact_phone', '+971 4 123 4567'),
        address: _extractValue(general, 'address', 'Dubai, UAE'),
        latitude: _extractValue(general, 'store_latitude', ''),
        longitude: _extractValue(general, 'store_longitude', ''),
        whatsapp: _extractValue(social, 'whatsapp_number', '+971 50 123 4567'),
        businessHours: _extractValue(
          business,
          'business_hours',
          '9:00 AM - 10:00 PM',
        ),
      );
    } catch (e) {
      AppLogger.error('getting contact info: $e');
      // Return default values on error
      return ContactInfo(
        email: 'info@almaryarostery.ae',
        phone: '+971 4 123 4567',
        address: 'Dubai, UAE',
        latitude: '',
        longitude: '',
        whatsapp: '+971 50 123 4567',
        businessHours: '9:00 AM - 10:00 PM',
      );
    }
  }

  /// Helper method to extract value from settings
  dynamic _extractValue(
    Map<String, dynamic> category,
    String key,
    dynamic defaultValue,
  ) {
    if (category.containsKey(key)) {
      final setting = category[key];
      if (setting is Map && setting.containsKey('value')) {
        return setting['value'] ?? defaultValue;
      }
      return setting ?? defaultValue;
    }
    return defaultValue;
  }
}

/// Contact information model
class ContactInfo {
  final String email;
  final String phone;
  final String address;
  final String latitude;
  final String longitude;
  final String whatsapp;
  final String businessHours;

  ContactInfo({
    required this.email,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.whatsapp,
    required this.businessHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'whatsapp': whatsapp,
      'businessHours': businessHours,
    };
  }

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      businessHours: json['businessHours'] ?? '',
    );
  }
}
