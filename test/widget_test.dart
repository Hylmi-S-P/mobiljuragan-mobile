import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiljuragan_mobile/main.dart';
import 'package:mobiljuragan_mobile/screens/splash_screen.dart';

void main() {
  testWidgets('MobilJuraganApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MobilJuraganApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel('MobilJuragan'), findsOneWidget);
    expect(find.text('MobilJuragan'), findsNothing);
  });
}

