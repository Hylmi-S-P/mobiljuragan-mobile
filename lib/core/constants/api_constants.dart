import 'package:flutter/foundation.dart';

/// Konfigurasi endpoint REST API backend MobilJuragan
class ApiConstants {
  /// Base URL API backend.
  /// Android Emulator: 10.0.2.2:4000
  /// Web / Desktop / iOS Simulator: 127.0.0.1:4000 atau IP LAN
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:4000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:4000/api/v1';
    }
  }

  // Endpoints Katalog Armada
  static const String vehiclesEndpoint = '/vehicles';
  static const String vehicleCategoriesEndpoint = '/vehicles/categories';

  // Endpoints FAQ Bantuan
  static const String faqsEndpoint = '/faqs';

  // Endpoints Autentikasi Customer
  static const String requestOtpEndpoint = '/auth/otp/request';
  static const String verifyOtpEndpoint = '/auth/otp/verify';

  // Endpoints Pemesanan
  static const String bookingsEndpoint = '/bookings';

  // Durasi timeout HTTP request
  static const Duration timeoutDuration = Duration(seconds: 8);
}
