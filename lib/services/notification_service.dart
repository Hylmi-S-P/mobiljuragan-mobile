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

  /// Menampilkan notifikasi native saat masa sewa armada diselesaikan oleh admin
  Future<void> showRentalCompletedNotification({
    required String bookingId,
    required String vehicleName,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'mobiljuragan_order_status',
      'Status Pesanan MobilJuragan',
      channelDescription: 'Notifikasi perubahan status pesanan dan penyelesaian masa sewa armada.',
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
      id: bookingId.hashCode + 1,
      title: 'Penyewaan Selesai',
      body: 'Masa sewa $vehicleName ($bookingId) telah tuntas. Terima kasih telah mempercayai MobilJuragan!',
      notificationDetails: notificationDetails,
    );
  }

  /// Menampilkan notifikasi native saat pesanan ditolak atau dibatalkan.
  ///
  /// Alasan ikut ditampilkan karena pelanggan perlu tahu apa yang harus
  /// diperbaiki (mis. dokumen kurang jelas) tanpa membuka aplikasi lebih dulu.
  Future<void> showBookingRejectedNotification({
    required String bookingId,
    required String vehicleName,
    String? reason,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'mobiljuragan_order_status',
      'Status Pesanan MobilJuragan',
      channelDescription: 'Notifikasi perubahan status pesanan dan penolakan permintaan sewa.',
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

    final alasan = (reason ?? '').trim();
    await _notificationsPlugin.show(
      id: bookingId.hashCode + 2,
      title: 'Pesanan Tidak Dapat Diproses',
      body: alasan.isEmpty
          ? 'Permintaan sewa $vehicleName ($bookingId) ditolak. Buka aplikasi untuk melihat detailnya.'
          : 'Permintaan sewa $vehicleName ($bookingId) ditolak: $alasan',
      notificationDetails: notificationDetails,
    );
  }
}
