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

  // Endpoint Asisten AI Pelanggan
  static const String aiChatEndpoint = '/ai/chat';

  // Endpoints Pembayaran
  static const String paymentsEndpoint = '/payments';
  static const String paymentsBookingEndpoint = '/payments/booking';

  // Endpoints Dokumen Persyaratan Lepas Kunci
  static const String documentTemplateTextEndpoint =
      '/documents/template/surat-pernyataan-lepas-kunci/text';
  static const String documentTemplatePdfEndpoint =
      '/documents/template/surat-pernyataan-lepas-kunci.pdf';

  // Durasi timeout HTTP request umum
  static const Duration timeoutDuration = Duration(seconds: 8);

  /// Timeout khusus asisten AI.
  ///
  /// Lebih panjang dari [timeoutDuration] karena backend menunggu model sampai
  /// 45 detik sebelum memberi teks cadangan. Kalau klien menyerah lebih dulu,
  /// pelanggan melihat galat padahal jawabannya sebenarnya sedang dibuat.
  static const Duration aiTimeoutDuration = Duration(seconds: 60);
}
