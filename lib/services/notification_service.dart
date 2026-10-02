import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Layanan notifikasi lokal perangkat (System Notification)
/// Menampilkan notifikasi native di luar aplikasi (status bar / notification drawer)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi dan permission handler
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);

    // Meminta izin notifikasi untuk Android 13+ (TIRAMISU ke atas)
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// Menampilkan notifikasi native saat tarif final terbit dari admin
  Future<void> showTariffReadyNotification({
    required String bookingId,
    required String vehicleName,
    required int totalCost,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'mobiljuragan_order_status',
      'Status Pesanan MobilJuragan',
      channelDescription: 'Notifikasi perubahan status pesanan dan penerbitan tarif resmi final.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final formattedCost = totalCost.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    await _notificationsPlugin.show(
      id: bookingId.hashCode,
      title: 'Biaya Final Sudah Tersedia',
      body: 'Tarif resmi $vehicleName ($bookingId) sebesar Rp $formattedCost telah siap. Silakan selesaikan pembayaran melalui Chat CS.',
      notificationDetails: notificationDetails,
    );
  }

  /// Menampilkan notifikasi native saat kode OTP dikirimkan
  Future<void> showOtpNotification({
    required String otp,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'mobiljuragan_otp',
      'Verifikasi Kode OTP MobilJuragan',
      channelDescription: 'Notifikasi kode keamanan verifikasi akun dan reset password.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: 9999,
      title: 'WhatsApp • MobilJuragan Merauke',
      body: 'Kode OTP verifikasi akun Anda adalah $otp. Rahasiakan kode ini dari pihak lain.',
      notificationDetails: notificationDetails,
    );
  }
}

