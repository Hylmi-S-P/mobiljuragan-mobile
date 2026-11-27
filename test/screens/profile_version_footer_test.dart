import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/controllers/auth_controller.dart';
import 'package:mobiljuragan_mobile/controllers/booking_controller.dart';
import 'package:mobiljuragan_mobile/models/user_model.dart';
import 'package:mobiljuragan_mobile/screens/profile_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

void main() {
  final penggunaUji = UserModel(
    id: 'user-uji-profil-001',
    name: 'Harun Yahya',
    phoneNumber: '081248002910',
    city: 'Merauke, Papua Selatan',
    avatarInitials: 'HY',
  );

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'MobilJuragan',
      packageName: 'id.mobiljuragan.mobiljuragan_mobile',
      version: '1.0.5',
      buildNumber: '6',
      buildSignature: '',
    );
  });

  Widget wrapProfile({
    required AuthController authController,
    Size? viewport,
    double textScale = 1.0,
  }) {
    final child = MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<BookingController>(
          create: (_) => BookingController(),
        ),
      ],
      child: MaterialApp(
        builder: viewport == null
            ? null
            : (context, widget) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: viewport,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: widget!,
              ),
        home: const ProfileScreen(),
      ),
    );
    return child;
  }

  group('ProfileScreen - Penanda Versi Aplikasi', () {
    testWidgets('Mode tamu menampilkan label versi di bagian bawah profil', (
      tester,
    ) async {
      final auth = AuthController();

      await tester.pumpWidget(wrapProfile(authController: auth));
      await tester.pumpAndSettle();

      expect(find.text('MobilJuragan \u00b7 v1.0.5 (6)'), findsOneWidget);
      expect(find.text('Keluar dari Akun'), findsNothing);
    });

    testWidgets(
      'Mode login menampilkan label versi di bawah tombol Keluar dari Akun tanpa overflow pada layar 320x640 @ 1.3x',
      (tester) async {
        const viewport = Size(320, 640);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final auth = AuthController()..setSessionForTest(user: penggunaUji);

        await tester.pumpWidget(
          wrapProfile(
            authController: auth,
            viewport: viewport,
            textScale: 1.3,
          ),
        );
        await tester.pumpAndSettle();

        final logoutFinder = find.text('Keluar dari Akun');
        final versionFinder = find.text('MobilJuragan \u00b7 v1.0.5 (6)');

        expect(logoutFinder, findsOneWidget);
        expect(versionFinder, findsOneWidget);

        final logoutBottom = tester.getBottomLeft(logoutFinder).dy;
        final versionTop = tester.getTopLeft(versionFinder).dy;
        expect(versionTop, greaterThan(logoutBottom));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
