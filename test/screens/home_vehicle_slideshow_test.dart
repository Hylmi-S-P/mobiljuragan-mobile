import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/auth_controller.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/controllers/vehicle_controller.dart';
import 'package:mobiljuragan_mobile/models/vehicle_model.dart';
import 'package:mobiljuragan_mobile/screens/home_screen.dart';
import 'package:mobiljuragan_mobile/screens/vehicle_detail_screen.dart';
import 'package:provider/provider.dart';

VehicleModel _buatUnit({
  required String id,
  required String name,
  String plateNumber = 'PA1001M',
  String category = 'MPV',
  String availabilityTag = 'Tersedia',
  bool isPopular = false,
  int pricePerDay = 450000,
}) {
  return VehicleModel(
    id: id,
    name: name,
    plateNumber: plateNumber,
    category: category,
    seatCapacity: '7 Penumpang',
    transmission: 'Manual',
    bodyType: 'MPV Keluarga',
    condition: 'Siap Pakai',
    availabilityTag: availabilityTag,
    isPopular: isPopular,
    pricePerDay: pricePerDay,
    imageUrl: '',
  );
}

Widget _bungkusHome({
  required VehicleController vehicleController,
  BookingController? bookingController,
  bool isActive = true,
  Duration autoSlideInterval = const Duration(seconds: 4),
  Size? viewport,
  double textScale = 1.0,
}) {
  final booking = bookingController ?? BookingController();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
      ChangeNotifierProvider<BookingController>.value(value: booking),
      ChangeNotifierProvider<VehicleController>.value(
        value: vehicleController,
      ),
    ],
    child: MaterialApp(
      builder: viewport == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: viewport,
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
      home: HomeScreen(
        isActive: isActive,
        autoSlideInterval: autoSlideInterval,
      ),
    ),
  );
}

