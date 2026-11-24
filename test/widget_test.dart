import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/main.dart';
import 'package:mobiljuragan_mobile/screens/splash_screen.dart';

void main() {
  testWidgets('MobilJuraganApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MobilJuraganApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
    expect(find.text('MobilJuragan'), findsNothing);
  });
}

