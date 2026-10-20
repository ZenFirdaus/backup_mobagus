import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Halaman intro FOODIE tampil', (WidgetTester tester) async {
    // Ukuran layar HP supaya layout tidak overflow di test.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const FoodieApp());

    expect(find.text('FOODIE'), findsOneWidget);
    expect(find.text('DIY & JAWA TENGAH'), findsOneWidget);

    // Pompa melewati timer 3 detik di IntroPage supaya tidak ada
    // pending timer saat test selesai.
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
