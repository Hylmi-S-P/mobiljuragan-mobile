import 'package:flutter/foundation.dart';

/// Konfigurasi endpoint REST API backend MobilJuragan
class ApiConstants {
  /// Base URL API backend.
  ///
  /// Urutan yang dipakai:
  /// 1. `--dart-define=API_BASE_URL=...` kalau diisi saat build.
  /// 2. `127.0.0.1` untuk Android, yang hanya bisa tembus lewat
  ///    `adb reverse tcp:4000 tcp:4000`.
  /// 3. `127.0.0.1` juga untuk desktop dan iOS simulator.
  ///
  /// Kenapa Android memakai `127.0.0.1`, bukan `10.0.2.2`:
  /// `10.0.2.2` adalah alamat khusus Emulator yang menunjuk ke laptop. Di HP
  /// asli alamat itu tidak ada, sehingga seluruh permintaan gagal walaupun
  /// kabelnya tersambung. `127.0.0.1` ditambah `adb reverse` bekerja di
  /// keduanya, jadi satu pengaturan berlaku untuk emulator maupun HP asli.
  static String get baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:4000/api/v1';
    }
    return 'http://127.0.0.1:4000/api/v1';
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
