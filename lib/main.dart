import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/support_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'core/config/app_config_store.dart';
import 'core/network/app_config_api_service.dart';
import 'data/local/database/app_database.dart';
import 'data/local/preferences/app_settings_service.dart';
import 'data/local/secure/secure_storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/vehicle_repository.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* 1. Inisialisasi layanan notifikasi sistem perangkat.
     Notifikasi hanya pelengkap: kegagalannya tidak boleh menghalangi aplikasi
     dibuka, jadi galat ditelan di sini juga (init() sendiri sudah menangkap,
     ini jaring kedua kalau kegagalan terjadi di luar jangkauannya). */
  try {
    await NotificationService().init();
  } catch (galat) {
    debugPrint('Notifikasi perangkat tidak aktif: $galat');
  }

  // 2. Inisialisasi tier penyimpanan pengaturan (SharedPreferences)
  final settingsService = await AppSettingsService.create();

  // 3. Inisialisasi tier penyimpanan rahasia & token (FlutterSecureStorage)
  final secureStorage = SecureStorageService();

  // 4. Inisialisasi tier penyimpanan terstruktur lokal (Drift SQLite)
  final appDatabase = AppDatabase();

  /* Pengaturan publik (tarif jasa supir, jam operasional) dibaca dari backend.
     Kegagalan diabaikan: aplikasi tetap bisa dibuka dengan nilai cadangan, dan
     tagihan tetap dihitung server. */
  try {
    final konfigurasi = await AppConfigApiService().fetchConfig();
    AppConfigStore.terapkan(konfigurasi);
  } catch (_) {
    AppConfigStore.reset();
  }

  // 5. Inisialisasi lapisan Repository Offline-First
  final vehicleRepo = VehicleRepository(
    vehicleDao: appDatabase.vehicleDao,
    settingsService: settingsService,
  );
  final authRepo = AuthRepository(secureStorage: secureStorage);
  final bookingRepo = BookingRepository(
    appDatabase.bookingDao,
    null,
    secureStorage,
    appDatabase.vehicleDao,
  );

  // Set system overlay style untuk status bar yang bersih dan transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cardWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // Layanan & Database
        Provider<AppDatabase>.value(value: appDatabase),
        Provider<AppSettingsService>.value(value: settingsService),
        Provider<SecureStorageService>.value(value: secureStorage),
        Provider<VehicleRepository>.value(value: vehicleRepo),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<BookingRepository>.value(value: bookingRepo),

        // State Management Controllers
        ChangeNotifierProvider(
          create: (_) => VehicleController(
            repository: vehicleRepo,
            settingsService: settingsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            repository: authRepo,
            secureStorage: secureStorage,
            bookingRepository: bookingRepo,
          )..initSession(),
        ),
        /* BookingController mengikuti sesi: saat akun berganti, riwayat akun
           sebelumnya dibuang dan riwayat akun baru diambil dari server. */
        ChangeNotifierProxyProvider<AuthController, BookingController>(
          create: (_) => BookingController(
            repository: bookingRepo,
          ),
          update: (_, auth, booking) {
            if (booking != null) {
              booking.syncIfSessionChanged(auth.currentUser?.id);
            }
            return booking ?? BookingController(repository: bookingRepo);
          },
        ),
        ChangeNotifierProxyProvider<AuthController, SupportController>(
          create: (_) => SupportController()..fetchFaqs(),
          update: (_, auth, support) {
            if (support != null) {
              support.syncIfSessionChanged(auth.currentUser?.id);
            }
            return support ?? (SupportController()..fetchFaqs());
          },
        ),
      ],
      child: const MobilJuraganApp(),
    ),
  );
}

/// Root Widget MobilJuragan Mobile App
class MobilJuraganApp extends StatelessWidget {
  const MobilJuraganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobilJuragan Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
