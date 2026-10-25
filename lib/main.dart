import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/support_controller.dart';
import 'controllers/vehicle_controller.dart';
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

  // 1. Inisialisasi layanan notifikasi sistem perangkat
  await NotificationService().init();

  // 2. Inisialisasi tier penyimpanan pengaturan (SharedPreferences)
  final settingsService = await AppSettingsService.create();

  // 3. Inisialisasi tier penyimpanan rahasia & token (FlutterSecureStorage)
  final secureStorage = SecureStorageService();

  // 4. Inisialisasi tier penyimpanan terstruktur lokal (Drift SQLite)
  final appDatabase = AppDatabase();

  // 5. Inisialisasi lapisan Repository Offline-First
  final vehicleRepo = VehicleRepository(
    vehicleDao: appDatabase.vehicleDao,
    settingsService: settingsService,
  );
  final authRepo = AuthRepository(
    secureStorage: secureStorage,
  );
  final bookingRepo = BookingRepository(
    appDatabase.bookingDao,
  );

  // Seed awal database lokal jika aplikasi baru pertama kali dibuka
  await vehicleRepo.ensureSeeded();

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
          create: (_) => BookingController(
            repository: bookingRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            repository: authRepo,
            secureStorage: secureStorage,
          )..initSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupportController()
            ..fetchFaqs()
            ..fetchTickets(),
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
