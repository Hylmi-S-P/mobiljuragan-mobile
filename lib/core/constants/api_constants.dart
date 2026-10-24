import 'package:flutter/foundation.dart';

/// Konfigurasi endpoint REST API backend MobilJuragan
class ApiConstants {
  /// Base URL API backend.
  /// Mendukung `--dart-define=API_BASE_URL=...`, port forwarding `adb reverse tcp:4000 tcp:4000` (127.0.0.1),
  /// atau IP LAN/Emulator.
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:4000/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://127.0.0.1:4000/api/v1';
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

  // Endpoints Tiket Bantuan Pelanggan
  static const String ticketsEndpoint = '/tickets';

  // Endpoints Pembayaran
  static const String paymentsEndpoint = '/payments';
  static const String paymentsBookingEndpoint = '/payments/booking';

  // Durasi timeout HTTP request
  static const Duration timeoutDuration = Duration(seconds: 8);
}