void main() {
  group('HomeScreen Vehicle Slideshow Widget Tests', () {
    testWidgets(
      'Filter hanya unit tersedia dan tempatkan unit populer di slide pertama',
      (tester) async {
        final vehicleController = VehicleController();
        vehicleController.updateVehicles([
          _buatUnit(
            id: 'v-disewa',
            name: 'XPANDER DISEWA',
            availabilityTag: 'DISEWA',
            isPopular: true,
          ),
          _buatUnit(
            id: 'v-tersedia-biasa',
            name: 'AVANZA TERSEDIA',
            availabilityTag: 'Tersedia',
            isPopular: false,
          ),
          _buatUnit(
            id: 'v-tersedia-populer',
            name: 'INNOVA POPULER',
            availabilityTag: 'Tersedia • Lepas Kunci',
            isPopular: true,
          ),
        ]);

        await tester.pumpWidget(
          _bungkusHome(vehicleController: vehicleController),
        );
        await tester.pump();

        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('INNOVA POPULER'), findsOneWidget);
        expect(find.text('TERPOPULER DI MOBILJURAGAN'), findsOneWidget);
        expect(find.text('1/2'), findsOneWidget);
        expect(find.text('XPANDER DISEWA'), findsNothing);
      },
    );

    testWidgets(
      'Swipe manual ke slide kedua menampilkan armada kedua dan mengetuk kartu membuka VehicleDetailScreen',
      (tester) async {
        final vehicleController = VehicleController();
        final bookingController = BookingController();
        vehicleController.updateVehicles([
          _buatUnit(
            id: 'v-1',
            name: 'FORTUNER VRZ MERAUKE',
            category: 'SUV',
            availabilityTag: 'Tersedia',
            isPopular: true,
          ),
          _buatUnit(
            id: 'v-2',
            name: 'HILUX DOUBLE CABIN',
            category: 'Pickup',
            availabilityTag: 'Tersedia',
            isPopular: false,
          ),
        ]);

        await tester.pumpWidget(
          _bungkusHome(
            vehicleController: vehicleController,
            bookingController: bookingController,
          ),
        );
        await tester.pump();

        expect(find.text('FORTUNER VRZ MERAUKE'), findsOneWidget);
        expect(find.text('1/2'), findsOneWidget);

        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.text('HILUX DOUBLE CABIN'), findsOneWidget);
        expect(find.text('ARMADA TERSEDIA'), findsOneWidget);
        expect(find.text('2/2'), findsOneWidget);

        await tester.tap(find.text('HILUX DOUBLE CABIN'));
        await tester.pumpAndSettle();

        expect(find.byType(VehicleDetailScreen), findsOneWidget);
        expect(find.text('Detail Kendaraan'), findsOneWidget);
        expect(find.text('HILUX DOUBLE CABIN'), findsOneWidget);
        expect(bookingController.selectedVehicle?.id, 'v-2');
      },
    );

    testWidgets(
      'Auto-slide berpindah otomatis, berhenti bersih saat dispose, dan fallback tampil saat semua unit disewa',
      (tester) async {
        final vehicleController = VehicleController();
        vehicleController.updateVehicles([
          _buatUnit(
            id: 'v-populer',
            name: 'AVANZA VELOZ HITAM',
            isPopular: true,
          ),
          _buatUnit(
            id: 'v-kedua',
            name: 'RUSH TRD PUTIH',
            isPopular: false,
          ),
        ]);

        await tester.pumpWidget(
          _bungkusHome(
            vehicleController: vehicleController,
            autoSlideInterval: const Duration(milliseconds: 500),
          ),
        );
        await tester.pump();

        expect(find.text('AVANZA VELOZ HITAM'), findsOneWidget);
        expect(find.text('1/2'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('RUSH TRD PUTIH'), findsOneWidget);
        expect(find.text('2/2'), findsOneWidget);

        // Semua unit berubah menjadi disewa -> fallback KATALOG ARMADA tetap tampil
        vehicleController.updateVehicles([
          _buatUnit(
            id: 'v-sewa-1',
            name: 'TERIOS KELUARGA',
            availabilityTag: 'DISEWA',
            isPopular: false,
          ),
          _buatUnit(
            id: 'v-sewa-2',
            name: 'CARRY NIAGA',
            availabilityTag: 'Sedang Disewa',
            isPopular: false,
          ),
        ]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.text('CARRY NIAGA'), findsOneWidget);
        expect(find.text('KATALOG ARMADA'), findsOneWidget);
        expect(find.text('2/2'), findsOneWidget);

        // Menyusut ke 1 unit saat sedang di slide 2 -> aman clamp ke index 0
        vehicleController.updateVehicles([
          _buatUnit(
            id: 'v-sewa-1',
            name: 'TERIOS KELUARGA',
            availabilityTag: 'DISEWA',
            isPopular: false,
          ),
        ]);
        await tester.pump();
        await tester.pump();

        expect(find.text('TERIOS KELUARGA'), findsOneWidget);
        expect(find.text('KATALOG ARMADA'), findsOneWidget);
        expect(find.byType(PageView), findsNothing);

        // Dispose eksplisit memastikan tidak ada pending timer tersisa
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'Audit anti-overflow: HomeScreen dengan 9 unit di viewport 320x568 @ 1.3x bebas FlutterError',
      (tester) async {
        const viewport = Size(320, 568);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final vehicleController = VehicleController();
        vehicleController.updateVehicles(
          List.generate(
            9,
            (i) => _buatUnit(
              id: 'v-$i',
              name: 'ARMADA MERAUKE SERI PANJANG ${i + 1}',
              plateNumber: 'PA100${i}M',
              isPopular: i == 0,
            ),
          ),
        );

        await tester.pumpWidget(
          _bungkusHome(
            vehicleController: vehicleController,
            viewport: viewport,
            textScale: 1.3,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('1/9'), findsOneWidget);
      },
    );
  });
}
